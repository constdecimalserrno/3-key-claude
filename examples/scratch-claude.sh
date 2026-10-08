#!/bin/sh
# Makes a fresh, dated scratch folder and starts claude code in it, for the "let's just try something" moments.
# It hands the folder to new-claude-session.sh, so keep the two side by side.

# where the scratch folders pile up
SCRATCH="$HOME/scratch"

DIR="$SCRATCH/$(date +%Y-%m-%d-%H%M%S)" # say ~/scratch/2026-10-07-153012, sorts itself by date
mkdir -p "$DIR"
exec /bin/sh "$(dirname "$0")/new-claude-session.sh" "$DIR"
