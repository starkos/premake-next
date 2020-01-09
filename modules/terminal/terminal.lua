---
-- Terminal colored output support.
---

local m = _PREMAKE.terminal

m._colorStack = {}

m.black = 0
m.blue = 1
m.green = 2
m.cyan = 3
m.red = 4
m.purple = 5
m.brown = 6
m.lightGray = 7
m.gray = 8
m.lightBlue  = 9
m.lightGreen = 10
m.lightCyan = 11
m.lightRed = 12
m.magenta = 13
m.yellow = 14
m.white = 15

m.warningColor = m.magenta
m.errorColor = m.lightRed
m.infoColor = m.lightCyan


function m.pushColor(color)
	local previousColor = m.getTextColor()
	table.insert(m._colorStack, previousColor)
	m.setTextColor(color)
end


function m.popColor()
	if #m._colorStack > 0 then
		local previousColor = table.remove(m._colorStack)
		m.setTextColor(previousColor)
	end
end


return m
