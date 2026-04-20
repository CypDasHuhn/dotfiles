if vim.fn.has('wsl') ~= 1 then
  return
end

-- vim-dadbod's sqlserver adapter shells out to `sqlcmd`.
-- On WSL, the Linux sqlcmd often can't use Windows Integrated auth (-E) to on-prem SQL,
-- resulting in "Login failed for user ''".
--
-- Point dadbod at the Windows `SQLCMD.EXE` instead.
vim.g.db_adapter_sqlserver = 'db#adapter#sqlserver_wsl#'
vim.g.db_sqlserver_sqlcmd = '/mnt/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/170/Tools/Binn/SQLCMD.EXE'

