#!/usr/bin/with-contenv bashio
set -e

export EINK_PHOTO_ROTATE_SECONDS="$(( $(bashio::config 'photo_rotate_minutes') * 60 ))"
export EINK_SCAN_SECONDS="$(bashio::config 'scan_seconds')"
export EINK_LOG_LEVEL="$(bashio::config 'log_level')"
export EINK_PORT=8100

bashio::log.info "eInk image server starting on :${EINK_PORT}"
exec python3 /app/server.py
