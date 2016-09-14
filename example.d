#!/usr/bin/env dub
/+ dub.json:
{
    "name": "example",
    "dependencies": {"traildb": {"path": "./"}}
}
+/
import std.stdio;

import TrailDB;

int main(string[] args)
{
    if(args.length != 2)
    {
        writeln("requries one argument: path to a database");
        return 1;
    }

    string path = args[1];

    auto DB = new TrailDB(path);
    writeln("Number of trails:  ", DB.numTrails);
    writeln("Number of fields:  ", DB.numFields);
    writeln("Number of events:  ", DB.numEvents);
    writeln("First timestamp:   ", DB.minTimestamp);
    writeln("Last timestamp:    ", DB.maxTimestamp);
    writeln("Field names:       ", DB.fieldNames);
    writeln("Version:           ", DB.vers);

    foreach(trail; DB)
    {
        foreach(event; trail)
        {
            writeln(event.timestamp, " : ", event[0]);
        }
    }

    DB.close();

    return 0;
}
