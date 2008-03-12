--- Lua String
String = {}

function String:__construct__ (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function String:new (s)
	local a = String:__construct__()
	a.__s = s
	return a
end

function String:charAt(p)
	return string.byte(self.__s,p); 
end

function String:trim()
	print("String:trim()",self.__s)
	return (String:new(self.__s:gsub("^%s*(.-)%s*$", "%1")))
end

function String:__tostring()
	return self.__s
end

function String.print(s)
	print(s)
end






b = String:new("    another string  ");
s = String:new("  well hello there")
print(s.__s)
print(b.__s)
print(s:trim())
print(b:trim())
print(b:charAt(1))
print(b:trim():charAt(1))
function b.trim()
	return(String:new("gotcha")) 
end 
print(b.charAt)
print(b.trim)
print("Should be gotcha", b:trim());
String.print("Hello")
b.print("Hello from b")
