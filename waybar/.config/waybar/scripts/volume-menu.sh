#!/bin/bash
if pgrep -x "pavucontrol" > /dev/null; then
    killall pavucontrol
else
    # Apply window rules at Hyprland runtime
    hyprctl keyword windowrulev2 "float, class:^(pavucontrol|org.pulseaudio.pavucontrol)$"
    hyprctl keyword windowrulev2 "size 640 450, class:^(pavucontrol|org.pulseaudio.pavucontrol)$"
    hyprctl keyword windowrulev2 "move 100%-655 42, class:^(pavucontrol|org.pulseaudio.pavucontrol)$"
    hyprctl keyword windowrulev2 "pin, class:^(pavucontrol|org.pulseaudio.pavucontrol)$"
    
    pavucontrol &
fi
