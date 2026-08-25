if vim.fn.has('wsl') ~= 1 then
  return
end

-- vim-dadbod's sqlserver adapter shells out to `sqlcmd`.
-- On WSL, the Linux sqlcmd often can't use Windows Integrated auth (-E) to on-prem SQL,
-- resulting in "Login failed for user ''".
--
-- Point dadbod at the Windows `SQLCMD.EXE` instead.
-- Prefix without '#' so dadbod skips the autoload/ file lookup (the functions
-- are defined as globals by lua/db/adapter/sqlserver_wsl.lua).
--
-- On Arch WSL, sqlcmd/ODBC come from the AUR (no official MS repo):
--   yay -S msodbcsql mssql-tools unixodbc
-- which installs sqlcmd to /usr/bin/sqlcmd (symlinked from /opt/mssql-tools/bin/sqlcmd).
require('db.adapter.sqlserver_wsl')
vim.g.db_adapter_sqlserver = '_DbAdapterSqlserverWsl_'
vim.g.db_sqlserver_sqlcmd = '/usr/bin/sqlcmd'

