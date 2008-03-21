require "Haxe";

-- Program generation
-- package create1
syntax = {};

syntax.SwitchCaseAccess = {_NAME='syntax.SwitchCaseAccess', _M=syntax.SwitchCaseAccess, _PACKAGE='syntax.',__name__= Array:new({"syntax","SwitchCaseAccess"}), prototype = {}, __statics__ ={}}
package.loaded['syntax.SwitchCaseAccess'] = syntax.SwitchCaseAccess
-- syntax.SwitchCaseAccess constructor
function syntax.SwitchCaseAccess:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = syntax.SwitchCaseAccess
	return o
end

function syntax.SwitchCaseAccess:new (p)
	local ___new =syntax.SwitchCaseAccess:__construct__();
	collectgarbage("step");
	return ___new;
end

-- package create1
lua = {};

lua.LuaString__ = {_NAME='lua.LuaString__', _M=lua.LuaString__, _PACKAGE='lua.',__name__= Array:new({"lua","LuaString__"}), prototype = {}, __statics__ ={}}
package.loaded['lua.LuaString__'] = lua.LuaString__
-- lua.LuaString__ constructor
function lua.LuaString__:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = lua.LuaString__
	return o
end

function lua.LuaString__:new (s)
	local ___new =lua.LuaString__:__construct__();
	local v = s.__tostring(); do return v; end
	return ___new;
end

lua.LuaString__.__statics__['__name__'] = "object";
-- package create1
unit = {};

unit.AssertException = {_NAME='unit.AssertException', _M=unit.AssertException, _PACKAGE='unit.',__name__= Array:new({"unit","AssertException"}), prototype = {}, __statics__ ={}}
package.loaded['unit.AssertException'] = unit.AssertException
-- unit.AssertException constructor
function unit.AssertException:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = unit.AssertException
	return o
end

function unit.AssertException:new (p,m)
	local ___new =unit.AssertException:__construct__();
	___new.pos = p;
	___new.message = m;
	return ___new;
end

unit.AssertException.message = nil;
unit.AssertException.prototype['message'] = "object";

unit.AssertException.pos = nil;
unit.AssertException.prototype['pos'] = "object";

ValueType = { __ename__ = {"ValueType"}, __constructs__ = {"TNull","TInt","TFloat","TBool","TObject","TFunction","TClass","TEnum","TUnknown"} };
ValueType.TBool = {"TBool",3};
ValueType.TBool.toString = tostring;
ValueType.TBool.__enum__ = ValueType;
ValueType.TClass =  function(c) ___x = {"TClass",6,c}; ___x.__enum__ = ValueType; ___x.toString = tostring; return ___x; end
ValueType.TEnum =  function(e) ___x = {"TEnum",7,e}; ___x.__enum__ = ValueType; ___x.toString = tostring; return ___x; end
ValueType.TFloat = {"TFloat",2};
ValueType.TFloat.toString = tostring;
ValueType.TFloat.__enum__ = ValueType;
ValueType.TFunction = {"TFunction",5};
ValueType.TFunction.toString = tostring;
ValueType.TFunction.__enum__ = ValueType;
ValueType.TInt = {"TInt",1};
ValueType.TInt.toString = tostring;
ValueType.TInt.__enum__ = ValueType;
ValueType.TNull = {"TNull",0};
ValueType.TNull.toString = tostring;
ValueType.TNull.__enum__ = ValueType;
ValueType.TObject = {"TObject",4};
ValueType.TObject.toString = tostring;
ValueType.TObject.__enum__ = ValueType;
ValueType.TUnknown = {"TUnknown",8};
ValueType.TUnknown.toString = tostring;
ValueType.TUnknown.__enum__ = ValueType;

Type = {_NAME='Type', _M=Type, _PACKAGE='',__name__= Array:new({"Type"}), prototype = {}, __statics__ ={}}
package.loaded['Type'] = Type
-- Type constructor
function Type:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = Type
	return o
end

function Type:new ()
	local new =Type:new()
	return new
end

Type.__statics__['toEnum'] = Type.toEnum;
function Type.toEnum (t) 
	do
		try do
			if(t.__ename__ == nil) then
				do return nil end
			end
			do return t end
		end
		catch e0 do
			if(e0.error == nil) then e0 = Haxe.luaError(e0) end
			 do
				local e = e0.error;
				collectgarbage("step")
			
			end --639;
		end --643;
		do return nil end
	end
end
Type.__statics__['toClass'] = Type.toClass;
function Type.toClass (t) 
	do
		try do
			if( not t.hasOwnProperty("prototype")) then
				do return nil end
			end
			do return t end
		end
		catch e1 do
			if(e1.error == nil) then e1 = Haxe.luaError(e1) end
			 do
				local e = e1.error;
				collectgarbage("step")
			
			end --639;
		end --643;
		do return nil end
	end
end
Type.__statics__['getClass'] = Type.getClass;
function Type.getClass (o) 
	do
		do return ((o ~= nil and o.__enum__ == nil) and (o.__class__) or (nil)) end
	end
end
Type.__statics__['getEnum'] = Type.getEnum;
function Type.getEnum (o) 
	do
		do return ((o ~= nil) and (o.__enum__) or (nil)) end
	end
end
Type.__statics__['getSuperClass'] = Type.getSuperClass;
function Type.getSuperClass (c) 
	do
		do return c.__super__ end
	end
end
Type.__statics__['getClassName'] = Type.getClassName;
function Type.getClassName (c) 
	do
		do return ((c ~= nil) and (Haxe.getQualifiedClassName(c)) or (nil)) end
	end
end
Type.__statics__['getEnumName'] = Type.getEnumName;
function Type.getEnumName (e) 
	do
		do return e.__ename__.join(".") end
	end
end
Type.__statics__['resolveClass'] = Type.resolveClass;
function Type.resolveClass (name) 
	do
		local cl;
		do
			local path = name:haxe_split(".");
			cl = (function(this) 
				local r;
				local o = lua.Boot.__classes;
				r = ((type(o) ~= "table") and (nil) or (o[path[0]]));
				return r;
			end)(self);
			local i = 1;
			while(cl ~= nil and i < path.length) do do
				cl = ((type(cl) ~= "table") and (nil) or (cl[path[i]]));
				i = i + (1);
			end end ;
			if(cl == nil or cl.__name__ == nil) then
				do return nil end
			end
		end
		do return cl end
	end
end
Type.__statics__['resolveEnum'] = Type.resolveEnum;
function Type.resolveEnum (name) 
	do
		local e;
		do
			local path = name:haxe_split(".");
			e = (function(this) 
				local r;
				local o = lua.Boot.__classes;
				r = ((type(o) ~= "table") and (nil) or (o[path[0]]));
				return r;
			end)(self);
			local i = 1;
			while(e ~= nil and i < path.length) do do
				e = ((type(e) ~= "table") and (nil) or (e[path[i]]));
				i = i + (1);
			end end ;
			if(e == nil or e.__ename__ == nil) then
				do return nil end
			end
		end
		do return e end
	end
end
Type.__statics__['createInstance'] = Type.createInstance;
function Type.createInstance (cl,args) 
	do
		if(args.length >= 6) then
			throw("Too many arguments");
		end
		do return cl:new (args[0],args[1],args[2],args[3],args[4],args[5]) end
	end
end
Type.__statics__['createEmptyInstance'] = Type.createEmptyInstance;
function Type.createEmptyInstance (cl) 
	do
		local o = cl:__construct__();
		do return o end
	end
end
Type.__statics__['getInstanceFields'] = Type.getInstanceFields;
function Type.getInstanceFields (c) 
	do
		local a = Reflect.fields(c.prototype);
		c = c.__super__;
		while(c ~= nil) do do
			a = a:concat(Reflect.fields(c.prototype));
			c = c.__super__;
		end end ;
		while(a:remove("__class__")) do collectgarbage("step") end ;
		do return a end
	end
end
Type.__statics__['getClassFields'] = Type.getClassFields;
function Type.getClassFields (c) 
	do
		local a = Reflect.fields(c);
		a:remove("__name__");
		a:remove("__interfaces__");
		a:remove("__super__");
		a:remove("__construct__");
		a:remove("prototype");
		a:remove("new");
		do return a end
	end
end
Type.__statics__['getEnumConstructs'] = Type.getEnumConstructs;
function Type.getEnumConstructs (e) 
	do
		do return e.__constructs__ end
	end
end
Type.__statics__['typeof'] = Type.typeof;
function Type.typeof (v) 
	do
		local switch = (type(v));
		if (switch =="boolean") then do
			do return ValueType.TBool end
		end
		elseif (switch == "string") then do
			do return ValueType.TClass(String) end
		end
		elseif (switch == "number") then do
			if(v + 1 == v) then
				do return ValueType.TFloat end
			end
			if(Math.ceil(v) == v) then
				do return ValueType.TInt end
			end
			do return ValueType.TFloat end
		end
		elseif (switch == "table") then do
			local e = v.__enum__;
			if(e ~= nil) then
				do return ValueType.TEnum(e) end
			end
			local c = v.__class__;
			if(c ~= nil) then
				do return ValueType.TClass(c) end
			end
			do return ValueType.TObject end
		end
		elseif (switch == "function") then do
			if(v.__name__ ~= nil) then
				do return ValueType.TObject end
			end
			do return ValueType.TFunction end
		end
		elseif (switch == "undefined") then do
			do return ValueType.TNull end
		end
		else do
			do return ValueType.TUnknown end
		end
		end -- end of switch;
		;
	end
end
Type.__statics__['enumEq'] = Type.enumEq;
function Type.enumEq (a,b) 
	do
		if(a == b) then
			do return true end
		end
		if(a[0] ~= b[0]) then
			do return false end
		end
		do
			local _g1 = 2; local _g = a.length;
			while(_g1 < _g) do do
				local i = (function() local _ = _g1; _g1 = _g1 + 1; return _; end)();
				if( not Type.enumEq(a[i],b[i])) then
					do return false end
				end
			end end ;
		end
		local e = a.__enum__;
		if(e ~= b.__enum__ or e == nil) then
			do return false end
		end
		do return true end
	end
end
Type.__statics__['enumConstructor'] = Type.enumConstructor;
function Type.enumConstructor (e) 
	do
		do return e[0] end
	end
end
Type.__statics__['enumParameters'] = Type.enumParameters;
function Type.enumParameters (e) 
	do
		do return e.slice(2) end
	end
end
Type.__statics__['enumIndex'] = Type.enumIndex;
function Type.enumIndex (e) 
	do
		do return e[1] end
	end
end

lua.LuaDate__ = {_NAME='lua.LuaDate__', _M=lua.LuaDate__, _PACKAGE='lua.',__name__= Array:new({"lua","LuaDate__"}), prototype = {}, __statics__ ={}}
package.loaded['lua.LuaDate__'] = lua.LuaDate__
-- lua.LuaDate__ constructor
function lua.LuaDate__:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = lua.LuaDate__
	return o
end

function lua.LuaDate__:new (year,month,day,hour,min,sec)
	local ___new =lua.LuaDate__:__construct__();
	___new.__t = {};
	___new.__t["year"] = year;
	___new.__t["year"] = year;
	___new.__t["month"] = month + 1;
	___new.__t["day"] = day;
	___new.__t["hour"] = hour;
	___new.__t["min"] = min;
	___new.__t["sec"] = sec;
	return ___new;
end

lua.LuaDate__.__statics__['now'] = lua.LuaDate__.now;
function lua.LuaDate__.now () 
	do
		local n = os.time();
		do return lua.LuaDate__.create(n) end
	end
end
lua.LuaDate__.__statics__['fromTime'] = lua.LuaDate__.fromTime;
function lua.LuaDate__.fromTime (t) 
	do
		t = t / (1000);
		local i1 = __dollar__int((t % 65536));
		local i2 = __dollar__int(t / 65536);
		local i = int32_add(i1,int32_shl(i2,16));
		do return lua.LuaDate__.create(i) end
	end
end
lua.LuaDate__.__statics__['fromString'] = lua.LuaDate__.fromString;
function lua.LuaDate__.fromString (s) 
	do
		do return lua.LuaDate__.create(date_new(s)) end
	end
end
lua.LuaDate__.__statics__['create'] = lua.LuaDate__.create;
function lua.LuaDate__.create (t) 
	do
		local d = lua.LuaDate__:new (2008,1,1,0,0,0);
		d.__t = t;
		do return d end
	end
end
lua.LuaDate__.__t = nil;
lua.LuaDate__.prototype['__t'] = "object";

function lua.LuaDate__:getDate () 
do
	do return __t['day'] end
end
end
lua.LuaDate__.prototype['getDate'] = lua.LuaDate__.getDate;

function lua.LuaDate__:getDay () 
do
	do return __t['wday'] - 1 end
end
end
lua.LuaDate__.prototype['getDay'] = lua.LuaDate__.getDay;

function lua.LuaDate__:getFullYear () 
do
	do return __t['year'] end
end
end
lua.LuaDate__.prototype['getFullYear'] = lua.LuaDate__.getFullYear;

function lua.LuaDate__:getHours () 
do
	do return __t['hour'] end
end
end
lua.LuaDate__.prototype['getHours'] = lua.LuaDate__.getHours;

function lua.LuaDate__:getMinutes () 
do
	do return __t['min'] end
end
end
lua.LuaDate__.prototype['getMinutes'] = lua.LuaDate__.getMinutes;

function lua.LuaDate__:getMonth () 
do
	do return __t['month'] - 1 end
end
end
lua.LuaDate__.prototype['getMonth'] = lua.LuaDate__.getMonth;

function lua.LuaDate__:getSeconds () 
do
	do return __t['sec'] end
end
end
lua.LuaDate__.prototype['getSeconds'] = lua.LuaDate__.getSeconds;

function lua.LuaDate__:getTime () 
do
	do return 1.0 end
end
end
lua.LuaDate__.prototype['getTime'] = lua.LuaDate__.getTime;

function lua.LuaDate__:toString () 
do
	do return String:new (date_format(self.__t,nil)) end
end
end
lua.LuaDate__.prototype['toString'] = lua.LuaDate__.toString;


Test = {_NAME='Test', _M=Test, _PACKAGE='',__name__= Array:new({"Test"}), prototype = {}, __statics__ ={}}
package.loaded['Test'] = Test
-- Test constructor
function Test:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = Test
	return o
end

function Test:new ()
	local new =Test:new()
	return new
end

Test.__statics__['main'] = Test.main;
function Test.main () 
	do
		local runner = unit.Runner:new ();
		runner:register(syntax.SwitchCaseAccess);
		runner:register(syntax.TypedefAccess);
		runner:register(syntax.WhileAccess);
		runner:run();
	end
end

Std = {_NAME='Std', _M=Std, _PACKAGE='',__name__= Array:new({"Std"}), prototype = {}, __statics__ ={}}
package.loaded['Std'] = Std
-- Std constructor
function Std:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = Std
	return o
end

function Std:new ()
	local new =Std:new()
	return new
end

Std.__statics__['is'] = Std.is;
function Std.is (v,t) 
	do
		do return lua.Boot.__instanceof(v,t) end
	end
end
Std.__statics__['string'] = Std.string;
function Std.string (s) 
	do
		do return lua.Boot.__string_rec(s,"") end
	end
end
Std.__statics__['int'] = Std.int;
function Std.int (x) 
	do
		if(x < 0) then
			do return Math.ceil(x) end
		end
		do return Math.floor(x) end
	end
end
Std.__statics__['bool'] = Std.bool;
function Std.bool (x) 
	do
		do return (x ~= 0 and x ~= nil and x ~= false) end
	end
end
Std.__statics__['parseInt'] = Std.parseInt;
function Std.parseInt (x) 
	do
		local preParse = function (ns) 
		do
			local neg = false;
			local s = StringTools.ltrim(ns);
			if(s:haxe_charAt(0) == "-") then
				do
					neg = true;
					s = s:haxe_substr(1,nil);
				end
				else if(s:haxe_charAt(0) == "+") then
					s = s:haxe_substr(1,nil);
				end
			end
			if( not StringTools.isNum(s,0)) then
				do return  { str = nil, neg = false } end
			end
			if( not StringTools.startsWith(s,"0x")) then
				do
					local l = s:len();
					local p = -1;
					local c = 0;
					while(c == 0 and p < l - 1) do do
						(function() local _ = p; p = p + 1; return _; end)();
						c = StringTools.num(s,p);
						if(c == nil) then
							do return nil end
						end
					end end ;
					s = s:haxe_substr(p,nil);
				end
			end
			do return  { str = s, neg = neg } end
		end
		end -- end local function decl
		;
		do return 0 end
	end
end
Std.__statics__['parseOctal'] = Std.parseOctal;
function Std.parseOctal (x) 
	do
		local neg = false;
		local n = 0;
		local s = StringTools.ltrim(x);
		local accum = 0;
		local l = s:len();
		if( not StringTools.isNum(s,0)) then
			do
				if(s:haxe_charAt(0) == "-") then
					neg = true;
					else if(s:haxe_charAt(0) == "+") then
						neg = false;
						else do return nil end
					end
				end
				(function() local _ = n; n = n + 1; return _; end)();
				if(n == s:len() or  not StringTools.isNum(s,n)) then
					do return nil end
				end
			end
		end
		while(n < l) do do
			local c = StringTools.num(s,n);
			if(c == nil) then
				break;
			end
			if(c > 7) then
				do return nil end
			end
			accum = accum << (3);
			accum = accum + (c);
			(function() local _ = n; n = n + 1; return _; end)();
		end end ;
		if(neg) then
			do return 0 - accum end
		end
		do return accum end
	end
end
Std.__statics__['parseFloat'] = Std.parseFloat;
function Std.parseFloat (x) 
	do
		do return 0 end
	end
end
Std.__statics__['chr'] = Std.chr;
function Std.chr (x) 
	do
		do return String:haxe_fromCharCode(x) end
	end
end
Std.__statics__['ord'] = Std.ord
function Std.ord (x) 
	do
		do return nil end
	end
end
Std.__statics__['random'] = Std.random;
function Std.random (x) 
	do
		do return 0 end
	end
end
Std.__statics__['resource'] = Std.resource;
function Std.resource (name) 
	do
		do return nil end
	end
end

lua.LuaMath__ = {_NAME='lua.LuaMath__', _M=lua.LuaMath__, _PACKAGE='lua.',__name__= Array:new({"lua","LuaMath__"}), prototype = {}, __statics__ ={}}
package.loaded['lua.LuaMath__'] = lua.LuaMath__
-- lua.LuaMath__ constructor
function lua.LuaMath__:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = lua.LuaMath__
	return o
end

function lua.LuaMath__:new ()
	local new =lua.LuaMath__:new()
	return new
end


StringTools = {_NAME='StringTools', _M=StringTools, _PACKAGE='',__name__= Array:new({"StringTools"}), prototype = {}, __statics__ ={}}
package.loaded['StringTools'] = StringTools
-- StringTools constructor
function StringTools:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = StringTools
	return o
end

function StringTools:new ()
	local new =StringTools:new()
	return new
end

StringTools.__statics__['urlEncode'] = StringTools.urlEncode;
function StringTools.urlEncode (s) 
	do
		do return string.urlEncode(s) end
	end
end
StringTools.__statics__['urlDecode'] = StringTools.urlDecode;
function StringTools.urlDecode (s) 
	do
		do return string.urlDecode(s) end
	end
end
StringTools.__statics__['htmlEscape'] = StringTools.htmlEscape;
function StringTools.htmlEscape (s) 
	do
		do return s:haxe_split("&"):join("&amp;"):haxe_split("<"):join("&lt;"):haxe_split(">"):join("&gt;") end
	end
end
StringTools.__statics__['htmlUnescape'] = StringTools.htmlUnescape;
function StringTools.htmlUnescape (s) 
	do
		do return s:haxe_split("&gt;"):join(">"):haxe_split("&lt;"):join("<"):haxe_split("&amp;"):join("&") end
	end
end
StringTools.__statics__['startsWith'] = StringTools.startsWith;
function StringTools.startsWith (s,start) 
	do
		do return (s:len() >= start:len() and s:haxe_substr(0,start:len()) == start) end
	end
end
StringTools.__statics__['endsWith'] = StringTools.endsWith;
function StringTools.endsWith (s,___end) 
	do
		local elen = ___end:len();
		local slen = s:len();
		do return (slen >= elen and s:haxe_substr(slen - elen,elen) == ___end) end
	end
end
StringTools.__statics__['isSpace'] = StringTools.isSpace;
function StringTools.isSpace (s,pos) 
	do
		local c = s:haxe_charCodeAt(pos);
		do return (c >= 9 and c <= 13) or c == 32 end
	end
end
StringTools.__statics__['isNum'] = StringTools.isNum;
function StringTools.isNum (s,pos) 
	do
		local c = s:haxe_charCodeAt(pos);
		do return (c >= 48 and c <= 57) end
	end
end
StringTools.__statics__['isAlpha'] = StringTools.isAlpha;
function StringTools.isAlpha (s,pos) 
	do
		local c = s:haxe_charCodeAt(pos);
		do return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) end
	end
end
StringTools.__statics__['num'] = StringTools.num;
function StringTools.num (s,pos) 
	do
		local c = s:haxe_charCodeAt(pos);
		c = c - (48);
		if(c < 0 or c > 9) then
			do return nil end
		end
		do return c end
	end
end
StringTools.__statics__['ltrim'] = StringTools.ltrim;
function StringTools.ltrim (s) 
	do
		local l = s:len();
		local r = 0;
		while(r < l and StringTools.isSpace(s,r)) do do
			(function() local _ = r; r = r + 1; return _; end)();
		end end ;
		if(r > 0) then
			do return s:haxe_substr(r,l - r) end
			else do return s end
		end
	end
end
StringTools.__statics__['rtrim'] = StringTools.rtrim;
function StringTools.rtrim (s) 
	do
		local l = s:len();
		local r = 0;
		while(r < l and StringTools.isSpace(s,l - r - 1)) do do
			(function() local _ = r; r = r + 1; return _; end)();
		end end ;
		if(r > 0) then
			do
				do return s:haxe_substr(0,l - r) end
			end
			else do
				do return s end
			end
		end
	end
end
StringTools.__statics__['trim'] = StringTools.trim;
function StringTools.trim (s) 
	do
		do return StringTools.ltrim(StringTools.rtrim(s)) end
	end
end
StringTools.__statics__['rpad'] = StringTools.rpad
function StringTools.rpad (s,c,l) 
	do
		local sl = s:len();
		local cl = c:len();
		while(sl < l) do do
			if(l - sl < cl) then
				do
					s = s + (c:haxe_substr(0,l - sl));
					sl = l;
				end
				else do
					s = s + (c);
					sl = sl + (cl);
				end
			end
		end end ;
		do return s end
	end
end
StringTools.__statics__['lpad'] = StringTools.lpad
function StringTools.lpad (s,c,l) 
	do
		local ns = "";
		local sl = s:len();
		if(sl >= l) then
			do return s end
		end
		local cl = c:len();
		while(sl < l) do do
			if(l - sl < cl) then
				do
					ns = ns + (c:haxe_substr(0,l - sl));
					sl = l;
				end
				else do
					ns = ns + (c);
					sl = sl + (cl);
				end
			end
		end end ;
		do return ns + s end
	end
end
StringTools.__statics__['replace'] = StringTools.replace;
function StringTools.replace (s,sub,by) 
	do
		do return s:haxe_split(sub):join(by) end
	end
end
StringTools.__statics__['replaceAll'] = StringTools.replaceAll;
function StringTools.replaceAll (s,sub,by) 
	do
		if(sub:len() == 0) then
			do return StringTools.replace(s,sub,by) end
		end
		local ns = s:haxe_toString();
		local olen = 0;
		local nlen = ns:len();
		while(olen ~= nlen) do do
			olen = ns:len();
			StringTools.replace(ns,sub,by);
			nlen = ns:len();
		end end ;
		do return ns end
	end
end
StringTools.__statics__['stripWhite'] = StringTools.stripWhite;
function StringTools.stripWhite (s) 
	do
		local l = s:len();
		local i = 0;
		local sb = StringBuf:new ();
		while(i < l) do do
			if( not StringTools.isSpace(s,i)) then
				sb:add(s:haxe_charAt(i));
			end
			(function() local _ = i; i = i + 1; return _; end)();
		end end ;
		do return sb:toString() end
	end
end
StringTools.__statics__['splitLines'] = StringTools.splitLines;
function StringTools.splitLines (str) 
	do
		local ret = str:haxe_split("\n");
		do
			local _g1 = 0; local _g = ret.length;
			while(_g1 < _g) do do
				local i = (function() local _ = _g1; _g1 = _g1 + 1; return _; end)();
				local l = ret[i];
				if(l:haxe_substr(-1,1) == "\r") then
					do
						ret[i] = l:haxe_substr(0,-1);
					end
				end
			end end ;
		end
		do return ret end
	end
end
StringTools.__statics__['baseEncode'] = StringTools.baseEncode;
function StringTools.baseEncode (s,base) 
	do
		local len = base:len();
		local nbits = 1;
		while(len > 1 << nbits) do (function() local _ = nbits; nbits = nbits + 1; return _; end)() end ;
		if(nbits > 8 or len ~= 1 << nbits) then
			throw("baseEncode: base must be a power of two.");
		end
		local size = Std._int((s:len() * 8 + nbits - 1) / nbits);
		local out = StringBuf:new ();
		local buf = 0;
		local curbits = 0;
		local mask = ((1 << nbits) - 1);
		local pin = 0;
		while((function() local _ = size; size = size - 1; return _; end)() > 0) do do
			while(curbits < nbits) do do
				curbits = curbits + (8);
				buf = buf << (8);
				local t = s:haxe_charCodeAt((function() local _ = pin; pin = pin + 1; return _; end)());
				if(t > 255) then
					throw("baseEncode: bad chars");
				end
				buf = buf | (t);
			end end ;
			curbits = curbits - (nbits);
			out:addChar(base:haxe_charCodeAt((buf >> curbits) & mask));
		end end ;
		do return out:toString() end
	end
end
StringTools.__statics__['baseDecode'] = StringTools.baseDecode;
function StringTools.baseDecode (s,base) 
	do
		local len = base:len();
		local nbits = 1;
		while(len > 1 << nbits) do (function() local _ = nbits; nbits = nbits + 1; return _; end)() end ;
		if(nbits > 8 or len ~= 1 << nbits) then
			throw("baseDecode: base must be a power of two.");
		end
		local size = (s:len() * 8 + nbits - 1) / nbits;
		local tbl = Array:new ();
		do
			local _g = 0;
			while(_g < 256) do do
				local i = (function() local _ = _g; _g = _g + 1; return _; end)();
				tbl[i] = -1;
			end end ;
		end
		do
			local _g = 0;
			while(_g < len) do do
				local i = (function() local _ = _g; _g = _g + 1; return _; end)();
				tbl[base:haxe_charCodeAt(i)] = i;
			end end ;
		end
		local size1 = (s:len() * nbits) / 8;
		local out = StringBuf:new ();
		local buf = 0;
		local curbits = 0;
		local pin = 0;
		while((function() local _ = size1; size1 = size1 - 1; return _; end)() > 0) do do
			while(curbits < 8) do do
				curbits = curbits + (nbits);
				buf = buf << (nbits);
				local i = tbl[s:haxe_charCodeAt((function() local _ = pin; pin = pin + 1; return _; end)())];
				if(i == -1) then
					throw("baseDecode: bad chars");
				end
				buf = buf | (i);
			end end ;
			curbits = curbits - (8);
			out:addChar((buf >> curbits) & 255);
		end end ;
		do return out:toString() end
	end
end
StringTools.__statics__['hex'] = StringTools.hex;
function StringTools.hex (n,digits) 
	do
		local neg = false;
		if(n < 0) then
			do
				neg = true;
				n = -n;
			end
		end
		local s = "";
		local hexChars = "0123456789ABCDEF";
		repeat do
			s = hexChars:haxe_charAt(n % 16) + s;
			n = Std._int(n / 16);
		end until(not (n > 0)) -- DOWHILE;
		if(digits ~= nil) then
			while(s:len() < digits) do s = "0" + s end ;
		end
		if(neg) then
			s = "-" + s;
		end
		do return s end
	end
end

unit.Runner = {_NAME='unit.Runner', _M=unit.Runner, _PACKAGE='unit.',__name__= Array:new({"unit","Runner"}), prototype = {}, __statics__ ={}}
package.loaded['unit.Runner'] = unit.Runner
-- unit.Runner constructor
function unit.Runner:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = unit.Runner
	return o
end

function unit.Runner:new (p)
	local ___new =unit.Runner:__construct__();
	___new.test_classes = Array:new({});
	return ___new;
end

function unit.Runner:getTestMethods (inst,cl) 
do
	local allFields = Type.getInstanceFields(cl);
	local testFields = Array:new({});
	do
		local _g = 0;
		while(_g < allFields.length) do do
			local name = allFields[_g];
			(function() _g = _g + 1; return _g; end)();
			if(name:haxe_substr(0,4) == "test") then
				do
					local field = ((type(inst) ~= "table") and (nil) or (inst[name]));
					if(Reflect.isFunction(field)) then
						do
							testFields:push(name);
						end
					end
				end
			end
		end end ;
	end
	do return testFields end
end
end
unit.Runner.prototype['getTestMethods'] = unit.Runner.getTestMethods;

function unit.Runner:println (v) 
do
	lua.Lib.println(v);
end
end
unit.Runner.prototype['println'] = unit.Runner.println;

function unit.Runner:register (t) 
do
	self.test_classes:push(t);
end
end
unit.Runner.prototype['register'] = unit.Runner.register;

function unit.Runner:run () 
do
	self:println("<pre>classes to test: <b>" + self.test_classes.length + "</b>");
	do
		local _g = 0; local _g1 = self.test_classes;
		while(_g < _g1.length) do do
			local t = _g1[_g];
			(function() _g = _g + 1; return _g; end)();
			self:println("   ");
			self:println("testing class: <b>" + Type.getClassName(t) + "</b>");
			local inst = Type.createInstance(t,Array:new({}));
			local tests = self:getTestMethods(inst,t);
			local i = 1;
			local tot = tests.length;
			local failures = 0;
			do
				local _g2 = 0;
				while(_g2 < tests.length) do do
					local test = tests[_g2];
					(function() _g2 = _g2 + 1; return _g2; end)();
					local msg = "... test " + i + " of " + tot + ", <i>" + test + "</i>:";
					local passed = true;
					try do
						Haxe.callMethod(inst,((type(inst) ~= "table") and (nil) or (inst[test])),Array:new({}));
					end
					catch e2 do
						if(e2.error == nil) then e2 = Haxe.luaError(e2) end
						if( lua.Boot.__instanceof(e2.error,unit.AssertException) ) then do--621
							local e = e2.error;
							do
								passed = false;
								msg = msg + ("<i>" + e.message + " at line #" + e.pos.lineNumber + "</i>");
								(function() local _ = failures; failures = failures + 1; return _; end)();
							end
							end--630;
						else do
							local e = e2.error;
							do
								passed = false;
								msg = msg + ("<i>" + "uncaught exception " + Std.string(e) + "</i>");
								(function() local _ = failures; failures = failures + 1; return _; end)();
							end
						end --636
						end --639;
					end --643;
					if(passed) then
						msg = msg + (" <b>OK</b>");
					end
					self:println(msg);
					(function() local _ = i; i = i + 1; return _; end)();
				end end ;
			end
			if(failures == 0) then
				self:println("<i>all tests passed</i>");
				else self:println("Huston we have a problem: <b>" + failures + " failed test(s)</b> out of " + tot);
			end
		end end ;
	end
	self:println("</pre>");
end
end
unit.Runner.prototype['run'] = unit.Runner.run;

unit.Runner.test_classes = nil;
unit.Runner.prototype['test_classes'] = "object";


Reflect = {_NAME='Reflect', _M=Reflect, _PACKAGE='',__name__= Array:new({"Reflect"}), prototype = {}, __statics__ ={}}
package.loaded['Reflect'] = Reflect
-- Reflect constructor
function Reflect:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = Reflect
	return o
end

function Reflect:new ()
	local new =Reflect:new()
	return new
end

Reflect.__statics__['empty'] = Reflect.empty;
function Reflect.empty () 
	do
		do return {} end
	end
end
Reflect.__statics__['hasField'] = Reflect.hasField
function Reflect.hasField (o,field) 
	do
		do
			do return Haxe.hasOwnProperty (o, field) end
		end
	end
end
Reflect.__statics__['field'] = Reflect.field
function Reflect.field (o,field) 
	do
		do return ((type(o) ~= "table") and (nil) or (o[field])) end
	end
end
Reflect.__statics__['setField'] = Reflect.setField
function Reflect.setField (o,field,value) 
	do
		o[field] = value;
	end
end
Reflect.__statics__['callMethod'] = Reflect.callMethod
function Reflect.callMethod (o,func,args) 
	do
		do return Haxe.callMethod(o,func,args) end
	end
end
Reflect.__statics__['fields'] = Reflect.fields;
function Reflect.fields (o) 
	do
		if(o == nil) then
			do return Array:new () end
		end
		do
			local a = Haxe.tableKeys(o);
			local i = 0;
			while(i < a.length) do do
				if( not Haxe.hasOwnProperty (o, a[i])) then
					a:splice(i,1);
					else i = i + 1;
				end
			end end ;
			do return a end
		end
	end
end
Reflect.__statics__['isFunction'] = Reflect.isFunction;
function Reflect.isFunction (f) 
	do
		do return type(f) == "function" end
	end
end
Reflect.__statics__['compare'] = Reflect.compare;
function Reflect.compare (a,b) 
	do
		do return (((a == b)) and (0) or ((((((a) > (b))) and (1) or (-1))))) end
	end
end
Reflect.__statics__['compareMethods'] = Reflect.compareMethods;
function Reflect.compareMethods (f1,f2) 
	do
		if(f1 == f2) then
			do return true end
		end
		if( not Reflect.isFunction(f1) or  not Reflect.isFunction(f2)) then
			do return false end
		end
		do return f1 == f2 end
	end
end
Reflect.__statics__['isObject'] = Reflect.isObject;
function Reflect.isObject (v) 
	do
		do return type(v) == "table" end
	end
end
Reflect.__statics__['deleteField'] = Reflect.deleteField
function Reflect.deleteField (o,f) 
	do
		do return ((Haxe.hasOwnProperty (o, f)) and ((function(this) 
			local r;
			o['f'] = nil;
			r = true;
			return r;
		end)(self)) or (false)) end
	end
end
Reflect.__statics__['copy'] = Reflect.copy;
function Reflect.copy (o) 
	do
		local o2 = {};
		do
			local _g = 0; local _g1 = Reflect.fields(o);
			while(_g < _g1.length) do do
				local f = _g1[_g];
				(function() _g = _g + 1; return _g; end)();
				o2[f] = ((type(o) ~= "table") and (nil) or (o[f]));
			end end ;
		end
		do return o2 end
	end
end
Reflect.__statics__['makeVarArgs'] = Reflect.makeVarArgs;
function Reflect.makeVarArgs (f) 
	do
		collectgarbage("step");
	end
end

StringBuf = {_NAME='StringBuf', _M=StringBuf, _PACKAGE='',__name__= Array:new({"StringBuf"}), prototype = {}, __statics__ ={}}
package.loaded['StringBuf'] = StringBuf
-- StringBuf constructor
function StringBuf:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = StringBuf
	return o
end

function StringBuf:new (p)
	local ___new =StringBuf:__construct__();
	___new.b = "";
	return ___new;
end

function StringBuf:add (x) 
do
	self.b = self.b + (x);
end
end
StringBuf.prototype['add'] = StringBuf.add

function StringBuf:addChar (c) 
do
	self.b = self.b + (String:haxe_fromCharCode(c));
end
end
StringBuf.prototype['addChar'] = StringBuf.addChar;

function StringBuf:addSub (s,pos,len) 
do
	self.b = self.b + (s:haxe_substr(pos,len));
end
end
StringBuf.prototype['addSub'] = StringBuf.addSub;

StringBuf.b = nil;
StringBuf.prototype['b'] = "object";

function StringBuf:toString () 
do
	do return self.b end
end
end
StringBuf.prototype['toString'] = StringBuf.toString;


syntax.WhileAccess = {_NAME='syntax.WhileAccess', _M=syntax.WhileAccess, _PACKAGE='syntax.',__name__= Array:new({"syntax","WhileAccess"}), prototype = {}, __statics__ ={}}
package.loaded['syntax.WhileAccess'] = syntax.WhileAccess
-- syntax.WhileAccess constructor
function syntax.WhileAccess:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = syntax.WhileAccess
	return o
end

function syntax.WhileAccess:new (p)
	local ___new =syntax.WhileAccess:__construct__();
	collectgarbage("step");
	return ___new;
end

function syntax.WhileAccess:testBreak () 
do
	local x = 0;
	while(x < 3) do do
		(function() local _ = x; x = x + 1; return _; end)();
		break;
	end end ;
	unit.Assert.equals(1,x,nil, { fileName = "WhileAccess.hx", lineNumber = 22, className = "syntax.WhileAccess", methodName = "testBreak" });
end
end
syntax.WhileAccess.prototype['testBreak'] = syntax.WhileAccess.testBreak;

function syntax.WhileAccess:testContinue () 
do
	local x = 0;
	while(x < 3) do do
		(function() local _ = x; x = x + 1; return _; end)();
		if true then continue end
		unit.Assert.isTrue(false,nil, { fileName = "WhileAccess.hx", lineNumber = 30, className = "syntax.WhileAccess", methodName = "testContinue" });
	end end ;
	unit.Assert.equals(3,x,nil, { fileName = "WhileAccess.hx", lineNumber = 32, className = "syntax.WhileAccess", methodName = "testContinue" });
end
end
syntax.WhileAccess.prototype['testContinue'] = syntax.WhileAccess.testContinue;

function syntax.WhileAccess:testWhile () 
do
	local x = 0;
	while(x < 3) do do
		(function() local _ = x; x = x + 1; return _; end)();
	end end ;
	unit.Assert.equals(3,x,nil, { fileName = "WhileAccess.hx", lineNumber = 13, className = "syntax.WhileAccess", methodName = "testWhile" });
end
end
syntax.WhileAccess.prototype['testWhile'] = syntax.WhileAccess.testWhile;


unit.Assert = {_NAME='unit.Assert', _M=unit.Assert, _PACKAGE='unit.',__name__= Array:new({"unit","Assert"}), prototype = {}, __statics__ ={}}
package.loaded['unit.Assert'] = unit.Assert
-- unit.Assert constructor
function unit.Assert:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = unit.Assert
	return o
end

function unit.Assert:new ()
	local new =unit.Assert:new()
	return new
end

unit.Assert.__statics__['isTrue'] = unit.Assert.isTrue;
function unit.Assert.isTrue (c,message,p) 
	do
		if(message == nil) then
			message = "Assertion failed";
		end
		if( not c) then
			throw(unit.AssertException:new (p,message));
		end
	end
end
unit.Assert.__statics__['equals'] = unit.Assert.equals;
function unit.Assert.equals (a,b,message,p) 
	do
		if(message == nil) then
			message = "Assertion failed: expected value was " + Std.string(a) + " but it is " + Std.string(b);
		end
		unit.Assert.isTrue(a == b,message,p);
	end
end
unit.Assert.__statics__['isNotNull'] = unit.Assert.isNotNull;
function unit.Assert.isNotNull (o,message,p) 
	do
		if(message == nil) then
			message = "Assertion failed: expected NOT null";
		end
		unit.Assert.isTrue(o ~= nil,message,p);
	end
end
unit.Assert.__statics__['isNull'] = unit.Assert.isNull;
function unit.Assert.isNull (o,message,p) 
	do
		if(message == nil) then
			message = "Assertion failed: expected null but it is " + Std.string(o);
		end
		unit.Assert.isTrue(o == nil,message,p);
	end
end

syntax.TypedefAccess = {_NAME='syntax.TypedefAccess', _M=syntax.TypedefAccess, _PACKAGE='syntax.',__name__= Array:new({"syntax","TypedefAccess"}), prototype = {}, __statics__ ={}}
package.loaded['syntax.TypedefAccess'] = syntax.TypedefAccess
-- syntax.TypedefAccess constructor
function syntax.TypedefAccess:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = syntax.TypedefAccess
	return o
end

function syntax.TypedefAccess:new (p)
	local ___new =syntax.TypedefAccess:__construct__();
	collectgarbage("step");
	return ___new;
end


lua.Boot = {_NAME='lua.Boot', _M=lua.Boot, _PACKAGE='lua.',__name__= Array:new({"lua","Boot"}), prototype = {}, __statics__ ={}}
package.loaded['lua.Boot'] = lua.Boot
-- lua.Boot constructor
function lua.Boot:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = lua.Boot
	return o
end

function lua.Boot:new ()
	local new =lua.Boot:new()
	return new
end

lua.Boot.__statics__['__classes'] = "object";
lua.Boot.__classes = nil;
lua.Boot.__statics__['__trace'] = lua.Boot.__trace;
function lua.Boot.__trace (v,i) 
	do
		do
			local msg = ((i ~= nil) and (i.fileName + ":" + i.lineNumber + ": ") or (""));
			msg = msg + (tostring(v));
			print(msg);
		end
	end
end
lua.Boot.__statics__['__closure'] = lua.Boot.__closure;
function lua.Boot.__closure (o,f) 
	do
		do
			local m = o[f];
			if(m == nil) then
				do return nil end
			end
			local f1 = function () 
			do
				do return m.apply(o,arguments) end
			end
			end -- end local function decl
			;
			do return f1 end
		end
	end
end
lua.Boot.__statics__['__string_rec'] = lua.Boot.__string_rec;
function lua.Boot.__string_rec (v,str) 
	do
		local cname = Haxe.getQualifiedClassName(v);
		local switch = (cname);
		if (switch =="Object") then do
			local k = Haxe.tableKeys(v);
			local s = "{";
			local first = true;
			do
				local _g1 = 0; local _g = k.length;
				while(_g1 < _g) do do
					local i = (function() local _ = _g1; _g1 = _g1 + 1; return _; end)();
					local key = k[i];
					if(first) then
						first = false;
						else s = s + (",");
					end
					s = s + (" " + key + " : " + lua.Boot.__string_rec(v[key],str));
				end end ;
			end
			if( not first) then
				s = s + (" ");
			end
			s = s + ("}");
			do return s end
		end
		elseif (switch == "Array") then do
			local s = "[";
			local i;
			local first = true;
			do
				local _g1 = 0; local _g = v.length;
				while(_g1 < _g) do do
					local i1 = (function() local _ = _g1; _g1 = _g1 + 1; return _; end)();
					if(first) then
						first = false;
						else s = s + (",");
					end
					s = s + (lua.Boot.__string_rec(v[i1],str));
				end end ;
			end
			do return s + "]" end
		end
		else do
			local switch = (type(v));
			if (switch =="function") then do
				do return "<function>" end
			end
			end -- end of switch;
			;
		end
		end -- end of switch;
		;
		do return tostring(v) end
	end
end
lua.Boot.__statics__['__interfLoop'] = lua.Boot.__interfLoop;
function lua.Boot.__interfLoop (cc,cl) 
	do
		if(cc == nil) then
			do return false end
		end
		if(cc == cl) then
			do return true end
		end
		local intf = cc.__interfaces__;
		if(intf ~= nil) then
			do
				local _g1 = 0; local _g = intf.length;
				while(_g1 < _g) do do
					local i = (function() local _ = _g1; _g1 = _g1 + 1; return _; end)();
					local i1 = intf[i];
					if(i1 == cl or lua.Boot.__interfLoop(i1,cl)) then
						do return true end
					end
				end end ;
			end
		end
		do return lua.Boot.__interfLoop(cc.__super__,cl) end
	end
end
lua.Boot.__statics__['__instanceof'] = lua.Boot.__instanceof;
function lua.Boot.__instanceof (o,cl) 
	do
		do
			try do
				if(Haxe.instanceof(o, cl)) then
					do
						if(cl == Array) then
							do return (o.__enum__ == nil) end
						end
						do return true end
					end
				end
				if(lua.Boot.__interfLoop(o.__class__,cl)) then
					do return true end
				end
			end
			catch e3 do
				if(e3.error == nil) then e3 = Haxe.luaError(e3) end
				 do
					local e = e3.error;
					do
						if(cl == nil) then
							do return false end
						end
					end
				
				end --639;
			end --643;
			local switch = (cl);
			if (switch ==Int) then do
				do return (Math.ceil(o) == o) and isFinite(o) end
			end
			elseif (switch == Float) then do
				do return type(o) == "number" end
			end
			elseif (switch == Bool) then do
				do return (o == true or o == false) end
			end
			elseif (switch == String) then do
				do return type(o) == "string" end
			end
			elseif (switch == Dynamic) then do
				do return true end
			end
			else do
				if(o ~= nil and o.__enum__ == cl) then
					do return true end
				end
				do return false end
			end
			end -- end of switch;
			;
		end
	end
end
lua.Boot.__statics__['__init'] = lua.Boot.__init;
function lua.Boot.__init () 
	do
		do
			string__add = function(r,w) return(r..w) end
			smt = getmetatable(""); smt.__add = string__add
			smt.length = string.len;
			
			smt.__concat = function (a,b)
				if(a == nil) then
					if(b == nil) then
						do return "" end;
					else
						do return tostring(b) end;
					end;
				elseif(b == nil) then
					if(a == nil) then
						do return "" end
					else do return tostring(a) end;
					end;
				end
				do return tostring(a)..tostring(b) end
			end;
			smt['haxe_charAt'] = function(s,p)
				return string.char(s,p+1);
			end
			smt['haxe_charCodeAt'] = function(s,p)
				return string.byte(s,p+1);
			end
			smt['haxe_indexOf'] = function(s,str,pos)
				if(pos == nil) then pos = 0; end;
				pos = pos + 1;
				local i = string.find(s, str, pos, true);
				if(i==nil) then do return -1 end end
				return i - 1;
			end
			smt['haxe_lastIndexOf'] = function(s,str,pos)
				local last = 0;
				local r = -1;
				if(pos == nil) then pos = string.len(s) + 1	end
				while(true) do
					try
						r = string.find(s,str,last+1,true);
						if(r== nil or r > pos) then
							do return last end
						end
						last = r;
					catch err do
						do
							return last-1;
						end
					end
				end
				return r-1;
			end
			smt['haxe_split'] = function(s,delim)
				local a = Array:new()
				local last = s.indexOf(delim,nil)
				if(last == nil) then
					do
						a:push(s);
						return a;
					end
				end
				local pos = 1;
				while(true) do
					do
						local first,last = string.find(s,delim,pos,true);
						if(first) then
							a:push(string.sub(s,pos,first - 1));
							pos = last + 1;
						else
							a:push(string.sub(s,pos));
							break;
						end
					end
				end
				return a;
			end

			smt['haxe_substr'] = function(s,pos,len)
				if(len == nil) then len = string.len(s) end;
				if(len == 0) then return ""; end;
				if(pos == nil) then pos = 0; end;
				if(pos >= 0) then pos = pos + 1; end;
				return string.sub(s,pos,len);
			end

			smt['haxe_toLowerCase'] = function(s)
				return string.lower(s);
			end

			smt['haxe_toUpperCase'] = function(s)
				return string.upper(s)
			end

			smt['haxe_toString'] = function(s)
				return s
			end

			smt['fromCharCode'] = function(c)
				return string.char(c);
			end


			getmetatable ("").__index =
			function (s, n)
			if type (n) == "number" then
				return sub (s, n, n)
			elseif type (oldmeta) == "function" then
				return smt (s, n)
			else
				return smt[n]
			end
			end

			;
			lua.Boot.__classes = {};
			String = lua.LuaString__;
			lua.Boot.__classes.String = String;
			lua.Boot.__classes.Array = Array;
			Int = {};
			Data = lua.LuaDate__;
			Dynamic = {};
			Math = math;
			Float = {};
			Bool = {};
			Bool["true"] = true;
			Bool["false"] = false;
			closure = lua.Boot.__closure;
			string.__add = function(a,b) return(a .. b); end
		end
	end
end

lua.Lib = {_NAME='lua.Lib', _M=lua.Lib, _PACKAGE='lua.',__name__= Array:new({"lua","Lib"}), prototype = {}, __statics__ ={}}
package.loaded['lua.Lib'] = lua.Lib
-- lua.Lib constructor
function lua.Lib:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = lua.Lib
	return o
end

function lua.Lib:new ()
	local new =lua.Lib:new()
	return new
end

lua.Lib.__statics__['load'] = lua.Lib.load
function lua.Lib.load (lib,prim,nargs) 
	do
		do return loadfile(lib) end
	end
end
lua.Lib.__statics__['print'] = lua.Lib.print;
function lua.Lib.print (v) 
	do
		if v!= nil then io.stdout:write(v) end
	end
end
lua.Lib.__statics__['println'] = lua.Lib.println;
function lua.Lib.println (v) 
	do
		if v ~= nil then io.stdout:write(v.."\n"); io.stdout:flush() end
	end
end
lua.Lib.__statics__['rethrow'] = lua.Lib.rethrow;
function lua.Lib.rethrow (e) 
	do
		do return throw(e) end
	end
end
lua.Lib.__statics__['getClasses'] = lua.Lib.getClasses;
function lua.Lib.getClasses () 
	do
		do return lua.Boot.__classes end
	end
end

IntIter = {_NAME='IntIter', _M=IntIter, _PACKAGE='',__name__= Array:new({"IntIter"}), prototype = {}, __statics__ ={}}
package.loaded['IntIter'] = IntIter
-- IntIter constructor
function IntIter:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = IntIter
	return o
end

function IntIter:new (min,max)
	local ___new =IntIter:__construct__();
	___new.min = min;
	___new.max = max;
	return ___new;
end

function IntIter:hasNext () 
do
	do return self.min < self.max end
end
end
IntIter.prototype['hasNext'] = IntIter.hasNext;

IntIter.max = nil;
IntIter.prototype['max'] = "object";

IntIter.min = nil;
IntIter.prototype['min'] = "object";

function IntIter:next () 
do
	do return (function() local _ = self.min; self.min = self.min + 1; return _; end)() end
end
end
IntIter.prototype['next'] = IntIter.next;


Main = {_NAME='Main', _M=Main, _PACKAGE='',__name__= Array:new({"@Main"}), prototype = {}, __statics__ ={}}
package.loaded['Main'] = Main
-- Main constructor
function Main:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.__class__ = Main
	return o
end

function Main:new ()
	local new =Main:new()
	return new
end

Main.__statics__['init'] = "object";
--
-- Boot generation
--

lua.Boot.__res = {}
lua.Boot.classes = {}
lua.Boot.__init();
do
	math.POSITIVE_INFINITY = 1/0;
	math.NEGATIVE_INFINITY = -1/0;
	math.NaN = 0/0;
	math.PI = math.pi;
	math.round = function(v) return math.floor(v + 0.5) end
	math.isNaN = function(v) return v == math.NaN; end
	math.isFinite = function(v) return v ~= math.NaN; end
	math.randomseed(os.time());
end
do
	Math = lua.LuaMath__;
end

-- Generate statics
try
lua.LuaString__.__name__ = "String";
Main.init = Test.main();
catch err do
	print (err.error)
	print ("ERROR: "..err.callinfo .. err.error)
end
