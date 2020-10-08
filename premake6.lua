---
-- Premake Next build configuration script
-- Use this script to configure the project with Premake6.
---

register('testing')

local premake = require('premake')

premake.store()
	:addValue('workspaces', 'MyWorkspace')

	:pushCondition({ workspaces = 'MyWorkspace' })
	:addValue('projects', 'MyProject')
	:popCondition()
