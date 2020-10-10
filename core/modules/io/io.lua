---
-- Overrides and extensions to Lua's `io` library.
---

local Buffer = require('buffer')
local path = require('path')

local _io_open = io.open
local _io_write = io.write

local SCOPE_IO = 1
local SCOPE_FILE = 2

-- because `write()` gets called a lot, replace with a tailored version for performance
local _capturingWriters = {
	[SCOPE_IO] = function (...)
		Buffer.write(io._captureBuffer, ...)
	end,
	[SCOPE_FILE] = function (self, ...)
		Buffer.write(self._captureBuffer, ...)
	end
}


---
-- Capture output. Use `SCOPE_IO` if capturing `io.write()`, and `SCOPE_FILE`
-- if capturing `io.output()`.
---

local function _capture(self, fn, scope)
	local oldBuffer = self._captureBuffer
	self._captureBuffer = Buffer.new()

	local oldWrite = self.write
	self.write = _capturingWriters[scope]

	fn()
	local result = Buffer.close(self._captureBuffer)

	self.write = oldWrite
	self._captureBuffer = oldBuffer
	return result
end

local function _captured(self)
	if self._captureBuffer then
		return Buffer.toString(self._captureBuffer)
	else
		return ''
	end
end


-- Replace built-in stdout/stderr with something I can mutate
local function _shim(file)
	return {
		capture = function(self, fn)
			return _capture(self, fn, SCOPE_FILE)
		end,
		captured = function(self)
			return _captured(self)
		end,
		close = function(self, ...)
			return file:close(...)
		end,
		flush = function(self, ...)
			return file:flush(...)
		end,
		lines = function(self, ...)
			return file:lines(...)
		end,
		read = function(self, ...)
			return file:read(...)
		end,
		seek = function(self, ...)
			return file:seek(...)
		end,
		setvbuf = function(self, ...)
			return file:setvbuf(...)
		end,
		write = function(self, ...)
			return file:write(...)
		end
	}
end

io.stderr = _shim(io.stderr)
io.stdout = _shim(io.stdout)


---
-- Capture contents of the default output. Use `io.stdout:capture()` or
-- `io.stderr:capture()` to capture those built-in streams.
---

io.capture = function(fn)
	return _capture(io, fn, SCOPE_IO)
end


---
-- Return the current contents of an in-progress capture.
---

function io.captured()
	return _captured(io)
end


---
-- Replacement `io.open()` which creates any missing subdirectories if the
-- the file path being opened is set to writeable.
---

function io.open(filename, mode)
	if mode and (string.contains(mode, 'w') or string.contains(mode, 'a')) then
		local dir = path.getDirectory(filename)
		local ok, err = os.mkdir(dir)
		if not ok then
			error(err, 0)
		end
	end
	return _io_open(filename, mode)
end


function io.writeln(format, ...)
	local msg = string.format(format, ...)
	io.write(msg)
	io.write('\n')
end


return io
