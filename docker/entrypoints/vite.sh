#!/bin/sh
set -x

# Increase file descriptor limits to prevent "too many open files" errors
ulimit -n 65536 2>/dev/null || echo "Warning: Could not set ulimit -n 65536"
echo "File descriptor limit: $(ulimit -n)"

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

pnpm store prune
pnpm install --force

echo "Ready to run Vite development server."

exec "$@"
