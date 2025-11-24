# Fix: "Too Many Open Files" Error - 502 Bad Gateway

## 🎯 Problem

The application was failing to start in Docker with:
- **Error**: `tail: inotify cannot be used, reverting to polling: Too many open files`
- **Result**: 502 Bad Gateway error when accessing the dashboard
- **Cause**: Docker containers were hitting the system's file descriptor limits

## ✅ Solution Applied

### 1. Updated `docker-entrypoint.sh`

Added file descriptor limit increase at the beginning of the script:

```bash
# Increase file descriptor limits to prevent "too many open files" errors
ulimit -n 65536 2>/dev/null || echo "Warning: Could not set ulimit -n 65536"
```

Also added diagnostic output to show the current limit:
```bash
echo -e "${YELLOW}File descriptor limit: $(ulimit -n)${NC}"
```

### 2. Updated Docker Compose Files

Added `ulimits` configuration to all service containers:

**Files modified:**
- `docker-compose.yaml` (development)
- `docker-compose.production.yaml` (production)

**Configuration added to each service:**
```yaml
ulimits:
  nofile:
    soft: 65536
    hard: 65536
```

**Services updated:**
- `rails` (web server)
- `sidekiq` (background worker)
- `vite` (development asset server)

### 3. Updated Documentation

**TROUBLESHOOTING_502.md:**
- Added section about the "too many open files" error
- Included instructions for Docker standalone deployments
- Added Docker daemon configuration examples

**DEPLOY_DOKPLOY.md:**
- Updated deployment process documentation
- Added troubleshooting entry for the error

## 🔍 Technical Details

### Why 65536?

- **Default limit**: Usually 1024 or 4096 in containers
- **Recommended**: 65536 for production Rails applications
- **Reason**: Rails apps open many files simultaneously:
  - Database connections
  - Log files
  - Temporary files
  - Asset files
  - Redis connections
  - External API connections

### What are file descriptors?

File descriptors are handles that processes use to access files, sockets, and other I/O resources. When you run out, the application can't:
- Open new files
- Create new network connections
- Fork new processes
- Use inotify for file watching

## 🚀 How to Deploy the Fix

### For Dokploy or Cloud Platforms

Simply rebuild your Docker image - the fix is automatic:

```bash
# Dokploy will rebuild automatically on push
git push origin main
```

### For Local Docker Compose

Restart your containers with the updated configuration:

```bash
# Development
docker-compose down
docker-compose up --build

# Production
docker-compose -f docker-compose.production.yaml down
docker-compose -f docker-compose.production.yaml up --build
```

### For Docker Run (Standalone)

If running without docker-compose, add the ulimit flag:

```bash
docker run -d \
  --name chatwoot \
  --ulimit nofile=65536:65536 \
  -p 3000:3000 \
  -e SECRET_KEY_BASE=your-secret \
  -e POSTGRES_HOST=postgres \
  # ... other env vars
  your-image:latest
```

## 📊 Verification

After deployment, check the logs for:

```
✅ Starting Chatwoot...
✅ File descriptor limit: 65536
✅ PostgreSQL is ready!
✅ Redis connection check complete!
✅ Database migrations completed successfully!
✅ Starting Puma web server...
```

The file descriptor limit should show **65536** or higher.

## 🔧 Host-Level Configuration (Optional)

If you need to increase limits at the Docker daemon level:

### Edit `/etc/docker/daemon.json`:

```json
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}
```

### Restart Docker:

```bash
sudo systemctl restart docker
```

### System-wide limits (Linux):

Edit `/etc/security/limits.conf`:

```
* soft nofile 65536
* hard nofile 65536
```

Then reboot or re-login.

## 📝 Testing

### Check current limits in a running container:

```bash
docker exec -it your-container bash
ulimit -n
# Should output: 65536
```

### Monitor file descriptor usage:

```bash
# Check how many files are open
docker exec -it your-container bash -c "ls -1 /proc/self/fd | wc -l"

# Check system limits
docker exec -it your-container bash -c "cat /proc/sys/fs/file-max"
```

## 🎉 Expected Results

After applying this fix:

1. ✅ Application starts successfully
2. ✅ No "too many open files" errors in logs
3. ✅ Dashboard loads without 502 errors
4. ✅ File watching (for development) works properly
5. ✅ All background jobs process correctly

## 🆘 If Problems Persist

If you still encounter file descriptor issues:

1. **Check Docker daemon limits**: Ensure Docker itself has proper limits
2. **Check host system limits**: Use `ulimit -n` on the host
3. **Monitor usage**: Check if you're actually hitting 65536 (unlikely)
4. **Check for leaks**: Ensure your application closes file descriptors properly

For more help, see:
- [TROUBLESHOOTING_502.md](TROUBLESHOOTING_502.md)
- [DEPLOY_DOKPLOY.md](DEPLOY_DOKPLOY.md)

## 📚 References

- [Docker ulimits documentation](https://docs.docker.com/engine/reference/commandline/run/#set-ulimits-in-container---ulimit)
- [Linux file descriptor limits](https://www.kernel.org/doc/Documentation/sysctl/fs.txt)
- [Rails deployment best practices](https://guides.rubyonrails.org/deploying.html)
