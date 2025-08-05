#!/bin/sh

# Source tarball versions
PG_MAJOR=15
PG_MINOR=13
PG_VERSION=${PG_MAJOR}.${PG_MINOR}


#Github branch for source tarball
PG_BRANCH="REL_${PG_MAJOR}_${PG_MINOR}"


#Product names
PPG_NAME=percona-postgresql


#Product full names
PPG_FULL_NAME=${PPG_NAME}-${PG_VERSION}