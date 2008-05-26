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

package couchdb;

import formats.json.JsonObject;
import formats.json.JsonArray;

/**
	A Result set for a query, much like that in any relational database.
**/
class Result extends Document {
	public var rowCount(default, null) : Int;
	public var offset(default, null) : Int;
	public var ok(default,null) : Bool;

	private var view : View;
	private var result : Dynamic;
	private var errId : String;
	private var errReason : String;

	public function new(d: Database, v : View, t : Transaction) {
		/**
		Reduced result:
			{"ok":true,"result":491}
		Mapped result:
		{
			"offset":0,
			"total_rows":10,
			"rows":[{"id":"0","key":"0","value":?}, ...]
		}
		**/
		super();
		this.database = d;
		this.view = v;
		if(!t.isOk()) {
			try {
				this.data = t.getObject();
			}
			catch(e:Dynamic) { this.data = {}; };
			this.errId = optString("error","unknown error");
			this.errReason = optString("reason","unknown error");
			this.ok = false;
			this.rowCount = 0;
			this.offset = 0;
		}
		else {
			this.data = t.getObject();
			this.errId = "";
			this.errReason = "";
			this.ok = true;

			// a reduced set
			if(has("ok")) {
				// I assume here that the result field will _not_ be JsonObject.
				// therefore, the success of this try is a fatal error on my part.
				try {
					getJsonObject("result");
					throw "Unhandled exception. Contact developers.";
				} catch(e : Dynamic) {}
				this.rowCount = 1;
				this.data =
				{
					rows : [{id: null, key:null, value: get("result")}]
				};
			}
			else {
				this.rowCount = getInt("total_rows");
				this.offset = getInt("offset");
			}
		}
		trace(Std.string(data));
	}

	/**
		Retrieves a list of Rows that matched this View.
	**/
	public function getRows() : List<Row>
	{	//{"total_rows":1000,"offset":0,"rows":[
		//{"id":"0","key":"0","value":{"rev":"2922574358"}}, ...
		var rv = new List<Row>();
		if(!ok)
			return rv;


		var a : JsonArray;
		//try {
			a = getJsonArray("rows");
		//} catch(e : Dynamic) { return rv; }
		//trace(Std.string(a));
		var l = a.length;
		for(i in 0...l) {
			if(a.get(i) != null && a.getString(i) != "null") {
				var dr = new Row(this.database, a.getJsonObject(i));
				dr.setDatabase(database);
				rv.add(dr);
			}
		}
		return rv;
	}

	/**
		Returns each row as a string representation of the Json object. Useful
		for debugging the result set, to see if the objects you are expecting
		from the query actually exist.
	**/
	public function getStrings() : List<String>
	{
		var rv = new List<String>();
		if(!ok)
			return rv;

		var a = getJsonArray("rows");
		var l = a.length;
		for(i in 0...l) {
			if(a.get(i) != null && a.getString(i) != "null") {
				rv.add(Std.string(a.getJsonObject(i)));
			}
		}
		return rv;
	}

	/**
		This will be true if there was no error during the query.
	**/
	public function isOk() {
		return ok;
	}

	/**
		The view this result set was generated from.
	**/
	public function getView(?foo:String) : View {
		return this.view;
	}


	/**
		The error code
	**/
	public function getErrorId() : String {
		return errId;
	}

	/**
		Error message
	**/
	public function getErrorReason() : String {
		return errReason;
	}

	/**
		The number of rows in the result set. Also available as the
		property 'rowCount'.
	**/
	public function numRows() : Int {
		return rowCount;
	}
}