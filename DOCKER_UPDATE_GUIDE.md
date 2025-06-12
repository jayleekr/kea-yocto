# Docker Image and Git Update Guide

## Summary of Changes

The following changes have been made to automatically configure Yocto cache paths when `yocto_init` is run:

### 1. New Script: `scripts/setup-yocto-cache.sh`
- Automatically configures `DL_DIR` and `SSTATE_DIR` in `local.conf`
- Points to the mounted cache directories (`/opt/yocto/downloads` and `/opt/yocto/sstate-cache`)
- Provides feedback on cache sizes and configuration status

### 2. Updated Dockerfile
- Modified the `yocto_init` function to automatically call the cache setup script
- The script runs after the Yocto environment is initialized

## Steps to Update

### 1. Commit Changes to Git

```bash
# Add the new files
git add scripts/setup-yocto-cache.sh
git add Dockerfile
git add DOCKER_UPDATE_GUIDE.md

# Commit the changes
git commit -m "feat: Add automatic cache configuration for Yocto builds

- Add setup-yocto-cache.sh script to automatically configure DL_DIR and SSTATE_DIR
- Update Dockerfile to call cache setup script during yocto_init
- Cache paths now automatically point to mounted volumes (/opt/yocto/downloads and /opt/yocto/sstate-cache)
- Improves user experience by eliminating manual local.conf configuration"

# Push to repository
git push origin main
```

### 2. Build and Push Docker Image

```bash
# Build the new image
docker build -t jabang3/yocto-lecture:5.0-lts .

# Tag with additional version if needed
docker tag jabang3/yocto-lecture:5.0-lts jabang3/yocto-lecture:5.0-lts-auto-cache

# Push to Docker Hub
docker push jabang3/yocto-lecture:5.0-lts
docker push jabang3/yocto-lecture:5.0-lts-auto-cache
```

### 3. Test the Updated Image

```bash
# Test with the quick-start script
./scripts/quick-start.sh

# Or test manually
docker compose run --rm yocto-lecture bash -c 'yocto_init && grep -E "^DL_DIR|^SSTATE_DIR" conf/local.conf'
```

## Expected Behavior After Update

1. **Automatic Configuration**: When users run `yocto_init`, the cache paths are automatically configured
2. **No Manual Editing**: Users no longer need to manually edit `local.conf`
3. **Cache Verification**: The script shows cache sizes and confirms configuration
4. **Graceful Handling**: If cache directories don't exist, warnings are shown but the process continues

## Benefits

- **Improved User Experience**: No manual configuration required
- **Consistent Setup**: All users get the same cache configuration
- **Better Performance**: Caches are automatically used when available
- **Reduced Errors**: Eliminates common configuration mistakes

## Verification

After updating, users should see output like this when running `yocto_init`:

```
🔧 Configuring Yocto cache paths...
✅ DL_DIR configured to use /opt/yocto/downloads
✅ SSTATE_DIR configured to use /opt/yocto/sstate-cache
📦 Downloads cache: 5.0G
🗄️  sstate cache: 1.9G
🎉 Cache configuration complete!
```

## Rollback Plan

If issues occur, you can rollback by:

1. Reverting the git commits
2. Rebuilding the Docker image without the changes
3. Using the previous Docker image tag

## Notes

- The script is designed to be idempotent (safe to run multiple times)
- It handles both commented and uncommented cache directory lines in `local.conf`
- Permissions are handled gracefully with appropriate error messages 