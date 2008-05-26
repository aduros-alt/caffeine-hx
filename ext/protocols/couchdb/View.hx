
package couchdb;

import formats.json.JsonObject;

/**
	A dynamic, or "AdHoc", View.
**/

/*
API change
http://mail-archives.apache.org/mod_mbox/incubator-couchdb-dev/200805.mbox/%3c8A150DFE-97BB-41D5-82D4-04D15B34ECFB@apache.org%3e
*/

class View {
	/** the limits on the view **/
	public var filter : Filter;
	/** the language interpreter is to use **/
	public var language(getLanguage, setLanguage) : String;
	/** the mapping function (WHERE clause)**/
	public var mapFunction(getMapFunction,setMapFunction) : String;
	/** the reduce (summation etc.) function **/
	public var reduceFunction(getReduceFunction,setReduceFunction) : String;

	/** the name of the view **/
	private var name : String;
	private var json : JsonObject;


	public function new( ?map : String, ?reduce : String, ? language : String )
	{
		this.json = new JsonObject();
		this.name = "_temp_view";

		this.mapFunction = map;
		this.reduceFunction = reduce;
		this.language = language;
	}

	public function toString() {
		return json.toString();
	}

	/**
		Returns the underlying object
	**/
	public function getDefinition() : Dynamic {
		return json.data;
	}

	/**
		The view Filter
	**/
	public function getFilter() : Filter {
		return filter;
	}

	/**
		Returns the language this script is interpreted with.
	**/
	public function getLanguage() : String {
		return json.optString("language", "javascript");
	}

	/**
		The map function, if one exists.
	**/
	function getMapFunction() : String {
		return json.optString("map", null);
	}

	/**
		The view name
	**/
	public function getName() : String {
		return name;
	}

	/**
		Return the name URL encoded, the full path for this view.
	**/
	public function getPathEncoded() : String {
		// ad-hoc requires no encoding.
		return name;
	}

	/**
		The reduce function, if one exists
	**/
	function getReduceFunction() : String {
		return json.optString("reduce", null);
	}

	/**
		Setting the filter to null removes it.
	**/
	function setFilter(f : Filter) : Filter {
		this.filter = f;
		return f;
	}

	/**
		Set the language interpreter for this view script
	**/
	function setLanguage(v : String) : String {
		// when not provided, javascript is the default that CouchDB will use
		if(v == null)
			//json.set("language", "javascript");
			json.remove("language");
		else
			json.set("language", v);
		return v;
	}

	function setMapFunction(code : String) : String {
		if(code == null)
			json.remove("map");
		else
			json.set("map", code);
		return code;
	}


	function setReduceFunction(code:String) : String {
		if(code == null)
			json.remove("reduce");
		else
			json.set("reduce", code);
		return code;
	}

	/**
		Changes an AdHoc view into a DesignView, suitable for attaching
		to a DesignDocument.
	**/
	public function toDesignView(newName:String, ?doc : DesignDocument) : DesignView {
		var rv = new DesignView(newName, this.mapFunction, this.reduceFunction, this.language);
		//trace(rv);
		if(doc != null) {
			doc.addView(rv);
			//rv.setDesignDocument(doc);
		}

		return rv;
	}
}