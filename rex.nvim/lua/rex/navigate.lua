-- Move between Neovim windows and Rex panes with the same keys.
--
-- Inside Neovim, the keys move between windows. At the edge of the layout,
-- they ask Rex to focus the neighboring pane instead. The Rex half lives in
-- rex/navigate.lua and sends the keys to Neovim when it is focused.
local M = {}

local wincmd = { left = "h", down = "j", up = "k", right = "l" }

function M.navigate(direction)
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(wincmd[direction])
    if vim.api.nvim_get_current_win() ~= win or not vim.env.REX_SESSION then
        return
    end

    vim.system({ "rex", "focus", "-s", vim.env.REX_SESSION, direction }, { text = true }, function(result)
        if result.code ~= 0 then
            vim.schedule(function()
                vim.notify("rex.nvim: " .. vim.trim(result.stderr), vim.log.levels.WARN)
            end)
        end
    end)
end

function M.setup(keys)
    for direction, key in pairs(keys) do
        vim.keymap.set({ "n", "i", "t" }, key, function()
            M.navigate(direction)
        end, { desc = "Focus window or Rex pane " .. direction })
    end
end

return M
