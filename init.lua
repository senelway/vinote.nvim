-- vinote/init.lua
local M = {}

local ui = require 'vinote.ui'
local files = require 'vinote.files'

M.toggle = ui.toggle
M.open = ui.open
M.close = ui.close

function M.new_note()
  vim.ui.input({ prompt = 'Note name: ' }, function(name)
    if name and name ~= '' then
      local ok, err = files.create(name)
      if ok then
        Snacks.notify('Created: ' .. name, { level = 'info' })
        ui.open()
      else
        Snacks.notify(err or 'Failed', { level = 'error' })
      end
    end
  end)
end

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
