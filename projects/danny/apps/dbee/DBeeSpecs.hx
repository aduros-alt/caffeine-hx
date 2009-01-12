/*
 *	Copyright (c) 2008, The Caffeine-hx project contributors
 *	Original author: Danny Wilson from deCube.net
 *	Contributors:
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; either version 2 of the License, or
 *	(at your option) any later version.
 *	
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 */
package dbee;

class DBeeSpecs
{
	public static function main()
	{
		var r = new hxspec.SpecRunner();
		r.add(new specifications.dbee.field.DatafieldSpecs());
		r.add(new specifications.dbee.ModelSpecs());
		r.add(new specifications.dbee.MockPersistentObjectSpecs());
		r.add(new specifications.dbee.MemoryPersistenceManagerSpecs());
		r.add(new specifications.dbee.field.TextSpecs());
		r.add(new specifications.dbee.field.IntegerSpecs());
		r.add(new specifications.dbee.ReferenceSpecs());
		/*
		r.add(new specifications.dbee.field.Country());
		r.add(new specifications.dbee.field.Email());
		r.add(new specifications.dbee.field.IPAddress());
		r.add(new specifications.dbee.field.Money());
		r.add(new specifications.dbee.field.Zipcode());
		*/
		r.run();
	}
}
