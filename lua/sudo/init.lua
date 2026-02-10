local M = {}

local config = require("sudo.config")
local password_input = require("sudo.password_input")

--- @param user_opts SudoConfig
M.setup = function(user_opts)
	config.setup(user_opts)

	if config.opts.commands then
		vim.api.nvim_create_user_command("SudoWrite", function(opts)
			local path = opts.args ~= "" and opts.args or nil
			M.buffer_write(path, opts.line1, opts.line2)
		end, {
			nargs = "?",
			complete = "file",
			range = "%",
			desc = "Write current buffer or given path with sudo",
			force = true,
		})

		vim.api.nvim_create_user_command("SudoRead", function(opts)
			local path = opts.args ~= "" and opts.args or vim.api.nvim_buf_get_name(0)
			M.buffer_read(path)
		end, { nargs = "?", complete = "file", desc = "Read given path with sudo", force = true })

		vim.api.nvim_create_user_command("SudoEdit", function(opts)
			local path = opts.args ~= "" and opts.args or vim.api.nvim_buf_get_name(0)
			M.buffer_read(path)
		end, { nargs = "?", complete = "file", desc = "Read given path with sudo (alias for SudoRead)", force = true })
	end
end

--- @param cmd string
--- @param callback fun(jobid: number, data: any, event: string)
M.sudo_run = function(cmd, callback)
	if vim.fn.executable("sudo") ~= 1 then
		vim.notify("Sudo: sudo command not found", vim.log.levels.ERROR)
		return
	end

	local attempt = 0
	local password_correct = false

	local on_event = function(jobid, data, event)
		if event == "stderr" then
			for _, line in ipairs(data) do
				if line == "" then
					goto continue
				end

				if line:find("enter_password") then
					attempt = attempt + 1
					vim.schedule(function()
						password_input.ask_password("Password (Attempt: " .. attempt .. ")", function(password)
							vim.fn.chansend(jobid, { password, "" })
						end, function()
							vim.fn.jobstop(jobid)
							vim.notify("Sudo: Operation cancelled", vim.log.levels.WARN)
						end)
					end)
					return
				end

				if line:find("incorrect password") or line:find("try again") then
					vim.notify("Sudo: Incorrect password", vim.log.levels.ERROR)
				end

				::continue::
			end
		elseif event == "stdout" then
			for i, line in ipairs(data) do
				if line == "" then
					goto continue
				end

				if not password_correct then
					if line == "password_correct" then
						password_correct = true
						callback(jobid, nil, "sudo_ready")

						local remaining = {}
						for j = i + 1, #data do
							if data[j] ~= "" then
								table.insert(remaining, data[j])
							end
						end
						if #remaining > 0 then
							callback(jobid, remaining, event)
						end
						return
					end
				else
					callback(jobid, { line }, event)
				end

				::continue::
			end
		elseif event == "exit" then
			callback(jobid, data, event)
		end
	end

	local full_cmd = string.format('sudo -S -p enter_password -- /bin/sh -c "echo password_correct ; %s"', cmd)

	local jobid = vim.fn.jobstart(full_cmd, {
		cwd = vim.fn.getcwd(),
		on_exit = on_event,
		on_stdout = on_event,
		on_stderr = on_event,
	})

	if jobid <= 0 then
		vim.notify("Sudo: Failed to start job: " .. jobid, vim.log.levels.ERROR)
	end
end

--- @param path string|nil
--- @param line1 number|nil
--- @param line2 number|nil
M.buffer_write = function(path, line1, line2)
	path = path or vim.api.nvim_buf_get_name(0)
	if not path or path == "" then
		vim.notify("SudoWrite: No file name", vim.log.levels.ERROR)
		return
	end

	path = vim.fn.expand(path)
	line1 = line1 or 1
	line2 = line2 or -1

	M.sudo_run("cat > " .. vim.fn.shellescape(path), function(jobid, data, event)
		if event == "sudo_ready" then
			local bufnr = vim.fn.bufnr(path)
			local buf = bufnr ~= -1 and bufnr or 0
			local content = vim.api.nvim_buf_get_lines(buf, line1 - 1, line2, false)
			if #content > 0 and content[#content] ~= "" then
				table.insert(content, "")
			end
			vim.fn.chansend(jobid, content)
			vim.fn.chanclose(jobid, "stdin")
		elseif event == "exit" then
			if data == 0 then
				vim.notify("SudoWrite: Written to " .. path)
				local bufnr = vim.fn.bufnr(path)
				if bufnr ~= -1 then
					vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
				end
			else
				vim.notify("SudoWrite failed with exit code " .. data, vim.log.levels.ERROR)
			end
		end
	end)
end

--- @param path string
M.buffer_read = function(path)
	if not path or path == "" then
		vim.notify("SudoRead: No path provided", vim.log.levels.ERROR)
		return
	end

	path = vim.fn.expand(path)
	local lines = {}
	local sudo_ready = false

	M.sudo_run("cat " .. vim.fn.shellescape(path), function(jobid, data, event)
		if event == "sudo_ready" then
			sudo_ready = true
		elseif event == "stdout" and sudo_ready then
			vim.list_extend(lines, data)
		elseif event == "exit" then
			if data == 0 then
				if #lines > 0 and lines[#lines] == "" then
					table.remove(lines, #lines)
				end

				local bufnr = vim.fn.bufnr(path)
				local buf = bufnr ~= -1 and bufnr or vim.api.nvim_create_buf(true, false)

				if bufnr == -1 then
					vim.api.nvim_buf_set_name(buf, path)
				end

				vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
				vim.api.nvim_set_option_value("modified", false, { buf = buf })
				vim.api.nvim_set_current_buf(buf)
				vim.cmd("filetype detect")

				local group = vim.api.nvim_create_augroup("SudoWrite_" .. buf, { clear = true })
				vim.api.nvim_create_autocmd("BufWriteCmd", {
					group = group,
					buffer = buf,
					callback = function()
						M.buffer_write(path)
					end,
				})
			else
				vim.notify("SudoRead failed with exit code " .. data, vim.log.levels.ERROR)
			end
		end
	end)
end

return M
