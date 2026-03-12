#!/bin/bash

set -e

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRONTAB_FILE="$SCRIPT_DIR/earth/crontab"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ── Font check function ───────────────────────────────────────────────────
run_font_check() {
    echo
    echo -e "${BLUE}Checking fonts...${NC}"
    echo "================================"
    grep -roh '{font [^}]*}' "$SCRIPT_DIR" | \
        grep -o '{font [^:}]*' | \
        sed 's/{font //' | \
        grep -E '^[A-Za-z][A-Za-z0-9 ]+$' | \
        sort -u | \
        while read -r font; do
            if fc-list | grep -qiF "$font"; then
                echo -e "${GREEN}✓ $font${NC}"
            else
                echo -e "${YELLOW}✗ MISSING: $font${NC}"
            fi
        done
    echo
}

# ── Lyrics setup function ─────────────────────────────────────────────────
run_lyrics_check() {
    if [ -f "$SCRIPT_DIR/music/lyrics/setup.sh" ]; then
        echo
        read -p "Run lyrics dependency check? (yes/no): " RUN_LYRICS
        if [[ "$RUN_LYRICS" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
            echo -e "${BLUE}Running lyrics dependency check...${NC}"
            echo "================================"
            bash "$SCRIPT_DIR/music/lyrics/setup.sh"
        fi
    fi
}

# ── Function to get active internet-facing interface ─────────────────────
get_default_interface() {
    local iface=$(ip route | grep '^default' | head -n1 | awk '{print $5}')
    if [ -z "$iface" ]; then
        iface=$(ip link show | grep -E '^[0-9]+: (eth|wl|en)' | grep 'state UP' | head -n1 | awk -F': ' '{print $2}')
    fi
    echo "$iface"
}

# ─────────────────────────────────────────────────────────────────────────
echo -e "${BLUE}Configuration Script${NC}"
echo "================================"
echo
echo -e "${YELLOW}NOTE: This script will update configuration files as needed.${NC}"
echo -e "${YELLOW}Required keys: apikey, cityid, cf, lat, lon${NC}"
if [ -f "$ENV_EXAMPLE" ]; then
    echo -e "${YELLOW}See .env.example for the format reference.${NC}"
fi
echo

# ── Load and display existing .env if present ────────────────────────────
apikey=""; cityid=""; cf=""; lat=""; lon=""; INTERFACE_NAME=""; cronpath=""

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    [ -z "$INTERFACE_NAME" ] && INTERFACE_NAME=$(get_default_interface)
    [ -z "$cronpath" ]       && cronpath="$USER"

    echo -e "${YELLOW}Current configuration:${NC}"
    printf "  %-15s %s\n" "API Key:"        "$apikey"
    printf "  %-15s %s\n" "City ID:"        "$cityid"
    printf "  %-15s %s\n" "Temp Unit:"      "$cf"
    printf "  %-15s %s\n" "Latitude:"       "$lat"
    printf "  %-15s %s\n" "Longitude:"      "$lon"
    printf "  %-15s %s\n" "Interface:"      "$INTERFACE_NAME"
    printf "  %-15s %s\n" "Cron User:"      "$cronpath"
    echo

    read -p "Any changes needed? (yes/no): " HAS_CHANGES
    if [[ ! "$HAS_CHANGES" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        echo -e "${GREEN}No changes. Nothing to update.${NC}"
        run_font_check
        run_lyrics_check
        exit 0
    fi
    echo
else
    # First run — no .env yet, set defaults
    INTERFACE_NAME=$(get_default_interface)
    cronpath="$USER"
    echo -e "${YELLOW}No existing configuration found. Please enter your settings.${NC}"
    echo
fi

# ── Individual prompts ────────────────────────────────────────────────────
read -p "API Key [$apikey]: " INPUT
apikey=${INPUT:-$apikey}

read -p "City ID [$cityid]: " INPUT
cityid=${INPUT:-$cityid}

read -p "metric (Celsius) or imperial (Fahrenheit) [$cf]: " INPUT
cf=${INPUT:-$cf}

read -p "Latitude [$lat]: " INPUT
lat=${INPUT:-$lat}

read -p "Longitude [$lon]: " INPUT
lon=${INPUT:-$lon}

read -p "Network interface [$INTERFACE_NAME]: " INPUT
INTERFACE_NAME=${INPUT:-$INTERFACE_NAME}

read -p "Cron User [$cronpath]: " INPUT
cronpath=${INPUT:-$cronpath}

echo
echo -e "${GREEN}Updated configuration:${NC}"
printf "  %-30s %s\n" "API Key:"    "$apikey"
printf "  %-30s %s\n" "City ID:"    "$cityid"
printf "  %-30s %s\n" "Temp Unit:"  "$cf"
printf "  %-30s %s\n" "Latitude:"   "$lat"
printf "  %-30s %s\n" "Longitude:"  "$lon"
printf "  %-30s %s\n" "Interface:"  "$INTERFACE_NAME"
printf "  %-30s %s\n" "Cron User:"  "$cronpath"
echo

# ── Files to be updated ───────────────────────────────────────────────────
echo "Files to be updated:"
echo "  - $ENV_FILE"
echo "  - sidepanel/sidepanel-1.rc"
echo "  - sidepanel/sidepanel-2.rc"
echo "  - network/network.rc"
echo "  - network/settings.lua"
if [ -f "$CRONTAB_FILE" ]; then
    echo "  - $CRONTAB_FILE"
fi
echo

read -p "Proceed with updates? (yes/no): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
    echo "Configuration cancelled. No files were modified."
    run_font_check
    run_lyrics_check
    exit 0
fi

# ── Write .env ────────────────────────────────────────────────────────────
cat > "$ENV_FILE" << EOF
apikey="$apikey"
cityid="$cityid"
cf="$cf"
lat=$lat
lon=$lon
INTERFACE_NAME="$INTERFACE_NAME"
cronpath="$cronpath"
EOF
chmod 600 "$ENV_FILE"
echo -e "${GREEN}✓ Saved $ENV_FILE (permissions: 600)${NC}"

# ── Update interface files ────────────────────────────────────────────────
if [ -f "sidepanel/sidepanel-1.rc" ]; then
    sed -i "s/template1 = \".*\",/template1 = \"$INTERFACE_NAME\",/" sidepanel/sidepanel-1.rc
    echo -e "${GREEN}✓ Updated sidepanel/sidepanel-1.rc${NC}"
else
    echo -e "${YELLOW}⚠ File sidepanel/sidepanel-1.rc not found${NC}"
fi

if [ -f "sidepanel/sidepanel-2.rc" ]; then
    sed -i "s/template1 = \".*\",/template1 = \"$INTERFACE_NAME\",/" sidepanel/sidepanel-2.rc
    echo -e "${GREEN}✓ Updated sidepanel/sidepanel-2.rc${NC}"
else
    echo -e "${YELLOW}⚠ File sidepanel/sidepanel-2.rc not found${NC}"
fi

if [ -f "network/network.rc" ]; then
    sed -i "s/template1 = \".*\",/template1 = \"$INTERFACE_NAME\",/" network/network.rc
    echo -e "${GREEN}✓ Updated network/network.rc${NC}"
else
    echo -e "${YELLOW}⚠ File network/network.rc not found${NC}"
fi

if [ -f "network/settings.lua" ]; then
    sed -i "s/var_NETWORK *= *\".*\"/var_NETWORK = \"$INTERFACE_NAME\"/" network/settings.lua
    echo -e "${GREEN}✓ Updated network/settings.lua${NC}"
else
    echo -e "${YELLOW}⚠ File network/settings.lua not found${NC}"
fi

# ── Update crontab ────────────────────────────────────────────────────────
if [ -f "$CRONTAB_FILE" ]; then
    sed -i "s|/home/<user>/|/home/$cronpath/|g" "$CRONTAB_FILE"
    echo -e "${GREEN}✓ Updated $CRONTAB_FILE${NC}"
fi

echo
echo -e "${GREEN}Configuration complete!${NC}"

# ── Font check ────────────────────────────────────────────────────────────
run_font_check

# ── Lyrics dependency check ───────────────────────────────────────────────
run_lyrics_check
