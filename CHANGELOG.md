# Changelog

# Next Release

* Location is now updated on registration. Customers location is truncated to 2
  decimal places based on their postcode.

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
