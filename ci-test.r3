Rebol [
    title: "Rebol/SQLite extension CI test"
]

print ["Running test on Rebol build:" mold to-block system/build]
system/options/quiet: false
system/options/log/rebol: 4

;; make sure that we load a fresh extension
try [system/modules/sqlite: none]
try [unset in system/schemes 'sqlite]

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


;; import the extension
sqlite: import 'sqlite

print as-yellow "Content of the module..."
? sqlite

print sqlite/info

;; make sure that the library is usable at all before running the suite
try/with [
    db: sqlite/open %ci-probe.db
    sqlite/close db
    attempt [delete %ci-probe.db]
][
    print "The SQLite library could not be used to open a database!"
    print system/state/last-error
    quit/return 1
]

;; run a real test file...
do %test.r3
