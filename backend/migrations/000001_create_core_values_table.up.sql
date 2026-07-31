-- Core Values
CREATE TABLE core_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'abandoned')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),                                        
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

