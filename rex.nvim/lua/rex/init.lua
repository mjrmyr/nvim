-- rex.nvim: integrate Neovim with the Rex terminal.
local M = {}

local defaults = {
    -- Derive the colorscheme from the active Rex theme (needs mini.nvim).
    theme = true,
    -- Keys that move between Neovim windows and Rex panes, or false to disable.
    -- These are what Rex sends for Cmd+Opt+arrows (see rex/navigate.lua).
    navigation = { left = "<D-M-Left>", down = "<D-M-Down>", up = "<D-M-Up>", right = "<D-M-Right>" },
}

function M.setup(opts)
    opts = vim.tbl_deep_extend("force", defaults, opts or {})
    if opts.theme then
        require("rex.theme").setup()
    end
    if opts.navigation then
        require("rex.navigate").setup(opts.navigation)
    end
end

return M
