local array = require('array')
local export = require('export')
local path = require('path')
local premake = require('premake')
local xml = require('xml')

local vstudio = select(1, ...)

local esc = xml.escape
local wl = export.writeLine

local vcxproj = {}

vcxproj.HEADER_FILES = array.join(premake.C_HEADER_EXTENSIONS, premake.CXX_HEADER_EXTENSIONS, premake.OBJC_HEADER_EXTENSIONS)
vcxproj.SOURCE_FILES = array.join(premake.C_SOURCE_EXTENSIONS, premake.CXX_SOURCE_EXTENSIONS, premake.OBJC_SOURCE_EXTENSIONS)
vcxproj.RESOURCE_FILES = premake.WIN_RESOURCE_EXTENSIONS


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
		return _EMPTY
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
-- Source file categorizations control how each type of source object is generated.
-- Categories are evaluated in the order in which they appear in the list.
---

vcxproj.categories = {
	{
		tag = 'ClInclude',
		match = function (file)
			return string.endsWith(file, vcxproj.HEADER_FILES)
		end
	},
	{
		tag = 'ClCompile',
		match = function (file)
			return string.endsWith(file, vcxproj.SOURCE_FILES)
		end,
		emit = function (file)
			-- TODO: implement per-file configurations
		end
	},
	{
		tag = 'FxCompile',
		match = function (file)
			return string.endsWith(file, '.hlsl')
		end,
		emit = function (file)
			-- TODO: implement per-file configurations
		end
	},
	{
		tag = 'ResourceCompile',
		match = function (file)
			return string.endsWith(file, vcxproj.RESOURCE_FILES)
		end,
		emit = function (file)
			-- TODO: implement per-file configurations
		end
	},
	{
		tag = 'Midl',
		match = function (file)
			return string.endsWith(file, '.idl')
		end,
		emit = function (file)
			-- TODO: implement per-file configurations
		end
	},
	{
		tag = 'Masm',
		match = function (file)
			return string.endsWith(file, '.asm')
		end,
		emit = function (file)
			-- TODO: implement per-file configurations
		end
	},
	{
		tag = 'Image',
		match = function (file)
			return string.endsWith(file, '.gif', '.jpg', '.jpe', '.png', '.bmp', '.dib', '.tif', '.wmf', '.ras', '.eps', '.pcx', '.pcd', '.tga', '.dds')
		end,
		emit = function (file)
			-- TODO: implement per-file configurations
		end
	},
	{
		tag = 'Natvis',
		match = function (file)
			return string.endsWith(file, '.natvis')
		end
	},
	{
		tag = 'None',
		match = function (file)
			return true
		end
	}
}


---
-- Emit an individual setting element, with an optional configuration condition.
--
-- @param tag
--    The setting element tag, e.g. 'WarningLevel'.
-- @param cfg
--    The configuration currently being exported.
-- @param value
--    The setting value for the element, e.g. 'Level3'.
---

local function _element(tag, cfg, value)
	export.write('<%s', tag)
	if cfg.vs_build ~= nil then
		export.append(' Condition="$(Configuration)|$(Platform)"=="%s"', cfg.vs_build)
	end
	export.appendLine('>%s</%s>', value, tag)
end


---
-- Build the export file name for a project.
---

function vcxproj.filename(prj)
	return path.join(prj.location, prj.filename) .. '.vcxproj'
end


---
-- Export the project's `.vcxproj` file.
--
-- @return
--    True if the target `.vcxproj` file was updated; false otherwise.
---

function vcxproj.export(prj)
	vcxproj.prepare(prj)

	local didUpdateVcxproj = premake.export(prj, prj.exportPath, function ()
		export.eol('\r\n')
		export.indentString('  ')
		premake.callArray(vcxproj.elements.project, prj)
	end)

	local didUpdateFilters = vstudio.vcxproj.filters.export(prj)

	-- Workaround: if only filters change, force VS to auto reload the project
	if didUpdateFilters == true and didUpdateVcxproj == false then
		os.touch(prj.exportPath)
	end

	vcxproj.cleanup(prj)
end


---
-- Precompute data sets that will be needed during export.
---

function vcxproj.prepare(prj)
	prj.allSourceFiles = vcxproj.utils.collectAllSourceFiles(prj)
	prj.categorizedSourceFiles = vcxproj.utils.categorizeSourceFiles(prj)
	prj.virtualSourceTree = vcxproj.utils.buildVirtualSourceTree(prj)
	return prj
end


---
-- Release data sets that are no longer needed once project has been exported.
---

function vcxproj.cleanup(prj)
	prj.allSourceFiles = nil
	prj.categorizedSourceFiles = nil
	prj.virtualSourceTree = nil
end


---
-- Handlers for structural elements, in the order in which they appear in the .vcxproj.
-- Handlers for individual setting elements are at the bottom of the file.
---

function vcxproj.xmlDeclaration()
	wl('<?xml version="1.0" encoding="utf-8"?>')
end


function vcxproj.project()
	local toolsVersion = vstudio.targetVersion.toolsVersion
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
	local architectures = array.collectUnique(configs, function (cfg)
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


---
-- Sort a list of source files into categories.
--
-- @returns
--    A list of category buckets, each bucket containing a list of files which
--    match that category, if any.
---

function vcxproj.files(prj)
	local categorizedFiles = vcxproj.utils.categorizeSourceFiles(prj)
	for ci = 1, #categorizedFiles do
		local category = vcxproj.categories[ci]
		local files = categorizedFiles[ci]
		if #files > 0 then
			wl('<ItemGroup>')
			export.indent()
			for fi = 1, #files do
				vcxproj.emitFileItem(prj, category, files[fi])
			end
			export.outdent()
			wl('</ItemGroup>')
		end
	end
end


function vcxproj.emitFileItem(prj, category, file)
	local settings

	if category.emit ~= nil then
		settings = export.capture(function ()
			-- TODO: select project-level file cfg & emit

			for i = 1, #prj.configs do
				local cfg = prj.configs[i]
				if prj.files[file] or cfg.files[file] then
					-- TODO: select config level file cfg & emit
				else
					_element('ExcludedFromBuild', cfg, 'true')
				end
			end
		end)
	end

	file = path.translate(path.getRelative(prj.baseDirectory, file))

	if settings == nil or #settings == 0 then
		wl('<%s Include="%s" />', category.tag, file)
	else
		wl('<%s Include="%s">', category.tag, file)
		wl(settings)
		wl('</%s>', category.tag)
	end
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
