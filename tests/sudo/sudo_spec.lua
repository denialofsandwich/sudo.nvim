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
end)
