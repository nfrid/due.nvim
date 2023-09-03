local M = {}
_VT_NS = vim.api.nvim_create_namespace("lsp_signature")

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

local use_clock_time
local use_clock_today
local use_seconds
local default_due_time

local user_hour
local user_min
local user_sec

local date_pattern
local datetime_pattern
local datetime12_pattern
local fulldate_pattern
local fulldatetime_pattern
local fulldatetime12_pattern

local regex_hi

local update_rate

local function patternify(str)
  return str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end

local function regexify(str) return str:gsub("\\%^%$%.%*~%[%]&", "\\%1") end

local function make_pattern(pattern)
  return patternify(pattern_start) .. pattern:gsub('%(', ''):gsub('%)', '') ..
      patternify(pattern_end)
end

local function make_pattern_match(pattern)
  return patternify(pattern_start) .. pattern .. patternify(pattern_end)
end

local function parseDue(due)
  local year = 31556926
  local month = 2629743
  local week = 604800
  local day = 86400
  local hour = 3600
  local minute = 60
  local res = ''
  local is_today = due < day

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

  if use_clock_time or (is_today and use_clock_today) then
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

    if use_seconds then res = res .. math.floor(due / 1) + 1 .. 's ' end

  else
    res = res .. math.floor(due / day) + 1 .. 'd '
  end

  return res
end

function M.setup(c)
  c = c or {}
  use_clock_time = c.use_clock_time or false
  use_clock_today = c.use_clock_today or false
  if type(c.use_seconds) == 'boolean' then
    use_seconds = c.use_seconds
  else
    use_seconds = c.use_clock_time or false
  end
  update_rate = c.update_rate or
      (use_clock_time and (use_seconds and 1000 or 60000) or 0)
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
  date_pattern = c.date_pattern or '(%d%d)%-(%d%d)'
  datetime_pattern = c.datetime_pattern or (date_pattern .. ' (%d+):(%d%d)')
  datetime12_pattern = c.datetime12_pattern or (datetime_pattern .. ' (%a%a)')
  fulldate_pattern = c.fulldate_pattern or ('(%d%d%d%d)%-' .. date_pattern)
  fulldatetime_pattern = c.fulldatetime_pattern or
      ('(%d%d%d%d)%-' .. datetime_pattern)
  fulldatetime12_pattern = c.fulldatetime12_pattern or
      (fulldatetime_pattern .. ' (%a%a)')
  regex_hi = c.regex_hi or
      "\\d*-*\\d\\+-\\d\\+\\( \\d*:\\d*\\( \\a\\a\\)\\?\\)\\?"

  if default_due_time == "midnight" then
    user_hour = 23
    user_min = 59
    user_sec = 59
  elseif default_due_time == "noon" then
    user_hour = 12
    user_min = 00
    user_sec = 00
  end

  local regex_start = regexify(pattern_start)
  local regex_end = regexify(pattern_end)

  local regex_hi_full = '/' .. regex_start .. regex_hi .. regex_end .. '/'

  vim.api.nvim_exec(string.format(
    [[
  augroup Due
    autocmd!
    autocmd BufEnter %s lua require("due_nvim").draw(0)
    autocmd BufEnter %s lua require("due_nvim").async_update(0)
    autocmd InsertLeave %s lua require("due_nvim").redraw(0)
    autocmd TextChanged %s lua require("due_nvim").redraw(0)
    autocmd TextChangedI %s lua require("due_nvim").redraw(0)
    autocmd BufEnter %s syn match DueDate %s display containedin=mkdNonListItemBlock,mkdListItemLine,mkdBlockquote contained
    autocmd BufEnter %s hi def link DueDate %s
  augroup END
  ]] , ft, ft, ft, ft, ft, ft, regex_hi_full, ft, date_hi),
    false
  )
end

local function draw_due(due, buf, key)
  local parsed

  if due > 0 then
    if not (use_clock_time or use_clock_today) and due < 86400 then
      parsed = { today, today_hi }
    else
      parsed = { parseDue(due), due_hi }
    end
  else
    parsed = { overdue, overdue_hi }
  end

  vim.api.nvim_buf_set_virtual_text(buf, _VT_NS, key - 1,
    { { prescript, prescript_hi }, parsed }, {})
end

function M.draw(buf)
  -- get current time
  local now = os.time(os.date('*t'))

  -- find which date pattern is being passed in by user
  for key, value in pairs(vim.api.nvim_buf_get_lines(buf, 0, -1, {})) do
    local fulldatetime12 = value:match(make_pattern(fulldatetime12_pattern))
    if fulldatetime12 then
      local year, month, day, hour, min, period =
      fulldatetime12:match(make_pattern_match(fulldatetime12_pattern))
      hour = tonumber(hour)
      local is_pm = period:lower() == 'pm'
      if is_pm and hour < 12 or not is_pm and hour == 12 then
        hour = hour + 12
        if hour == 24 then
          hour = 0
        end
      end
      draw_due(os.time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = user_sec
      }) - now, buf, key)
      goto continue
    end

    local fulldatetime = value:match(make_pattern(fulldatetime_pattern))
    if fulldatetime then
      local year, month, day, hour, min =
      fulldatetime:match(make_pattern_match(fulldatetime_pattern))
      draw_due(os.time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = user_sec
      }) - now, buf, key)
      goto continue
    end

    local fulldate = value:match(make_pattern(fulldate_pattern))
    if fulldate then
      local year, month, day = fulldate:match(make_pattern_match(
        fulldate_pattern))
      draw_due(os.time({
        year = year,
        month = month,
        day = day,
        hour = user_hour,
        min = user_min,
        sec = user_sec
      }) - now, buf, key)
      goto continue
    end

    local datetime12 = value:match(make_pattern(datetime12_pattern))
    if datetime12 then
      local month, day, hour, min, period =
      datetime12:match(make_pattern_match(datetime12_pattern))
      local year = os.date("%Y")
      hour = tonumber(hour)
      local is_pm = period:lower() == 'pm'
      if is_pm and hour < 12 or not is_pm and hour == 12 then
        hour = hour + 12
        if hour == 24 then
          hour = 0
        end
      end
      draw_due(os.time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = user_sec
      }) - now, buf, key)
      goto continue
    end

    local datetime = value:match(make_pattern(datetime_pattern))
    if datetime then
      local month, day, hour, min = datetime:match(make_pattern_match(
        datetime_pattern))
      local year = os.date("%Y")
      draw_due(os.time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = user_sec
      }) - now, buf, key)
      goto continue
    end

    local date = value:match(make_pattern(date_pattern))
    if date then
      local month, day = date:match(make_pattern_match(date_pattern))
      local year = os.date("%Y")

      draw_due(os.time({
        year = year,
        month = month,
        day = day,
        hour = user_hour,
        min = user_min,
        sec = user_sec
      }) - now, buf, key)
      goto continue
    end
    ::continue::
  end
end

function M.clear(buf) vim.api.nvim_buf_clear_namespace(buf, _VT_NS, 0, -1) end

function M.redraw(buf)
  M.clear(buf)
  M.draw(buf)
end

function M.async_update(buf)
  if update_rate <= 0 then return end
  local timer = vim.loop.new_timer()
  timer:start(update_rate, 0, vim.schedule_wrap(function()
    M.redraw(buf)
    M.async_update(buf)
  end))
end

return M
