local paths = {
    { "${appdataLocal}/Zellij" },
    { "C:/Program Files/LLVM/bin" },
    { "${programFiles}/Nextcloud" },
}
paths.only = { os = "windows" }
return paths
