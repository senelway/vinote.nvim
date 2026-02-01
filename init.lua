-- vinote/init.lua
-- Main module for vinote - a floating window note-taking plugin

local M = {}

local ui = require 'vinote.ui'
local files = require 'vinote.files'

---@class VinoteKeysOpts
---@field toggle string|nil
---@field new_note string|nil

---@class VinoteWindowOpts
---@field width number|nil       -- Width ratio (0-1), default 0.6
---@field height number|nil      -- Height ratio (0-1), default 0.7
---@field list_height number|nil -- List pane height ratio (0-1), default 0.3

---@class VinoteOpts
---@field notes_dir string|nil
---@field keys VinoteKeysOpts|nil
---@field window VinoteWindowOpts|nil

---Toggle the vinote UI
function M.toggle()
  ui.toggle()
end

---Open the vinote UI
function M.open()
  ui.open()
end

---Close the vinote UI
function M.close()
  ui.close()
end

---Quick create a new note
function M.new_note()
  vim.ui.input({ prompt = 'Note name: ' }, function(name)
    if not name or name == '' then
      return
    end
    local ok, err = files.create(name)
    if ok then
      Snacks.notify('Created: ' .. name, { level = 'info' })
      ui.open()
    else
      Snacks.notify(err or 'Failed to create note', { level = 'error' })
    end
  end)
end

---Set up vinote
---@param opts VinoteOpts|nil
function M.setup(opts)
  opts = opts or {}

  if opts.notes_dir then
    files.set_notes_dir(opts.notes_dir)
  end

  if opts.window then
    ui.set_config(opts.window)
  end

  local keys = opts.keys or {}

  if keys.toggle then
    vim.keymap.set('n', keys.toggle, M.toggle, { desc = 'Toggle Vinote' })
  end

  if keys.new_note then
    vim.keymap.set('n', keys.new_note, M.new_note, { desc = 'New Vinote note' })
  end
end

return M
