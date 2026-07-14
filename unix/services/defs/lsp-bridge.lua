return {
	name = "lsp-bridge",
	description = "Codex LSP Bridge",
	command = {
		"codex-lsp-bridge",
		"serve",
		"--config",
		"${HOME}/code/codex-lsp-bridge/config/default.toml",
		"--host",
		"127.0.0.1",
		"--port",
		"8000",
	},
	restart = "on-failure",
	wanted_by = "default.target",
	only = { os = "unix" },
}
