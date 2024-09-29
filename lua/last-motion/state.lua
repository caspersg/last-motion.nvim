local M = {
    --- State which stores the last motion, to be repeated
    history = {},
}

local Last = {}
Last.__index = Last

function Last.new(opts)
    local new = setmetatable({}, Last)

    new.count = opts.count
    new.charstr = opts.charstr
    new.forward = opts.forward
    new.backward = opts.backward

    -- debugging
    new.desc = opts.desc
    new.command = opts.command
    new.pending = opts.pending

    return new
end

M.update_last = function(opts)
    local new_motion = Last.new(opts)

    table.insert(M.history, 1, new_motion)

    if #M.history > 10 then
        table.remove(M.history)
    end
    return new_motion
end

M.last = function()
    return M.history[1]
end

return M
