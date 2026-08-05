package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/benroasting/becoming/internal/models"
	"github.com/benroasting/becoming/internal/repository"
	"github.com/go-chi/chi/v5"
)

type HabitHandler struct {
	repo *repository.HabitRepository
}

func NewHabitHandler(repo *repository.HabitRepository) *HabitHandler {
	return &HabitHandler{repo: repo}
}

func (h *HabitHandler) Create(w http.ResponseWriter, r *http.Request) {
	var habit models.Habit

	if err := json.NewDecoder(r.Body).Decode(&habit); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if habit.Title == "" {
		http.Error(w, "Title is required", http.StatusBadRequest)
		return
	}

	if err := h.repo.Create(r.Context(), &habit); err != nil {
		writeHabitError(w, err, "create")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(habit)
}

func (h *HabitHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	habit, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		writeHabitError(w, err, "get")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(habit)
}

func (h *HabitHandler) List(w http.ResponseWriter, r *http.Request) {
	filter := repository.HabitFilter{}

	if isActive := r.URL.Query().Get("is_active"); isActive != "" {
		parsed, err := strconv.ParseBool(isActive)
		if err != nil {
			http.Error(w, "Invalid is_active value", http.StatusBadRequest)
			return
		}
		filter.IsActive = &parsed
	}

	if frequency := r.URL.Query().Get("frequency"); frequency != "" {
		filter.Frequency = &frequency
	}

	habits, err := h.repo.List(r.Context(), filter)
	if err != nil {
		http.Error(w, "Failed to list habits", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(habits)
}

func (h *HabitHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var habit models.Habit
	if err := json.NewDecoder(r.Body).Decode(&habit); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if habit.Title == "" {
		http.Error(w, "Title is required", http.StatusBadRequest)
		return
	}

	habit.ID = id

	if err := h.repo.Update(r.Context(), &habit); err != nil {
		writeHabitError(w, err, "update")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(habit)
}

func (h *HabitHandler) Archive(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	if err := h.repo.Archive(r.Context(), id); err != nil {
		writeHabitError(w, err, "archive")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func writeHabitError(w http.ResponseWriter, err error, action string) {
	switch err {
	case repository.ErrNotFound:
		http.Error(w, "Habit not found", http.StatusNotFound)
	case repository.ErrValueRequired:
		http.Error(w, "At least one value is required", http.StatusBadRequest)
	case repository.ErrValueNotFound:
		http.Error(w, "One or more values not found", http.StatusBadRequest)
	case repository.ErrInvalidValue:
		http.Error(w, "Invalid field value", http.StatusBadRequest)
	default:
		http.Error(w, "Failed to "+action+" habit", http.StatusInternalServerError)
	}
}
