module haxe.List;

import haxe.HaxeTypes;
import haxe.Serializer;
import tango.util.container.LinkedList;

private alias LinkedList!(Dynamic) HList;
class List : HaxeClass {
	public HaxeType type() { return HaxeType.TList; }
	public HList data;
	public char[] __classname() { return "List<Dynamic>"; }

	this() { data = new HList(); }


	public char[] toString() {
		char[] b = "{";
		bool first = true;
		foreach(v; data) {
			if(first) first = false;
			else b ~= ", ";
			b ~= v.toString();
		}
		b ~= "}";
		return b;
	}

	/**
		Add to the end of the list.
	**/
	public void add(HaxeValue v) {
		data.append(toDynamic(v));
	}

	public void clear() {
		data.clear();
	}

	/**
		Returns first element, null if empty
	**/
	public Dynamic first() {
		return data.head;
	}

	public bool isEmpty() {
		return data.size == 0;
	}

	/**
		Return last element, null if empty
	**/
	public Dynamic last() {
		return data.tail;
	}

	/**
		Remove and returns first element, null if empty
	**/
	public Dynamic pop() {
		Dynamic d;
		if(data.take(d))
			return d;
		return null;
	}

	/**
		Add to beginning of list
	**/
	public void push(HaxeValue v) {
		data.prepend(toDynamic(v));
	}

	/**
		Remove first element that equals v. True if something removed
	**/
	public bool remove(HaxeValue v) {
		auto c = data.remove(toDynamic(v));
		return c == 0 ? false : true;
	}

	Dynamic toDynamic(HaxeValue v) {
		if(v is null)
			return new Dynamic(new Null);
		if(v.type == HaxeType.TDynamic)
			return cast(Dynamic) v;
		return new Dynamic(v);
	}

	public char[] __serialize() {
		auto s = new Serializer();
		s.buf ~= "l";
		foreach(v; data) {
			s.serialize(v.value);
		}
		s.buf ~= "h";
		return s.buf;
	}

	public bool __unserialize() {
		return false;
	}
}