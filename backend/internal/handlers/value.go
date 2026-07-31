package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/benroasting/becoming/internal/models"
	"github.com/benroasting/becoming/internal/repository"
	"github.com/go-chi/chi/v5"
)

type ValueHandler struct {
	repo *repository.ValueRepository
}

func NewValueHandler(repo *repository.ValueRepository) *ValueHandler {
	return &ValueHandler{repo: repo}
}

func (h *ValueHandler) Create(w http.ResponseWriter, r *http.Request) {
	var value models.Value

	if err := json.NewDecoder(r.Body).Decode(&value); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if value.Title == "" {
		http.Error(w, "Title is required", http.StatusBadRequest)
		return
	}

	if err := h.repo.Create(r.Context(), &value); err != nil {
		http.Error(w, "Failed to create value", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(value)
}

func (h *ValueHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	value, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "Value not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Failed to get value", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(value)
}

func (h *ValueHandler) List(w http.ResponseWriter, r *http.Request) {
	filter := repository.ValueFilter{}

	if status := r.URL.Query().Get("status"); status != "" {
		filter.Status = &status
	}

	values, err := h.repo.List(r.Context(), filter)
	if err != nil {
		http.Error(w, "Failed to list values", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(values)
}

func (h *ValueHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var value models.Value
	if err := json.NewDecoder(r.Body).Decode(&value); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if value.Title == "" {
		http.Error(w, "Title is required", http.StatusBadRequest)
		return
	}

	value.ID = id

	if err := h.repo.Update(r.Context(), &value); err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "Value not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Failed to update value", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(value)
}

func (h *ValueHandler) Abandon(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	if err := h.repo.Abandon(r.Context(), id); err != nil {
		if err == repository.ErrNotFound {
			http.Error(w, "Value not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Failed to abandon value", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
