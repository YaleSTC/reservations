# Changelog
* This file will be updated whenever a new release is put into production.
* Any problems should be reported via the "report an issue" link in the footer of the application.

## Unreleased
### Fixed
* Fixed issue with links to documentation and anchor tags being escaped in flash mesasges ([#1760](https://github.com/YaleSTC/reservations/issues/1760)).
* Fixed issue with recurring blackouts being blocked by old reservations ([#1756](https://github.com/YaleSTC/reservations/issues/1756)).
* Update loofah from 2.2.2 -> 2.2.3 ([#1763](https://github.com/YaleSTC/reservations/issues/1763)).

## v6.3.5 - 2018-10-08
### Fixed
* Fixed an issue where cancelling a reservation would break availability ([#1754](https://github.com/YaleSTC/reservations/issues/1754)).
* Updated a number of dependencies to fix security vulnerabilities ([#1757](https://github.com/YaleSTC/reservations/issues/1757)).

## v6.3.4 - 2018-08-10
### Changed
* Log files now rotate properly, limited to 150 MB/file with 5 files retained ([#1743](https://github.com/YaleSTC/reservations/issues/1743)).
* Allowed for bulk-updating of user roles with a csv import with just usernames ([#1748](https://github.com/YaleSTC/reservations/issues/1748)).

### Fixed
* Fixed broken renewals when reservations were the maximum checkout length ([#1734](https://github.com/YaleSTC/reservations/issues/1734)).
* Fixed issue with the manage reservation button for approved requests ([1747](https://github.com/YaleSTC/reservations/issues/1747))
* Fixed unauthorized display of procedures and equipment items ([1749](https://github.com/YaleSTC/reservations/issues/1749))

## v6.3.3 - 2018-07-20
### Fixed
* Modify daily/hourly Admin buttons to use relative path via helper method ([1742](https://github.com/YaleSTC/reservations/issues/1742))
* Fix buttons to run cron tasks ([1745](https://github.com/YaleSTC/reservations/issues/1745))
* Change rake daily/hourly tasks to execute immediately to fix issue with cron job in production ([#1739](https://github.com/YaleSTC/reservations/issues/1739), [#1740](https://github.com/YaleSTC/reservations/issues/1740), [#1741](https://github.com/YaleSTC/reservations/issues/1741))

## v6.3.2 - 2018-06-26
### Fixed
* Fixed incorrect evaluation of reservations affected by a blackout ([#1644](https://github.com/YaleSTC/reservations/issues/1644)).
* Fixed issues with escaped HTML in flashes and elsewhere ([#1705](https://github.com/YaleSTC/reservations/issues/1705)).
* Fixed issues with deactivation / activation by removing permanent_records ([#1715](https://github.com/YaleSTC/reservations/issues/1715)).
* Fixed broken return receipts ([#1717](https://github.com/YaleSTC/reservations/issues/1717)).
* Fixed issue with previous migration leading to incorrect data ([#1722](https://github.com/YaleSTC/reservations/issues/1722)).
* Fixed broken hourly / monthly task buttons ([#1723](https://github.com/YaleSTC/reservations/issues/1723)).
* Fixed reservation checkin / checkout with procedures ([#1726](https://github.com/YaleSTC/reservations/issues/1726)).
* Fixed broken procedure creation ([#1727](https://github.com/YaleSTC/reservations/issues/1727)).
* Fixed broken calendar feed with archived reservations ([#1729](https://github.com/YaleSTC/reservations/issues/1729)).
* Updated several vulnerable dependencies.
* Fixed broken rendering of equipment with a requirement ([#1730](https://github.com/YaleSTC/reservations/issues/1730)).

### Added
* Added link to the accessibility at Yale site in the footer ([#1725](https://github.com/YaleSTC/reservations/issues/1725)).

## v6.3.1 - 2018-05-31
### Fixed
* Fixed issues with AWS S3 and Paperclip ([#1702](https://github.com/YaleSTC/reservations/issues/1702)).
* Fixed new user signup when guest access is disabled ([#1706](https://github.com/YaleSTC/reservations/issues/1706)).
* Permit the use of S3 buckets in regions other than US-East-1 ([#1708](https://github.com/YaleSTC/reservations/issues/1708)).
* Fixed issue with displaying future reservations ([#1711](https://github.com/YaleSTC/reservations/issues/1711)).
* Fix issue with checkout form populating the same equipment items for all models ([#1713](https://github.com/YaleSTC/reservations/issues/1713)).

### Removed
* Removed the ability to order equipment models due to bugs ([#1696](https://github.com/YaleSTC/reservations/issues/1696)).

## v6.3.0 - 2017-09-01
### Important
*This release includes an update to Ruby 2.4.1 and Rails 5.1 along with other dependencies*
*This release fixes several long-standing security vulnerabilities*

### Fixed
* Put headers in order corresponding to their order on reservation page ([#1661](https://github.com/YaleSTC/reservations/issues/1661)).
* Fixed the equipment model seed script generator ([#1662](https://github.com/YaleSTC/reservations/issues/1662)).
* Fixed broken database migrations ([#1676](https://github.com/YaleSTC/reservations/issues/1676), [#1684](https://github.com/YaleSTC/reservations/issues/1684)).
* Fixed Heroku deployments by updating post-deploy script and switching to MySQL ([#1680](https://github.com/YaleSTC/reservations/issues/1680), [#1690](https://github.com/YaleSTC/reservations/issues/1690)).
* Fixed the creation of recurring blackouts ([#1698](https://github.com/YaleSTC/reservations/issues/1698)).

### Added
* Added ordering of equipment models within the catalog ([#1418](https://github.com/YaleSTC/reservations/issues/1418)).
* Add API-based user lookup functionality in addition to LDAP ([#1648](https://github.com/YaleSTC/reservations/issues/1648)).

### Changed
* Refactor LDAP functionality into a separate class ([#1649](https://github.com/YaleSTC/reservations/issues/1649)).

## v6.2.0 - 2016-07-04
### Important
*This release includes an update to Ruby 2.3.1 along with other dependencies*

### Fixed
* Fixed intermittent asset failure in specs ([#1528](https://github.com/YaleSTC/reservations/issues/1528)).
* Downgraded Permanent Record gem to fix deactivation issue ([#1638](https://github.com/YaleSTC/reservations/issues/1638)).
* Fixed cart validation counting error ([#1641](https://github.com/YaleSTC/reservations/issues/1641)).
* Fixed User phone number validation regex ([#1633](https://github.com/YaleSTC/reservations/issues/1633)).
* Use AppConfig#check everywhere ([#1584](https://github.com/YaleSTC/reservations/issues/1584)).
* Fix issues with Paperclip and S3 ([#1702](https://github.com/YaleSTC/reservations/issues/1702)).

### Added
* Configuration for Hound CI ([#1577](https://github.com/YaleSTC/reservations/issues/1577)).
* Setting to allow requests to block availability ([#1521](https://github.com/YaleSTC/reservations/issues/1521)).
* Buttons to run cron jobs manually ([#1275](https://github.com/YaleSTC/reservations/issues/1275)).
* TravisCI now runs ESlint ([#1581](https://github.com/YaleSTC/reservations/issues/1581)).

### Changed
* Refactor EquipmentModel model spec ([#1600](https://github.com/YaleSTC/reservations/issues/1600)).
* Refactor EquipmentModels controller spec ([#1587](https://github.com/YaleSTC/reservations/issues/1587)).
* Periodic rake tasks moved to ActiveJob ([#1275](https://github.com/YaleSTC/reservations/issues/1275)).
* Refactor Reservation model spec ([#1554](https://github.com/YaleSTC/reservations/issues/1554)).
* Refactor EquipmentItems controller spec ([#1588](https://github.com/YaleSTC/reservations/issues/1588)).
* Refactor Reservations controller spec ([#1586](https://github.com/YaleSTC/reservations/issues/1586)).
* Refactor EquipmentItem model spec ([#1610](https://github.com/YaleSTC/reservations/issues/1600)).
* Refactor Users controller spec ([#1595](https://github.com/YaleSTC/reservations/issues/1595)).
* Refactor Categories controller spec ([#1589](https://github.com/YaleSTC/reservations/issues/1589)).
* Overhaul seed script ([#1327](https://github.com/YaleSTC/reservations/issues/1327)).
* Default LDAP to nil in test suite ([#1411](https://github.com/YaleSTC/reservations/issues/1411)).

## v6.1.0 - 2016-06-01
### Fixed
* Seed script no longer saves reservations with invalid dates ([#1229](https://github.com/YaleSTC/reservations/issues/1229)).
* Seed script no longer saves future overdue reservations ([#1263](https://github.com/YaleSTC/reservations/issues/1263)).
* Minor clean up of CsvExport code ([#1499](https://github.com/YaleSTC/reservations/issues/1499)).
* Availability calculation methods all work as expected ([#1501](https://github.com/YaleSTC/reservations/issues/1501)).
* Fixed intermittent ElementNotFound error during tests ([#1514](https://github.com/YaleSTC/reservations/issues/1514)).
* Fixed progress bar overflow on reservations show page ([#1532](https://github.com/YaleSTC/reservations/issues/1532)).

### Changed
* Changed default Heroku mailer from Mandrill to Sendgrid ([#1515](https://github.com/YaleSTC/reservations/issues/1515)).
* Updated all dependencies ([#1553](https://github.com/YaleSTC/reservations/issues/1553)).

## v6.0.0 - 2016-04-11
### Important
*This release includes an upgrade to Ruby 2.2.3 and Rails 4.2.5 along with updates to many other dependencies. Also, the configuration parameter SERVE_STATIC was renamed to RAILS_SERVE_STATIC_FILES.*

### Fixed
* Fixed issue with duplicate search results ([#933](https://github.com/YaleSTC/reservations/issues/933)).
* Fixed the alignment of the reset TOS checkbox on the Settings page ([#1266](https://github.com/YaleSTC/reservations/issues/1266)).
* Fixed issue where most users couldn't hide announcements ([#1339](https://github.com/YaleSTC/reservations/issues/1339)).
* The equipment model availability numbers no longer overflow when they are two digits long ([#1363](https://github.com/YaleSTC/reservations/issues/1363)).
* Admins can again manually create new users when CAS authentication is enabled ([#1370](https://github.com/YaleSTC/reservations/issues/1370)).
* Fixed integration of Capistrano with the whenever cron scheduler ([#1373](https://github.com/YaleSTC/reservations/issues/1373)).
* Fixed missing affiliation LDAP lookup ([#1375](https://github.com/YaleSTC/reservations/issues/1375)).
* Fixed broken cancel button on the quick new user model ([#1376](https://github.com/YaleSTC/reservations/issues/1376)).
* Fixed issue with missing datepicker assets / update jQuery UI + Bootstrap theme ([#1377](https://github.com/YaleSTC/reservations/issues/1377)).
* The reservation history tables on user profiles are again sortable ([#1378](https://github.com/YaleSTC/reservations/issues/1378)).
* Fixed broken link to pending reservations on equipment model page ([#1379](https://github.com/YaleSTC/reservations/issues/1379)).
* Fixed broken "Total Stock" count on the equipment model table ([#1380](https://github.com/YaleSTC/reservations/issues/1380)).
* Fixed migration that was leading to reservations being incorrectly marked as overdue ([#1381](https://github.com/YaleSTC/reservations/issues/1381)).
* Removed extra padding from navbar due to #1377 ([#1403](https://github.com/YaleSTC/reservations/issues/1403)).
* The quick new user modal form works again ([#1421](https://github.com/YaleSTC/reservations/issues/1421), [#1469](https://github.com/YaleSTC/reservations/issues/1469), [#1471](https://github.com/YaleSTC/reservations/issues/1471)).
* All URL helpers now use the correct relative root with subdirectory deployment ([#1424](https://github.com/YaleSTC/reservations/issues/1424), [#1465](https://github.com/YaleSTC/reservations/issues/1465)).
* Fixed the links to Paperclip uploads ([#1425](https://github.com/YaleSTC/reservations/issues/1425)).
* Resolved an issue where all AdminMailer e-mails were not being delivered ([#1426](https://github.com/YaleSTC/reservations/issues/1426)).
* Fixed typo in .env.example ([#1427](https://github.com/YaleSTC/reservations/issues/1427)).
* Resolved an issue where late fees in e-mails were cumulative, not daily ([#1433](https://github.com/YaleSTC/reservations/issues/1433)).
* CSV Import can handle CR line endings ([#1438](https://github.com/YaleSTC/reservations/issues/1438)).
* Uploaded CSVs support extra columns ([#1439](https://github.com/YaleSTC/reservations/issues/1439)).
* Daily rake tasks run sequentially; check-in emails now only send for checked-out reservations ([#1446](https://github.com/YaleSTC/reservations/issues/1446)).
* Resolved an issue where checked-out reservations were not being taken into account when validating availability ([#1449](https://github.com/YaleSTC/reservations/issues/1449)).
* Translation added for button label ([#1463](https://github.com/YaleSTC/reservations/issues/1463)).
* The start and end dates of reports can now actually be changed ([#1476](https://github.com/YaleSTC/reservations/issues/1476)).
* The reservation overdue parameter correctly updates when editing the due date of checked out reservations ([#1479](https://github.com/YaleSTC/reservations/issues/1479)).
* Fixed an issue where enabling CAS wouldn't actually require the relevant gem ([#1487](https://github.com/YaleSTC/reservations/issues/1487)).
* Reservations now correctly identifies blackout conflicts ([#1489](https://github.com/YaleSTC/reservations/issues/1489)).
* Various UI bugs fixed: equipment_model show table and checkout restrictions ([#1492](https://github.com/YaleSTC/reservations/issues/1492)).
* Terms of Service checkbox correctly determines if editable ([#1497](https://github.com/YaleSTC/reservations/issues/1497)).
* Fixed some strange behavior with the availability calendar ([#1498](https://github.com/YaleSTC/reservations/issues/1498)).
* The contact form now correctly falls back to the admin e-mail if no separate e-mail is set ([#1524](https://github.com/YaleSTC/reservations/issues/1524)).
* Fixed regression with the crontab generator ([#1542](https://github.com/YaleSTC/reservations/issues/1542)).
* Fixed issue with request prompt on new reservation confirmation page ([#1544](https://github.com/YaleSTC/reservations/issues/1544)).

### Added
* Uploads can now be hosted on Amazon S3; particularly useful for Heroku deployments ([#1210](https://github.com/YaleSTC/reservations/issues/1210)).
* Users can no longer create consecutive reservations to bypass length limits ([#1311](https://github.com/YaleSTC/reservations/issues/1311)).
* CSV files of user and equipment data can be downloaded ([#1337](https://github.com/YaleSTC/reservations/issues/1337)).
* You can now view a monthly calendar view of reservations for categories, equipment models, and equipment items. ([#1360](https://github.com/YaleSTC/reservations/issues/1360)).
* Made archived reservations accessible through the reservations index page ([#1383](https://github.com/YaleSTC/reservations/issues/1383)).
* Equipment items checked out to a given reservation are now optionally deactivated when that reservation is archived ([#1384](https://github.com/YaleSTC/reservations/issues/1384)).

### Changed
* Refactored and redesigned the confirm reservation page to allow editing ([#237](https://github.com/YaleSTC/reservations/issues/237)).
* Clarified error message when adding too many items to cart ([#1242](https://github.com/YaleSTC/reservations/issues/1242)).
* Refactored and improved Reservation queries using Query Objects ([#1288](https://github.com/YaleSTC/reservations/issues/1288)).
* Updated all dependencies, including Ruby and Rails ([#1329](https://github.com/YaleSTC/reservations/issues/1329)).
* Refactored and improved the md_link method for resources and standardized its usage in notes / logs ([#1382](https://github.com/YaleSTC/reservations/issues/1382)).
* Improved ability.rb for clarity and to avoid redundancy ([#1391](https://github.com/YaleSTC/reservations/issues/1391)).
* Reordered sections on current reservations page ([#1414](https://github.com/YaleSTC/reservations/issues/1414)).
* Updated SERVE_STATIC to RAILS_SERVE_STATIC_FILES in .env.example and app.json ([#1419](https://github.com/YaleSTC/reservations/issues/1419)).
* Changed receipts page to include user search ([#1420](https://github.com/YaleSTC/reservations/issues/1420)).
* Reservations now defaults to deleting missed reservations after one week ([#1491](https://github.com/YaleSTC/reservations/issues/1491)).
* Fixed redirect error on direct url visit to /reservations/new ([#1502](https://github.com/YaleSTC/reservations/issues/1502)).
* Updated the database schema to reflect the default field limits in MariaDB based on change in Rails 4.2 ([#1517](https://github.com/YaleSTC/reservations/issues/1517)).

## v5.5.6 - 2016-03-07
### Fixed
* CSV Import can handle CR line endings ([#1438](https://github.com/YaleSTC/reservations/issues/1438)).
* Reservations now correctly identifies blackout conflicts ([#1489](https://github.com/YaleSTC/reservations/issues/1489)).
* Various UI bugs fixed: equipment model show table and checkout restrictions ([#1492](https://github.com/YaleSTC/reservations/issues/1492)).
* Terms of Service checkbox correctly determines if editable ([#1497](https://github.com/YaleSTC/reservations/issues/1497)).
* Fixed some strange behavior with the availability calendar ([#1498](https://github.com/YaleSTC/reservations/issues/1498)).
* Directly accessing /reservations/new now redirects to root_path ([#1502](https://github.com/YaleSTC/reservations/issues/1502)).
* The contact form now correctly falls back to the admin e-mail if no separate e-mail is set ([#1524](https://github.com/YaleSTC/reservations/issues/1524)).

### Changed
* Reservations now defaults to deleting missed reservations after one week ([#1491](https://github.com/YaleSTC/reservations/issues/1491)).
* The availability calendar now uses FullCalendar ([#1498](https://github.com/YaleSTC/reservations/issues/1498)).

## v5.5.5 - 2016-02-05
### Fixed
* Updated Rails Admin to allow editing of reservations ([#1449](https://github.com/YaleSTC/reservations/issues/1449#issuecomment-180207219)).
* The start and end dates of reports can now actually be changed ([#1476](https://github.com/YaleSTC/reservations/issues/1476)).
* The reservation overdue parameter correctly updates when editing the due date of checked out reservations ([#1479](https://github.com/YaleSTC/reservations/issues/1479)).

## v5.5.4 - 2016-02-02
### Fixed
* The quick new user modal form works again ([#1421](https://github.com/YaleSTC/reservations/issues/1421), [#1469](https://github.com/YaleSTC/reservations/issues/1469), [#1471](https://github.com/YaleSTC/reservations/issues/1471)).
* All URL helpers now use the correct relative root with subdirectory deployment ([#1424](https://github.com/YaleSTC/reservations/issues/1424), [#1465](https://github.com/YaleSTC/reservations/issues/1465)).
* Fixed the links to Paperclip uploads ([#1425](https://github.com/YaleSTC/reservations/issues/1425)).
* Uploaded CSVs support extra columns ([#1439](https://github.com/YaleSTC/reservations/issues/1439)).
* Daily rake tasks run sequentially; check-in emails now only send for checked-out reservations ([#1446](https://github.com/YaleSTC/reservations/issues/1446)).

### Changed
* Changed receipts page to include user search ([#1420](https://github.com/YaleSTC/reservations/issues/1420)).

## v5.5.3 - 2016-01-24
### Fixed
* Resolved an issue where checked-out reservations were not being taken into account when validating availability ([#1449](https://github.com/YaleSTC/reservations/issues/1449)).

## v5.5.2 - 2016-01-18
### Fixed
* Resolved an issue where all AdminMailer e-mails were not being delivered ([#1426](https://github.com/YaleSTC/reservations/issues/1426)).
* Resolved an issue where late fees in e-mails were cumulative, not daily ([#1433](https://github.com/YaleSTC/reservations/issues/1433)).

## v5.5.1 - 2016-01-12
### Fixed
* Fixed issue where most users couldn't hide announcements ([#1339](https://github.com/YaleSTC/reservations/issues/1339)).
* The equipment model availability numbers no longer overflow when they are two digits long ([#1363](https://github.com/YaleSTC/reservations/issues/1363)).
* Admins can again manually create new users when CAS authentication is enabled ([#1370](https://github.com/YaleSTC/reservations/issues/1370)).
* Fixed integration of Capistrano with the whenever cron scheduler ([#1373](https://github.com/YaleSTC/reservations/issues/1373)).
* Fixed missing affiliation LDAP lookup ([#1375](https://github.com/YaleSTC/reservations/issues/1375)).
* Fixed broken cancel button on the quick new user model ([#1376](https://github.com/YaleSTC/reservations/issues/1376)).
* Fixed issue with missing datepicker assets ([#1377](https://github.com/YaleSTC/reservations/issues/1377)).
* The reservation history tables on user profiles are again sortable ([#1378](https://github.com/YaleSTC/reservations/issues/1378)).
* Fixed broken link to pending reservations on equipment model page ([#1379](https://github.com/YaleSTC/reservations/issues/1379)).
* Fixed broken "Total Stock" count on the equipment model table ([#1380](https://github.com/YaleSTC/reservations/issues/1380)).
* Fixed migration that was leading to reservations being incorrectly marked as overdue ([#1381](https://github.com/YaleSTC/reservations/issues/1381)).
* Removed extra padding from navbar due to #1377 ([#1403](https://github.com/YaleSTC/reservations/issues/1403)).

### Added
* Made archived reservations accessible through the reservations index page ([#1383](https://github.com/YaleSTC/reservations/issues/1383)).

### Changed
* Updated jQuery UI and its associated Bootstrap theme ([#1377](https://github.com/YaleSTC/reservations/issues/1377)).
* Updated the default sort order for the reservation history tables on user profiles ([#1378](https://github.com/YaleSTC/reservations/issues/1378)).
* Updated jQuery Datatables ([#1378](https://github.com/YaleSTC/reservations/issues/1378)).
* Reordered sections on the current reservations page ([#1414](https://github.com/YaleSTC/reservations/issues/1414)).


## v5.5.0 - 2015-11-23
### Fixed
* The dropdown menu that appears when clicking on the reserver in a list of reservations is no longer blocked in a short table ([#724](https://github.com/YaleSTC/reservations/issues/724)).
* Importing users when using CAS now correctly sets their cas_login ([#1272](https://github.com/YaleSTC/reservations/issues/1272)).
* Resolved issues with an earlier migration that would fail when trying to update an old database ([#1330](https://github.com/YaleSTC/reservations/issues/1330)).
* Fixed issue with FontAwesome asset files in production ([#1342](https://github.com/YaleSTC/reservations/issues/1342)).
* Fixed broken search results partial ([#1344](https://github.com/YaleSTC/reservations/issues/1344)).
* Resolved issue with missing logs in non-Heroku deployments ([#1345](https://github.com/YaleSTC/reservations/issues/1345)).
* Fixed an issue where requirements could not be applied to users ([#1354](https://github.com/YaleSTC/reservations/issues/1354)).
* The secret token is now appropriately set by the relevant environment variable ([#1356](https://github.com/YaleSTC/reservations/issues/1356)).

### Changed
* Multiple equipment items of a given equipment model can no longer have the same non-blank serial number ([#296](https://github.com/YaleSTC/reservations/issues/296)).
* Made equipment model table more informative for patrons ([#1199](https://github.com/YaleSTC/reservations/issues/1199)).
* The reservation note for creation now includes the name of the reserver ([#1250](https://github.com/YaleSTC/reservations/issues/1250)).

## v5.4.0 - 2015-10-26
### Fixed
* Setup script for initial user now doesn't echo the typed password ([#1304](https://github.com/YaleSTC/reservations/pull/1304)).
* Addressed a versioning issue with Capistrano ([#1306](https://github.com/YaleSTC/reservations/issues/1306)).
* The seed-script-created superuser can now login in CAS mode ([#1320](https://github.com/YaleSTC/reservations/issues/1320)).
* Actually fixed the user authentication initializer allowing both CAS and password authentication to be used ([#1324](https://github.com/YaleSTC/reservations/issues/1324)).

### Added
* ENV variable 'LOG_EMAILS' to log more detailed information upon sending any email ([#1127](https://github.com/YaleSTC/reservations/issues/1127)).
* Email notifcations for requests that expire ([#1203](https://github.com/YaleSTC/reservations/issues/1203)).

## v5.3.0 - 2015-09-21
### Fixed
* Fixed issues with reservation renewals and added tests ([#416](https://github.com/YaleSTC/reservations/issues/416), [#1218](https://github.com/YaleSTC/reservations/issues/1218)).
* Reservation scopes refactored ([#462](https://github.com/YaleSTC/reservations/issues/462)).
* Equipment Items and other deactivate-able resources can now be destroyed using Rails Admin ([#1062](https://github.com/YaleSTC/reservations/issues/1062)).
* Fixed broken calendar logic ([#1218](https://github.com/YaleSTC/reservations/issues/1218)).
* Forgetting to check off the ToS checkbox during checkout no longer causes checkout to fail silently ([#1227](https://github.com/YaleSTC/reservations/issues/1227)).
* ToS acceptance is no longer saved if checkout doesn't succeed ([#1227](https://github.com/YaleSTC/reservations/issues/1227)).
* Trying to make a reservation with an empty cart now redirects properly to the last page you were on ([#1235](https://github.com/YaleSTC/reservations/issues/1235)).
* Autocomplete now works on Heroku / when using a PostgreSQL database ([#1237](https://github.com/YaleSTC/reservations/issues/1237)).
* Several issues with e-mails were addressed ([#1240](https://github.com/YaleSTC/reservations/issues/1240)).
* Admin users and superusers can no longer ban themselves ([#1241](https://github.com/YaleSTC/reservations/issues/1241)).
* Attempting to check out equipment without checking off the ToS checkbox no longer updated the equipment item notes ([#1243](https://github.com/YaleSTC/reservations/issues/1243)).
* Fixed visibility issue with autocomplete selection ([#1251](https://github.com/YaleSTC/reservations/issues/1251)).
* Archiving a reservation with a missing reserver no longer fails ([#1253](https://github.com/YaleSTC/reservations/issues/1253)).
* The Reservation#approved? method now correctly returns false for open requests ([#1267](https://github.com/YaleSTC/reservations/issues/1267)).
* CSV upload now sanitizes for invalid UTF-8 characters ([#1271](https://github.com/YaleSTC/reservations/issues/1271), [#1299](https://github.com/YaleSTC/reservations/issues/1299)).
* All Rake tasks were refactored to avoid the `LocalJumpError` when calling the bulk tasks defined for Heroku ([#1276](https://github.com/YaleSTC/reservations/issues/1276)).
* The authorization initializer is now skipped if running commands with a pre-v4.1.0 database ([#1282](https://github.com/YaleSTC/reservations/issues/1282)).

### Added
* Added integration tests for basic reservation actions and Rails Admin routes ([#416](https://github.com/YaleSTC/reservations/issues/416)).
* Added Reservation flags for various attributes ([see wiki](https://github.com/YaleSTC/reservations/wiki/Reservation-Flags), [#462](https://github.com/YaleSTC/reservations/issues/462)).
* Set up Capistrano deployment script ([#1074](https://github.com/YaleSTC/reservations/issues/1074)).
* Added quantity fields to cart items ([#1114](https://github.com/YaleSTC/reservations/issues/1114)).
* Added the ability to view returned overdue reservations from the reservations index page along with their late fees ([#1121](https://github.com/YaleSTC/reservations/issues/1121)).
* Checkout receipts are now sent automatically on checkout ([#1215](https://github.com/YaleSTC/reservations/issues/1215)).
* Added an optional admin notification upon Reservation creation ([#1284](https://github.com/YaleSTC/reservations/issues/1284)).
* Added an optional cap for equipment item late fees ([#1285](https://github.com/YaleSTC/reservations/issues/1285)).
* Added kill switch for user e-mails ([#1286](https://github.com/YaleSTC/reservations/issues/1286)).

### Changed
* Reservation approval status and status method are now consolidated into a status enum ([#462](https://github.com/YaleSTC/reservations/issues/462)).
* Equipment item notes can now only be viewed by admin roles and higher ([#1245](https://github.com/YaleSTC/reservations/issues/1245)).
* Equipment can now be checked-in for banned users ([#1246](https://github.com/YaleSTC/reservations/issues/1246)).
* TOS checkbox on checkout/checkin page moved to the left of the notice text for increased salience and UX consistency ([#1259](https://github.consistencom/YaleSTC/reservations/issues/1259)).
* The Reservation status / flagging tasks have been removed from the `flag_reservations` namespace and put in separate files ([#1273](https://github.com/YaleSTC/reservations/issues/1273)).
* The cron task that flags overdue reservations has been updated to check all past reservations ([#1274](https://github.com/YaleSTC/reservations/issues/1274)).

## v5.2.2 - 2015-04-20
### Fixed
* Forgetting to check off the ToS checkbox during checkout no longer causes checkout to fail silently ([#1227](https://github.com/YaleSTC/reservations/issues/1227)).

## v5.2.1 - 2015-04-14
### Fixed
* Skipped authentication initializer when users table does not yet exist; resolves issue where new Heroku installation failed due to asset precompilation running before database migrations.
* Added seed script gems to heroku group in the Gemfile; resolves regression due to [#1165](https://github.com/YaleSTC/reservations/issues/1165) ([#1226](https://github.com/YaleSTC/reservations/issues/1226)).

## v5.2.0 - 2015-04-13
### Fixed
* Refactored qualifications logic from catalog views ([#980](https://github.com/YaleSTC/reservations/issues/980)).
* Fixed broken pdf uploads on Firefox ([#1016](https://github.com/YaleSTC/reservations/issues/1016)).
* Fixed user import for CAS and LDAP users ([#1094](https://github.com/YaleSTC/reservations/issues/1094)).
* Rails Admin can now manipulate all important models in the database ([#1122](https://github.com/YaleSTC/reservations/issues/1122)).
* Re-added links to flash messages ([#1124](https://github.com/YaleSTC/reservations/issues/1124)).
* Fixed broken checkout / checkin procedures ([#1139](https://github.com/YaleSTC/reservations/issues/1139)).
* 3rd party assets were moved to a separate directory ([#1142](https://github.com/YaleSTC/reservations/issues/1142)).
* Application config settings now pre-check for existing configuration to prevent crashes when the configuration isn't initialized ([#1144](https://github.com/YaleSTC/reservations/issues/1144)).
* EquipmentModels with uploaded documentation no longer crash ([#1181](https://github.com/YaleSTC/reservations/issues/1181)).
* Banned users can no longer have reservations created for them or equipment checked out to them ([#1185](https://github.com/YaleSTC/reservations/issues/1185)).
* Fixed broken view on equipment model import ([#1192](https://github.com/YaleSTC/reservations/issues/1192)).

### Added
* Added flash error when trying to access non-existent records ([#927](https://github.com/YaleSTC/reservations/issues/927)).
* Added pending reservations table to equipment model view ([#987](https://github.com/YaleSTC/reservations/issues/987)).
* Added table of equipment models to the category show view and improved the equipment model index table for admins ([#1009](https://github.com/YaleSTC/reservations/issues/1009)).
* Added a [guide](https://github.com/YaleSTC/reservations/blob/master/CONTRIBUTING.md) for contributing to Reservations ([#1056](https://github.com/YaleSTC/reservations/issues/1056)).
* Added more information to the EquipmentModel index page for checkout persons ([#1082](https://github.com/YaleSTC/reservations/issues/1082)).
* Allowed switching between password and CAS authentication ([#1106](https://github.com/YaleSTC/reservations/issues/1106)).
* Allowed users to be "remembered" when using password authentication ([#1109](https://github.com/YaleSTC/reservations/issues/1109)).

### Changed
* Added new logo and default favicon ([#194](https://github.com/YaleSTC/reservations/issues/194)).
* Completely overhauled user emails ([#665](https://github.com/YaleSTC/reservations/issues/665), [#938](https://github.com/YaleSTC/reservations/issues/938)).
* Renamed EquipmentObjects to EquipmentItems ([#1081](https://github.com/YaleSTC/reservations/issues/1081)).
* Removed links to EquipmentItems index page because of performance issues ([#1082](https://github.com/YaleSTC/reservations/issues/1082)).
* Removed seed script gems from default group in Gemfile ([#1165](https://github.com/YaleSTC/reservations/issues/1165)).


## v5.1.0 - 2015-02-23
### Fixed
* Calendar views no longer overflow on some browsers ([#846](https://github.com/YaleSTC/reservations/issues/846)).
* Date and time zone handling is now standardized; additionally, reservation start and due dates are now stored as `Date`s rather than as `DateTime`s ([#939](https://github.com/YaleSTC/reservations/issues/939)).
* The handling of missed reservations was improved, and e-mails of missed open requests are no longer sent ([#1031](https://github.com/YaleSTC/reservations/issues/1031)).
* The late checkin e-mail is no longer sent if the late fee due is zero ([#1064](https://github.com/YaleSTC/reservations/issues/1064)).
* The extra 1px at the bottom of the navbar has been removed ([#1111](https://github.com/YaleSTC/reservations/issues/1111)).
* Minor bugs with equipment import were fixed ([#1140](https://github.com/YaleSTC/reservations/issues/1140)).
* Calendar cells can no longer be clicked on, preventing apparently incorrect cart updates ([#1152](https://github.com/YaleSTC/reservations/issues/1152)).

### Added
* Reservations is now set up for Heroku deployment (please see the [Deployment Guide](https://github.com/YaleSTC/reservations/wiki/Heroku-Deployment-Guide) for more information, [#275](https://github.com/YaleSTC/reservations/issues/275)).
* There is now a badge on user profile pages indicating that they have open requests ([#1028](https://github.com/YaleSTC/reservations/issues/1028)).

### Changed
* Bootstrap was updated to v3.3 and the entire UI of the app was overhauled ([#245](https://github.com/YaleSTC/reservations/issues/245)).
* The cart validations code was substantially refactored ([#1097](https://github.com/YaleSTC/reservations/issues/1097)).
* The equipment item link on the reservation page now goes to the equipment item page instead of the equipment model page ([#1159](https://github.com/YaleSTC/reservations/issues/1159)).
* The version of Rails was updated to 4.1.9 ([#600](https://github.com/YaleSTC/reservations/issues/600)).
* All of the dependencies were updated to the latest versions and the Gemfile was cleaned up ([#245](https://github.com/YaleSTC/reservations/issues/245), [#600](https://github.com/YaleSTC/reservations/issues/600)).
* Added a link to the reservation in emails ([#1102](https://github.com/YaleSTC/reservations/issues/1102)).

### Removed
* The `.env` file was removed from the repository; the `.env.example` file may be copied for local use ([#1104](https://github.com/YaleSTC/reservations/issues/1104)).
* The `dynamic_form` gem was removed ([#1110](https://github.com/YaleSTC/reservations/issues/1110)).
* The `yajl-ruby` gem was removed ([#600](https://github.com/YaleSTC/reservations/issues/600)).

## v5.0.0 - 2015-01-12
### Important
*This release fundamentally changes how Reservations is configured (see the ([wiki](https://github.com/YaleSTC/reservations/wiki/Configuration)) for more details). You will likely have to rework how Reservations is deployed and hosted for it to work properly when updating to this version.*

### Fixed
* Two intermittently failing tests have been commented out and a third has been fixed ([#1059](https://github.com/YaleSTC/reservations/issues/1059)).
* Changing the cart dates now updates the catalog availability descriptions ([#1060](https://github.com/YaleSTC/reservations/issues/1060)).

### Added
* Fleshed out and polished guest user functionality ([#175](https://github.com/YaleSTC/reservations/issues/175)).
* Adding or removing an item from the cart now updates the availability count in the catalog ([#718](https://github.com/YaleSTC/reservations/issues/718)).
* Carts are now limited to **100** items to avoid cookie overflow ([#997](https://github.com/YaleSTC/reservations/issues/997)).
* The equipment model page now renders the 'Add to Cart' button differently depending on model status ([#1053](https://github.com/YaleSTC/reservations/issues/1053)).
* Reservation notes now indicate if failed validations were overriden during reservation creation ([#1054](https://github.com/YaleSTC/reservations/issues/1054)).
* Code quality tools (currently [`rubocop`](https://github.com/bbatsov/rubocop) with support for JS linters as well) have been added to the TravisCI build ([#1075](https://github.com/YaleSTC/reservations/issues/1075)).
* The cart is now checked for equipment models that have been destroyed in between requests to avoid rendering issues ([#1085](https://github.com/YaleSTC/reservations/issues/1085)).

### Changed
* Environment variables are now used to configure Reservations. These can be spoofed using the [`dotenv-deployment`](https://github.com/bkeepers/dotenv-deployment) gem if desired ([#683](https://github.com/YaleSTC/reservations/issues/683)).
* The reservations index view has been overhauled and now is date-restricted; this resolves the issue where loading the 'Returned' reservations table would hang the browser on instances with large numbers of reservations ([#708](https://github.com/YaleSTC/reservations/issues/708)).
* The reports code has been completely refactored and heavily improved ([#994](https://github.com/YaleSTC/reservations/issues/994)).
* The seed script has been completely refactored; it now includes several modes of operation and has been heavily optimized ([#629](https://github.com/YaleSTC/reservations/issues/629), [#1071](https://github.com/YaleSTC/reservations/issues/1071)).
* The authorization statements used to restrict equipment activation / deactivation have been rewritten for legibility ([#1019](https://github.com/YaleSTC/reservations/issues/1019)).

### Removed
* The Yale dependencies in the LDAP configuration have been removed to allow for the use of any LDAP server. ([#653](https://github.com/YaleSTC/reservations/issues/653)).
* An unnecessary `before_filter` has been removed from the `ApplicationController` ([#1072](https://github.com/YaleSTC/reservations/issues/1072)).

## v4.1.0 - 2014-12-01
### Added
* Added an "archive" action for reservations to deal with unusual circumstances ([#728](https://github.com/YaleSTC/reservations/issues/728)).
* Added a persistent history for equipment objects / items ([#273](https://github.com/YaleSTC/reservations/issues/273)).
* Authentication is now handled by the [Devise](http://devise.plataformatec.com.br/) gem. Added email/password authentication ([#2](https://github.com/YaleSTC/reservations/issues/2)).
* Equipment switches are now noted in both relevant reservations ([#1022](https://github.com/YaleSTC/reservations/issues/1022)).
* `secrets.yml` is now used for sensitive settings ([#1018](https://github.com/YaleSTC/reservations/issues/1018)).
* There is now a link to Rails Admin in the navbar for superusers ([#965](https://github.com/YaleSTC/reservations/issues/965)).
* The [dotenv](https://github.com/bkeepers/dotenv) gem is now used to spoof environment variables in development ([#694](https://github.com/YaleSTC/reservations/issues/694)).
* Equipment items are now returned before deactivation ([#288](https://github.com/YaleSTC/reservations/issues/288)).
* Admins can now disable user creation by patrons and checkout persons ([#622](https://github.com/YaleSTC/reservations/issues/622)).
* Reservation renewals are now logged in the reservation notes ([#920](https://github.com/YaleSTC/reservations/issues/920)).
* Admins are now warned if deactivating a category or equipment model with current or future reservations (within the next week) ([#1040](https://github.com/YaleSTC/reservations/issues/1040)).
* Deactivating a category or an equipment model will now archive all checked-out reservations with associated equipment items ([#1040](https://github.com/YaleSTC/reservations/issues/1040)).

### Changed
* Deactivating an equipment item now archives relevant reservations if they're currently checked out ([#288](https://github.com/YaleSTC/reservations/issues/288)).
* Reservation notes have been improved and include links for easier history tracking ([#999](https://github.com/YaleSTC/reservations/issues/999), [#1021](https://github.com/YaleSTC/reservations/issues/1021)).
* Rails Admin now has proper authorization ([#973](https://github.com/YaleSTC/reservations/issues/973)).
* `spin.js` has been replaced with a Font Awesome icon for the cart spinner ([#777](https://github.com/YaleSTC/reservations/issues/777)).
* The number of days after which a missed reservation is deleted can now be defined by admins ([#594](https://github.com/YaleSTC/reservations/issues/594)).
* Blackout dates can no longer be created when the due dates of existing reservations would conflict with said blackout date ([#562](https://github.com/YaleSTC/reservations/issues/562)).

### Removed
* Took out the logging functionality of paper_trail in lieu of recently added reservation and equipment history features ([#1033](https://github.com/YaleSTC/reservations/issues/1033)).
* A number of broken links left over from earlier versions were removed ([#957](https://github.com/YaleSTC/reservations/issues/957)).
* The cart was removed from a number of views ([#776](https://github.com/YaleSTC/reservations/issues/776)).


## v4.0.1 - 2014-11-03
### Important
*This release has not been tested under production conditions. We recommend waiting for a release that has undergone more testing.*

### Fixed
* Fixed an issue where links in the request e-mail were broken ([#1017](https://github.com/YaleSTC/reservations/issues/1017)).
* Moved the email link hostname back to the environment files ([#1017](https://github.com/YaleSTC/reservations/issues/1017)).
* Fixed an issue where requiring phone numbers with existing users in the database would cause problems ([#675](https://github.com/YaleSTC/reservations/issues/675), [#1008](https://github.com/YaleSTC/reservations/issues/1008)).
* Fixed an issue where some application options defaulted to `nil` instead of `''` and associated problems ([#947](https://github.com/YaleSTC/reservations/issues/947)).
* Updated `link_to` confirmation syntax for Rails 4 ([#990](https://github.com/YaleSTC/reservations/issues/990)).

### Added
* Added a confirmation dialog when deactivating an item would cause that model to be overbooked within the coming week ([#983](https://github.com/YaleSTC/reservations/issues/983)).

### Changed
* Announcements are now rendered in Markdown so they can include links and formatting ([#1027](https://github.com/YaleSTC/reservations/issues/1027)).
* Majorly refactored the Reservations controller ([#836](https://github.com/YaleSTC/reservations/issues/836), [#882](https://github.com/YaleSTC/reservations/issues/882)).
* Moved the session from the database to a cookie to improve performance ([#880](https://github.com/YaleSTC/reservations/issues/880)).
* Added fallback version number derived from CHANGELOG ([#968](https://github.com/YaleSTC/reservations/issues/968)).
* Added a "Delete" button to the Requirements "show" page ([#803](https://github.com/YaleSTC/reservations/issues/803)).

## v4.0.0 - 2014-10-05
### Important
*This release includes an upgrade to Rails 4 and a large number of other changes; it has not been tested under production conditions. We recommend waiting for a release that has undergone more testing.*

### Fixed
* Fixed CodeClimate testing coverage ([#682](https://github.com/YaleSTC/reservations/issues/682)).
* Fixed unescaped HTML on some views ([#781](https://github.com/YaleSTC/reservations/issues/781), [#860](https://github.com/YaleSTC/reservations/issues/860)).
* Fixed broken migration due to switch to Rails Admin ([#853](https://github.com/YaleSTC/reservations/issues/853), see below).
* The 'superuser' option now appears in the View Mode menu from any view mode when logged in as a superuser ([#976](https://github.com/YaleSTC/reservations/issues/976)).

### Added
* The maximum reservation length is now shown on the equipment model page ([#303](https://github.com/YaleSTC/reservations/issues/303)).
* Users are now notified via e-mail when requests have been processed ([#726](https://github.com/YaleSTC/reservations/issues/726)).
* Reservation notes are now edited in append mode ([#752](https://github.com/YaleSTC/reservations/issues/752)).

### Changed
* Updated to Rails 4.1.4 ([#585](https://github.com/YaleSTC/reservations/issues/585)).
* Switched to Rails Admin from Active Admin ([#691](https://github.com/YaleSTC/reservations/issues/691)).
* Added equipment model-specific validation parameters ([#749](https://github.com/YaleSTC/reservations/issues/749)).
* Reorganized all JavaScript files ([#234](https://github.com/YaleSTC/reservations/issues/234)).
* Added .ruby-version file ([#697](https://github.com/YaleSTC/reservations/issues/697)).
* Added testing coverage for the Reservations controller ([#874](https://github.com/YaleSTC/reservations/issues/874)).
* Added persistent flash for superusers in other view modes ([#974](https://github.com/YaleSTC/reservations/issues/974)).
* Replaced Airbrake with Party Foul ([#501](https://github.com/YaleSTC/reservations/issues/501)).
* The first user is now created as a superuser ([#753](https://github.com/YaleSTC/reservations/issues/753)).

## v3.4.10 - 2015-04-20
### Fixed
* Forgetting to check off the ToS checkbox during checkout no longer causes checkout to fail silently ([#1227](https://github.com/YaleSTC/reservations/issues/1227)).

## v3.4.9 - 2015-03-16
### Fixed
* Banned users can no longer have reservations created for them or equipment checked out to them ([#1185](https://github.com/YaleSTC/reservations/issues/1185)).

## v3.4.8 - 2014-10-26
### Fixed
* Fixed an issue where links in the request e-mail were broken ([#1017](https://github.com/YaleSTC/reservations/issues/1017)).
* Moved the email link hostname back to the environment files ([#1017](https://github.com/YaleSTC/reservations/issues/1017)).

### Changed
* Announcements are now rendered in Markdown so they can include links and formatting ([#1027](https://github.com/YaleSTC/reservations/issues/1027)).

## v3.4.7 - 2014-10-12
### Changed
* Modified `schedule.rb` so that the cron jobs of multiple Reservations instances on the same server don't overload the server.

## v3.4.6 - 2014-10-06
### Fixed
* Improved performance of sending reservations notes emails
* Actually finally resolved the issue where links in e-mails were broken ([#868](https://github.com/YaleSTC/reservations/issues/868)).

## v3.4.5 - 2014-09-22
### Fixed
* Ensured that only reservations with notes or missed procedures were being sent in the notes e-mail ([#948](https://github.com/YaleSTC/reservations/issues/948)).
* Finally resolved the issue where the links in e-mails were broken ([#868](https://github.com/YaleSTC/reservations/issues/868)).
* Fixed an issue where the catalog was showing negative equipment availability ([#982](https://github.com/YaleSTC/reservations/issues/982)).
* Fixed some holes in our admin and default new user permissions ([#966](https://github.com/YaleSTC/reservations/issues/966)).

## v3.4.4 - 2014-09-02
### Added
* An email will now be sent to the administrators when a new request is created ([#943](https://github.com/YaleSTC/reservations/issues/943)).

### Changed
* Made sure that there were no redundant prompts when a custom request prompt was defined ([#940](https://github.com/YaleSTC/reservations/issues/940)).

## v3.4.3 - 2014-08-31
### Fixed
* Fixed typo on the application settings form ([#850](https://github.com/YaleSTC/reservations/issues/850)).
* Fixed an issue where checkout persons could not use autocomplete ([#857](https://github.com/YaleSTC/reservations/issues/857)).
* Fixed an issue where items with unrestricted checkout lengths could not be added to the cart ([#848](https://github.com/YaleSTC/reservations/issues/848)).
* Fixed an issue where the overdue fines sent via e-mail were incorrect ([#876](https://github.com/YaleSTC/reservations/issues/876)).
* Fixed an issue where the calendar availability was incorrect ([#883](https://github.com/YaleSTC/reservations/issues/883)).
* Ensured that the empty cart button completely resets the cart ([#845](https://github.com/YaleSTC/reservations/issues/845)).
* Fixed an issue where all links in e-mails were broken ([#868](https://github.com/YaleSTC/reservations/issues/868)).
* Fixed an issue where the overdue scope was including missed reservations ([#893](https://github.com/YaleSTC/reservations/issues/893)).
* Fixed an issue where the reservation notes e-mails were not being sent ([#906](https://github.com/YaleSTC/reservations/issues/906)).
* Fixed the equipment model change popup to only show when relevant ([#890](https://github.com/YaleSTC/reservations/issues/890)).
* Fixed an issue where the notes field in the check-out form was being populated with prior notes ([#915](https://github.com/YaleSTC/reservations/issues/915)).
* Fixed an issue where the renewal button would be active even when the max renewal length was zero ([#916](https://github.com/YaleSTC/reservations/issues/916)).
* Fixed an issue where the app wasn't properly counting reservations that started on the same day as the cart start date for availability ([#932](https://github.com/YaleSTC/reservations/issues/932)).
* Fixed an issue where renewals were including the start date of any upcoming reservations that required the item ([#932](https://github.com/YaleSTC/reservations/issues/932)).

### Added
* Added equipment import functionality ([#494](https://github.com/YaleSTC/reservations/issues/494)).
* Added an option to disable renewals ([#916](https://github.com/YaleSTC/reservations/issues/916)).
* Added a customizable prompt to the reservation request page ([#746](https://github.com/YaleSTC/reservations/issues/746)).

### Changed
* Made version number visible to all users ([#856](https://github.com/YaleSTC/reservations/issues/856)).
* The request notes are now shown on the request review page ([#901](https://github.com/YaleSTC/reservations/issues/901)).
* Made the search box more noticable ([#293](https://github.com/YaleSTC/reservations/issues/293)).

## v3.4.2 - 2014-07-28
### Fixed
* Added requirements to cart validations to prevent unqualified users from being granted reservations inappropriately ([#763](https://github.com/YaleSTC/reservations/issues/763))
* Tweaked the check-in UI to fix an issue where clicking in the notes field would toggle item selection ([#840](https://github.com/YaleSTC/reservations/issues/840))
* Updated scopes to ensure that reservations could be checked out any time before due date ([#844](https://github.com/YaleSTC/reservations/issues/844))

## v3.4.1 - 2014-07-27
### Changed
* Updated Ruby version to 2.1.2

## v3.4.0 - 2014-07-27
### Fixed
* Fixed failing tests in `user_mailer_spec` ([#643](https://github.com/YaleSTC/reservations/pull/643))
* Ensured that overdue equipment items could not be checked out ([#625](https://github.com/YaleSTC/reservations/pull/625))
* Fixed typo in `ability.rb` ([#649](https://github.com/YaleSTC/reservations/pull/649))
* Ensured that the new cart would not break the app for existing users ([#676](https://github.com/YaleSTC/reservations/pull/676))
* Fix edge case new user creation when :possible_netid is not set ([#732](https://github.com/YaleSTC/reservations/issues/732))
* Prevented infinite redirect loop in edge case when a user tries to log on to the system before the admin has set up the application ([#684](https://github.com/YaleSTC/reservations/issues/684))
* Updating the cart no longer breaks the catalog pagination links
  ([#531](https://github.com/YaleSTC/reservations/issues/531))
* Deleting Blackout Dates now works in all cases ([#808](https://github.com/YaleSTC/reservations/issues/808))
* Checkout persons can no longer see the Import Users button ([#810](https://github.com/YaleSTC/reservations/issues/810))
* Reservations checked in on their due-date are no-longer counted as overdue ([#785](https://github.com/YaleSTC/reservations/issues/785))
* Block patrons from URL-hacking and creating new users ([#823](https://github.com/YaleSTC/reservations/issues/823))
* Fixed a bug wherewith patrons were unable to edit their own profiles ([#830](https://github.com/YaleSTC/reservations/issues/830))
* Fixed broken user form ([#787](https://github.com/YaleSTC/reservations/issues/787))

### Added
* Added benchmarking for speed-testing ([#574](https://github.com/YaleSTC/reservations/pull/574))
* Added version number to footer and app settings page ([#560](https://github.com/YaleSTC/reservations/pull/560))
* Added continuous integration testing w/ [TravisCI](https://travis-ci.org/) ([#641](https://github.com/YaleSTC/reservations/pull/641))
* Added testing coverage w/ [CodeClimate](https://codeclimate.com/) ([#634](https://github.com/YaleSTC/reservations/pull/634))
* Added reservation notes entry for validation-failing requests
  ([#502](https://github.com/YaleSTC/reservations/issues/502))
* Blackouts automatically are removed after an admin-configurable period
  ([#654](https://github.com/YaleSTC/reservations/issues/654), [#242](https://github.com/YaleSTC/reservations/issues/242))
* User deactivation/reactivation has been changed to user ban/unban
  ([#529](https://github.com/YaleSTC/reservations/issues/529))

### Changed
* Completely overhauled cart ([#587](https://github.com/YaleSTC/reservations/pull/587))
* Completely overhauled cart and reservation validations ([#644](https://github.com/YaleSTC/reservations/pull/644), [#343](https://github.com/YaleSTC/reservations/pull/343))
* Refactored the Reservation model ([#614](https://github.com/YaleSTC/reservations/pull/614))
* Greatly improved catalog render times ([#628](https://github.com/YaleSTC/reservations/pull/628))
* Updated `kaminari` gem ([#657](https://github.com/YaleSTC/reservations/pull/657))
* Refactored `UsersController#new` ([#660](https://github.com/YaleSTC/reservations/pull/660))
* Further speed enhancements for the catalog and checkout ([#734](https://github.com/YaleSTC/reservations/issues/734))
* Removed deletion of reservations when deactivating equipment ([#706](https://github.com/YaleSTC/reservations/issues/706))
* Further speed enhancements for the reservation lists page ([#655](https://github.com/YaleSTC/reservations/issues/655))
* Refactor blackout system ([#654](https://github.com/YaleSTC/reservations/issues/654))
* Add full coverage for reservation checkin and checkout ([#679](https://github.com/YaleSTC/reservations/issues/679))
* Autocomplete improvements ([#620](https://github.com/YaleSTC/reservations/issues/620))
    * Clicking a user name in find user suggestions directs
      automatically to the manage reservation page
    * Clearing a reserver name in the cart resets the cart to the
      current user
    * Typing a full name with space doesn't delete the query
* Make everything a lot faster by not counting all users on every
  request ([#759](https://github.com/YaleSTC/reservations/issues/759))
* Refactor checkin and checkout ([#666](https://github.com/YaleSTC/reservations/issues/666))
* Index users table for speed optimization ([#755](https://github.com/YaleSTC/reservations/pull/755))
* Clarified and refactored reservation renewal code ([#674](https://github.com/YaleSTC/reservations/issues/674))
* Restore Checkin box location from the v3.1-era ([#819](https://github.com/YaleSTC/reservations/issues/819))

### Removed
* It's no-longer possible to delete categories, equipment models, or equipment items. Deactivation is now the only method ([#802](https://github.com/YaleSTC/reservations/issues/802))

## v3.3.0 - 2014-07-22
### Important
*Please don't use this version. Use 3.4.x instead: it has undergone more bugtesting.*

### Fixed
* Fixed catalog pagination not working correctly ([#533](https://github.com/YaleSTC/reservations/issues/533))
* Fix bug preventing recurring blackouts not being able to be created if
  they are the first blackout of the application
  ([#589](https://github.com/YaleSTC/reservations/issues/589))
* Fix bug causing reservation validations to check all reservations ever
  made by the user
([#570](https://github.com/YaleSTC/reservations/issues/570))
* Banned users are now actually banned
  ([#564](https://github.com/YaleSTC/reservations/issues/564))
* Can now edit and update equipment models that have no checkin/checkout
  procedures (was crashing application earlier)
([#558](https://github.com/YaleSTC/reservations/issues/558))
* Fixed off-by-one-day error with the blackout dates
  ([#525](https://github.com/YaleSTC/reservations/issues/525))
* Pointed reservation edit cancel to correct view
  ([#316](https://github.com/YaleSTC/reservations/issues/316))

### Added
* Added ability to swap equipment objects for checked out reservations
  ([#536](https://github.com/YaleSTC/reservations/issues/536))
* Added the ability to add a deactivation reason to equipment objects
  ([#332](https://github.com/YaleSTC/reservations/issues/332))
* Added a comprehensive auditing/logging feature
  ([#319](https://github.com/YaleSTC/reservations/issues/319))
* Enabled editing of email field in quick create user modal
  ([#567](https://github.com/YaleSTC/reservations/issues/567))
* Set up ActiveAdmin and added superuser role for easy backup
  administration capabilities
  ([#546](https://github.com/YaleSTC/reservations/issues/546))
* Added overdue-checkin emails to both patron and admin, noting total
  fees ([#317](https://github.com/YaleSTC/reservations/issues/317))
* Reservation Requests, for patrons who would like to request extended
  reservations (or other reservations that otherwise would not be valid)
([#206](https://github.com/YaleSTC/reservations/issues/206))
* Calendar view of available equipment items
  ([#12](https://github.com/YaleSTC/reservations/pull/12))

### Changed
* Added flash to notify admins when viewing Reservations
  as a different user ([#542](https://github.com/YaleSTC/reservations/issues/542))
* Revamped authentication system with CanCan gem
  ([#419](https://github.com/YaleSTC/reservations/issues/419))
* Revamped the check-in UX ([#172](https://github.com/YaleSTC/reservations/issues/172), [#568](https://github.com/YaleSTC/reservations/issues/568))
    * Added ability to click div to select the checkbox
    * Added color cues to indicate selection and overdue status
    * Added overdue glyph
* Upgraded to Ruby v2.1.1 and Rails v3.2.14 ([#535](https://github.com/YaleSTC/reservations/issues/535))
* Added hidden field to datepickers for blackouts and announcements to
  remove unnecessary date parsing
([#580](https://github.com/YaleSTC/reservations/issues/580))
* Improved seed script, adding minimal mode and reducing inconvenience
  ([#578](https://github.com/YaleSTC/reservations/issues/578))
* Updated developer wiki and launched [companion documentation
  site](https://YaleSTC.github.io/reservations)
([#532](https://github.com/YaleSTC/reservations/issues/532))
* Made all emails much more informative and included links to relevant
  pages on Reservations app.
([#519](https://github.com/YaleSTC/reservations/issues/519))
* Refactored update method in ReservationsController
  ([#354](https://github.com/YaleSTC/reservations/issues/354))
* Upgraded to Font-Awesome v4.1.0. ([#616](https://github.com/YaleSTC/reservations/pull/616))
* Vastly-improved rspec testing coverage.

### Removed
* Removed test/unit ([#612](https://github.com/YaleSTC/reservations/issues/612))
  in favor of markèd improvement of rspec coverage
  ([#403](https://github.com/YaleSTC/reservations/issues/403),
  [#404](https://github.com/YaleSTC/reservations/issues/404))

## v3.2.0 - 2014-06-10
### Fixed
* Disabled cart during update and added JS spinner/success flash message to prevent cart changes from not being saved ([#528](https://github.com/YaleSTC/reservations/issues/528))
* Fixed duplicate flash message for blackout dates ([#420](https://github.com/YaleSTC/reservations/issues/420), [#445](https://github.com/YaleSTC/reservations/issues/445))
* Fixed issue where the Users page would display a link when the `nickname` was set to `nil` ([#466](https://github.com/YaleSTC/reservations/issues/466))
* Fixed issue where checkin / checkout steps could not be deleted ([#470](https://github.com/YaleSTC/reservations/issues/470))
* Fixed `database.yml` example for Ubuntu where all databases had the same name ([#472](https://github.com/YaleSTC/reservations/issues/472))
* Fixed test for the cart date where `DateTime.tomorrow` was used instead of `DateTime.now.tomorrow` ([#491](https://github.com/YaleSTC/reservations/issues/491))

### Added
* Added flash for checkout persons when making a reservation for the current day ([#321](https://github.com/YaleSTC/reservations/issues/321))
* Added admin interface for setting up site-wide announcements ([421](https://github.com/YaleSTC/reservations/issues/421), [447](https://github.com/YaleSTC/reservations/issues/447))

### Changed
* Added [Guard](http://guardgem.org/) and [Spork](https://github.com/sporkrb/spork) for faster testing ([#490](https://github.com/YaleSTC/reservations/issues/490))

## v3.1.0.alpha10 - 2014-03-26
### Fixed
* Fix an error that was causing some emails to not send


## v3.1.0.alpha9 - 2014-03-26
### Fixed

* Slow reservation notification emails to send hourly instead of every 5 minutes
* Fix Chrome bug where `remove` button did not render correctly in the cart

## v3.1.0.alpha7 - 2014-02-28
### Bug Fixes
* Changed autocomplete field in cart to display the reserving for user without it disappearing

### Added
* Quick add user from cart by typing their netID and clicking the `+` button
* Reservation note emails are now categorized by checkin and checkout
