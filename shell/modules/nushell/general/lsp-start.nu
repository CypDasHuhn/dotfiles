def lsp-start [] { 
  ^codex-lsp-bridge serve --config ~/code/codex-lsp-bridge/config/default.toml --host 127.0.0.1 --port 8000
}

def lsp-setup [] {
  git clone https://github.com/eLyiN/codex-bridge.git ~/code/codex-lsp-bridge
  cd ~/code/codex-lsp-bridge
  pip install -e .

  open ~/.codex/config.toml
  | merge deep {
      mcp_servers: {
        lsp_bridge: {
          url: "http://127.0.0.1:8000/mcp"
          default_tools_approval_mode: "auto"
        }
      }
    }
  | save -f ~/.codex/config.toml
  sudo pacman -S typescript-language-server
  sudo pacman -S vue-language-server

  dotnet tool install --global csharp-ls
  open ~/code/codex-lsp-bridge/config/default.toml
  | merge deep {
      servers: {
        csharp: {
          command: "csharp-ls"
          args: []
          file_extensions: ["cs"]
          language_id: "csharp"
        }
      }
    }
  | save -f ~/code/codex-lsp-bridge/config/default.toml

  let cfg = (open ~/code/codex-lsp-bridge/config/default.toml)
  let ts = (
    $cfg.servers.typescript
    | upsert file_extensions (
        $cfg.servers.typescript.file_extensions
        | append "vue"
        | uniq
      )
  )
  let servers = ($cfg.servers | upsert typescript $ts)

  $cfg
  | upsert servers $servers
  | save -f ~/code/codex-lsp-bridge/config/default.toml
}
