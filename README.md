# floaterm.nvim

A lightweight Neovim plugin for managing floating terminals with ease.

## ✨ Features

- 🪟 **Floating terminals** - Beautiful floating windows for terminal sessions
- 🔄 **Multiple terminals** - Create and manage multiple terminal instances with unique IDs
- 🎯 **Terminal picker** - Quick selection with fzf-lua, snack, or builtin picker
- 📐 **Resizable windows** - Dynamic resizing with configurable ratios
- 🎨 **Customizable** - Configurable borders, dimensions, and behavior
- 🔧 **Command execution** - Run any command in floating terminals
- 🏷️ **Named terminals** - Create terminals with custom IDs for easy reference
- 🚀 **Auto-start terminals** - Configure terminals to start automatically on plugin load

## 📋 Requirements

- Neovim 0.11.0+
- Optional: [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [snack.nvim](https://github.com/folke/snack.nvim) for enhanced picker with preview

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'forestchen1224/floaterm.nvim',
  dependencies = {
    'ibhagwan/fzf-lua', -- Optional: for enhanced picker with preview
    -- or 'folke/snack.nvim', -- Alternative picker option
  },
  config = function()
    require('floaterm').setup({
      -- Optional: override default configuration
      opts = {
        width = 0.9,
        height = 0.9,
        border = 'rounded',
      }
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'forestchen1224/floaterm.nvim',
  requires = { 'ibhagwan/fzf-lua' }, -- Optional
  config = function()
    require('floaterm').setup()
  end
}
```


## ⚙️ Configuration

### Default Options

```lua
require('floaterm').setup({
  picker = "fzf-lua",  -- Terminal picker: "fzf-lua", "snack", or "builtin"
  opts = {
    width = 0.9,        -- Terminal width as fraction of screen width (0.1-0.99)
    height = 0.9,       -- Terminal height as fraction of screen height (0.1-0.99)
    style = "minimal",  -- Window style: "minimal" for clean UI
    border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    autoclose = false,  -- Whether to automatically close terminal when job exits
    cmd = nil,          -- Default command to run (defaults to vim.o.shell)
    pick = true,        -- Whether terminal appears in picker by default
  },
  start_cmds = {        -- Terminals to create automatically on startup
    -- Example:
    -- {
    --   id = "lazygit",
    --   opts = {
    --     pick = false,
    --     cmd = "lazygit",
    --   },
    -- },
  },
})
```

Note: if a terminal is not pickable, it is not picked by the picker, nor picked 
by the default `open()` or `toggle()`, you can only access it via the ID by
`open(ID)` or `toggle(ID)`.

### Example Keymaps

```lua
local floaterm = require('floaterm')

-- Basic terminal operations
vim.keymap.set({ 'n', 't' }, '<leader>tf', function() floaterm.new() end, 
  { silent = true, desc = 'Open new floating terminal' })
vim.keymap.set({ 'n', 't' }, '<leader>tt', function() floaterm.toggle() end, 
  { silent = true, desc = 'Toggle floating terminal' })

-- Terminal navigation
vim.keymap.set({ 'n', 't' }, '<leader>tl', function() floaterm.pick() end, 
  { silent = true, desc = 'Pick terminal' })

-- Terminal resizing
vim.keymap.set({ 'n', 't' }, '<leader>t=', function() floaterm.resize(0.05) end, 
  { silent = true, desc = 'Increase terminal size' })
vim.keymap.set({ 'n', 't' }, '<leader>t-', function() floaterm.resize(-0.05) end, 
  { silent = true, desc = 'Decrease terminal size' })

-- Open specific terminal by ID
vim.keymap.set('n', '<leader>to', function()
  floaterm.toggle('lazygit') -- Opens the terminal with ID 'lazygit'
end, { silent = true, desc = 'Open specific terminal' })
```

## 🚀 Usage

### Core Functions

#### `new(id, opts)`
Creates and opens a new floating terminal with optional custom ID.

- `id` (string, optional): Custom ID for the terminal (auto-generated if not provided)
- `opts` (table, optional): Configuration overrides for this terminal

```lua
-- Open terminal with auto-generated ID
require('floaterm').new()

-- Open terminal with custom ID and command
require('floaterm').new('python-repl', { cmd = 'python' })

-- Open terminal with custom options
require('floaterm').new('small-term', { width = 0.5, height = 0.5 })
```

#### `open(id)`
Opens an existing terminal by ID, or the last active terminal if no ID specified.

```lua
-- Open the current/last active terminal
require('floaterm').open()

-- Open specific terminal by ID
require('floaterm').open('lazygit')
```

#### `toggle(id)`
Toggles the visibility of a terminal. Creates a new one if none exists.

```lua
-- Toggle current terminal
require('floaterm').toggle()

-- Toggle specific terminal
require('floaterm').toggle('python-repl')
```

#### `close(id)`
Closes a terminal and removes it from the terminal list.

```lua
-- Close current terminal
require('floaterm').close()

-- Close specific terminal
require('floaterm').close('temp-terminal')
```

#### `pick()`
Opens a picker to select from available terminals. Uses the configured picker (fzf-lua, snack, or builtin).

#### `resize(delta)`
Resize the current terminal by the specified delta (positive or negative float).

```lua
require('floaterm').resize(0.1)  -- Increase size by 10%
require('floaterm').resize(-0.1) -- Decrease size by 10%
```

### Advanced Usage

#### Auto-start Terminals
Configure terminals to start automatically when the plugin loads:

```lua
require('floaterm').setup({
  start_cmds = {
    {
      id = "main",
      opts = {
        cmd = vim.o.shell,
        pick = true,
      },
    },
    {
      id = "git",
      opts = {
        cmd = "lazygit",
        pick = false,  -- Don't show in picker
        width = 0.8,
        height = 0.8,
      },
    },
  },
})
```

#### Creating Specialized Terminals

```lua
local floaterm = require('floaterm')

-- Create a hidden terminal for background tasks
floaterm.new('background', { pick = false, cmd = 'watch -n1 "df -h"' })

-- Create a compact terminal for quick commands
floaterm.new('mini', { width = 0.4, height = 0.3 })

-- File manager that starts at current file location
local function open_ranger()
  local file = vim.fn.expand("%:p")
  local cmd = "ranger"
  if file and file ~= "" then
    cmd = cmd .. " --selectfile=" .. vim.fn.shellescape(file)
  end
  floaterm.new('ranger', { cmd = cmd })
end

vim.keymap.set('n', '<leader>tr', open_ranger, { desc = 'Open ranger at current file' })
```

#### Custom Border Styles

```lua
-- Using array for custom border characters
floaterm.new('custom-border', {
  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
})

-- Using predefined styles
floaterm.new('double-border', { border = "double" })
floaterm.new('shadow-border', { border = "shadow" })
```

## 🎨 Picker Options

### fzf-lua Picker (Recommended)
When [fzf-lua](https://github.com/ibhagwan/fzf-lua) is available, the picker provides:
- Live preview of terminal content
- Fuzzy searching by terminal ID and title
- Better visual presentation
- Keyboard shortcuts (Ctrl-N for next)

### Snack Picker
When [snack.nvim](https://github.com/folke/snack.nvim) is available:
- Integration with Snack's picker system
- Consistent UI with other Snack components

### Builtin Picker
Falls back to `vim.ui.select` when enhanced pickers are not available:
- Simple list selection
- Works with any `vim.ui.select` implementation
- No additional dependencies

## 🔧 API Reference

### Terminal Object Methods

When you get a terminal object via `find()`, it has these methods:
- `term:open()` - Open the terminal window
- `term:toggle()` - Toggle terminal visibility
- `term:hide()` - Hide the terminal window
- `term:show()` - Show the terminal window
- `term:close()` - Close and stop the terminal

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
