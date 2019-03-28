---
-- Premake Next build configuration script
-- Use this script to configure the project with Premake5.
---

	workspace 'Premake6'

		configurations { 'Release', 'Debug' }

		flags { 'MultiProcessorCompile' }
		staticruntime 'On'
		warnings 'Extra'

		filter { 'system:windows' }
			platforms { 'x86', 'x64' }

		filter 'configurations:Debug'
			defines '_DEBUG'
			symbols 'On'

		filter 'configurations:Release'
			defines 'NDEBUG'
			optimize 'Full'
			flags { 'NoBufferSecurityCheck', 'NoRuntimeChecks' }

		filter 'action:vs*'
			defines { '_CRT_SECURE_NO_DEPRECATE', '_CRT_SECURE_NO_WARNINGS', '_CRT_NONSTDC_NO_WARNINGS' }

		filter { 'system:windows', 'configurations:Release' }
			flags { 'NoIncrementalLink', 'LinkTimeOptimization' }

	project 'Premake6'

		targetname 'premake6'
		language 'C'
		kind 'ConsoleApp'

		files
		{
			'src/**.h', 'src/**.c',
			'src/**.lua',
			'contrib/lua/src/**.h', 'contrib/lua/src/**.c'
		}

		removefiles
		{
			'contrib/lua/src/lua.c',
			'contrib/lua/src/luac.c',
			'contrib/lua/src/print.c',
			'contrib/lua/**.lua',
			'contrib/lua/etc/*.c'
		}

		includedirs { 'contrib/lua/src' }

		filter 'configurations:Debug'
			targetdir 'bin/debug'
			debugargs { '--scripts=%{prj.location}/%{path.getrelative(prj.location, prj.basedir)}' }
			debugdir '.'

		filter 'configurations:Release'
			targetdir 'bin/release'

		filter 'system:windows'
			links { 'ole32', 'ws2_32', 'advapi32' }

		filter 'system:linux or bsd or hurd'
			defines { 'LUA_USE_POSIX', 'LUA_USE_DLOPEN' }
			links { 'm' }
			linkoptions { '-rdynamic' }

		filter 'system:linux or hurd'
			links { 'dl', 'rt' }

		filter 'system:macosx'
			defines { 'LUA_USE_MACOSX' }
			links { 'CoreServices.framework', 'Foundation.framework', 'Security.framework', 'readline' }

		filter { 'system:macosx', 'action:gmake' }
			toolset 'clang'

		filter { 'system:solaris' }
			links { 'm', 'socket', 'nsl' }

		filter 'system:aix'
			defines { 'LUA_USE_POSIX', 'LUA_USE_DLOPEN' }
			links { 'm' }
