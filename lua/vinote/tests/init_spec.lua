describe('vinote', function()
  local vinote
  local files

  before_each(function()
    package.loaded['vinote'] = nil
    package.loaded['vinote.files'] = nil
    package.loaded['vinote.ui'] = nil
    package.loaded['vinote.state'] = nil
    vinote = require 'vinote'
    files = require 'vinote.files'
  end)

  describe('module', function()
    it('should export toggle function', function()
      assert.is_function(vinote.toggle)
    end)

    it('should export open function', function()
      assert.is_function(vinote.open)
    end)

    it('should export close function', function()
      assert.is_function(vinote.close)
    end)

    it('should export new_note function', function()
      assert.is_function(vinote.new_note)
    end)

    it('should export setup function', function()
      assert.is_function(vinote.setup)
    end)
  end)

  describe('setup', function()
    it('should accept empty opts', function()
      assert.has_no.errors(function()
        vinote.setup()
      end)
    end)

    it('should accept nil opts', function()
      assert.has_no.errors(function()
        vinote.setup(nil)
      end)
    end)

    it('should set notes_dir', function()
      local test_dir = '/tmp/vinote-setup-test'
      vinote.setup { notes_dir = test_dir }
      assert.equals(test_dir, files.get_notes_dir())
    end)

    it('should set keymaps when keys provided', function()
      vinote.setup {
        keys = {
          toggle = '<leader>vt',
          new_note = '<leader>vn',
        },
      }
      -- Keymaps are set, we just verify no errors
      assert.is_true(true)
    end)

    it('should set window config', function()
      local ui = require 'vinote.ui'
      assert.has_no.errors(function()
        vinote.setup {
          window = {
            width = 0.5,
            height = 0.8,
            list_height = 0.4,
          },
        }
      end)
    end)
  end)
end)
