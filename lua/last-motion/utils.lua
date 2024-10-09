local M = {}

local state = require("last-motion.state")

--- debug helper to show what the last motion was
M.notify_last_motion = function()
  vim.notify("last motion" .. vim.inspect(state.get(0)))
end

--- add count to a motion to make it repeatable with count
--- @param count number: the count for the motion, 0 if there is no count
--- @param action string|function: the exact keys for the motion or function to execute
--- @return function: the closure to execute the action
M.with_count = function(action, count)
  return function()
    -- repeat at least once
    for _ = 1, math.max(count, 1) do
      action()
    end
  end
end

--- remember this basic key so it can be repeated
--- @param forward string: the forward keys
--- @param backward string: the backwards keys
--- @param read_char boolean: whether this motion waits for another character
--- @param is_cmd boolean: cmd doesn't need to execute the keys
--- @param has_count boolean: if motion already supports counts
--- @return function: the closure to be used in a keymap
M.remember_key = function(forward, backward, read_char, is_cmd, has_count)
  return function()
    -- this is inline with all motions, so do as little as possible here

    -- get surrounding context for the motion
    local count = vim.v.count
    local countstr = not has_count and count > 0 and count or ""
    local char = ""
    if read_char then
      -- this motion requires another character
      char = vim.fn.nr2char(vim.fn.getchar())
    end
    local count_forward = countstr .. forward .. char

    local motion = state.push_motion({
      name = count_forward,
      forward_keys = count_forward,
      backward_keys = countstr .. backward .. char,
    })

    if not is_cmd then
      motion:forward()
    end
  end
end

--- remember this motion so it can be repeated
--- @param key string: the key that triggered the motion
--- @param forward function: the function to execute the motion
--- @param backward function: the function to execute the motion in reverse
--- @return function: the closure to be used in a keymap
M.remember_func = function(key, forward, backward)
  return function()
    -- this is inline with all motions, so do as little as possible here

    -- get surrounding context for the motion
    local count = vim.v.count
    local countstr = count > 0 and count or ""
    local count_forward = M.with_count(forward, count)

    state.push_motion({
      name = countstr .. key,
      forward_func = count_forward,
      backward_func = M.with_count(backward, count),
    })

    count_forward()
  end
end

return M
