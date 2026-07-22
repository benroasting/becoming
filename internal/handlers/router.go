package handlers

import (
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/benroasting/becoming/internal/config"
)

func NewRouter(cfg *config.Config, valueHandler *ValueHandler) *chi.Mux {
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.RequestID)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.Heartbeat("/ping"))

	// Health check
	r.Get("/health", HealthCheck)

	// API routes
	r.Route("/api/v1", func(r chi.Router) {
		r.Route("/values", func(r chi.Router) {
			r.Get("/", valueHandler.List)
			r.Post("/", valueHandler.Create)
			r.Get("/{id}", valueHandler.GetByID)
			r.Put("/{id}", valueHandler.Update)
			r.Post("/{id}/abandon", valueHandler.Abandon)
		})
	})

	return r
}
