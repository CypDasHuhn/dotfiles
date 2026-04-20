def port-pid [port: int] {
  lsof -ti $":($port)" | lines | each { into int }
}

def kill-port [port: int] {
  let pids = (port-pid-unix $port)
  if ($pids | is-empty) {
    print $"No process found on port ($port)"
    return
  }
  $pids | each { |pid|
    kill -9 $pid
    print $"Killed process ($pid) on port ($port)"
  }
}
