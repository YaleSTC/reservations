Change Log
==================

###About this file


* This file will be updated whenever new release put into production
* The release version should be visible from within the application (coming soon)
* Any problems should be reported via the "report an issue" link in the footer of the application instance

###v3.3.0
####Bug Fixes
* Fixed catalog pagination not working correctly ([#533](https://github.com/YaleSTC/reservations/issues/533))

####New Features
* Added flash to notify admins/checkout-persons when viewing Reservations as a different user ([#542]((https://github.com/YaleSTC/reservations/issues/542))

* Revamped the check-in UX ([#172](https://github.com/YaleSTC/reservations/issues/172))
	* Added ability to click div to select the checkbox
	* Added color cues to indicate selection and overdue status
	* Added overdue glyph
	
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
