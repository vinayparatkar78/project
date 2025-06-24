#!/bin/bash
set -e

# Function to wait for database
wait_for_db() {
    echo "Waiting for database to be ready..."
    while ! python -c "
import os
import psycopg2
try:
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        port=os.environ.get('DB_PORT', '5432'),
        user=os.environ.get('DB_USER', 'horilla'),
        password=os.environ.get('DB_PASSWORD', 'horilla'),
        dbname=os.environ.get('DB_NAME', 'horilla_main')
    )
    conn.close()
    print('Database is ready!')
except psycopg2.OperationalError:
    exit(1)
"; do
        echo "Database is unavailable - sleeping"
        sleep 2
    done
}

# Wait for database
wait_for_db

# Run database migrations with fake initial to avoid signal issues
echo "Running database migrations..."
python manage.py migrate --run-syncdb --noinput || python manage.py migrate --noinput

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput --clear

echo "Starting application..."
exec "$@"
