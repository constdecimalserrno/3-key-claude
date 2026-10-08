-- Same as new-claude-session.sh, but as an AppleScript file, so you can see that kind of Action works too:
-- {"script": "examples/new-claude-session.applescript"} and 3KC runs it with osascript.
-- iterm2 ONLY, AppleScript won't even start when it names an app you don't have, so picking one is the .sh's job.

-- the folder claude starts in, "" is your home folder ( a full path, AppleScript doesn't know ~ )
property theFolder : ""

if theFolder is "" then set theFolder to POSIX path of (path to home folder)
set cmd to "cd " & quoted form of theFolder & " && claude"
tell application id "com.googlecode.iterm2"
    tell current session of (create window with default profile) to write text cmd
    activate
end tell
