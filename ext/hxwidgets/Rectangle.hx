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
class Rectangle extends flash.geom.Rectangle {
#else
class Rectangle {
#end

#if !flash
    public var bottom(getBottom,setBottom)	:Float;
	public var bottomRight(getBottomR,setBottomR) :Point;
	public var height(default,setHeight)	: Float;
	public var left(getX,setX)				:Float;
	public var right(getRight,setRight)		:Float;
	public var size(getSize,setSize)		:Point;
	public var top(getY,setY)				:Float;
	public var topLeft(getTopLeft,setTopLeft) :Point;
	public var width(default,setWidth)		:Float;
	public var x(default,default)			:Float;
	public var y(default,default)			:Float;
#end
    public var r(getRight,setRight)			:Float;
	public var b(getBottom,setBottom)		:Float;
	public var cx(getCenterX,null)			:Float;
	public var cy(getCenterY,null)			:Float;
	public var center(getCenter,null)		:Point;

    public function new( ?x:Float, ?y:Float, ?width:Float, ?height:Float) :Void {
#if flash
		super(x,y,width,height);
#else
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
#end
    }

#if !flash
	public function clone() : Rectangle {
		return new Rectangle(x,y,width,height);
	}

    public function contains( x:Float, y:Float ) :Bool {
        return( x>=this.x && x<=this.right && y>=this.y && y<=this.bottom );
    }

    public function containsPoint( p:Point ) :Bool {
        return( p.x>=this.x && p.x<=this.right && p.y>=this.y && p.y<=this.bottom );
    }

	public function containsRect( rect: Rectangle ) : Bool {
		return ( containsPoint(rect.topLeft) && containsPoint(rect.bottomRight));
	}

	public function equals(rect : Rectangle) : Bool {
		return ( x==rect.x && y==rect.y && width==rect.width && height==rect.height );
	}

	public function inflate(dx:Float, dy:Float) : Void {
		width += dx;
		height += dy;
	}

	public function inflatePoint(p:Point) : Void {
		inflate(p.x, p.y);
	}

	/* Todo
	public function intersection( rect : Rectangle ) : Rectangle {
		var r = new Rectangle(0,0,0,0);

		return r;
	}
	*/

    public function intersects( i:Rectangle ) :Bool {
        return( x<=i.right && right>=i.x && y<=i.bottom && bottom>=i.y );
    }

	public function isEmpty() : Bool {
		return ( width == 0. || height == 0.);
	}
#end

    public function merge( m:Rectangle ) :Void {
        if( m.x<x ) x=m.x;
        if( m.y<y ) y=m.y;
        if( m.right>right ) right=m.right;
        if( m.bottom>bottom ) bottom=m.bottom;
    }

#if !flash
	public function offset(dx:Float, dy:Float) :Void {
		x += dx;
		y += dy;
	}

	public function offsetPoint(p:Point) : Void {
		offset(p.x, p.y);
	}

	public function setEmpty() : Void {
		x = y = width = height = 0.;
	}

    public function toString() :String {
        return("("+l+","+t+" "+(r-l)+"x"+(b-t)+")");
    }
#end

#if !flash
	public function union(toUnion:Rectangle) : Rectangle {
		var r = clone();
		r.merge(toUnion);
		return r;
	}
#end

    public function within( w:Rectangle ) :Bool {
        return( x>=w.x && y>=w.y && right<=w.right && bottom<=w.bottom );
    }



	//////////////////////////////////////
	//			Properties				//
	//////////////////////////////////////
	function getRight() : Float {
		return x + width;
	}
	function setRight(v:Float) : Float {
		x = v -x;
		return v;
	}
	function getBottom() : Float {
		return y + height;
	}
	function setBottom(v:Float) : Float {
		height = v - y;
		return v;
	}
	public function getCenter() : Point {
		return new Point(getCenterX(), getCenterY());
	}
    function getCenterX() :Float {
        return( x + (width/2) );
    }
    function getCenterY() :Float {
        return( y + (height/2) );
    }

#if !flash
	function getBottomR() : Point {
		return new Point(x+width, y+height);
	}
	function setBottomR(v:Point) : Point {
		width = v.x - x;
		height = v.y - y;
		return v;
	}
	function setHeight(v : Float) : Float {
		height = v;
		return v;
	}
	function getSize() : Point {
		return new Point(width, height);
	}
	function setSize(v : Point): Point {
		width = v.x;
		height = v.y;
		return v;
	}
	function getTopLeft() : Point {
		return new Point(x,y);
	}
	function setTopLeft(v:Point) :Point {
		x = v.x;
		y = v.y;
		return v;
	}
	function setWidth(v:Float) : Float {
		width = v;
		return v;
	}
#end

	public function centerHorizontalIn(r : Rectangle) {
		x = x + (r.cx - this.cx);
	}

	public function centerVerticalIn(r : Rectangle) {
		y = y + (r.cy - this.cy);
	}

	public function centerIn(r : Rectangle) {
		centerHorizontalIn(r);
		centerVerticalIn(r);
	}

	//////////////////////////////////////
	//			Statics 				//
	//////////////////////////////////////
#if flash
	/**
		Clones a flash rectangle to this class.
	**/
	public static function ofFlash(r:flash.geom.Rectangle) {
		var n = new Rectangle(r.x,r.y,r.width,r.height);
		return n;
	}
#end

}


