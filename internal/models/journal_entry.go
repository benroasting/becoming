package models

import "time"

type JournalEntry struct {
	ID        string    `json:"id"`
	Content   string    `json:"content"`
	ValueIDs  []string  `json:"value_ids,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
