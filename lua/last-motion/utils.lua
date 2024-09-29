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
    if type(action) == "string" then -- it's a raw set of keys to execute
        local countstr = count > 0 and count or ""
        local cmd = countstr .. action .. (pending_chars or "")
        vim.cmd("normal! " .. vim.api.nvim_replace_termcodes(cmd, true, true, true))
        -- vim.notify("cmd " .. cmd) -- debugging
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

        -- maintain the current direction, so if moving backwards, next continues backwards
        local forward = reverse and def.prev or def.next
        local backward = reverse and def.next or def.prev

        local last = state.update_last({
            count = count,
            charstr = charstr,
            forward = forward,
            backward = backward,

            -- just for debugging
            desc = def.desc,
            command = def.command,
            pending = def.pending,
        })

        if last and not def.command then
            -- commands are detected with hooks, so they've already been called
            M.exec(last.count, last.forward, last.charstr)
        end
    end
end

return M
