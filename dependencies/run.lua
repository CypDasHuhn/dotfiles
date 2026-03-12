#!/usr/bin/env lua
-- Run dependency resolution from command line
-- Usage: lua run.lua [base_path] [max_cycles]

package.path = package.path .. ";../?.lua;../?/init.lua"

local deps = require("dependencies")

local base_path = arg[1] or ".."
local max_cycles = tonumber(arg[2]) or 10

print("Resolving dependencies from: " .. base_path)
print("Max cycles: " .. max_cycles)

deps.run(base_path, max_cycles)
