# LocalSpend (Server)

Looking to discover if the value of spending local can be measured, understood and shown.

This repository contains the server application for the LocalSpend system. See also:

* the [Web application](https://github.com/Pear-Trading/Foodloop-Web); and
* the [mobile application](https://github.com/Pear-Trading/LocalSpend-Tracker).

## Current Status

| Branch        | Status            |
|---------------|------------------ |
| `master`      | [![Build Status](https://travis-ci.org/Pear-Trading/Foodloop-Server.svg?branch=master)](https://travis-ci.org/Pear-Trading/Foodloop-Server) |
| `development` | [![Build Status](https://travis-ci.org/Pear-Trading/Foodloop-Server.svg?branch=development)](https://travis-ci.org/Pear-Trading/Foodloop-Server) |

## Table of Contents

* [Tech Stack](#tech-stack)
* [Features](#features)
* [Installation](#installation)
* [Configuration](#configuration)
* [Usage](#usage)
* [Testing](#testing)
* [Code Formatting](#code-formatting)
* [Documentation](#documentation)
* [Acknowledgments](#acknowledgements)
* [License](#license)
* [Contact](#contact)

## Technology Stack

The server app. is written in [Perl](https://www.perl.org/).

| Technology  | Description         | Link                |
|-------------|---------------------|---------------------|
| Mojolicious | Perl Web framework	| [Link][mojolicious] |
| PostgreSQL	|	Relational database | [Linke][postgresql] |

[mojolicious]: https://mojolicious.org/
[postgresql]: https://www.postgresql.org/

## Features

This server app. provides:

- user creation, updating and deletion;
- organisation creation, updating and deletion;
- transaction logging;
- transaction history analysis; and
- leaderboard generation.

## Installation

1. Clone the repo. to your dev. environment (`git clone git@github.com:Pear-Trading/FoodLoop-Server.git`);
1. enter the new directory (`cd FoodLoop-Server`);
1. install the dependencies:
    - ```shell script
      cpanm --installdeps . \
      --with-feature=sqlite \
      --with-feature=codepoint-open
      ```
    - if you are using a PostgreSQL database, replace `--with-feature=sqlite` with `--with-feature=postgres`.
1. install the database:
    - development supports both SQLite and PostgreSQL, however production uses PostgreSQL;
    - for this example we will use SQLite;
    - as the default config. is set up for this, no configuration changes are needed initially.
    - run `./script/deploy_db install -c 'dbi:SQLite:dbname=foodloop.db'`.
1. set up the development users:
    - `./script/pear-local_loop dev_data --force`
    - **DO NOT RUN ON PROD.**
1. start the [minion](https://docs.mojolicious.org/Minion) job queue:
    - `./script/pear-local_loop minion worker`
1. import ward data:
    1. Download the CSV(s) from [here](https://www.doogal.co.uk/PostcodeDownloads.php); and
    1. run the following command:
        - ```shell script
		      ./script/pear-local_loop minion job \
		      --enqueue 'csv_postcode_import'  \
		      --args '[ "⟨ path to CSV ⟩ ]'
		      ```
1. set up postcodes:
    1. import [Code-Point Open](https://www.ordnancesurvey.co.uk/business-government/products/code-point-open):
    		- a copy is included in `etc/`;
    		- run `./script/pear-local_loop codepoint_open --outcodes LA1`
		1. assign postcodes:
    		- ```shell script
      	  ./script/pear-local_loop minion job \
          --enqueue entity_postcode_lookup
     		  ```

## Configuration

App. configuration settings are found in `pear-local_loop.⟨environment⟩.conf`.

[Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/) (FCM) credentials should be placed in a file called `localspend-47012.json` in root.

## Usage

- Run `morbo script/pear-local_loop -l http://*:3000` to start the server; and
- run `./script/pear-local_loop minion worker` to start the Minion asynchronous job scheduler.

### Database Scripts

To upgrade the database after making changes to commit:

1. Increment the `$VERSION` number in `lib/Pear/LocalLoop/Schema.pm`;
1. run `./script/deploy_db write_ddl -c 'dbi:SQLite:dbname=foodloop.db'`; and
1. run `./script/deploy_db upgrade -c 'dbi:SQLite:dbname=foodloop.db'`.

Run `./script/pear-local_loop recalc_leaderboards` to update the leaderboards.

## Testing

- Run `prove -lr` to run the full test suite using [Test-Simple](https://metacpan.org/release/Test-Simple) (when using an SQLite database); and
- run `PEAR_TEST_PG=1 prove -lr` to run the full test suite (when using a PostgreSQL database).

## Code Formatting

TODO

## Documentation

TODO

## Acknowledgements

LocalLoop is the result of collaboration between the [Small Green Consultancy](http://www.smallgreenconsultancy.co.uk/), [Shadowcat Systems](https://shadow.cat/), [Independent Lancaster](http://www.independent-lancaster.co.uk/) and the [Ethical Small Traders Association](http://www.lancasteresta.org/).

## License

This project is released under the [MIT license](https://mit-license.org/).

## Contact

| Name           | Link(s)           |
|----------------|-------------------|
| Mark Keating   | [Email][mkeating] |
| Michael Hallam | [Email][mhallam]  |

[mkeating]: mailto:m.keating@shadowcat.co.uk
[mhallam]: mailto:info@lancasteresta.org
