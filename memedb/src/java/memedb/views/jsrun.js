function log(v) {
	return eval('('+_MemeDB_JSVIEW.scriptLog(v)+')');
}

function sum(results) {
  var rv = 0;
  for (var x = 0; x < results.length; x++) {
	rv += results[x].value;
  }
  return rv;
}

function emit(key,val) {
	_MemeDB_retval = { 'key':key,'value':val };
}

function get(id,revision,db) {
	return eval('('+_MemeDB_JSVIEW.get(id,revision,db)+')');
}

function toJSON(obj) {
	if (obj!=null && typeof obj != 'undefined') {
		return obj.toJSONString();
	}
}
