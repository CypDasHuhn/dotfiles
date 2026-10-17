local paths = {
	{ "/home/linuxbrew/.linuxbrew/bin" },
	{ "${me}/.local/bin" },
	{ "${me}/.zvm/bin" },
	{ "${me}/.zvm/self" },
	{ "${me}/.zvm/master" },
	{ "${me}/repos/fcp/build/install/fcp/bin" },
	{ "${me}/repos/semantic-code-painter/analysis-engine/build/install/semantic-code-painter/bin" },
	{ "${me}/repos/semantic-code-painter/analysis-engine/build/install/semantic-code-painter-server/bin" },
	{ "${me}/.cargo/bin" },
}
paths.only = { os = "unix" }
return paths
