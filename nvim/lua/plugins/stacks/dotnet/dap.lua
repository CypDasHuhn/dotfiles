return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
  },
  ft = { 'cs', 'csproj', 'sln' },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local dap_log = require 'dap.log'

    local function is_windows()
      return vim.loop.os_uname().sysname == 'Windows_NT'
    end

    local function joinpath(...)
      return table.concat({ ... }, is_windows() and '\\' or '/')
    end

    local function first_executable(paths)
      for _, path in ipairs(paths) do
        if vim.fn.executable(path) == 1 or vim.uv.fs_stat(path) then
          return path
        end
      end
    end

    local function netcoredbg_path()
      local data = vim.fn.stdpath 'data'
      local candidates = is_windows() and {
        joinpath(data, 'mason', 'packages', 'netcoredbg', 'netcoredbg', 'netcoredbg.exe'),
        joinpath(data, 'mason', 'bin', 'netcoredbg.cmd'),
      } or {
        joinpath(data, 'mason', 'bin', 'netcoredbg'),
        joinpath(data, 'mason', 'packages', 'netcoredbg', 'netcoredbg', 'netcoredbg'),
      }

      return first_executable(candidates) or 'netcoredbg'
    end

    local function current_buffer_dir()
      local file = vim.api.nvim_buf_get_name(0)
      if file == '' then
        return vim.fn.getcwd()
      end

      return vim.fs.dirname(file)
    end

    local function find_upward(matcher, startpath)
      local found = vim.fs.find(matcher, {
        upward = true,
        path = startpath,
        stop = vim.loop.os_homedir(),
      })[1]

      return found and vim.fs.normalize(found) or nil
    end

    local function csproj_path()
      return find_upward(function(name)
        return name:match '%.csproj$'
      end, current_buffer_dir())
    end

    local function csproj_target_frameworks(project_path)
      if not project_path or project_path == '' then
        return {}
      end

      local lines = vim.fn.readfile(project_path)
      local text = table.concat(lines, '\n')

      local tfms = text:match('<TargetFrameworks>%s*([^<]+)%s*</TargetFrameworks>')
      if tfms then
        local out = {}
        for tfm in tfms:gmatch('[^;]+') do
          tfm = vim.trim(tfm)
          if tfm ~= '' then
            table.insert(out, tfm)
          end
        end
        return out
      end

      local tfm = text:match('<TargetFramework>%s*([^<]+)%s*</TargetFramework>')
      if tfm then
        tfm = vim.trim(tfm)
        if tfm ~= '' then
          return { tfm }
        end
      end

      return {}
    end

    local function solution_or_project_dir()
      local root_file = find_upward(function(name)
        return name:match '%.sln$' or name:match '%.csproj$'
      end, current_buffer_dir())
      if root_file then
        return vim.fs.dirname(root_file)
      end

      return vim.fn.getcwd()
    end

    local function default_dll_path()
      local project = csproj_path()
      if not project then
        return joinpath(vim.fn.getcwd(), 'bin', 'Debug', 'net8.0', vim.fn.fnamemodify(vim.fn.getcwd(), ':t') .. '.dll')
      end

      local project_dir = vim.fs.dirname(project)
      local assembly_name = vim.fn.fnamemodify(project, ':t:r')
      local debug_dir = joinpath(project_dir, 'bin', 'Debug')
      local frameworks = csproj_target_frameworks(project)
      local preferred_tfm = frameworks[1] or 'net8.0'
      local preferred = joinpath(debug_dir, preferred_tfm, assembly_name .. '.dll')

      if vim.uv.fs_stat(preferred) then
        return preferred
      end

      local matches = vim.fn.globpath(debug_dir, '**/' .. assembly_name .. '.dll', false, true)
      for _, match in ipairs(matches) do
        local normalized = vim.fs.normalize(match)
        if not normalized:match('[\\/]ref[\\/]') then
          return normalized
        end
      end

      return preferred
    end

    local function prompt_for_program()
      local default_path = default_dll_path()
      local input = vim.fn.input('Path to DLL: ', default_path, 'file')
      return vim.fs.normalize(vim.fn.expand(input ~= '' and input or default_path))
    end

    local function prompt_for_args()
      local input = vim.fn.input 'Arguments: '
      local args = {}
      for arg in string.gmatch(input, '%S+') do
        table.insert(args, arg)
      end
      return args
    end

    local function notify(msg, level)
      vim.schedule(function()
        vim.notify(msg, level or vim.log.levels.INFO, { title = 'nvim-dap' })
      end)
    end

    local function breakpoint_location(bp)
      if not bp then
        return nil
      end

      local source = bp.source and bp.source.path
      local line = bp.line
      if not source or not line then
        return nil
      end

      return string.format('%s:%s', vim.fs.normalize(source), line)
    end

    local function show_breakpoint_state(bp)
      if not bp or bp.verified ~= false then
        return
      end

      local parts = { bp.message or 'Breakpoint rejected by adapter' }
      local location = breakpoint_location(bp)
      if location then
        table.insert(parts, location)
      end

      notify(table.concat(parts, '\n'), vim.log.levels.WARN)
    end

    local function set_dap_log_level(level)
      dap.set_log_level(level)
      local log_path = dap_log.create_logger('dap.log'):get_path()
      notify(string.format('DAP log level: %s\n%s', level, log_path))
    end

    local function list_attachable_processes()
      if not is_windows() then
        -- dap.utils.get_processes only provides (pid, name) and can miss the
        -- command line we need to identify the right dotnet host. Use `ps` so
        -- users can reliably pick the exact PID they want to attach to.
        local lines = vim.fn.systemlist { 'ps', '-eo', 'pid=,comm=,args=' }
        local processes = {}
        for _, line in ipairs(lines) do
          local pid, name, args = line:match('^%s*(%d+)%s+(%S+)%s+(.*)$')
          pid = tonumber(pid)
          if pid and name then
            table.insert(processes, {
              pid = pid,
              name = name,
              command = args ~= '' and args or name,
            })
          end
        end

        local ignored = {
          'MSBuild.dll',
          'Microsoft.CodeAnalysis.LanguageServer.dll',
          'EasyDotnet.BuildServer.dll',
          'dotnet-easydotnet',
        }

        local filtered = {}
        for _, proc in ipairs(processes) do
          local cmd = proc.command or proc.name or ''
          local skip = false
          for _, pattern in ipairs(ignored) do
            if cmd:find(pattern, 1, true) then
              skip = true
              break
            end
          end

          if not skip then
            -- Prefer showing the actual dotnet host processes. This keeps the
            -- picker focused and matches typical "dotnet run" workflows.
            if cmd:find('dotnet', 1, true) ~= nil then
              table.insert(filtered, proc)
            end
          end
        end

        table.sort(filtered, function(a, b)
          local function score(p)
            local c = (p.command or ''):lower()
            if c:find('dotnet run', 1, true) then
              return 0
            end
            if c:find('.dll', 1, true) then
              return 1
            end
            return 2
          end
          local sa, sb = score(a), score(b)
          if sa == sb then
            return (a.pid or 0) > (b.pid or 0)
          end
          return sa < sb
        end)

        return filtered
      end

      local powershell = 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe'
      local command = table.concat({
        "$ErrorActionPreference='Stop'",
        'Get-CimInstance Win32_Process',
        "| Where-Object { $_.Name -match '^(dotnet|iisexpress|w3wp)(\\.exe)?$' }",
        '| Select-Object ProcessId, Name, CommandLine',
        '| ConvertTo-Json -Compress',
      }, '; ')

      local output = vim.fn.system({ powershell, '-NoProfile', '-Command', command })
      if vim.v.shell_error ~= 0 or output == '' then
        return require('dap.utils').get_processes {
          filter = function(proc)
            return proc.name:find('dotnet', 1, true) ~= nil
              and not proc.name:find('easydotnet', 1, true)
          end,
        }
      end

      local json_decode = (vim.json and vim.json.decode) or vim.fn.json_decode
      local ok, decoded = pcall(json_decode, output)
      if not ok or not decoded then
        return require('dap.utils').get_processes {
          filter = function(proc)
            return proc.name:find('dotnet', 1, true) ~= nil
              and not proc.name:find('easydotnet', 1, true)
          end,
        }
      end

      if decoded.ProcessId then
        decoded = { decoded }
      end

      local ignored = {
        'MSBuild.dll',
        'Microsoft.CodeAnalysis.LanguageServer.dll',
        'EasyDotnet.BuildServer.dll',
        'dotnet-easydotnet',
      }

      local processes = {}
      for _, proc in ipairs(decoded) do
        local pid = tonumber(proc.ProcessId)
        local name = proc.Name or 'unknown'
        local cmd = proc.CommandLine or name
        local skip = false

        for _, pattern in ipairs(ignored) do
          if cmd:find(pattern, 1, true) then
            skip = true
            break
          end
        end

        if pid and not skip then
          table.insert(processes, {
            pid = pid,
            name = name,
            command = cmd,
          })
        end
      end

      return processes
    end

    local function prompt_for_pid()
      local input = vim.fn.input 'Process ID to attach: '
      local pid = tonumber(input)
      if not pid then
        notify('Invalid PID: ' .. tostring(input), vim.log.levels.WARN)
        return dap.ABORT
      end
      return pid
    end

    local function pick_dotnet_process()
      local ui = require 'dap.ui'
      local processes = list_attachable_processes()

      if #processes == 0 then
        notify('No attachable .NET process found; enter PID manually', vim.log.levels.WARN)
        return prompt_for_pid()
      end

      local function label(proc)
        local cmd = (proc.command or proc.name or ''):gsub('%s+', ' ')
        if #cmd > 180 then
          cmd = cmd:sub(1, 177) .. '...'
        end

        return string.format('id=%d %s', proc.pid, cmd)
      end

      table.insert(processes, 1, { pid = -1, name = 'manual', command = '[Enter PID manually]' })

      local result = ui.pick_one_sync(processes, 'Select .NET process: ', label)
      if not result then
        return dap.ABORT
      end
      if result.pid == -1 then
        return prompt_for_pid()
      end
      return result.pid
    end

    dapui.setup()
    require('nvim-dap-virtual-text').setup()

    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticSignError', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticSignWarn', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '◉', texthl = 'DiagnosticSignInfo', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected', { text = 'R', texthl = 'DiagnosticSignError', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticSignHint', linehl = 'Visual', numhl = 'DiagnosticSignHint' })

    dap.adapters.coreclr = {
      type = 'executable',
      command = netcoredbg_path(),
      args = { '--interpreter=vscode' },
    }

    dap.configurations.cs = {
      {
        type = 'coreclr',
        name = 'Launch project DLL',
        request = 'launch',
        program = prompt_for_program,
        cwd = function()
          local project = csproj_path()
          return project and vim.fs.dirname(project) or solution_or_project_dir()
        end,
        stopAtEntry = false,
        console = 'integratedTerminal',
        args = prompt_for_args,
        env = {
          ASPNETCORE_ENVIRONMENT = 'Development',
        },
      },
      {
        type = 'coreclr',
        name = 'Attach to process',
        request = 'attach',
        processId = pick_dotnet_process,
        cwd = solution_or_project_dir,
      },
    }

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end

    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end

    dap.listeners.after.event_breakpoint.dotnet_breakpoint_status = function(_, event)
      show_breakpoint_state(event and event.breakpoint)
    end

    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end

    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    local map = vim.keymap.set
    map('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    map('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
    map('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
    map('n', '<F12>', dap.step_out, { desc = 'Debug: Step Out' })
    map('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    map('n', '<leader>dB', function()
      vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(condition)
        if condition and condition ~= '' then
          dap.set_breakpoint(condition)
        end
      end)
    end, { desc = 'Debug: Conditional Breakpoint' })
    map('n', '<leader>dl', dap.run_last, { desc = 'Debug: Run Last' })
    map('n', '<leader>dL', function()
      local log_path = dap_log.create_logger('dap.log'):get_path()
      notify(log_path)
    end, { desc = 'Debug: Show DAP Log Path' })
    map('n', '<leader>dT', function()
      set_dap_log_level 'TRACE'
    end, { desc = 'Debug: Set Log Level TRACE' })
    map('n', '<leader>dI', function()
      set_dap_log_level 'INFO'
    end, { desc = 'Debug: Set Log Level INFO' })
    map('n', '<leader>dr', dap.repl.open, { desc = 'Debug: Open REPL' })
    map('n', '<leader>du', dapui.toggle, { desc = 'Debug: Toggle UI' })
    map('n', '<leader>dt', dap.terminate, { desc = 'Debug: Terminate' })
  end,
}
