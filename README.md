# testcmd

Dev-only Luanti mod for driving a running server from outside, for local testing.

- Every 0.5s, runs each line of the command file as a chat command, then removes the file.
- Commands run as the player named by the `name` setting, without privilege checks.
- `/lua <code>` runs Lua and logs returned values. Only available from the command file.
- Results are logged as `[testcmd] /cmd args -> ok message`.

Example:

    echo "/time 12:00" >> worlds/myworld/cmds.txt
    echo "/shutdown" >> worlds/myworld/cmds.txt

## Command file

Set by `CMD_FILE` at the top of `init.lua`, default `cmds.txt`. Paths containing `..` are rejected.

- Relative: inside the world directory.
- Absolute: requires `secure.trusted_mods = testcmd`, and must be outside the world and
  mod data directories. Otherwise polling is disabled with an error.

## Security

Anything that can write the command file gets full admin access.

With a relative path, that includes every other mod, since mods can write to the world
directory. Renaming the file does not help, as mods can read this mod's code.

With an absolute path, mods cannot write the file. Use a directory only you can write to.

Only use this on local test servers, never on a public one.
