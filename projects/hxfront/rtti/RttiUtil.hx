package hxfront.rtti;

import haxe.rtti.CType;

class RttiUtil {
	public static function typeName(type : CType, opt : Bool) : String {
		switch(type) {
			case CFunction(_,_):
				return opt ? "Null<function>" : "function";
			case CUnknown:
				return opt ? "Null<unknown>" : "unknown";
			case CAnonymous(_), CDynamic(_):
				return opt ? "Null<Dynamic>" : "Dynamic";
			case CEnum(name, params),
				 CClass(name, params),
				 CTypedef(name, params):
				var t = name;
				if(params != null && params.length > 0) {
					var types = [];
					for(p in params)
						types.push(typeName(p, false));
					t += '<'+types.join(',')+'>';
				}
				return name != 'Null' && opt ? 'Null<'+t+'>' : t;
		}
	}

	public static function unifyFields(cls : Classdef, ?h : Hash<ClassField>) : Hash<ClassField> {
		if(h == null) h = new Hash();
		for(f in cls.fields)
			if(!h.exists(f.name))
				h.set(f.name, f);
		var parent = cls.superClass;
		if(parent != null) {
			var pcls = Type.resolveClass(parent.path);
			var x = Xml.parse(untyped pcls.__rtti).firstElement();
			switch(new haxe.rtti.XmlParser().processElement(x)) {
				case TClassdecl(c):
					unifyFields(c, h);
				default:
					throw "Invalid type parent type (" + parent.path + ") for class: " + cls;
			}
		}
		return h;
	}

	public static function getClassDef(cls : Class<Dynamic>) {
        var x = Xml.parse(untyped cls.__rtti).firstElement();
        var infos = new haxe.rtti.XmlParser().processElement(x);

		var cd;
		switch(infos) {
			case TClassdecl(c) : cd = c;
			default            : return throw "not a class!";
		}
		return cd;
	}
}