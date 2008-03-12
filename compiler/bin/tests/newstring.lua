require('class')

--- Lua String
class "String"

function String:initialize(s) 
	self.__s = s;
end

function String:charAt(p)
	return string.byte(self.__s,p); 
end

function String:trim()
	print("String:trim",self.__s)
	return (String(self.__s:gsub("^%s*(.-)%s*$", "%1")))
end

function String:__tostring__()
  return self.__s
end


class "lua.Lib"

function lua.Lib:initialize(s)
	self.__s = s
end

function lua.Lib:charAt(p)
	return string.byte(self.__s,p); 
end


b = String("    another string  ");
s = String("  well hello there")
print("s.__s", s.__s)
print("b.__s",b.__s)
print("s:trim()", s:trim())
print(b:trim())
print(b:charAt(1))
print(b:trim():charAt(1))

print(b.trim)
function b:trim()
	return(String("gotcha")) 
end 

print(b.trim)
s = b:trim();
print(s)

b = lua.Lib("       lua.Lib test");
print(b:trim())
