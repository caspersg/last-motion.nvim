local M = {
  --- State which stores the last motion
  --- @type Motion the last motion
  last = nil,
}

local Motion = require("last-motion.motion")

--- add a new last motion
--- @param motion Motion: the motion to remember
--- @return Motion: the motion that was added
M.push_motion = function(motion)
  local new_motion = Motion.new(motion)
  M.last = new_motion
  return new_motion
end

--- get the last motion
--- @return Motion: the last motion
M.get = function()
  return M.last
end

return M
