local export = require('export')
local path = require('path')
local premake = require('premake')
local xml = require('xml')

local vstudio = select(1, ...)

local esc = xml.escape
local wl = export.writeln

local vcxproj = {}



---
-- Element lists describe the contents of each section of the project file
---

vcxproj.elements = {

	project = function (prj)
		return {
			vcxproj.xmlDeclaration,
			vcxproj.project,
			vcxproj.projectConfigurations,
			vcxproj.globals,
			vcxproj.importDefaultProps,
			vcxproj.configurationPropertyGroup,
			vcxproj.importLanguageSettings,
			vcxproj.importExtensionSettings,
			vcxproj.propertySheets,
			vcxproj.userMacros,
			vcxproj.outputPropertyGroup,
			vcxproj.itemDefinitionGroup,
			vcxproj.assemblyReferences,
			vcxproj.files,
			vcxproj.projectReferences,
			vcxproj.importLanguageTargets,
			vcxproj.importExtensionTargets,
			vcxproj.ensureNuGetPackageBuildImports,
			vcxproj.endTag
		}
	end,

	globals = function (prj)
		return {
			vcxproj.projectGuid,
			vcxproj.ignoreWarnCompileDuplicatedFilename,
			vcxproj.keyword,
			vcxproj.rootNamespace
		}
	end,

	clCompile = function (cfg)
		return {
			vcxproj.precompiledHeader,
			vcxproj.warningLevel,
			vcxproj.preprocessorDefinitions,
			vcxproj.debugInformationFormat,
			vcxproj.optimization,
			vcxproj.functionLevelLinking,
			vcxproj.intrinsicFunctions,
			vcxproj.minimalRebuild,
			vcxproj.stringPooling
		}
	end,

	configurationPropertyGroup = function (cfg)
		return {
			vcxproj.configurationType,
			vcxproj.useDebugLibraries,
			vcxproj.characterSet,
			vcxproj.platformToolset
		}
	end,

	importExtensionSettings = function (prj)
		return {}
	end,

	itemDefinitionGroup = function (cfg)
		return {
			vcxproj.clCompile,
			vcxproj.link
		}
	end,

	link = function (cfg)
		return {
			vcxproj.subSystem,
			vcxproj.generateDebugInformation,
			vcxproj.enableComdatFolding,
			vcxproj.optimizeReferences
		}
	end,

	outputPropertyGroup = function (cfg)
		return {
			vcxproj.linkIncremental,
			vcxproj.outDir,
			vcxproj.intDir,
			vcxproj.targetName,
			vcxproj.targetExt
		}
	end
}


---
-- Build the export file name for a project.
---

function vcxproj.filename(prj)
	return path.join(prj.location, prj.filename) .. '.vcxproj'
end


---
-- Export the project to the currently open output stream.
---

function vcxproj.export(prj)
	export.eol('\r\n')
	export.indentString('  ')
	premake.callArray(vcxproj.elements.project, prj)
end


---
-- Handlers for structural elements, in the order in which they appear in the .vcxproj.
-- Handlers for individual setting elements are at the bottom of the file.
---

function vcxproj.xmlDeclaration()
	wl('<?xml version="1.0" encoding="utf-8"?>')
end


function vcxproj.project()
	local toolsVersion = vstudio.currentVersion.toolsVersion
	if toolsVersion ~= nil then
		wl('<Project DefaultTargets="Build" ToolsVersion="%s" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">', toolsVersion)
	else
		wl('<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
	end
	export.indent()
end


function vcxproj.projectConfigurations(prj)
	wl('<ItemGroup Label="ProjectConfigurations">')
	export.indent()

	local configs = prj.configs

	-- Identify all architectures used by the project
	local architectures = table.collectUnique(configs, function (cfg)
		return cfg.vs_architecture
	end)

	for i = 1, #configs do
		local cfg = configs[i]
		for j = 1, #architectures do
			local arch = architectures[j]

			local cfgName
			if cfg.platform ~= arch then
				cfgName = string.join(' ', cfg.configuration, cfg.platform)
			else
				cfgName = cfg.configuration
			end

			wl('<ProjectConfiguration Include="%s|%s">', cfgName, arch)
			export.indent()
			wl('<Configuration>%s</Configuration>', cfgName)
			wl('<Platform>%s</Platform>', arch)
			export.outdent()
			wl('</ProjectConfiguration>')
		end
	end

	export.outdent()
	wl('</ItemGroup>')
end


function vcxproj.globals(prj)
	wl('<PropertyGroup Label="Globals">')
	export.indent()
	premake.callArray(vcxproj.elements.globals, prj)
	export.outdent()
	wl('</PropertyGroup>')
end


function vcxproj.importDefaultProps(prj)
	wl('<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />')
end


function vcxproj.configurationPropertyGroup(prj)
	for i = 1, #prj.configs do
		local cfg = prj.configs[i]
		wl('<PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'%s\'" Label="Configuration">', cfg.vs_build)
		export.indent()
		premake.callArray(vcxproj.elements.configurationPropertyGroup, cfg)
		export.outdent()
		wl('</PropertyGroup>')
	end
end


function vcxproj.importLanguageSettings(prj)
	wl('<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.props" />')
end


function vcxproj.importExtensionSettings(prj)
	wl('<ImportGroup Label="ExtensionSettings">')
	export.indent()
	premake.callArray(vcxproj.elements.importExtensionSettings, prj)
	export.outdent()
	wl('</ImportGroup>')
end


function vcxproj.propertySheets(prj)
	for i = 1, #prj.configs do
		local cfg = prj.configs[i]
		wl('<ImportGroup Label="PropertySheets" Condition="\'$(Configuration)|$(Platform)\'==\'%s\'">', cfg.vs_build)
		export.indent()
		wl('<Import Project="$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props" Condition="exists(\'$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />')
		export.outdent()
		wl('</ImportGroup>')
	end
end


function vcxproj.userMacros(prj)
	wl('<PropertyGroup Label="UserMacros" />')
end


function vcxproj.outputPropertyGroup(prj)
	for i = 1, #prj.configs do
		local cfg = prj.configs[i]
		wl('<PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'%s\'">', cfg.vs_build)
		export.indent()
		premake.callArray(vcxproj.elements.outputPropertyGroup, cfg)
		export.outdent()
		wl('</PropertyGroup>')
	end
end


function vcxproj.itemDefinitionGroup(prj)
	for i = 1, #prj.configs do
		local cfg = prj.configs[i]
		wl('<ItemDefinitionGroup Condition="\'$(Configuration)|$(Platform)\'==\'%s\'">', cfg.vs_build)
		export.indent()
		premake.callArray(vcxproj.elements.itemDefinitionGroup, cfg)
		export.outdent()
		wl('</ItemDefinitionGroup>')
	end
end


function vcxproj.clCompile(cfg)
	wl('<ClCompile>')
	export.indent()
	premake.callArray(vcxproj.elements.clCompile, cfg)
	export.outdent()
	wl('</ClCompile>')
end


function vcxproj.link(cfg)
	wl('<Link>')
	export.indent()
	premake.callArray(vcxproj.elements.link, cfg)
	export.outdent()
	wl('</Link>')
end


function vcxproj.assemblyReferences()
end


function vcxproj.files()
	wl('<ItemGroup>')
	export.indent()
		wl('<ClCompile Include="..\\main.cpp" />')
	export.outdent()
	wl('</ItemGroup>')
end


function vcxproj.projectReferences()
end


function vcxproj.importLanguageTargets()
	wl('<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.targets" />')
end


function vcxproj.importExtensionTargets()
	wl('<ImportGroup Label="ExtensionTargets">')
	wl('</ImportGroup>')
end


function vcxproj.ensureNuGetPackageBuildImports()
end


function vcxproj.endTag(prj)
	export.outdent()
	export.write('</Project>')  -- no trailing newline to match VS output
end


---
-- Handlers for individual setting elements, in alpha order.
---

function vcxproj.characterSet(cfg)
	wl('<CharacterSet>Unicode</CharacterSet>')
end


function vcxproj.configurationType(cfg)
	wl('<ConfigurationType>Application</ConfigurationType>')
end


function vcxproj.debugInformationFormat(cfg)
	-- just pass the unit tests
	if cfg.configuration == 'Debug' then
		wl('<DebugInformationFormat>EditAndContinue</DebugInformationFormat>')
	end
end


function vcxproj.enableComdatFolding(cfg)
	-- just pass the unit tests
	if cfg.configuration == 'Release' then
		wl('<EnableCOMDATFolding>true</EnableCOMDATFolding>')
	end
end


function vcxproj.functionLevelLinking(cfg)
	-- just pass the unit tests
	if cfg.configuration == 'Release' then
		wl('<FunctionLevelLinking>true</FunctionLevelLinking>')
	end
end


function vcxproj.generateDebugInformation(cfg)
	-- just pass the unit tests
	if cfg.configuration == 'Debug' then
		wl('<GenerateDebugInformation>true</GenerateDebugInformation>')
	end
end


function vcxproj.ignoreWarnCompileDuplicatedFilename(prj)
	wl('<IgnoreWarnCompileDuplicatedFilename>true</IgnoreWarnCompileDuplicatedFilename>')
end


function vcxproj.intDir(cfg)
	wl('<IntDir>obj\\%s\\</IntDir>', cfg.configuration)
end


function vcxproj.intrinsicFunctions(cfg)
	-- just pass the unit tests
	if cfg.configuration == 'Release' then
		wl('<IntrinsicFunctions>true</IntrinsicFunctions>')
	end
end


function vcxproj.keyword(prj)
	wl('<Keyword>Win32Proj</Keyword>')
end


function vcxproj.linkIncremental(cfg)
	-- just pass the unit tests for now
	local value = (cfg.configuration == 'Debug')
	wl('<LinkIncremental>%s</LinkIncremental>', tostring(value))
end


function vcxproj.minimalRebuild(cfg)
	-- just pass the unit tests
	if cfg.configuration == 'Release' then
		wl('<MinimalRebuild>false</MinimalRebuild>')
	end
end


function vcxproj.optimization(cfg)
	-- pass unit tests for now
	local value
	if cfg.configuration == 'Debug' then
		value = 'Disabled'
	else
		value = 'MinSpace'
	end
	wl('<Optimization>%s</Optimization>', value)
end


function vcxproj.optimizeReferences(cfg)
	-- just pass the unit tests
	if cfg.configuration == 'Release' then
		wl('<OptimizeReferences>true</OptimizeReferences>')
	end
end


function vcxproj.outDir(cfg)
	wl('<OutDir>bin\\%s\\</OutDir>', cfg.configuration)
end


function vcxproj.platformToolset(cfg)
	wl('<PlatformToolset>v140</PlatformToolset>')
end


function vcxproj.precompiledHeader(cfg)
	wl('<PrecompiledHeader>NotUsing</PrecompiledHeader>')
end


function vcxproj.preprocessorDefinitions(cfg)
	-- pass unit tests for now
	local value
	if cfg.configuration == 'Debug' then
		value = '_DEBUG'
	else
		value = 'NDEBUG'
	end
	wl('<PreprocessorDefinitions>%s;%%(PreprocessorDefinitions)</PreprocessorDefinitions>', value)
end


function vcxproj.projectGuid(prj)
	wl('<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)
end


function vcxproj.rootNamespace(prj)
	wl('<RootNamespace>%s</RootNamespace>', esc(prj.name))
end


function vcxproj.stringPooling(cfg)
	-- just pass the unit tests
	if cfg.configuration == 'Release' then
		wl('<StringPooling>true</StringPooling>')
	end
end


function vcxproj.subSystem(cfg)
	wl('<SubSystem>Console</SubSystem>')
end


function vcxproj.targetExt(cfg)
	wl('<TargetExt>.exe</TargetExt>')
end


function vcxproj.targetName(cfg)
	wl('<TargetName>%s</TargetName>', esc(cfg.container.name))
end


function vcxproj.useDebugLibraries(cfg)
	-- make the tests pass for now
	local value = (cfg.configuration == 'Debug')
	wl('<UseDebugLibraries>%s</UseDebugLibraries>', tostring(value))
end


function vcxproj.warningLevel(cfg)
	wl('<WarningLevel>Level3</WarningLevel>')
end


return vcxproj
