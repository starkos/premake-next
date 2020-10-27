local path = require('path')

local PathPartTests = test.declare('PathPartTests', 'path')


function PathPartTests.getBaseName_onDirAndExtension()
	test.isEqual('filename', path.getBaseName('folder/filename.ext'))
end


function PathPartTests.getDirectory_onDirAndFileName()
	test.isEqual('folder/src', path.getDirectory('folder/src/filename.ext'))
end


function PathPartTests.getName_onDirAndExtension()
	test.isEqual('filename.ext', path.getName('folder/filename.ext'))
end
