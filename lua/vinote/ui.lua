-- vinote/ui.lua
local M = {}

local state = require 'vinote.state'
local files = require 'vinote.files'
local notify = require 'vinote.notify'
local api = vim.api
local fn = vim.fn

local config = {
  width = 0.6,
  height = 0.7,
  list_height = 0.3,
  show_footer_keys = true,
}

local ns = api.nvim_create_namespace 'vinote'

function M.set_config(opts)
  config = vim.tbl_extend('force', config, opts)
end

local function calc_dimensions()
  local width = math.floor(vim.o.columns * config.width)
  local height = math.floor(vim.o.lines * config.height)
  local list_height = math.floor(height * config.list_height)
  return {
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    list_height = list_height,
    preview_height = height - list_height - 1,
  }
end

local function create_float(buf, opts)
  local win_opts = {
    relative = 'editor',
    width = opts.width,
    height = opts.height,
    row = opts.row,
    col = opts.col,
    border = 'rounded',
    title = opts.title,
    title_pos = 'center',
    style = opts.minimal and 'minimal' or nil,
  }
  if opts.footer and config.show_footer_keys then
    win_opts.footer = opts.footer
    win_opts.footer_pos = 'center'
  end
  return api.nvim_open_win(buf, opts.enter or false, win_opts)
end

local function valid_win(win)
  return win and api.nvim_win_is_valid(win)
end

local function valid_buf(buf)
  return buf and api.nvim_buf_is_valid(buf)
end

local function map(buf, key, fn_cb)
  vim.keymap.set('n', key, fn_cb, { buffer = buf, nowait = true })
end

local function block_nav(buf)
  local noop = function() end
  for _, key in ipairs { '<C-w>', '<C-h>', '<C-l>' } do
    map(buf, key, noop)
  end
end

function M.refresh_list()
  local s = state.state
  if not valid_buf(s.list_buf) then
    return
  end

  s.files = files.list_files()
  api.nvim_set_option_value('modifiable', true, { buf = s.list_buf })

  local lines = {}
  for i, name in ipairs(s.files) do
    lines[#lines + 1] = (i == s.selected_index and ' > ' or '   ') .. name
  end
  if #lines == 0 then
    lines = { "   (no notes - press 'n' to create)" }
  end

  api.nvim_buf_set_lines(s.list_buf, 0, -1, false, lines)
  api.nvim_set_option_value('modifiable', false, { buf = s.list_buf })

  api.nvim_buf_clear_namespace(s.list_buf, ns, 0, -1)
  if s.selected_index > 0 and s.selected_index <= #s.files then
    api.nvim_buf_set_extmark(s.list_buf, ns, s.selected_index - 1, 0, {
      line_hl_group = 'CursorLine',
    })
  end

  if valid_win(s.list_win) then
    pcall(api.nvim_win_set_cursor, s.list_win, { math.max(1, math.min(s.selected_index, #s.files)), 0 })
  end
end

function M.save_preview()
  local s = state.state
  if valid_buf(s.preview_buf) and s.current_file then
    fn.writefile(api.nvim_buf_get_lines(s.preview_buf, 0, -1, false), s.current_file)
  end
end

local function setup_preview_keymaps()
  local s = state.state
  local buf = s.preview_buf
  block_nav(buf)

  local function go_to_list()
    if valid_win(s.list_win) then
      api.nvim_set_current_win(s.list_win)
    end
  end

  map(buf, '<Tab>', go_to_list)
  map(buf, '<C-k>', go_to_list)

  map(buf, 'w', function()
    M.save_preview()
    vim.bo[buf].modified = false
    notify.info 'Saved'
  end)

  map(buf, 'q', M.close)
  map(buf, '<Esc>', M.close)
end

function M.refresh_preview()
  local s = state.state
  if not valid_win(s.preview_win) then
    return
  end

  if s.selected_index > 0 and s.selected_index <= #s.files then
    local path = files.get_path(s.files[s.selected_index])
    s.current_file = path

    local buf = fn.bufadd(path)
    fn.bufload(buf)
    api.nvim_win_set_buf(s.preview_win, buf)
    s.preview_buf = buf
    setup_preview_keymaps()
  else
    s.current_file = nil
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, { '(no file selected)' })
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = 'wipe'
    api.nvim_win_set_buf(s.preview_win, buf)
    s.preview_buf = buf
  end
end

local function setup_list_keymaps()
  local s = state.state
  local buf = s.list_buf
  block_nav(buf)

  local function move(delta)
    if #s.files > 0 then
      s.selected_index = math.max(1, math.min(s.selected_index + delta, #s.files))
      M.refresh_list()
      M.refresh_preview()
    end
  end

  map(buf, 'j', function()
    move(1)
  end)
  map(buf, 'k', function()
    move(-1)
  end)

  map(buf, '<CR>', function()
    if s.selected_index > 0 and s.selected_index <= #s.files then
      local path = files.get_path(s.files[s.selected_index])
      M.close()
      vim.cmd('edit ' .. fn.fnameescape(path))
    end
  end)

  map(buf, 'n', function()
    vim.ui.input({ prompt = 'Note name: ' }, function(name)
      if name and name ~= '' then
        local ok, err = files.create(name)
        if ok then
          notify.info('Created: ' .. name)
          s.selected_index = 1
          M.refresh_list()
          M.refresh_preview()
        else
          notify.error(err or 'Failed')
        end
      end
    end)
  end)

  map(buf, 'd', function()
    if s.selected_index > 0 and s.selected_index <= #s.files then
      local name = s.files[s.selected_index]
      vim.ui.input({ prompt = "Delete '" .. name .. "'? (y/n): " }, function(confirm)
        if confirm == 'y' then
          local ok, err = files.delete(name)
          if ok then
            notify.info 'Deleted'
            s.selected_index = math.max(1, s.selected_index - 1)
            M.refresh_list()
            M.refresh_preview()
          else
            notify.error(err or 'Failed')
          end
        end
      end)
    end
  end)

  map(buf, 'r', function()
    if s.selected_index > 0 and s.selected_index <= #s.files then
      local old = s.files[s.selected_index]
      vim.ui.input({ prompt = 'Rename to: ', default = old }, function(new)
        if new and new ~= '' and new ~= old then
          local ok, err = files.rename(old, new)
          if ok then
            notify.info 'Renamed'
            M.refresh_list()
            M.refresh_preview()
          else
            notify.error(err or 'Failed')
          end
        end
      end)
    end
  end)

  local function go_to_preview()
    if valid_win(s.preview_win) then
      api.nvim_set_current_win(s.preview_win)
    end
  end

  map(buf, '<Tab>', go_to_preview)
  map(buf, '<C-j>', go_to_preview)

  map(buf, 'q', M.close)
  map(buf, '<Esc>', M.close)
end

function M.open()
  if state.is_open() then
    M.close()
    return
  end

  local dims = calc_dimensions()
  local s = state.state

  s.list_buf = api.nvim_create_buf(false, true)
  s.list_win = create_float(s.list_buf, {
    width = dims.width,
    height = dims.list_height,
    row = dims.row,
    col = dims.col,
    title = ' Vinote ',
    enter = true,
    minimal = true,
    footer = ' n:new  d:del  r:rename  ⏎:open  ⇥/C-j:preview  q:close ',
  })

  s.preview_buf = api.nvim_create_buf(false, true)
  s.preview_win = create_float(s.preview_buf, {
    width = dims.width,
    height = dims.preview_height,
    row = dims.row + dims.list_height + 2,
    col = dims.col,
    title = ' Preview ',
    footer = ' w:save  ⇥/C-k:list  q:close ',
  })

  -- Preview window options
  local wo = { number = true, relativenumber = false, wrap = true, linebreak = true }
  for k, v in pairs(wo) do
    api.nvim_set_option_value(k, v, { win = s.preview_win })
  end

  vim.bo[s.list_buf].bufhidden = 'wipe'
  vim.bo[s.list_buf].buftype = 'nofile'

  setup_list_keymaps()

  local group = api.nvim_create_augroup('VinoteUI', { clear = true })
  api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = { tostring(s.list_win), tostring(s.preview_win) },
    callback = M.close,
  })

  s.selected_index = 1
  M.refresh_list()
  M.refresh_preview()
end

function M.close()
  local s = state.state

  if valid_buf(s.preview_buf) and vim.bo[s.preview_buf].modified then
    M.save_preview()
  end

  if valid_win(s.list_win) then
    api.nvim_win_close(s.list_win, true)
  end
  if valid_win(s.preview_win) then
    api.nvim_win_close(s.preview_win, true)
  end

  pcall(api.nvim_del_augroup_by_name, 'VinoteUI')
  state.reset()
end

function M.toggle()
  if state.is_open() then
    M.close()
  else
    M.open()
  end
end

return M
