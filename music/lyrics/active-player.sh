#!/bin/bash
# active-player.sh — monitors playerctl and triggers lyric fetching on song change.
# Runs as a persistent background daemon launched by conky's lua startup hook or
# a wrapper. Uses /dev/shm for all temp I/O to avoid disk writes.
# v1 01 2026-03-09 @rew62

BASEDIR="$(cd "$(dirname "$0")" && pwd)"
TMP="/dev/shm/conky-lyrics"
mkdir -p "$TMP"

outfile="$TMP/lyrics.out"
pidfile="$TMP/active-player.pid"

# Write our PID so conky can confirm we're running
echo $$ > "$pidfile"

sendmsg() {
    printf '\n${color 888888}Active-player: ${color FF0000} %s' "$1" > "$outfile"
}

last_song=""

# Retry loop for initial player detection — fixes the startup hang/race.
# playerctl -l can return nothing for a few seconds after a player starts.
wait_for_player() {
    local retries=10
    local delay=0.5
    local i=0
    while [ $i -lt $retries ]; do
        local p
        p=$(playerctl -l 2>/dev/null | head -n1)
        [ -n "$p" ] && { echo "$p"; return 0; }
        sleep "$delay"
        (( i++ ))
    done
    return 1
}

while true; do
    # Get first listed player (non-blocking after startup)
    player=$(playerctl -l 2>/dev/null | head -n1)

    if [ -z "$player" ]; then
        # No player found — clear state and wait
        if [ -n "$last_song" ]; then
            > "$outfile"
            > "$TMP/player.running"
            last_song=""
        fi
        sleep 1   # Back off longer — no point polling fast when idle
        continue
    fi

    status=$(playerctl -p "$player" status 2>/dev/null)

    if [ "$status" = "Playing" ]; then
        # Write player name once per change for show-lyric to consume
        echo -n "$player" > "$TMP/player.running"

        # Batch all metadata in ONE playerctl call to reduce forks
        meta=$(playerctl -p "$player" metadata --format '{{xesam:artist}}|{{xesam:title}}|{{xesam:album}}' 2>/dev/null)
        artist="${meta%%|*}"; rest="${meta#*|}"; title="${rest%%|*}"; album="${rest#*|}"

        current="$artist|$title|$album"

        if [ "$current" != "$last_song" ]; then
            last_song="$current"
            # Clear stale lyrics immediately so previous song never bleeds through
            > "$TMP/lyrics.txt"
            > "$TMP/lyrics.out"
            rm -f "$TMP/lyrics.parsed"
            sendmsg "Fetching: $artist - $title"
            "$BASEDIR/get-lyrics.sh" "$current"
        fi
    else
        # Paused or stopped
        if [ -n "$last_song" ]; then
            > "$outfile"
            > "$TMP/player.running"
            last_song=""
        fi
        sleep 1
        continue
    fi

    sleep 0.5
done
