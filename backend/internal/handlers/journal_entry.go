package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/benroasting/becoming/internal/models"
	"github.com/benroasting/becoming/internal/repository"
	"github.com/go-chi/chi/v5"
)

type JournalEntryHandler struct {
	repo *repository.JournalEntryRepository
}

func NewJournalEntryHandler(repo *repository.JournalEntryRepository) *JournalEntryHandler {
	return &JournalEntryHandler{repo: repo}
}

func (h *JournalEntryHandler) Create(w http.ResponseWriter, r *http.Request) {
	var entry models.JournalEntry

	if err := json.NewDecoder(r.Body).Decode(&entry); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if entry.Content == "" {
		http.Error(w, "Content is required", http.StatusBadRequest)
		return
	}

	if err := h.repo.Create(r.Context(), &entry); err != nil {
		writeJournalEntryError(w, err, "create")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(entry)
}

func (h *JournalEntryHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	entry, err := h.repo.GetByID(r.Context(), id)

	if err != nil {
		writeJournalEntryError(w, err, "get")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entry)
}

func (h *JournalEntryHandler) List(w http.ResponseWriter, r *http.Request) {
	entries, err := h.repo.List(r.Context())
	if err != nil {
		http.Error(w, "Failed to list journal entries", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entries)
}

func (h *JournalEntryHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var entry models.JournalEntry
	if err := json.NewDecoder(r.Body).Decode(&entry); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if entry.Content == "" {
		http.Error(w, "Content is required", http.StatusBadRequest)
		return
	}

	entry.ID = id

	if err := h.repo.Update(r.Context(), &entry); err != nil {
		writeJournalEntryError(w, err, "update")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(entry)
}

func (h *JournalEntryHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	if err := h.repo.Delete(r.Context(), id); err != nil {
		writeJournalEntryError(w, err, "delete")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func writeJournalEntryError(w http.ResponseWriter, err error, action string) {
	switch err {
	case repository.ErrNotFound:
		http.Error(w, "Journal entry not found", http.StatusNotFound)
	case repository.ErrValueNotFound:
		http.Error(w, "One or more values not found", http.StatusBadRequest)
	case repository.ErrInvalidValue:
		http.Error(w, "Invalid field value", http.StatusBadRequest)
	default:
		http.Error(w, "Failed to "+action+" journal entry", http.StatusInternalServerError)
	}
}
