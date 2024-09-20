# sudo.nvim

This small plugin can be used to read and write files in neovim using root permissions with sudo.
It uses nui.nvim to prompt for the password, so no external askpass provider is required.

This plugin is experimental and may not work in all cases. Please report any issues you might encounter.

## Usage

You can use the `:SudoWrite` command to write the current buffer using sudo and the `:SudoRead` command to read a file using sudo.

## Installation using lazy.vim

```lua
  {
    "denialofsandwich/sudo.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = true,
  },
```
