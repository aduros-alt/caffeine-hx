--- Lua String
String = {}
String.__index = String

function String.charAt(p)
	return string.byte(self.__s,p); 
end

function String.trim()
print(this)
	return __s
--	return (String.new(self.__s:gsub("^%s*(.-)%s*$", "%1")))
end

function String.new (s)
	local o = o or {}
	setmetatable(o, String)
--	String.__index = String
	mt = getmetatable(o)
--print("index", mt.__index)
--	setmetatable(o, mt)
--print("index", mt.__index)
--	String.__construct__(o, s);
	o.this = o
	o.__s = s
	return o
end

b = String.new("    another string  ");
s = String.new("  well hello there")
print(s.__s)
print("s.this.__s", s.this.__s)
print(b.__s)
--print("s:trim",s:trim())
print("b.trim",b.trim())

