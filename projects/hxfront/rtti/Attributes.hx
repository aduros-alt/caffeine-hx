package hxfront.rtti;

class Attributes {
	static var cache = new Hash<Dynamic>();

	public static function ofClass(cls : Class<Dynamic>, ?o : Dynamic) : Dynamic {
		if(o == null) o = {};
		if(untyped cls.__rtti == null) return o;
		var x = Xml.parse(untyped cls.__rtti).firstChild();
		var doc = x.elementsNamed("haxe_doc").next();
		if(doc != null)
			return parseDoc(doc.firstChild().nodeValue, o);
		else
			return o;
	}

	public static function ofField(cls : Class<Dynamic>, field : String, ?o : Dynamic) : Dynamic {
		if(o == null) o = {};
		if(untyped cls.__rtti == null) return o;
		var x = Xml.parse(untyped cls.__rtti).firstChild();
		var docs = [];

		while(true) {
			var fields = x.elementsNamed(field);
			if(fields.hasNext()) {
				var f = fields.next();
				var doc = f.elementsNamed("haxe_doc").next();
				if(doc != null)
					docs.unshift(doc.firstChild().nodeValue);
			}
			var parent = x.elementsNamed("extends");
			if(!parent.hasNext()) break;
			cls = Type.resolveClass(parent.next().get("path"));
			if(untyped cls.__rtti == null) break;
			x = Xml.parse(untyped cls.__rtti).firstElement();
		}
		return parseDocs(docs, o);
	}

	static var parser = ~/\s*[*]?\s*[$]([a-z0-9_]+)=([^\r\n]+)(?:\n|\r\n|\r)?/im;
	static function parseDoc(s : String, o : Dynamic) {
		while(s.length > 0) {
			if(!parser.match(s)) break;
			Reflect.setField(o, parser.matched(1), parser.matched(2));
			s = parser.matchedRight();
		}
		return o;
	}

	static function parseDocs(a : Array<String>, o : Dynamic) {
		for(s in a)
			parseDoc(s, o);
		return o;
	}
}