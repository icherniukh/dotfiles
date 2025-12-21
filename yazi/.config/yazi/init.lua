require("full-border"):setup()
require("git"):setup()

require("mime-ext"):setup {
	-- Expand the existing filename database (lowercase), for example:
	with_files = {
		Config = "text/perl",
		-- ...
	},

	-- Expand the existing extension database (lowercase), for example:
	with_exts = {
		mk = "text/makefile",
		-- ...
	},

	-- If the mime-type is not in both filename and extension databases,
	-- then fallback to Yazi's preset `mime` plugin, which uses `file(1)`
	fallback_file1 = true,
}

-- require("git"):setup()
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
