#!/bin/bash
# USB Monitor Script for Waybar
# Detects connected USB devices and outputs JSON format

# Glyphs
GLYPH_MOUNTED="󱊞"
GLYPH_UNMOUNTED="󱊟"

# Function to get USB devices (removable storage only)
get_usb_devices() {
    # Get all removable block devices (excluding loops and rams)
    # Process each device and check properties individually
    while IFS= read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        rm=$(echo "$line" | awk '{print $2}')
        type=$(echo "$line" | awk '{print $3}')

        # Skip if not removable partition
        [[ "$rm" != "1" || "$type" != "part" ]] && continue

        # Get device info using lsblk for this specific device
        hotplug=$(lsblk -ndo HOTPLUG "$device" 2>/dev/null)
        [[ "$hotplug" != "1" ]] && continue

        mountpoint=$(lsblk -ndo MOUNTPOINT "$device" 2>/dev/null)
        size=$(lsblk -ndo SIZE "$device" 2>/dev/null)
        fstype=$(lsblk -ndo FSTYPE "$device" 2>/dev/null)
        label=$(lsblk -ndo LABEL "$device" 2>/dev/null)

        echo "$device|$mountpoint|$size|$fstype|$label"
    done < <(lsblk -nlo NAME,RM,TYPE -p)
}

# Function to escape JSON strings
json_escape() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Main logic
main() {
    mapfile -t usb_devices < <(get_usb_devices)
    
    device_count=${#usb_devices[@]}
    
    # No USB devices connected
    if [ "$device_count" -eq 0 ]; then
        echo "{\"text\":\"$GLYPH_UNMOUNTED\",\"tooltip\":\"No USB devices connected\",\"class\":\"none\",\"alt\":\"none\"}"
        exit 0
    fi
    
    # Build tooltip with all device information
    tooltip=""
    mounted_count=0
    unmounted_count=0
    
    for device_info in "${usb_devices[@]}"; do
        IFS='|' read -r device mountpoint size fstype label <<< "$device_info"
        
        device_name=$(basename "$device")
        
        if [ -n "$mountpoint" ]; then
            mounted_count=$((mounted_count + 1))
            
            # Get used/free space
            if [ -d "$mountpoint" ]; then
                usage=$(df -h "$mountpoint" | awk 'NR==2 {print $3" / "$2" ("$5" used)"}')
            else
                usage="mounted"
            fi
            
            # Build label display
            display_label="${label:-$device_name}"
            
            tooltip+="[Mounted] $display_label\\n"
            tooltip+="Device: $device\\n"
            tooltip+="Mount: $mountpoint\\n"
            tooltip+="Space: $usage\\n\\n"
        else
            unmounted_count=$((unmounted_count + 1))
            
            display_label="${label:-$device_name}"
            
            tooltip+="[Not Mounted] $display_label\\n"
            tooltip+="Device: $device\\n"
            tooltip+="Size: $size\\n"
            tooltip+="Type: ${fstype:-unknown}\\n\\n"
        fi
    done
    
    # Remove trailing newlines
    tooltip=$(echo -e "$tooltip" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
    
    # Determine icon and state
    if [ "$mounted_count" -gt 0 ]; then
        icon="$GLYPH_MOUNTED"
        state="mounted"
    else
        icon="$GLYPH_UNMOUNTED"
        state="unmounted"
    fi
    
    # Build text display
    if [ "$device_count" -eq 1 ]; then
        text="$icon"
    else
        text="$icon $device_count"
    fi
    
    # Output JSON using jq to handle escaping properly
    jq -nc \
        --arg text "$text" \
        --arg tooltip "$tooltip" \
        --arg class "$state" \
        --arg alt "$state" \
        '{text: $text, tooltip: $tooltip, class: $class, alt: $alt}'
}

main
