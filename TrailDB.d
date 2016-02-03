module TrailDB;

import std.algorithm;
import std.conv;
import std.datetime;
import std.path : buildPath;
import std.range;
import std.stdint;
import std.stdio;
import std.string : fromStringz, format, toStringz;
import std.typecons;

import traildbc;

immutable static BUFFER_SIZE = 1 << 18;

alias RawUuid = ubyte[16];
alias HexUuid = ubyte[32];

RawUuid hexToRaw(HexUuid hexId)
{
    RawUuid rawId;
    if(int err = tdb_uuid_raw(hexId, rawId))
    {
        throw new Exception("Failure to convert hex uuid to raw.\n\t"
                            ~ cast(string)fromStringz(tdb_error_str(err)));
    }
    return rawId;
}

HexUuid rawToHex(RawUuid rawId)
{
    HexUuid hexId;
    if(int err = tdb_uuid_hex(rawId, hexId))
    {
        throw new Exception("Failure to convert raw uuid to hex..\n\t"
                            ~ cast(string)fromStringz(tdb_error_str(err)));
    }
    return hexId;
}

/* Event in a TrailDB trail. Indexing returns immutable reference to field values. */
/* The reference returned should be deep copied if another trail is loaded before use. */
struct Event
{
    void* db; // Needed to get item value
    tdb_event* event;

    @property ulong timestamp() { return event.timestamp; }

    string opIndex(ulong i)
    {
        uint64_t valueLength;
        auto ret = tdb_get_item_value(db, (cast(tdb_item*)(event.items))[i], &valueLength);
        return cast(string)ret[0 .. valueLength];
    }
}

/* D Range representing trail of events */
struct Trail
{
    void* db;
    void* cursor;

    int opApply(int delegate(ref Event) foreach_body)
    {
        tdb_event* event;
        while((event = tdb_cursor_next(cursor)) != null)
        {
            Event e = Event(db, event);
            if(int result = foreach_body(e))
            {
                return result;
            }
        }

        return 0;
    }
}

class TrailDB
{
    void* db;
    void* cursor;
    bool open = false;

    immutable uint64_t numTrails;
    immutable uint64_t numEvents;
    immutable uint64_t numFields;
    immutable uint64_t minTimestamp;
    immutable uint64_t maxTimestamp;
    immutable string[] fieldNames;
    immutable uint64_t vers;

    this(string db_path)
    {
        db = tdb_init();
        if(int err = tdb_open(db, toStringz(db_path)))
        {
            throw new Exception("Failure to open traildb " ~ db_path ~ ".\n\t"
                                ~ cast(string)fromStringz(tdb_error_str(err)));
        }

        open = true;

        numTrails     = tdb_num_trails(db);
        numEvents     = tdb_num_events(db);
        numFields     = tdb_num_fields(db);
        minTimestamp  = tdb_min_timestamp(db);
        maxTimestamp  = tdb_max_timestamp(db);
        fieldNames    = cast(immutable)map!(i => cast(string)fromStringz(tdb_get_field_name(db, cast(uint)i)))(iota(0, numFields)).array();

        vers   = tdb_version(db);
        cursor = tdb_cursor_new(db);
    }

    ~this()
    {
        close();
    }

    void close()
    {
        if(open)
        {
            tdb_close(db);
            tdb_cursor_free(cursor);
            open = false;
        }
    }

    ulong fieldLexiconSize(uint field)
    {
        return tdb_lexicon_size(db, field);
    }

    /* Returns trail of events (a D Range)*/
    Trail opIndex(ulong trailIndex)
    {
        tdb_get_trail(cursor, trailIndex);
        return Trail(db, cursor);
    }

    Trail opIndex(HexUuid uuid)
    {
        return opIndex(uuidIndex(hexToRaw(uuid)));
    }

    Trail opIndex(RawUuid uuid)
    {
        return opIndex(uuidIndex(uuid));
    }

    int opApply(int delegate(ref Trail) foreach_body)
    {
        tdb_willneed(db);
        scope(exit) tdb_dontneed(db);

        foreach(i; 0 .. numTrails)
        {
            Trail t = opIndex(i);
            if(int result = foreach_body(t))
            {
                return result;
            }
        }

        return 0;
    }

    /* Returns the 16 bytes cookie ID at a given position in the DB. */
    RawUuid indexUuid(ulong index)
    {
        auto uuidPtr = tdb_get_uuid(db, index);
        if(uuidPtr == null)
        {
            throw new Exception("No trail with index " ~ to!string(index) ~ " found.");
        }
        RawUuid uuid = uuidPtr[0 .. 16];
        return uuid;
    }

    long uuidIndex(RawUuid uuid)
    {
        ulong index;
        if(int err = tdb_get_trail_id(db, uuid, &index))
        {
            throw new Exception("No trail with uuid " ~ cast(string)(rawToHex(uuid)) ~ " found.");
        }

        return index;
    }
}

class TrailDBConstructor
{
}
