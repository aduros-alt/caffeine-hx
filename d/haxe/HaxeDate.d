module haxe.HaxeDate;

import haxe.HaxeTypes;

private import tango.text.convert.TimeStamp;
private import tango.time.Time;
private import tango.time.chrono.Gregorian;
private import tango.time.Clock;
private import tango.time.WallClock;
private import Util = tango.text.Util;
private import IntUtil = tango.text.convert.Integer;
import tango.io.Console;

class HaxeDate : HaxeClass {
	public HaxeType type() { return HaxeType.TDate; }
	public Dynamic[] data;
	public char[] __classname() { return "HaxeDate"; }
	public Time value;

	this(int year, int month, int day, int hour, int min, int sec) {
		TimeOfDay tod;
		Date date;
		date.year = year;
		date.month = month + 1;
		date.day = day;
		tod.hours = hour;
		tod.minutes = min;
		tod.seconds = sec;
		value = Gregorian.generic.toTime(date, tod);
	}

	this() {
		value = WallClock.now();
	}

	/**
		Day, range 1-31
	**/
	public uint getDate() {
		return Gregorian.generic.getDayOfMonth(value);
	}

	/**
		Day of week, 0-6
	**/
	public uint getDay() {
		return Gregorian.generic.getDayOfWeek(value);
	}

	/**
		1 - 366
	**/
	public uint getDayOfYear() {
		return Gregorian.generic.getDayOfYear(value);
	}

	/**
		Year
	**/
	public uint getFullYear() {
		return Gregorian.generic.getYear(value);
	}

	/**
		24 hour, 0-23
	**/
	public uint getHours() {
		return value.time.hours;
	}

	/**
		0-59
	**/
	public uint getMinutes() {
		return value.time.minutes;
	}

	/**
		0-11
	**/
	public uint getMonth() {
		return Gregorian.generic.getMonth(value) - 1;
	}

	/**
		0-59
	**/
	public int getSeconds() {
		return value.time.seconds;
	}

	public double getTime() {
		return 0;
	}

	public char[] toString() {
		char [] format4(long v) {
			return IntUtil.format(new char[5], v, "d4");
		}
		char [] format2(long v) {
			return IntUtil.format(new char[5], v, "d2");
		}
		char[] buf;
		buf ~= format4(getFullYear());
		buf ~= "-";
		buf ~= format2(getMonth() + 1);
		buf ~= "-";
		buf ~= format2(getDate());
		buf ~= " ";
		TimeOfDay tod = value.time();
		buf ~= format2(cast(long) tod.hours);
		buf ~= ":";
		buf ~= format2(cast(long) tod.minutes);
		buf ~= ":";
		buf ~= format2(cast(long) tod.seconds);

		return buf.dup;
	}

	/**
		Parse a date or date/time format.
		TODO: This needs work as tango time() function is broken
	**/
	public static HaxeDate fromString(T)(T[] s) {
		Time t;
		Date date;
		TimeOfDay tod;
		int pos = 0;

		if(s.length == 19) { // YYYY-MM-DD HH:MM:SS
			//tango is broken
			//auto v = s.dup ~ ",000";
			//pos = iso8601(v, t);
			T* p = s.ptr;
			if(parseDate(date, p)) {
				if(*p++ == ' ') {
					if(parseTime(tod, p)) {
						t = Gregorian.generic.toTime (date, tod);
						pos = p - s.ptr;
					}
				}

			}

		}
		else if(s.length == 23) { // YYYY-MM-DD HH:MM:SS,ms
			pos = iso8601(s, t);
			if(pos == 0) // Sun Nov 6 08:49:37 1994 (23 or 24 long)
				pos = asctime(s, t);
		}
		else if(s.length == 24) { // Sun Nov 6 08:49:37 1994 (23 or 24 long)
			pos = asctime(s, t);
		}
		else if(s.length == 8) { // HH:MM:SS
			T* p = s.ptr;
			if(parseTime(tod, p)) {
				pos = p - s.ptr;
				auto hd = now();
				date.year = hd.getFullYear();
				date.month = hd.getMonth() + 1;
				date.day = hd.getDate();
				t = Gregorian.generic.toTime (date, tod);
				// convert from UTC
				auto dt = WallClock.toDate(t);
				tod = dt.time;
				date = dt.date;
				t = Gregorian.generic.toTime (date, tod);
			}
		}
		else if(s.length == 10) { // YYYY-MM-DD
			T* p = s.ptr;
			if(parseDate(date, p)) {
				pos = p - s.ptr;
				t = Gregorian.generic.toTime (date, tod);
			}
			else
				pos = 0;
		}
		// others?
		if(pos == 0) {
			pos = rfc1123(s, t);
		}
		if(pos == 0) {
			pos = rfc850(s, t);
		}
		if(pos == 0)
			throw new Exception("Unable to parse date " ~ s ~ " length: "~ IntUtil.toString(s.length));

		auto hd = new HaxeDate();
		hd.value = t;
		return hd;
	}

	public char[] __serialize() {
		return toString();
	}

	public bool __unserialize(HaxeObject* o) {
		return false;
	}

// 	public static HaxeDate fromTime( double t ) {
// 	}

	public static HaxeDate now() {
		return new HaxeDate();
	}

	private	static int parseInt(T)(inout T* p)
	{
		int value;
		while (*p >= '0' && *p <= '9')
			value = value * 10 + *p++ - '0';
		return value;
	}

	private static bool parseDate(T)(ref Date date, inout T* p) {
		return(
			(date.year = parseInt(p)) > 0 &&
			*p++ == '-' &&
			(date.month = parseInt(p)) > 0 &&
			*p++ == '-' &&
			(date.day = parseInt(p)) > 0
		);
	}

	private static bool parseTime(T)(ref TimeOfDay tod, inout T* p) {
		return(
			(tod.hours = parseInt(p)) >= 0 &&
			*p++ == ':' &&
			(tod.minutes = parseInt(p)) >= 0 &&
			*p++ == ':' &&
			(tod.seconds = parseInt(p)) >= 0
		);
	}
}