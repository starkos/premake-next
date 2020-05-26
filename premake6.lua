---
-- Premake Next build configuration script
-- Use this script to configure the project with Premake6.
---

register('testing')

-----------------------------------------------------------

local Store = require('store')

-- local store = Store.new()

-- store
-- 	-- Workspace --
-- 	:addValue('workspaces', 'Premake6')
-- 	:pushCondition({ workspaces = 'Premake6' })
-- 		:addValue('configurations', { 'Release', 'Debug' })

-- 		:pushCondition({ configurations = 'Debug' })
-- 			:addValue('defines', '_DEBUG')
-- 		:popCondition()

-- 		:pushCondition({ configurations = 'Release' })
-- 			:addValue('defines', 'NDEBUG')
-- 		:popCondition()

-- 		-- Project --
-- 		:addValue('projects', 'Premake6')
-- 		:pushCondition({ projects = 'Premake6' })
-- 			:addValue('kind', 'ConsoleApplication')
-- 		:popCondition()
-- 		-- End project --

-- 	:popCondition()
-- 	-- End workspace --


-- -- Begin "action" --

-- function printAllFields(cfg)
-- 	local fields = { 'configurations', 'kind', 'defines' }
-- 	for i = 1, #fields do
-- 		local value = cfg:fetch(fields[i])
-- 		if type(value) == 'table' then
-- 			value = table.toString(value)
-- 		end
-- 		if value ~= nil then
-- 			print(fields[i], value)
-- 		end
-- 	end
-- end

-- local global = store:query({})
-- local workspace = global:select({ workspaces = 'Premake6' }):inheritValues()
-- local project = workspace:select({ projects = 'Premake6' }):inheritValues()
-- local config = project:select({ configurations = 'Debug' }):inheritValues()

-- print('---- WORKSPACE ----')
-- printAllFields(workspace)
-- print()

-- print('---- PROJECT ----')
-- printAllFields(project)
-- print()

-- print('---- CONFIG ----')
-- printAllFields(config)
-- print()
