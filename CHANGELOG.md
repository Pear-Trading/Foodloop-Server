# Changelog

# Next Release

* **Admin Feature** Improved links in relevant places to automatically open in
  a new tab
* **Admin Feature** Ability to add ESTA to entity Added
* Trail map code updated
* Added API for customer graphs
* Revamped graphs code
* Added API for customer local purchase pie charts
* Added API for customer snippets
* Added API for sector purchase list for customer dashboard
* **Admin Fix** Fixed org sector on user edit layout and text
* **Admin Feature** Added Sector U

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
