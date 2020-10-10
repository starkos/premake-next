# Changes since Premake5

My best attempt to keep track of all the notable changes between this version and the latest and greatest v5. If you spot anything I missed, open an issue to let me know!

## The Big Stuff

#### Exporters now default to latest version

Tool vendors are moving to more "fluid" releases, and significant changes are no longer limited to major releases. The expectation is that most developers will stay up-to-date with the most recent version (whether they like it or not!). In this new world, Premake's one-exporter-per-major-version approach isn't holding up. Instead, exporters now register a single action per toolset with an optional argument to specify the version. If not specified, the most recent version is targeted.

```sh
# Target the latest version
$ premake6 vstudio
$ premake6 xcode

# Target a specific version
$ premake vstudio=2017
$ premake6 xcode=9

# Opens possibility of targeting incremental releases
$ premake vstudio=14.0.25431.01
```
#### Names are now Camel Case

All symbols have been standardized on [camelCase](https://en.wikipedia.org/wiki/Camel_case), ex. `string.startswith()` is now `string.startsWith()`. This includes Lua's built-in functions as well, ex. `doFile()` and `loadFile()`. In previous versions I tried to match Lua's `alllowercasenoseparators` standard but it only resulted in unreadable code.

#### No longer modifies the current working directory

Previous versions would set the working directory to the location of the last loaded script file. The current working directory is now left intact; use `__SCRIPT_DIR` to create script relative paths at runtime.

#### Documentation has moved

Documentation is now stored in a `docs/` folder in the main repository. This allows it to be authored alongside the code, and reviewed and approved as part of the normal pull request process.


## Smaller improvements

- **No longer modifies the Lua runtime.** You can now choose to link Premake against the system's Lua library in order to interoperate with third-party binary Lua modules.

- **Less global namespace clutter.** In particular, the `premake` and `path` globals are gone; you'll now need to `local premake = require('premake')` and `local path = require('path')` instead.

- **System script runs earlier.** The system script is now run earlier in the bootstrap process, enabling third-party modules more opportunities to modify that process.

- **Improved command line option model and parsing.** The distinction between "options" and "actions" has been removed. All arguments may now specify an `execute()` method. The "=" is now optional when assigning values from the command line. The `_OPTIONS` global has been removed; use the `options` module for direct programmatic access.

- **Preload magic replaced with `register()`.** Previously only core modules could register command line options and other settings on startup without actually loading the entire module. Any modules may now include a `register.lua` script which can be loaded with `register('moduleName')`. See [the testing module](../modules/testing) for an example.


## Under the Hood Changes

- The way in which project settings are stored and queries has been entirely rewritten to improve flexibility and enable new features; see [this community update](https://opencollective.com/premake/updates/community-update-5) for more information

- The division of responsibilities has been shifted to give exporters significantly more control over how data is queried, inherited, and exported

- The code has been reorganized to be more module-oriented; features are now loaded on-demand for faster startup time and lower resource usage.


## API Changes

- As mentioned above, all APIs now use camel-case: `string.startswith` is now `string.startsWith`, etc.

#### _G

- Most of global variables are now gathered under a new `_PREMAKE` global: `_PREMAKE.COMMAND`, `_PREMAKE.COMMAND_DIR`, `_PREMAKE.MAIN_SCRIPT`, `_PREMAKE.MAIN_SCRIPT_DIR`, `_PREMAKE.PATH`

- `premake.path` (now `_PREMAKE.PATH`) is now an array of paths rather than a semicolon separated string. You may also put functions in this list, which are called at file load time to resolve the path to be searched.

- `doFile()` now accepts an optional list of arguments to pass to the called script

### os

- `os.writefile_ifnotequal()` has been moved to `io.writeFile()` and `io.compareFile()`

### premake

- `premake.generate()` is now `export()`, and uses a different signature

- `premake.workspace`, `project`, and `config` have been moved to a new `dom` module

- I/O functions (`capture`, `w`, `eol`, etc.) have been moved to the `io` library

#### table

- API reworked to distinguish between array and dictionary operations

#### terminal

- `terminal.textColor()` has replaced `getTextColor` and `setTextColor`

#### testing

-  Test module name changed from `self-test` to `testing`

-  `--test-only` option now supports "*" wildcards and multiple, comma-separated patterns, ex. `--test-only="string,os"`

- Test output is now quieter by default; use `--verbose` flag to enable detailed out

- Modules may now register pre- and post-test hooks to allow module state to be captured and restored around test boundaries
