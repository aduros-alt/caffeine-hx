--- Lua String
lua = {}
lua.String = {}

function lua.String:__construct__ (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function lua.String:new (s)
	local a = lua.String:__construct__()
	a.__s = s
	return a
end

function lua.String:charAt(p)
	return string.byte(self.__s,p); 
end

function lua.String:trim()
	print("lua.String:trim()",self.__s)
	return (lua.String:new(self.__s:gsub("^%s*(.-)%s*$", "%1")))
end

function lua.String:__tostring()
	return self.__s
end

function lua.String.print(s)
	print(s)
end






b = lua.String:new("    another string  ");
s = lua.String:new("  well hello there")
print(s.__s)
print(b.__s)
print(s:trim())
print(b:trim())
print(b:charAt(1))
print(b:trim():charAt(1))
function b.trim()
	return(lua.String:new("gotcha")) 
end 
print(b.charAt)
print(b.trim)
print("Should be gotcha", b:trim());
lua.String.print("Hello")
b.print("Hello from b")
