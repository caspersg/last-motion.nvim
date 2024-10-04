-- try to log every motion, so we can remember and then repeat them
-- adds count to the repeats, and maintains any existing counts
-- conditionally can deal with operator pending keys too

local utils = require("last-motion.utils")
local state = require("last-motion.state")
local Definition = require("last-motion.definition")
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
--- @param is_pending boolean: whether this motion is in operator pending mode
--- @return table: next and prev functions which can be used in keymaps
M.key_motion = function(next_key, prev_key, is_pending)
    return {
        next = utils.remember_basic_key(next_key, prev_key, is_pending),
        prev = utils.remember_basic_key(prev_key, next_key, is_pending),
    }
end

--- get next/prev for motions which trigger CmdlineLeave event
--- @param command string: the command to register
--- @param next string: the next keymap to use
--- @param prev string: the previous keymap to use
M.cmd_motion = function(command, next, prev)
    local mem_next = utils.remember_basic_key(next, prev, false)
    local mem_prev = utils.remember_basic_key(prev, next, false)
    vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        callback = function()
            if not vim.v.event.abort and vim.fn.expand("<afile>") == command then
                -- call the closure immediately
                mem_next()
            end
        end,
    })
    return {
        next = mem_next,
        prev = mem_prev,
    }
end

-- repeat the last motion, with count
M.forward = function()
    if state.last() then
        -- count specific to the repeat, so multiplies with the original count
        local count = vim.v.count
        for _ = 1, math.max(count, 1) do
            utils.exec_action(state.last().forward)
        end
    end
end

-- repeat the last motion in reverse, with count
M.backward = function()
    if state.last() then
        local count = vim.v.count
        for _ = 1, math.max(count, 1) do
            utils.exec_action(state.last().backward)
        end
    end
end

-- repeat motion at offset with count, 0 is more recent, 9 is oldest
-- @param offset number: the offset into the history
M.nth = function(offset)
    local motion = state.get(offset)
    if motion then
        local count = vim.v.count
        for _ = 1, math.max(count, 1) do
            utils.exec_action(motion.forward)
        end
    end
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

--- setup the plugin
--- @param opts table: configuration options
M.setup = function(opts)
    M.config = vim.tbl_deep_extend("keep", opts or {}, default_config)

    state.max_motions = M.config.max_motions

    local noremap = { noremap = true, silent = true }
    for _, def in ipairs(M.config.key_motions) do
        local mem = M.key_motion(def.next, def.prev, false)

        vim.keymap.set({ "n", "v" }, def.next, mem.next, noremap)
        vim.keymap.set({ "n", "v" }, def.prev, mem.prev, noremap)
    end

    for _, def in ipairs(M.config.pending_key_motions) do
        local mem = M.key_motion(def.next, def.prev, true)

        vim.keymap.set({ "n", "v" }, def.next, mem.next, noremap)
        vim.keymap.set({ "n", "v" }, def.prev, mem.prev, noremap)
    end

    for _, def in ipairs(M.config.cmd_motions) do
        local mem = M.cmd_motion(def.command, def.next, def.prev)

        vim.keymap.set({ "n", "v" }, def.next, mem.next, noremap)
        vim.keymap.set({ "n", "v" }, def.prev, mem.prev, noremap)
    end

    for _, def in ipairs(M.config.func_motions) do
        local mem = M.func_motion(def.next, def.prev, def.next_func, def.prev_func)

        local desc = { desc = def.desc, noremap = true, silent = true }
        vim.keymap.set({ "n", "v" }, def.next, mem.next, desc)
        vim.keymap.set({ "n", "v" }, def.prev, mem.prev, desc)
    end

    -- extra keymaps for [ ] consistency
    vim.keymap.set({ "n", "v" }, "]l", "zj", { desc = "fo[l]d", remap = true })
    vim.keymap.set({ "n", "v" }, "[l}", "zk", { desc = "fo[l]d", remap = true })
    vim.keymap.set({ "n", "v" }, "]w", "<C-w>w", { desc = "[w]indow", remap = true })
    vim.keymap.set({ "n", "v" }, "[w}", "<C-w>w", { desc = "[w]indow", remap = true })

    vim.api.nvim_create_user_command("LastMotionsNotify", function()
        vim.notify(M.get_last_motions(), vim.log.levels.INFO, { title = "Last Motions" })
    end, {})
end

return M
