-- dadbod adapter for SQL Server on WSL.
-- Uses global functions (not autoload) so dadbod's adapter resolver skips
-- the autoload/ file lookup (prefix has no '#' → returns immediately).

vim.cmd([[
function! _DbAdapterSqlserverWsl_canonicalize(url) abort
  let url = a:url
  if url =~# ';.*=' && url !~# '?'
    let url = tr(substitute(substitute(url, ';', '?', ''), ';$', '', ''), ';', '&')
  endif
  let parsed = db#url#parse(url)
  for [param, value] in items(parsed.params)
    let canonical = param !~# '\l' ? param : tolower(param[0]) . param[1 : -1]
    if canonical !=# param
      call remove(parsed.params, param)
      if has_key(parsed.params, canonical)
        continue
      else
        let parsed.params[canonical] = value
      endif
    endif
    if value is# 1
      let parsed.params[canonical] = 'true'
    endif
  endfor
  return db#url#absorb_params(parsed, {
        \ 'user': 'user',
        \ 'userName': 'user',
        \ 'password': 'password',
        \ 'server': 'host',
        \ 'serverName': 'host',
        \ 'port': 'port',
        \ 'portNumber': 'port',
        \ 'database': 'database',
        \ 'databaseName': 'database'})
endfunction

function! s:_SqlServerWsl_server(url) abort
  return get(a:url, 'host', 'localhost') .
        \ (has_key(a:url, 'port') ? ',' . a:url.port : '')
endfunction

function! s:_SqlServerWsl_bool_flag(url, param, flag) abort
  let value = get(a:url.params, a:param, get(a:url.params, toupper(a:param[0]) . a:param[1 : -1], '0'))
  return value =~# '^[1tTyY]' ? [a:flag] : []
endfunction

function! s:_SqlServerWsl_bin() abort
  return get(g:, 'db_sqlserver_sqlcmd', 'sqlcmd')
endfunction

function! s:_SqlServerWsl_is_win() abort
  return s:_SqlServerWsl_bin() =~# '\c\.exe$'
endfunction

function! s:_SqlServerWsl_winpath(path) abort
  if !s:_SqlServerWsl_is_win()
    return a:path
  endif
  let out = systemlist(['wslpath', '-w', a:path])
  return empty(out) ? a:path : substitute(out[0], '\r\?$', '', '')
endfunction

function! _DbAdapterSqlserverWsl_interactive(url) abort
  let url = db#url#parse(a:url)
  let encrypt = get(url.params, 'encrypt', get(url.params, 'Encrypt', ''))
  let has_authentication = has_key(url.params, 'authentication')

  return (has_key(url, 'password') ? ['env', 'SQLCMDPASSWORD=' . url.password] : []) +
        \ [s:_SqlServerWsl_bin(), '-S', s:_SqlServerWsl_server(url)] +
        \ (empty(encrypt) ? [] : ['-N'] + (encrypt ==# '1' ? [] : [url.params.encrypt])) +
        \ s:_SqlServerWsl_bool_flag(url, 'trustServerCertificate', '-C') +
        \ (has_key(url, 'user') || has_authentication ? [] : ['-E']) +
        \ (has_authentication ? ['--authentication-method', url.params.authentication] : []) +
        \ db#url#as_argv(url, '', '', '', '-U ', '', '-d ')
endfunction

function! _DbAdapterSqlserverWsl_input(url, in) abort
  return _DbAdapterSqlserverWsl_interactive(a:url) + ['-i', s:_SqlServerWsl_winpath(a:in)]
endfunction

function! _DbAdapterSqlserverWsl_dbext(url) abort
  let url = db#url#parse(a:url)
  return {
        \ 'srvname': s:_SqlServerWsl_server(url),
        \ 'host': '',
        \ 'port': '',
        \ 'integratedlogin': !has_key(url, 'user'),
        \ }
endfunction

function! s:_SqlServerWsl_complete_query(url, query) abort
  let cmd = _DbAdapterSqlserverWsl_interactive(a:url)
  let query = 'SET NOCOUNT ON; ' . a:query
  let out = db#systemlist(cmd + ['-h-1', '-W', '-Q', query])
  return map(out, 'matchstr(v:val, "\\S\\+")')
endfunction

function! _DbAdapterSqlserverWsl_complete_database(url) abort
  return s:_SqlServerWsl_complete_query(matchstr(a:url, '^[^:]\+://.\\{-\\}/'), 'SELECT NAME FROM sys.sysdatabases')
endfunction

function! _DbAdapterSqlserverWsl_tables(url) abort
  return s:_SqlServerWsl_complete_query(a:url, 'SELECT TABLE_NAME FROM information_schema.tables ORDER BY TABLE_NAME')
endfunction
]])
