describe('vinote.state', function()
  local state

  before_each(function()
    package.loaded['vinote.state'] = nil
    state = require 'vinote.state'
  end)

  describe('initial state', function()
    it('should have nil windows and buffers', function()
      assert.is_nil(state.state.list_win)
      assert.is_nil(state.state.list_buf)
      assert.is_nil(state.state.preview_win)
      assert.is_nil(state.state.preview_buf)
    end)

    it('should have empty files list', function()
      assert.equals(0, #state.state.files)
    end)

    it('should have selected_index of 1', function()
      assert.equals(1, state.state.selected_index)
    end)

    it('should have focus on list', function()
      assert.equals('list', state.state.focus)
    end)
  end)

  describe('reset', function()
    it('should reset all state to defaults', function()
      state.state.list_win = 123
      state.state.list_buf = 456
      state.state.files = { 'a', 'b', 'c' }
      state.state.selected_index = 5
      state.state.focus = 'preview'

      state.reset()

      assert.is_nil(state.state.list_win)
      assert.is_nil(state.state.list_buf)
      assert.equals(0, #state.state.files)
      assert.equals(1, state.state.selected_index)
      assert.equals('list', state.state.focus)
    end)
  end)

  describe('is_open', function()
    it('should return false when list_win is nil', function()
      assert.is_false(state.is_open())
    end)

    it('should return false when list_win is invalid', function()
      state.state.list_win = 99999
      assert.is_false(state.is_open())
    end)
  end)
end)
