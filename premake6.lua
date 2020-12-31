---
-- Premake Next build configuration script
-- Use this script to configure the project with Premake6.
---

register('testing')

workspace('Premake', function ()
	configurations { 'Debug', 'Release' }

	project('Premake', function ()
	end)
end)
