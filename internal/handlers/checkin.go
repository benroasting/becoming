package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/benroasting/becoming/internal/models"
	"github.com/benroasting/becoming/internal/repository"
	"github.com/go-chi/chi/v5"
)

type CheckInHandler struct {
	repo *repository.CheckInRepository
}

func NewCheckInHandler(repo *repository.CheckInRepository) *CheckInHandler {
	return &CheckInHandler{repo: repo}
}

func (h *CheckInHandler) Create(w http.ResponseWriter, r *http.Request) {
	habitID := chi.URLParam(r, "id")

	var checkIn models.CheckIn

	if err := json.NewDecoder(r.Body).Decode(&checkIn); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	checkIn.HabitID = habitID
	if checkIn.CompletedAt.IsZero() {
		checkIn.CompletedAt = time.Now()
	}

	if err := h.repo.Create(r.Context(), &checkIn); err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "Habit not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Failed to create check-in", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(checkIn)
}

func (h *CheckInHandler) List(w http.ResponseWriter, r *http.Request) {
	habitID := chi.URLParam(r, "id")

	checkIns, err := h.repo.ListByHabit(r.Context(), habitID)
	if err != nil {
		http.Error(w, "Failed to list check-ins", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(checkIns)
}
