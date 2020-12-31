---
-- System-defined user script fields
---

local Field = require('field')

Field.register({
	name = 'action',
	kind = 'string'
})

Field.register({
	name = 'architecture',
	kind = 'string',
	allowed = {
		'x86',
		'x86_86',
		'arm',
		'arm64'
	}
})

Field.register({
	name = 'baseDir',
	kind = 'path'
})

Field.register({
	name = 'configurations',
	kind = 'list:string',
	isScope = true
})

Field.register({
	name = 'defines',
	kind = 'list:string'
})

Field.register({
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

Field.register({
	name = 'filename',
	kind = 'string'
})

Field.register({
	name = 'kind',
	kind = 'string',
	allowed = {
		'ConsoleApplication',
		'SharedLibrary',
		'StaticLibrary',
		'WindowedApplication'
	}
})


Field.register({
	name = 'location',
	kind = 'path'
})

Field.register({
	name = 'platforms',
	kind = 'list:string',
	isScope = true
})

Field.register({
	name = 'projects',
	kind = 'list:string',
	isScope = true
})

Field.register({
	name = 'rtti',
	kind = 'string',
	allowed = {
		'Default',
		'On',
		'Off'
	}
})

Field.register({
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
	}
})

Field.register({
	name = 'uuid',
	kind = 'string'
})

Field.register({
	name = 'version',
	kind = 'string'
})

Field.register({
	name = 'workspaces',
	kind = 'list:string',
	isScope = true
})
