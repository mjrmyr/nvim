return {
    {
        "sainnhe/sonokai",
        enabled = false,
        priority = 1000,
        config = function()
            vim.g.sonokai_enable_italic = false
            vim.g.sonokai_style = "maia"
            vim.cmd.colorscheme("sonokai")
        end,
    },
}
