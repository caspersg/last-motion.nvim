local M = {}

local state = require("last-motion.state")
local ts_move = require("nvim-treesitter.textobjects.move")

M.ts_next = function(query)
    return function()
        ts_move.goto_next_start(query)
    end
end

M.ts_prev = function(query)
    return function()
        ts_move.goto_previous_start(query)
    end
end

--- debug helper to show what the last motion was
M.notify_last_motion = function()
    vim.notify("last motion" .. vim.inspect(state.last()))
end

--- prepare an action
--- @param count number: the count for the motion, 0 if there is no count
--- @param action string|function: the exact keys for the motion or function to execute
--- @param pending_chars? string: the pending chars for the motion, if it supports operator pending
--- @return function: the closure to execute the action
M.as_exec = function(action, count, pending_chars)
    -- don't execute any of it now, do it on the repeat
    return function()
        if type(action) == "string" then
            -- it's a raw set of keys to execute
            local countstr = count > 0 and count or ""
            local cmd_str = countstr .. action .. (pending_chars or "")
            local cmd = vim.api.nvim_replace_termcodes(cmd_str, true, true, true)
            if string.find(action, "<C%-i>") then
                -- C-i is a special case, it's the same as tab, so it requires feedkeys
                vim.api.nvim_feedkeys(cmd, "n", true)
            else
                vim.cmd("normal! " .. cmd)
            end
        elseif type(action) == "function" then
            -- add count to any repeated motion
            for _ = 1, math.max(count, 1) do
                action()
            end
        else
            error("Invalid action type: " .. type(action))
        end
    end
end

--- remember this motion so it can be repeated
--- @param key string: the key that triggered the motion
--- @param def table: the motion definition
--- @param reverse boolean: if true, the motion is reversed
--- @return function: the closure to remember the motion
M.remember = function(key, def, reverse)
    -- need to figure out which field is the action
    -- func overrides key, new key overrides default key
    local next = def.next_func or def.next_key or def.next
    local prev = def.prev_func or def.prev_key or def.prev

    -- maintain the current direction, so if moving backwards, next continues backwards
    local forward = reverse and prev or next
    local backward = reverse and next or prev

    return function()
        -- this is inline with all motions, so do as little as possible here

        -- get surrounding context for the motion
        local count = vim.v.count
        local pending_chars = nil
        if def.pending then
            -- this motion has operator pending mode, so get those chars
            pending_chars = vim.fn.nr2char(vim.fn.getchar())
        end

        local current_motion = state.update_last({
            count = count,
            pending_chars = pending_chars,
            forward = M.as_exec(forward, count, pending_chars),
            backward = M.as_exec(backward, count, pending_chars),

            name = key,
            command = def.command,
            pending = def.pending,
            searching = false, -- assume false to begin with
        })

        if not def.command then
            -- commands are detected with hooks, so they've already been called
            current_motion.forward()
        end
    end
end

M.exec_basic_key = function(action)
    -- it's a raw set of keys to execute
    local cmd = vim.api.nvim_replace_termcodes(action, true, true, true)
    if string.find(action, "<C%-i>") then
        -- C-i is a special case, it's the same as tab, so it requires feedkeys
        vim.api.nvim_feedkeys(cmd, "n", true)
    else
        vim.cmd("normal! " .. cmd)
    end
end

M.exec_action = function(action)
    if type(action) == "string" then
        M.exec_basic_key(action)
    elseif type(action) == "function" then
        action()
    else
        error("Invalid action type: " .. type(action) .. " for " .. vim.inspect(action))
    end
end

M.remember_basic_key = function(forward, backward, is_pending)
    return function()
        -- this is inline with all motions, so do as little as possible here

        -- get surrounding context for the motion
        local count = vim.v.count
        local countstr = count > 0 and count or ""
        local pending_chars = ""
        if is_pending then
            -- this motion has operator pending mode, so get those chars
            pending_chars = vim.fn.nr2char(vim.fn.getchar())
        end
        local count_forward = countstr .. forward .. pending_chars

        state.update_last({
            count = count,
            pending_chars = "",
            forward = count_forward,
            backward = countstr .. backward .. pending_chars,

            name = forward,
            command = "",
            pending = false,
            searching = false, -- assume false to begin with
        })

        --
        M.exec_basic_key(count_forward)
    end
end

return M
