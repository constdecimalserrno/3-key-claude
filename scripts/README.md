# Your scripts

This folder is for YOUR scripts, the ones your Macro keys run. Git ignores everything in here except this README, so nothing personal ends up in a commit or a pull request by accident.

You don't have to use it, a script can live anywhere on your Mac, this is just a handy spot right next to the examples. 3KC doesn't copy anything from here, it runs your script right where it is. 3KC's own scripts folder, `~/.config/uwu/scripts/`, works just as well ( the 3KC window's Choose… starts there ).

Point a Macro key at it with a `~/...` path, from wherever your clone lives:

```json
{"script": "~/code/3-key-claude/scripts/standup.sh"}
```

A relative path starts in `~/.config/uwu/` instead ( that's how the default script macros reach the examples ), and an absolute one works too. `.applescript` and `.scpt` files run with `osascript`, a file you `chmod +x`'d runs as is ( give it a `#!` line ), anything else runs with `/bin/sh`.

Scripts run with 3KC's permissions, Accessibility included, so only run scripts you've read.

Cheers!
