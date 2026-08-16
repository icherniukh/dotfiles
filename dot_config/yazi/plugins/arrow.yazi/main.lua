--- @sync entry

local function entry(_, job)
	local current = cx.active.current
	if not current or #current.files == 0 then return end

	local new = (current.cursor + job.args[1]) % #current.files
	ya.emit("arrow", { new - current.cursor })
end

return { entry = entry }
