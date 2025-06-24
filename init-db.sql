-- Initialize database for Horilla HRMS
-- This script runs when the PostgreSQL container starts for the first time

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone
SET timezone = 'UTC';

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE horilla_main TO horilla;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO horilla;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO horilla;

-- Create indexes for better performance (will be created by Django migrations)
-- These are just examples and will be handled by Django

-- Log the initialization
DO $$
BEGIN
    RAISE NOTICE 'Horilla database initialized successfully';
END $$;
