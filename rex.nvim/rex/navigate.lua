-- Rex half of rex.nvim's pane navigation. Load it from ~/.config/rex/init.lua:
--
--   dofile(os.getenv("HOME") .. "/.config/nvim/rex.nvim/rex/navigate.lua")
--
-- Cmd+Opt+arrows focus the neighboring pane, as they do by default, except
-- when the focused pane runs Neovim: then the key goes to Neovim, which moves
-- between its own windows and asks Rex to focus the next pane at the edge.
local terminal = "com.superlogical.terminal"

-- Rex keeps Cmd+Opt+arrows for itself, so write the key to Neovim directly.
-- Modifier 11 is Opt+Cmd in xterm encoding; Neovim reads it as <D-M-arrow>.
local sequences = { left = "\27[1;11D", right = "\27[1;11C", up = "\27[1;11A", down = "\27[1;11B" }

local function runs_nvim(block_id)
    local process = rex.block.call(terminal, "process", { block_id = block_id })
    return process ~= nil and process.foreground ~= nil and process.foreground.name == "nvim"
end

rex.action({
    name = "nvim_focus",
    title = "Focus Pane or Neovim Window",
    description = "Focus the neighboring pane, or the neighboring window when the focused pane runs Neovim.",
    category = "Pane",
    args = { direction = "string" },
    run = function(ctx, args)
        if ctx.block_id and runs_nvim(ctx.block_id) then
            rex.block.call(terminal, "write", { block_id = ctx.block_id, data = sequences[args.direction] })
        else
            rex.session.focus_direction({ direction = args.direction })
        end
    end,
})

for direction in pairs(sequences) do
    rex.bind("alt+cmd+" .. direction, "nvim_focus", { direction = direction })
end
