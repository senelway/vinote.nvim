-- vinote/ui.lua
-- UI management for vinote

local M = {}

local state = require 'vinote.state'
local files = require 'vinote.files'

-- Default dimensions (can be overridden via opts)
local config = {
  width = 0.6,
  height = 0.7,
  list_height = 0.3,
}

function M.set_config(opts)
  if opts.width then
    config.width = opts.width
  end
  if opts.height then
    config.height = opts.height
  end
  if opts.list_height then
    config.list_height = opts.list_height
  end
end

-- Forward declarations
local setup_preview_keymaps

-- Highlight namespace
local ns = vim.api.nvim_create_namespace 'vinote'

---Calculate window dimensions
---@return table
local function calc_dimensions()
  local width = math.floor(vim.o.columns * config.width)
  local height = math.floor(vim.o.lines * config.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local list_height = math.floor(height * config.list_height)
  local preview_height = height - list_height - 1 -- -1 for border

  return {
    width = width,
    height = height,
    row = row,
    col = col,
    list_height = list_height,
    preview_height = preview_height,
  }
end

---Create a floating window
---@param buf integer
---@param opts table
---@return integer win
local function create_float(buf, opts)
  return vim.api.nvim_open_win(buf, opts.enter or false, {
    relative = 'editor',
    width = opts.width,
    height = opts.height,
    row = opts.row,
    col = opts.col,
    style = 'minimal',
    border = 'rounded',
    title = opts.title,
    title_pos = 'center',
  })
end

---Update the file list display
function M.refresh_list()
  local s = state.state
  if not s.list_buf or not vim.api.nvim_buf_is_valid(s.list_buf) then
    return
  end

  s.files = files.list_files()

  vim.api.nvim_set_option_value('modifiable', true, { buf = s.list_buf })

  local lines = {}
  for i, name in ipairs(s.files) do
    local prefix = i == s.selected_index and ' > ' or '   '
    table.insert(lines, prefix .. name)
  end

  if #lines == 0 then
    lines = { "   (no notes - press 'n' to create)" }
  end

  vim.api.nvim_buf_set_lines(s.list_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = s.list_buf })

  -- Clear previous highlights and add new one for selected line (full line)
  vim.api.nvim_buf_clear_namespace(s.list_buf, ns, 0, -1)
  if s.selected_index > 0 and s.selected_index <= #s.files then
    vim.api.nvim_buf_set_extmark(s.list_buf, ns, s.selected_index - 1, 0, {
      line_hl_group = 'CursorLine',
      end_row = s.selected_index - 1,
    })
  end

  -- Update cursor position
  if s.list_win and vim.api.nvim_win_is_valid(s.list_win) then
    local row = math.max(1, math.min(s.selected_index, #s.files))
    pcall(vim.api.nvim_win_set_cursor, s.list_win, { row, 0 })
  end
end

---Update the preview display
function M.refresh_preview()
  local s = state.state
  if not s.preview_win or not vim.api.nvim_win_is_valid(s.preview_win) then
    return
  end

  if s.selected_index > 0 and s.selected_index <= #s.files then
    local name = s.files[s.selected_index]
    local path = files.get_path(name)

    -- Load file into buffer
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)

    -- Set the buffer in preview window
    vim.api.nvim_win_set_buf(s.preview_win, buf)
    s.preview_buf = buf

    -- Set up keymaps for this buffer
    setup_preview_keymaps()
  else
    -- No file selected - show empty scratch buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '(no file selected)' })
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_win_set_buf(s.preview_win, buf)
    s.preview_buf = buf
  end
end

---Block window navigation keys
---@param buf integer
local function block_window_nav(buf)
  local noop = function() end
  local opts = { buffer = buf, nowait = true }
  -- Block <C-w> commands
  vim.keymap.set('n', '<C-w>', noop, opts)
  -- Block common window navigation
  vim.keymap.set('n', '<C-h>', noop, opts)
  vim.keymap.set('n', '<C-j>', noop, opts)
  vim.keymap.set('n', '<C-k>', noop, opts)
  vim.keymap.set('n', '<C-l>', noop, opts)
end

---Set up keybindings for the list buffer
local function setup_list_keymaps()
  local s = state.state
  local buf = s.list_buf

  local function map(key, fn)
    vim.keymap.set('n', key, fn, { buffer = buf, nowait = true })
  end

  block_window_nav(buf)

  -- Navigation
  map('j', function()
    if #s.files > 0 then
      s.selected_index = math.min(s.selected_index + 1, #s.files)
      M.refresh_list()
      M.refresh_preview()
    end
  end)

  map('k', function()
    if #s.files > 0 then
      s.selected_index = math.max(s.selected_index - 1, 1)
      M.refresh_list()
      M.refresh_preview()
    end
  end)

  -- Open file
  map('<CR>', function()
    if s.selected_index > 0 and s.selected_index <= #s.files then
      local name = s.files[s.selected_index]
      local path = files.get_path(name)
      M.close()
      vim.cmd('edit ' .. vim.fn.fnameescape(path))
    end
  end)

  -- New note
  map('n', function()
    vim.ui.input({ prompt = 'Note name: ' }, function(name)
      if not name or name == '' then
        return
      end
      local ok, err = files.create(name)
      if ok then
        Snacks.notify('Created: ' .. name, { level = 'info' })
        s.selected_index = 1 -- New file will be first (newest)
        M.refresh_list()
        M.refresh_preview()
      else
        Snacks.notify(err or 'Failed to create note', { level = 'error' })
      end
    end)
  end)

  -- Delete note
  map('d', function()
    if s.selected_index > 0 and s.selected_index <= #s.files then
      local name = s.files[s.selected_index]
      vim.ui.input({ prompt = "Delete '" .. name .. "'? (y/n): " }, function(confirm)
        if confirm == 'y' then
          local ok, err = files.delete(name)
          if ok then
            Snacks.notify('Deleted: ' .. name, { level = 'info' })
            s.selected_index = math.max(1, s.selected_index - 1)
            M.refresh_list()
            M.refresh_preview()
          else
            Snacks.notify(err or 'Failed to delete note', { level = 'error' })
          end
        end
      end)
    end
  end)

  -- Rename note
  map('r', function()
    if s.selected_index > 0 and s.selected_index <= #s.files then
      local old_name = s.files[s.selected_index]
      vim.ui.input({ prompt = 'Rename to: ', default = old_name }, function(new_name)
        if not new_name or new_name == '' or new_name == old_name then
          return
        end
        local ok, err = files.rename(old_name, new_name)
        if ok then
          Snacks.notify('Renamed to: ' .. new_name, { level = 'info' })
          M.refresh_list()
          M.refresh_preview()
        else
          Snacks.notify(err or 'Failed to rename note', { level = 'error' })
        end
      end)
    end
  end)

  -- Switch focus to preview
  map('<Tab>', function()
    if s.preview_win and vim.api.nvim_win_is_valid(s.preview_win) then
      vim.api.nvim_set_current_win(s.preview_win)
      s.focus = 'preview'
    end
  end)

  -- Close
  map('q', M.close)
  map('<Esc>', M.close)
end

---Set up keybindings for the preview buffer
setup_preview_keymaps = function()
  local s = state.state
  local buf = s.preview_buf

  local function map(key, fn)
    vim.keymap.set('n', key, fn, { buffer = buf, nowait = true })
  end

  block_window_nav(buf)

  -- Scroll
  map('j', function()
    vim.cmd 'normal! j'
  end)

  map('k', function()
    vim.cmd 'normal! k'
  end)

  -- Switch focus to list
  map('<Tab>', function()
    if s.list_win and vim.api.nvim_win_is_valid(s.list_win) then
      vim.api.nvim_set_current_win(s.list_win)
      s.focus = 'list'
    end
  end)

  -- Close
  map('q', M.close)
  map('<Esc>', M.close)
end

---Open the vinote UI
function M.open()
  if state.is_open() then
    M.close()
    return
  end

  local dims = calc_dimensions()

  -- Create list buffer and window
  state.state.list_buf = vim.api.nvim_create_buf(false, true)
  state.state.list_win = create_float(state.state.list_buf, {
    width = dims.width,
    height = dims.list_height,
    row = dims.row,
    col = dims.col,
    title = ' Vinote ',
    enter = true,
  })

  -- Create preview buffer and window
  state.state.preview_buf = vim.api.nvim_create_buf(false, true)
  state.state.preview_win = create_float(state.state.preview_buf, {
    width = dims.width,
    height = dims.preview_height,
    row = dims.row + dims.list_height + 2, -- +2 for border
    col = dims.col,
    title = ' Preview ',
    enter = false,
  })

  -- Set list buffer options (preview will be a real file buffer)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = state.state.list_buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = state.state.list_buf })

  -- Set up keymaps
  setup_list_keymaps()
  setup_preview_keymaps()

  -- Set up autocommands
  local group = vim.api.nvim_create_augroup('VinoteUI', { clear = true })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(state.state.list_win),
    callback = function()
      M.close()
    end,
  })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(state.state.preview_win),
    callback = function()
      M.close()
    end,
  })

  -- Initial refresh
  state.state.selected_index = 1
  state.state.focus = 'list'
  M.refresh_list()
  M.refresh_preview()
end

---Close the vinote UI
function M.close()
  local s = state.state

  if s.list_win and vim.api.nvim_win_is_valid(s.list_win) then
    vim.api.nvim_win_close(s.list_win, true)
  end

  if s.preview_win and vim.api.nvim_win_is_valid(s.preview_win) then
    vim.api.nvim_win_close(s.preview_win, true)
  end

  pcall(vim.api.nvim_del_augroup_by_name, 'VinoteUI')
  state.reset()
end

---Toggle the vinote UI
function M.toggle()
  if state.is_open() then
    M.close()
  else
    M.open()
  end
end

return M
