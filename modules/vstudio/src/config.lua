---
-- Visual Studio helper methods for build configurations and platforms.
---

local dom = require('dom')

local vstudio = select(1, ...)

local Config = declareType('Config', dom.Config)


-- Map Premake architecture symbols to Visual Studio equivalents
-- TODO: this will probably have to move into toolset definitions; C# values are different
local _ARCHITECTURES = {
	x86 = 'Win32',
	x86_64 = 'x64',
	arm = 'ARM',
	arm64 = 'ARM64'
}


---
-- Extract all configurations from a workspace or project.
---

function Config.extractAll(container)
	local configs = {}

	local selectors = dom.Config.fetchConfigPlatformPairs(container)
	for i = 1, #selectors do
		configs[i] = Config.extract(container, selectors[i])
	end

	-- Visual Studio requires that configurations be alpha sorted, or it will resort them
	table.sort(configs, function(cfg0, cfg1)
		return (cfg0.vs_identifier:lower() < cfg1.vs_identifier:lower())
	end)

	return configs
end


---
-- Extra a configuration state instance from a workspace/project state.
--
-- @param container
--    The parent workspace or project.
-- @param selector
--    The configuration configuration/platform selector.
-- @returns
--    The corresponding config object.
---

function Config.extract(container, selector)
	local cfg = instantiateType(Config, dom.Config.new(container
		:selectAny(selector)
		:include(container.workspace, container.global)
		:withInheritance())
	)

	-- Configs can be contained by workspaces, projects, files...
	cfg.rootState = container.rootState
	cfg.container = container

	-- translate the incoming architecture
	cfg.vs_architecture = _ARCHITECTURES[cfg.architecture] or 'Win32'
	cfg.platform = cfg.platform or cfg.vs_architecture

	-- "Configuration|Platform or Architecture", e.g. "Debug|MyPlatform" or "Debug|Win32"
	cfg.vs_identifier = string.format('%s|%s', cfg.configuration, cfg.platform)

	-- "Configuration Platform|Architecture" e.g. "Debug MyPlatform|x64" or "Debug|Win32"
	if cfg.platform ~= cfg.vs_architecture then
		cfg.vs_build = string.format('%s|%s', string.join(' ', cfg.configuration, cfg.platform), cfg.vs_architecture)
	else
		cfg.vs_build = string.format('%s|%s', cfg.configuration, cfg.vs_architecture)
	end

	return cfg
end


return Config
