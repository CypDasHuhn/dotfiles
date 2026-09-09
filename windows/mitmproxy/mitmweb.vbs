' Start the headless mitmproxy process without a console window at sign-in.
Option Explicit

Dim shell, filterPath, configDir, command
Set shell = CreateObject("WScript.Shell")

configDir = shell.ExpandEnvironmentStrings("%USERPROFILE%\.config\mitmproxy")
filterPath = configDir & "\reddit_filter.py"
command = "mitmdump.exe --quiet --listen-host 127.0.0.1 --listen-port 8080 -s """ & filterPath & """ --set confdir="""" & configDir & """" --set ssl_insecure=true"

' 0 = hidden window; false = do not block the Startup-folder launcher.
shell.Run command, 0, False
