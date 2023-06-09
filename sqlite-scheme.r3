Rebol [
	title: "SQLite scheme (WIP)"
	file:  %sqlite-scheme.r3
	note:  {This is just an initial proof of concept}
	version: 0.1.0
	author: "Oldes"
]

try [system/modules/sqlite: none]
sqlite: import 'sqlite

sys/make-scheme [
	title: "SQLite database scheme"
	name:  'sqlite
	spec:   make system/standard/port-spec-file []

	actor: [
		open: func [
			port[port! url!]
			/new
			/local path
		][	
			;? port/spec
			path: rejoin [
				any [select port/spec 'path   %./]
				any [select port/spec 'target %.db]
			]
			port/spec/path: copy path: clean-path path
			if all [not new not exists? path][
				cause-error 'Access 'cannot-open reduce [path "file not exists!"]
			]
			;; SQLite expect full path in the local format (C:/ on Windows)
			;; but Rebol's open function does not accept string...
			;; so do this strange thing to get over it
			all [
				system/platform = 'Windows
				path: as file! to-local-file path
			]
			port/state: make object! [
				db:          sqlite/open path  ;; used to store a database handle
				statements:  #()               ;; prepared statements
				query:                         ;; last used query
				stmt:        #[none]           ;; last prepared statement
				trace-level: 0
			]
			return port
		]
		
		open?: func [port [port!]][
			handle? port/state/db
		]

		close: func [port [port!] /local state][
			unless open? port [	cause-error 'Access 'not-open port/spec/ref ]
			state: port/state
			sqlite/close state/db
			foreach [query stmt] state/statements [
				sqlite/finalize stmt
			]
			clear state/statements
			state/db:
			state/query:
			state/stmt: none
			port
		]

		;; WRITE is now just executes a query... no result is collected, but may be printed in console
		write: func[port [port!] query [string!]][
			unless open? port [	cause-error 'Access 'not-open port/spec/ref ]
			sqlite/exec port/state/db port/state/query: query
		]

		;; INSERT is used to prepare a statement, which is then used with other actions
		insert: func[port [port!] query [string!] /local ps stmt][
			unless open? port [	cause-error 'Access 'not-open port/spec/ref ]
			ps: port/state
			ps/query: query
			either stmt: select ps/statements query [
				;; make sure that the statement starts from begining
				sqlite/reset stmt
			][
				;; prepare the new statement and store it for later use
				stmt: sqlite/prepare ps/db query
				ps/statements/:query: stmt
			]
			ps/stmt: stmt
			port
		]

		;; TAKE used to get just a single row (or multiple)
		take: func[
			port [port!]
			/part length [integer!]
		][
			read/part port any [length 1] 
		]

		;; READ used to get all rows if used without refinement (or multiple when used with /part)
		read: func[
			port [port!]
			/part length [integer!]
			/local stmt temp data
		][
			unless open? port [	cause-error 'Access 'not-open port/spec/ref ]
			stmt: port/state/stmt
			port/data: data: clear any [port/data []]

			temp: sqlite/step/rows stmt any [length 0]
			either block? temp [
				append data temp
				unless part [
					;; gets all rows
					while [
						block? temp: sqlite/step/rows stmt 0
					][	append data temp ]
					sqlite/reset stmt
				]
			][
				return none
			]
			data
		]

		;; PICK is a shortcut for READ INSERT "query"
		pick: func[
			port [port!]
			query [string!]
		][
			read insert port query
		]

		modify: func[
			port  [port!]
			field [word!]
			value [integer!]
		][
			switch field [
				trace-level [
					sqlite/trace port/state/db port/state/trace-level: value
				]
			]
		]
	]
]

;------------------------------------------------------------------------------------------------
;print sqlite/info

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



