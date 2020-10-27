local export = require('export')
local path = require('path')

local vcxproj = {}

local wl = export.writeln


function vcxproj.filename(prj)
	return path.join(prj.location, prj.filename) .. '.vcxproj'
end


function vcxproj.export(prj)
	vcxproj.header()
	wl('<Project DefaultTargets="Build" ToolsVersion="14.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
	export.write('</Project>')
end


function vcxproj.header()
	wl('<?xml version="1.0" encoding="utf-8"?>')
end


return vcxproj
