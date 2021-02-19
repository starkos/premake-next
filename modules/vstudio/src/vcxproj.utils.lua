local array = require('array')
local path = require('path')
local tree = require('tree')

local vstudio = select(1, ...)
local vcxproj = vstudio.vcxproj

local utils = {}


---
-- Builds a source tree hierarchy applying any virtual paths.
---

function utils.buildVirtualSourceTree(prj)
	local sourceTree = tree.new()

	local allFiles = prj.allSourceFiles
	for i = 1, #allFiles do
		local filePath = path.getRelative(prj.baseDirectory, allFiles[i])
		-- TODO: virtual paths, generated files...
		tree.add(sourceTree, filePath)
	end

	tree.sort(sourceTree)
	return sourceTree
end


---
-- VS expects all source files to be specified at the project level, even those which
-- are specific to only a subset of the configurations. Collect all files across all
-- configurations and associate with the project
---

function utils.collectAllSourceFiles(prj)
	local allFiles = array.copy(prj.files)

	for i = 1, #prj.configs do
		allFiles = array.appendArrays(allFiles, prj.configs[i].files)
	end

	return allFiles
end


---
-- Sort project source files into target tool categories, e.g. `ClCompile`, `ClInclude`. See
-- `vcxproj.categories` table in `vcxproj.lua`.
---

function utils.categorizeSourceFiles(prj)
	local categorizedFiles = {}

	-- create empty lists for each category
	local categories = vcxproj.categories
	for ci = 1, #categories do
		categorizedFiles[ci] = {}
	end

	for fi = 1, #prj.allSourceFiles do
		local file = prj.allSourceFiles[fi]
		for ci = 1, #categories do
			local category = categories[ci]
			if category.match(file) then
				table.insert(categorizedFiles[ci], file)
				break
			end
		end
	end

	return categorizedFiles
end


return utils
