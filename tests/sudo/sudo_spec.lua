-- Mock nui before requiring sudo
package.preload["nui.input"] = function()
	return {
		extend = function()
			return {
				init = function() end,
				mount = function() end,
				on = function() end,
				super = {
					init = function() end,
					mount = function() end,
				},
			}
		end,
	}
end
package.preload["nui.utils.autocmd"] = function()
	return { event = { BufLeave = "BufLeave" } }
end

local sudo = require("sudo")
local spy = require("luassert.spy")

describe("sudo.nvim", function()
	it("setup registers commands", function()
		sudo.setup({ commands = true })
		assert.is_not_nil(vim.fn.exists(":SudoWrite"))
		assert.is_not_nil(vim.fn.exists(":SudoRead"))
		assert.is_not_nil(vim.fn.exists(":SudoEdit"))
	end)

	it("buffer_read handles empty path", function()
		local spy_notify = spy.on(vim, "notify")
		sudo.buffer_read("")
		assert.spy(spy_notify).was_called_with("SudoRead: No path provided", vim.log.levels.ERROR)
		vim.notify:revert()
	end)

	it("buffer_write handles empty path and no buffer name", function()
		-- Create a new buffer with no name
		local buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_set_current_buf(buf)

		local spy_notify = spy.on(vim, "notify")
		sudo.buffer_write()
		assert.spy(spy_notify).was_called_with("SudoWrite: No file name", vim.log.levels.ERROR)
		vim.notify:revert()

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("sudo_run handles cancellation", function()
		local old_jobstart = vim.fn.jobstart
		vim.fn.jobstart = function()
			return 123
		end
		local old_jobstop = vim.fn.jobstop
		local jobstop_called = false
		vim.fn.jobstop = function(id)
			if id == 123 then
				jobstop_called = true
			end
		end

		local old_ask = require("sudo.password_input").ask_password
		require("sudo.password_input").ask_password = function(title, on_submit, on_cancel)
			if on_cancel then
				on_cancel()
			end
		end

		sudo.sudo_run("ls", function() end)

		vim.fn.jobstart = old_jobstart
		vim.fn.jobstop = old_jobstop
		require("sudo.password_input").ask_password = old_ask
	end)

	it("buffer_read creates buffer with correct content", function()
		local test_path = "/tmp/test_sudo_nvim"
		local test_content = { "line 1", "line 2" }

		-- Mock sudo_run to simulate successful read
		local old_sudo_run = sudo.sudo_run
		sudo.sudo_run = function(cmd, callback)
			callback(1, nil, "sudo_ready")
			callback(1, test_content, "stdout")
			callback(1, 0, "exit")
		end

		sudo.buffer_read(test_path)

		local bufnr = vim.fn.bufnr(test_path)
		assert.is_not_equal(-1, bufnr)
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		assert.are.same(test_content, lines)

		-- Cleanup
		vim.api.nvim_buf_delete(bufnr, { force = true })
		sudo.sudo_run = old_sudo_run
	end)
end)
