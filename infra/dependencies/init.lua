-- Dependency system entry point
-- Auto-imports all dependencies.lua files and resolves them

local resolver = require("dependencies.resolver")
local helpers = require("dependencies.helpers")

local M = {}

-- Re-export all helpers
for k, v in pairs(helpers) do
	M[k] = v
end

-- Collect all dependencies from a directory
function M.collect(base_path)
    local all_deps = {}

    -- Find all dependencies.lua files
    local handle = io.popen('find "' .. base_path .. '" -name "dependencies.lua" 2>/dev/null')
    if not handle then return all_deps end

    for file in handle:lines() do
        print("[LOAD] " .. file)
        -- Provide helpers in the environment (shallow copy so loaded files can't mutate helpers)
        local env = setmetatable({}, { __index = function(_, k) return helpers[k] or _G[k] end })

        -- Lua 5.2+ compatible loading with environment
        local chunk, err = loadfile(file, "t", env)
        if chunk then
            local deps = chunk()
            if type(deps) == "table" then
                for name, entry in pairs(deps) do
                    if all_deps[name] then
                        print("[WARN] Duplicate dependency: " .. name)
                    end
                    all_deps[name] = entry
                end
            end
        else
            print("[ERR] Failed to load " .. file .. ": " .. (err or "unknown"))
        end
    end
    handle:close()

    return all_deps
end

-- Main entry point
function M.run(base_path, max_cycles)
    base_path = base_path or "."
    local deps = M.collect(base_path)
    resolver.resolve(deps, max_cycles)
end

return M
