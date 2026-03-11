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

echo -e "${BLUE}Configuration Script${NC}"
echo "================================"
echo
echo -e "${YELLOW}NOTE: This script will update configuration files as needed.${NC}"
echo -e "${YELLOW}Required keys: apikey, cityid, cf, lat, lon${NC}"
if [ -f "$ENV_EXAMPLE" ]; then
    echo -e "${YELLOW}See .env.example for the format reference.${NC}"
fi
echo

# Function to get active internet-facing interface
get_default_interface() {
    local iface=$(ip route | grep '^default' | head -n1 | awk '{print $5}')
    if [ -z "$iface" ]; then
        iface=$(ip link show | grep -E '^[0-9]+: (eth|wl|en)' | grep 'state UP' | head -n1 | awk -F': ' '{print $2}')
    fi
    echo "$iface"
}

# Load existing .env if it exists
ORIGINAL_APIKEY=""
ORIGINAL_CITYID=""
ORIGINAL_CF=""
ORIGINAL_LAT=""
ORIGINAL_LON=""
ORIGINAL_CRONPATH=""

if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Loading existing configuration from $ENV_FILE${NC}"
    source "$ENV_FILE"
    ORIGINAL_APIKEY="$apikey"
    ORIGINAL_CITYID="$cityid"
    ORIGINAL_CF="$cf"
    ORIGINAL_LAT="$lat"
    ORIGINAL_LON="$lon"
    ORIGINAL_CRONPATH="$cronpath"
    echo
fi

# Question 1: API Key
CURRENT_APIKEY=${apikey:-""}
read -p "API Key [$CURRENT_APIKEY]: " INPUT
apikey=${INPUT:-$CURRENT_APIKEY}

# Question 2: City ID
CURRENT_CITYID=${cityid:-""}
read -p "City ID [$CURRENT_CITYID]: " INPUT
cityid=${INPUT:-$CURRENT_CITYID}

# Question 3: metric (Celsius) or imperial (Fahrenheit)
CURRENT_CF=${cf:-""}
read -p "metric (Celsius) or imperial (Fahrenheit) [$CURRENT_CF]: " INPUT
cf=${INPUT:-$CURRENT_CF}

# Question 4: Latitude
CURRENT_LAT=${lat:-""}
read -p "Latitude [$CURRENT_LAT]: " INPUT
lat=${INPUT:-$CURRENT_LAT}

# Question 5: Longitude
CURRENT_LON=${lon:-""}
read -p "Longitude [$CURRENT_LON]: " INPUT
lon=${INPUT:-$CURRENT_LON}

# Question 6: Interface name (from active network interface)
CURRENT_INTERFACE=${INTERFACE_NAME:-$(get_default_interface)}
read -p "Network interface name [$CURRENT_INTERFACE]: " INPUT
INTERFACE_NAME=${INPUT:-$CURRENT_INTERFACE}

# Question 7: Cron User
CURRENT_CRONPATH=${cronpath:-$USER}
read -p "Cron User [$CURRENT_CRONPATH]: " INPUT
cronpath=${INPUT:-$CURRENT_CRONPATH}

echo
echo -e "${GREEN}Configuration Summary:${NC}"
echo "  API Key:      $apikey"
echo "  City ID:      $cityid"
echo "  Temp Unit:    $cf"
echo "  Latitude:     $lat"
echo "  Longitude:    $lon"
echo "  Interface:    $INTERFACE_NAME"
echo "  Cron User:    $cronpath"
echo

# Check if .env values changed
ENV_CHANGED=false
if [ "$apikey" != "$ORIGINAL_APIKEY" ] || \
   [ "$cityid" != "$ORIGINAL_CITYID" ] || \
   [ "$cf" != "$ORIGINAL_CF" ] || \
   [ "$lat" != "$ORIGINAL_LAT" ] || \
   [ "$lon" != "$ORIGINAL_LON" ] || \
   [ "$cronpath" != "$ORIGINAL_CRONPATH" ]; then
    ENV_CHANGED=true
fi

# Check if interface changed
INTERFACE_UPDATE=false
if [ -n "$INTERFACE_NAME" ]; then
    INTERFACE_UPDATE=true
fi

# Check if crontab needs updating
CRONTAB_UPDATE=false
if [ "$cronpath" != "$ORIGINAL_CRONPATH" ] && [ -n "$cronpath" ] && [ -f "$CRONTAB_FILE" ]; then
    CRONTAB_UPDATE=true
fi

# Show what will be updated
if [ "$ENV_CHANGED" = false ] && [ "$INTERFACE_UPDATE" = false ] && [ "$CRONTAB_UPDATE" = false ]; then
    echo -e "${GREEN}No changes detected. Nothing to update.${NC}"
    exit 0
fi

# Confirmation prompt
echo "Files to be updated:"
if [ "$ENV_CHANGED" = true ]; then
    echo "  - $ENV_FILE"
fi
if [ "$INTERFACE_UPDATE" = true ]; then
    echo "  - sidepanel/sidepanel-1.rc"
    echo "  - sidepanel/sidepanel-2.rc"
    echo "  - network/network.rc"
    echo "  - network/settings.lua"
fi
if [ "$CRONTAB_UPDATE" = true ]; then
    echo "  - $CRONTAB_FILE"
fi
echo

read -p "Proceed with updates? (yes/no): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
    echo "Configuration cancelled. No files were modified."
    exit 0
fi

# Write .env file only if changed
if [ "$ENV_CHANGED" = true ]; then
    cat > "$ENV_FILE" << EOF
apikey="$apikey"
cityid="$cityid"
cf="$cf"
lat=$lat
lon=$lon
cronpath="$cronpath"
EOF
    chmod 600 "$ENV_FILE"
    echo -e "${GREEN}✓ Configuration saved to $ENV_FILE (permissions: 600)${NC}"
fi

# Update network interface in sidepanel and network scripts if changed
if [ "$INTERFACE_UPDATE" = true ]; then
    # Update sidepanel/sidepanel-1.rc
    if [ -f "sidepanel/sidepanel-1.rc" ]; then
        sed -i "s/template1 = \".*\",/template1 = \"$INTERFACE_NAME\",/" sidepanel/sidepanel-1.rc
        echo -e "${GREEN}✓ Updated sidepanel/sidepanel-1.rc${NC}"
    else
        echo -e "${YELLOW}⚠ File sidepanel/sidepanel-1.rc not found${NC}"
    fi

    # Update sidepanel/sidepanel-2.rc
    if [ -f "sidepanel/sidepanel-2.rc" ]; then
        sed -i "s/template1 = \".*\",/template1 = \"$INTERFACE_NAME\",/" sidepanel/sidepanel-2.rc
        echo -e "${GREEN}✓ Updated sidepanel/sidepanel-2.rc${NC}"
    else
        echo -e "${YELLOW}⚠ File sidepanel/sidepanel-2.rc not found${NC}"
    fi

    # Update network/network.rc
    if [ -f "network/network.rc" ]; then
        sed -i "s/template1 = \".*\",/template1 = \"$INTERFACE_NAME\",/" network/network.rc
        echo -e "${GREEN}✓ Updated network/network.rc${NC}"
    else
        echo -e "${YELLOW}⚠ File network/network.rc not found${NC}"
    fi

    # Update network/settings.lua
    if [ -f "network/settings.lua" ]; then
        sed -i "s/var_NETWORK *= *\".*\"/var_NETWORK = \"$INTERFACE_NAME\"/" network/settings.lua
        echo -e "${GREEN}✓ Updated network/settings.lua${NC}"
    else
        echo -e "${YELLOW}⚠ File network/settings.lua not found${NC}"
    fi
fi

# Update crontab if cronpath changed
if [ "$CRONTAB_UPDATE" = true ]; then
    sed -i "s|/home/<user>/|/home/$cronpath/|g" "$CRONTAB_FILE"
    echo -e "${GREEN}✓ Updated $CRONTAB_FILE${NC}"
fi

echo
echo -e "${GREEN}Configuration complete!${NC}"
