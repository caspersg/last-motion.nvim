--- @class Motion an individual motion, either set func or keys
--- @field name string: the exact keys, or a description of the motion
--- @field forward_func? function: to repeat motion
--- @field backward_func? function: to repeat motion in reverse
--- @field forward_keys? string: keys to repeat motion
--- @field backward_keys? string: keys to repeat motion in reverse
--- @field searching? boolean: if the motion is a search type motion, should be false
local Motion = {}
Motion.__index = Motion

local exec = require("last-motion.exec")

--- create a new motion
function Motion.new(opts)
  local new = setmetatable({}, Motion)

  new.name = opts.name
  new.searching = false
  new.forward_func = opts.forward_func
  new.backward_func = opts.backward_func
  new.forward_keys = opts.forward_keys
  new.backward_keys = opts.backward_keys

  return new
end

function Motion:display()
  return self.name
end

function Motion:repeat_motion(direction)
  -- count specific to the repeat, so multiplies with the original count
  local count = vim.v.count
  for _ = 1, math.max(count, 1) do
    local keys = self[direction .. "_keys"]
    if keys then
      exec.exec_keys(keys)
    else
      self[direction .. "_func"]()
    end
  end
end

--- repeat the motion
function Motion:forward()
  self:repeat_motion("forward")
end

--- repeat the motion in reverse
function Motion:backward()
  self:repeat_motion("backward")
end

return Motion
