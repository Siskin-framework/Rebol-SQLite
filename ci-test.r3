Rebol [
	title: "SQLite extension test"
	needs:  3.13.1 ;; using system/options/modules as extension location
]

print "Trying to import SQLite extension..."
;; In the GitHub Actions, the built extension is copied into the current directory.
unless empty? read %sqlite*.rebx [
	;; make sure that we load a fresh extension
	try [system/modules/sqlite: none]
	;; use current directory as a modules location
	system/options/modules: what-dir
]

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


	print-horizontal-line
	trace db 1 ;= SQLITE_TRACE_STMT


	probe eval db [{INSERT INTO Genres (name) VALUES (?)}  "Fantasy" "Science Fiction" "French Poetry" "Crime"]
	probe eval db [{INSERT INTO Genres (name) VALUES (?)}  "Comedy"]

	last-id: sqlite/last-insert-id db
	? last-id

	print-horizontal-line
	print as-yellow "Using eval command with string as a query..."

	probe eval db sql: {SELECT * FROM Genres}
	probe eval db [{SELECT * FROM Genres}] ;; in block, but no parameters
	probe eval db [:sql] ;; in block as a word, but no parameters
	;; also test, if query works when not at its head position
	probe eval db next {XSELECT * FROM Genres}
	probe eval db reduce [next {XSELECT * FROM Genres}]

	print-horizontal-line
	print as-yellow "Using prepared statement with eval..."

	stmt-genres-like!: prepare db {SELECT Name FROM Genres WHERE Name LIKE :pattern}
	probe eval db  stmt-genres-like!
	probe eval db [stmt-genres-like! "F%"]
	probe eval db [stmt-genres-like! "C%"]
	finalize stmt-genres-like!

	print as-yellow "Using already finalized statement throws an error..."
	print try [eval db [stmt-genres-like! "F%"]]


	print-horizontal-line
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

	print-horizontal-line

	print as-yellow "Testing constraint error..."
	;; family_name cannot be NULL, so there must be an error:
	print try [
		eval db [
			{INSERT INTO Authors (first_name, family_name, date_of_birth, date_of_death) VALUES (?,?,?,?)}
			"Jim" none "1971-12-16" none
		]
	]


	print-horizontal-line
	print as-yellow "Getting authors one by one..."
	stmt: prepare db "SELECT * FROM Authors"
	while [rec: step stmt] [ probe rec ]
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


;------------------------------------------------------------------------------------------------
print-horizontal-line
print as-yellow "SQLITE SCHEME TESTS"
print-horizontal-line

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

print-horizontal-line
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

print-horizontal-line
prin as-yellow "Testing an error message of the invalid query."
print try [insert db "INVALID_QUERY"]

print-horizontal-line

insert db "SELECT * FROM Cars"  ;; Prepares a statement
print as-yellow "Resolving 10 rows one by one..."
loop 10 [probe take db]
print as-yellow "Resolving 5 rows at once..."
probe read/part db 5
print as-yellow "Resolving the rest of rows..."
probe read db

print-horizontal-line
print as-yellow "Resolving 4 random hexadecimal blobs"
insert db "SELECT hex(randomblob(16)), hex(randomblob(16)), hex(randomblob(16)), hex(randomblob(16))"
probe read db

print-horizontal-line
print as-yellow "Resolving all data using PICK action"
probe pick db "SELECT * FROM Contacts"


print as-yellow "DONE"

;quit

