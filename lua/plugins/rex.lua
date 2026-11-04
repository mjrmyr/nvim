return {
    {
        dir = vim.fn.stdpath("config") .. "/rex.nvim",
        name = "rex.nvim",
        main = "rex",
        lazy = false,
        priority = 1000,
        dependencies = { "nvim-mini/mini.nvim" },
        opts = {},
    },
}
