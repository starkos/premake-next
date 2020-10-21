---
-- System-defined user script fields
---

local Field = require('field')

Field.new({
	name = 'baseDir',
	kind = 'path'
})

Field.new({
	name = 'configurations',
	kind = 'list:string'
})

Field.new({
	name = 'defines',
	kind = 'list:string'
})

Field.new({
	name = 'exceptionHandling',
	kind = 'string',
	allowed = {
		'Default',
		'On',
		'Off',
		'SEH',
		'CThrow',
	}
})

Field.new({
	name = 'filename',
	kind = 'string'
})

Field.new({
	name = 'kind',
	kind = 'string',
	allowed = {
		'ConsoleApplication',
		'SharedLibrary',
		'StaticLibrary',
		'WindowedApplication'
	}
})


Field.new({
	name = 'location',
	kind = 'path'
})

Field.new({
	name = 'projects',
	kind = 'list:string'
})

Field.new({
	name = 'rtti',
	kind = 'string',
	allowed = {
		'Default',
		'On',
		'Off'
	}
})

Field.new({
	name = 'system',
	kind = 'string',
	allowed = {
		'AIX',
		'BSD',
		'Haiku',
		'iOS',
		'Linux',
		'MacOS',
		'Solaris',
		'Wii',
		'Windows',
	},
})

Field.new({
	name = 'workspaces',
	kind = 'list:string'
})
