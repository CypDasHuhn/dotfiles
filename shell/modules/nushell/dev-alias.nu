# Development shortcuts (mirrors dev-alias.ps1)

def npm-r [] {
    npm run dev
}

def npm-t [] {
    npm test
}

def dn-r-https [] {
    dotnet run --launch-profile "https"
}

def dn-r [] {
    api
    dotnet run
}

def dn-t [] {
    dotnet test
}
