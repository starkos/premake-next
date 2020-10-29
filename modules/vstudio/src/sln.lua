local export = require('export')
local path = require('path')
local premake = require('premake')
local xml = require('xml')

local vstudio = select(1, ...)

local esc = xml.escape
local wl = export.writeln

local sln = {}

sln.elements = {}

sln.elements.solution = function (wks)
	return {
		sln.bom,
		sln.header,
		sln.projects,
		sln.global
	}
end

sln.elements.global = function (wks)
	return {
		sln.solutionConfiguration,
		sln.projectConfiguration,
		sln.solutionProperties
	}
end


function sln.filename(wks)
	return path.join(wks.location, wks.filename) .. '.sln'
end


function sln.export(wks)
	export.eol('\r\n')
	export.indentString('\t')
	premake.callArray(sln.elements.solution, wks)
end


function sln.bom()
	export.writeUtf8Bom()
	wl()
end


function sln.header()
	wl('Microsoft Visual Studio Solution File, Format Version %d.00', vstudio.currentVersion.solutionFileFormatVersion)
	wl('# Visual Studio %s', vstudio.currentVersion.visualStudioVersion)
end


function sln.projects(wks)
	local projects = wks.projects
	for i = 1, #projects do
		local prj = projects[i]

		local prjPath = path.translate(path.getRelativeFile(wks.exportPath, prj.exportPath), '\\')

		-- Unlike projects, solutions must use old-school %...% DOS style syntax for environment variables
		prjPath = prjPath:gsub("$%((.-)%)", "%%%1%%")

		wl('Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "%s", "%s", "{%s}"', esc(prj.name), esc(prjPath), prj.uuid)
		wl('EndProject')
	end
end


function sln.global(wks)
	wl('Global')
	export.indent()
	premake.callArray(sln.elements.global)
	export.outdent()
	wl('EndGlobal')
end


function sln.solutionConfiguration(wks)
	wl('GlobalSection(SolutionConfigurationPlatforms) = preSolution')
	export.indent()
		wl('Debug|Win32 = Debug|Win32')
		wl('Release|Win32 = Release|Win32')
	export.outdent()
	wl('EndGlobalSection')
end


function sln.projectConfiguration(wks)
	wl('GlobalSection(ProjectConfigurationPlatforms) = postSolution')
	export.indent()
		wl('{42B5DBC6-AE1F-903D-F75D-41E363076E92}.Debug|Win32.ActiveCfg = Debug|Win32')
		wl('{42B5DBC6-AE1F-903D-F75D-41E363076E92}.Debug|Win32.Build.0 = Debug|Win32')
		wl('{42B5DBC6-AE1F-903D-F75D-41E363076E92}.Release|Win32.ActiveCfg = Release|Win32')
		wl('{42B5DBC6-AE1F-903D-F75D-41E363076E92}.Release|Win32.Build.0 = Release|Win32')
	export.outdent()
	wl('EndGlobalSection')
end


function sln.solutionProperties(wks)
	wl('GlobalSection(SolutionProperties) = preSolution')
	export.indent()
		wl('HideSolutionNode = FALSE')
	export.outdent()
	wl('EndGlobalSection')
end


return sln
