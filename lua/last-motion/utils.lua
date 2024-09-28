local M = {}

local state = require("last-motion.state")

--- debug helper to show what the last motion was
M.notify_last_motion = function()
    vim.notify("last motion" .. vim.inspect(state.last))
end

--- execute an action
--- @param count number: the count for the motion, 0 if there is no count
--- @param action string|function: the exact keys for the motion or function to execute
--- @param pending_chars? string: the pending chars for the motion, if it supports operator pending
M.exec = function(count, action, pending_chars)
    if type(action) == "string" then
        -- Handle motion command
        local countstr = count > 0 and count or ""
        local cmd = countstr .. action .. (pending_chars or "")
        -- vim.cmd can't handle control and other special keys
        -- vim.cmd("normal! "..cmd)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, true, true), "n", false)
    -- vim.notify("cmd " .. cmd)
    elseif type(action) == "function" then
        -- add count to any repeated motion
        for _ = 1, math.max(count, 1) do
            action()
        end
    else
        error("Invalid action type: " .. type(action))
    end
end

--- remember this motion so it can be repeated
--- @param def table: the motion definition
--- @param reverse boolean: if true, the motion is reversed
--- @return function: the closure to remember the motion
M.remember = function(def, reverse)
    return function()
        local count = vim.v.count
        local charstr = nil
        if def.pending then
            -- this motion has operator pending mode, so get those chars
            charstr = vim.fn.nr2char(vim.fn.getchar())
        end
        state.last = {
            count = count,
            charstr = charstr,
            desc = def.desc, -- just for debugging
            command = def.command, -- just for debugging
            forward = def.next,
            backward = def.prev,
        }
        if reverse then
            -- maintain the current direction, so if moving backwards, next continues backwards
            state.last.forward = def.prev
            state.last.backward = def.next
        end

        if not def.command then
            -- commands are detected with hooks, so they've already been called
            M.exec(state.last.count, state.last.forward, state.last.charstr)
        end
    end
end

return M
