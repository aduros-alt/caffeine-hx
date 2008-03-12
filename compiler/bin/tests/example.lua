Account = {balance = 0}

function Account:new (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Account:deposit (v)
	self.balance = self.balance + v
end

function Account:withdraw (v)
	if v > self.balance then error"insufficient funds" end
	self.balance = self.balance - v
end

function Account:printBalance ()
	print("Account balace", self.balance);
end

function Account:overrideMe ()
	print("Account");
end

-- usage 

a = Account:new({balance = 0})
a:deposit(100.00)


-- inheritance

SpecialAccount = Account:new()

function SpecialAccount:__construct__ (v, x)
	local a = SpecialAccount:new()
	a.balance = v
	a.unkfield = v
	if( x == nil ) then print("NIL") end
	return a
end

function SpecialAccount:withdraw (v)
	if v - self.balance >= self:getLimit() then
		error"insufficient funds"
	end
	self.balance = self.balance - v
end

function SpecialAccount:getLimit ()
	return self.limit or 0
end

function SpecialAccount:overrideMe ()
	Account.overrideMe(self);
	print("SpecialAccout");
end

-- usage 

s = SpecialAccount:new{limit=1000.00}
s:withdraw(200.00)

s:overrideMe()
s:printBalance()

-- haxe
d = SpecialAccount:__construct__(50000.00)
d:printBalance()
print(d.unkfield)

function try(f, catch_f)
	local status, exception = pcall(f)
	if not status then
		catch_f(exception)
	end
end

