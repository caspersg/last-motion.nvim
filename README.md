# last-motion.nvim
Repeat the last motion or reverse the last motion in Neovim.

Like . (dot) repeat, but for motions.

So you can:
- repeat the last motion
- reverse the last motion
- add a count prefix to a repeat

Motion keymaps are replaced with next/prev pairs of keymaps that remember the previous motion.
It remembers direction, so for example 'n' after '?' will continue search upwards through the document.

Some uses:
- ']b' (:bnext keymap), then use n and N to move backwards and forwards through buffers
- '2}' then scroll by 2 paragraphs with 'n' and 'N', or scroll by 4 paragraphs with '2n'
- ']s' continue the most recent search

I've done my best to add every motion in neovim, including treesitter motions like "@attribute.inner".
Many of the motions are defined in [square-motions.nvim](https://github.com/caspersg/square-motions.nvim)

hjkl seem pretty pointless to include, but you can repeat '10j' with 'n', go back up by 10 lines with N.

TODO add  a video

## Installation

**[Lazy.nvim](https://github.com/folke/lazy.nvim)**

```lua
{
  "caspersg/last-motion.nvim",
  dependencies = {
    -- if using the treesitter motions
    { "nvim-treesitter/nvim-treesitter" },
    { "nvim-treesitter/nvim-treesitter-textobjects" },

    -- if using the square-motions keymaps
    { "caspersg/square-motions.nvim" },
  },
  config = function()
    local lm = require("last-motion")
    lm.setup({
        -- empty to keep default config
    })
  end
}

```

## Usage

This assumes the recommended keymaps.

Move around with a motion eg `2}`

repeat the last motion `n`

reverse the last motion `N`

add a count prefix to a repeat `3n`

### Ex commands
repeat last motion `:LastMotionsForward`

reverse last motion `:LastMotionsBackward`

## Default Configuration

The default config has definitions for all the builtin motions I could figure out.
Some of the definitions need to import helper functions.

[Default Config](https://github.com/caspersg/last-motion.nvim/blob/main/lua/last-motion/config.lua)


### Recommended keymaps

I also add these keymaps, which assume [ and ] prefixes from the default config

```lua
-- comma "," is not needed anymore, so I like to use it instead of ] as a motion prefix
vim.keymap.set({"n", "v", "o"}, ",", "]", { remap = true })
```

## Manual Configuration

If you don't want to use any of the default configurations or keymaps, you can register each motion manually.

```lua
{
  "caspersg/last-motion.nvim",
  dependencies = {},
  config = function()
    local lm = require("last-motion")
    lm.setup({
      default_next_previous_keys = false,
      square_motions = false,
      textobjects = false,
      add_operator_pending_keymaps = false,
      key_motions = {},
      read_char_motions = {},
      cmd_motions = {},
      func_motions = {},
    })

    -- Add keymaps for at least forward and backward to do anything useful.
    vim.keymap.set({ "n", "v", "o" }, "n", lm.forward, { desc = "repeat last motion" })
    vim.keymap.set({ "n", "v", "o" }, "N", lm.backward, { desc = "reverse last motion" })

    -- add your own keymaps
    local mem = lm.func_motion(
      function()
        vim.diagnostic.jump({ count = 1, float = true })
      end,
      function()
        vim.diagnostic.jump({ count = -1, float = true })
      end
    )
    vim.keymap.set({ "n", "v", "o" }, "]d", mem.next, { desc = "[d]iagnostic" })
    vim.keymap.set({ "n", "v", "o" }, "[d", mem.prev, { desc = "[d]iagnostic" })
  end,
}
```

## Similar plugins

- [nvim-better-n](https://github.com/jonatan-branting/nvim-better-n)
- [nvim-treesitter-textobjects text-objects-move](https://github.com/nvim-treesitter/nvim-treesitter-textobjects?tab=readme-ov-file#text-objects-move)
- [vim-unimpaired](https://github.com/tpope/vim-unimpaired)
- [mini.bracketed](https://github.com/echasnovski/mini.bracketed)
