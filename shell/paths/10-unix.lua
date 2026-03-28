local paths = {
	{ "/home/linuxbrew/.linuxbrew/bin" },
	{ "${me}/.local/bin" },
	{ "${me}/.zvm/bin" },
	{ "${me}/.zvm/self" },
	{ "${me}/.zvm/master" },
	{ "${vdirCli}/zig-out/bin" },
}
paths.only = { os = "unix" }
return paths
