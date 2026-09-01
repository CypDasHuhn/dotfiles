def fix-audio [
    --dir: string = "."      # directory with video files
    --suffix: string = "_fixed"  # suffix appended before extension
    --bitrate: string = "192k"   # AAC bitrate
    --replace                 # overwrite originals instead of creating new files
] {
    let dir = ($dir | path expand)
    let files = (glob $"($dir)/*.mp4")

    if ($files | is-empty) {
        print $"No .mp4 files found in ($dir)"
        return
    }

    let count = ($files | length)
    let plural = (if $count == 1 { "" } else { "s" })
    print ("Found " + ($count | into string) + " file" + $plural)

    for file in $files {
        let stem = ($file | path parse | get stem)
        let parent = ($file | path parse | get parent)
        let ext = ($file | path parse | get extension)

        let out = if $replace {
            $"/tmp/($stem)_tmp.($ext)"
        } else {
            $"($parent)/($stem)($suffix).($ext)"
        }

        print $"(ansi cyan)Processing:(ansi reset) ($file | path basename)"

        ^ffmpeg -y -loglevel error -i $file -c:v copy -c:a aac -b:a $bitrate $out e>| ignore

        if $replace {
            mv $out $file
        }
    }

    print "Done."
}
