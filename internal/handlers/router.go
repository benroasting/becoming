package handlers

import (
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/benroasting/becoming/internal/config"
)

func NewRouter(cfg *config.Config,
	valueHandler *ValueHandler,
	habitHandler *HabitHandler,
	goalHandler *GoalHandler,
	checkInHandler *CheckInHandler,
	journalEntryHandler *JournalEntryHandler,
) *chi.Mux {
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

		r.Route("/habits", func(r chi.Router) {
			r.Get("/", habitHandler.List)
			r.Post("/", habitHandler.Create)
			r.Get("/{id}", habitHandler.GetByID)
			r.Put("/{id}", habitHandler.Update)
			r.Post("/{id}/archive", habitHandler.Archive)
			r.Post("/{id}/check-ins", checkInHandler.Create)
			r.Get("/{id}/check-ins", checkInHandler.List)
		})

		r.Route("/goals", func(r chi.Router) {
			r.Get("/", goalHandler.List)
			r.Post("/", goalHandler.Create)
			r.Get("/{id}", goalHandler.GetByID)
			r.Put("/{id}", goalHandler.Update)
		})

		r.Route("/journal-entries", func(r chi.Router) {
			r.Get("/", journalEntryHandler.List)
			r.Post("/", journalEntryHandler.Create)
			r.Get("/{id}", journalEntryHandler.GetByID)
			r.Put("/{id}", journalEntryHandler.Update)
			r.Delete("/{id}", journalEntryHandler.Delete)
		})
	})

	return r
}
