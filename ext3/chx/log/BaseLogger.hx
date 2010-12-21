package chx.log;

import chx.log.LogLevel;

class BaseLogger implements IEventLog {
	
	public var serviceName : String;
	public var level : LogLevel;
	
	/**
		Create a logger under the program name [service], which
		will only log events that are greater than or equal to
		LogLevel [level]
	**/
	public function new(service : String, level : LogLevel) {
		if(EventLog.defaultServiceName == null)
			EventLog.defaultServiceName = service;
		if(EventLog.defaultLevel == null)
			EventLog.defaultLevel = LogLevel.NOTICE;
		this.serviceName = service;
		this.level = level;
	}
	
	/**
	 * Adds this logger to the chain of event loggers, only if it does not
	 * yet exist.
	 */
	public function addToLogChain():Void {
		EventLog.add(this);
	}
	
	/**
	 * Closes this logger
	 */
	public function close():Void {
	}
	
	public inline function debug(s:String) : Void { log(s,DEBUG); }
	public inline function info(s:String) : Void { log(s,INFO); }
	public inline function notice(s : String) : Void { log(s,NOTICE); }
	public inline function warn(s : String) : Void { log(s,WARN); }
	public inline function error(s : String) : Void { log(s,ERROR); }
	public inline function critical(s : String) : Void { log(s,CRITICAL); }
	public inline function alert(s : String) : Void { log(s,ALERT); }
	public inline function emerg(s : String) : Void { log(s, EMERG); }
	
	
	public function log(s : String, ?lvl:LogLevel) {
		throw "Override";
	}
}