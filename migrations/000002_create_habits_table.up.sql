-- Habits
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('hourly', 'daily', 'weekly', 'custom')),
    custom_days VARCHAR(20)[] DEFAULT '{}',
    reminder_hour INTEGER CHECK (reminder_hour >= 0 AND reminder_hour <= 23),
    reminder_minute INTEGER CHECK (reminder_minute >= 0 AND reminder_minute <= 59),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Habit <-> Value join table
CREATE TABLE habit_values (
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    value_id UUID NOT NULL REFERENCES core_values(id) ON DELETE CASCADE,
    PRIMARY KEY (habit_id, value_id)
);

CREATE INDEX idx_habit_values_value_id ON habit_values (value_id);
