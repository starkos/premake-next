---
-- Premake script-side program entry point.
---

forceRequire('_G')
forceRequire('string')
forceRequire('table')
forceRequire('os')
forceRequire('io')

local main = require('main')

function _premake_main()
	main.run()
end
