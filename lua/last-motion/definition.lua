--- @class Definition defines a pair of motions
--- @field desc? string: description used for keymap desc field
--- @field next string: the keymap for forward, also the action key if not overridden
--- @field prev string: the keymap for backward, also the action key if not overridden
--- @field next_func? function: the function to call for forward action, overrides next as the action
--- @field prev_func? function: the function to call for backward action, overrides prev as the action
--- @field next_key? string: the key for forward action, overrides next as the action
--- @field prev_key? string: the key for backward action, overrides prev as the action
--- @field pending? boolean: if the motion is operator pending, key will wait for keys after the motion
--- @field command? string: the key for the command, if it is a command like /
local Definition = {}
Definition.__index = Definition

local function err(msg, def)
    error(msg .. " " .. vim.inspect(def))
end

local function validate(def)
    if not def.next or def.next == "" then
        err("next is always required", def)
    end
    if not def.prev or def.prev == "" then
        err("prev is always require", def)
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
    if def.next_key ~= nil and type(def.next_key) ~= "string" then
        err("next_key is optional but must be a string", def)
    end
    if def.prev_key ~= nil and type(def.prev_key) ~= "string" then
        err("prev_key is optional but must be a string", def)
    end
    if def.next_func ~= nil and type(def.next_func) ~= "function" then
        err("next_func is optional but must be a function", def)
    end
    if def.prev_func ~= nil and type(def.prev_func) ~= "function" then
        err("prev_func is optional but must be a function", def)
    end
    if def.next_func and def.next_key then
        err("cannot have both next_func and next_key", def)
    end
    if def.prev_func and def.prev_key then
        err("cannot have both prev_func and prev_key", def)
    end
end

--- create a new definition
function Definition.new(opts)
    validate(opts)

    local new = setmetatable({}, Definition)
    new.desc = opts.desc
    new.next = opts.next
    new.prev = opts.prev
    new.next_func = opts.next_func
    new.prev_func = opts.prev_func
    new.next_key = opts.next_key
    new.prev_key = opts.prev_key
    new.pending = opts.pending
    new.command = opts.command

    return new
end

return Definition
