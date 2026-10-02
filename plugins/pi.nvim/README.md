# pi.nvim

Neovim helper plugin for chatting with Pi via RPC and sending visual selections to it.

## Installation

With lazy.nvim:

```lua
{
  "yourname/pi.nvim",
  opts = {
    cmd = { "pi" },
    temp_session = true,
  },
}
```

For local development:

```lua
{
  dir = "~/path/to/pi.nvim",
  name = "pi.nvim",
  opts = {},
}
```

## Usage

Default commands/mappings:

- `:PiChat` opens the Pi chat window
- `:PiPrompt` sends a prompt to Pi
- `<leader>pc` toggles the Pi chat window
- visual `<leader>pq` asks Pi about the selected code
- message types use distinct foreground/background highlights
- tool calls use their own background and show arguments, including bash commands and file paths
- `<CR>` prompts from the chat buffer
- `q` closes the floating Pi window

## Configuration

```lua
require("pi").setup({
  -- pi.nvim always adds `--mode rpc` when starting Pi.
  cmd = { "pi" },
  -- Store this Neovim instance's Pi session in a temporary session directory.
  -- Reopening Pi inside the same editor resumes that session; closing Neovim deletes it.
  temp_session = false,
  width = 0.85,
  height = 0.8,
  block_margin = 1,
  block_padding = 2,
  mappings = {
    toggle = "<leader>pc",
    ask_selection = "<leader>pq",
    close = "q",
    prompt = "<CR>",
  },
})
```

`block_margin` controls blank lines between message/tool blocks. `block_padding` controls spaces added to both sides of highlighted blocks.

Set any mapping to `false` to disable it.
