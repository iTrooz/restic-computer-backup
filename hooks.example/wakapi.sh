#!/bin/sh
SCRIPT_DIR=$(dirname "$0")
sqlite3 /etc/wakapi/wakapi.db .dump | gzip > $SCRIPT_DIR/../tmp/wakapi.sql.gz
