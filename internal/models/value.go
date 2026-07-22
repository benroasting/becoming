package models

import "time"

type ValueStatus string

const (
	ValueStatusActive    ValueStatus = "active"
	ValueStatusAbandoned ValueStatus = "abandoned"
)

type Value struct {
	ID          string      `json:"id"`
	Title       string      `json:"title"`
	Description string      `json:"description"`
	Status      ValueStatus `json:"status"`
	CreatedAt   time.Time   `json:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at"`
}
