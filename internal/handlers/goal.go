package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/benroasting/becoming/internal/models"
	"github.com/benroasting/becoming/internal/repository"
	"github.com/go-chi/chi/v5"
)

type GoalHandler struct {
	repo *repository.GoalRepository
}

func NewGoalHandler(repo *repository.GoalRepository) *GoalHandler {
	return &GoalHandler{repo: repo}
}

func (h *GoalHandler) Create(w http.ResponseWriter, r *http.Request) {
	var goal models.Goal

	if err := json.NewDecoder(r.Body).Decode(&goal); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if goal.Title == "" {
		http.Error(w, "Title is required", http.StatusBadRequest)
		return
	}

	if err := h.repo.Create(r.Context(), &goal); err != nil {
		writeGoalError(w, err, "create")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(goal)
}

func (h *GoalHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	goal, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		writeGoalError(w, err, "get")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(goal)
}

func (h *GoalHandler) List(w http.ResponseWriter, r *http.Request) {
	filter := repository.GoalFilter{}

	if status := r.URL.Query().Get("status"); status != "" {
		filter.Status = &status
	}

	goals, err := h.repo.List(r.Context(), filter)
	if err != nil {
		http.Error(w, "Failed to list goals", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(goals)
}

func (h *GoalHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var goal models.Goal
	if err := json.NewDecoder(r.Body).Decode(&goal); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if goal.Title == "" {
		http.Error(w, "Title is required", http.StatusBadRequest)
		return
	}

	goal.ID = id

	if err := h.repo.Update(r.Context(), &goal); err != nil {
		writeGoalError(w, err, "update")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(goal)
}

func writeGoalError(w http.ResponseWriter, err error, action string) {
	switch err {
	case repository.ErrNotFound:
		http.Error(w, "Goal not found", http.StatusNotFound)
	case repository.ErrValueRequired:
		http.Error(w, "At least one value is required", http.StatusBadRequest)
	case repository.ErrValueNotFound:
		http.Error(w, "One or more values not found", http.StatusBadRequest)
	case repository.ErrHabitRequired:
		http.Error(w, "At least one habit is required", http.StatusBadRequest)
	case repository.ErrHabitNotFound:
		http.Error(w, "One or more habits not found", http.StatusBadRequest)
	default:
		http.Error(w, "Failed to "+action+" goal", http.StatusInternalServerError)
	}
}
