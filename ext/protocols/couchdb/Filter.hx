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

package protocols.couchdb;

/**
	A view Filter, which limits the rows returned in a view.
**/
class Filter {
	/** The number of rows to return **/
	public var count(default, setCount) : Null<Int>;
	/** the last key to include in the result set **/
	public var endKey(default, setEndKey) : String;
	/** reverse order of result set **/
	public var reverse(default, setReverse) : Bool;
	public var skip(default, setSkip) : String;
	/** the first key to use in result set **/
	public var startKey(default, setStartKey) : String;
	/** false improves performance, but Couch may not have updated records **/
	public var update(default, setUpdate) : Bool;

	public function new( ) {
		this.update = true;
	}

	/**
		The query params to be added to the URL for this Query
	**/
	public function getQueryParams() : Hash<String> {
		var rv = new Hash();
		if(startKey != null)
			rv.set("startkey", startKey);
		if(endKey != null)
			rv.set("endkey", endKey);
		if(skip != null)
			rv.set("skip", skip);
		if(count != null)
			rv.set("count", Std.string(count));
		if(update != null)
			rv.set("update", Std.string(update));
		if(reverse != null)
			rv.set("reverse", Std.string(reverse));
		return rv;
	}

	/**
		Number of entries to return
	**/
	public function setCount(v : Int) : Int {
		this.count = v;
		return v;
	}

	/**
		Key to stop listing at
	**/
	public function setEndKey(key : String) : String {
		this.endKey = key;
		return key;
	}

	/**
		Reverse list
	**/
	public function setReverse(v : Bool) {
		this.reverse = v;
		return v;
	}

	/**
		Skip specific keys (may not work)
	**/
	public function setSkip(s : String) : String {
		this.skip = s;
		return s;
	}

	/**
		Key to start at
	**/
	public function setStartKey(key : String) : String {
		this.startKey = key;
		return key;
	}

	/**
		To improve performance, the update flag can be set to false,
		which means couchdb may not do refreshing before processing the view.
	**/
	public function setUpdate(v : Bool) : Bool {
		this.update = v;
		return v;
	}

}
