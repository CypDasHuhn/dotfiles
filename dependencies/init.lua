-- Dependency system entry point
-- Auto-imports all dependencies.lua files and resolves them

local resolver = require("dependencies.resolver")
local helpers = require("dependencies.helpers")

local M = {}

-- Export helpers for use in dependencies.lua files
M.vanilla = helpers.vanilla
M.chocolate = helpers.chocolate

-- Package manager commands
M.pacman = helpers.pacman
M.yay = helpers.yay
M.winget = helpers.winget
M.apt = helpers.apt

-- Tool helpers (with conditions)
M.npm_pkg = helpers.npm_pkg
M.pipx_pkg = helpers.pipx_pkg
M.cargo_pkg = helpers.cargo_pkg
M.go_pkg = helpers.go_pkg

-- Condition helpers
M.which = helpers.which
M.which_any = helpers.which_any
M.file_exists = helpers.file_exists
M.dir_exists = helpers.dir_exists

-- Collect all dependencies from a directory
function M.collect(base_path)
    local all_deps = {}

    -- Find all dependencies.lua files
    local handle = io.popen('find "' .. base_path .. '" -name "dependencies.lua" 2>/dev/null')
    if not handle then return all_deps end

    for file in handle:lines() do
        print("[LOAD] " .. file)
        -- Provide helpers in the environment
        local env = setmetatable({
            vanilla = helpers.vanilla,
            chocolate = helpers.chocolate,
            -- Package manager commands
            pacman = helpers.pacman,
            yay = helpers.yay,
            winget = helpers.winget,
            apt = helpers.apt,
            -- Tool helpers
            npm_pkg = helpers.npm_pkg,
            pipx_pkg = helpers.pipx_pkg,
            cargo_pkg = helpers.cargo_pkg,
            go_pkg = helpers.go_pkg,
            -- Condition helpers
            which = helpers.which,
            which_any = helpers.which_any,
            file_exists = helpers.file_exists,
            dir_exists = helpers.dir_exists,
        }, { __index = _G })

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
