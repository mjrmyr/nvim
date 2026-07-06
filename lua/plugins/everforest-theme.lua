return {
    {
        "sainnhe/everforest",
        enabled = true,
        priority = 1000,
        config = function()
            vim.g.everforest_enable_italic = false
            vim.g.everforest_background = "hard"
            vim.cmd.colorscheme("everforest")
        end,
    },
}
