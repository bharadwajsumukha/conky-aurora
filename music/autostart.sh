#!/bin/bash
# Change directory to the script's location
cd "$(dirname "$0")" || exit

#sleep 2  # only if launching at login

( set -x; setsid bash nowplaying/start.sh & )
#( set -x; setsid bash eq/start.sh & )
#( set -x; setsid bash lyrics/start.sh & )
