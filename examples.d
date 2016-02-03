import std.stdio;

import TrailDB;

int main(string[] args)
{
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
