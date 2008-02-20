package hxspec;
 import haxe.unit.TestStatus;

class SpecResult {

	var m_tests : List<TestStatus>;
	public var success(default,null) : Bool;

	public function new() {
		m_tests = new List();
		success = true;
	}

	public function add( t:TestStatus ) : Void {
		m_tests.add(t);
		if( !t.success )
			success = false;
	}

	public function toString() : String
	{
		var buf = new StringBuf();
		var failures = 0;
		for ( test in m_tests ){
			if (test.success == false){
				buf.add("* ");
				buf.add(test.classname);
				buf.add(' - ');
				var m = test.method;
				for(i in 0 ... m.length) {
					var c = m.charAt(i);
					buf.add( if(c == '_') ' ' else c ); // Convert _ to [space]
				}
				buf.add('\n');

				buf.add('Failed ');
				if( test.posInfos != null )
				{
					buf.add('[');
					buf.add(test.posInfos.fileName);
					buf.add(":");
					buf.add(test.posInfos.lineNumber);
					buf.add("] ");
				/*	buf.add(test.posInfos.className);
					buf.add(".");
					buf.add(test.posInfos.methodName);
					buf.add(") - ");
				*/}
				buf.add(test.error);
				buf.add("\n");

				if (test.backtrace != null) {
					buf.add(test.backtrace);
					buf.add("\n");
				}

				buf.add("\n");
				failures++;
			}
		}
		buf.add("\n");
		if (failures == 0)
			buf.add("OK - ");
		else
			buf.add("FAILED - ");

		buf.add(m_tests.length);
		buf.add(" expectations, ");
		buf.add(failures);
		buf.add(" failed, ");
		buf.add( (m_tests.length - failures) );
		buf.add(" success");
		buf.add("\n");
		return buf.toString();
	}

}
