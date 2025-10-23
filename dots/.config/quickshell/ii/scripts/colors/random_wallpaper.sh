#!/usr/bin/env bash

# Default wallpaper directory
DEFAULT_WALLPAPER_DIR="$HOME/wallpaper"

# Script directory (where switchwall.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWITCHWALL_SCRIPT="$SCRIPT_DIR/switchwall.sh"

# State file to track current position
STATE_FILE="$SCRIPT_DIR/.wallpaper_position"

# Supported image and video extensions
SUPPORTED_EXTENSIONS=("jpg" "jpeg" "png" "gif" "bmp" "webp" "tiff" "svg" "mp4" "mkv" "webm")

usage() {
    echo "Usage: $0 [OPTIONS] [DIRECTORY]"
    echo ""
    echo "Sequentially select and set wallpapers from a directory"
    echo ""
    echo "OPTIONS:"
    echo "  -d, --directory DIR    Directory to search for wallpapers"
    echo "  --mode MODE           Color mode: dark or light"
    echo "  --type TYPE           Color scheme type"
    echo "  --color [HEX]         Use color instead of image (optional hex color)"
    echo "  --recursive           Search subdirectories recursively"
    echo "  --list-only           Only list found images, don't set wallpaper"
    echo "  --reset               Reset position to start from beginning"
    echo "  --show-position       Show current position and exit"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "DIRECTORY:"
    echo "  Path to wallpaper directory (default: $DEFAULT_WALLPAPER_DIR)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Next wallpaper from default directory"
    echo "  $0 ~/Pictures/Wallpapers             # Next wallpaper from specific directory"
    echo "  $0 --recursive ~/Pictures            # Next wallpaper from directory and subdirectories"
    echo "  $0 --mode dark --type vibrant         # Next wallpaper with specific color settings"
    echo "  $0 --reset                           # Reset to start from beginning"
    echo "  $0 --show-position                   # Show current position"
}

find_images() {
    local search_dir="$1"
    local recursive="$2"
    local find_args=()
    
    if [[ ! -d "$search_dir" ]]; then
        echo "Error: Directory '$search_dir' does not exist" >&2
        return 1
    fi
    
    # Build find command arguments
    if [[ "$recursive" == "1" ]]; then
        find_args+=("$search_dir")
    else
        find_args+=("$search_dir" "-maxdepth" "1")
    fi
    
    find_args+=("-type" "f")
    
    # Add extension filters
    local first=1
    find_args+=("(")
    for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
        if [[ $first -eq 1 ]]; then
            find_args+=("-iname" "*.${ext}")
            first=0
        else
            find_args+=("-o" "-iname" "*.${ext}")
        fi
    done
    find_args+=(")")
    
    # Execute find command and sort for consistent ordering
    find "${find_args[@]}" 2>/dev/null | sort
}

get_state_key() {
    local wallpaper_dir="$1"
    local recursive="$2"
    
    # Create a unique key based on directory and recursive flag
    local key="${wallpaper_dir}:${recursive:-0}"
    echo "$key"
}

read_position() {
    local state_key="$1"
    
    if [[ -f "$STATE_FILE" ]]; then
        # Look for the line with our state key
        grep "^${state_key}:" "$STATE_FILE" 2>/dev/null | cut -d':' -f3
    fi
}

write_position() {
    local state_key="$1"
    local position="$2"
    
    # Create state file if it doesn't exist
    touch "$STATE_FILE"
    
    # Remove old entry for this key and add new one
    grep -v "^${state_key}:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
    echo "${state_key}:${position}" >> "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

select_next_image() {
    local images=("$@")
    local state_key="$1"
    shift
    images=("$@")
    
    if [[ ${#images[@]} -eq 0 ]]; then
        echo "Error: No supported images found" >&2
        return 1
    fi
    
    # Read current position
    local current_position
    current_position=$(read_position "$state_key")
    
    # If no position found or invalid, start from 0
    if [[ -z "$current_position" ]] || ! [[ "$current_position" =~ ^[0-9]+$ ]]; then
        current_position=0
    fi
    
    # Make sure position is within bounds
    if [[ $current_position -ge ${#images[@]} ]]; then
        current_position=0
    fi
    
    # Get the image at current position
    local selected_image="${images[$current_position]}"
    
    # Calculate next position (wrap around if at end)
    local next_position=$(( (current_position + 1) % ${#images[@]} ))
    
    # Save next position for next run
    write_position "$state_key" "$next_position"
    
    echo "$selected_image"
}

reset_position() {
    local state_key="$1"
    write_position "$state_key" "0"
    echo "Position reset to beginning"
}

show_position() {
    local state_key="$1"
    local images=("$@")
    shift
    images=("$@")
    
    local current_position
    current_position=$(read_position "$state_key")
    
    if [[ -z "$current_position" ]] || ! [[ "$current_position" =~ ^[0-9]+$ ]]; then
        current_position=0
    fi
    
    if [[ $current_position -ge ${#images[@]} ]]; then
        current_position=0
    fi
    
    echo "Current position: $current_position / ${#images[@]}"
    if [[ ${#images[@]} -gt 0 ]]; then
        echo "Next wallpaper: $(basename "${images[$current_position]}")"
    fi
}

main() {
    local wallpaper_dir="$DEFAULT_WALLPAPER_DIR"
    local mode_flag=""
    local type_flag=""
    local color_flag=""
    local color=""
    local recursive=""
    local list_only=""
    local reset_position_flag=""
    local show_position_flag=""
    local switchwall_args=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--directory)
                if [[ -n "$2" && "$2" != -* ]]; then
                    wallpaper_dir="$2"
                    shift 2
                else
                    echo "Error: --directory requires a directory path" >&2
                    exit 1
                fi
                ;;
            --mode)
                if [[ -n "$2" && "$2" != -* ]]; then
                    mode_flag="$2"
                    switchwall_args+=(--mode "$2")
                    shift 2
                else
                    echo "Error: --mode requires a value (dark/light)" >&2
                    exit 1
                fi
                ;;
            --type)
                if [[ -n "$2" && "$2" != -* ]]; then
                    type_flag="$2"
                    switchwall_args+=(--type "$2")
                    shift 2
                else
                    echo "Error: --type requires a value" >&2
                    exit 1
                fi
                ;;
            --color)
                color_flag="1"
                switchwall_args+=(--color)
                if [[ -n "$2" && "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    color="$2"
                    switchwall_args+=("$2")
                    shift 2
                else
                    shift
                fi
                ;;
            --recursive)
                recursive="1"
                shift
                ;;
            --list-only)
                list_only="1"
                shift
                ;;
            --reset)
                reset_position_flag="1"
                shift
                ;;
            --show-position)
                show_position_flag="1"
                shift
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                echo "Use --help for usage information" >&2
                exit 1
                ;;
            *)
                # Treat as directory path
                wallpaper_dir="$1"
                shift
                ;;
        esac
    done
    
    # Check if switchwall.sh exists
    if [[ ! -f "$SWITCHWALL_SCRIPT" ]]; then
        echo "Error: switchwall.sh not found at $SWITCHWALL_SCRIPT" >&2
        echo "Make sure this script is in the same directory as switchwall.sh" >&2
        exit 1
    fi
    
    # If using color mode, just pass through to switchwall
    if [[ "$color_flag" == "1" ]]; then
        echo "Using color mode..."
        exec "$SWITCHWALL_SCRIPT" "${switchwall_args[@]}"
    fi
    
    # Expand tilde if present
    wallpaper_dir="${wallpaper_dir/#\~/$HOME}"
    
    # Create state key for this configuration
    state_key=$(get_state_key "$wallpaper_dir" "$recursive")
    
    # Handle reset position
    if [[ "$reset_position_flag" == "1" ]]; then
        reset_position "$state_key"
        exit 0
    fi
    
    echo "Searching for images in: $wallpaper_dir"
    if [[ "$recursive" == "1" ]]; then
        echo "Searching recursively..."
    fi
    
    # Find all supported images
    mapfile -t images < <(find_images "$wallpaper_dir" "$recursive")
    
    if [[ ${#images[@]} -eq 0 ]]; then
        echo "No supported images found in '$wallpaper_dir'" >&2
        echo "Supported extensions: ${SUPPORTED_EXTENSIONS[*]}" >&2
        exit 1
    fi
    
    echo "Found ${#images[@]} supported image(s)"
    
    # Handle show position
    if [[ "$show_position_flag" == "1" ]]; then
        show_position "$state_key" "${images[@]}"
        exit 0
    fi
    
    # If list-only mode, just print the images and exit
    if [[ "$list_only" == "1" ]]; then
        printf '%s\n' "${images[@]}"
        exit 0
    fi
    
    # Select next image in sequence
    selected_image=$(select_next_image "$state_key" "${images[@]}")
    
    if [[ -z "$selected_image" ]]; then
        echo "Error: Failed to select next image" >&2
        exit 1
    fi
    
    echo "Selected: $(basename "$selected_image")"
    echo "Full path: $selected_image"
    
    # Call switchwall.sh with the selected image
    exec "$SWITCHWALL_SCRIPT" "$selected_image" "${switchwall_args[@]}"
}

main "$@"