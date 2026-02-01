describe('vinote.ui', function()
  local ui
  local state
  local files
  local test_dir = '/tmp/vinote-ui-test-' .. os.time()

  before_each(function()
    package.loaded['vinote.ui'] = nil
    package.loaded['vinote.state'] = nil
    package.loaded['vinote.files'] = nil
    ui = require 'vinote.ui'
    state = require 'vinote.state'
    files = require 'vinote.files'
    files.set_notes_dir(test_dir)
    vim.fn.mkdir(test_dir, 'p')
  end)

  after_each(function()
    pcall(ui.close)
    vim.fn.delete(test_dir, 'rf')
  end)

  describe('module', function()
    it('should export toggle function', function()
      assert.is_function(ui.toggle)
    end)

    it('should export open function', function()
      assert.is_function(ui.open)
    end)

    it('should export close function', function()
      assert.is_function(ui.close)
    end)

    it('should export set_config function', function()
      assert.is_function(ui.set_config)
    end)

    it('should export refresh_list function', function()
      assert.is_function(ui.refresh_list)
    end)

    it('should export refresh_preview function', function()
      assert.is_function(ui.refresh_preview)
    end)
  end)

  describe('set_config', function()
    it('should accept width option', function()
      assert.has_no.errors(function()
        ui.set_config { width = 0.5 }
      end)
    end)

    it('should accept height option', function()
      assert.has_no.errors(function()
        ui.set_config { height = 0.8 }
      end)
    end)

    it('should accept list_height option', function()
      assert.has_no.errors(function()
        ui.set_config { list_height = 0.4 }
      end)
    end)
  end)

  describe('open', function()
    it('should create list window', function()
      ui.open()
      assert.is_not_nil(state.state.list_win)
      assert.is_true(vim.api.nvim_win_is_valid(state.state.list_win))
    end)

    it('should create preview window', function()
      ui.open()
      assert.is_not_nil(state.state.preview_win)
      assert.is_true(vim.api.nvim_win_is_valid(state.state.preview_win))
    end)

    it('should create list buffer', function()
      ui.open()
      assert.is_not_nil(state.state.list_buf)
      assert.is_true(vim.api.nvim_buf_is_valid(state.state.list_buf))
    end)

    it('should set is_open to true', function()
      ui.open()
      assert.is_true(state.is_open())
    end)
  end)

  describe('close', function()
    it('should close list window', function()
      ui.open()
      local win = state.state.list_win
      ui.close()
      assert.is_false(vim.api.nvim_win_is_valid(win))
    end)

    it('should close preview window', function()
      ui.open()
      local win = state.state.preview_win
      ui.close()
      assert.is_false(vim.api.nvim_win_is_valid(win))
    end)

    it('should reset state', function()
      ui.open()
      ui.close()
      assert.is_nil(state.state.list_win)
      assert.is_nil(state.state.preview_win)
    end)

    it('should set is_open to false', function()
      ui.open()
      ui.close()
      assert.is_false(state.is_open())
    end)
  end)

  describe('toggle', function()
    it('should open when closed', function()
      ui.toggle()
      assert.is_true(state.is_open())
    end)

    it('should close when open', function()
      ui.open()
      ui.toggle()
      assert.is_false(state.is_open())
    end)
  end)

  describe('with notes', function()
    before_each(function()
      files.create('note1')
      files.create('note2')
    end)

    it('should display notes in list', function()
      ui.open()
      local lines = vim.api.nvim_buf_get_lines(state.state.list_buf, 0, -1, false)
      assert.equals(2, #lines)
    end)

    it('should select first note by default', function()
      ui.open()
      assert.equals(1, state.state.selected_index)
    end)
  end)
end)
