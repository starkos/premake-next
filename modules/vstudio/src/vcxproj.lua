local path = require('path')

local vcxproj = {}


function vcxproj.filename(prj)
	return path.join(prj.location, prj.filename) .. '.vcxproj'
end


function vcxproj.export(prj)
	vcxproj.header()
	io.writeln('<Project DefaultTargets="Build" ToolsVersion="14.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
	io.write('</Project>')
end


function vcxproj.header()
	io.writeln('<?xml version="1.0" encoding="utf-8"?>')
end


return vcxproj
