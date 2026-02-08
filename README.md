# sudo.nvim

This small plugin allows you to read and write files in Neovim using root permissions via `sudo`.
Unlike other solutions, it uses [nui.nvim](https://github.com/MunifTanjim/nui.nvim) to prompt for the password directly within Neovim, eliminating the need for an external `askpass` provider.

## Features

- **Direct Password Input**: Uses a floating UI (via `nui.nvim`) for sudo password entry.
- **Transparent Writing**: When you open a file with `:SudoRead`, the plugin automatically sets up the buffer so that standard `:w` commands work seamlessly using sudo.
- **Buffer Range Support**: `:SudoWrite` can be used with ranges (e.g., `:'<,'>SudoWrite chunk.txt`).

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "denialofsandwich/sudo.nvim",
  cmd = { "SudoRead", "SudoWrite", "SudoEdit" },
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  opts = {
    -- optional configuration
    -- commands = true,
  },
}
```

## Usage

### Commands

| Command | Description |
| :--- | :--- |
| `:SudoRead [path]` | Reads the specified file (or the current file if no path given) using sudo. |
| `:SudoEdit [path]` | Alias for `:SudoRead`. |
| `:SudoWrite [path]` | Writes the current buffer (or range) to the specified path using sudo. |

### Workflow

1.  Run `:SudoRead /etc/hosts`
2.  Enter your password in the popup.
3.  Edit the file as usual.
4.  Save normally with `:w`.

## Configuration

The plugin comes with the following default (trivial) configuration:

```lua
require("sudo").setup({
  -- Whether to create the default user commands
  commands = true,
})
```

## Requirements

- `sudo` executable in your `$PATH`.
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
