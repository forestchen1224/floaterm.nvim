# floaterm.nvim

A lightweight Neovim plugin for managing floating terminals with ease.

## ✨ Features

- 🪟 **Floating terminals** - Beautiful floating windows for terminal sessions
- 🔄 **Multiple terminals** - Create and manage multiple terminal instances
- 🎯 **Terminal picker** - Quick selection with fzf-lua or builtin picker
- 📐 **Resizable windows** - Dynamic resizing with configurable ratios
- ⌨️ **Navigation** - Easy switching between terminals with next/prev
- 🎨 **Customizable** - Configurable borders, dimensions, and behavior
- 🔧 **Command execution** - Run any command in floating terminals

## 📋 Requirements

- Neovim 0.5+
- Optional: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for enhanced picker with preview

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'forestchen1224/floaterm.nvim',
  dependencies = {
    'ibhagwan/fzf-lua', -- Optional: for enhanced picker with preview
  },
  config = function()
    require('floaterm').setup({
      -- Optional: override default configuration
      width = 0.9,
      height = 0.9,
      border = 'rounded',
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
  width = 0.9,        -- Terminal width as fraction of screen width (0.1-0.99)
  height = 0.9,       -- Terminal height as fraction of screen height (0.1-0.99)
  style = "minimal",  -- Window style: "minimal" for clean UI
  border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
  autoclose = false,  -- Whether to automatically close terminal when job exits
  picker = "fzf-lua", -- Terminal picker: "fzf-lua" or "builtin"
})
```

### Example Keymaps

```lua
local floaterm = require('floaterm')

-- Basic terminal operations
vim.keymap.set({ 'n', 't' }, '<leader>tf', function() floaterm.open() end, 
  { silent = true, desc = 'Open floating terminal' })
vim.keymap.set({ 'n', 't' }, '<leader>tt', function() floaterm.toggle() end, 
  { silent = true, desc = 'Toggle floating terminal' })

-- Terminal navigation
vim.keymap.set({ 'n', 't' }, '<leader>tn', function() floaterm.next() end, 
  { silent = true, desc = 'Next terminal' })
vim.keymap.set({ 'n', 't' }, '<leader>tp', function() floaterm.prev() end, 
  { silent = true, desc = 'Previous terminal' })
vim.keymap.set({ 'n', 't' }, '<leader>tl', function() floaterm.pick() end, 
  { silent = true, desc = 'Pick terminal' })

-- Terminal resizing
vim.keymap.set({ 'n', 't' }, '<leader>t=', function() floaterm.resize(0.05) end, 
  { silent = true, desc = 'Increase terminal size' })
vim.keymap.set({ 'n', 't' }, '<leader>t-', function() floaterm.resize(-0.05) end, 
  { silent = true, desc = 'Decrease terminal size' })

-- Example: Open terminal with specific command
vim.keymap.set('n', '<leader>tg', function()
  floaterm.open({}, 'lazygit')
end, { silent = true, desc = 'Open lazygit' })

-- Example: File manager in current directory
vim.keymap.set('n', '<leader>tv', function()
  local cmd = "ranger"
  local file = vim.fn.expand("%:p")
  if file and file ~= "" then
    cmd = cmd .. " --selectfile=" .. vim.fn.shellescape(file)
  end
  floaterm.open({}, cmd)
end, { silent = true, desc = "Open ranger at current file" })
```

## 🚀 Usage

### Core Functions

#### `open(opts, cmd)`
Creates and opens a new floating terminal.

- `opts` (table, optional): Configuration overrides for this terminal
- `cmd` (string, optional): Command to run (defaults to `vim.o.shell`)

```lua
-- Open terminal with default shell
require('floaterm').open()

-- Open terminal with custom command
require('floaterm').open({}, 'htop')

-- Open terminal with custom options
require('floaterm').open({ width = 0.5, height = 0.5 }, 'python')
```

#### `new(opts, cmd)`
Creates a new terminal instance without opening it.

```lua
local term = require('floaterm').new({ width = 0.8 }, 'nvim')
term:open() -- Open when ready
```

#### `toggle()`
Toggles the visibility of the current terminal.

#### `next()` / `prev()`
Navigate between multiple terminal instances.

#### `pick()`
Opens a picker to select from available terminals. Uses fzf-lua with preview if available, otherwise falls back to `vim.ui.select`.

#### `resize(delta)`
Resize the current terminal by the specified delta (positive or negative float).

```lua
require('floaterm').resize(0.1)  -- Increase size by 10%
require('floaterm').resize(-0.1) -- Decrease size by 10%
```

#### `count()`
Returns the number of active terminals.

### Advanced Usage

#### Creating Specialized Terminals

```lua
local floaterm = require('floaterm')

-- Create a hidden terminal for background tasks
local background_term = floaterm.new({ hide = true }, 'watch -n1 "df -h"')

-- Create a compact terminal for quick commands
local mini_term = floaterm.new({ width = 0.4, height = 0.3 })
```

#### Custom Border Styles

```lua
-- Using array for custom border characters
floaterm.open({
  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
})

-- Using predefined styles
floaterm.open({ border = "double" })
floaterm.open({ border = "shadow" })
```

## 🎨 Picker Options

### fzf-lua Picker (Recommended)
When [fzf-lua](https://github.com/ibhagwan/fzf-lua) is available, the picker provides:
- Live preview of terminal content
- Fuzzy searching
- Better visual presentation
- Customizable actions

### Builtin Picker
Falls back to `vim.ui.select` when fzf-lua is not available:
- Simple list selection
- Works with any `vim.ui.select` implementation
- No additional dependencies

## 🔧 API Reference

### Configuration Schema

```lua
{
  width = number,     -- 0.1 to 0.99 (fraction of screen width)
  height = number,    -- 0.1 to 0.99 (fraction of screen height)
  style = string,     -- Window style for nvim_open_win
  border = string|table, -- Border style or custom border array
  autoclose = boolean,   -- Auto-close terminal on job exit
  picker = string,       -- "fzf-lua" or "builtin"
}
```

### Terminal Object Methods

- `term:open()` - Open the terminal window
- `term:toggle()` - Toggle terminal visibility
- `term:hide()` - Hide the terminal window
- `term:show()` - Show the terminal window

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

