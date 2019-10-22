# loadFile

Load a Lua script file.

```lua
local chunk = loadFile('file')
```

## Parameters

`file` is name of the script file to be loaded. See [_PREMAKE.PATH](_PREMAKE.PATH.md) for the list of locations Premake will check to locate this file.

## Return Value

If successful, returns a function that, when run, executes the contents of the script file. On failure, returns `nil` and an error message.

## See Also

- [doFile](doFile.md)
