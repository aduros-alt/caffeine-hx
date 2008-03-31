package stdlib;

import unit.Assert;

class TestDate {
	public function new(){}
	
	public function testFormat(){
		var d = new Date(2006,2,19,8,20,3);
		Assert.equals("2006-03-19 08:20:03",d.toString());
		Assert.equals("2006-03-19 08:20:03",Std.string(d));
		Assert.equals("2006-03-19 08:20:03",DateTools.format(d,"%Y-%m-%d %H:%M:%S"));
	}


	public function testDelta(){
		var d = new Date(2006,2,19,8,20,3);
		d = DateTools.delta(d,3600*24*1000);
		Assert.equals("2006-03-20 08:20:03",DateTools.format(d,"%Y-%m-%d %H:%M:%S"));
	}

	public function testFormat2(){
		#if neko
		// strftime on windows does not support all options
		if( neko.Sys.systemName() == "Windows" ) {
			Assert.isTrue(true);
			return;
		}
		#end

		var d = new Date(2006,2,19,8,20,3);

		Assert.equals("% 20 19 03/19/06 19 08 08  8  8 03 20 AM 08:20:03 AM 08:20 1142752803 03 08:20:03 7 0 06 2006",DateTools.format(d,"%% %C %d %D %e %H %I %k %l %m %M %p %r %R %s %S %T %u %w %y %Y"));
	}

	public function testGetters(){
		var d = new Date(2006,2,19,8,20,3);
		Assert.equals(2006,d.getFullYear());
		Assert.equals(2,d.getMonth());
		Assert.equals(19,d.getDate());
		Assert.equals(8,d.getHours());
		Assert.equals(20,d.getMinutes());
		Assert.equals(3,d.getSeconds());
		Assert.equals(0,d.getDay());
	}

	public function testDayOfMonth(){
		Assert.equals(30,DateTools.getMonthDays(Date.fromString("2006-06-01")));
		Assert.equals(31,DateTools.getMonthDays(Date.fromString("2006-07-01")));
		Assert.equals(29,DateTools.getMonthDays(Date.fromString("2000-02-01")));
		Assert.equals(29,DateTools.getMonthDays(Date.fromString("1996-02-01")));
		Assert.equals(28,DateTools.getMonthDays(Date.fromString("1997-02-01")));
	}
}
