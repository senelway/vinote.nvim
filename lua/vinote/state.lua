-- vinote/state.lua
local M = {}

local default_state = {
  list_win = nil,
  list_buf = nil,
  preview_win = nil,
  preview_buf = nil,
  files = {},
  selected_index = 1,
  current_file = nil,
}

M.state = vim.deepcopy(default_state)

function M.reset()
  M.state = vim.deepcopy(default_state)
end

function M.is_open()
  return M.state.list_win ~= nil and vim.api.nvim_win_is_valid(M.state.list_win)
end

return M
