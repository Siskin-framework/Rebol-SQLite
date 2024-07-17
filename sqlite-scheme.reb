Rebol [
	title: "SQLite scheme (WIP)"
	file:  %sqlite-scheme.reb
	note:  {This is just an initial proof of concept}
	version: 0.1.0
	author: "Oldes"
	needs:   [
		3.13.1 ;; using system/options/modules as extension location
		sqlite
	]
]

sys/make-scheme [
	title: "SQLite database scheme"
	name:  'sqlite
	spec:   make system/standard/port-spec-file []
	sqlite: import sqlite

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
				statements:  make map! 0       ;; prepared statements
				query:                         ;; last used query
				stmt:        none              ;; last prepared statement
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

		;; WRITE now just executes a query... no result is collected, but may be printed in console
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
