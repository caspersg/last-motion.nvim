local M = {}

local state = require("last-motion.state")

--- debug helper to show what the last motion was
M.notify_last_motion = function()
    vim.notify("last motion" .. vim.inspect(state.last()))
end

--- prepare an action to be executed
--- @param count number: the count for the motion, 0 if there is no count
--- @param action string|function: the exact keys for the motion or function to execute
--- @param pending_chars? string: the pending chars for the motion, if it supports operator pending
--- @return function: the closure to execute the action
M.as_exec = function(count, action, pending_chars)
    if type(action) == "string" then -- it's a raw set of keys to execute
        local countstr = count > 0 and count or ""
        local cmd = countstr .. action .. (pending_chars or "")
        -- vim.notify("cmd " .. cmd) -- debugging
        if string.find(action, "<C%-i>") then
            return function()
                -- C-i is a special case, it's the same as tab, so it requires feedkeys
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, true, true), "n", true)
            end
        else
            return function()
                vim.cmd("normal! " .. vim.api.nvim_replace_termcodes(cmd, true, true, true))
            end
        end
    elseif type(action) == "function" then
        -- add count to any repeated motion
        return function()
            for _ = 1, math.max(count, 1) do
                action()
            end
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
        -- get surrounding context
        local count = vim.v.count
        local pending_chars = nil
        if def.pending then
            -- this motion has operator pending mode, so get those chars
            pending_chars = vim.fn.nr2char(vim.fn.getchar())
        end

        -- maintain the current direction, so if moving backwards, next continues backwards
        local forward = reverse and def.prev or def.next
        local backward = reverse and def.next or def.prev

        local last = state.update_last({
            count = count,
            charstr = pending_chars,
            forward = M.as_exec(count, forward, pending_chars),
            backward = M.as_exec(count, backward, pending_chars),

            -- just for debugging
            desc = def.desc,
            command = def.command,
            pending = def.pending,
        })

        if last and not def.command then
            -- commands are detected with hooks, so they've already been called
            last.forward()
        end
    end
end

return M
