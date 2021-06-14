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

vim.g.dueVir_prescript = 'due: '
vim.g.dueVir_prescript_hi = 'Comment'
vim.g.dueVir_due_hi = 'String'
vim.g.dueVir_ft = '*.md'
vim.g.dueVir_overdue = 'OVERDUE'
vim.g.dueVir_overdue_hi = 'Error'

function M.draw(buf)
  local now = os.time(os.date('*t'))
  for key, value in pairs(vim.api.nvim_buf_get_lines(buf, 0, -1, {})) do
    local date = string.match(value, '<%d%d%d%d%-%d%d%-%d%d>')

    if date then
      local year, month, day = date:match('<(%d%d%d%d)%-(%d%d)%-(%d%d)>')
      local due = os.time({ year = year, month = month, day = day }) - now

      local parsed
      if due > 0 then
        parsed = { parseDue(due), vim.g.dueVir_due_hi }
      else
        parsed = { vim.g.dueVir_overdue, vim.g.dueVir_overdue_hi }
      end

      vim.api.nvim_buf_set_virtual_text(buf, _VT_NS, key - 1, {
        { vim.g.dueVir_prescript, vim.g.dueVir_prescript_hi },
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
  vim.api.nvim_command('autocmd BufEnter ' .. vim.g.dueVir_ft ..' lua require("dueVir").draw(0)')
  vim.api.nvim_command('autocmd InsertLeave ' .. vim.g.dueVir_ft ..' lua require("dueVir").redraw(0)')
  vim.api.nvim_command('autocmd TextChanged ' .. vim.g.dueVir_ft ..' lua require("dueVir").redraw(0)')
  vim.api.nvim_command('autocmd TextChangedI ' .. vim.g.dueVir_ft ..' lua require("dueVir").redraw(0)')
end

return M
