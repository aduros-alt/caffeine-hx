module ("Haxe", package.seeall)
require "Array"
require "HLLString"
--require "std"

local __classes__ = {}

function instanceof(o, cl, superCheck)
--print("Haxe:instanceof")
	if ((type(o) ~= "table") or (o.__name__ == nil)) then throw "o is not a class" end;
	if (not superCheck) and (not isInstance(o)) then do return false end end;
	if ((type(cl) ~= "table") or (not cl.__name__) ) then
		throw "cl is not a class"
	end

	if(o.__name__ == cl.__name__) then
		do return true end
	end

	if(o.__interfaces__ ~= nil) then
		for k, v in pairs(o.__interfaces__) do
			if(v == cl) then do return true end end;
		end
	end

	if(o.__super__ ~= nil) then
		do return instanceof(o.__super__, cl, true); end;
	end

	return false
end


--
-- Returns true if class object 'o' has field string 's'
-- Follows the same style as ActionScript 3.
--
function hasOwnProperty(o, s)
	if(type(o) ~= "table") then	throw "Object is not a table" end;
	if(type(s) ~= "string") then
		print("Haxe.hasOwnProperty: warning: s is '"..type(s).."' not a string")
		do return false end;
	end
	-- field doesn't exist at all?
	if(o[s] == nil) then do return false end end;

	--
	-- Anonymous Object
	if(o.__class__ == nil) then
		do return tableKeys(o) end;
	end;

	--
	-- Handle Classes
	if(not isInstance(o)) then
		-- true only if it is a static property of the class object
		-- and does not account for inherited statics.
		for k in pairs(o.prototype) do
			if( k == s ) then do return false end end;
		end
		if(o[s] == nil) then do return false end end;
		do return true end;
	end

	--
	-- Instances
	local a; local f;
	a, f = fieldType(o,s,true);
	if(a == "none" or a == "static") then
		do return false end;
	end
	-- dynamic only if from this instance
	if(a == "dynamic") then
		if(o[s] == nil) then do return false end end;
	end
	return true;
end

--
-- Determines the field type of field 's' on object 'o'. If
-- 'follow' is true, the superclass chain will be followed.
-- returns: accesstype, fieldtype where
-- accesstype = "prototype" | "static" | "dynamic" | "none"
-- fieldtype = "function" | "object" | "none"
function fieldType(o, s, follow)
	for k in pairs(o.prototype) do
		if( k == s ) then
			if(type(o.prototype[s]) == "function") then
				do return "prototype","method" end
			end;
			do return "prototype","object" end;
		end;
	end
	for k in pairs(o.statics) do
		if( k == s ) then
			if(type(o.__statics__[s]) == "function") then
				do return "static","method" end
			end;
			do return "static","object" end;
		end;
	end
	for k in pairs(o) do
		if( k == s ) then
			if(type(o[s]) == "function") then
				do return "dynamic","method" end
			end;
			do return "dynamic","object" end;
		end;
	end
	if (follow and o.__super__ ~= nil) then
		do return fieldType(o,s,true) end;
	end
	return "none","none";
end

--
-- Finds a function on an object, class or anon, and returns the type.
-- The func param is an actual function pointer reference.
-- Returns type = "prototype" | "static" | "dynamic" | "none"
function findMethodByRef(o,func)
	-- anon object, must be a static
	if(o.__name__ == nil) then
		do return "static" end
	end
	for k,v in pairs(o.prototype) do
		if(func == v) then
			do return "prototype" end;
		end
	end
	for k,v in pairs(o.__statics__) do
		if(func == v) then
			do return "static" end;
		end
	end
	for k,v in pairs(o) do
		if(type(v) == "function" and v == func) then
			do return "dynamic" end
		end
	end
	return "none"
end

--
-- Create an array from the keys of a table
--
function tableKeys(o)
	local a = Array:new();
	if(type(o) ~= "table") then
		do return a end
	end;
	for k in pairs(o) do
		a:push(k);
	end
	return a;
end

--
-- Returns true if object o is a class instance
-- Classes have the __class__ field set, which does not show
-- up in the pairs() of an instance, but is available if referenced
-- directly, since the __index metaevent will fire and call the Class
-- field.
--
function isInstance(o)
	if(type(o) ~= "table") then do return false end end;
	for k in pairs(o) do
		if k=="__class__" then do return false end end;
	end
	if(o.__class__ ~= nil) then do return true end end;
	return false;
end;

-- Classes satisfy both Lua and Haxe style naming
--__name__=[syntax,AnonymousObject],_NAME=syntax.AnonymousObject,_PACKAGE=syntax.
--
function getQualifiedClassName(o)
	if(o == nil) then do return "" end end;
	if(type(o) == "string") then do return "String" end;
	elseif (type(o) == "number") then do return "Number" end;
	elseif (type(o) == "boolean") then do return "Boolean" end;
	elseif (type(o) ~= "table") then do return "" end;
	end
	if(o.__name__ == nil) then
		if(type(o) == "table") then
			do return "Object" end;
		elseif(type(o) == "string") then
			do return "String" end;
		end;
		print("getQualifiedClassName: warning: o is not a class, object or string");
		do return "" end;
	end;
	if(not instanceof(o.__name__, Array)) then
		if(o.__name__[1] == "Array" and o.__name__[0] == nil) then
			do return "Array" end
		end
		print("getQualifiedClassName: warning: __name__ field '"..o.__name__.."'is not an array");
		do return "" end;
	end;
	return o.__name__:join(".");
end

function callMethod(o, func, args)
	local ftype = findMethodByRef(o, func);
--print("Function type: "..ftype);
	while(ftype == "none" and o.__super__ ~= nil) do
		o = o.__super__;
		ftype = findMethodByRef(o, func);
	end
	if (ftype == "none") then
		do throw "method does not exist" end;
	end

	if(args == nil) then
		args = Array:new();
	end
	if(ftype == "prototype") then
		args:unshift(o);
	end
	local ap = args:pack();
	func(unpack(ap))
	if(ftype == "prototype") then
		args:shift();
	end
end

function luaError(s)
--print("luaError", s);
	local err = {};
	local serr = "";
	if(s == nil) then
		s = "unknown error";
	end
	if(type(s) == "function") then
		return {error="function", callinfo="???"};
	elseif type(s) == "table" then
		serr = tostring(s);
	else
		serr = tostring(s);
	end
	local p = string.find(serr,"\n",1,true);
	if(p == nil) then
		err.error = serr
		err.callinfo = serr
	else
		err.error = string.sub(serr,1,p-1)
		err.callinfo = string.sub(serr,p+1) or ""
	end
	err.error = "luaError: " .. err.error;
	--err.error = err.error.." ["..err.callinfo.."]";
	return err
end

function resolveClass (name)
	return __classes__[name]
end

function closure(o, fname)
	local m = o[fname]
	if (m == nil) or (type(m) ~= "function") then
		do return nil end;
	end
	local f = function(...)
		return o[fname](o,...)
	end
	return f;
end
