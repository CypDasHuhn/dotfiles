def dotnet-certs [] {
    dotnet dev-certs https --clean
    dotnet dev-certs https --trust
}
