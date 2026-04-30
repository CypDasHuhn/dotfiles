def port-pid [port: int] {
  netstat -ano
    | lines
    | where { str contains $":($port)" }
    | each { split row " " | last | str trim | into int }
    | uniq
}

def kill-port [port: int] {
  let pids = (port-pid $port)
  if ($pids | is-empty) {
    print $"No process found on port ($port)"
    return
  }
  $pids | each { |pid|
    taskkill /F /PID $pid
    print $"Killed process ($pid) on port ($port)"
  }
}
