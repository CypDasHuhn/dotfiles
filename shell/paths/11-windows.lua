local paths = {
    { "${appdataLocal}/Zellij" },
    { "${programFiles}/Microsoft SDKs/Azure/CLI2/wbin" },
    { "C:/Program Files/LLVM/bin" },
    { "${programFiles}/Nextcloud" },
}
paths.only = { os = "windows" }
return paths
