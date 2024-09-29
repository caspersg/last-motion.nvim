--- @class Motion an individual motion
--- @field count number: the count before the motion
--- @field pending_chars string: the character string following the motion
--- @field forward function: to repeat motion
--- @field backward function: to repeat motion in reverse
--- @field desc string: the description of the motion
--- @field command string: the command of the motion
--- @field pending boolean: if the motion is pending
--- @field searching boolean: if the motion is a search type motion
local Motion = {}
Motion.__index = Motion

--- create a new motion
function Motion.new(opts)
    local new = setmetatable({}, Motion)

    new.count = opts.count
    new.pending_chars = opts.pending_chars
    new.forward = opts.forward
    new.backward = opts.backward

    -- debugging
    new.desc = opts.desc
    new.command = opts.command
    new.pending = opts.pending

    return new
end

return Motion
