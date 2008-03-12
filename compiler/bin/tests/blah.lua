module("lua",package.seeall);
require('class')

class "Lib"

function Lib.print(s)
	print(s);
end


Lib.print("hey there")

