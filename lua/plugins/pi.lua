return {
    dir = vim.fn.stdpath("config") .. "/plugins/pi.nvim",
    name = "pi.nvim",
    main = "pi",
    opts = {
        cmd = { "pi" },
        temp_session = true,
    },
}
