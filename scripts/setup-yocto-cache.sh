#!/bin/bash

# Setup Yocto cache paths in local.conf
# This script is called automatically when yocto_init is run

set -e

LOCAL_CONF_FILE="conf/local.conf"

if [ ! -f "$LOCAL_CONF_FILE" ]; then
    echo "⚠️  local.conf not found at $LOCAL_CONF_FILE - skipping cache configuration"
    return 0 2>/dev/null || exit 0
fi

echo "🔧 Configuring Yocto cache paths..."

# Update DL_DIR to point to mounted cache
if grep -q "^#DL_DIR.*TOPDIR.*downloads" "$LOCAL_CONF_FILE"; then
    sed -i 's|^#DL_DIR ?= "${TOPDIR}/downloads"|DL_DIR ?= "/opt/yocto/downloads"|' "$LOCAL_CONF_FILE"
    echo "✅ DL_DIR configured to use /opt/yocto/downloads"
elif grep -q "^DL_DIR.*TOPDIR.*downloads" "$LOCAL_CONF_FILE"; then
    sed -i 's|^DL_DIR ?= "${TOPDIR}/downloads"|DL_DIR ?= "/opt/yocto/downloads"|' "$LOCAL_CONF_FILE"
    echo "✅ DL_DIR updated to use /opt/yocto/downloads"
fi

# Update SSTATE_DIR to point to mounted cache
if grep -q "^#SSTATE_DIR.*TOPDIR.*sstate-cache" "$LOCAL_CONF_FILE"; then
    sed -i 's|^#SSTATE_DIR ?= "${TOPDIR}/sstate-cache"|SSTATE_DIR ?= "/opt/yocto/sstate-cache"|' "$LOCAL_CONF_FILE"
    echo "✅ SSTATE_DIR configured to use /opt/yocto/sstate-cache"
elif grep -q "^SSTATE_DIR.*TOPDIR.*sstate-cache" "$LOCAL_CONF_FILE"; then
    sed -i 's|^SSTATE_DIR ?= "${TOPDIR}/sstate-cache"|SSTATE_DIR ?= "/opt/yocto/sstate-cache"|' "$LOCAL_CONF_FILE"
    echo "✅ SSTATE_DIR updated to use /opt/yocto/sstate-cache"
fi

# Verify cache directories exist and are accessible
if [ -d "/opt/yocto/downloads" ]; then
    downloads_size=$(du -sh /opt/yocto/downloads 2>/dev/null | cut -f1 || echo "unknown")
    echo "📦 Downloads cache: $downloads_size"
else
    echo "⚠️  Downloads cache directory not found at /opt/yocto/downloads"
fi

if [ -d "/opt/yocto/sstate-cache" ]; then
    sstate_size=$(du -sh /opt/yocto/sstate-cache 2>/dev/null | cut -f1 || echo "unknown")
    echo "🗄️  sstate cache: $sstate_size"
else
    echo "⚠️  sstate cache directory not found at /opt/yocto/sstate-cache"
fi

echo "🎉 Cache configuration complete!" 