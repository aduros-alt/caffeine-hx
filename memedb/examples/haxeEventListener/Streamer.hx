//import protocols.http.Request;
//import formats.json.JSON;
import system.log.LogLevel;


class Streamer {
	static var PROGNAME     : String    = "streamer";
	static var LOGLEVEL     : LogLevel  = DEBUG;
	static var STDIN 		: neko.io.FileInput;
	static var logger 		: system.log.Syslog;

    public static function main() {
        STDIN = neko.io.File.stdin();
        logger = new system.log.Syslog(PROGNAME, LOGLEVEL);
        logger.info("Startup");

		while(true) {
			var line = StringTools.trim(STDIN.readLine());
			logger.info("Received message " + line);
			if(line == "shutdown") neko.Sys.exit(0);
		}
	}

}
