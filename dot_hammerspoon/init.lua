local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Hyperkey + number → focus app
-- (2 = Ghostty quick terminal, handled by Ghostty global keybind)
local appBindings = {
    {"1", "Ghostty"},
    {"3", "Arc"},
    {"4", "Finder"},
    {"5", "CotEditor"},
    {"6", "Visual Studio Code"},
    {"7", "Obsidian"},
}

for _, binding in ipairs(appBindings) do
    hs.hotkey.bind(hyper, binding[1], function()
        hs.application.launchOrFocus(binding[2])
    end)
end

-- Redirect Finder windows to Marta
hs.window.filter.new('Finder'):subscribe(hs.window.filter.windowCreated, function(window, appName)
    local success, finderPath = hs.osascript.applescript([[
        tell application "Finder"
            set folderPath to POSIX path of (target of front window)
        end tell
        return folderPath
    ]])

    if success and finderPath ~= "" then
        os.execute(string.format('open -a Marta "%s"', finderPath))
        hs.osascript.applescript([[
            tell application "Finder"
                close every window
            end tell
        ]])
    end
end)


-- Ghostty script shortcuts (Hammerspoon runs these so they don't type into the terminal)
hs.hotkey.bind({"cmd", "shift"}, "o", function()
    os.execute(os.getenv("HOME") .. "/.config/ghostty/scripts/random-split-color.sh")
end)
hs.hotkey.bind({"cmd", "shift"}, "m", function()
    os.execute(os.getenv("HOME") .. "/.config/ghostty/scripts/random-tab-color.sh")
end)

hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()
