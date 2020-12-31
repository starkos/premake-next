local premake = require('premake')
local Config = require('dom').Config

local DomConfigTests = test.declare('DomConfigTests', 'dom')


function DomConfigTests.fetchConfigPlatformPairs_onConfigsOnly()
	configurations { 'Debug', 'Release' }

	local pairs = Config.fetchConfigPlatformPairs(premake.newState())
	test.isEqual({
		{ configurations = 'Debug' },
		{ configurations = 'Release' }
	}, pairs)
end
