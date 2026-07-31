-- Goals
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Goal <-> Value join table
CREATE TABLE goal_values (
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    value_id UUID NOT NULL REFERENCES core_values(id) ON DELETE CASCADE,
    PRIMARY KEY (goal_id, value_id)
);

CREATE INDEX idx_goal_values_value_id ON goal_values (value_id);

-- Habit <-> Goal join table
CREATE TABLE habit_goals (
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    PRIMARY KEY (habit_id, goal_id)
);

CREATE INDEX idx_habit_goals_goal_id ON habit_goals (goal_id);
