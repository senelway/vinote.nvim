-- vinote/notify.lua
local M = {}

local snacks_ok, snacks = pcall(require, 'snacks')

---@alias vinote.NotifyLevel "info"|"warn"|"error"

---@param msg string
---@param level? vinote.NotifyLevel
---@param opts? table
local function run(msg, level, opts)
  if snacks_ok then
    return snacks.notify(msg, level, opts)
  end
  vim.notify(msg, level and vim.log.levels[level:upper()], opts)
end

---@param msg string
---@param opts? table
function M.info(msg, opts)
  run(msg, 'info', opts)
end

---@param msg string
---@param opts? table
function M.error(msg, opts)
  run(msg, 'error', opts)
end

return M
