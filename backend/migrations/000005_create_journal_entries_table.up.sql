CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE journal_values (
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    value_id UUID NOT NULL REFERENCES core_values(id) ON DELETE CASCADE,
    PRIMARY KEY (journal_entry_id, value_id)
);

CREATE INDEX idx_journal_values_value_id ON journal_values (value_id);
