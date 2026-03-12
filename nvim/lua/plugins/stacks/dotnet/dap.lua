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
      local preferred = joinpath(debug_dir, 'net8.0', assembly_name .. '.dll')

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

    dapui.setup()
    require('nvim-dap-virtual-text').setup()

    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticSignError', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticSignWarn', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '◉', texthl = 'DiagnosticSignInfo', linehl = '', numhl = '' })
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
        processId = require('dap.utils').pick_process,
        cwd = solution_or_project_dir,
      },
    }

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end

    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
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
    map('n', '<leader>dr', dap.repl.open, { desc = 'Debug: Open REPL' })
    map('n', '<leader>du', dapui.toggle, { desc = 'Debug: Toggle UI' })
    map('n', '<leader>dt', dap.terminate, { desc = 'Debug: Terminate' })
  end,
}
