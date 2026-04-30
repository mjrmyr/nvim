-- bootstrap lazy.nvim

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    setup = {
        { import = "config.plugins" }
    },
    -- NOTE: Plugins can be added via a link or github org/name. To run setup automatically, use `opts = {}`
    { "NMAC427/guess-indent.nvim", opts = {} },

    -- Alternatively, use `config = function() ... end` for full control over the configuration.
    -- If you prefer to call `setup` explicitly, use:
    --    {
        --        'lewis6991/gitsigns.nvim',
        --        config = function()
            --            require('gitsigns').setup({
                --                -- Your gitsigns configuration here
                --            })
                --        end,
                --    }
                --
                -- Here is a more advanced example where we pass configuration
                -- options to `gitsigns.nvim`.
                --
                -- See `:help gitsigns` to understand what the configuration keys do
                { -- Adds git related signs to the gutter, as well as utilities for managing changes
                    "lewis6991/gitsigns.nvim",
                    ---@module 'gitsigns'
                    ---@type Gitsigns.Config
                    ---@diagnostic disable-next-line: missing-fields
                    opts = {
                        signs = {
                            add = { text = "+" }, ---@diagnostic disable-line: missing-fields
                            change = { text = "~" }, ---@diagnostic disable-line: missing-fields
                            delete = { text = "_" }, ---@diagnostic disable-line: missing-fields
                            topdelete = { text = "‾" }, ---@diagnostic disable-line: missing-fields
                            changedelete = { text = "~" }, ---@diagnostic disable-line: missing-fields
                        },
                    },
                },

                -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
                --
                -- This is often very useful to both group configuration, as well as handle
                -- lazy loading plugins that don't need to be loaded immediately at startup.
                --
                -- For example, in the following configuration, we use:
                --  event = 'VimEnter'
                --
                -- which loads which-key before all the UI elements are loaded. Events can be
                -- normal autocommands events (`:help autocmd-events`).
                --
                -- Then, because we use the `opts` key (recommended), the configuration runs
                -- after the plugin has been loaded as `require(MODULE).setup(opts)`.

                -- NOTE: Plugins can specify dependencies.
                --
                -- The dependencies are proper plugin specifications as well - anything
                -- you do for a plugin at the top level, you can do for a dependency.
                --
                -- Use the `dependencies` key to specify the dependencies of a particular plugin

                { -- Fuzzy Finder (files, lsp, etc)
                    "nvim-telescope/telescope.nvim",
                    -- By default, Telescope is included and acts as your picker for everything.

                    -- If you would like to switch to a different picker (like snacks, or fzf-lua)
                    -- you can disable the Telescope plugin by setting enabled to false and enable
                    -- your replacement picker by requiring it explicitly (e.g. 'custom.plugins.snacks')

                    -- Note: If you customize your config for yourself,
                    -- it’s best to remove the Telescope plugin config entirely
                    -- instead of just disabling it here, to keep your config clean.
                    enabled = true,
                    event = "VimEnter",
                    dependencies = {
                        "nvim-lua/plenary.nvim",
                        { -- If encountering errors, see telescope-fzf-native README for installation instructions
                            "nvim-telescope/telescope-fzf-native.nvim",

                            -- `build` is used to run some command when the plugin is installed/updated.
                            -- This is only run then, not every time Neovim starts up.
                            build = "make",

                            -- `cond` is a condition used to determine whether this plugin should be
                            -- installed and loaded.
                            cond = function()
                                return vim.fn.executable("make") == 1
                            end,
                        },
                        { "nvim-telescope/telescope-ui-select.nvim" },

                        -- Useful for getting pretty icons, but requires a Nerd Font.
                        { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
                    },
                    config = function()
                        -- Telescope is a fuzzy finder that comes with a lot of different things that
                        -- it can fuzzy find! It's more than just a "file finder", it can search
                        -- many different aspects of Neovim, your workspace, LSP, and more!
                        --
                        -- The easiest way to use Telescope, is to start by doing something like:
                        --  :Telescope help_tags
                        --
                        -- After running this command, a window will open up and you're able to
                        -- type in the prompt window. You'll see a list of `help_tags` options and
                        -- a corresponding preview of the help.
                        --
                        -- Two important keymaps to use while in Telescope are:
                        --  - Insert mode: <c-/>
                        --  - Normal mode: ?
                        --
                        -- This opens a window that shows you all of the keymaps for the current
                        -- Telescope picker. This is really useful to discover what Telescope can
                        -- do as well as how to actually do it!

                        -- [[ Configure Telescope ]]
                        -- See `:help telescope` and `:help telescope.setup()`
                        require("telescope").setup({
                            -- You can put your default mappings / updates / etc. in here
                            --  All the info you're looking for is in `:help telescope.setup()`
                            --
                            -- defaults = {
                                --   mappings = {
                                    --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
                                    --   },
                                    -- },
                                    -- pickers = {}
                                    extensions = {
                                        ["ui-select"] = { require("telescope.themes").get_dropdown() },
                                    },
                                })

                                -- Enable Telescope extensions if they are installed
                                pcall(require("telescope").load_extension, "fzf")
                                pcall(require("telescope").load_extension, "ui-select")

                                -- See `:help telescope.builtin`
                                local builtin = require("telescope.builtin")
                                vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
                                vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
                                vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
                                vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
                                vim.keymap.set({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
                                vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
                                vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
                                vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
                                vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
                                vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "[S]earch [C]ommands" })
                                vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

                                -- This runs on LSP attach per buffer (see main LSP attach function in 'neovim/nvim-lspconfig' config for more info,
                                -- it is better explained there). This allows easily switching between pickers if you prefer using something else!
                                vim.api.nvim_create_autocmd("LspAttach", {
                                    group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
                                    callback = function(event)
                                        local buf = event.buf

                                        -- Find references for the word under your cursor.
                                        vim.keymap.set("n", "grr", builtin.lsp_references, { buffer = buf, desc = "[G]oto [R]eferences" })

                                        -- Jump to the implementation of the word under your cursor.
                                        -- Useful when your language has ways of declaring types without an actual implementation.
                                        vim.keymap.set(
                                            "n",
                                            "gri",
                                            builtin.lsp_implementations,
                                            { buffer = buf, desc = "[G]oto [I]mplementation" }
                                        )

                                        -- Jump to the definition of the word under your cursor.
                                        -- This is where a variable was first declared, or where a function is defined, etc.
                                        -- To jump back, press <C-t>.
                                        vim.keymap.set("n", "grd", builtin.lsp_definitions, { buffer = buf, desc = "[G]oto [D]efinition" })

                                        -- Fuzzy find all the symbols in your current document.
                                        -- Symbols are things like variables, functions, types, etc.
                                        vim.keymap.set(
                                            "n",
                                            "gO",
                                            builtin.lsp_document_symbols,
                                            { buffer = buf, desc = "Open Document Symbols" }
                                        )

                                        -- Fuzzy find all the symbols in your current workspace.
                                        -- Similar to document symbols, except searches over your entire project.
                                        vim.keymap.set(
                                            "n",
                                            "gW",
                                            builtin.lsp_dynamic_workspace_symbols,
                                            { buffer = buf, desc = "Open Workspace Symbols" }
                                        )

                                        -- Jump to the type of the word under your cursor.
                                        -- Useful when you're not sure what type a variable is and you want to see
                                        -- the definition of its *type*, not where it was *defined*.
                                        vim.keymap.set(
                                            "n",
                                            "grt",
                                            builtin.lsp_type_definitions,
                                            { buffer = buf, desc = "[G]oto [T]ype Definition" }
                                        )
                                    end,
                                })

                                -- Override default behavior and theme when searching
                                vim.keymap.set("n", "<leader>/", function()
                                    -- You can pass additional configuration to Telescope to change the theme, layout, etc.
                                    builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
                                        winblend = 10,
                                        previewer = false,
                                    }))
                                end, { desc = "[/] Fuzzily search in current buffer" })

                                -- It's also possible to pass additional configuration options.
                                --  See `:help telescope.builtin.live_grep()` for information about particular keys
                                vim.keymap.set("n", "<leader>s/", function()
                                    builtin.live_grep({
                                        grep_open_files = true,
                                        prompt_title = "Live Grep in Open Files",
                                    })
                                end, { desc = "[S]earch [/] in Open Files" })

                                -- Shortcut for searching your Neovim configuration files
                                vim.keymap.set("n", "<leader>sn", function()
                                    builtin.find_files({ cwd = vim.fn.stdpath("config") })
                                end, { desc = "[S]earch [N]eovim files" })
                            end,
                        },
                        { -- Autoformat
                            "stevearc/conform.nvim",
                            event = { "BufWritePre" },
                            cmd = { "ConformInfo" },
                            keys = {
                                {
                                    "<leader>f",
                                    function()
                                        require("conform").format({ async = true, lsp_format = "fallback" })
                                    end,
                                    mode = "",
                                    desc = "[F]ormat buffer",
                                },
                            },
                            ---@module 'conform'
                            ---@type conform.setupOpts
                            opts = {
                                notify_on_error = false,
                                format_on_save = function(bufnr)
                                    -- Disable "format_on_save lsp_fallback" for languages that don't
                                    -- have a well standardized coding style. You can add additional
                                    -- languages here or re-enable it for the disabled ones.
                                    local disable_filetypes = { c = true, cpp = true }
                                    if disable_filetypes[vim.bo[bufnr].filetype] then
                                        return nil
                                    else
                                        return {
                                            timeout_ms = 500,
                                            lsp_format = "fallback",
                                        }
                                    end
                                end,
                                formatters_by_ft = {
                                    lua = { "stylua" },
                                    -- Conform can also run multiple formatters sequentially
                                    -- python = { "isort", "black" },
                                    --
                                    -- You can use 'stop_after_first' to run the first available formatter from the list
                                    -- javascript = { "prettierd", "prettier", stop_after_first = true },
                                },
                            },
                        },

                        { -- Autocompletion
                            "saghen/blink.cmp",
                            event = "VimEnter",
                            version = "1.*",
                            dependencies = {
                                -- Snippet Engine
                                {
                                    "L3MON4D3/LuaSnip",
                                    version = "2.*",
                                    build = (function()
                                        -- Build Step is needed for regex support in snippets.
                                        -- This step is not supported in many windows environments.
                                        -- Remove the below condition to re-enable on windows.
                                        if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
                                            return
                                        end
                                        return "make install_jsregexp"
                                    end)(),
                                    dependencies = {
                                        -- `friendly-snippets` contains a variety of premade snippets.
                                        --    See the README about individual language/framework/plugin snippets:
                                        --    https://github.com/rafamadriz/friendly-snippets
                                        -- {
                                            --   'rafamadriz/friendly-snippets',
                                            --   config = function()
                                                --     require('luasnip.loaders.from_vscode').lazy_load()
                                                --   end,
                                                -- },
                                            },
                                            opts = {},
                                        },
                                    },
                                    ---@module 'blink.cmp'
                                    ---@type blink.cmp.Config
                                    opts = {
                                        keymap = {
                                            -- 'default' (recommended) for mappings similar to built-in completions
                                            --   <c-y> to accept ([y]es) the completion.
                                            --    This will auto-import if your LSP supports it.
                                            --    This will expand snippets if the LSP sent a snippet.
                                            -- 'super-tab' for tab to accept
                                            -- 'enter' for enter to accept
                                            -- 'none' for no mappings
                                            --
                                            -- For an understanding of why the 'default' preset is recommended,
                                            -- you will need to read `:help ins-completion`
                                            --
                                            -- No, but seriously. Please read `:help ins-completion`, it is really good!
                                            --
                                            -- All presets have the following mappings:
                                            -- <tab>/<s-tab>: move to right/left of your snippet expansion
                                            -- <c-space>: Open menu or open docs if already open
                                            -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
                                            -- <c-e>: Hide menu
                                            -- <c-k>: Toggle signature help
                                            --
                                            -- See :h blink-cmp-config-keymap for defining your own keymap
                                            preset = "default",

                                            -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                                            --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
                                        },

                                        appearance = {
                                            -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                                            -- Adjusts spacing to ensure icons are aligned
                                            nerd_font_variant = "mono",
                                        },

                                        completion = {
                                            -- By default, you may press `<c-space>` to show the documentation.
                                            -- Optionally, set `auto_show = true` to show the documentation after a delay.
                                            documentation = { auto_show = false, auto_show_delay_ms = 500 },
                                        },

                                        sources = {
                                            default = { "lsp", "path", "snippets" },
                                        },

                                        snippets = { preset = "luasnip" },

                                        -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
                                        -- which automatically downloads a prebuilt binary when enabled.
                                        --
                                        -- By default, we use the Lua implementation instead, but you may enable
                                        -- the rust implementation via `'prefer_rust_with_warning'`
                                        --
                                        -- See :h blink-cmp-config-fuzzy for more information
                                        fuzzy = { implementation = "lua" },

                                        -- Shows a signature help window while you type arguments for a function
                                        signature = { enabled = true },
                                    },
                                },

                                { -- You can easily change to a different colorscheme.
                                    -- Change the name of the colorscheme plugin below, and then
                                    -- change the command in the config to whatever the name of that colorscheme is.
                                    --
                                    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
                                    "folke/tokyonight.nvim",
                                    priority = 1000, -- Make sure to load this before all the other start plugins.
                                    config = function()
                                        ---@diagnostic disable-next-line: missing-fields
                                        require("tokyonight").setup({
                                            styles = {
                                                comments = { italic = false }, -- Disable italics in comments
                                            },
                                        })

                                        -- Load the colorscheme here.
                                        -- Like many other themes, this one has different styles, and you could load
                                        -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
                                        vim.cmd.colorscheme("tokyonight-night")
                                    end,
                                },

                                -- Highlight todo, notes, etc in comments
                                {
                                    "folke/todo-comments.nvim",
                                    event = "VimEnter",
                                    dependencies = { "nvim-lua/plenary.nvim" },
                                    ---@module 'todo-comments'
                                    ---@type TodoOptions
                                    ---@diagnostic disable-next-line: missing-fields
                                    opts = { signs = false },
                                },
                                -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
                                -- init.lua. If you want these files, they are in the repository, so you can just download them and
                                -- place them in the correct locations.

                                -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
                                --
                                --  Here are some example plugins that I've included in the Kickstart repository.
                                --  Uncomment any of the lines below to enable them (you will need to restart nvim).
                                --
                                -- require 'kickstart.plugins.debug',
                                -- require 'kickstart.plugins.indent_line',
                                -- require 'kickstart.plugins.lint',
                                -- require 'kickstart.plugins.autopairs',
                                -- require 'kickstart.plugins.neo-tree',
                                -- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommended keymaps

                                -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
                                --    This is the easiest way to modularize your config.
                                --
                                --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
                                -- { import = 'custom.plugins' },
                                --
                                -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
                                -- Or use telescope!
                                -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
                                -- you can continue same window with `<space>sr` which resumes last telescope search
                            }, { ---@diagnostic disable-line: missing-fields
                                ui = {
                                    -- If you are using a Nerd Font: set icons to an empty table which will use the
                                    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
                                    icons = vim.g.have_nerd_font and {} or {
                                        cmd = "⌘",
                                        config = "🛠",
                                        event = "📅",
                                        ft = "📂",
                                        init = "⚙",
                                        keys = "🗝",
                                        plugin = "🔌",
                                        runtime = "💻",
                                        require = "🌙",
                                        source = "📄",
                                        start = "🚀",
                                        task = "📌",
                                        lazy = "💤 ",
                                    },
                                },
                            })

