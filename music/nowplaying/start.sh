#!/bin/bash
# start sript - called by music.sh
# v1 01 2026-03-06 @rew62

# Change directory to the script's location
cd "$(dirname "$0")" || exit
setsid conky -c nowplaying.rc
