def port-pid [port: int] {
  lsof -ti $":($port)" | lines | each { |line| $line | into int }
}

def kill-port [port: int] {
  let pids = (port-pid $port)
  if ($pids | is-empty) {
    print $"No process found on port ($port)"
    return
  }
  $pids | each { |pid|
    kill -s 9 $pid
    print $"Killed process ($pid) on port ($port)"
  }
}
