return {
  'GustavEikaas/easy-dotnet.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
  ft = { 'cs', 'fsproj', 'csproj', 'sln' },
  config = function()
    require('easy-dotnet').setup {
      lsp = {
        enabled = true,
        auto_refresh_codelens = false,
        config = {
          settings = {
            ["csharp|inlay_hints"] = {
              csharp_enable_inlay_hints_for_implicit_object_creation = true,
              csharp_enable_inlay_hints_for_implicit_variable_types = true,
              csharp_enable_inlay_hints_for_lambda_parameter_types = true,
              csharp_enable_inlay_hints_for_types = true,
              dotnet_enable_inlay_hints_for_parameters = true,
            },
            ["csharp|code_lens"] = {
              dotnet_enable_references_code_lens = true,
            },
          },
        },
      },
    }

    -- easy-dotnet.nvim's debugger path calls an RPC build without an explicit
    -- configuration and then errors without surfacing MSBuild diagnostics.
    -- Patch the RPC client *after initialize* so we can:
    -- - default builds to Debug
    -- - show the first build error via vim.notify
    local ok_rpc, rpc = pcall(require, 'easy-dotnet.rpc.rpc')
    if ok_rpc and rpc and rpc.global_rpc_client then
      local client = rpc.global_rpc_client
      local wrapped = false

      local function wrap_msbuild()
        if wrapped or not client.msbuild or type(client.msbuild.msbuild_build) ~= 'function' then
          return
        end
        wrapped = true

        local original = client.msbuild.msbuild_build
        client.msbuild.msbuild_build = function(self, request, cb, opts)
          if type(request) == 'table' and request.configuration == nil then
            request = vim.tbl_extend('force', request, { configuration = 'Debug' })
          end

          local function wrapped_cb(res)
            if res and res.success == false then
              local errors = res.errors or {}
              local first = errors[1]
              local msg = 'easy-dotnet: build failed'
              if first and first.message then
                msg = msg .. '\n' .. tostring(first.message)
                if first.filePath and first.lineNumber then
                  msg = msg .. string.format('\n%s:%s', first.filePath, first.lineNumber)
                end
                if #errors > 1 then
                  msg = msg .. string.format('\n(+%d more)', #errors - 1)
                end
              end
              vim.schedule(function()
                vim.notify(msg, vim.log.levels.ERROR, { title = 'easy-dotnet' })
              end)
            end
            if cb then
              return cb(res)
            end
          end

          return original(self, request, wrapped_cb, opts)
        end
      end

      -- In many setups `client.msbuild` only exists after `client:initialize()`.
      -- Hook initialize so the wrapper is installed reliably.
      if type(client.initialize) == 'function' then
        local original_init = client.initialize
        client.initialize = function(self, cb, ...)
          return original_init(self, function(...)
            wrap_msbuild()
            if cb then
              return cb(...)
            end
          end, ...)
        end
      end

      wrap_msbuild()
    end

    local csharp_codelens = require 'config.dotnet.codelens'
    local easy_dotnet = vim.lsp.config.easy_dotnet
    if easy_dotnet and easy_dotnet.on_attach then
      local original_on_attach = easy_dotnet.on_attach
      easy_dotnet.on_attach = function(client, bufnr)
        original_on_attach(client, bufnr)
        csharp_codelens.on_attach(client, bufnr)
      end
    end
  end,
}
