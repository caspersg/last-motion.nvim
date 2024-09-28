-- try to log every motion, so we can remember and then repeat them
-- adds count to the repeats, and maintains any existing counts
-- conditionally can deal with operator pending keys too

local utils = require("last-motion.utils")
local state = require("last-motion.state")
local default_config = require("last-motion.config")

local M = {}
local config

local group = vim.api.nvim_create_augroup("last-motion", {})

--- register a new motion
--- @param def table
M.register = function(def)
    if def.command then
        vim.api.nvim_create_autocmd("CmdlineLeave", {
            group = group,
            callback = function()
                if not vim.v.event.abort and vim.fn.expand("<afile>") == def.command then
                    -- call the closure immediately
                    utils.remember(def, false)()
                end
            end,
        })
        -- commands are a hook, so we don't need a new keymap
        return
    end

    -- always add keymaps for existing keys
    def.next_keys = def.next_keys or {}
    def.prev_keys = def.prev_keys or {}
    if type(def.next) == "string" then
        table.insert(def.next_keys, def.next)
    end
    if type(def.prev) == "string" then
        table.insert(def.prev_keys, def.prev)
    end

    -- add new keymaps
    local mapopts = { desc = def.desc, noremap = true, silent = true }
    for _, key in ipairs(def.next_keys) do
        vim.keymap.set({ "n", "v" }, key, utils.remember(def, false), mapopts)
    end
    if def.prev_keys then
        for _, key in ipairs(def.prev_keys) do
            vim.keymap.set({ "n", "v" }, key, utils.remember(def, true), mapopts)
        end
    end
    -- print("last-motion registered " .. vim.inspect(def))
end

-- repeat the last motion
M.forward = function()
    if state.last then
        utils.exec(state.last.count, state.last.forward, state.last.charstr)
    end
end

-- repeat the last motion in reverse
M.backward = function()
    if state.last then
        utils.exec(state.last.count, state.last.backward, state.last.charstr)
    end
end

--- setup the plugin
---@param opts? table
M.setup = function(opts)
    -- TODO: allow overriding the defaults
    config = default_config
    for _, definition in ipairs(config.default_definitions) do
        M.register(definition)
    end

    -- TODO: extract these keymaps to config
    vim.keymap.set({ "n", "v" }, "n", M.forward, { desc = "repeat last motion", noremap = true, silent = true })
    vim.keymap.set({ "n", "v" }, "N", M.backward, { desc = "reverse last motion", noremap = true, silent = true })
end

return M
