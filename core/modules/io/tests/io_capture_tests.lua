local IOCaptureTests = test.declare('IOCaptureTests', 'io')


function IOCaptureTests.capture_capturesDefaultOutput()
	local result = io.capture(function()
		io.write('to default output')
	end)
	test.isEqual('to default output', result)
end


function IOCaptureTests.capture_stderr()
	local result = io.stderr:capture(function()
		io.stderr:write('to stderr')
	end)
	test.isEqual('to stderr', result)
end


function IOCaptureTests.capture_stdout()
	local result = io.stdout:capture(function()
		io.stdout:write('to stdout')
	end)
	test.isEqual('to stdout', result)
end


function IOCaptureTests.captured_returnsCurrentCapture()
	local result
	io.capture(function()
		io.write('before')
		result = io.captured()
		io.write('after')
	end)
	test.isEqual('before', result)
end
