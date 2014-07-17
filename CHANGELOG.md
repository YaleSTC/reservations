Changelog
==================

### About this file
* This file will be updated whenever new release put into production.
* The release version should be visible from within the application (coming soon).
* Any problems should be reported via the "report an issue" link in the footer of the application instance.

### v3.4.0
#### Bug Fixes
* Fixed failing tests in `user_mailer_spec` ([#643](https://github.com/YaleSTC/reservations/pull/643))
* Ensured that overdue equipment items could not be checked out ([#625](https://github.com/YaleSTC/reservations/pull/625))
* Fixed typo in `ability.rb` ([#649](https://github.com/YaleSTC/reservations/pull/649))
* Ensured that the new cart would not break the app for existing users ([#676](https://github.com/YaleSTC/reservations/pull/676))
* Fix edge case new user creation when :possible_netid is not set ([#732](https://github.com/YaleSTC/reservations/issues/732)).
* Prevented infinite redirect loop in edge case when a user tries to log on to the system before the admin has set up the application ([#684](https://github.com/YaleSTC/reservations/issues/684)).

#### New Features
* Added benchmarking for speed-testing ([#574](https://github.com/YaleSTC/reservations/pull/574))
* Added version number to footer and app settings page ([#560](https://github.com/YaleSTC/reservations/pull/560))
* Added continuous integration testing w/ [TravisCI](https://travis-ci.org/) ([#641](https://github.com/YaleSTC/reservations/pull/641))
* Added testing coverage w/ [CodeClimate](https://codeclimate.com/) ([#634](https://github.com/YaleSTC/reservations/pull/634))

#### Enhancements
* Completely overhauled cart ([#587](https://github.com/YaleSTC/reservations/pull/587), [#])
* Completely overhauled cart and reservation validations ([#644](https://github.com/YaleSTC/reservations/pull/644), [#343](https://github.com/YaleSTC/reservations/pull/343))
* Refactored the Reservation model ([#614](https://github.com/YaleSTC/reservations/pull/614))
* Greatly improved catalog render times ([#628](https://github.com/YaleSTC/reservations/pull/628))
* Updated `kaminari` gem ([#657](https://github.com/YaleSTC/reservations/pull/657))
* Refactored `UsersController#new` ([#660](https://github.com/YaleSTC/reservations/pull/660))
* Further speed enhancements for the catalog and checkout ([#734](https://github.com/YaleSTC/reservations/issues/734)).

###v3.3.0
####Bug Fixes
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

####New Features
* Added ability to swap equipment objects for checked out reservations
  ([#536](https://github.com/YaleSTC/reservations/issues/536))
* Added the ability to add a deactivation reason to equipment objects
  ([#332](https://github.com/YaleSTC/reservations/issues/332)
* Added a comprehensive auditing/logging feature
  ([#319](https://github.com/YaleSTC/reservations/issues/319)
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

####Enhancements
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

####Deprecations
* Removed test/unit ([#612](https://github.com/YaleSTC/reservations/issues/612))
  in favor of markèd improvement of rspec coverage
  ([#403](https://github.com/YaleSTC/reservations/issues/403),
  [#404](https://github.com/YaleSTC/reservations/issues/404))

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
