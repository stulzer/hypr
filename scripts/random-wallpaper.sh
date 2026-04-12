#!/bin/bash

# List your images
directory="~/.config/hyprpaper"
img1="$directory/wallpaper.png"
img2="$directory/wallpaper-2.png"
img3="$directory/wallpaper-3.jpg"

# Put them in an array
images=("$img1" "$img2" "$img3")

# Shuffles the array and picks the first two
random_images=($(printf "%s\n" "${images[@]}" | shuf))

# Apply to your specific monitors
hyprctl hyprpaper wallpaper "eDP-1,${random_images[0]}"
hyprctl hyprpaper wallpaper "DP-2,${random_images[1]}"
