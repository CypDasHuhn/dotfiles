def lsh [] {
    ls | where { |it| not ($it.name | str starts-with ".") } 
}
