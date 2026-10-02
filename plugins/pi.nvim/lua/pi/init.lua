local M = {}

local defaults = {
    cmd = { "pi" },
    temp_session = false,
    width = 0.85,
    height = 0.8,
    block_margin = 1,
    block_padding = 2,
    mappings = {
        toggle = "<leader>pc",
        ask_selection = "<leader>pq",
        close = "q",
        prompt = "<CR>",
    },
}

M.config = vim.deepcopy(defaults)

local state = {
    job = nil,
    buf = nil,
    win = nil,
    next_id = 0,
    stdout = "",
    session_dir = nil,
    has_started_session = false,
    assistant_response_started = false,
    assistant_thinking_had_delta = false,
    assistant_section = nil,
    markdown_preview_scheduled = false,
}

local function is_valid_buf(buf)
    return buf and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_win(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function is_running_job(job)
    return job and vim.fn.jobwait({ job }, 0)[1] == -1
end

local function normalize_lines(lines)
    local normalized = {}
    for _, line in ipairs(lines) do
        vim.list_extend(normalized, vim.split(tostring(line), "\n", { plain = true }))
    end
    return normalized
end

local function ensure_session_dir()
    if state.session_dir then
        return state.session_dir
    end

    state.session_dir = vim.fn.tempname() .. "-pi-nvim-sessions"
    vim.fn.mkdir(state.session_dir, "p")
    return state.session_dir
end

local function has_arg(cmd, arg)
    return vim.tbl_contains(cmd, arg)
end

local function build_cmd()
    local cmd = vim.deepcopy(M.config.cmd)

    if not has_arg(cmd, "--mode") then
        vim.list_extend(cmd, { "--mode", "rpc" })
    end

    if M.config.temp_session then
        vim.list_extend(cmd, { "--session-dir", ensure_session_dir() })
        if state.has_started_session then
            vim.list_extend(cmd, { "--continue" })
        end
    end

    return cmd
end

local function cleanup_session_dir()
    if is_running_job(state.job) then
        vim.fn.jobstop(state.job)
        state.job = nil
    end
    if state.session_dir then
        vim.fn.delete(state.session_dir, "rf")
        state.session_dir = nil
    end
end

local function window_opts()
    local columns = vim.o.columns
    local lines = vim.o.lines
    local width = math.floor(columns * M.config.width)
    local height = math.floor(lines * M.config.height)

    return {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((lines - height) / 2),
        col = math.floor((columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Pi ",
        title_pos = "center",
    }
end

local function refresh_markdown_preview()
    if state.markdown_preview_scheduled or not is_valid_buf(state.buf) then
        return
    end

    state.markdown_preview_scheduled = true
    vim.defer_fn(function()
        state.markdown_preview_scheduled = false
        if not is_valid_buf(state.buf) then
            return
        end

        pcall(vim.treesitter.start, state.buf, "markdown")

        local ok, actions = pcall(require, "markview.actions")
        if ok then
            pcall(actions.render, state.buf, { enable = true, hybrid_mode = false })
        end
    end, 50)
end

local function enable_markdown_preview(buf)
    pcall(vim.treesitter.start, buf, "markdown")

    local ok, actions = pcall(require, "markview.actions")
    if ok then
        pcall(actions.attach, buf, { enable = true, hybrid_mode = false })
    end
end

local function ensure_buf()
    if is_valid_buf(state.buf) then
        return state.buf
    end

    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].bufhidden = "hide"
    vim.bo[state.buf].swapfile = false
    vim.bo[state.buf].filetype = "markdown"
    vim.api.nvim_buf_set_name(state.buf, "Pi Chat")
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {
        "Pi Chat",
        "",
        "Keys: <CR> send prompt, q close window",
        "",
    })
    enable_markdown_preview(state.buf)

    if M.config.mappings.close then
        vim.keymap.set("n", M.config.mappings.close, M.close, { buffer = state.buf, desc = "Close Pi chat" })
    end
    if M.config.mappings.prompt then
        vim.keymap.set("n", M.config.mappings.prompt, M.prompt, { buffer = state.buf, desc = "Send prompt to Pi" })
    end

    return state.buf
end

local function with_modifiable(fn)
    local buf = ensure_buf()
    local was_modifiable = vim.bo[buf].modifiable
    vim.bo[buf].modifiable = true
    fn(buf)
    vim.bo[buf].modifiable = was_modifiable
end

local function scroll_to_bottom()
    if is_valid_win(state.win) and is_valid_buf(state.buf) then
        vim.api.nvim_win_set_cursor(state.win, { vim.api.nvim_buf_line_count(state.buf), 0 })
    end
end

local namespace = vim.api.nvim_create_namespace("pi.nvim.chat")

local function get_hl_fg(group, fallback)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and hl and hl.fg then
        return hl.fg
    end
    return fallback
end

local function define_highlights()
    vim.api.nvim_set_hl(0, "PiChatUser", {
        fg = get_hl_fg("Identifier", "#89b4fa"),
        bg = "#1e2a3a",
        default = true,
    })
    vim.api.nvim_set_hl(0, "PiChatAssistant", {
        fg = get_hl_fg("String", "#a6e3a1"),
        bg = "#1f2d24",
        default = true,
    })
    vim.api.nvim_set_hl(0, "PiChatThinking", {
        fg = get_hl_fg("Comment", "#7f849c"),
        bg = "#24262f",
        italic = true,
        default = true,
    })
    vim.api.nvim_set_hl(0, "PiChatTool", {
        fg = get_hl_fg("Function", "#f9e2af"),
        bg = "#332b1f",
        default = true,
    })
    vim.api.nvim_set_hl(0, "PiChatMeta", {
        fg = get_hl_fg("Comment", "#7f849c"),
        bg = "#252535",
        default = true,
    })
    vim.api.nvim_set_hl(0, "PiChatError", {
        fg = get_hl_fg("ErrorMsg", "#f38ba8"),
        bg = "#3a1f2a",
        default = true,
    })
end

local function is_fenced_code_line(buf, target_line)
    local in_fence = false
    local fence_marker = nil
    local lines = vim.api.nvim_buf_get_lines(buf, 0, target_line + 1, false)

    for idx, line in ipairs(lines) do
        local marker = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
        if marker then
            if not in_fence then
                in_fence = true
                fence_marker = marker:sub(1, 1)
            elseif marker:sub(1, 1) == fence_marker then
                if idx == target_line + 1 then
                    return true
                end
                in_fence = false
                fence_marker = nil
            end

            if idx == target_line + 1 then
                return true
            end
        elseif idx == target_line + 1 then
            return in_fence
        end
    end

    return false
end

local function set_line_highlight(buf, start_line, end_line, hl_group)
    vim.api.nvim_buf_clear_namespace(buf, namespace, start_line, end_line + 1)

    if not hl_group then
        return
    end

    for line = start_line, end_line do
        -- Let markdown/markview own fenced code blocks; a full-line chat
        -- background makes rendered code blocks look like plain text.
        if not is_fenced_code_line(buf, line) then
            vim.api.nvim_buf_set_extmark(buf, namespace, line, 0, {
                line_hl_group = hl_group,
                hl_eol = true,
            })
        end
    end
end

local function ensure_blank_lines(count)
    with_modifiable(function(buf)
        local line_count = vim.api.nvim_buf_line_count(buf)
        local from = math.max(0, line_count - count)
        local tail = vim.api.nvim_buf_get_lines(buf, from, line_count, false)
        local blanks = 0

        for i = #tail, 1, -1 do
            if tail[i] == "" then
                blanks = blanks + 1
            else
                break
            end
        end

        local missing = count - blanks
        if missing > 0 then
            local padding = {}
            for _ = 1, missing do
                table.insert(padding, "")
            end
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, padding)
        end
    end)
end

local function block_padding_text()
    return string.rep(" ", M.config.block_padding)
end

local function padded_line(line, hl_group)
    if not hl_group or M.config.block_padding <= 0 then
        return line
    end

    local padding = block_padding_text()
    return padding .. line .. padding
end

local function padded_lines(lines, hl_group)
    if not hl_group or M.config.block_padding <= 0 then
        return lines
    end

    return vim.tbl_map(function(line)
        return padded_line(line, hl_group)
    end, lines)
end

local function append_lines(lines, hl_group)
    local normalized = padded_lines(normalize_lines(lines), hl_group)
    with_modifiable(function(buf)
        local start_line = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, normalized)
        set_line_highlight(buf, start_line, start_line + #normalized - 1, hl_group)
    end)
    refresh_markdown_preview()
    scroll_to_bottom()
end

local function append_text(text, hl_group)
    if text == nil or text == "" then
        return
    end

    with_modifiable(function(buf)
        local line_count = vim.api.nvim_buf_line_count(buf)
        local start_line = line_count - 1
        local last = vim.api.nvim_buf_get_lines(buf, start_line, line_count, false)[1] or ""
        local parts = vim.split(text, "\n", { plain = true })

        if hl_group and M.config.block_padding > 0 then
            local padding = block_padding_text()
            if last:sub(-#padding) == padding then
                last = last:sub(1, #last - #padding)
            end
            vim.api.nvim_buf_set_lines(buf, start_line, line_count, false, { last .. parts[1] .. padding })
        else
            vim.api.nvim_buf_set_lines(buf, start_line, line_count, false, { last .. parts[1] })
        end
        if #parts > 1 then
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, padded_lines(vim.list_slice(parts, 2), hl_group))
        end
        set_line_highlight(buf, start_line, start_line + #parts - 1, hl_group)
    end)
    refresh_markdown_preview()
    scroll_to_bottom()
end

local function ensure_assistant_message_started(section, hl_group)
    if not state.assistant_response_started then
        state.assistant_response_started = true
        state.assistant_section = section
        ensure_blank_lines(M.config.block_margin)
        append_lines({ "" }, hl_group)
        return
    end

    if state.assistant_section ~= section then
        state.assistant_section = section
        ensure_blank_lines(M.config.block_margin)
        append_lines({ "" }, hl_group)
    end
end

local function format_tool_args(tool_name, args)
    if type(args) ~= "table" then
        return {}
    end

    if tool_name == "bash" and args.command then
        return { "", "```bash", tostring(args.command), "```", "" }
    end

    local summary = nil
    if args.path then
        summary = "path: " .. tostring(args.path)
    elseif args.command then
        summary = "command: " .. tostring(args.command)
    end

    local lines = {}
    if summary then
        table.insert(lines, summary)
    end
    table.insert(lines, "")
    table.insert(lines, "```lua")
    vim.list_extend(lines, vim.split(vim.inspect(args), "\n", { plain = true }))
    table.insert(lines, "```")
    table.insert(lines, "")
    return lines
end

local function append_tool_start(tool_name, args)
    ensure_blank_lines(M.config.block_margin)
    local lines = { string.format("running tool: %s", tool_name or "unknown") }
    vim.list_extend(lines, format_tool_args(tool_name, args))
    append_lines(lines, "PiChatTool")
end

local function append_event(record)
    if record.type == "message_update" then
        local ev = record.assistantMessageEvent
        if ev and ev.type == "text_delta" then
            ensure_assistant_message_started("text", "PiChatAssistant")
            append_text(ev.delta, "PiChatAssistant")
        elseif ev and ev.type == "thinking_start" then
            ensure_assistant_message_started("thinking", "PiChatThinking")
        elseif ev and ev.type == "thinking_delta" then
            ensure_assistant_message_started("thinking", "PiChatThinking")
            state.assistant_thinking_had_delta = true
            append_text(ev.delta, "PiChatThinking")
        elseif ev and ev.type == "thinking_end" and ev.content and not state.assistant_thinking_had_delta then
            ensure_assistant_message_started("thinking", "PiChatThinking")
            append_text(ev.content, "PiChatThinking")
        end
    elseif record.type == "tool_execution_start" then
        append_tool_start(record.toolName, record.args)
    elseif record.type == "agent_settled" then
        ensure_blank_lines(M.config.block_margin + 1)
        refresh_markdown_preview()
        scroll_to_bottom()
        state.assistant_response_started = false
        state.assistant_thinking_had_delta = false
        state.assistant_section = nil
    elseif record.type == "response" and record.success == false then
        ensure_blank_lines(M.config.block_margin)
        append_lines({ "Pi RPC error: " .. tostring(record.error), "" }, "PiChatError")
    elseif record.type == "extension_ui_request" then
        ensure_blank_lines(M.config.block_margin)
        append_lines({ "Pi extension UI request:", vim.inspect(record), "" }, "PiChatMeta")
    end
end

local function process_stdout_line(line)
    line = line:gsub("\r$", "")
    if line == "" then
        return
    end

    local ok, record = pcall(vim.json.decode, line)
    vim.schedule(function()
        if ok then
            append_event(record)
        else
            ensure_blank_lines(M.config.block_margin)
            append_lines({ "Pi RPC decode error: " .. line, "" }, "PiChatError")
        end
    end)
end

local function handle_stdout(_, data, _)
    if not data or #data == 0 then
        return
    end

    if #data == 1 then
        state.stdout = state.stdout .. data[1]
        return
    end

    state.stdout = state.stdout .. data[1]
    process_stdout_line(state.stdout)

    for i = 2, #data - 1 do
        process_stdout_line(data[i])
    end

    state.stdout = data[#data]
end

local function handle_stderr(_, data, _)
    if not data then
        return
    end

    local lines = vim.tbl_filter(function(line)
        return line ~= ""
    end, data)

    if #lines > 0 then
        vim.schedule(function()
            ensure_blank_lines(M.config.block_margin)
            local error_lines = vim.tbl_map(function(line)
                return "Pi stderr: " .. line
            end, lines)
            table.insert(error_lines, "")
            append_lines(error_lines, "PiChatError")
        end)
    end
end

function M.start()
    if is_running_job(state.job) then
        return
    end

    ensure_buf()
    state.stdout = ""
    state.job = vim.fn.jobstart(build_cmd(), {
        cwd = vim.fn.getcwd(),
        stdin = "pipe",
        stdout_buffered = false,
        stderr_buffered = false,
        on_stdout = handle_stdout,
        on_stderr = handle_stderr,
        on_exit = function(_, code, _)
            vim.schedule(function()
                ensure_blank_lines(M.config.block_margin)
                append_lines({ "Pi exited with code " .. tostring(code), "" }, "PiChatMeta")
            end)
            state.job = nil
            state.has_started_session = true
        end,
    })

    if state.job <= 0 then
        ensure_blank_lines(M.config.block_margin)
        append_lines({ "Failed to start Pi RPC process. Is `pi` on PATH?", "" }, "PiChatError")
        state.job = nil
        return
    end

    state.has_started_session = true
    ensure_blank_lines(M.config.block_margin)
    append_lines({ "Started Pi RPC session", "" }, "PiChatMeta")
end

function M.send(message)
    M.start()
    if not is_running_job(state.job) then
        vim.notify("Pi is not running", vim.log.levels.ERROR)
        return
    end

    state.next_id = state.next_id + 1
    local command = {
        id = "nvim-" .. state.next_id,
        type = "prompt",
        message = message,
        streamingBehavior = "followUp",
    }

    state.assistant_response_started = false
    state.assistant_thinking_had_delta = false
    state.assistant_section = nil
    vim.fn.chansend(state.job, vim.json.encode(command) .. "\n")
    ensure_blank_lines(M.config.block_margin)
    append_lines({ message, "" }, "PiChatUser")
end

function M.prompt()
    vim.ui.input({ prompt = "Pi prompt: " }, function(input)
        if input and input ~= "" then
            M.send(input)
        end
    end)
end

function M.open()
    local buf = ensure_buf()

    if is_valid_win(state.win) then
        vim.api.nvim_set_current_win(state.win)
        vim.api.nvim_win_set_config(state.win, window_opts())
    else
        state.win = vim.api.nvim_open_win(buf, true, window_opts())
    end

    vim.wo[state.win].wrap = true
    vim.wo[state.win].conceallevel = 2
    M.start()
    scroll_to_bottom()
end

function M.close()
    if is_valid_win(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
end

function M.toggle()
    if is_valid_win(state.win) then
        M.close()
    else
        M.open()
    end
end

local function get_visual_selection()
    local source_buf = vim.api.nvim_get_current_buf()
    local visual_mode = vim.fn.visualmode()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_row = start_pos[2] - 1
    local start_col = start_pos[3] - 1
    local end_row = end_pos[2] - 1
    local end_col = end_pos[3]
    local line_count = vim.api.nvim_buf_line_count(source_buf)

    start_row = math.max(0, math.min(start_row, line_count - 1))
    end_row = math.max(0, math.min(end_row, line_count - 1))

    if start_row > end_row then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
    elseif start_row == end_row and start_col > end_col then
        start_col, end_col = end_col, start_col
    end

    local lines
    if visual_mode == "V" or visual_mode == "\022" then
        lines = vim.api.nvim_buf_get_lines(source_buf, start_row, end_row + 1, false)
    else
        local start_line = vim.api.nvim_buf_get_lines(source_buf, start_row, start_row + 1, false)[1] or ""
        local end_line = vim.api.nvim_buf_get_lines(source_buf, end_row, end_row + 1, false)[1] or ""

        start_col = math.max(0, math.min(start_col, #start_line))
        end_col = math.max(0, math.min(end_col, #end_line))

        if start_row == end_row and start_col > end_col then
            start_col, end_col = end_col, start_col
        end

        lines = vim.api.nvim_buf_get_text(source_buf, start_row, start_col, end_row, end_col, {})
    end

    return {
        text = table.concat(lines, "\n"),
        path = vim.api.nvim_buf_get_name(source_buf),
        filetype = vim.bo[source_buf].filetype,
        start_line = start_row + 1,
        end_line = end_row + 1,
    }
end

function M.ask_selection()
    local selection = get_visual_selection()
    if selection.text == "" then
        vim.notify("No visual selection found", vim.log.levels.WARN)
        return
    end

    vim.ui.input({ prompt = "Ask Pi about selection: " }, function(question)
        if question == nil then
            return
        end

        local path = selection.path ~= "" and vim.fn.fnamemodify(selection.path, ":.") or "[No file]"
        local filetype = selection.filetype ~= "" and selection.filetype or "text"
        local prompt = table.concat({
            question ~= "" and question or "Please review this selected code.",
            "",
            string.format("Selected code from `%s` lines %d-%d:", path, selection.start_line, selection.end_line),
            "",
            "```" .. filetype,
            selection.text,
            "```",
        }, "\n")

        M.open()
        M.send(prompt)
    end)
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
    M.config.block_margin = math.max(0, tonumber(M.config.block_margin) or 0)
    M.config.block_padding = math.max(0, tonumber(M.config.block_padding) or 0)
    define_highlights()
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("pi_nvim_cleanup", { clear = true }),
        callback = cleanup_session_dir,
    })
    vim.api.nvim_create_user_command("PiChat", M.open, { desc = "Open Pi chat" })
    vim.api.nvim_create_user_command("PiPrompt", M.prompt, { desc = "Send a prompt to Pi" })

    if M.config.mappings.toggle then
        vim.keymap.set("n", M.config.mappings.toggle, M.toggle, { desc = "[P]i [C]hat" })
    end
    if M.config.mappings.ask_selection then
        vim.keymap.set("v", M.config.mappings.ask_selection, function()
            local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
            vim.api.nvim_feedkeys(esc, "x", false)
            vim.schedule(M.ask_selection)
        end, { desc = "[P]i [Q]uestion about selection" })
    end
end

return M
