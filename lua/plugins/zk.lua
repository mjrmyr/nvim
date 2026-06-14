return {
    {
        "zk-org/zk-nvim",
        name = "zk",
        -- Use `config` instead of `opts` so we can register custom commands
        -- and keymaps after setup runs.
        config = function()
            local zk = require("zk")
            local commands = require("zk.commands")

            -- ── Core setup ───────────────────────────────────────────────────────
            zk.setup({
                -- Picker used by built-in commands (ZkNotes, ZkTags, …)
                picker = "telescope",

                lsp = {
                    config = {
                        name = "zk",
                        cmd = { "zk", "lsp" },
                        filetypes = { "markdown" },

                        -- Buffer-local keymaps – only active inside a zk notebook
                        on_attach = function(_, bufnr)
                            local opts = { buffer = bufnr, noremap = true, silent = true }

                            -- Navigate links
                            vim.keymap.set(
                                "n",
                                "<CR>",
                                "<Cmd>ZkLinks<CR>",
                                vim.tbl_extend("force", opts, { desc = "zk: links in note" })
                            )

                            vim.keymap.set(
                                "n",
                                "<BS>",
                                "<Cmd>ZkBacklinks<CR>",
                                vim.tbl_extend("force", opts, { desc = "zk: backlinks to note" })
                            )

                            -- Open / peek linked note under cursor
                            vim.keymap.set(
                                "n",
                                "gd",
                                vim.lsp.buf.definition,
                                vim.tbl_extend("force", opts, { desc = "zk: go to linked note" })
                            )

                            -- Insert a link to another note while in insert/normal mode
                            vim.keymap.set(
                                "n",
                                "<leader>zi",
                                "<Cmd>ZkInsertLink<CR>",
                                vim.tbl_extend("force", opts, { desc = "zk: [i]nsert link" })
                            )
                        end,
                    },

                    auto_attach = {
                        enabled = true,
                    },
                },
            })

            -- ── Custom commands ───────────────────────────────────────────────────
            -- Create a fleeting (quick-capture) note, always in the `inbox/` dir.
            commands.add("ZkNewFleeting", function(opts)
                opts = vim.tbl_extend("force", opts or {}, { dir = "inbox" })
                vim.ui.input({ prompt = "Fleeting note title: " }, function(input)
                    if input and input ~= "" then
                        opts.title = input
                    end
                    zk.new(opts)
                end)
            end)

            -- Create a permanent note in `notes/`.
            commands.add("ZkNewPermanent", function(opts)
                opts = vim.tbl_extend("force", opts or {}, { dir = "notes", group = "permanent" })
                vim.ui.input({ prompt = "Permanent note title: " }, function(input)
                    if not input or input == "" then
                        return
                    end
                    opts.title = input
                    zk.new(opts)
                end)
            end)

            -- Create a source note in `references/`
            commands.add("ZkNewReference", function(opts)
                opts = vim.tbl_extend("force", opts or {}, { dir = "references", group = "reference" })
                vim.ui.input({ prompt = "Reference note title: " }, function(input)
                    if not input or input == "" then
                        return
                    end
                    opts.title = input
                    zk.new(opts)
                end)
            end)

            -- Open today's daily note (creates it if it doesn't exist yet).
            commands.add("ZkDaily", function(opts)
                opts = vim.tbl_extend("force", opts or {}, {
                    dir = "daily",
                    group = "daily",
                })
                zk.new(opts)
            end)

            -- ── Global keymaps (<leader>z …) ─────────────────────────────────────
            local map = function(lhs, rhs, desc)
                vim.keymap.set("n", lhs, rhs, { noremap = true, silent = true, desc = "zk: " .. desc })
            end

            -- Note creation
            map("<leader>zn", "<Cmd>ZkNewFleeting<CR>", "[f]leeting note")
            map("<leader>zp", "<Cmd>ZkNewPermanent<CR>", "[p]ermanent note")
            map("<leader>zr", "<Cmd>ZkNewReference<CR>", "[r]eference note")
            map("<leader>zd", "<Cmd>ZkDaily<CR>", "[d]aily note")

            -- Browsing
            map("<leader>zo", "<Cmd>ZkNotes<CR>", "[o]pen / search notes")
            map("<leader>zt", "<Cmd>ZkTags<CR>", "[t]ags picker")

            -- Full-text search inside notes
            map("<leader>zs", "<Cmd>ZkNotes { match = vim.fn.input('Search: ') }<CR>", "[s]earch in notes")
        end,
    },
}
