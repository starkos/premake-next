# Changes since Premake5

## The Big Stuff

#### Names are now Camel Case

All symbols have been standardized on [camelCase](https://en.wikipedia.org/wiki/Camel_case), ex. `string.startswith()` is now `string.startsWith()`. This includes Lua's built-in functions as well, ex. `doFile()` and `loadFile()`. (In previous versions I tried to match Lua's `alllowercase` standard but it only resulted in unreadable code. This isn't assembly language.)


## Smaller improvements

- **No longer modifies the Lua runtime.** This opens up the possibility of linking Premake against the system's Lua library, enabling it to interoperate with third-party Lua binary modules.

- **Now respects and maintains the current working directory.** Previous versions would set the working directory to the location of the last loaded script file.

- **System script runs earlier.** The system script is now run earlier in the bootstrap process, enabling third-party modules more opportunities to modify that process.

- **Improved command line option model and parsing.** The distinction between "options" and "actions" has been removed. All options may now specify an `execute()` method. The "=" is now optional when assigning values from the command line. The `_OPTIONS` global has been removed; use the `options` module for direct programmatic access.

- **Preload magic replaced with `require()`.** Previously only core modules could register command line options and other settings on startup without actually loading the entire module. Modules may now include a `register.lua` script which can be loaded with `register('moduleName')`. See [the testing module](../modules/testing) for an example.


## API Changes

- As mentioned above, all APIs now use camel-case: `string.startswith` is now `string.startsWith`, etc.

- `doFile()` now accepts an optional list of arguments to pass to the called script

- Most of the global state variables have been gathered under a new `_PREMAKE` global: `_PREMAKE.COMMAND`, `_PREMAKE.COMMAND_DIR`, `_PREMAKE.MAIN_SCRIPT`, `_PREMAKE.MAIN_SCRIPT_DIR`, `_PREMAKE.PATH`.

- `premake.path` (now `_PREMAKE.PATH`) is now an array of paths rather than a semicolon separated string. You may also put functions in this list, which are called at file load time to resolve the path to be searched.


## Under the Hood Changes

- The code has been reorganized to be more module-oriented, with less global namespace clutter. In particular, the `premake` and `path` globals are gone; you'll now need to `local premake = require('premake')` and `local path = require('path')` instead. In addition to cleaning up the globals table, this means that core features and actions are now lazy-loaded on demand, rather than always loading everything up front.

- Documentation is now stored in a `docs/` folder in the main repository. This allows it to be authored alongside the code, and reviewed and approved as part of the normal pull request process.

- The internal C APIs are now faster (using local buffers instead of the Lua stack) and use more consistent function signatures.


## Unit Testing Module Changes

- **Name changed from `self-test` to `testing`**

- **Improved `--test-only` option.** Now supports the "*" wildcard and multiple, comma-separated patterns, ex. `--test-only="string,os"`

- **Assertions now use camel-case.** Like all other APIs; `test.isEqual`

- **Quieter default output.** The detailed test output is now muted by default; use the `--verbose` command line option to display.
