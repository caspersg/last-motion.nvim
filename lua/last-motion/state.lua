local M = {
    --- State which stores the last motion, to be repeated
    last = nil,
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
    M.last = Last.new(opts)
    return M.last
end

return M
