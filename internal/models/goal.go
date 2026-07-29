package models

import "time"

type GoalStatus string

const (
	GoalStatusActive    GoalStatus = "active"
	GoalStatusCompleted GoalStatus = "completed"
	GoalStatusAbandoned GoalStatus = "abandoned"
	GoalStatusInactive  GoalStatus = "inactive"
)

type Goal struct {
	ID          string     `json:"id"`
	ValueIDs    []string   `json:"value_ids"`
	HabitIDs    []string   `json:"habit_ids"`
	Title       string     `json:"title"`
	Description string     `json:"description"`
	Status      GoalStatus `json:"status"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}
