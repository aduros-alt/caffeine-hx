package chx.sys;

#if (flash9 || neko)
typedef MyTypedef2 = {
#if flash9
	var flash9 : Int;
#elseif neko
	var neko : Float;
#else
	var js : Float;
#end
};

#else

typedef MyTypedef2 = Int;
#end
