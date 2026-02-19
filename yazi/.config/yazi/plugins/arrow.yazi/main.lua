--- @sync entry

local function entry(_, job)
	local current = cx.active.current
  if not current then return end

	local new = (current.cursor + job.args[1]) % #current.files
	-- ya.manager_emit("arrow", { new - current.cursor })
	ya.mgr_emit("arrow", { new - current.cursor })
end

return { entry = entry }
