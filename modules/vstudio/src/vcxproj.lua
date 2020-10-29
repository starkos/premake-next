local export = require('export')
local path = require('path')
local premake = require('premake')
local xml = require('xml')

local vstudio = select(1, ...)

local esc = xml.escape
local wl = export.writeln

local vcxproj = {}

vcxproj.elements = {}

vcxproj.elements.project = function (prj)
	return {
		vcxproj.xmlDeclaration,
		vcxproj.project,
		vcxproj.projectConfigurations,
		vcxproj.globals,
		vcxproj.importDefaultProps,
		vcxproj.configurationPropertiesGroup,
		vcxproj.importLanguageSettings,
		vcxproj.importExtensionSettings,
		vcxproj.propertySheetGroup,
		vcxproj.userMacros,
		vcxproj.outputPropertiesGroup,
		vcxproj.itemDefinitionGroups,
		vcxproj.assemblyReferences,
		vcxproj.files,
		vcxproj.projectReferences,
		vcxproj.importLanguageTargets,
		vcxproj.importExtensionTargets,
		vcxproj.ensureNuGetPackageBuildImports,
		vcxproj.endTag
	}
end

vcxproj.elements.globals = function (prj)
	return {
		vcxproj.projectGuid,
		vcxproj.ignoreWarnCompileDuplicatedFilename,
		vcxproj.keyword,
		vcxproj.rootNamespace,
	}
end

vcxproj.elements.importExtensionSettings = function (prj)
	return {}
end


function vcxproj.filename(prj)
	return path.join(prj.location, prj.filename) .. '.vcxproj'
end


function vcxproj.export(prj)
	export.eol('\r\n')
	export.indentString('  ')
	premake.callArray(vcxproj.elements.project, prj)
end


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
		wl('<ProjectConfiguration Include="Debug|Win32">')
		export.indent()
			wl('<Configuration>Debug</Configuration>')
			wl('<Platform>Win32</Platform>')
		export.outdent()
		wl('</ProjectConfiguration>')
		wl('<ProjectConfiguration Include="Release|Win32">')
		export.indent()
			wl('<Configuration>Release</Configuration>')
			wl('<Platform>Win32</Platform>')
		export.outdent()
		wl('</ProjectConfiguration>')
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


function vcxproj.projectGuid(prj)
	wl('<ProjectGuid>{%s}</ProjectGuid>', prj.uuid)
end


function vcxproj.ignoreWarnCompileDuplicatedFilename(prj)
	wl('<IgnoreWarnCompileDuplicatedFilename>true</IgnoreWarnCompileDuplicatedFilename>')
end


function vcxproj.keyword(prj)
	wl('<Keyword>Win32Proj</Keyword>')
end


function vcxproj.rootNamespace(prj)
	wl('<RootNamespace>%s</RootNamespace>', esc(prj.name))
end


function vcxproj.importDefaultProps(prj)
	wl('<Import Project="$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />')
end


function vcxproj.configurationPropertiesGroup(prj)
	wl('<PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'Debug|Win32\'" Label="Configuration">')
	export.indent()
		wl('<ConfigurationType>Application</ConfigurationType>')
		wl('<UseDebugLibraries>true</UseDebugLibraries>')
		wl('<CharacterSet>Unicode</CharacterSet>')
		wl('<PlatformToolset>v140</PlatformToolset>')
	export.outdent()
	wl('</PropertyGroup>')
	wl('<PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'Release|Win32\'" Label="Configuration">')
	export.indent()
		wl('<ConfigurationType>Application</ConfigurationType>')
		wl('<UseDebugLibraries>false</UseDebugLibraries>')
		wl('<CharacterSet>Unicode</CharacterSet>')
		wl('<PlatformToolset>v140</PlatformToolset>')
	export.outdent()
	wl('</PropertyGroup>')
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


function vcxproj.propertySheetGroup(prj)
	wl('<ImportGroup Label="PropertySheets" Condition="\'$(Configuration)|$(Platform)\'==\'Debug|Win32\'">')
	export.indent()
		wl('<Import Project="$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props" Condition="exists(\'$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />')
	export.outdent()
	wl('</ImportGroup>')
	wl('<ImportGroup Label="PropertySheets" Condition="\'$(Configuration)|$(Platform)\'==\'Release|Win32\'">')
	export.indent()
		wl('<Import Project="$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props" Condition="exists(\'$(UserRootDir)\\Microsoft.Cpp.$(Platform).user.props\')" Label="LocalAppDataPlatform" />')
	export.outdent()
	wl('</ImportGroup>')
end


function vcxproj.userMacros(prj)
	wl('<PropertyGroup Label="UserMacros" />')
end


function vcxproj.outputPropertiesGroup(prj)
	wl('<PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'Debug|Win32\'">')
	export.indent()
		wl('<LinkIncremental>true</LinkIncremental>')
		wl('<OutDir>bin\\Debug\\</OutDir>')
		wl('<IntDir>obj\\Debug\\</IntDir>')
		wl('<TargetName>%s</TargetName>', esc(prj.name))
		wl('<TargetExt>.exe</TargetExt>')
	export.outdent()
	wl('</PropertyGroup>')
	wl('<PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'Release|Win32\'">')
	export.indent()
		wl('<LinkIncremental>false</LinkIncremental>')
		wl('<OutDir>bin\\Release\\</OutDir>')
		wl('<IntDir>obj\\Release\\</IntDir>')
		wl('<TargetName>%s</TargetName>', esc(prj.name))
		wl('<TargetExt>.exe</TargetExt>')
	export.outdent()
	wl('</PropertyGroup>')
end


function vcxproj.itemDefinitionGroups(prj)
	wl('<ItemDefinitionGroup Condition="\'$(Configuration)|$(Platform)\'==\'Debug|Win32\'">')
	export.indent()
		wl('<ClCompile>')
		export.indent()
			wl('<PrecompiledHeader>NotUsing</PrecompiledHeader>')
			wl('<WarningLevel>Level3</WarningLevel>')
			wl('<PreprocessorDefinitions>_DEBUG;%%(PreprocessorDefinitions)</PreprocessorDefinitions>')
			wl('<DebugInformationFormat>EditAndContinue</DebugInformationFormat>')
			wl('<Optimization>Disabled</Optimization>')
		export.outdent()
		wl('</ClCompile>')
		wl('<Link>')
		export.indent()
			wl('<SubSystem>Console</SubSystem>')
			wl('<GenerateDebugInformation>true</GenerateDebugInformation>')
		export.outdent()
		wl('</Link>')
	export.outdent()
	wl('</ItemDefinitionGroup>')
	wl('<ItemDefinitionGroup Condition="\'$(Configuration)|$(Platform)\'==\'Release|Win32\'">')
	export.indent()
		wl('<ClCompile>')
		export.indent()
			wl('<PrecompiledHeader>NotUsing</PrecompiledHeader>')
			wl('<WarningLevel>Level3</WarningLevel>')
			wl('<PreprocessorDefinitions>NDEBUG;%%(PreprocessorDefinitions)</PreprocessorDefinitions>')
			wl('<Optimization>MinSpace</Optimization>')
			wl('<FunctionLevelLinking>true</FunctionLevelLinking>')
			wl('<IntrinsicFunctions>true</IntrinsicFunctions>')
			wl('<MinimalRebuild>false</MinimalRebuild>')
			wl('<StringPooling>true</StringPooling>')
		export.outdent()
		wl('</ClCompile>')
		wl('<Link>')
		export.indent()
			wl('<SubSystem>Console</SubSystem>')
			wl('<EnableCOMDATFolding>true</EnableCOMDATFolding>')
			wl('<OptimizeReferences>true</OptimizeReferences>')
		export.outdent()
		wl('</Link>')
	export.outdent()
	wl('</ItemDefinitionGroup>')
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


return vcxproj
