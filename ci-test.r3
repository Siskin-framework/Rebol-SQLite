Rebol [
	title: "SQLite extension test"
]

print "Trying to import SQLite extension..."
;; make sure that we load a fresh extension
try [system/modules/sqlite: none]
sqlite: import 'sqlite

? sqlite

recycle/torture ; make sure that recycle issues are catched

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

	sb: prepare db {select randomblob(16)}
	loop 4 [
		probe step sb
		reset sb
	]
	finalize sb

	print as-green "^/Using prepared statements and input values..."

	stmt: prepare db "SELECT * FROM Cars WHERE Price > ? ORDER BY name"
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


	print-horizontal-line
	stmt: prepare db {INSERT INTO Genres (name) VALUES (?)}
	step/with stmt ["Fantasy"]
	step/with stmt ["Scifi"  ]
	finalize stmt
	stmt: prepare db {SELECT * FROM Genres}
	genres: step/rows stmt -1 ;; all rows
	if 4 <> length? genres [
		print as-red "Something is wrong!"
	]
	finalize stmt
	? genres

	print-horizontal-line
	stmt: prepare db {
		INSERT INTO Authors (first_name, family_name, date_of_birth, date_of_death)
		VALUES (?,?,?,?)
	}
	step/with stmt ["Patrick" "Rothfuss" "1973-06-06" none]
	step/with stmt ["Ben" "Bova" "1932-11-8" none]
	step/with stmt ["Isaac" "Asimov" "1920-01-02" "1992-04-06"]
	step/with stmt ["Bob" "Billings"] ;; missing values are NULL
	step/with stmt ["Jim" "Jones" "1971-12-16" false]

	print as-yellow "Testing constraint error..."
	;; family_name cannot be NULL, so there must be an error:
	print try [step/with stmt ["Jim" none "1971-12-16" false]]
	
	finalize stmt

	stmt: sqlite/prepare db "SELECT * FROM Authors"
	while [rec: sqlite/step stmt] [ probe rec ]
	finalize stmt

	print as-green "^/Shutting down.."
	print info
	close db
	probe shutdown
	probe shutdown ; no-op
	probe initialize
	print info
	print "SQLite tests done."
]
;quit

