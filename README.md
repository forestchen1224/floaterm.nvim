# floaterm.nvim

## Introduction

`floaterm.nvim` is just a simple plugin to provide floating terminals to
*Neovim*. You can create terminals that run any command, toggle, resize,
or select them using `next/prev` commands or a picker.

## Requirements

The picker can be [snacks.nvim](https://github.com/folke/snacks.nvim) if you
have it installed, and if not, it will use the standard `vim.ui.select`.
`snacks.nvim` is preferred because it also provides a nice preview and
highlighting groups.

## Installation and Configuration

There are no default keymaps or settings for the highlighting groups.

If you use [lazy.nvim](https://github.com/folke/lazy.nvim), configuring the
plugin could look like this:

``` lua
{
  'dawsers/floaterm.nvim',
  -- You don't need this dependency, but the picker is nicer, with preview
  dependencies = {
    'folke/snacks.nvim',
  },
  config = function()
    local terminal = require('floaterm')
    -- You need to call setup
    terminal.setup()
    vim.keymap.set({ 'n', 't' }, '<leader>tf', function() terminal.open() end, { silent = true, desc = 'New floating terminal' })
    vim.keymap.set({ 'n', 't' }, '<leader>tn', function() terminal.next() end, { silent = true, desc = 'Next floating terminal' })
    vim.keymap.set({ 'n', 't' }, '<leader>tp', function() terminal.prev() end, { silent = true, desc = 'Prev floating terminal' })
    vim.keymap.set({ 'n', 't' }, '<leader>tt', function() terminal.toggle() end, { silent = true, desc = 'Toggle floating terminal' })
    vim.keymap.set({ 'n', 't' }, "<leader>tl", function() terminal.pick() end, { silent = true, desc = 'Floaterm picker' })
    vim.keymap.set({ 'n', 't' }, "<leader>t-", function() terminal.resize(-0.05) end, { silent = true, desc = 'Floaterm inc size' })
    vim.keymap.set({ 'n', 't' }, "<leader>t=", function() terminal.resize(0.05) end, { silent = true, desc = 'Floaterm dec size' })
    -- Example to run an arbitrary command
    vim.keymap.set('n', '<leader>tv', function()
        local cmd = "vifm"
        local file = vim.fn.expand("%:p")
        if file and file ~= "" then
          cmd = cmd .. " --select " .. file
        end
        terminal.open({}, cmd)
      end,
      { silent = true, desc = "vifm at current dir" }
    )
    -- Set highlighting groups if your theme doesn't include them
    vim.api.nvim_set_hl(0, 'FloatermNumber', { link = 'Number' })
    vim.api.nvim_set_hl(0, 'FloatermDirectory', { link = 'Function' })
  end
}
```

## Available Functions and Options

### open(opts, cmd)

Opens a new floating terminal that runs `cmd`. If `cmd` is omitted, it will
create a terminal running your shell (`vim.o.shell`).

Every time you create a new terminal, it is added to a list, and assigned an id
transparently managed by the plugin. You can create as many as you want.

`opts` can also be omitted, or override some of the defaults, which are:

``` lua
width = 0.8 -- ratio of the total Neovim size
height = 0.8
autoclose = true  -- Close on exit
-- The folliwing parameters are passed to Neovim's window creation function,
-- so they can take any of the standard parameters
-- :h nvim_open_win() for help
style = "minimal" -- No extra UI elements
-- "none", "single", "double", "rounded", "solid", "shadow" or an array
border = "rounded"
```

For example

``` lua
require("floaterm").open({ height = 0.5 })
```

would open a new terminal with height half of *Neovim*'s window.

### toggle()

Toggles the current terminal on/off.

### next()

Shows the next terminal.

### prev()

Shows the previous terminal.

### resize(delta)

Resizes the current terminal by delta.

### pick()

Opens a picker to choose a terminal from the list, showing its id and name.

If you have [snacks.nvim](https://github.com/folke/snacks.nvim) installed
(recommended), the picker will include a preview of the terminal. If you
don't, the plugin will use `vim.ui.select`.

