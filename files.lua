-- vinote/files.lua
-- File operations for vinote

local M = {}

local notes_dir = vim.fn.stdpath 'config' .. '/vinote'

function M.set_notes_dir(dir)
  notes_dir = dir
end

function M.get_notes_dir()
  return notes_dir
end

function M.ensure_dir()
  if vim.fn.isdirectory(notes_dir) == 0 then
    vim.fn.mkdir(notes_dir, 'p')
  end
end

---Get list of note files sorted by modification time (newest first)
---@return string[]
function M.list_files()
  M.ensure_dir()
  local files = {}
  local handle = vim.loop.fs_scandir(notes_dir)
  if not handle then
    return files
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == 'file' then
      local path = notes_dir .. '/' .. name
      local stat = vim.loop.fs_stat(path)
      table.insert(files, { name = name, mtime = stat and stat.mtime.sec or 0 })
    end
  end

  table.sort(files, function(a, b)
    return a.mtime > b.mtime
  end)

  local result = {}
  for _, f in ipairs(files) do
    table.insert(result, f.name)
  end
  return result
end

---Create a new note
---@param name string
---@return boolean success
---@return string|nil error
function M.create(name)
  M.ensure_dir()
  -- Add .md extension if no extension provided
  if not name:match '%.%w+$' then
    name = name .. '.md'
  end

  local path = notes_dir .. '/' .. name
  if vim.fn.filereadable(path) == 1 then
    return false, 'File already exists'
  end

  local file = io.open(path, 'w')
  if not file then
    return false, 'Failed to create file'
  end
  file:write('# ' .. name:gsub('%.%w+$', '') .. '\n\n')
  file:close()
  return true, nil
end

---Delete a note
---@param name string
---@return boolean success
---@return string|nil error
function M.delete(name)
  local path = notes_dir .. '/' .. name
  if vim.fn.filereadable(path) == 0 then
    return false, 'File not found'
  end

  local ok = os.remove(path)
  if not ok then
    return false, 'Failed to delete file'
  end
  return true, nil
end

---Rename a note
---@param old_name string
---@param new_name string
---@return boolean success
---@return string|nil error
function M.rename(old_name, new_name)
  -- Add .md extension if no extension provided
  if not new_name:match '%.%w+$' then
    new_name = new_name .. '.md'
  end

  local old_path = notes_dir .. '/' .. old_name
  local new_path = notes_dir .. '/' .. new_name

  if vim.fn.filereadable(old_path) == 0 then
    return false, 'File not found'
  end

  if vim.fn.filereadable(new_path) == 1 then
    return false, 'Target file already exists'
  end

  local ok = os.rename(old_path, new_path)
  if not ok then
    return false, 'Failed to rename file'
  end
  return true, nil
end

---Read file contents
---@param name string
---@return string[]|nil lines
function M.read(name)
  local path = notes_dir .. '/' .. name
  if vim.fn.filereadable(path) == 0 then
    return nil
  end

  local lines = {}
  for line in io.lines(path) do
    table.insert(lines, line)
  end
  return lines
end

---Get full path for a note
---@param name string
---@return string
function M.get_path(name)
  return notes_dir .. '/' .. name
end

return M
