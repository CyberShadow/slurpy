import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.regex;
import std.stdio;
import std.string;

static import slurpy.sites.neuron;
static import slurpy.sites.shopit;

import ae.sys.console;
import ae.utils.regex;

void neuron()
{
	import slurpy.sites.neuron;
	auto products = getProducts("http://www.neuron.md/routere-wireless-%5B282%5D.aspx");
	foreach (p; products)
	{
		auto name = p.fullName.replace(p.shortSpec, "").strip;
		auto url = "http://www.neuron.md" ~ p.url;
		scope(failure) writeln(url);
		auto details = getProductSpecs(url);
		if ("USB Host" in details)
			continue;
		auto ports = details.get("Porturi LAN", details.get("Porturile WAN/LAN", null));
		enforce(ports, "No ports info");
		if (!ports.canFind("1000"))
			continue;
		writeln(url);
	}
}

void shopit()
{
	import slurpy.sites.shopit;

	auto products = getProducts();
	auto network = products["PC Componente"]["Retelistica"];

	string[string][string] productData;
	{
		auto items = network["TP-Link"].items;
		foreach (item; items)
		{
			auto price = item.price.replace(" lei", "").replace(",", "");

			//writeln(parts);
			string model =
			{
				auto name = item.name;
				name = name.replace(`TP-Link,`, `TP-Link`);
				name = name.replace(`PoE Switch, `, ``);
			//	name = name.replace(` Easy Smart`, ``);
			//	name = name.replace(` ADSL`, `, ADSL`);
			//	name = name.replace(` Hardware `, `, Hardware `);
			//	name = name.replace(` High Power`, `, High Power`);
				auto parts = name.replace(",", "\n").replace("\r", "").split("\n").map!strip.array();

				auto part = parts.find!(part => part.toUpper.canFind("TP-LINK"));
				if (!part.empty)
				{
					auto words = part.front.split.find!(word => word.toUpper == "TP-LINK")[1..$];
				//	return words.join(" ");
					if (words[0] == "Archer")
						return words[0..2].join(" ");
					else
						return words[0];
				}
			//	part = parts[1..$];
			//	writeln(part.front);
			//	writeln("Can't find model: " ~ name);
				return name.extractCapture(`\b([A-Z][\-\w]*\d[\-\w]*)\b`).front;
			}();

			//writeln(model);

		//	auto s = item.name.replace(regex(`[,\s]+`), " ").strip.split();
		/*
			bool tryMatch(string r) { auto m = item.name.extractCapture(r); if (m.empty) return false; model = m.front; return true; }
			if (!(tryMatch(`(?:TP-LINK )?\b(T\w-\w+\d\w*)\b`)
			   || tryMatch(`TP-LINK \b(\w+\d\w*)\b`))
			)
			{
				writeln("Can't find model name: " ~ item.name);
			}
			writeln(model);
		*/
		/*
			import slurpy.sites.tplink.us;
			auto purl = findProduct(model);
			//writeln(model, " ", purl);
			if (purl)
				writefln("%15s %s", model, getProduct(purl).get("Interface", null));
		*/

			(){
				import slurpy.sites.tplink.us;

				auto purl = findProduct(model);
				//writeln(model, " ", purl);
				if (purl)
				{
					int gbitPorts;

					auto product = getProduct(purl);
					if ("ADSL Standards" in product)
						return;
					auto standards = product.get("Standards and Protocols", null).replace("\n", ",").split(",").map!strip.array;
					if (standards.canFind("IPsec"))
						return;
					auto interfaces = product.get("Interface", null).splitLines;
					foreach (iface; interfaces)
					{
						iface = iface.replace("*", "").replaceAll(re!`\s+`, " ").replace(re!`\b[Oo]ne\b`, "1");
						if (iface.canFind("Coax"))
							return;
						if (iface.canFind("Console"))
							return;
						if (iface.canFind("1000Mbps") || iface.canFind("Gigabit"))
							gbitPorts += iface.split(" ")[0].to!int;
						else
						if (iface.canFind("100Mbps"))
							return;
					}
					if (gbitPorts >= 4 && gbitPorts < 10)
						writefln("%15s %4s %s", model, price, interfaces);
					productData[model] = product;
				}
				else
				{
				//	writefln("Can't find model: %s", model);
				}
			}();
		}
	}

	auto propertyNames = productData.values.map!(value => value.keys).join.sort().uniq;

	foreach (name, properties; productData)
	{
		auto f = File("results/" ~ name ~ ".txt", "wb");
		foreach (pname; properties.keys.sort())
		{
			f.writeln("== ", pname, " ==");
			f.writeln(properties[pname]);
		}
	}

//	writeln(products);
}

void main() { shopit(); }
