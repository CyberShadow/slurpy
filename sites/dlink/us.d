module slurpy.sites.dlink.us;

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
		("http://us.dlink.com/search/keyword/" ~ encode(name) ~ "/")
		.download
		.readText
		.toXML
		.xmlParse
		.I!(doc => zip(
			doc
			.findAll("div.padBrd > div.content_subtitle_dark > a")
			.map!(e => e.attributes["href"])
		,	
			doc
			.findAll("div.padBrd > div.content_subtitle_dark")
			.map!(e => e.children[$-1].text.strip)
		))
		.array // https://issues.dlang.org/show_bug.cgi?id=14485
		.filter!(t => t[1] == name)
		.I!(r => r.empty ? null : r.front[0])
	;
}
