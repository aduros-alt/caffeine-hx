--- Lua String
lua = {}
lua.String = {__s = " default string val "}

function lua.String:new (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function lua.String:__construct__ (s)
	local a = lua.String:new()
	a.__s = s
	return a
end

function lua.String:charAt(p)
	return string.byte(self.__s,p); 
end

function lua.String:trim()
	print(self.__s)
	return (lua.String:__construct__(self.__s:gsub("^%s*(.-)%s*$", "%1")))
end


b = lua.String:__construct__("    another string  ");
s = lua.String:__construct__("  well hello there")
print(s.__s)
print(b.__s)
print(s:trim())
print(b:trim())
print(b:charAt(1))
print(b:trim():charAt(1))
function b.trim()
	return(lua.String:__construct__("gotcha")) 
end 
print(b.charAt)
print(b.trim)
s = b:trim();
print(s)
