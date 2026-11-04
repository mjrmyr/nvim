-- Derive the colorscheme from the active Rex terminal theme.
--
-- Rex doesn't answer OSC 11 background queries, so Neovim can't detect the
-- theme itself. Instead, read the selected theme IDs from Rex's macOS defaults
-- and the colors from the theme catalog bundled with the app, then feed them
-- to mini.base16.
local M = {}

local themes_paths = {
    "/Applications/Rex.app/Contents/Resources/SuperUI_SuperDesignTokens.bundle/Contents/Resources/themes.json",
    "/Applications/Rex Beta.app/Contents/Resources/SuperUI_SuperDesignTokens.bundle/Contents/Resources/themes.json",
}

local function defaults_read(...)
    local result = vim.system({ "defaults", "read", ... }, { text = true }):wait()
    if result.code == 0 then
        return vim.trim(result.stdout)
    end
end

local function find_theme(id)
    for _, path in ipairs(themes_paths) do
        local file = io.open(path, "r")
        if file then
            local themes = vim.json.decode(file:read("*a"))
            file:close()
            for _, theme in ipairs(themes) do
                if theme.id == id then
                    return theme
                end
            end
        end
    end
end

-- Linear mix of two "#rrggbb" colors: t = 0 gives a, t = 1 gives b.
local function mix(a, b, t)
    local out = "#"
    for i = 2, 6, 2 do
        local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
        out = out .. string.format("%02x", math.floor(x + (y - x) * t + 0.5))
    end
    return out
end

-- Map a Rex theme onto base16 slots. `ansi` is 1-indexed: ansi[2] is color 1 (red).
local function palette(source)
    local bg, fg, ansi = source.background, source.foreground, source.ansi
    return {
        base00 = bg,
        base01 = mix(bg, fg, 0.07), -- cursorline, statusline
        base02 = mix(bg, fg, 0.18), -- visual selection
        base03 = ansi[9], -- comments
        base04 = mix(bg, fg, 0.6),
        base05 = fg,
        base06 = fg,
        base07 = fg,
        base08 = ansi[2], -- red
        base09 = mix(ansi[2], ansi[4], 0.5), -- orange
        base0A = ansi[4], -- yellow
        base0B = ansi[3], -- green
        base0C = ansi[7], -- cyan
        base0D = ansi[5], -- blue
        base0E = ansi[6], -- magenta
        base0F = ansi[14], -- bright magenta
    }
end

local applied

function M.apply()
    local dark = defaults_read("-g", "AppleInterfaceStyle") == "Dark"
    local id = defaults_read("com.superlogical.rex", dark and "Workspace.darkThemeID" or "Workspace.lightThemeID")
    if id == nil or id == applied then
        return
    end

    local theme = find_theme(id)
    if not theme then
        vim.notify("rex.nvim: Rex theme '" .. id .. "' not found", vim.log.levels.WARN)
        return
    end

    vim.o.background = theme.appearance
    require("mini.base16").setup({ palette = palette(theme.source) })
    applied = id
end

function M.setup()
    M.apply()
    -- Pick up theme or appearance switches made while Neovim was in the background.
    vim.api.nvim_create_autocmd("FocusGained", {
        group = vim.api.nvim_create_augroup("rex.theme", { clear = true }),
        callback = M.apply,
    })
end

return M
