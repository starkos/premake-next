local os = require('os')

local suite = test.declare('os')

local _cwd

function suite.setup()
	_cwd = os.getCwd()
	os.chdir(_SCRIPT_DIR)
end

function suite.teardown()
	os.chdir(_cwd)
end


-- os.isFile() --

function suite.isFile_isTrue_onExistingFile()
	test.isTrue(os.isFile('test_os.lua'))
end

function suite.isFile_isFalse_onNoSuchFile()
	test.isFalse(os.isFile('no_such_file.lua'))
end
