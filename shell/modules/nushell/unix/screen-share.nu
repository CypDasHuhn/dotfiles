def single-share [fps: int, duration: int, format: string, root: string, monitor: string] {
  let expanded_root = ($root | path expand)
  job spawn { gpu-screen-recorder -w $monitor -f $fps -a default_output -c $format -r $duration -o $expanded_root -cr full }
}

def screen-share [] {
  let fps = 60
  let duration = 60 * 5
  let format = "mp4"
  let root = "~/Videos/"
  single-share $fps $duration $format $"($root)hdmi/" "HDMI-A-1"
  single-share $fps $duration $format $"($root)dp/" "DP-3"
}

def capture [] {
  ps | where name =~ "gpu-screen-reco" | each { |p| kill -s 10 $p.pid }
}

def kill-recording [] {
  ps | where name =~ "gpu-screen-reco" | each { |p| kill $p.pid }
}
