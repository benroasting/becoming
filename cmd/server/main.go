package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/benroasting/becoming/internal/config"
	"github.com/benroasting/becoming/internal/database"
	"github.com/benroasting/becoming/internal/handlers"
	"github.com/benroasting/becoming/internal/repository"
)

func main() {
	cfg := config.Load()

	// structured logging
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: cfg.LogLevel,
	}))
	slog.SetDefault(logger)

	// connect to database
	ctx := context.Background()
	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		slog.Error("failed to connect to database", "error", err)
		os.Exit(1)
	}
	defer pool.Close()
	slog.Info("connected to database")

	valueRepo := repository.NewValueRepository(pool)
	valueHandler := handlers.NewValueHandler(valueRepo)
	habitRepo := repository.NewHabitRepository(pool)
	habitHandler := handlers.NewHabitHandler(habitRepo)
	goalRepo := repository.NewGoalRepository(pool)
	goalHandler := handlers.NewGoalHandler(goalRepo)
	checkInRepo := repository.NewCheckInRepository(pool)
	checkInHandler := handlers.NewCheckInHandler(checkInRepo)
	journalEntryRepo := repository.NewJournalEntryRepository(pool)
	journalEntryHandler := handlers.NewJournalEntryHandler(journalEntryRepo)

	// router
	router := handlers.NewRouter(cfg, valueHandler, habitHandler, goalHandler, checkInHandler, journalEntryHandler)

	// create server
	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		slog.Info("starting server", "port", cfg.Port, "environment", cfg.Environment)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("server error", "error", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	slog.Info("shutting down server...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		slog.Error("server forced to shutdown", "error", err)
		os.Exit(1)
	}

	slog.Info("server stopped")
}
