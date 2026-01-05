#!/bin/bash
cd "$(dirname "$0")"
pkill -f MdSh 2>/dev/null
swift build && {
    .build/debug/MdSh &
    sleep 0.5
    osascript -e 'tell application "System Events" to set frontmost of (first process whose name is "MdSh") to true' 2>/dev/null
}
