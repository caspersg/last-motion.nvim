--- @class Motion an individual motion, either set func or keys
--- @field name string: the exact keys, or a description of the motion
--- @field forward_func? function: to repeat motion
--- @field backward_func? function: to repeat motion in reverse
--- @field forward_keys? string: keys to repeat motion
--- @field backward_keys? string: keys to repeat motion in reverse
--- @field searching? boolean: if the motion is a search type motion, should be false
local Motion = {}
Motion.__index = Motion

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

--- execute a basic key sequence
--- @param cmd_str string: the exact keys for the motion
local function exec_keys(cmd_str)
  -- it's a raw set of keys to execute
  local cmd = vim.api.nvim_replace_termcodes(cmd_str, true, true, true)
  if string.find(cmd_str, "<C%-i>") then
    -- C-i is a special case, it's the same as tab, so it requires feedkeys
    vim.api.nvim_feedkeys(cmd, "n", true)
  else
    vim.cmd("normal! " .. cmd)
  end
end

function Motion:repeat_motion(direction)
  -- count specific to the repeat, so multiplies with the original count
  local count = vim.v.count
  for _ = 1, math.max(count, 1) do
    local keys = self[direction .. "_keys"]
    if keys then
      exec_keys(keys)
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
