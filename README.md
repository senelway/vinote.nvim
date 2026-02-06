# Vinote

<img alt="vinote" src="https://github.com/user-attachments/assets/03e86b33-5292-47fa-9fb5-3c3f2d26351b" />

A floating window note-taking plugin for Neovim.

## Features

- Floating UI with file list and preview panes
- Notes sorted by modification time (most recent first)
- Auto-saves on close
- Auto-adds `.md` extension if not specified
- Optional [snacks.nvim](https://github.com/folke/snacks.nvim) integration for notifications

## Installation

### lazy.nvim

```lua
{
  'senelway/vinote.nvim',
  event = 'VeryLazy',
  opts = {
    notes_dir = vim.fn.stdpath 'config' .. '/vinote',
    keys = {
      toggle = '<leader>vv',
      new_note = '<leader>vn',
    },
    window = {
      width = 0.6,
      height = 0.7,
      layout = 'vertical',
      list_height = 0.3,
      list_width = 0.3,
      show_footer_keys = true,
    },
  },
}
```

## Options

### `notes_dir`

- **Type:** `string`
- **Default:** `vim.fn.stdpath('config') .. '/vinote'`
- **Description:** Directory where notes are stored.

### `keys`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `toggle` | `string` | `nil` | Keymap to toggle the vinote UI |
| `new_note` | `string` | `nil` | Keymap to quickly create a new note |

### `window`

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `width` | `number` | `0.6` | Window width as ratio of screen (0-1) |
| `height` | `number` | `0.7` | Window height as ratio of screen (0-1) |
| `layout` | `string` | `'vertical'` | Pane layout: `'vertical'` (list top, preview bottom) or `'horizontal'` (list left, preview right) |
| `list_height` | `number` | `0.3` | File list pane height as ratio of window, used in vertical layout (0-1) |
| `list_width` | `number` | `0.3` | File list pane width as ratio of window, used in horizontal layout (0-1) |
| `show_footer_keys` | `boolean` | `true` | Show keybinding hints in window footer |

## Keybindings

### Global (configurable via opts.keys)

| Key | Action |
|-----|--------|
| `<leader>vv` | Toggle vinote UI |
| `<leader>vn` | Quick create new note |

### In File List

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate up/down |
| `<CR>` | Open note in editor |
| `n` | Create new note |
| `d` | Delete note (with confirmation) |
| `r` | Rename note |
| `<Tab>` / `<C-j>` (vertical) / `<C-l>` (horizontal) | Switch focus to preview |
| `q` / `<Esc>` | Close vinote |

### In Preview

| Key | Action |
|-----|--------|
| `<Tab>` / `<C-k>` (vertical) / `<C-h>` (horizontal) | Switch focus to file list |
| `w` | Save changes |
| `q` / `<Esc>` | Close vinote |

## API

```lua
local vinote = require('vinote')

vinote.toggle()    -- Toggle the UI
vinote.open()      -- Open the UI
vinote.close()     -- Close the UI
vinote.new_note()  -- Create a new note (prompts for name)
```

