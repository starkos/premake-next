# path.getKind

Determines if the given path is absolute or relative.

```lua
local path = require('path')
local result = path.getKind('value')
```

## Parameters

`value` is the path to be tested.

## Return Value

One of:

- "absolute" if `value` is an absolute path
- "relative" if `value` is a relative path
- "unknown" if the kind could not be determined; this usually means the path starts with variable of some type
