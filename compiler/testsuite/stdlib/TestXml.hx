package stdlib;

import unit.Assert;

class TestXml {
	public function new(){}
	
	public function testBase(){
#if !php
		var x = Xml.parse("<coucou var=\"val\">Lala</coucou>");
		Assert.equals(Xml.Document,x.nodeType);
		
		Assert.equals("coucou",x.firstChild().nodeName);
		Assert.equals("Lala",x.firstChild().firstChild().nodeValue);
		Assert.equals("val",x.firstChild().get("var"));

		Assert.equals("var",x.firstChild().attributes().next());
		Assert.equals("<coucou var=\"val\">Lala</coucou>",x.toString());
#end
	}

	public function test2(){
#if !php
		var x = Xml.parse("<coucou var=\"val\"><sub>Pouet !</sub>Lala</coucou>");

		try {
			Assert.isFalse(x.exists("pouet"));
			Assert.isTrue(false);
		}catch( e : Dynamic ){
		}
		
		Assert.equals("coucou",x.firstChild().nodeName);
		Assert.isTrue(x.firstChild().get("pouet")==null);
		Assert.isTrue(x.firstChild().exists("var"));
		Assert.equals("val",x.firstChild().get("var"));

		var i = 0;
		for( n in x.firstChild().elements() ){
			Assert.equals("sub",n.nodeName);
			i++;
		}
		Assert.equals(1,i);
		i = 0;
		for( n in x.firstChild() ){
			i++;
		}
		Assert.equals(2,i);
		i = 0;
		var a = x.firstChild().firstChild().attributes();
		Assert.isTrue(a != null);
		for( n in a ){
			i++;
		}
		Assert.equals(0,i);
#end
	}

	public function test3(){
#if !php
		var x = Xml.parse("<a/>lala<a/><b/><a/>pouet<c/><a/>pouet<c/><a/>");

		var i = 0;
		for( n in x.elementsNamed("a") ){
			i++;
		}
		Assert.equals(5,i);
#end
	}

	// fail on Flash
	#if (flash8 || flash7)
	#else true
	public function testEmptyNode(){
#if !php
		var s = "<p><x/><y></y></p>";
		
		var x = Xml.parse(s);

		Assert.equals("<p><x/><y></y></p>",x.toString());
#end
	}
	#end

	public function testModif(){
#if !php
		var x = Xml.createElement("base");
		x.set("var","val");
		
		var y = Xml.createElement("temp");
		x.addChild(y);
		x.firstChild().nodeName = "un";

		var d = Xml.createElement("deux");
		x.addChild(d);
		
		#if (flash8 || flash7)
		Assert.equals("<base var=\"val\"><un /><deux /></base>",x.toString());
		#else true
		Assert.equals("<base var=\"val\"><un/><deux/></base>",x.toString());
		#end
		
		var z = Xml.createElement("zero");
		x.insertChild(z,0);

		x.set("var","realval");
		
		#if (flash8 || flash7)
		Assert.equals("<base var=\"realval\"><zero /><un /><deux /></base>",x.toString());
		#else true
		Assert.equals("<base var=\"realval\"><zero/><un/><deux/></base>",x.toString());
		#end

		var t = Xml.createElement("trois");

		x.insertChild(t,1);
		x.removeChild(y);
		
		#if (flash8 || flash7)
		Assert.equals("<base var=\"realval\"><zero /><trois /><deux /></base>",x.toString());
		#else true
		Assert.equals("<base var=\"realval\"><zero/><trois/><deux/></base>",x.toString());
		#end

		var q = Xml.createElement("quatre");

		x.insertChild(q,2);
		x.removeChild(d);

		#if (flash8 || flash7)
		Assert.equals("<base var=\"realval\"><zero /><trois /><quatre /></base>",x.toString());
		#else true
		Assert.equals("<base var=\"realval\"><zero/><trois/><quatre/></base>",x.toString());
		#end
		
		Assert.equals(true,x.removeChild(t));
		
		#if (flash8 || flash7)
		Assert.equals("<base var=\"realval\"><zero /><quatre /></base>",x.toString());
		#else true
		Assert.equals("<base var=\"realval\"><zero/><quatre/></base>",x.toString());
		#end
#end
	}

	public function testFirstElement(){
#if !php
		var x = Xml.parse("<?xml ?>     <pouet/>");
		Assert.equals("pouet",x.firstElement().nodeName);
#end
	}
	
	// fail on Flash
	#if (flash8 || flash7)
	#else true
	public function testSpecials(){
#if !php
		var x = Xml.parse("<p var=\"&quot; &lt;&gt;&amp;\"><![CDATA[&lt;<COUCOU>]]>&lt;&gt;&amp;&quot;&</p>");
		var p = x.firstChild();
		Assert.equals("&quot; &lt;&gt;&amp;",p.get("var"));
		var a = new Array<Xml>();
		for( c in p ){
			a.push(c);
		}
		Assert.equals(Xml.CData,a[0].nodeType);
		Assert.equals("&lt;<COUCOU>",a[0].nodeValue);
		Assert.equals(Xml.PCData,a[1].nodeType);
		Assert.equals("&lt;&gt;&amp;&quot;&",a[1].nodeValue);
		
		Assert.equals("<p var=\"&quot; &lt;&gt;&amp;\"><![CDATA[&lt;<COUCOU>]]>&lt;&gt;&amp;&quot;&</p>",x.toString());
#end
	}
	#end
	
}
