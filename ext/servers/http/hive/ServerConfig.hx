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

package servers.http.hive;

import config.XmlConfig;
import haxe.xml.Check;

class ServerConfig extends XmlConfig {
	public var host : String;
	public var port : Int;
	public var maxConnections : Int;
	public var serverRoot : String;
	public var logFormat : String;
	public var accessLog : String;
	public var errorLog : String;
	public var threads : Int;
#if HIVEDB
	public var dbName : String;
	public var dbPath : String;
	public var nodeNumber : Int;
	public var minimumNodes : Int;
#end


	var sec : XmlConfigSection;
	public var fast(default, null) : haxe.xml.Fast;

	override public function loadFile( path : String ) {
		super.loadFile(path);
		sec = getSection("hive", validate);
		populate();
	}

	override public function loadUrl( url : String, completeCallback : Void->Void ) {
		var me = this;
		super.loadUrl(url,
			function() {
				me.sec = me.getSection("hive", me.validate);
				me.populate();
				completeCallback();
			}
		);
	}

	override public function loadString( s : String ) {
		super.loadString( s );
		sec = getSection("hive", validate);
		populate();
	}

	function populate() {
		fast = new haxe.xml.Fast(sec.xml);
		if(host == null)
			host = fast.node.host.innerData;
		if(port == null)
			port = Std.parseInt(fast.node.port.innerData);
		if(maxConnections == null)
			maxConnections = Std.parseInt(fast.node.maxConnections.innerData);
		if(serverRoot == null)
			serverRoot = fast.node.serverRoot.innerData;
		if(logFormat == null)
			logFormat = fast.node.logFormat.innerData;
		if(accessLog == null)
			accessLog = fast.node.accessLog.innerData;
		if(errorLog == null)
			errorLog = fast.node.errorLog.innerData;
		if(threads == null) {
			threads = try Std.parseInt(fast.node.threads.innerData) catch(e:Dynamic) 10;
		}
#if HIVEDB
		if(dbName == null)
			dbName = fast.node.dbName.innerData;
		if(dbPath == null)
			dbPath = fast.node.dbPath.innerData;
		if(nodeNumber == null)
			nodeNumber = Std.parseInt(fast.node.nodeNumber.innerData);
		if(minimumNodes == null)
			minimumNodes = Std.parseInt(fast.node.minimumNodes.innerData);
#end
	}

	function validate() : haxe.xml.Rule {
		var rule: haxe.xml.Rule =
		RNode("hive", [],
			RList([
				RNode("host",[],RData()),
				RNode("port",[],RData(FInt)),
				RNode("maxConnections",[],RData(FInt)),
				RNode("serverRoot",[],RData()),
				RNode("logFormat",[],RData()),
				RNode("accessLog",[],RData()),
				RNode("errorLog",[],RData()),
#if HIVEDB
				RNode("dbName", [], RData()),
				RNode("dbPath", [], RData()),
				RNode("nodeNumber",[],RData(FInt)),
				RNode("minimumNodes",[],RData(FInt)),
				RNode("backbone",[Attrib.Att("type")],
					RMulti(
						RNode("server",[
							Attrib.Att("host"),
							Attrib.Att("port"),
							Attrib.Att("username"),
							Attrib.Att("password")
						])
					, true)
				),
#end
				ROptional(
					RNode('schedRealtime',[],
						RNode('threads',[],RData(FInt))
					)
				),
				ROptional(
					RNode('schedThreadPool',[],ROptional(RData()))
				),
			],false)
		);
		return rule;
	}
}