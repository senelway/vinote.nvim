-- vinote/notify.lua
local M = {}

local snacks_ok, snacks = pcall(require, 'snacks')

---@alias vinote.NotifyLevel "info"|"warn"|"error"

---@param msg string
---@param level? vinote.NotifyLevel
---@param opts? table
function M.notify(msg, level, opts)
  if snacks_ok then
    return snacks.notify(msg, level, opts)
  end
  vim.notify(msg, level and vim.log.levels[level:upper()], opts)
end

return M
