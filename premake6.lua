---
-- Premake Next build configuration script
-- Use this script to configure the project with Premake6.
---

-- Define an action to run the automated unit tests
commandLineOption {
	trigger = 'test',
	description = 'Run the automated test suite',
	category = 'Testing',
	execute = function ()
		print('Running tests...')
	end
}
