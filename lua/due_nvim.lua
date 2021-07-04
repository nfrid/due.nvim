local M = {}
_VT_NS = vim.api.nvim_create_namespace("lsp_signature")


local function parseDue(due)
  local year = 31556926
  local month = 2629743
  local week = 604800
  local day = 86400
  local hour = 3600
  local minute = 60
  local res = ''

  if due >= year then
    res = res .. math.floor(due / year) .. 'y '
    due = due % year
  end

  if due >= month then
    res = res .. math.floor(due / month) .. 'm '
    due = due % month
  end

  if due >= week then
    res = res .. math.floor(due / week) .. 'w '
    due = due % week
  end

  if use_clock_time == true then
    if due >= day then
      res = res .. math.floor(due / day) .. 'd '
      due = due % day
    end  

    if due >= hour then
      res = res .. math.floor(due / hour) .. 'h '
      due = due % hour
    end 

    if due >= minute then
      res = res .. math.floor(due / minute) .. 'min '
      due = due % minute
    end  

    res = res .. math.floor(due / 1) + 1 .. 's '

  else
    res = res .. math.floor(due / day) + 1 .. 'd '
  end

  return res
end


local prescript
local prescript_hi
local due_hi
local ft
local today
local today_hi
local overdue
local overdue_hi
local date_hi
local pattern_start
local pattern_end

local date_pattern
local fulldate_pattern
local date_pattern_match
local fulldate_pattern_match


function M.setup(c)
  use_clock_time = c.use_clock_time or true
  default_due_time = c.default_due_time or 'midnight'
  prescript = c.prescript or 'due: '
  prescript_hi = c.prescript_hi or 'Comment'
  due_hi = c.due_hi or 'String'
  ft = c.ft or '*.md'
  today = c.today or 'TODAY'
  today_hi = c.today_hi or 'Character'
  overdue = c.overdue or 'OVERDUE'
  overdue_hi = c.overdue_hi or 'Error'
  date_hi = c.date_hi or 'Conceal'
  pattern_start = c.pattern_start or '<'
  pattern_end = c.pattern_end or '>'

  local lua_start = pattern_start:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
  local lua_end = pattern_end:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")

  local regex_start = pattern_start:gsub("\\%^%$%.%*~%[%]&", "\\%1")
  local regex_end = pattern_end:gsub("\\%^%$%.%*~%[%]&", "\\%1")

  date_pattern = lua_start .. '%d%d%-%d%d' .. lua_end
  fulldate_pattern = lua_start .. '%d%d%d%d%-%d%d%-%d%d' .. lua_end

  date_pattern_match = lua_start .. '(%d%d)%-(%d%d)' .. lua_end
  fulldate_pattern_match = lua_start .. '(%d%d%d%d)%-(%d%d)%-(%d%d)' .. lua_end

  local regex_hi = '/' .. regex_start .. '\\d*-*\\d\\+-\\d\\+' .. regex_end .. '/'

  vim.api.nvim_command('autocmd BufEnter ' .. ft ..' lua require("due_nvim").draw(0)')
  vim.api.nvim_command('autocmd InsertLeave ' .. ft ..' lua require("due_nvim").redraw(0)')
  vim.api.nvim_command('autocmd TextChanged ' .. ft ..' lua require("due_nvim").redraw(0)')
  vim.api.nvim_command('autocmd TextChangedI ' .. ft ..' lua require("due_nvim").redraw(0)')

  vim.api.nvim_command('autocmd BufEnter ' .. ft .. ' syn match DueDate ' .. regex_hi .. ' display containedin=mkdNonListItemBlock,mkdListItemLine,mkdBlockquote contained')
  vim.api.nvim_command('autocmd BufEnter ' .. ft .. ' hi def link DueDate ' .. date_hi)
end


function M.draw(buf)
  local user_time
  local user_hour
  local user_min
  local user_sec

  -- get user default time option
  if default_due_time == "midnight" then
    user_hour = 23 
    user_min = 59 
    user_sec = 59  
  elseif default_due_time == "noon" then
    user_hour = 12 
    user_min = 00 
    user_sec = 00   
  end
  
  -- get current time
  local now = os.time(os.date('*t'))

  -- find which date pattern is being passed in by user
  for key, value in pairs(vim.api.nvim_buf_get_lines(buf, 0, -1, {})) do
    local date = string.match(value, date_pattern)
    local fullDate = string.match(value, fulldate_pattern)
    local due

    if date then
      local month, day = date:match(date_pattern_match)
      local cur_year = os.date("%Y")

      user_time = os.time({ year = cur_year, month = month, day = day, hour = user_hour, min = user_min, sec = user_sec }) 

      due = user_time - now
    end

    if fullDate then
      local cur_year, month, day = fullDate:match(fulldate_pattern_match)

      user_time = os.time({ year = cur_year, month = month, day = day, hour = user_hour, min = user_min, sec = user_sec }) 

      due = user_time - now
    end

    if due then
      local parsed

      if due > 0 then
        parsed = { parseDue(due), due_hi }
      elseif not use_clock_time and due > -86400 then
        parsed = { today, today_hi }
      else
        parsed = { overdue, overdue_hi }
      end

      vim.api.nvim_buf_set_virtual_text(buf, _VT_NS, key - 1, {
        { prescript, prescript_hi },
        parsed
    }, {})
    end
  end
end

function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, _VT_NS, 0, -1)
end

function M.redraw(buf)
  M.clear(buf)
  M.draw(buf)
end

return M
