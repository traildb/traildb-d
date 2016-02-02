import std.stdint;

alias tdb_error = int32_t;
alias tdb_field = uint32_t;
alias tdb_val   = uint64_t;
alias tdb_item  = uint64_t;

enum tdb_opt_key
{
    TDB_OPT_ONLY_DIFF_ITEMS             = 100,
    TDB_OPT_EVENT_FILTER                = 101,
    TDB_OPT_CURSOR_EVENT_BUFFER_SIZE    = 102,
    TDB_OPT_CONS_OUTPUT_FORMAT          = 1001
}

union tdb_opt_value
{
    const void* ptr;
    uint64_t value;
}

struct tdb_event
{
align(1):
    uint64_t timestamp;
    uint64_t num_items;
    tdb_item items[0];
}

extern(C):

    void* tdb_cons_init();
    tdb_error tdb_cons_open(void* cons,
                            const char* root,
                            const char** ofield_names,
                            uint64_t num_ofields);

    void tdb_cons_close(void* cons);

    tdb_error tdb_cons_set_opt(void* cons,
                               tdb_opt_key key,
                               tdb_opt_value value);

    tdb_error tdb_cons_get_opt(void* cons,
                               tdb_opt_key key,
                               tdb_opt_value* value);

    tdb_error tdb_cons_add(void* cons,
                           ref const uint8_t[16] uuid,
                           const uint64_t timestamp,
                           const char** values,
                           const uint64_t* value_lengths);

    tdb_error tdb_cons_append(void* cons, const void* db);
    tdb_error tdb_cons_finalize(void* cons);

    tdb_error tdb_uuid_raw(ref const uint8_t[32] hexuuid, ref uint8_t[16] uuid);
    tdb_error tdb_uuid_hex(ref const uint8_t[16] uuid, ref uint8_t[32] hexuuid);

    void* tdb_init();
    tdb_error tdb_open(void* db, const char* root);
    void tdb_close(void* db);
    void tdb_dontneed(const void* db);
    void tdb_willneed(const void* db);

    tdb_error tdb_set_opt(void* tdb, tdb_opt_key key, tdb_opt_value value);
    tdb_error tdb_set_opt(void* tdb, tdb_opt_key key, tdb_opt_value* value);

    uint64_t tdb_lexicon_size(const void* db, tdb_field field);

    tdb_error tdb_get_field(const void* db, const char* field_name, tdb_field* field);
    char* tdb_get_field_name(const void* db, tdb_field field);

    tdb_item tdb_get_item(const void* db,
                          tdb_field field,
                          const char* value,
                          uint64_t value_length);

    char* tdb_get_value(const void* db,
                              tdb_field field,
                              tdb_val val,
                              uint64_t* value_length);

    char* tdb_get_item_value(const void* db,
                                   tdb_item item,
                                   uint64_t* value_length);

    uint8_t* tdb_get_uuid(const void* db, uint64_t trail_id);

    tdb_error tdb_get_trail_id(const void* db,
                               ref const uint8_t[16] uuid,
                               uint64_t* traild_id);

    char* tdb_error_str(tdb_error errcode);

    uint64_t tdb_num_trails(const void* db);
    uint64_t tdb_num_events(const void* db);
    uint64_t tdb_num_fields(const void* db);
    uint64_t tdb_min_timestamp(const void* db);
    uint64_t tdb_max_timestamp(const void* db);

    uint64_t tdb_version(const void* db);

    void* tdb_cursor_new(const void* db);
    void  tdb_cursor_free(void* cursor);

    tdb_error tdb_get_trail(void* cursor, uint64_t trail_id);
    uint64_t  tdb_get_trail_length(void* cursor);
    tdb_event* tdb_cursor_next(void* cursor);
