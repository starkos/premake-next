local path = require('path')

local sln = {}


function sln.filename(wks)
	return path.join(wks.location, wks.filename) .. '.sln'
end


function sln.export(wks)
	sln.header()
	io.writeln('Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "MyProject", "MyProject.vcxproj", "{42B5DBC6-AE1F-903D-F75D-41E363076E92}"')
	io.writeln('EndProject')
end


function sln.header()
	io.writeln('Microsoft Visual Studio Solution File, Format Version 12.00')
	io.writeln('# Visual Studio 14')
end


return sln
