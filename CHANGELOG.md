Change Log
==================

###About this file


* This file will be updated whenever new release put into production
* The release version should be visible from within the application (coming soon)
* Any problems should be reported via the "report an issue" link in the footer of the application instance

###v3.3.0
####Bug Fixes
* Fixed catalog pagination not working correctly ([#533](https://github.com/YaleSTC/reservations/issues/533))
* Fix bug preventing recurring blackouts not being able to be created if
  they are the first blackout of the application
  ([#589](https://github.com/YaleSTC/reservations/issues/589))
* Fix bug causing reservation validations to check all reservations ever
  made by the user
([#583](https://github.com/YaleSTC/reservations/issues/589),
[#570](https://github.com/YaleSTC/reservations/issues/570))
* Banned users are now actually banned
  ([#564](https://github.com/YaleSTC/reservations/issues/564))
* Can now edit and update equipment models that have no checkin/checkout
  procedures (was crashing application earlier)
([#558](https://github.com/YaleSTC/reservations/issues/558))
* Fixed off-by-one-day error with the blackout dates
  ([#525](https://github.com/reservations/issues/525))
* Pointed reservation edit cancel to correct view
  ([#316](https://github.com/YaleSTC/reservation/issues/316))

####New Features
* Added ability to swap equipment objects for checked out reservations
  ([#582](https://github.com/YaleSTC/reservations/issues/582))
* Added the ability to add a deactivation reason to equipment objects
  ([#332](https://github.com/YaleSTC/reservations/issues/332),
[#572](https://github.com/YaleSTC/reservations/issues/572))
* Added a comprehensive auditing/logging feature
  ([#319](https://github.com/YaleSTC/reservations/issues/319),
[#571](https://github.com/YaleSTC/reservations/issues/571))
* Enabled editing of email field in quick create user modal
  ([#567](https://github.com/YaleSTC/reservations/issues/567))
* Set up ActiveAdmin and added superuser role for easy backup
  administration capabilities
  ([#546](https://github.com/YaleSTC/reservations/issues/546))
* Added overdue-checkin emails to both patron and admin, noting total
  fees. ([#317](https://github.com/YaleSTC/reservations/issues/317))
* Reservation Requests, for patrons who would like to request extended
  reservations (or other reservations that otherwise would not be valid)
([#206](https://github.com/YaleSTC/reservations/issues/206))
* Calendar view of available equipment items
  ([#12](https://github.com/YaleSTC/reservations/pull/12))

####Enhancements
* Added flash to notify admins/checkout-persons when viewing Reservations 
  as a different user ([#542](https://github.com/YaleSTC/reservations/issues/542))
* Revamped authentication system with CanCan gem
  ([#419](https://github.com/YaleSTC/reservations/issues/535))
* Revamped the check-in UX ([#172](https://github.com/YaleSTC/reservations/issues/172),[#568](https://github.com/YaleSTC/reservations/issues/568))
	* Added ability to click div to select the checkbox
	* Added color cues to indicate selection and overdue status
	* Added overdue glyph
* Upgraded to Ruby v2.1.1 and Rails v3.2.14 ([#535](https://github.com/YaleSTC/reservations/issues/535))
* Added hidden field to datepickers for blackouts and announcements to
  remove unnecessary date parsing
([#580](https://github.com/YaleSTC/reservations/issues/535))
* Improved seed script, adding minimal mode and reducing inconvenience
  ([#578](https://github.com/YaleSTC/reducing/issues/578))
* Updated developer wiki and launched [companion documentation
  site](https://YaleSTC.github.io/reservations)
([#532](https://github.com/YaleSTC/reservations/issues/532))
* Made all emails much more informative and included links to relevant
  pages on Reservations app.
([#519](https://github.com/YaleSTC/Reservations/519))
* Refactored update method in ReservationsController
  ([#354](https://github.com/YaleSTC/ReservationsController/issues/354))
* Upgraded to Font-Awesome v4.1.0. ([#616](https://github.com/YaleSTC/reservations/pull/616))
* Vastly-improved rspec testing coverage.

####Deprecations
* Removed test/unit ([#612](https://github.com/YaleSTC/reservations/issues/612)) 
  in favor of markèd improvement of rspec coverage 
  ([#403](https://github.com/YaleSTC/reservations/issues/403),
  [#404](https://github.com/YaleSTC/reservations/issues/404),
  [#584](https://github.com/YaleSTC/reservations/issues/584))

###v3.2.0

####New Features
* Added flash for checkout persons when making a reservation for the current day ([#321](https://github.com/YaleSTC/reservations/issues/321))
* Added admin interface for setting up site-wide announcements ([421](https://github.com/YaleSTC/reservations/issues/421), [447](https://github.com/YaleSTC/reservations/issues/447))

####Enhancements
* Added [Guard](http://guardgem.org/) and [Spork](https://github.com/sporkrb/spork) for faster testing ([#490](https://github.com/YaleSTC/reservations/issues/490))

####Bug Fixes
* Disabled cart during update and added JS spinner/success flash message to prevent cart changes from not being saved ([#528](https://github.com/YaleSTC/reservations/issues/528))
* Fixed duplicate flash message for blackout dates ([#420](https://github.com/YaleSTC/reservations/issues/420), [#445](https://github.com/YaleSTC/reservations/issues/445))
* Fixed issue where the Users page would display a link when the `nickname` was set to `nil` ([#466](https://github.com/YaleSTC/reservations/issues/466))
* Fixed issue where checkin / checkout steps could not be deleted ([#470](https://github.com/YaleSTC/reservations/issues/470))
* Fixed `database.yml` example for Ubuntu where all databases had the same name ([#472](https://github.com/YaleSTC/reservations/issues/472))
* Fixed test for the cart date where `DateTime.tomorrow` was used instead of `DateTime.now.tomorrow` ([#491](https://github.com/YaleSTC/reservations/issues/491))


###v3.1.0.alpha10
####Bug Fixes

* Fix an error that was causing some emails to not send


###v3.1.0.alpha9
####Bug Fixes

* Slow reservation notification emails to send hourly instead of every 5 minutes
* Fix Chrome bug where `remove` button did not render correctly in the cart


###v3.1.0.alpha8
Accidentally the same as v3.1.0.alpha7

###v3.1.0.alpha7

####New Features

* Quick add user from cart by typing their netID and clicking the `+` button
* Reservation note emails are now categorized by checkin and checkout

####Bug Fixes

* Changed autocomplete field in cart to display the reserving for user without it disappearing
