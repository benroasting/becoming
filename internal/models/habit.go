package models

import (
	"time"
)

type Frequency string

const (
	FrequencyHourly Frequency = "hourly"
	FrequencyDaily  Frequency = "daily"
	FrequencyWeekly Frequency = "weekly"
	FrequencyCustom Frequency = "custom"
)

type TimeOfDay struct {
	Hour   int `json:"hour"`
	Minute int `json:"minute"`
}

type Habit struct {
	ID           string     `json:"id"`
	Title        string     `json:"title"`
	Description  string     `json:"description"`
	Frequency    Frequency  `json:"frequency"`
	CustomDays   []string   `json:"custom_days,omitempty"`
	ReminderTime *TimeOfDay `json:"reminder_time,omitempty"`
	IsActive     bool       `json:"is_active"`
	ValueIDs     []string   `json:"value_ids"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}
