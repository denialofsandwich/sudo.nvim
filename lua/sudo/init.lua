local M = {}

local config = require("sudo.config")
local password_input = require("sudo.password_input")

--- Set up the plugin
--- @param user_opts SudoConfig
M.setup = function(user_opts)
	config.setup(user_opts)

	-- add commands
	if config.opts.commands then
		vim.cmd([[
      command! SudoWrite lua require("sudo").buffer_write()
      command! -nargs=1 SudoRead lua require("sudo").buffer_read(<f-args>)
    ]])
	end
end

--- @param cmd string
--- @param callback fun(jobid: number, data: table, event: string)
M.sudo_run = function(cmd, callback)
	local attempt = 0
	local password_correct = false
	local on_event = function(jobid, data, event)
		-- print(event .. ":", vim.inspect(data))

		if event == "stderr" and data[1] == "enter_password" then
			attempt = attempt + 1
			password_input.ask_password("Password (Attempt: " .. attempt .. ")", function(password)
				vim.fn.chansend(jobid, { password, "" })
			end)
		elseif event == "stderr" and string.find(data[1], "incorrect password") then
			print("Too many failed attempts")
		elseif event == "stdout" and data[1] == "password_correct" then
			password_correct = true
		end

		if password_correct == true then
			callback(jobid, data, event)
		end
	end

	vim.fn.jobstart('sudo -S -p enter_password -- bash -c "echo password_correct ; ' .. cmd .. '"', {
		cwd = vim.fn.getcwd(),
		on_exit = on_event,
		on_stdout = on_event,
		on_stderr = on_event,
	})
end

--- @param path string
M.buffer_write = function(path)
	path = path or vim.api.nvim_buf_get_name(0)
	M.sudo_run("cat > " .. path, function(jobid, data, event)
		if event == "stdout" and data[1] == "password_correct" then
			local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			table.insert(content, "")

			vim.fn.chansend(jobid, content)
			vim.fn.chanclose(jobid, "stdin")
		elseif event == "exit" and data == 0 then
			vim.cmd("edit! " .. path)
		end
	end)
end

--- @param path string
M.buffer_read = function(path)
	local ready_to_read = false
	M.sudo_run("cat " .. path, function(jobid, data, event)
		if event == "stdout" and data[1] == "password_correct" then
			ready_to_read = true
		elseif ready_to_read then
			ready_to_read = false
			table.remove(data, #data)

			local buf = vim.api.nvim_create_buf(true, false)
			vim.api.nvim_buf_set_name(buf, path)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, data)
			vim.api.nvim_set_option_value("modified", false, { buf = buf })
			vim.api.nvim_set_current_buf(buf)
		end
	end)
end

return M
