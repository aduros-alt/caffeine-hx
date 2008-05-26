/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */


package formats.json;

class JsonObject {
	public var data(default,null) : Dynamic;

	/**
		Initial data may be a JSON formatted String, or an
		Object, or null.
	**/
	public function new(?initialData : Dynamic) {
		if(initialData == null)
			this.data = {};
		else if(Std.is(initialData, String))
			this.data = JSON.decode(initialData);
		else if(Reflect.isObject(initialData))
			this.data = initialData;
		else
			throw new JsonException("JsonObject can not parse initialData");
	}

	public function toString() {
		if(data == null) return "";
		return JSON.encode(data);
	}

	static function DOES_NOT_EXIST(k:String) {
		return "Json key '"+k+"' does not exist";
	}

	static function CAN_NOT_CONVERT(k:String, t:String) {
		return "Json key '"+k+"' can not be converted to type '"+t+"'";
	}

	/**
		Descend down an object dot notation path to recover the object there.
		Returns null if the object, or any path part, does not exist.
	**/
	public function get(k : String) : Dynamic {
		if(data == null) return null;

		var kp = k.split(".");
		var o = data;
		for(i in kp) {
			if(!Reflect.hasField(o, i)) {
				return null;
			}
			o = Reflect.field(o, i);
		}
		return o;
	}

	public function set(k :String, v : Dynamic) {
		if(data == null)
			data = {};
		var kp = k.split(".");
		var o = data;
		var lastO = data;
		var key : String;
		for(i in kp) {
			lastO = o;
			if(!Reflect.hasField(o, i))
				Reflect.setField(o, i, {});
			o = Reflect.field(o, i);
			key = i;
		}
		if(Std.is(v, JsonObject))
			Reflect.setField(lastO, key, v.data);
		else
			Reflect.setField(lastO, key, v);
	}

	/**
		TODO: merge with/seperate from concat()
	**/
	public function setAll(o:Dynamic) {
		if(!Reflect.isObject(o))
			throw new JsonException("Must be an object");
		for(i in Reflect.fields(o))
			data.set(i, Reflect.field(o, i));
	}

	/**
		Return a new Json Object by appending [j] to this. Fields
		in [j] will overwrite [this]
	**/
	public function concat(j : JsonObject) : JsonObject {
		var d = {};
		var a = [this.data, j.data];
		for(o in a) {
			for(i in Reflect.fields(o))
				Reflect.setField(d, i, Reflect.field(o, i));
		}
		var nj = new JsonObject();
		nj.data = d;
		return nj;
	}

	public function has(k : String) : Bool {
		if(data == null) return false;
		var kp = k.split(".");
		var o = data;
		for(i in kp) {
			if(!Reflect.hasField(o, i))
				return false;
			o = Reflect.field(o, i);
		}
		return true;
	}


	/**
		Returns a bool.
	**/
	public function getBool(key : String) : Bool {
		if(!has(key))
			throw new JsonException(DOES_NOT_EXIST(key));
		var o = get(key);
		if(Std.is(o, Bool))
			return o;
		if(Std.is(o,String)) {
			var s = Std.string(o).toLowerCase();
			if(s == "true")
				return true;
			if(s == "false")
				return false;
		}
		throw new JsonException(CAN_NOT_CONVERT(key, "Bool"));
		return false;
	}

	public function getFloat(key : String) : Float {
		if(!has(key))
			throw new JsonException(DOES_NOT_EXIST(key));
		var o = get(key);
		if(Std.is(o,Float)) {
			return o;
		}
		if(Std.is(o,Int)) {
			return o * 1.0;
		}
		var rv : Float;
		try {
			rv =  Std.parseFloat(Std.string(o));
		} catch(e : Dynamic) {
			throw new JsonException(CAN_NOT_CONVERT(key, "Float"));
		}
		return rv;
	}

	public function getInt(key : String) : Int {
		if(!has(key))
			throw new JsonException(DOES_NOT_EXIST(key));
		var o = get(key);
		if(Std.is(o,Int))
			return o;
		if(Std.is(o,String)) {
			return Std.parseInt(Std.string(o));
		}
		if(Std.is(o,Float)) {
			return Std.int(o);
		}
		throw new JsonException(key + " is not an Int.");
		return 0;
	}

	/**
		Returns a JsonArray from the specified key <br />
		TODO: Optimize.
	**/
	public function getJsonArray(key : String) : JsonArray {
		if(!has(key))
			throw new JsonException(DOES_NOT_EXIST(key));
		return JsonArray.fromObject(JSON.encode(get(key)));
	}

	/**
		Return key as a new Json Object. If it cannot be converted,
		an exception is thrown.
	**/
	public function getJsonObject(key : String) : JsonObject {
		if(!has(key))
			throw new JsonException(DOES_NOT_EXIST(key));
		var rv : JsonObject;
		try {
			rv = new JsonObject(get(key));
		}
		catch(e : Dynamic) {
			throw new JsonException(CAN_NOT_CONVERT(key,"JsonObject"));
		}
		return rv;
	}

	/**
		Throws JsonException if key does not exist
	**/
	public function getString(key : String) : String {
		if(!has(key))
			throw new JsonException(DOES_NOT_EXIST(key));
		var o = get(key);
		if(o == null)
			return null;
		if(Std.is(o,String))
			return o;
		return Std.string(o);
	}


	public function optBool(key:String, ?defaultValue : Bool) : Bool {
		return try {
			getBool(key);
		} catch (e : JsonException) {
			defaultValue;
		}
	}

	public function optFloat(key:String, ?defaultValue : Float) : Float {
		return try {
			getFloat(key);
		} catch (e : JsonException) {
			defaultValue;
		}
	}

	public function optInt(key:String, ?defaultValue : Int) : Int {
		return try {
			getInt(key);
		} catch (e : JsonException) {
			defaultValue;
		}
	}

	public function optString(key:String, ?defaultValue : String) : String {
		return try {
			getString(key);
		} catch (e : JsonException) {
			defaultValue;
		}
	}

	public function remove(k :String) {
		if(data == null) {
			data = {};
			return;
		}
		var kp = k.split(".");
		var o = data;
		var lastO = data;
		var key : String;
		for(i in kp) {
			lastO = o;
			if(!Reflect.hasField(o, i))
				Reflect.setField(o, i, {});
			o = Reflect.field(o, i);
			key = i;
		}
		Reflect.deleteField(lastO, key);
	}

}


