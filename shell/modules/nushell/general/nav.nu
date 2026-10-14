alias __nav_builtin_cd = cd

def --env nav [action?: string] {
    match $action {
        null => {
            $env.IS_NAVIGATION_MODE = true
            ls
        }
        "off" => {
            $env.IS_NAVIGATION_MODE = false
        }
        _ => {
            error make { msg: $"Unknown nav action: ($action)" }
        }
    }
}

def --env cd [
    path?: directory
    --physical (-P)
] {
    if $physical {
        if $path == null {
            __nav_builtin_cd --physical
        } else {
            __nav_builtin_cd --physical $path
        }
    } else if $path == null {
        __nav_builtin_cd
    } else {
        __nav_builtin_cd $path
    }

    if (($env.IS_NAVIGATION_MODE? | default false) | into bool) {
        ls
    }
}

def --env ".." [] {
    cd ..
}
