Rebol [
	title: "SQLite extension test"
	needs:  3.13.1 ;; using system/options/modules as extension location
]

print ["Running test on Rebol build:" mold to-block system/build]

system/options/quiet: false
system/options/log/rebol: 4

;; make sure that we load a fresh extension
try [system/modules/sqlite: none]

if CI?: any [
    "true" = get-env "CI"
    "true" = get-env "GITHUB_ACTIONS"
    "true" = get-env "TRAVIS"
    "true" = get-env "CIRCLECI"
    "true" = get-env "GITLAB_CI"
][
    ;; configure modules location for the CI test 
    system/options/modules: dirize to-rebol-file any [
    	get-env 'REBOL_MODULES_DIR
    	what-dir
    ]
]

sqlite: import 'sqlite

? sqlite

recycle/torture ; make sure that recycle issues are catched

;------------------------------------------------------------------------------------------------
;; Minimal check helpers.
;; Most of this script only prints its results, which means CI stays green as
;; long as nothing crashes - a command silently returning the wrong value would
;; not be noticed. These count mismatches so the run can fail at the end.
failures: 0
checks:   0

assert-equal: func [
	"Compares the expected value with the actual one"
	expected [any-type!]
	actual   [any-type!]
][
	checks: checks + 1
	;; `equal?` and `mold` both refuse unset!, so it is handled separately -
	;; a command returning nothing where a value is expected must be reported
	;; as a failure, not crash the check itself.
	either all [
		not unset? :expected
		not unset? :actual
		equal? :expected :actual
	][
		print [as-green "  ok  " mold/flat :actual]
	][
		failures: failures + 1
		print [
			as-red "FAILED"
			"expected:" either unset? :expected ["unset!"][mold/flat :expected]
			"but got:"  either unset? :actual   ["unset!"][mold/flat :actual]
		]
	]
]

assert-error: func [
	"Evaluates the code and expects it to throw an error"
	code [block!]
	/local result
][
	checks: checks + 1
	either error? set/any 'result try code [
		print [as-green "  ok  " "error was raised"]
	][
		failures: failures + 1
		print [
			as-red "FAILED" "expected an error, but got:"
			either unset? :result ["unset!"][mold/flat :result]
		]
	]
]
;------------------------------------------------------------------------------------------------


print sqlite/info
with sqlite [
	db: open %test.db
	;? db
	print info/of db
	trace db 3 ;= SQLITE_TRACE_STMT or SQLITE_TRACE_PROFILE

	print as-green "^/Testing that EXEC throws an error on invalid query"
	print try [ exec db "INVALID" ]

	exec db {
BEGIN TRANSACTION;
/* delete any tables used in the test */
DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS Cars;

DROP TABLE IF EXISTS Authors;
DROP TABLE IF EXISTS Genres;

/* ---------------------------------- */
CREATE TABLE Cars(Id INTEGER PRIMARY KEY, Name TEXT, Price INTEGER);
INSERT INTO "Cars" VALUES(1,'Audi',52642);
INSERT INTO "Cars" VALUES(2,'Mercedes',57127);
INSERT INTO "Cars" VALUES(3,'Skoda',9000);
INSERT INTO "Cars" VALUES(4,'Volvo',29000);
INSERT INTO "Cars" VALUES(5,'Bentley',350000);
INSERT INTO "Cars" VALUES(6,'Citroen',21000);
INSERT INTO "Cars" VALUES(7,'Hummer',41400);


CREATE TABLE IF NOT EXISTS Authors (
	author_id INTEGER PRIMARY KEY,
	first_name TEXT,
	family_name TEXT NOT NULL,
	date_of_birth TEXT,
	date_of_death TEXT
);

CREATE TABLE IF NOT EXISTS Genres (
	genre_id INTEGER PRIMARY KEY,
	name TEXT NOT NULL
);

COMMIT;}

	exec db {INSERT INTO "Cars" VALUES(null,'Hummer',null);}
	exec db "SELECT last_insert_rowid();"
	exec db "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
	exec db "SELECT * FROM Cars ORDER BY name"
	exec db "SELECT hex(randomblob(16));"

	stmt: prepare db "SELECT * FROM Cars ORDER BY name"
	;? stmt
	print info/of stmt
	probe step stmt
	finalize stmt
	print info/of stmt

	print as-green "^/Random bin generator..."

	stmt: prepare db {select randomblob(16)}
	name: columns stmt
	loop 4 [
		print [name #"=" step stmt]
		reset stmt
	]
	finalize stmt

	print as-green "^/Using prepared statements and input values..."

	stmt: prepare db "SELECT * FROM Cars WHERE Price > ? ORDER BY name"
	cols: columns stmt
	? cols
	probe step/with/rows stmt [20000] 100
	probe step/with/rows stmt [40000.0] 100
	finalize stmt

	stmt: prepare db "SELECT * FROM Cars WHERE Name LIKE :pattern ORDER BY name"
	probe step/with/rows stmt ["H%"] 100
	; testing an input where index is not at its head
	name: next "xA_di"
	probe step/with/rows stmt reduce [name] 100 
	finalize stmt

	print as-green "^/Testing STRICT keyword..."
	exec db {CREATE TABLE t1(a ANY) STRICT;}
	exec db {INSERT INTO t1 VALUES('000123');}
	exec db {SELECT typeof(a), quote(a) FROM t1;} ;-- result: text '000123'

	exec db {CREATE TABLE t2(a ANY);}
	exec db {INSERT INTO t2 VALUES('000123');}
	exec db {SELECT typeof(a), quote(a) FROM t2;} ;-- result: integer 123


	print-hline
	trace db 1 ;= SQLITE_TRACE_STMT


	probe eval db [{INSERT INTO Genres (name) VALUES (?)}  "Fantasy" "Science Fiction" "French Poetry" "Crime"]
	probe eval db [{INSERT INTO Genres (name) VALUES (?)}  "Comedy"]

	last-id: sqlite/last-insert-id db
	? last-id

	print-hline
	print as-yellow "Using eval command with string as a query..."

	probe eval db sql: {SELECT * FROM Genres}
	probe eval db [{SELECT * FROM Genres}] ;; in block, but no parameters
	probe eval db [:sql] ;; in block as a word, but no parameters
	;; also test, if query works when not at its head position
	probe eval db next {XSELECT * FROM Genres}
	probe eval db reduce [next {XSELECT * FROM Genres}]

	print-hline
	print as-yellow "Using prepared statement with eval..."

	stmt-genres-like!: prepare db {SELECT Name FROM Genres WHERE Name LIKE :pattern}
	probe eval db  stmt-genres-like!
	probe eval db [stmt-genres-like! "F%"]
	probe eval db [stmt-genres-like! "C%"]
	finalize stmt-genres-like!

	print as-yellow "Using already finalized statement throws an error..."
	print try [eval db [stmt-genres-like! "F%"]]


	print-hline
	print as-yellow "Using eval command with parameters in blocks..."
	probe eval db [
		{INSERT INTO Authors (first_name, family_name, date_of_birth, date_of_death) VALUES (?,?,?,?)}
		["Patrick" "Rothfuss" "1973-06-06" none        ]
		["Ben"     "Bova"     "1932-11-08" none        ]
		["Isaac"   "Asimov"   "1920-01-02" "1992-04-06"]
		["Bob"     "Billings"                          ] ;; missing values are NULL
		["Jim"     "Jones"    "1971-12-16"             ] ;; missing values are NULL
	]
	probe eval db "SELECT family_name, date_of_birth FROM Authors"

	print-hline

	print as-yellow "Testing constraint error..."
	;; family_name cannot be NULL, so there must be an error:
	print try [
		eval db [
			{INSERT INTO Authors (first_name, family_name, date_of_birth, date_of_death) VALUES (?,?,?,?)}
			"Jim" none "1971-12-16" none
		]
	]


	print-hline
	print as-yellow "Getting authors one by one..."
	stmt: prepare db "SELECT * FROM Authors"
	while [rec: step stmt] [ probe rec ]
	finalize stmt



	;==========================================================================
	;; Added checks
	;==========================================================================
	print-hline
	print as-yellow "Round-trip of all supported parameter types..."
	;; A column with no declared type keeps whatever type is bound to it,
	;; so each value can be checked as it comes back.
	exec db {DROP TABLE IF EXISTS Vals;}
	exec db {CREATE TABLE Vals(id INTEGER PRIMARY KEY, val);}

	eval db [
		{INSERT INTO Vals (id, val) VALUES (?,?)}
		1 42
		2 3.14
		3 "text"
		4 none
		5 #{DECAFBAD}
		6 true
		7 false
	]

	assert-equal 42          first eval db "SELECT val FROM Vals WHERE id = 1"
	assert-equal 3.14        first eval db "SELECT val FROM Vals WHERE id = 2"
	assert-equal "text"      first eval db "SELECT val FROM Vals WHERE id = 3"
	assert-equal none        first eval db "SELECT val FROM Vals WHERE id = 4"
	assert-equal #{DECAFBAD} first eval db "SELECT val FROM Vals WHERE id = 5"
	;; logic! is bound as an integer, so it reads back as 1 / 0
	assert-equal 1           first eval db "SELECT val FROM Vals WHERE id = 6"
	assert-equal 0           first eval db "SELECT val FROM Vals WHERE id = 7"

	;; the multi-row form must consume the parameters in pairs
	assert-equal 7 first eval db "SELECT count(*) FROM Vals"

	print as-yellow "^/Any-string types are bound as their text content..."
	eval db [
		{INSERT INTO Vals (id, val) VALUES (?,?)}
		10 %some/file.txt
		11 http://example.com
		12 user@example.com
		13 <a-tag>
	]
	assert-equal "some/file.txt"      first eval db "SELECT val FROM Vals WHERE id = 10"
	assert-equal "http://example.com" first eval db "SELECT val FROM Vals WHERE id = 11"
	assert-equal "user@example.com"   first eval db "SELECT val FROM Vals WHERE id = 12"
	assert-equal "a-tag"              first eval db "SELECT val FROM Vals WHERE id = 13"

	print as-yellow "^/Unicode round-trip (wide strings must be converted to UTF-8)..."
	unicode-text: "Příliš žluťoučký kůň úpěl ďábelské ódy"
	eval db [{INSERT INTO Vals (id, val) VALUES (?,?)} 20 unicode-text]
	assert-equal unicode-text first eval db "SELECT val FROM Vals WHERE id = 20"
	;; and the length must survive as characters, not as UTF-8 bytes
	assert-equal length? unicode-text first eval db "SELECT length(val) FROM Vals WHERE id = 20"

	print as-yellow "^/A parameter which is not at its head position..."
	skipped: skip "XXhello" 2
	eval db [{INSERT INTO Vals (id, val) VALUES (?,?)} 21 skipped]
	assert-equal "hello" first eval db "SELECT val FROM Vals WHERE id = 21"

	print-hline
	print as-yellow "COLUMNS command..."
	stmt: prepare db "SELECT Id, Name, Price FROM Cars"
	assert-equal ["Id" "Name" "Price"] columns stmt
	finalize stmt
	;; a statement without a result set has no columns
	stmt: prepare db {INSERT INTO Vals (val) VALUES (?)}
	assert-equal none columns stmt
	finalize stmt

	print-hline
	print as-yellow "STEP row counts..."
	total-cars: first eval db "SELECT count(*) FROM Cars"
	stmt: prepare db "SELECT Name FROM Cars ORDER BY Name"
	;; without the /rows refinement a single row is returned...
	assert-equal 1 length? step stmt
	;; ...with it, at most the requested number of rows...
	assert-equal 3 length? step/rows stmt 3
	;; ...and a count below 1 means "all the remaining rows"
	assert-equal (total-cars - 4) length? step/rows stmt 0
	;; nothing is left now
	assert-equal none step stmt
	finalize stmt

	print-hline
	print as-yellow "Errors must be thrown, not silently ignored..."
	assert-error [exec db "INVALID"]
	assert-error [prepare db "SELECT * FROM NoSuchTable"]
	;; family_name has a NOT NULL constraint
	assert-error [
		eval db [
			{INSERT INTO Authors (first_name, family_name) VALUES (?,?)}
			"Jim" none
		]
	]

	print-hline
	print as-yellow "Binding a vector! as a compact BLOB..."
	;; This is the only place where the vector branch of the parameter binding
	;; is used - an f32 vector of 8 items must arrive as exactly 32 bytes.
	either find eval db {PRAGMA module_list;} "vec0" [
		exec db {DROP TABLE IF EXISTS vec_test;}
		exec db {CREATE VIRTUAL TABLE vec_test USING vec0(embedding float[8]);}
		;; 8 x 32bit float is exactly the 32 bytes which vec0 expects here
		embedding: try [make vector! [decimal! 32 [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8]]]
		either vector? :embedding [
			eval db [{INSERT INTO vec_test(rowid, embedding) VALUES (?,?)} 1 embedding]
			assert-equal 32 length? first eval db {SELECT embedding FROM vec_test WHERE rowid = 1}
			;; a vector of a wrong size must be refused by the vec0 module
			;; (built up front - values inside the block are only word-resolved,
			;; an expression like `make vector! [...]` would not be evaluated there)
			wrong-embedding: make vector! [decimal! 32 [1.0 2.0]]
			assert-error [
				eval db [
					{INSERT INTO vec_test(rowid, embedding) VALUES (?,?)}
					2 wrong-embedding
				]
			]
		][
			print as-red "  could not construct an f32 vector! - check the constructor syntax"
		]
	][
		print as-yellow "  sqlite-vec is not available, skipping"
	]

	print as-green "^/Shutting down.."
	print info
	close db
	probe shutdown
	probe shutdown ; no-op
	probe initialize
	print info
	print "SQLite tests done."
]


;------------------------------------------------------------------------------------------------
print-hline
print as-yellow "Handles must be released by the garbage collector"
;; Neither the connection nor the statement below is closed explicitly, so the
;; handle release callbacks are the only thing which can free them. With
;; `recycle/torture` still active, a mistake in those callbacks shows up here.
try [delete %test-gc.db]
gc-db:   sqlite/open %test-gc.db
sqlite/exec gc-db {CREATE TABLE IF NOT EXISTS gc(a);}
gc-stmt: sqlite/prepare gc-db {SELECT 1}
assert-equal [1] sqlite/step gc-stmt
;; drop every reference and let the recycler do the rest
gc-db: gc-stmt: none
recycle
print as-green "  ok   (no crash while releasing the handles)"

;; Removing the file is a secondary check: on Windows an open database cannot
;; be deleted, so a leaked connection is caught there. On POSIX an open file can
;; be unlinked, so there the value of this section is the crash-free recycle above.
checks: checks + 1
try [delete %test-gc.db]
either exists? %test-gc.db [
	failures: failures + 1
	print as-red "FAILED  the database file could not be removed - still open?"
][
	print as-green "  ok   the database file was released and removed"
]

;------------------------------------------------------------------------------------------------
print-hline
print as-yellow "SQLITE SCHEME TESTS"
print-hline

import %sqlite-scheme.reb

if exists? %chinook.db [
	db: open/new sqlite:chinook.db

	probe read insert db {SELECT
	    InvoiceId,
	    BillingAddress,
	    date(InvoiceDate) InvoiceDate,
	    Total
	FROM
	    invoices
	WHERE
	    InvoiceDate NOT BETWEEN '2009-01-03' AND '2013-12-01'
	ORDER BY
	    InvoiceDate;
	}
]

;open sqlite:new.db              ;; would throw an error, if the file ./new.db does not exists
;open sqlite:/home/oldes/new.db  ;; used full path to the DB file

print-hline
prin  as-yellow "Testing an error message, when trying to open a database using not existing dir."
print try [open/new sqlite:not-exists/dir]

;; Create a new DB file in the current dir, if it does not exists, and open it
db: open/new sqlite:new.db

;; Allow verbose SQLite traces...
modify db 'trace-level 3 ;= SQLITE_TRACE_STMT or SQLITE_TRACE_PROFILE

;; Execute multiple queries at once...
write db {
BEGIN TRANSACTION;
/* delete any tables used in the test */
DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS Cars;
DROP TABLE IF EXISTS Contacts;
/* ---------------------------------- */
CREATE TABLE Cars(Id INTEGER PRIMARY KEY, Name TEXT, Price INTEGER);
INSERT INTO "Cars" VALUES(1,'Audi',52642);
INSERT INTO "Cars" VALUES(2,'Mercedes',57127);
INSERT INTO "Cars" VALUES(3,'Skoda',9000);
INSERT INTO "Cars" VALUES(4,'Volvo',29000);
INSERT INTO "Cars" VALUES(5,'Bentley',350000);
INSERT INTO "Cars" VALUES(6,'Citroen',21000);
INSERT INTO "Cars" VALUES(7,'Hummer',41400);
INSERT INTO "Cars" VALUES(NULL,'Audi',52642);
INSERT INTO "Cars" VALUES(NULL,'Mercedes',57127);
INSERT INTO "Cars" VALUES(NULL,'Skoda',9000);
INSERT INTO "Cars" VALUES(NULL,'Volvo',29000);
INSERT INTO "Cars" VALUES(NULL,'Bentley',350000);
INSERT INTO "Cars" VALUES(NULL,'Citroen',21000);
INSERT INTO "Cars" VALUES(NULL,'Hummer',41400);
INSERT INTO "Cars" VALUES(NULL,'Audi',52642);
INSERT INTO "Cars" VALUES(NULL,'Mercedes',57127);
INSERT INTO "Cars" VALUES(NULL,'Skoda',9000);
INSERT INTO "Cars" VALUES(NULL,'Volvo',29000);
INSERT INTO "Cars" VALUES(NULL,'Bentley',350000);
INSERT INTO "Cars" VALUES(NULL,'Citroen',21000);
INSERT INTO "Cars" VALUES(NULL,'Hummer',41400);
INSERT INTO "Cars" VALUES(NULL,'Audi',52642);
INSERT INTO "Cars" VALUES(NULL,'Mercedes',57127);
INSERT INTO "Cars" VALUES(NULL,'Skoda',9000);
INSERT INTO "Cars" VALUES(NULL,'Volvo',29000);
INSERT INTO "Cars" VALUES(NULL,'Bentley',350000);
INSERT INTO "Cars" VALUES(NULL,'Citroen',21000);
INSERT INTO "Cars" VALUES(NULL,'Hummer',41400);
INSERT INTO "Cars" VALUES(NULL,'Audi',52642);
INSERT INTO "Cars" VALUES(NULL,'Mercedes',57127);
INSERT INTO "Cars" VALUES(NULL,'Skoda',9000);
INSERT INTO "Cars" VALUES(NULL,'Volvo',29000);
INSERT INTO "Cars" VALUES(NULL,'Bentley',350000);
INSERT INTO "Cars" VALUES(NULL,'Citroen',21000);
INSERT INTO "Cars" VALUES(NULL,'Hummer',41400);
	
CREATE TABLE Contacts (
	email TEXT PRIMARY KEY,
	first_name TEXT NOT NULL,
	last_name TEXT NOT NULL
);
INSERT INTO "Contacts" VALUES('oceane.pacome@corporate.com', 'Océane', 'Pacôme');
INSERT INTO "Contacts" VALUES('Oldes@corporate.com','Oldes', 'Huhuman');
COMMIT;
}

print-hline
prin as-yellow "Testing an error message of the invalid query."
print try [insert db "INVALID_QUERY"]

print-hline

insert db "SELECT * FROM Cars"  ;; Prepares a statement
print as-yellow "Resolving 10 rows one by one..."
loop 10 [probe take db]
print as-yellow "Resolving 5 rows at once..."
probe read/part db 5
print as-yellow "Resolving the rest of rows..."
probe read db

print-hline
print as-yellow "Resolving 4 random hexadecimal blobs"
insert db "SELECT hex(randomblob(16)), hex(randomblob(16)), hex(randomblob(16)), hex(randomblob(16))"
probe read db

print-hline
print as-yellow "Resolving all data using PICK action"
probe pick db "SELECT * FROM Contacts"


print-hline
print as-yellow "Resolving available extension modules"
insert db {PRAGMA module_list;}
probe extensions: read db

if find extensions "vec0" [
	print-hline
	print as-yellow "Test sqlite-vec extension"
	write db {
	DROP TABLE IF EXISTS vec_examples;
	CREATE VIRTUAL TABLE IF NOT EXISTS vec_examples using vec0(
	  sample_embedding float[8]
	);
	-- vectors can be provided as JSON or in a compact binary format
	insert into vec_examples(rowid, sample_embedding)
	  values
	    (1, '[-0.200, 0.250, 0.341, -0.211, 0.645, 0.935, -0.316, -0.924]'),
	    (2, '[0.443, -0.501, 0.355, -0.771, 0.707, -0.708, -0.185, 0.362]'),
	    (3, '[0.716, -0.927, 0.134, 0.052, -0.669, 0.793, -0.634, -0.162]'),
	    (4, '[-0.710, 0.330, 0.656, 0.041, -0.990, 0.726, 0.385, -0.958]');
	}
	insert db {
	-- KNN style query
	select
	  rowid,
	  distance
	from vec_examples
	where sample_embedding match '[0.890, 0.544, 0.825, 0.961, 0.358, 0.0196, 0.521, 0.175]'
	order by distance
	limit 2;}
	probe read db
]

close db

print-hline
print as-yellow "DONE"

print-hline
either failures > 0 [
	print as-red ajoin ["RESULT: " failures " of " checks " check(s) FAILED!"]
	quit/return 1
][
	print as-green ajoin ["RESULT: all " checks " checks passed."]
]
quit/return 0

;quit

