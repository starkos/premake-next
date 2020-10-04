---
-- A unit testing framework for Premake/Lua.
---

local options = require('options')
local p = require('premake')
local path = require('path')
local terminal = require('terminal')

local m = {}

local _allowedTestPatterns = {}
local _suites = {}
local _onBeforeTestCallbacks = {}
local _onAfterTestCallbacks = {}

local _isVerbose


-- Formatted, colored output
local INFO = terminal.systemColor
local GREEN = terminal.lightGreen
local RED = terminal.red


local function _log(color, label, format, ...)
	if color then
		terminal.printColor(color, label)
		printf(format, ...)
	else
		print()
	end
end


local function _logVerbose(color, label, format, ...)
	if _isVerbose then
		_log(color, label, format, ...)
	end
end


-- Test failure handler
local function _failureHandler(err)
	local msg = err

	-- if the error doesn't include a stack trace, add one
	if not msg:find('stack traceback:', 1, true) then
		msg = debug.traceback(err, 2)
	end

	-- trim off the trailing context of the originating xpcall
	local i = msg:find("[C]: in function 'xpcall'", 1, true)
	if i then
		msg = msg:sub(1, i - 3)
	end

	-- if the resulting stack trace is only one level deep, ignore it
	local n = select(2, msg:gsub('\n', '\n'))
	if n == 2 then
		msg = msg:sub(1, msg:find('\n', 1, true) - 1)
	end

	return msg
end


function m.runTests()
	_isVerbose = options.isSet('--verbose')

	m.loadAllTests()
	m.parseAllowedTestPatterns()

	local totalSuites = 0
	local totalTests = 0
	local startTime = os.clock()

	local failedTests = {}

	for suiteName in pairs(_suites) do
		local tests = m.collectTestsForSuite(suiteName)
		if #tests > 0 then
		   local passed, failed = m.runTestSuite(suiteName, tests, failedTests)
		   totalSuites = totalSuites + 1
		   totalTests = totalTests + #tests
		end
	end

	local totalPassed = totalTests - #failedTests
	local totalFailed = #failedTests
	local elapsedTime = (os.clock() - startTime) * 1000

	_logVerbose(GREEN, '[==========]', ' %d tests from %d test suites', totalTests, totalSuites)
	_logVerbose(GREEN, '[  PASSED  ]', ' %d tests', totalPassed)
	if totalFailed > 0 then
		_logVerbose(RED, '[  FAILED  ]', ' %d tests, listed below:', totalFailed)
		for i = 1, totalFailed do
			_logVerbose(RED, '[  FAILED  ]', ' %s', failedTests[i])
		end
	end
	_logVerbose()

	printf('%d passed, %d failed (%.0f ms total)', totalPassed, totalFailed, elapsedTime)

	if totalFailed > 0 then
		os.exit(5)
	end
end


function m.loadAllTests()
	local suites = os.matchFiles(path.join(_PREMAKE.MAIN_SCRIPT_DIR, '**', 'test_*.lua'))
	for i = 1, #suites do
		dofile(suites[i])
	end
end


function m.parseAllowedTestPatterns()
	_allowedTestPatterns = {}

	local testOnly = options.valueOf('--test-only')

	local patterns = string.split(testOnly, ',')

	for i = 1, #patterns do
		local pattern = patterns[i]

		-- if there is no '.', assume it's a suite name
		if not string.contains(pattern, '.') then
			pattern = pattern .. '%.*'
		end

		-- expand '*'
		pattern = string.patternFromWildcards(pattern)

		table.insert(_allowedTestPatterns, pattern)
	end
end


function m.collectTestsForSuite(suiteName)
	local tests = {}

	for testName in pairs(_suites[suiteName]) do
		if m.isValidTest(suiteName, testName) and m.isAllowedTest(suiteName, testName) then
			table.insert(tests, testName)
		end
	end

	return tests
end


function m.runTestSuite(suiteName, testNames, failedTests)
	local totalPassed = 0
	local totalFailed = 0
	local startTime = os.clock()

	_logVerbose(GREEN, '[----------]', ' %d tests from %s', #testNames, suiteName)

	for i = 1, #testNames do
		if m.runIndividualTest(suiteName, testNames[i]) then
			totalPassed = totalPassed + 1
		else
			totalFailed = totalFailed + 1
			table.insert(failedTests, testNames[i])
		end
	end

	local elapsedTime = (os.clock() - startTime) * 1000
	_logVerbose(GREEN, '[----------]', ' %d tests from %s (%.0f ms total)', #testNames, suiteName, elapsedTime)
	_logVerbose()

	return totalPassed, totalFailed
end


function m.runIndividualTest(suiteName, testName)
	_logVerbose(GREEN, '[ RUN      ]', ' %s.%s', suiteName, testName)
	local startTime = os.clock()

	local suite = _suites[suiteName]
	_SCRIPT_DIR = suite._SCRIPT_DIR

	local ok, err = m.runSuiteSetup(suiteName)

	if ok then
		p.capture(function()
			ok, err = xpcall(suite[testName], _failureHandler)
		end)
	end

	local teardownOk, teardownErr = m.runSuiteTeardown(suiteName)

	ok = ok and teardownOk
	err = err or teardownErr

	local elapsedTime = (os.clock() - startTime) * 1000

	if _isVerbose then
		if ok then
			_logVerbose(GREEN, '[       OK ]', ' %s.%s (%.0f ms)', suiteName, testName, elapsedTime)
		else
			_logVerbose(RED, '[  FAILED  ]', ' %s.%s (%.0f ms)', suiteName, testName, elapsedTime)
		end
	elseif not ok then
		_log(RED, '[FAILED]', ' %s.%s', suiteName, testName)
	end

	if not ok then
		print(err)
	end

	return ok
end


function m.runSuiteSetup(suiteName)
	for i = 1, #_onBeforeTestCallbacks do
		local callback = _onBeforeTestCallbacks[i]
		-- _SCRIPT_DIR = callback._SCRIPT_DIR
		callback()
	end

	local suite = _suites[suiteName]
	_SCRIPT_DIR = suite._SCRIPT_DIR

	if type(suite.setup) == 'function' then
		return xpcall(suite.setup, _failureHandler)
	else
		return true
	end
end


function m.runSuiteTeardown(suiteName)
	local ok, err

	local suite = _suites[suiteName]
	_SCRIPT_DIR = suite._SCRIPT_DIR

	if type(suite.teardown) == 'function' then
		ok, err = xpcall(suite.teardown, _failureHandler)
	else
		ok = true
	end

	for i = #_onAfterTestCallbacks, 1, -1 do
		local callback = _onAfterTestCallbacks[i]
		-- _SCRIPT_DIR = callbacks._SCRIPT_DIR
		callback()
	end

	return ok, err
end


function m.declare(suiteName)
	if _suites[suiteName] then
		error(string.format('Duplicate test suite `%s`', suiteName), 2)
	end

	local tests = {}

	-- duplicate test detector
	local suite = setmetatable({}, {
		__index = tests,
		__newindex = function(table, testName, testFunc)
			if tests[testName] ~= nil then
				error(string.format('Duplicate test "%s"', testName), 2)
			end
			tests[testName] = testFunc
		end,
		__pairs = function (table)
			return pairs(tests)
		end,
		__ipairs = function (table)
			return ipairs(tests)
		end
	})

	suite._SCRIPT_DIR = _SCRIPT_DIR

	_suites[suiteName] = suite
	return suite
end


function m.isAllowedTest(suiteName, testName)
	local fullTestName = string.format('%s.%s', suiteName, testName)

	for i = 1, #_allowedTestPatterns do
		if string.match(fullTestName, _allowedTestPatterns[i]) == fullTestName then
			return true
		end
	end

	return false
end


function m.isValidTest(suiteName, testName)
	local test = _suites[suiteName][testName]
	return type(test) == 'function' and testName ~= 'setup' and testName ~= 'teardown'
end


function m.onBeforeTest(fn)
	table.insert(_onBeforeTestCallbacks, fn)
end


function m.onAfterTest(fn)
	table.insert(_onAfterTestCallbacks, fn)
end


doFile('assertions.lua', m)
doFile('stubs.lua', m)

return m
