--[[
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
--]]

module ("Haxe", package.seeall)
require "Array"
require "std"
require "HLLString"

Array.__name__ = Array:new({"Array"});
Array.__class__ = Array;

debug = false;

--[[
<fponticelli> that is a very difficult journey ... and stressfull ... every time you think that a piece fits its place ... a new unexpected one appears...
--]]

local __classes__ = {}

function dprint(...)
	if debug then
		_G.print(unpack(arg))
	end
end
function instanceof(o, cl, superCheck)
	dprint("Haxe:instanceof")
	if ((type(o) ~= "table") or (o.__name__ == nil)) then
		throw "o is not a class"
	end;
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
	dprint("Haxe:hasOwnProperty ".. o.__name__.." field :".. s)
	if(type(o) ~= "table") then	throw "Object is not a table" end;
	if(type(s) ~= "string") then
		print("Haxe.hasOwnProperty: warning: s is '"..type(s).."' not a string")
		do return false end;
	end

	--
	-- Anonymous Object
	if(o.__class__ == nil) then
		--do return tableKeysArray(o) end;
		if(o[s] ~= nil) then
			do return true end
		else
			do return false end
		end
	end;

	--
	-- Handle Classes
	if(not isInstance(o)) then
		dprint("---- is not instance "..o.__name__)
		-- true only if it is a static property of the class object
		-- and does not account for inherited statics.
		if s == 'prototype' and o.prototype ~= nil then do return true end end
		if s == '__statics__' and o.__statics__ ~= nil then do return true end end
		for k in pairs(o.__statics__) do
			if( k == s ) then do return true end end;
		end
		-- if(o[s] == nil) then do return false end end;
		do return false end;
	end

	dprint("---- is instance ----")
-- 	-- field doesn't exist at all?
-- 	if(o[s] == nil) then do
-- 		return false end
-- 	end;

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
function fieldType(o, s, follow, n)
	if(n == nil) then n = 1 else n = n + 1 end
    if n > 40 then throw "recursion error" end
	dprint("Haxe:fieldType")
	if(s == "prototype") then
		do return "none","none" end
	end
	if o.prototype then
		for k in pairs(o.prototype) do
			if( k == s ) then
				if(type(o.prototype[s]) == "function") then
					do return "prototype","method" end
				end;
				do return "prototype","object" end;
			end;
		end
	end
	if o.statics then
		for k in pairs(o.statics) do
			if( k == s ) then
				if(type(o.__statics__[s]) == "function") then
					do return "static","method" end
				end;
				do return "static","object" end;
			end;
		end
	end
	for k in pairs(o) do
		if( k == s ) then
			if(type(o[s]) == "function") then
				do return "dynamic","method" end
			end;
			do return "dynamic","object" end;
		end;
	end
	if (follow and o.__super__ ~= nil and o.__super__ ~= o) then
		do return fieldType(o.__super__,s,true,n) end;
	end
	return "none","none";
end

--
-- Finds a function on an object, class or anon, and returns the type.
-- The func param is an actual function pointer reference.
-- Returns accesstype = "prototype" | "static" | "dynamic" | "none"
function findMethodByRef(o,func,follow)
	dprint("Haxe:findMethodByRef")
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

	if follow and o.__super__ ~= nil then
		do return findMethodByRef(o.__super__, func, true) end
	end
	return "none"
end

--
-- Create an Array from the keys of a table
--
function tableKeysArray(o)
	dprint("Haxe:tableKeysArray")
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
	dprint("Haxe:isInstance")
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
	dprint("Haxe:getQualifiedClassName")
	if(o == nil) then do return nil end end;
	if(type(o) == "string") then do return "String" end;
	elseif (type(o) == "number") then do return "Number" end;
	elseif (type(o) == "boolean") then do return "Boolean" end;
	elseif (type(o) ~= "table") then do return nil end;
	end
	if(o.__name__ == nil) then
		if(type(o) == "table") then
			do return nil end;
		elseif(type(o) == "string") then
			do return "String" end;
		end;
		--print("getQualifiedClassName: warning: o is not a class, object or string");
		do return nil end;
	end;
	if(not instanceof(o.__name__, Array)) then
		--if(o.__name__[1] == "Array" and o.__name__[0] == nil) then
		--	do return "Array" end
		--end
		print("getQualifiedClassName: warning: __name__ field '"..o.__name__.."'is not an array");
		do return nil end;
	end;
	return o.__name__:join(".");
end

--[[
	Call a method on the specified object.
	@param o Any table
	@param func a function reference, or a string of the function name
	@param args list of arguments
--]]
function callMethod(o, func, args)
	dprint("Haxe:callMethod")
	local functype;
	local fieldtype;

	if type(func) == "function" then
		functype = findMethodByRef(o, func, true)
	elseif type(func) == "string" then
		functype,fieldtype = fieldType(o, func, true)
		if fieldtype ~= "method" then
			throw ("callMethod: field "..func.." is not a function:"..functype..","..fieldtype)
		end
		func = o[func]
	else
		throw ("callMethod: invalid function type "..type(func))
	end;

	if (functype == "none") then
		do throw "method does not exist" end;
	end

	local ap;
	if args == nil then
		ap = {}
	elseif args.__name__ ~= nil then -- is Array
		ap = args:pack()
	else
		ap = args
	end

	if(functype == "prototype") then
		table.insert(ap,1,o)
	end
	return func(unpack(ap))
end

function luaError(s)
	--dprint("luaError", s);
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
	dprint("Haxe:resolveClass")
	return __classes__[name]
end

function closure(o, fname)
	dprint("Haxe:closure")
	local m = o[fname]
	if (m == nil) or (type(m) ~= "function") then
		do return nil end;
	end
	local f = function(...)
		return o[fname](o,...)
	end
	return f;
end

--
-- Haxe hashes have the value stored in a table
-- with 'v' the only field set.
function iterator_hash(o)
	dprint("Haxe:iterator_hash")
	local t = {}
	local tbl = table_clone(o)
	local p = pairs(tbl)
	local idx, curvalue = next(tbl)
	t.hasNext = function()
		return curvalue ~= nil
	end
	t.next = function()
		local rv = curvalue
		if curvalue ~= nil then
			idx,curvalue = next(tbl,idx)
		end
		return rv.v
	end
	return t
end

--
-- Iterator over hash keys.
-- Regular Hashes keys are preceeded by $ to allow for
-- null to be a key.
function iterator_hash_keys(o,isIntHash)
	dprint("Haxe:iterator_hash_keys")
	local iih = isIntHash
	local t = {}
	local tbl = {}
	for k,v in pairs(o) do
		table.insert(tbl, k);
	end
	local p = pairs(tbl)
	local idx, curvalue = next(tbl)
	t.hasNext = function()
		return curvalue ~= nil
	end
	t.next = function()
		local rv = curvalue
		if curvalue ~= nil then
			idx,curvalue = next(tbl,idx)
		end
		if not iih then do return string.sub(rv,2) end end
		return rv
	end
	return t
end


function parseFloat(v)
	dprint("Haxe:parseFloat")
	local n = _G.tonumber(v);
	if (n == nil) then
		do return math.NaN end
	end
	return n
end

function parseInt(v)
	dprint("Haxe:parseInt")
	local n = _G.tonumber(v);
	if n == nil then do return math.NaN end end
	if n > 0 then
		n = math.floor(n)
	else
		n = math.ceil(n)
	end
	return n
end

function table_clone(t)
	dprint("Haxe:table_clone")
	local tbl = setmetatable ({}, getmetatable (t))
	for k,v in pairs(t) do
		tbl[k] = v;
	end
	return tbl
end

function fields(o, ff)
	local f = ff or {}
	local inst = isInstance(o);
	local incFunc = false;
	if o.__class__ == nil then
		inst = true;
		incFunc = true;
	end
	-- static functions and vars only from class, not superclass
	if not inst then
		if hasOwnProperty(o, "__statics__") then
			for k,v in pairs(o.__statics__) do
				f[k] = true;
			end
		end
		f["__super__"] = o.__super__;
		f["__name__"] = o.__name__;
		do return f end
	end
	for k,v in pairs(o) do
		if incFunc or type(v) ~= 'function' then f[k] = true end
	end
	if type(o.prototype) == 'table' then
		for k,v in pairs(o.prototype) do
			if incFunc or type(v) ~= 'function' then f[k] = true end
		end
	end

	if inst and not incFunc and type(o.__super__) == 'table' then
		f = fields(o.__super__:__construct__(), f)
	end
	f["__name__"] = nil
	f["this"] = nil;
	return f
end
