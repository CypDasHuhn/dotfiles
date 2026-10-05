local paths = {
    { "${appdataLocal}/Zellij" },
    { "C:/Program Files/LLVM/bin" },
    { "${programFiles}/Seafile/bin" },
}
paths.only = { os = "windows" }
return paths
