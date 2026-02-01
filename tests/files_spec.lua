describe('vinote.files', function()
  local files = require 'vinote.files'
  local test_dir = '/tmp/vinote-test-' .. os.time()

  before_each(function()
    files.set_notes_dir(test_dir)
    vim.fn.mkdir(test_dir, 'p')
  end)

  after_each(function()
    vim.fn.delete(test_dir, 'rf')
  end)

  describe('create', function()
    it('should create a new note with .md extension', function()
      local ok, err = files.create 'test-note'
      assert.is_true(ok)
      assert.is_nil(err)
      assert.equals(1, vim.fn.filereadable(test_dir .. '/test-note.md'))
    end)

    it('should preserve explicit extension', function()
      local ok, err = files.create 'snippet.ts'
      assert.is_true(ok)
      assert.is_nil(err)
      assert.equals(1, vim.fn.filereadable(test_dir .. '/snippet.ts'))
    end)

    it('should fail if file already exists', function()
      files.create 'duplicate'
      local ok, err = files.create 'duplicate'
      assert.is_false(ok)
      assert.equals('File already exists', err)
    end)

    it('should create file with header', function()
      files.create 'with-header'
      local content = vim.fn.readfile(test_dir .. '/with-header.md')
      assert.equals('# with-header', content[1])
    end)
  end)

  describe('delete', function()
    it('should delete an existing note', function()
      files.create 'to-delete'
      local ok, err = files.delete 'to-delete.md'
      assert.is_true(ok)
      assert.is_nil(err)
      assert.equals(0, vim.fn.filereadable(test_dir .. '/to-delete.md'))
    end)

    it('should fail if file does not exist', function()
      local ok, err = files.delete 'nonexistent.md'
      assert.is_false(ok)
      assert.equals('File not found', err)
    end)
  end)

  describe('rename', function()
    it('should rename an existing note', function()
      files.create 'old-name'
      local ok, err = files.rename('old-name.md', 'new-name')
      assert.is_true(ok)
      assert.is_nil(err)
      assert.equals(0, vim.fn.filereadable(test_dir .. '/old-name.md'))
      assert.equals(1, vim.fn.filereadable(test_dir .. '/new-name.md'))
    end)

    it('should fail if source does not exist', function()
      local ok, err = files.rename('nonexistent.md', 'new-name')
      assert.is_false(ok)
      assert.equals('File not found', err)
    end)

    it('should fail if target already exists', function()
      files.create 'source'
      files.create 'target'
      local ok, err = files.rename('source.md', 'target')
      assert.is_false(ok)
      assert.equals('Target file already exists', err)
    end)
  end)

  describe('list_files', function()
    it('should return empty list when no files', function()
      local list = files.list_files()
      assert.equals(0, #list)
    end)

    it('should list all files', function()
      files.create 'note1'
      files.create 'note2'
      files.create 'note3'
      local list = files.list_files()
      assert.equals(3, #list)
    end)

    it('should sort by modification time (newest first)', function()
      files.create 'old'
      vim.loop.sleep(100) -- ensure different mtime
      files.create 'new'
      local list = files.list_files()
      assert.equals('new.md', list[1])
      assert.equals('old.md', list[2])
    end)
  end)

  describe('get_path', function()
    it('should return full path', function()
      local path = files.get_path 'test.md'
      assert.equals(test_dir .. '/test.md', path)
    end)
  end)
end)
