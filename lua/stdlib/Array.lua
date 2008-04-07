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

module("Array",package.seeall)

function Array:__construct__(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self;
	self.length = 0;

	--self.__concat = function (...)
	--	print("CONCAT ARRAY UNFINISHED");
	--end

	self.__newindex = function(tbl,key,value)
		--print("Setting "..key.." to "..value);
		if(type(key) ~= "number") then
			rawset(tbl,key,value);
		else
			if(key >= tbl.length) then tbl.length = key + 1; end;
			rawset(tbl,key,value);
		end;
	end

	self.__eq = function(a,b)
		for k,v in pairs(a) do
			if b[k] ~= v then do return false end end
		end
		for k,v in pairs(b) do
			if a[k] ~= v then do return false end end
		end
		return true
	end

	return o;
end

function Array:new(a)
	local __new = Array:__construct__();
	local max = 0;
	if a ~= nil then
		for i, v in pairs(a) do
			if type(i) == 'number' then
				rawset(__new,i-1,v);
				if(i > max) then max = i end;
			end
		end
	end
	rawset(__new,"length", max);
	return __new;
end

function Array:concat(arr)
	if(arr.__name__[0] ~= "Array") then throw("Not array"); end;
	local a = Array:new();
	for k,v in pairs (self) do
		if(type(k) == "number") then a[k] = v; end
	end
	local l = self.length
	local max = self.length
	local amax = arr.length
	for k,v in pairs (arr) do
		if(type(k) == "number" and k < amax) then
			local idx = l + k;
			a[idx] = v;
			if idx >= max then max = idx + 1 end
		end
	end
	rawset(a,"length", max)
	return a
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
				self[v] = self[v+1]
			end
			do rawset(self,"length", l-1) end
			l = l - 1
			self[l] = nil
			rawset(self,"length", l);
			do return true end
		end
	end
	return false
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

prototype = {}
__statics__ = {}
--__class__ = Array;
--__name__ = {"Array"};

prototype['concat'] = concat
prototype['copy'] = copy
prototype['insert'] = insert
prototype['iterator'] = iterator
prototype['join'] = join
prototype['pop'] = pop
prototype['push'] = push
prototype['remove'] = remove
prototype['reverse'] = reverse
prototype['shift'] = shift
prototype['slice'] = slice
prototype['sort'] = sort
prototype['splice'] = splice
prototype['toString'] = toString
prototype['unshift'] = unshift
