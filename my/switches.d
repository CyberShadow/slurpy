import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;

import slurpy.sites.neuron;

import ae.sys.console;

void main()
{
	auto products = getProducts("http://www.neuron.md/switch-uri-%5B273%5D.aspx");
	foreach (p; products)
	{
		auto name = p.fullName.replace(p.shortSpec, "").strip;
		auto details = getProductSpecs("http://www.neuron.md" ~ p.url);
		auto manufacturer = details["Producător"].split[0];
		auto model = details["Model"];
		switch (manufacturer)
		{
			case "TP-LINK":
			{
				import slurpy.sites.tplink.us;

				auto purl = findProduct(model);
				//writeln(model, " ", purl);
				if (purl)
					writefln("%15s %s", model, getProduct(purl).get("Interface", null));
				break;
			}
			case "D-LINK":
			{
				import slurpy.sites.dlink.us;

				auto purl = findProduct(model);
				//writeln(model, " ", purl);
				break;
			}
			default:
				writeln("Unknown manufacturer: ", [manufacturer, model]);
		}
/*
		auto ports = details["Porturi LAN"];
		auto nports = ports.parse!int();
		assert(ports.canFind("100"), ports);
		bool hasGbit = ports.canFind("1000");
		if (hasGbit && nports > 5 && nports <= 10)
			writefln("%4d %s", p.price, details["Model"]);
*/
	}
}
