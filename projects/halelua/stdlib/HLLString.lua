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

module ("string", package.seeall)

string__add = function(r,w)
	if r == nil then r = "null" else r = tostring(r) end
	if w == nil then w = "null" else w = tostring(w) end
	return(r..w)
end
getmetatable("").__add = string__add
getmetatable("").__concat = function (a,b)
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

function new(self,v)
	return v;
end

function haxe_charAt(s,p)
	return string.sub(s,p+1,p+1);
end

function haxe_charCodeAt(s,p)
	if(p < 0) or (p >= string.len(s)) then
		do return nil end
	end
	return string.byte(s,p+1);
end

function haxe_indexOf(s,str,pos)
	if(pos == nil) then pos = 0; end;
	pos = pos + 1;
	local i = string.find(s, str, pos, true);
	if(i==nil) then do return -1 end end
	return i - 1;
end

function haxe_lastIndexOf(s,str,pos)
	local last = 0;
	local r = -1;
	if pos == nil then pos = string.len(s)	end
	if pos >= 0 then pos = pos + 1 end
	while(true) do
		try
			r = string.find(s,str,last+1,true);
			if(r== nil or r > pos) then
				do return last - 1 end
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

function haxe_split(s,delim)
	local a = Array:new()
	local last = haxe_indexOf(s,delim,nil)
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

function haxe_substr(s,pos,len)
	local l = string.len(s)
	if(l == 0) then do return "" end end;

	if(len == nil) then
		len = l
	elseif len == 0 then
		do return "" end
	end

	if(pos == nil) then pos = 0 end
	if(pos ~= 0 and len < 0) then do return "" end end

	if pos < 0 then
		pos = l + pos
		if pos < 0 then pos = 0 end
	elseif len < 0 then
		len = l + len - pos
	end
	if (pos+len > l) then len = l - pos	end
	if (pos < 0) or (len <= 0) then do return "" end end

	local iend = pos + len
	if(iend > l) then iend = l end
	return string.sub(s,pos+1, iend);
end

function haxe_toLowerCase(s)
	return string.lower(s);
end

function haxe_toUpperCase(s)
	return string.upper(s)
end

function haxe_toString(s)
	return s
end

function haxe_fromCharCode(...)
	for i,v in ipairs(arg) do
		if type(v) == "number" then
			do return string.char(v) end
		end
	end
	return ""
end

function fromCharCode(c)
	return string.char(c);
end

function fromHexString(s)
	return string.char( tonumber(s,16) )
end

function urlDecode(s)
	return (
		string.gsub(
			string.gsub(s,"+"," "),
			"%%(%x%x)",
			fromHexString
		)
	)
end

function urlEncode(s)
	return (
		string.gsub (
			s,
			"%W",
			function(s2)
				return string.format("%%%02X", string.byte(s2))
			end
		)
	)
end
