local State = require('state')

local Config = declareType('Config', State)


function Config.new(state)
	local cfg = instantiateType(Config, state)

	cfg.configuration = state.configurations[1]
	cfg.platform = state.platforms[1]

	return cfg
end


---
-- Given a container state (i.e. workspace or project), returns a list of build
-- configuration and platform pairs for that state, as an array of query selectors
-- suitable for passing to `State.selectAny()`, ex.
--
--     { configurations = 'Debug', platforms = 'x86_64' }
---

function Config.fetchConfigPlatformPairs(state)
	local configs = state.configurations
	local platforms = state.platforms

	local results = {}

	for i = 1, #configs do
		if #platforms == 0 then
			table.insert(results, {
				configurations = configs[i]
			})
		else
			for j = 1, #platforms do
				table.insert(results, {
					configurations = configs[i],
					platforms = platforms[j]
				})
			end
		end
	end

	return results
end


return Config
