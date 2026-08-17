# /Users/ivan/Library/Application Support/com.mitchellh.ghostty/config
# Run `ghostty +show-config --default --docs` to view a list of
# # Any line beginning with a # is a comment. It's not possible to put
# # a comment after a config option, since it would be interpreted as a
# # part of the value. For example, this will have a value of "#123abc":
# background = #123abc
#
# # Empty values are used to reset config keys to default.
# key =
#
# # Some config options have unique syntaxes for their value,
# # which is explained in the docs for that config option.
# resize-overlay-duration = 4s 200ms
# ----------------------------------

font-family = "FiraCode Nerd Font"
font-size=13

window-inherit-font-size=true

theme = "Horizon"
# theme = "0x96f"
# theme = "duckbones"
# theme = "Arcoiris"
# Top Tier: duckbones
# Oxocarbon, Paraiso Dark, IC_Green_PPL, Horizon, Hopscotch.256, ENCOM, Espresso Libre, Duotone Dark, duckbones, Dracula, Darkside, Violet Dark
# Blue Dolphin,Bright Lights, Arcoiris, Cutie Pro, Desert,Gruvbox Dark Hard, Niji, Rupture, Raycast Dark, Tomorrow Night Burns, Xcode Dark hc, Twilight
# WHITE: Breadog,Balafonte Day, Gruvbox Light, Novel,Popping And Locking

window-height=30
window-width=110
#title="👻"
# window-subtitle=working-directory

background-opacity=1
background-blur=15

split-divider-color=#97c5fb
# split-divider-color=#330088
# split-divider-color=#f92672

macos-icon=official
macos-icon-frame=chrome

# keybind = cmd+ctrl+alt+shift+f>m=toggle_mouse_reporting

keybind = cmd+ctrl+alt+shift+f>m=toggle_mouse_reporting
keybind = cmd+ctrl+alt+shift+f>r=toggle_readonly
keybind = cmd+ctrl+alt+shift+f>o=toggle_background_opacity
keybind = cmd+ctrl+alt+shift+f>j=jump_to_prompt:1
keybind = cmd+ctrl+alt+shift+f>h=jump_to_prompt:-1
keybind = cmd+ctrl+alt+shift+f>p=jump_to_prompt:-1

keybind=shift+enter=text:\n
# Hyper (cmd+ctrl+alt+shift) + ` toggles the quick terminal globally

keybind = global:cmd+backquote=toggle_quick_terminal
keybind = global:ctrl+alt+cmd+shift+backquote=toggle_quick_terminal

# keybind=shift+enter=unbind

# Cmd+Shift+E opens Ghostty config in Helix
keybind=super+shift+e=open_config

# Cmd+Shift+R reloads Ghostty config
keybind=super+shift+r=reload_config

# Cmd+Shift+T prompts for the current surface title
keybind=super+shift+t=prompt_surface_title

# Random split divider color — handled by Hammerspoon (Cmd+Shift+O)

# Alt key → traditional escape sequences (zsh doesn't understand CSI u)
keybind=alt+backspace=text:\x1b\x7f
keybind=alt+left=esc:b
keybind=alt+right=esc:f
keybind=alt+d=esc:d
keybind=alt+f=esc:f
keybind=alt+b=esc:b

keybind=ctrl+d=unbind

keybind=super+shift+up=toggle_split_zoom

# Resize splits — larger jumps (Cmd+Ctrl+Shift+Arrow, delta=24)
keybind=super+ctrl+shift+up=resize_split:up,24
keybind=super+ctrl+shift+down=resize_split:down,24
keybind=super+ctrl+shift+left=resize_split:left,24
keybind=super+ctrl+shift+right=resize_split:right,24







