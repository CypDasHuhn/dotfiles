$env.PATH = ($env.PATH | split row (char esep) | prepend '/home/linuxbrew/.linuxbrew/bin')
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.zvm/self")
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.zvm/master")
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.vdirCli)/zig-out/bin")
