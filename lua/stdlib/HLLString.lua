module ("string", package.seeall)

string__add = function(r,w) return(r..w) end
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

function haxe_charAt(s,p)
	return string.char(s,p+1);
end

function haxe_charCodeAt(s,p)
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

function haxe_split(s,delim)
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

function haxe_substr(s,pos,len)
	if(len == nil) then len = string.len(s) end;
	if(len == 0) then return ""; end;
	if(pos == nil) then pos = 0; end;
	if(pos >= 0) then pos = pos + 1; end;
	return string.sub(s,pos,len);
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

function fromCharCode(c)
	return string.char(c);
end

