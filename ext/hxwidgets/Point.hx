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

package hxwidgets;

#if flash
class Point extends flash.geom.Point {
#else
class Point {

	public var x:Float;
	public var y:Float;
	public var length(get_length,null):Float;
#end

    public function new( _x:Float, _y:Float ) {
#if flash
		super(_x, _y);
#else
        x = _x;
        y = _y;
#end
    }

#if !flash
    public function add( p:Point ) : Point {
        return new Point( x+p.x, y+p.x );
    }

    public function clone() : Point {
        return new Point( x, y );
    }

    public function normalize( thickness:Float ) : Void {
        throw("NYI");
    }

    public function offset( dx:Float, dy:Float ) : Void {
        x+=dx;
        y+=dy;
    }

    public function subtract( p:Point ) : Point {
        return new Point( x-p.x, y-p.y );
    }

    public function toString() : String {
        return("("+x+","+y+")");
    }
#end

	//////////////////////////////////////
	//			Properties				//
	//////////////////////////////////////
#if !flash
    private function get_length() : Float {
        return( Math.sqrt( Math.pow(x,2) + Math.pow(y,2) ) );
    }
#end

	//////////////////////////////////////
	//			Statics 				//
	//////////////////////////////////////
#if !flash
    static public function distance( pt1:Point, pt2:Point ) : Float {
        var d:Point = pt2.clone();
        d.subtract(pt1);
        return d.length;
    }

    static public function interpolate( pt1:Point, pt2:Point, f:Float ) : Point {
        var d:Point = new Point( (pt2.x-pt1.x)*f, (pt2.y-pt1.y)*f );
        d.add(pt1);
        return d;
    }

    static public function polar( len:Float, angle:Float ) : Point {
        return new Point( len * Math.cos(angle), len * Math.sin(angle) );
    }
#end

}
