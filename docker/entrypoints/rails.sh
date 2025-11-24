#!/bin/sh

set -x

# Increase file descriptor limits to prevent "too many open files" errors
ulimit -n 65536 2>/dev/null || echo "Warning: Could not set ulimit -n 65536"
echo "File descriptor limit: $(ulimit -n)"

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# Let DATABASE_URL env take presedence over individual connection params.
# This is done to avoid printing the DATABASE_URL in the logs
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  sleep 2;
done

echo "Database ready to accept connections."

#install missing gems for local dev as we are using base image compiled for production
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

# Run Doctor Diagnostic Script
echo "Running Chatwoot Doctor..."
bundle exec ruby bin/doctor || echo "Doctor script failed, but continuing..."

# Execute the main process of the container
exec "$@"
