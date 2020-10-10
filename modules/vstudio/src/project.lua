local project = {}


function project.export(prj)
	io.writeln('<?xml version="1.0" encoding="utf-8"?>')
	io.writeln('<Project DefaultTargets="Build" ToolsVersion="14.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
	io.write('</Project>')
end


return project
