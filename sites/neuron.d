module slurpy.sites.neuron;

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

import slurpy.net;

struct Product
{
	string fullName, shortSpec, url;
	int price;
}

Product[] getProducts(string url)
{
	return url
		.download
		.readText
		.toXML
		.xmlParse
		.I!(doc => zip(
			doc
			.findAll(".Content_Goods_TitleBlock")
			.map!(e => e.text.strip)
		,	
			doc
			.findAll(".Content_Goods_TitleBlock > a > span")
			.map!(e => e.text.strip)
		,	
			doc
			.findAll(".Content_Goods_TitleBlock > a")
			.map!(e => e.attributes["href"])
		,	
			doc
			.findAll(".Content_Goods_PriceBlock_Value")
			.map!(e => e.attributes["price"].to!int)
		))
		.map!(t => Product(t.expand))
		.array;
}

string[string] getProductSpecs(string url)
{
	return url
		.download
		.readText
		.toXML
		.xmlParse
		.I!(doc => zip(
			doc
			.findAll(".Page_Product_Content_Description_Table_Cell1_Content")
			.map!(e => e.text.strip)
		,
			doc
			.findAll(".Page_Product_Content_Description_Table_Cell2")
			.map!(e => e.text.strip)
		))
		.assocArray();
}
