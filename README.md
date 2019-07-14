# Pear LocalLoop Server

## Current Status

*Master:* [![Build Status](https://travis-ci.org/Pear-Trading/Foodloop-Server.svg?branch=master)](https://travis-ci.org/Pear-Trading/Foodloop-Server)

*Development:* [![Build Status](https://travis-ci.org/Pear-Trading/Foodloop-Server.svg?branch=development)](https://travis-ci.org/Pear-Trading/Foodloop-Server)

# Testing

To run the main test framework, first install all the dependencies, then run the tests:

```
cpanm --installdeps .
prove -lr
```

To run the main framework against a PostgreSQL backend, assuming you have postgres installed, you will need some extra dependencies first:

```
cpanm --installdeps . --with-feature postgres
PEAR_TEST_PG=1 prove -lr
```

# Minion

to set up minion support, you will need to create a database and user for
minion to connect to. In production his should be a PostgreSQL database,
however an SQLite db can be used in testing.

To use the SQLite version, run the following commands:

```
cpanm --installdeps --with-feature sqlite .
```

And then add the following to your configuration file:

```
  minion => {
    SQLite => 'sqlite:minion.db',
  },
```

This will then use an SQLite db for the minion backend, at minion.db


## Example PostgreSQL setup

```
# Example commands - probably not the best ones
# TODO come back and improve these with proper ownership and DDL rights
sudo -u postgres createuser minion
sudo -u postgres createdb localloop_minion
sudo -u postgres psql
psql=# alter user minion with encrypted password 'abc123';
psql=# grant all privileges on database localloop_minion to minion;
```

# Dev notes

## Local test database

To install a local DB:

```
./script/deploy_db install -c 'dbi:SQLite:dbname=foodloop.db'
```

To do an upgrade of it after making DB changes to commit:

```
./script/deploy_db write_ddl -c 'dbi:SQLite:dbname=foodloop.db'
./script/deploy_db upgrade -c 'dbi:SQLite:dbname=foodloop.db'
```

To redo leaderboards:

```
./script/pear-local_loop recalc_leaderboards
```

To serve a test version locally of the server:

```
morbo script/pear-local_loop
```
