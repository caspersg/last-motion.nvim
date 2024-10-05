local M = {
  --- State which stores the history of last motion 1-indexed
  --- @type Motion[] history of motions
  history = {},

  --- The maximum number of motions to remember
  max_motions = 1,
}

local Motion = require("last-motion.motion")

--- add a new last motion
--- @param motion Motion: the motion to remember
--- @return Motion: the motion that was added
M.push_motion = function(motion)
  local new_motion = Motion.new(motion)

  table.insert(M.history, 1, new_motion)

  if #M.history > M.max_motions then
    table.remove(M.history)
  end
  return new_motion
end

--- get the nth motion, 0 is the most recent, 9 is the oldest
--- @param offset number: the offset from the most recent motion 0-indexed
--- @return Motion: the motion at the offset
M.get = function(offset)
  local index = offset + 1
  return M.history[index]
end

return M
