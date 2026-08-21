[![rebol-sqlite](https://github.com/user-attachments/assets/f4b0d517-9c7b-4b16-bbf6-7b7631dfa848)](https://github.com/Siskin-framework/Rebol-SQLite)

[![Rebol-SQLite CI](https://github.com/Siskin-framework/Rebol-SQLite/actions/workflows/main.yml/badge.svg)](https://github.com/Siskin-framework/Rebol-SQLite/actions/workflows/main.yml)
[![Gitter](https://badges.gitter.im/rebol3/community.svg)](https://gitter.im/rebol3/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# Rebol/SQLite

[SQLite](https://www.sqlite.org/) extension for [Rebol3](https://github.com/Siskin-framework/Rebol),
with the [sqlite-vec](https://github.com/asg017/sqlite-vec) vector search extension built in.

> [!WARNING]
> Under development. The API may change at any moment.

## Contents

* [Getting started](#getting-started)
* [Commands](#commands)
* [Queries](#queries)
* [Prepared statements](#prepared-statements)
* [Parameter binding](#parameter-binding)
* [Vector search](#vector-search)
* [Port scheme](#port-scheme)
* [Building](#building)
* [License](#license)

## Getting started

Put the extension library (`sqlite-x64.rebx` or the variant for your machine) into the
directory reported by `system/options/modules`, and import it:

```rebol
sqlite: import 'sqlite

print sqlite/info
```

Everything below assumes the module is bound to the word `sqlite`. Commands can also be
used without the prefix inside a `with` block:

```rebol
with sqlite [
    db: open %my.db
    exec db {CREATE TABLE IF NOT EXISTS Cars(Id INTEGER PRIMARY KEY, Name TEXT, Price INTEGER);}
    close db
]
```

## Commands

| Command                | Purpose |
| ---------------------- | ------- |
| `info`                 | Version and memory info of the library; `info/of handle` describes a database or statement handle |
| `open file`            | Opens (or creates) a database and returns a `sqlite-db` handle |
| `close db`             | Closes a database connection |
| `exec db sql`          | Runs one or more semicolon separated statements; results are printed, not returned |
| `eval db query`        | Evaluates a statement and returns its result; accepts a string, a block with parameters, or a prepared statement |
| `prepare db sql`       | Compiles a statement and returns a `sqlite-stmt` handle |
| `step stmt`            | Executes a prepared statement; `/rows count` returns more rows, `/with block` binds parameters |
| `reset stmt`           | Rewinds a prepared statement so it can be executed again |
| `finalize stmt`        | Releases a prepared statement |
| `columns stmt`         | Column names of a statement as a block of strings, or `none` when it has no result set |
| `last-insert-id db`    | Rowid of the most recent successful insert |
| `trace db mask`        | Enables SQLite tracing (`1` = statements, `2` = profiles, `3` = both) |
| `initialize`           | Initializes the SQLite library |
| `shutdown`             | Releases the library's resources |

Handles are released automatically by the garbage collector, so `close` and `finalize`
are optional — they only make the release deterministic.

Failing commands throw a Rebol error, so they can be caught with `try`:

```rebol
print try [exec db "INVALID"]
```

## Queries

`eval` is the main way to get data out. Results come back as a flat block, one value per
column, in row order:

```rebol
probe eval db {SELECT * FROM Cars}
;== [1 "Audi" 52642 2 "Mercedes" 57127 3 "Skoda" 9000 ...]
```

Use `columns` on a prepared statement when the column names are needed.

For statements which return no rows, `eval` returns the number of affected rows instead:

```rebol
probe eval db [{INSERT INTO Genres (name) VALUES (?)} "Fantasy" "Science Fiction" "Crime"]
;== 3
```

`exec` is a thin wrapper over `sqlite3_exec`. It accepts several statements at once, which
makes it convenient for schema setup, but it prints its results rather than returning them:

```rebol
exec db {
BEGIN TRANSACTION;
DROP TABLE IF EXISTS Cars;
CREATE TABLE Cars(Id INTEGER PRIMARY KEY, Name TEXT, Price INTEGER);
COMMIT;
}
```

## Prepared statements

A statement compiled once can be executed repeatedly:

```rebol
stmt: prepare db "SELECT * FROM Cars WHERE Price > ? ORDER BY Name"

probe columns stmt
;== ["Id" "Name" "Price"]

probe step/with/rows stmt [20000] 100   ;; up to 100 matching rows
reset stmt
probe step/with/rows stmt [40000.0] 100
finalize stmt
```

`step` returns a single row by default, `step/rows stmt n` returns at most `n` rows, and a
count below `1` returns all the remaining ones. When a statement is exhausted, `step`
returns `none`.

Prepared statements can also be handed to `eval`, on their own or with parameters:

```rebol
stmt: prepare db {SELECT Name FROM Genres WHERE Name LIKE :pattern}
probe eval db [stmt "F%"]
probe eval db [stmt "C%"]
finalize stmt
```

## Parameter binding

Values are bound rather than pasted into the SQL, so quoting and escaping are not a
concern. Both `eval` (in a block) and `step/with` accept these types:

| Rebol type                                  | SQLite type |
| ------------------------------------------- | ----------- |
| `integer!`                                  | INTEGER |
| `logic!`                                    | INTEGER (`1` / `0`) |
| `decimal!`                                  | REAL |
| `string!` `file!` `email!` `ref!` `url!` `tag!` | TEXT (converted to UTF-8) |
| `binary!`                                   | BLOB |
| `vector!`                                   | BLOB (raw elements, as `sqlite-vec` expects them) |
| `none!`                                     | NULL |

Words in the block are resolved, so values can be passed by reference:

```rebol
pattern: "A%"
probe eval db [{SELECT * FROM Cars WHERE Name LIKE ?} pattern]
```

Grouping the parameters into blocks runs the statement once per group. Missing values are
bound as NULL:

```rebol
eval db [
    {INSERT INTO Authors (first_name, family_name, date_of_birth, date_of_death) VALUES (?,?,?,?)}
    ["Patrick" "Rothfuss" "1973-06-06" none        ]
    ["Isaac"   "Asimov"   "1920-01-02" "1992-04-06"]
    ["Bob"     "Billings"                          ] ;; the missing values are NULL
]
```

## Vector search

The [sqlite-vec](https://github.com/asg017/sqlite-vec) extension is registered on every
connection. Check for it with:

```rebol
if find eval db {PRAGMA module_list;} "vec0" [ ... ]
```

Vectors may be given as JSON text or as a compact binary blob. A Rebol `vector!` is bound
directly as the latter, which avoids the text round-trip:

```rebol
exec db {CREATE VIRTUAL TABLE vec_examples USING vec0(sample_embedding float[8]);}

embedding: make vector! [decimal! 32 [-0.2 0.25 0.341 -0.211 0.645 0.935 -0.316 -0.924]]
eval db [{INSERT INTO vec_examples(rowid, sample_embedding) VALUES (?,?)} 1 embedding]

;; KNN style query
probe eval db {
    SELECT rowid, distance FROM vec_examples
    WHERE sample_embedding MATCH '[0.890, 0.544, 0.825, 0.961, 0.358, 0.0196, 0.521, 0.175]'
    ORDER BY distance LIMIT 2;
}
```

An `f32` vector of 8 items is exactly the 32 bytes which `float[8]` expects.

## Port scheme

`sqlite-scheme.reb` wraps the commands in a port, which keeps a cache of prepared
statements keyed by the query text. It is a proof of concept and its API is not settled.

```rebol
do %sqlite-scheme.reb

db: open/new sqlite:new.db     ;; without /new the file must already exist

write db {CREATE TABLE IF NOT EXISTS Cars(Id INTEGER PRIMARY KEY, Name TEXT, Price INTEGER);}

insert db "SELECT * FROM Cars" ;; prepares a statement
probe take db                  ;; a single row
probe read/part db 5           ;; five rows
probe read db                  ;; all the remaining rows

probe pick db "SELECT * FROM Contacts"  ;; prepare and read in one step

modify db 'trace-level 3       ;; verbose SQLite traces
close db
```

Note that the scheme takes query strings only — to bind parameters, use the commands
directly.

## Building

The extension is built with the [Siskin builder](https://github.com/Siskin-framework/Builder):

```sh
siskin Rebol-SQLite.nest
```

The nest offers x86, x64 and arm64 targets. Its `do %make-extension.r3` step regenerates
`src/gen-sqlite.h` and `src/gen-sqlite.c` from the `src/sqlite.reb` specification, which
holds the command list, their argument types and the module's init code. Command
implementations live in `src/sqlite-commands.c`; `src/sqlite.c` holds the entry points for
both the standalone library and the variant compiled into the host.

To add or change a command, edit `src/sqlite.reb` and rebuild — the generated files should
not be edited by hand.

Tests are run with:

```sh
rebol ci-test.r3
```

## License

Distributed under the [MIT license](LICENSE).