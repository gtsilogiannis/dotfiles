#!/usr/bin/env bash
# Wi-Fi menu in Rofi (themed by ~/.config/rofi/config.rasi), opened from the bar.
# Selecting the connected network disconnects it, a saved one reconnects,
# a new secured one asks for the password.

notify() {
    command -v notify-send >/dev/null && notify-send -a "Wi-Fi" "$1" "${2:-}"
}

if [[ "$(nmcli -t -f WIFI general)" != "enabled" ]]; then
    choice=$(printf '%s\n' "Turn Wi-Fi on" | rofi -dmenu -i -p "Wi-Fi")
    [[ "$choice" == "Turn Wi-Fi on" ]] && nmcli radio wifi on
    exit 0
fi

# -t: colon-separated, -e no: SSID colons are not escaped, so the SSID is
# everything after the third field.
declare -A ssid_of
declare -A secure
lines=("Turn Wi-Fi off")
while IFS= read -r row; do
    in_use=${row%%:*};  rest=${row#*:}
    signal=${rest%%:*}; rest=${rest#*:}
    security=${rest%%:*}
    ssid=${rest#*:}
    [[ -z "$ssid" || -n "${secure[$ssid]+x}" ]] && continue       # hidden networks, duplicate APs
    secure[$ssid]=$([[ -n "$security" && "$security" != "--" ]] && echo 1 || echo 0)
    mark=$([[ "$in_use" == "*" ]] && echo "✓" || echo " ")
    lock=$([[ "${secure[$ssid]}" == 1 ]] && echo "" || echo " (open)")
    label=$(printf '%s  %3s%%  %s%s' "$mark" "$signal" "$ssid" "$lock")
    ssid_of[$label]=$ssid
    lines+=("$label")
done < <(nmcli -t -e no -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan auto)

choice=$(printf '%s\n' "${lines[@]}" | rofi -dmenu -i -p "Wi-Fi")
[[ -z "$choice" ]] && exit 0                                       # Esc

if [[ "$choice" == "Turn Wi-Fi off" ]]; then
    nmcli radio wifi off
    exit 0
fi

ssid=${ssid_of[$choice]}

if [[ "$choice" == ✓* ]]; then
    nmcli connection down id "$ssid" >/dev/null && notify "Disconnected" "$ssid"
elif nmcli -g NAME connection show | grep -Fxq -- "$ssid"; then
    nmcli connection up id "$ssid" >/dev/null && notify "Connected" "$ssid" || notify "Connection failed" "$ssid"
elif [[ "${secure[$ssid]}" == 1 ]]; then
    password=$(rofi -dmenu -password -p "Password for $ssid" < /dev/null)
    [[ -z "$password" ]] && exit 0
    nmcli device wifi connect "$ssid" password "$password" >/dev/null \
        && notify "Connected" "$ssid" || notify "Connection failed" "$ssid"
else
    nmcli device wifi connect "$ssid" >/dev/null && notify "Connected" "$ssid" || notify "Connection failed" "$ssid"
fi
