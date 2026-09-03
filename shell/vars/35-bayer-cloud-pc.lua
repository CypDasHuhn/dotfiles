local vars = {
    cvm = { "/cvm-vip-module-vhub" },
    cvmDb = { "/cvm-vip-module-dbtest" },
    cvmLake = { "/cvm-vip-module-vlake" },
}

for _, v in pairs(vars) do
    v.dir_function = true
    v[1] = "${repos}" .. v[1]
end

for _, v in pairs(vars) do
    v.only = { machine = "bayer-cloud-pc" }
end

return vars
