module slurpy.sites.tplink.us;

import ae.utils.meta;
import ae.utils.xmllite;
import ae.utils.xmlsel;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.range;
import std.stdio;
import std.string;
import std.uri;

import slurpy.net;

string findProduct(string name)
{
	return
		("http://www.tp-link.com/en/search/?q=" ~ encodeComponent(name))
		.download
		.readText
		.toXML
		.xmlParse
		.I!(doc => zip(
			doc
			.findAll("#productResult > li > dl > dt > a")
			.map!(e => e.attributes["href"])
		,	
			doc
			.findAll("#productResult > li > dl > dt > a")
			.map!(e => e.children[$-1].text.strip)
		))
		.array // https://issues.dlang.org/show_bug.cgi?id=14485
		.filter!(t => !icmp(t[1], name))
		.I!(r => r.empty ? null : "http://www.tp-link.com" ~ r.front[0])
	;
}

string[string] getProduct(string url)
{
	return
		url
		.download
		.readText
		.toXML
		.xmlParse
		.I!(doc => zip(
			doc
			.findAll("#div_specifications > div.container tbody th")
			.map!(e => e.text)
		,	
			doc
			.findAll("#div_specifications > div.container tbody td")
			.map!(e => e.text)
		))
		.assocArray()
	;
}
