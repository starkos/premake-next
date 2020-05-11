---
-- A unit testing framework for Premake/Lua.
---

local options = require('options')
local p = require('premake')
local path = require('path')
local terminal = require('terminal')

local m = {}

m._suites = {}
m._onBeforeTestCallbacks = {}
m._onAfterTestCallbacks = {}

local _isVerbose


-- Formatted, colored output
local INFO = terminal.systemColor
local GREEN = terminal.lightGreen
local RED = terminal.red

local function _logVerbose(color, label, format, ...)
	if _isVerbose then
		if color then
			terminal.printColor(color, label)
			printf(format, ...)
		else
			print()
		end
	end
end


-- Metatable to attach to suites; detects duplicate test function names
local _duplicateTestDetector = {
	__newIndex = function(table, key, value)
		if table[key] ~= nil then
			error(string.format('Duplicate test `%s`', key), 2)
		end
		table[key] = value
	end
}


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

	for suiteName in pairs(m._suites) do
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
	m._allowedTestPatterns = {}

	local testOnly = options.valueOf('--test-only')

	if not testOnly then
		table.insert(m._allowedTestPatterns, '.*')
	else
		local patterns = string.split(testOnly, ',')
		for i = 1, #patterns do
			local pattern = string.patternFromWildcards(patterns[i])
			table.insert(m._allowedTestPatterns, pattern)
		end
	end
end


function m.collectTestsForSuite(suiteName)
	local tests = {}

	for testName in pairs(m._suites[suiteName]) do
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

	local suite = m._suites[suiteName]
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

	if ok then
		_logVerbose(GREEN, '[       OK ]', ' %s.%s (%.0f ms)', suiteName, testName, elapsedTime)
	else
		_logVerbose(RED, '[  FAILED  ]', ' %s.%s (%.0f ms)', suiteName, testName, elapsedTime)
		print(err)
	end

	return ok
end


function m.runSuiteSetup(suiteName)
	local callbacks = m._onBeforeTestCallbacks

	for i = 1, #callbacks do
		_SCRIPT_DIR = callbacks._SCRIPT_DIR
		callbacks[i]()
	end

	local suite = m._suites[suiteName]
	_SCRIPT_DIR = suite._SCRIPT_DIR

	if type(suite.setup) == 'function' then
		return xpcall(suite.setup, _failureHandler)
	else
		return true
	end
end


function m.runSuiteTeardown(suiteName)
	local ok, err

	local suite = m._suites[suiteName]
	_SCRIPT_DIR = suite._SCRIPT_DIR

	if type(suite.teardown) == 'function' then
		ok, err = xpcall(suite.teardown, _failureHandler)
	else
		ok = true
	end

	local callbacks = m._onAfterTestCallbacks

	for i = #callbacks, 1, -1 do
		_SCRIPT_DIR = callbacks._SCRIPT_DIR
		callbacks[i]()
	end

	return ok, err
end


function m.declare(suiteName)
	if m._suites[suiteName] then
		error(string.format('Duplicate test suite `%s`', suiteName), 2)
	end

	local suite = {
		_SCRIPT_DIR = _SCRIPT_DIR
	}

	setmetatable(suite, _duplicateTestDetector)

	m._suites[suiteName] = suite
	return suite
end


function m.isAllowedTest(suiteName, testName)
	local fullTestName = string.format('%s.%s', suiteName, testName)

	local patterns = m._allowedTestPatterns
	for i = 1, #patterns do
		if string.match(fullTestName, patterns[i]) then
			return true
		end
	end

	return false
end


function m.isValidTest(suiteName, testName)
	local test = m._suites[suiteName][testName]
	return type(test) == 'function' and testName ~= 'setup' and testName ~= 'teardown'
end


function m.onBeforeTest(fn)
	table.insert(m._onBeforeTestCallbacks, fn)
end


function m.onAfterTest(fn)
	table.insert(m._onAfterTestCallbacks, fn)
end


doFile('assertions.lua', m)
doFile('stubs.lua', m)

return m
