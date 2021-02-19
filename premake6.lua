---
-- Premake Next build configuration script
-- Use this script to configure the project with Premake6.
---

register('testing')

workspace('Premake', function ()
	configurations { 'Debug', 'Release' }

	project('Premake', function ()

		files {
			'core/host/src/**.h',
			'core/host/src/**.c',
			'core/host/src/**.lua',
			'core/host/contrib/lua/src/**.h',
			'core/host/contrib/lua/src/**.c'
		}

		removeFiles {
			'core/host/contrib/lua/src/lua.c',
			'core/host/contrib/lua/src/luac.c'
		}

	end)
end)
