# due.nvim

Simple plugin that provides you due for the date string.

![Example](img/ex.png)

## Requirements

- Neovim Nightly (0.5)

TODO: test for 0.4

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'NFrid/due.nvim',
  config = function()
    require('due_nvim').setup {}
  end
}
```

## Settings

Parse any of these settings to setup func to overwrite the defaults:

```lua
require('due_nvim').setup {
  prescript = 'due: '      -- prescript to due data
  prescript_hi = 'Comment' -- highlight group of it
  due_hi = 'String'        -- highlight group of the data itself
  ft = '*.md'              -- filename template to apply aucmds :)
  today = 'TODAY'          -- text for today's due
  today_hi = 'Character'   -- highlight group of today's due
  overdue = 'OVERDUE'      -- text for overdued
  overdue_hi = 'Error'     -- highlight group of overdued
  date_hi = 'Conceal'      -- highlight group of date string
  pattern_start = '<'      -- start for a date string pattern
  pattern_end = '>'        -- end for a date string pattern
}
```

## Functions

These are used to make it work..

```lua
require("due_nvim").draw(0)   -- Draw it for a buffer (0 to current)
require("due_nvim").clean(0)  -- Clean the array from it
require("due_nvim").redraw(0) -- Clean, then draw
```

## TODO

idk if I ever will develop this thing more... In case of somebody needs it, here
are my 'plans' on it:

- Option for pattern style
- idk time?????
