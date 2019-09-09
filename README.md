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

This will then use an SQLite db for the minion backend, using `minion.db` as
the database file. To start the minion itself, run:

```
./script/pear-local_loop minion worker
```

# Importing Ward Data

To import ward data, get the ward data csv and then run the following command:

```shell script
./script/pear-local_loop minion job \
  --enqueue 'csv_postcode_import' \
  --args '[ "/path/to/ward/csv" ]'
```

# Setting up Entity Postcodes

Assuming you have imported codepoint open, then to properly assign all
 postcodes:
 
```shell script
./script/pear-local_loop minion job \
  --enqueue entity_postcode_lookup
```

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

# Development

There are a couple of setup steps to getting a development environment ready.
Use the corresponding instructions depending on what state your current setup
is in.

## First Time Setup

First, decide if you're using SQLite or PostgreSQL locally. Development supports
both, however production uses PostgreSQL. For this example we will use SQLite.
As the default config is set up for this, no configuration changes are
needed initially. So, first off, install dependencies:

```shell script
cpanm --installdeps . --with-feature=sqlite
```

Then install the database:

```shell script
./script/deploy_db install -c 'dbi:SQLite:dbname=foodloop.db'
```

Then set up the development users:

```shell script
./script/pear-local_loop dev_data --force
```

***Note: do NOT run that script on production.***

Then you can start the application:

```shell script
morbo script/pear-local_loop -l http://*:3000
```

You can modify the host and port for listening as needed.

# Old Docs

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
