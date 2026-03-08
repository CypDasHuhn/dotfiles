fcd() {
    local depth=1
    local -a patterns

    for arg in "$@"; do
        case $arg in
            --depth=*) depth="${arg#*=}" ;;
            *) patterns+=("$arg") ;;
        esac
    done

    if [ ${#patterns[@]} -eq 0 ]; then
        echo "Usage: fcd <pattern> [pattern2 ...] [--depth=N]"
        return 1
    fi

    for pattern in "${patterns[@]}"; do
        local dir
        dir=$(find . -maxdepth "$depth" -type d -iname "*${pattern}*" | head -n 1)
        if [ -n "$dir" ]; then
            cd "$dir" || return 1
        else
            print -P "%F{red}No directory matching '$pattern' found%f"
            return 1
        fi
    done
}
