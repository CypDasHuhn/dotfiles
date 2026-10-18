local paths = {
	{ "/home/linuxbrew/.linuxbrew/bin" },
	{ "${me}/.local/bin" },
	{ "${me}/.zvm/bin" },
	{ "${me}/.zvm/self" },
	{ "${me}/.zvm/master" },
	{ "${me}/repos/fcp/build/install/fcp/bin" },
	{ "${me}/repos/code-intent/analysis-engine/build/install/cint/bin" },
	{ "${me}/repos/code-intent/analysis-engine/build/install/cint-server/bin" },
	{ "${me}/.cargo/bin" },
}
paths.only = { os = "unix" }
return paths
