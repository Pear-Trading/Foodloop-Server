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

