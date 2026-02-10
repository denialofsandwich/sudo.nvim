local root = vim.fn.fnamemodify(".", ":p")
local plenary_path = "/home/rene/.local/share/nvim/lazy/plenary.nvim"
local nui_path = "/home/rene/.local/share/nvim/lazy/nui.nvim"

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(plenary_path)
vim.opt.runtimepath:prepend(nui_path)

package.path = package.path .. ";" .. plenary_path .. "/lua/?.lua"
package.path = package.path .. ";" .. plenary_path .. "/lua/?/init.lua"
package.path = package.path .. ";" .. nui_path .. "/lua/?.lua"
package.path = package.path .. ";" .. nui_path .. "/lua/?/init.lua"
package.path = package.path .. ";" .. root .. "lua/?.lua"
package.path = package.path .. ";" .. root .. "lua/?/init.lua"
