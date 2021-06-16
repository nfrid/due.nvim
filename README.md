# due.nvim

Simple plugin that provides you due for the date string.

![Example](img/ex.png)

## Requirements

- Neovim Nightly (0.5) (may work with 0.4.4 idk test it and message me lol)

## Installation

I don't think any vim-ish plugin manager can install this lua shit. So it is
[packer.nvim](https://github.com/wbthomason/packer.nvim) and similarities only...

```lua
use {
  'NFrid/due.nvim',
  config = function()
    require('due_nvim').setup {}
  end
}
```

Or you may implement your own 'setup' due to mine just being couple of aucmds
with plugin's functions (listed below).

## Variables

Plugin's settings are all in vim variables. There are all of them, with their
default values, in lua, of course:

```lua
vim.g.due_nvim_prescript = 'due: '      -- prescript to due data
vim.g.due_nvim_prescript_hi = 'Comment' -- highlight group of it
vim.g.due_nvim_due_hi = 'String'        -- highlight group of the data itself
vim.g.due_nvim_ft = '*.md'              -- filename to apply aucmds :)
vim.g.due_nvim_overdue = 'OVERDUE'      -- text for overdued data
vim.g.due_nvim_overdue_hi = 'Error'     -- highlight group of overdued
vim.g.due_nvim_date_hi = 'Conceal'      -- highlight group of date string
```

## Functions

Welp..

```lua
require("due_nvim").draw(0)   -- Draw it for a buffer (0 to current)
require("due_nvim").clean(0)  -- Clean the array from it
require("due_nvim").redraw(0) -- Clean, then draw
```

## TODO

idk if I ever will develop this thing more... In case of somebody needs it, here
are my 'plans' on it:

- More patterns / option for pattern style
- Settings in setup function
- idk time?????
