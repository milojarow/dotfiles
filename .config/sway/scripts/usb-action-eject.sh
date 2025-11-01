#!/bin/bash
# Eject (safely remove) USB device(s)

# Function to get USB devices
get_usb_devices() {
    while IFS= read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        rm=$(echo "$line" | awk '{print $2}')
        type=$(echo "$line" | awk '{print $3}')

        [[ "$rm" != "1" || "$type" != "part" ]] && continue

        hotplug=$(lsblk -ndo HOTPLUG "$device" 2>/dev/null)
        [[ "$hotplug" != "1" ]] && continue

        mountpoint=$(lsblk -ndo MOUNTPOINT "$device" 2>/dev/null)
        label=$(lsblk -ndo LABEL "$device" 2>/dev/null)

        echo "$device|$mountpoint|$label"
    done < <(lsblk -nlo NAME,RM,TYPE -p)
}

# Function to show notification
notify() {
    notify-send -u normal "USB Manager" "$1"
}

# Function to eject device
eject_device() {
    local device="$1"
    local label="$2"
    local mountpoint="$3"

    # Unmount first if mounted
    if [ -n "$mountpoint" ]; then
        if ! udisksctl unmount -b "$device" 2>/dev/null; then
            notify "Failed to unmount ${label:-$(basename "$device")}"
            return 1
        fi
    fi

    # Then power off (eject)
    if udisksctl power-off -b "$device" 2>/dev/null; then
        notify "Successfully ejected ${label:-$(basename "$device")}"
        pkill -RTMIN+15 waybar
        return 0
    else
        notify "Failed to eject ${label:-$(basename "$device")}"
        return 1
    fi
}

# Main logic
main() {
    mapfile -t usb_devices < <(get_usb_devices)

    if [ "${#usb_devices[@]}" -eq 0 ]; then
        notify "No USB devices found"
        exit 0
    fi

    # If only one USB, eject it
    if [ "${#usb_devices[@]}" -eq 1 ]; then
        IFS='|' read -r device mountpoint label <<< "${usb_devices[0]}"
        eject_device "$device" "$label" "$mountpoint"
        exit 0
    fi

    # Multiple USBs - ask which one or all
    menu_items=("All USB devices|all|")
    menu_items+=("---SEPARATOR---|separator|")

    for device_info in "${usb_devices[@]}"; do
        IFS='|' read -r device mountpoint label <<< "$device_info"
        device_name=$(basename "$device")
        display_label="${label:-$device_name}"

        if [ -n "$mountpoint" ]; then
            status="(mounted at $mountpoint)"
        else
            status="(not mounted)"
        fi

        menu_items+=("$display_label $status|single|$device|$label|$mountpoint")
    done

    selection=$(printf '%s\n' "${menu_items[@]}" | grep -v "SEPARATOR" | rofi -dmenu -i \
        -theme "$HOME/.config/rofi/themes/usb-manager.rasi" \
        -p "Eject USB" \
        -mesg "Select which USB(s) to safely remove" \
        -no-custom)

    [ -z "$selection" ] && exit 0

    action=$(echo "$selection" | cut -d'|' -f2)

    if [ "$action" = "all" ]; then
        # Eject all
        success_count=0
        for device_info in "${usb_devices[@]}"; do
            IFS='|' read -r device mountpoint label <<< "$device_info"
            if eject_device "$device" "$label" "$mountpoint"; then
                success_count=$((success_count + 1))
            fi
        done
        notify "Ejected $success_count of ${#usb_devices[@]} USB(s)"
    elif [ "$action" = "single" ]; then
        device=$(echo "$selection" | cut -d'|' -f3)
        label=$(echo "$selection" | cut -d'|' -f4)
        mountpoint=$(echo "$selection" | cut -d'|' -f5)
        eject_device "$device" "$label" "$mountpoint"
    fi
}

main
