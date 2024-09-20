local Input = require("nui.input")
local event = require("nui.utils.autocmd").event

-- Stolen from: https://github.com/MunifTanjim/nui.nvim/wiki/nui.input
local SecretInput = Input:extend("SecretInput")

function SecretInput:init(popup_options, options)
	assert(
		not options.conceal_char or vim.api.nvim_strwidth(options.conceal_char) == 1,
		"conceal_char must be a single char"
	)

	popup_options.win_options = vim.tbl_deep_extend("force", popup_options.win_options or {}, {
		conceallevel = 2,
		concealcursor = "nvi",
	})

	SecretInput.super.init(self, popup_options, options)

	self._.conceal_char = type(options.conceal_char) == "nil" and "*" or options.conceal_char
end

function SecretInput:mount()
	SecretInput.super.mount(self)

	local conceal_char = self._.conceal_char
	local prompt_length = vim.api.nvim_strwidth(vim.fn.prompt_getprompt(self.bufnr))

	vim.api.nvim_buf_call(self.bufnr, function()
		vim.cmd(string.format(
			[[
        syn region SecretValue start=/^/ms=s+%s end=/$/ contains=SecretChar
        syn match SecretChar /./ contained conceal %s
      ]],
			prompt_length,
			conceal_char and "cchar=" .. (conceal_char or "*") or ""
		))
	end)
end

--- @param title string
--- @param on_submit fun(value: string)
local ask_password = function(title, on_submit)
	title = title or "Password"

	local input = SecretInput({
		position = "50%",
		size = {
			width = 30,
		},
		border = {
			style = "single",
			text = {
				top = title,
				top_align = "center",
			},
		},
	}, {
		prompt = "> ",
		default_value = "",
		on_submit = on_submit,
	})

	-- mount/open the component
	input:mount()

	-- unmount component when cursor leaves buffer
	input:on(event.BufLeave, function()
		input:unmount()
	end)
end

--- @class PasswordInput
--- @field ask_password fun(title: string, on_submit: fun(value: string))

--- @type PasswordInput
return {
	ask_password = ask_password,
}
