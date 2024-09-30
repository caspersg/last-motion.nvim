-- try to log every motion, so we can remember and then repeat them
-- adds count to the repeats, and maintains any existing counts
-- conditionally can deal with operator pending keys too

local utils = require("last-motion.utils")
local state = require("last-motion.state")
local default_config = require("last-motion.config")

local M = {}

local group = vim.api.nvim_create_augroup("last-motion", {})

local function err(msg, def)
    error(msg .. " " .. vim.inspect(def))
end

local function validate(def)
    if not def.next or def.next == "" then
        err("next is always required", def)
    end
    if def.prev ~= nil and def.prev == "" then
        err("prev is optional but cannot be empty", def)
    end
    if def.desc ~= nil and def.desc == "" then
        err("desc is optional but cannot be empty", def)
    end
    if def.command ~= nil and def.desc == "" then
        err("command is optional but cannot be empty", def)
    end
    if def.pending ~= nil and type(def.pending) ~= "boolean" then
        err("pending is optional but must be a boolean", def)
    end
    if def.next_keys ~= nil and type(def.next_keys) ~= "table" then
        err("next_keys is optional but must be a table", def)
    end
    if def.prev_keys ~= nil and type(def.prev_keys) ~= "table" then
        err("prev_keys is optional but must be a table", def)
    end
end

local function register_command(def)
    vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        callback = function()
            if not vim.v.event.abort and vim.fn.expand("<afile>") == def.command then
                -- call the closure immediately
                utils.remember(def.command, def, false)()
            end
        end,
    })
end

--- register a motion
--- @param def table: the motion definition
M.register = function(def)
    validate(def)

    if def.command then
        register_command(def)
        -- commands are a hook, so we don't need a new keymap
        return
    end

    -- always add keymaps for existing keys
    def.next_keys = def.next_keys or ((type(def.next) == "string" and { def.next }) or {})
    def.prev_keys = def.prev_keys or ((type(def.prev) == "string" and { def.prev }) or {})

    -- add new keymaps
    local mapopts = { desc = def.desc, noremap = true, silent = true }
    for _, key in ipairs(def.next_keys) do
        vim.keymap.set({ "n", "v" }, key, utils.remember(key, def, false), mapopts)
    end
    if def.prev_keys then
        for _, key in ipairs(def.prev_keys) do
            vim.keymap.set({ "n", "v" }, key, utils.remember(key, def, true), mapopts)
        end
    end
    -- vim.notify("last-motion registered " .. vim.inspect(def))
end

-- repeat the last motion
M.forward = function()
    if state.last() then
        local count = vim.v.count
        for _ = 1, math.max(count, 1) do
            state.last().forward()
        end
    end
end

-- repeat the last motion in reverse
M.backward = function()
    if state.last() then
        local count = vim.v.count
        for _ = 1, math.max(count, 1) do
            state.last().backward()
        end
    end
end

-- repeat motion at offset, 0 is more recent, 9 is oldest
-- @param offset number: the offset into the history
M.nth = function(offset)
    local motion = state.get(offset)
    if motion then
        local count = vim.v.count
        for _ = 1, math.max(count, 1) do
            motion.forward()
        end
    end
end

--- get the latest 10 motions
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
    M.config = vim.tbl_deep_extend("force", default_config, opts or {})

    state.max_motions = M.config.max_motions

    for _, definition in ipairs(M.config.definitions) do
        M.register(definition)
    end

    vim.api.nvim_create_user_command("LastMotionsNotify", function()
        vim.notify(M.get_last_motions(), vim.log.levels.INFO, { title = "Last Motions" })
    end, {})

    -- Add these yourself
    -- vim.keymap.set({ "n", "v" }, "n", M.forward, { desc = "repeat last motion", noremap = true, silent = true })
    -- vim.keymap.set({ "n", "v" }, "N", M.backward, { desc = "reverse last motion", noremap = true, silent = true })
    --
    -- for i = 0, 9 do
    --     vim.keymap.set({ "n", "v" }, "," .. i, function()
    --         M.nth(i)
    --     end, { desc = "repeat motion" .. i, noremap = true, silent = true })
    -- end
    --
    -- vim.keymap.set("n", ",,", function()
    --     vim.notify(M.print_last_motions, vim.log.levels.INFO, { title = "Last Motions" })
    -- end, { desc = "last motions", noremap = true, silent = true })
end

return M
