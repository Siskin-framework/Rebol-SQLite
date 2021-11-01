Rebol [
	title: "SQLite extension test"
]

unless value? 'sqlite [
	;@@ This really should be easier!!!
	if 'Macintosh = sys: system/platform [sys: 'macos]
	arch: system/build/target
	target: lowercase join "" [sys #"-" arch]
	replace target "win32_" ""
;append target "-xcode"
	;if 'xcode = system/build/compiler [append target "-xcode"]
	;@@-----------------------------!!!
	print "Trying to import SQLite extension..."
	sqlite: import probe to-real-file rejoin [%../sqlite- target %.rebx]
]

? sqlite
print sqlite/info
with sqlite [
	db: open %test.db
	? db
	print info/of db
	trace db 3 ;= SQLITE_TRACE_STMT or SQLITE_TRACE_PROFILE

	exec db {
BEGIN TRANSACTION;
DROP TABLE IF EXISTS Cars;
CREATE TABLE Cars(Id INTEGER PRIMARY KEY, Name TEXT, Price INTEGER);
INSERT INTO "Cars" VALUES(1,'Audi',52642);
INSERT INTO "Cars" VALUES(2,'Mercedes',57127);
INSERT INTO "Cars" VALUES(3,'Skoda',9000);
INSERT INTO "Cars" VALUES(4,'Volvo',29000);
INSERT INTO "Cars" VALUES(5,'Bentley',350000);
INSERT INTO "Cars" VALUES(6,'Citroen',21000);
INSERT INTO "Cars" VALUES(7,'Hummer',41400);
COMMIT;}

	exec db {INSERT INTO "Cars" VALUES(null,'Hummer',null);}
	exec db "SELECT last_insert_rowid();"
	exec db "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
	exec db "SELECT * FROM Cars ORDER BY name"
	exec db "SELECT hex(randomblob(16));"

	stmt: prepare db "SELECT * FROM Cars ORDER BY name"
	? stmt
	print info/of stmt
	probe step stmt
	reset stmt

	sb: prepare db {select randomblob(16)}
	loop 4 [
		probe step sb
		reset sb
	]

	stmt: prepare db "SELECT * FROM Cars WHERE Price > ? ORDER BY name"
	probe step/with/rows stmt [20000] 100
	probe step/with/rows stmt [40000.0] 100
	reset stmt

	stmt: prepare db "SELECT * FROM Cars WHERE Name LIKE :pattern ORDER BY name"
	probe step/with/rows stmt ["H%"] 100
	probe step/with/rows stmt ["A_di"] 100
	reset stmt
	print "SQLite tests done."
]
quit

