local M = {}

-- Ported to the Yazi 26 previewer API (peek/seek receive `job`).
function M:peek(job)
	local args = job.file.cha.len == 0 and {} or { "--border", "none", "--terminal-width", tostring(job.area.w) }
	args[#args + 1] = tostring(job.file.url)
	local child, err = Command("hexyl"):arg(args):stdout(Command.PIPED):stderr(Command.PIPED):spawn()
	if not child then
		return require("empty").msg(job, "Failed to start `hexyl`: " .. tostring(err))
	end

	local limit = job.area.h
	local i, lines = 0, ""
	repeat
		local next, event = child:read_line()
		if event == 1 then
			ya.err(tostring(event))
		elseif event ~= 0 then
			break
		end

		i = i + 1
		if i > job.skip then
			lines = lines .. next
		end
	until i >= job.skip + limit

	child:start_kill()
	if job.skip > 0 and i < job.skip + limit then
		ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
	else
		lines = lines:gsub("\t", string.rep(" ", rt.preview.tab_size))
		ya.preview_widget(job, ui.Text.parse(lines):area(job.area))
	end
end

function M:seek(job) require("code"):seek(job) end

return M
