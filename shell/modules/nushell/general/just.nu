def "nu-complete just-recipes" [] {
  ^just --list err> /dev/null
  | lines
  | each { |line| $line | str replace --regex '\s+#.*' '' | str trim }
  | where { |s| $s != '' }
}

export extern "just" [
  recipe?: string@"nu-complete just-recipes"
  ...args
]

export extern "jst" [
  recipe?: string@"nu-complete just-recipes"
  ...args
]
