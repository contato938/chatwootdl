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
bundle exec ruby bin/doctor > public/doctor.html 2>&1 || echo "Doctor script failed" >> public/doctor.html

# EMERGENCY MODE: Start simple Node server to serve the doctor file
# This bypasses Rails to ensure we can see the diagnostic output even if Rails crashes.
echo "Starting Emergency Node Server on port 3000..."
node -e "const http = require('http'); const fs = require('fs'); const port = process.env.PORT || 3000; http.createServer((req, res) => { res.writeHead(200, {'Content-Type': 'text/html'}); try { res.end(fs.readFileSync('public/doctor.html')); } catch (e) { res.end('Error: ' + e.message); } }).listen(port, '0.0.0.0', () => console.log('Emergency server listening'));"

# Disable original execution for now
# exec "$@"
