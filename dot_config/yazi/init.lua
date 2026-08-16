
require("git"):setup()

require("full-border"):setup()

require("mime-ext.local"):setup {
	-- Expand the existing filename database (lowercase), for example:
	with_files = {
		makefile = "text/makefile",
		Config = "text/perl",
		-- ...
	},

	-- Expand the existing extension database (lowercase), for example:
	with_exts = {
		mk = "text/makefile",
		-- ...
	},

	-- If the MIME type is not in both filename and extension databases,
	-- then fallback to Yazi's preset `mime.local` plugin, which uses `file(1)`
	fallback_file1 = false,
}

if ya.target_family() == "unix" and jit and jit.os == "OSX" then
	require("mactag"):setup {
		keys = {
			r = "Red",
			o = "Orange",
			y = "Yellow",
			g = "Green",
			b = "Blue",
			p = "Purple",
		},
		colors = {
			Red = "#ee7b70",
			Orange = "#f5bd5c",
			Yellow = "#fbe764",
			Green = "#91fc87",
			Blue = "#5fa3f8",
			Purple = "#cb88f8",
		},
	}
end

local path_sep = package.config:sub(1, 1)
local home_path = os.getenv("HOME")
local bookmarks = {
	{
		tag = "Home",
		path = home_path .. path_sep,
		key = "h",
	},
	{
		tag = "Repos",
		path = home_path .. path_sep .. "repos" .. path_sep,
		key = "p",
	},
	{
		tag = "Config",
		path = home_path .. path_sep .. ".config" .. path_sep,
		key = "c",
	},
}

require("yamb"):setup {
	bookmarks = bookmarks,
	jump_notify = true,
	cli = "fzf",
	keys = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
	path = home_path .. path_sep .. ".config" .. path_sep .. "yazi" .. path_sep .. "bookmark",
}

-- require("starship"):setup()
-- require("simple-status"):setup()

-- Custom sort
-- https://yazi-rs.github.io/docs/tips#folder-rules

-- function Linemode:size_and_mtime()
-- 	local time = math.floor(self._file.cha.mtime or 0)
-- 	if time == 0 then
-- 		time = ""
-- 	elseif os.date("%Y", time) == os.date("%Y") then
-- 		time = os.date("%b %d %H:%M", time)
-- 	else
-- 		time = os.date("%b %d  %Y", time)
-- 	end

-- 	local size = self._file:size()
-- 	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
-- end
