local M = {}

--- execute a basic key sequence
--- @param cmd_str string: the exact keys for the motion
M.exec_keys = function(cmd_str)
  -- it's a raw set of keys to execute
  local cmd = vim.api.nvim_replace_termcodes(cmd_str, true, true, true)
  -- '!' won't work with other keymaps, but it's required to avoid recursive calls
  -- So we can only use keys with builtin motions
  vim.cmd("normal! " .. cmd)
end

return M
