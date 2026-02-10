--- @class SudoConfig
--- @field commands boolean

local M = {
	--- @type SudoConfig
	opts = {
		commands = true,
	},
}

M.setup = function(config)
	if config ~= nil then
		M.opts = vim.tbl_deep_extend("force", M.opts, config)
	end
end

return M
