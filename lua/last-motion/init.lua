-- try to log every motion, so we can remember and then repeat them
-- adds count to the repeats, and maintains any existing counts

local utils = require("last-motion.utils")
local state = require("last-motion.state")
local default_config = require("last-motion.config")

local M = {}

local group = vim.api.nvim_create_augroup("last-motion", {})

--- get next/prev for function motions
--- @param next string: name of next function
--- @param prev string: name of prev function
--- @param next_func function: the function to execute when next is called
--- @param prev_func function: the function to execute when prev is called
--- @return table: next and prev functions which can be used in keymaps
M.func_motion = function(next, prev, next_func, prev_func)
  return {
    next = utils.remember_func(next, next_func, prev_func),
    prev = utils.remember_func(prev, prev_func, next_func),
  }
end

--- get next/prev for existing keys
--- @param next_key string: keys for motion
--- @param prev_key string: keys for reverse motion
--- @param read_char boolean: whether this motion waits for another character
--- @param has_count boolean: if motion already supports counts
--- @return table: next and prev functions which can be used in keymaps
M.key_motion = function(next_key, prev_key, read_char, has_count)
  return {
    next = utils.remember_key(next_key, prev_key, read_char, false, has_count),
    prev = utils.remember_key(prev_key, next_key, read_char, false, has_count),
  }
end

--- get next/prev for motions which trigger CmdlineLeave event
--- @param command string: the command to register
--- @param next string: the next keymap to use
--- @param prev string: the previous keymap to use
--- @param has_count boolean: if motion already supports counts
--- @return table: next and prev functions which can be used in keymaps
M.cmd_motion = function(command, next, prev, has_count)
  local mem_next = utils.remember_key(next, prev, false, true, has_count)
  local mem_prev = utils.remember_key(prev, next, false, true, has_count)
  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function()
      if not vim.v.event.abort and vim.fn.expand("<afile>") == command then
        -- call the closure immediately, just to remember it
        mem_next()
      end
    end,
  })
  return {
    next = mem_next,
    prev = mem_prev,
  }
end

--- repeat the last motion, with count
--- @param offset? number: the offset into the history 0-indexed default is 0
M.forward = function(offset)
  if not offset then
    offset = 0
  end
  local motion = state.get(offset)
  if motion then
    motion:forward()
  end
end

--- repeat the last motion in reverse, with count
--- @param offset? number: the offset into the history 0-indexed default is 0
M.backward = function(offset)
  if not offset then
    offset = 0
  end
  local motion = state.get(offset)
  if motion then
    motion:backward()
  end
end

--- get the raw array of motion history
--- @return table: the history of motions 1-indexed
M.history = function()
  return state.history
end

--- get the latest motions
--- @return string: the motions each on a new line
M.get_last_motions = function()
  local lines = {}
  for i, motion in ipairs(state.history) do
    table.insert(lines, string.format("%d:%s", i - 1, motion:display()))
  end

  return table.concat(lines, "\n")
end

local function create_keymaps(def, mem)
  local opts = { desc = def.desc, remap = true, silent = true }

  local modes = { "n", "v" }
  vim.keymap.set(modes, def.next, mem.next, opts)
  vim.keymap.set(modes, def.prev, mem.prev, opts)
  if M.config.add_operator_pending_keymaps and not def.operator_pending then
    -- add operator pending for motions that don't support it, but don't remember them as motions
    vim.keymap.set("o", def.next, def.next_func or def.next, opts)
    vim.keymap.set("o", def.prev, def.prev_func or def.next, opts)
  end
end

M.setup_square_motions = function(motions)
  local sm = require("square-motions")

  for _, to in ipairs(motions) do
    local next_key = sm.config.next_prefix .. to.key
    local prev_key = sm.config.prev_prefix .. to.key
    local mem = nil
    -- square-motions always use funcs
    mem = M.func_motion(next_key, prev_key, to.next, to.prev)

    -- vim.notify("sq '" .. to.desc .. "' '" .. next_key)

    create_keymaps({
      next = next_key,
      prev = prev_key,
      next_func = to.next,
      prev_func = to.prev,
      desc = to.desc,
      operator_pending = false,
    }, mem)
  end
end

--- setup the plugin
--- @param opts table: configuration options
M.setup = function(opts)
  M.config = vim.tbl_deep_extend("keep", opts or {}, default_config)

  state.max_motions = M.config.max_motions

  for _, def in ipairs(M.config.key_motions) do
    local mem = M.key_motion(def.next, def.prev, false, def.count)
    create_keymaps(def, mem)
  end

  for _, def in ipairs(M.config.read_char_motions) do
    local mem = M.key_motion(def.next, def.prev, true, def.count)
    create_keymaps(def, mem)
  end

  for _, def in ipairs(M.config.cmd_motions) do
    local mem = M.cmd_motion(def.command, def.next, def.prev, def.count)
    create_keymaps(def, mem)
  end

  for _, def in ipairs(M.config.func_motions) do
    local mem = M.func_motion(def.next, def.prev, def.next_func, def.prev_func)
    create_keymaps(def, mem)
  end

  local sm = require("square-motions")
  if M.config.textobjects then
    M.setup_square_motions(sm.textobject_motions())
  end

  if M.config.square_motions then
    M.setup_square_motions(sm.config.motions)
  end

  if M.config.default_next_previous_keys then
    -- Add keymaps for at least forward and backward to do anything useful.
    vim.keymap.set({ "n", "v", "o" }, "n", M.forward, { desc = "repeat last motion" })
    vim.keymap.set({ "n", "v", "o" }, "N", M.backward, { desc = "reverse last motion" })
  end

  vim.api.nvim_create_user_command("LastMotionNotify", function()
    vim.notify(M.get_last_motions(), vim.log.levels.INFO, { title = "Last Motions" })
  end, {})

  vim.api.nvim_create_user_command("LastMotionForward", function(cmd_opts)
    M.forward(tonumber(cmd_opts.args))
  end, { nargs = "?", desc = "repeat the specified, or last motion" })

  vim.api.nvim_create_user_command("LastMotionBackward", function(cmd_opts)
    M.backward(tonumber(cmd_opts.args))
  end, { nargs = "?", desc = "repeat the specified, or last motion in reverse" })

  vim.api.nvim_create_user_command("LastMotionRemove", function(cmd_opts)
    local offset = tonumber(cmd_opts.args)
    table.remove(require("last-motion").history(), (offset or 0) + 1)
  end, { nargs = "?", desc = "remove the specified motion from history at offset" })
end

return M
