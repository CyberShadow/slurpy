module slurpy.sites.shopit;

import ae.utils.iconv;
import ae.utils.meta;
import ae.utils.regex;
import ae.utils.text;
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
	string name, warranty, price, legalPrice;
}

NestedList!Product getProducts()
{
	return
		"http://shopit.md/ru/page/price"
		.download
		.readText
		.extractCapture(`(http://shopit.md/.*?\.xls)`)
		.front
		.download
		.toCSV
		.read
		.I!(s => cast(ascii)s)
		.toUtf8("windows1251")
		.parseNestedCSV!Product
	;
}
