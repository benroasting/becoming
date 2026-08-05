package models

import "time"

type JournalValueTag struct {
	ValueID string `json:"value_id"`
	Impact  int    `json:"impact"`
}

type JournalEntry struct {
	ID        string            `json:"id"`
	Content   string            `json:"content"`
	ValueTags []JournalValueTag `json:"value_tags,omitempty"`
	CreatedAt time.Time         `json:"created_at"`
	UpdatedAt time.Time         `json:"updated_at"`
}
