-- vinote/state.lua
-- State management for vinote

local M = {}

---@class VinoteState
---@field list_win integer|nil
---@field list_buf integer|nil
---@field preview_win integer|nil
---@field preview_buf integer|nil
---@field files string[]
---@field selected_index integer
---@field focus "list"|"preview"

---@type VinoteState
M.state = {
  list_win = nil,
  list_buf = nil,
  preview_win = nil,
  preview_buf = nil,
  files = {},
  selected_index = 1,
  focus = 'list',
}

function M.reset()
  M.state = {
    list_win = nil,
    list_buf = nil,
    preview_win = nil,
    preview_buf = nil,
    files = {},
    selected_index = 1,
    focus = 'list',
  }
end

function M.is_open()
  return M.state.list_win ~= nil and vim.api.nvim_win_is_valid(M.state.list_win)
end

return M
