local M = {
    --- State which stores the last motions, to be repeated
    history = {},
    max_motions = nil,
}

local Motion = require("last-motion.motion")

--- update the last motion
--- @param motion Motion: the motion to remember
M.update_last = function(motion)
    local new_motion = Motion.new(motion)

    table.insert(M.history, 1, new_motion)

    if #M.history > M.max_motions then
        table.remove(M.history)
    end
    return new_motion
end

--- get the most recent motion
--- @return Motion: the most recent motion
M.last = function()
    return M.get(0)
end

--- get the nth motion, 0 is the most recent, 9 is the oldest
--- @param offset number: the offset from the most recent motion
--- @return Motion: the motion at the offset
M.get = function(offset)
    local index = offset + 1
    return M.history[index]
end

return M
