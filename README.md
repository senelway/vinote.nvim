# Vinote
<img alt="vinote" src="https://github.com/user-attachments/assets/03e86b33-5292-47fa-9fb5-3c3f2d26351b" />

A floating window note-taking plugin for Neovim.

## Installation

### lazy.nvim

```lua
{
  name = 'vinote',
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
      list_height = 0.3,
    },
  }
}
```

## Options

### `notes_dir`
- **Type:** `string`
- **Default:** `~/.config/nvim/vinote`
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
| `list_height` | `number` | `0.3` | File list pane height as ratio of window (0-1) |

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
| `<Tab>` | Switch focus to preview |
| `q` / `<Esc>` | Close vinote |

### In Preview

| Key | Action |
|-----|--------|
| `j` / `k` | Scroll content |
| `<Tab>` | Switch focus to file list |
| `q` / `<Esc>` | Close vinote |
| `:w` | Save changes (preview is editable) |

