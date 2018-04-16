# Changelog

# Next Release

# v.10.7

* Added `cron_daily` script for holding all daily cronjobs
* **Admin Fix** Parse currency without a currency symbol on import
* **Admin Fix** Fix large CSV issue on import
* Use custom secrets for encryption
* Made purchase categories easier to pull
* Added dashboard data for getting essential for all purchases along with
weekly and monthly view of category purchases
* Amended tests where relevant

# v0.10.6

* Fixed organisation submission
* Changed category listing code
* Made transaction upload code more lenient
* Added API ability to edit and delete transactions
* Added test for above
* Made test dumping more sane
* Fixed quantised transaction calcuations for weeks on sqlite
* Amended customer snippet, category list and customer stats tests

# v0.10.5

* **Admin Feature** Removed generic Transaction List, replaced with a new
transaction statistic viewing list
* **Admin Fix** Amended user view to have accordion

# v0.10.4

* Added API for category budget
* Added working test for the new API
* Added initial placeholder API for medals & user points being used in testing
* Added initial schema for medals
* Added essential flag to purchases in schema
* Amended upload API to account for essential purchases
* **Admin Feature** Added ability to view essential flag on purchases
* Made fixes to category viewing API
* Added schema for storing recurring purchases
* Amended Upload code to allow for if purchases are recurring
* Added script for checking recurring purchases and creating them if required

# v0.10.3

* Added Category and Transaction Category tables to DB
* Added API for categories in Transactions
* **Admin Feature** Added ability to add and delete categories
* **Admin Feature** Added ability to view transaction category
* Fixed all relevant tests to match

# v0.10.2

* Added fairly traded column for organisations
* **Admin Fix** Fix issue with setting location on Admin side

# v0.10.1

* Added API for customer graphs
* Revamped graphs code
* Added API for customer local purchase pie charts
* Added API for customer snippets
* Added API for sector purchase list for customer dashboard
* **Admin Fix** Fixed org sector on user edit layout and text
* **Admin Feature** Added Sector U

# v0.10.0

* **API Change** Updated API for story trail maps
* **Admin Feature** Improved links in relevant places to automatically open in
  a new tab
* **Admin Feature** Ability to add ESTA to entity Added
* Trail map code updated

# v0.9.7

* **Admin Fix**: Fix error in Importing under Postgres
* **Admin Feature** Ability to add entity to LIS Added
* Added code endpoint for LIS organisations for web app use
* Schema updated to account for these changes

# v0.9.6

* **Admin Feature** Merged organisation lists into one list
* **Admin Feature** Paginated Organisation listings
* **Admin Feature** Added flags to Organisations listings
* **Admin Feature** Added `is_local` flag to Organisations to start categorising odd stores
* **Admin Feature** Feedback items now word wrap
* **Admin Feature** Rework transaction viewing
* **Admin Feature** Implemented import method for importing previous data from csv
* **Admin Feature** Added badges for various organisation flags eg. local, user, validated
* **Admin Feature** Enabled merging of organisations to reduce duplicates
* **Admin Feature** Added badges to user listing to show whether customer or organisation
* **Admin Feature** Added pagination to user listings
* Improved logging for debugging issues with login

# v0.9.5

* Added leaderboard api for web-app with pagination
* Location is now updated on registration. Customers location is truncated to 2
  decimal places based on their postcode.
* Location is also updated on changing a users postcode
* Distance is now calculated when a transaction is submitted

## Bug Fixes

* Updated Geo::UK::Postcode::Regex dependency to latest version. Fixes postcode
  validation errors

# v0.9.4

* **Admin Feature:** Report of transaction data graphs
* **Fix:** Mobile view meta tag for admin
* Upgrade all CSS to Bootstrap 4 beta
* **Admin Feature:** Added version number to admin console

# v0.9.3

* **Feature:** lat/long locations on customers and organisations
* **Feature:** Suppliers map co-ords

# v0.9.2

* **Fix:** Leaderboard total calculations not mapped correctly
* **Fix:** Reroute to org list on submission

# v0.9.1

* Change to semantic versioning
* Change database schema to use entity style model
* Added schema graphs for showing the schema layout
* **Fix:** null values on Org Graphs
* **Feature:** Org Graphs for sales and purchase data
* **Fix:** Deny organisations buying from themselves
* **Feature:** API endpoint for viewing purchases
* **Feature:** Transaction viewing in Admin interface
* **Fix:** Booleans under postgres and sqlite
* **Feature:** Organisation snippets API

# v0.009

*No changes recorded*

# v0.008.1

*No changes recorded*

# v0.008

*No changes recorded*

# v0.007

*No changes recorded*

# v0.006

*No changes recorded*

# v0.005

*No changes recorded*

# v0.004

*No changes recorded*

# v0.003

Made leaderboard cronjob scripts work correctly by using production config
instead of defaulting to development

# v0.002

Release with leaderboard scripts for automatic generation of leaderboards

# v0.001

First release with basic functionality.
