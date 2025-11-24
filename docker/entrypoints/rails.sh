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

# EMERGENCY MODE: Robust Setup
# 1. Run Doctor in background so it doesn't block/crash the main process
echo "Starting Doctor in background..."
(bundle exec ruby bin/doctor > public/doctor.html 2>&1 || echo "Doctor script failed" >> public/doctor.html) &

# 2. Start Node server in FOREGROUND to keep container alive
echo "Starting Emergency Node Server on port 3000..."
node -e "const http = require('http'); const fs = require('fs'); const port = process.env.PORT || 3000; http.createServer((req, res) => { res.writeHead(200, {'Content-Type': 'text/html'}); try { if (fs.existsSync('public/doctor.html')) { res.end(fs.readFileSync('public/doctor.html')); } else { res.end('<html><head><meta http-equiv=\"refresh\" content=\"5\"></head><body><h1>Doctor is running...</h1><p>Page will refresh in 5 seconds.</p></body></html>'); } } catch (e) { res.end('Error: ' + e.message); } }).listen(port, '0.0.0.0', () => console.log('Emergency server listening'));"
