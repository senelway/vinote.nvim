-- vinote/files.lua
local M = {}

local notes_dir = vim.fn.stdpath 'config' .. '/vinote'

function M.set_notes_dir(dir)
  notes_dir = dir
end

function M.get_notes_dir()
  return notes_dir
end

function M.get_path(name)
  return notes_dir .. '/' .. name
end

local function ensure_dir()
  vim.fn.mkdir(notes_dir, 'p')
end

function M.list_files()
  ensure_dir()
  local files = {}
  local handle = vim.uv.fs_scandir(notes_dir)
  if not handle then
    return files
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == 'file' then
      local stat = vim.uv.fs_stat(M.get_path(name))
      files[#files + 1] = { name = name, mtime = stat and stat.mtime.sec or 0 }
    end
  end

  table.sort(files, function(a, b)
    return a.mtime > b.mtime
  end)

  return vim.tbl_map(function(f)
    return f.name
  end, files)
end

function M.create(name)
  ensure_dir()
  if not name:match '%.%w+$' then
    name = name .. '.md'
  end

  local path = M.get_path(name)
  if vim.uv.fs_stat(path) then
    return false, 'File already exists'
  end

  local file = io.open(path, 'w')
  if not file then
    return false, 'Failed to create file'
  end
  file:write('# ' .. name:gsub('%.%w+$', '') .. '\n\n')
  file:close()
  return true
end

function M.delete(name)
  local path = M.get_path(name)
  if not vim.uv.fs_stat(path) then
    return false, 'File not found'
  end
  local ok = os.remove(path)
  if ok then
    return true
  end
  return false, 'Failed to delete'
end

function M.rename(old_name, new_name)
  if not new_name:match '%.%w+$' then
    new_name = new_name .. '.md'
  end

  local old_path = M.get_path(old_name)
  local new_path = M.get_path(new_name)

  if not vim.uv.fs_stat(old_path) then
    return false, 'File not found'
  end
  if vim.uv.fs_stat(new_path) then
    return false, 'Target file already exists'
  end

  local ok = os.rename(old_path, new_path)
  if ok then
    return true
  end
  return false, 'Failed to rename'
end

return M
