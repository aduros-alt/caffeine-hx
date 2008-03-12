-- Test prototype
Test = {}
function Test:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.__class__ = Test
    self.__name__ = "Test"
    return o
end

function Test:__construct__ (va)
    local new =Test:new()
    do
        new.a = va
    end
    return new
end


a = Test:__construct__(23)
print(a.a)
