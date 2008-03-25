module("Array",package.seeall)

function Array:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self;
	self.__class__ = Array;
	self.__name__ = {"Array"};
	self.length = 0;

	self.__concat = function (...)
		print("CONCAT ARRAY");
	end

	self.__newindex = function(tbl,key,value)
		--print("Setting "..key.." to "..value);
		--print(tbl, tbl.length);
		--print(self, self.length)
		if(type(key) ~= "number") then
			rawset(tbl,key,value);
			--throw("Invalid key "..key);
		else
			if(key >= tbl.length) then tbl.length = key + 1; end;
			rawset(tbl,key,value);
		end;

		--print("New length: ",self.length);
	end

	return o;
end

function Array:new(a)
	local __new = Array:__construct__();
	if a ~= nil then
		for i, v in ipairs(a) do
			__new:push(v);
		end
	end
	return __new;
end

function Array:concat(arr)
	if(arr.__name__[1] ~= "Array") then throw("Not array"); end;
	local a = Array:new();
	for k,v in pairs (self) do
		if(type(k) == "number") then a[k] = v; end;
	end
	for k,v in pairs (arr) do
		if(type(k) == "number") then a[k] = v; end;
	end;
	return a;
end

function Array:copy()
	local u = Array:new();
	for k, v in pairs (self) do
		if(type(k) == "number") then u[k] = v; end;
	end
	return u;
end


function Array:iterator()
	local u = { a = self, p = 0 }
	u.hasNext = function()
		return p < a.length;
	end
	u.next = function()
		local i = a[p];
		p = p + 1;
		return i;
	end
	return u;
end


function Array:insert(pos, x)
	local l = self.length;
	if( pos < 0 ) then
		pos = l + pos;
		if( pos < 0 ) then pos = 0; end;
	end
	if( pos > l ) then pos = l; end;

	local b = {};
	for i, v in pairs (self) do
		if(type(i) == "number" and i >= pos) then
			b[i+1] = v
		end
	end
	for i, v in pairs (b) do
		self[i] = v
	end
	self[pos] = x;
end

function Array:join(delim)
	local s = "";
	local max = self.length-1;
	for i = 0,max,1 do
		if(self[i] == nil) then
			s = s .. "null";
		else
			s = s .. self[i];
		end
		if(i ~= max) then s = s .. delim; end;
	end
	return s
end

function Array:__tostring()
	local s = "[";
	s = s .. join(self, ", ");
	s = s .. "]";
	return s;
end

function Array:toString()
	return __tostring(self);
end

function Array:pop()
	local l = self.length;
	if(l == 0) then do return nil end end;
	l = l - 1;
	rawset(self,"length", l);
	local rv = self[l];
	self[l] = nil;
	return rv;
end

function Array:push(v)
	local l = self.length;
	self[l] = v;
	rawset(self,"length", l+1);
	return l;
end

function Array:unshift(v)
	insert(self, 0, v);
end

function Array:remove(v)
	local l = self.length;
	local max = l - 1;
	for i = 0,max,1 do
		if(self[i] == v) then
			for v = i, max, 1 do
				self[v] = self[v+1];
			end
			l = l -1;
			rawset(self,"length", l);
			self[l] = nil;
			return true;
		end
	end
	return false;
end

--[[
	Reverses the array in place
--]]
function Array:reverse()
	local i = 0
	local l = self.length
	local h = math.floor(l / 2);
	local t = nil;
	l = l - 1
	while( i < h ) do
		t = self[i]
		self[i] = self[l-i]
		self[l-i] = t
		i = i + 1;
	end;
end;


function Array:shift()
	local l = self.length
	local max = l -1;
	if(l == nil) then do return nil end end
	local rv = self[0]
	for k = 1,max,1 do
		self[k-1] = self[k]
	end
	rawset(self,"length", max)
	return rv
end


function Array:slice(pos, iend)
	if( pos < 0 ) then
		pos = self.length + pos;
		if(pos < 0) then pos = 0 end;
	end
	if(iend == nil) then
		iend = self.length
	elseif( iend < 0 ) then
		iend = self.length + iend;
	end;
	if(iend > self.length) then iend = self.length end;
	iend = iend - 1;

	local a = Array:new()
	for i=pos,iend,1 do
		push(a, self[i])
	end
	return a;

end

function Array:sort(f)
	print("Array:sort")

	local i = 0;
	local l = self.length;
	local a = self;

	while( i < l ) do
		local swap = false;
		local j = 0;
		local max = l - i - 1;
		while( j < max) do
			if(f(a[j], a[j+1]) > 0) then
				local tmp = a[j+1]
				a[j+1] = a[j]
				a[j] = tmp;
				swap = true
			end
			j = j + 1
		end
		if ( not swap ) then break end;
		i = i + 1;
	end
end


function Array:splice( pos, len )
	local l = self.length
	if( len < 0 ) then do return Array:new() end end;
	if( pos < 0) then
		pos = l + pos;
		if(pos < 0) then pos = 0 end;
	end
	if(pos > l) then
		pos = 0;
		len = 0;
	elseif( (pos + len) > l) then
		len = l - pos;
	end
	local iend = pos + len
	local b = slice(self, pos, iend)
	for i=pos, iend, 1 do
		self[i] = self[i+len]
	end
	-- GC
	for i=iend+1, l, 1 do
		rawset(self,i, nil)
	end;
	rawset(self,"length", l - len);
	return b
end


function Array:orderKeys()
	local b = {};
	local max = self.length - 1;
	for i = 0,max,1 do
		b[i] = i
	end
	table.sort(b);
	return b;
end

--
-- Pack an array to Lua style beginning at index 1
-- Returns a Lua table, not an Array object.
function Array:pack()
	local a = {}
	for i=0,length,1 do
		a[i+1] = rawget(self,i)
	end
	return a
end

--__class__ = Array;
--__name__ = {"Array"};
