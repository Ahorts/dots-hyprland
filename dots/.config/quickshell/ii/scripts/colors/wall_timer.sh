#!/usr/bin/env bash

# Script directory (where random_wallpaper.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RANDOM_WALLPAPER_SCRIPT="$SCRIPT_DIR/random_wallpaper.sh"

# Wait time in seconds (10 minutes = 600 seconds)
WAIT_TIME=600

# Check if random_wallpaper.sh exists
if [[ ! -f "$RANDOM_WALLPAPER_SCRIPT" ]]; then
  echo "Error: random_wallpaper.sh not found at $RANDOM_WALLPAPER_SCRIPT"
  echo "Make sure this script is in the same directory as random_wallpaper.sh"
  exit 1
fi

echo "Starting wallpaper rotation loop..."
echo "Changing wallpaper every 10 minutes"
echo "Press Ctrl+C to stop"
echo ""

# Counter for tracking iterations
counter=1

while true; do
  sleep $WAIT_TIME
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $counter - Setting new wallpaper..."

  # Execute random_wallpaper.sh with any arguments passed to this script
  "$RANDOM_WALLPAPER_SCRIPT" "$@"

  if [[ $? -eq 0 ]]; then
    echo "Wallpaper changed successfully"
  else
    echo "Error: Failed to change wallpaper"
  fi

  echo "Waiting 10 minutes until next change..."
  echo ""

  # Wait for 10 minutes

  ((counter++))
done

