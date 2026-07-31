package models

import "time"

type CheckIn struct {
	ID          string    `json:"id"`
	HabitID     string    `json:"habit_id"`
	CompletedAt time.Time `json:"completed_at"`
	Notes       string    `json:"notes"`
	CreatedAt   time.Time `json:"created_at"`
}
