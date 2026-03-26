$env.PATH = ($env.PATH | split row (char esep) | prepend '/home/linuxbrew/.linuxbrew/bin')
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.me)/.zvm/self")
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.me)/.zvm/master")
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.vdirCli)/zig-out/bin")
