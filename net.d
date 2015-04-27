module slurpy.net;

import std.algorithm.searching;
import std.array;
import std.conv;
import std.exception;
import std.file;
import std.path;
import std.process;
import std.range.primitives;
import std.typecons;

import ae.sys.file;
import ae.sys.net;
import ae.sys.net.system;
import ae.utils.digest;

debug(slurpy) import std.stdio : stderr;

string download(string url)
{
	auto target = "cache/" ~ getDigestString!MD5(url);
	debug(slurpy) stderr.writeln("download: ", target, " - ", url);
	ensurePathExists(target);
	cached!downloadFile(url, target);
	return target;
}

string toXML(string data)
{
	auto target = "cache/" ~ getDigestString!MD5(data);
	debug(slurpy) stderr.writeln("toXml   : ", target);
	ensurePathExists(target);
//	cached!runXmlLint(data, target);
//	cached!runHtmlTidy(data, target);
//	cached!runBeautifulSoup(data, target);
	cached!runPhpDom(data, target);
	return target.readText();
}

void runXmlLint(string data, string target)
{
	auto input = pipe();
	auto p = spawnProcess(["xmllint", "--html", "--xmlout", "--encode", "utf8", "-"], input.readEnd, File(target, "wb"));
	input.writeEnd.rawWrite(data);
	input.writeEnd.close();
	enforce(p.wait() == 0, "xmllint failed");
}

void runHtmlTidy(string data, string target)
{
	auto input = pipe();
	auto p = spawnProcess(["tidy", "-q", "--show-warnings", "0", "-asxhtml", "-utf8", "--show-errors", "0", "-wrap", "0", "--force-output", "1"], input.readEnd, File(target, "wb"));
	input.writeEnd.rawWrite(data);
	input.writeEnd.close();
//	enforce(p.wait() == 0, "tidy failed");
	p.wait();
}

void runBeautifulSoup(string data, string target)
{
	auto input = pipe();
	auto p = spawnProcess(["python", `C:\Soft\Tools\beautifulsoup_format.py`], input.readEnd, File(target, "wb"));
	input.writeEnd.rawWrite(data);
	input.writeEnd.close();
	enforce(p.wait() == 0, "beautifulsoup_format failed");
	p.wait();
}

void runPhpDom(string data, string target)
{
	auto input = pipe();
	auto p = spawnProcess(["php", `C:\Soft\Tools\htmlformat_dom.php`], input.readEnd, File(target, "wb"));
	input.writeEnd.rawWrite(data);
	input.writeEnd.close();
	enforce(p.wait() == 0, "htmlformat_dom failed");
	p.wait();
}

string toCSV(string fn)
{
	auto data = read(fn);
	auto target = "cache/tocsv-" ~ getDigestString!MD5(data);
	ensurePathExists(target);
	cached!runXlsToCsv(fn, target);
	return target;
}

void runXlsToCsv(string fn, string target)
{
	auto xls = fn.setExtension("xls");
	copy(fn, xls); // Excel modifies the file when opening it
	scope(exit) remove(xls);
	auto p = spawnProcess(["cscript", `C:\Soft\Tools\xls2csv.vbs`, xls.absolutePath.buildNormalizedPath, target.absolutePath.buildNormalizedPath]);
	enforce(p.wait() == 0, "xls2csv failed");
}

// -----------------------------------------------------------------------------------------------------------------

struct NestedList(T)
{
	string name;
	NestedList!T[] lists;
	T[] items;

	NestedList!T opIndex(string name)
	{
		return lists.find!(l => l.name == name).front;
	}
}

NestedList!T parseNestedCSV(T)(string csv)
{
	NestedList!T root;
	NestedList!T* current = null;
	int depth = 0;

	import std.csv;
	foreach (record; csvReader!(Tuple!(string, string, typeof(T.tupleof)))(csv))
	{
		if (record[0] != "")
		{
			int n = record[0].to!int;
			auto name = record[2];

			current = &root;
			foreach (i; 0..n-1)
				current = &current.lists[$-1];
			current.lists ~= NestedList!T(name);
			current = &current.lists[$-1];
		}
		else
		if (current)
			current.items ~= T(record[2..$]);
	}
	return root;
}
