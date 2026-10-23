# testcmd

Dev-only Luanti mod for driving a running server from outside, for local testing.

- Every 0.5s, runs each line of `<world>/cmds.txt` as a chat command, then removes the file.
- Commands run as the player named by the `name` setting, without privilege checks.
- Results are written to the server log as `[testcmd] /cmd args -> ok message`.
- Adds `/lua <code>` (requires `server` priv): runs Lua and prints returned values.

Example:

    echo "/time 12:00" >> worlds/myworld/cmds.txt
    echo "/shutdown" >> worlds/myworld/cmds.txt

## Warning

Anyone who can write to the world directory gets full admin command access.
Only use this on local test servers, never on a public one.
