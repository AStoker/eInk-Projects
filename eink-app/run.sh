#!/bin/sh
# Plain sh, not bashio: bashio ships in the Home Assistant base images and this
# add-on builds on a plain Alpine base. Options are read straight from
# /data/options.json in server.py, which is the same file bashio would parse.
set -e
exec python3 /app/server.py
