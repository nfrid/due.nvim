local M = {}
_VT_NS = vim.api.nvim_create_namespace("lsp_signature")

local function parseDue(due)
  local year = 31556926
  local month = 2629743
  local week = 604800
  local day = 86400
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
  if due >= day then res = res .. math.floor(due / day) .. 'd ' end
  return res
end

vim.g.due_nvim_prescript = 'due: '
vim.g.due_nvim_prescript_hi = 'Comment'
vim.g.due_nvim_due_hi = 'String'
vim.g.due_nvim_ft = '*.md'
vim.g.due_nvim_overdue = 'OVERDUE'
vim.g.due_nvim_overdue_hi = 'Error'
vim.g.due_nvim_date_hi = 'Conceal'

function M.draw(buf)
  local now = os.time(os.date('*t'))
  for key, value in pairs(vim.api.nvim_buf_get_lines(buf, 0, -1, {})) do
    local date = string.match(value, '<%d%d%-%d%d>')
    local fullDate = string.match(value, '<%d%d%d%d%-%d%d%-%d%d>')
    local due

    if date then
      local month, day = date:match('<(%d%d)%-(%d%d)>')
      due = os.time({ year = os.date("%Y"), month = month, day = day }) - now
    end

    if fullDate then
      local year, month, day = fullDate:match('<(%d%d%d%d)%-(%d%d)%-(%d%d)>')
      due = os.time({ year = year, month = month, day = day }) - now
    end

    if due then
      local parsed
      if due > 0 then
        parsed = { parseDue(due), vim.g.due_nvim_due_hi }
      else
        parsed = { vim.g.due_nvim_overdue, vim.g.due_nvim_overdue_hi }
      end

      vim.api.nvim_buf_set_virtual_text(buf, _VT_NS, key - 1, {
        { vim.g.due_nvim_prescript, vim.g.due_nvim_prescript_hi },
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

function M.setup()
  vim.api.nvim_command('autocmd BufEnter ' .. vim.g.due_nvim_ft ..' lua require("due_nvim").draw(0)')
  vim.api.nvim_command('autocmd InsertLeave ' .. vim.g.due_nvim_ft ..' lua require("due_nvim").redraw(0)')
  vim.api.nvim_command('autocmd TextChanged ' .. vim.g.due_nvim_ft ..' lua require("due_nvim").redraw(0)')
  vim.api.nvim_command('autocmd TextChangedI ' .. vim.g.due_nvim_ft ..' lua require("due_nvim").redraw(0)')

  vim.api.nvim_command('autocmd BufEnter ' .. vim.g.due_nvim_ft .. ' syn match DueDate /<\\d*-*\\d\\+-\\d\\+>/ display containedin=mkdNonListItemBlock,mkdListItemLine,mkdBlockquote contained')
  vim.api.nvim_command('autocmd BufEnter ' .. vim.g.due_nvim_ft .. ' hi def link DueDate ' .. vim.g.due_nvim_date_hi)
end

return M
