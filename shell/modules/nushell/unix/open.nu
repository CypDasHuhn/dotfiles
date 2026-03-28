def xopen [...paths: string] {
    for path in $paths {
        xdg-open $path
    }
}
