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

--- add count to a motion to make it repeatable with count
--- @param count number: the count for the motion, 0 if there is no count
--- @param action string|function: the exact keys for the motion or function to execute
--- @return function: the closure to execute the action
M.with_count = function(action, count)
    return function()
        -- repeat at least once
        for _ = 1, math.max(count, 1) do
            action()
        end
    end
end

--- remember this motion so it can be repeated
--- @param key string: the key that triggered the motion
--- @return function: the closure to remember the motion
M.remember = function(key, forward, backward)
    return function()
        -- this is inline with all motions, so do as little as possible here

        -- get surrounding context for the motion
        local count = vim.v.count

        local current_motion = state.update_last({
            count = count,
            pending_chars = "",
            forward = M.with_count(forward, count),
            backward = M.with_count(backward, count),

            name = key,
            command = "",
            pending = false,
            searching = false, -- assume false to begin with
        })

        current_motion.forward()
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
