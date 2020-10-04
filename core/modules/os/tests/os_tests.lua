local os = require('os')

local OsTests = test.declare('OsTests')

local _cwd

function OsTests.setup()
	_cwd = os.getCwd()
	os.chdir(_SCRIPT_DIR)
end

function OsTests.teardown()
	os.chdir(_cwd)
end


-- os.isFile() --

function OsTests.isFile_isTrue_onExistingFile()
	test.isTrue(os.isFile('os_tests.lua'))
end

function OsTests.isFile_isFalse_onNoSuchFile()
	test.isFalse(os.isFile('no_such_file.lua'))
end
