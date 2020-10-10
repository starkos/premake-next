local IOTests = test.declare('io')


function IOTests.capture_capturesDefaultOutput()
	local result = io.capture(function()
		io.write('to default output')
	end)
	test.isEqual('to default output', result)
end


function IOTests.capture_stderr()
	local result = io.stderr:capture(function()
		io.stderr:write('to stderr')
	end)
	test.isEqual('to stderr', result)
end


function IOTests.capture_stdout()
	local result = io.stdout:capture(function()
		io.stdout:write('to stdout')
	end)
	test.isEqual('to stdout', result)
end


function IOTests.captured_returnsCurrentCapture()
	local result
	io.capture(function()
		io.write('before')
		result = io.captured()
		io.write('after')
	end)
	test.isEqual('before', result)
end


function IOTests.writeln_appensEol()
end
