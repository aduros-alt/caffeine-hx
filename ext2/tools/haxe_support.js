
/**
	Simple test to see if flash ExternalInterface is working
	@param v Dynamic value which will be returned
**/
function haxeSupportTest(v) {
// 	window.alert("supported");
	return v;
}

/**
	Flash is unable to receive a JS object, so when returned to flash, the
	res.index and res.input are undefined, leaving only the array of matches.
	@param s String to match
	@param ereg Regular expression text
	@param opt Regular expression options
	@return Array with first element indicating the match index
**/
function haxeERegMatch(s, ereg, opt) {
	var re = new RegExp(unescape(ereg), unescape(opt));
	var res = re.exec(unescape(s));
	if(res == null)
		return null;
	for(var i=0; i < res.length; i++)
		res[i] = escape(res[i]);
	res.unshift(res.index);
	return res;
}

