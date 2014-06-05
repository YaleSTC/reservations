Change Log
==================

###About this file


* This file will be updated whenever new release put into production
* The release version should be visible from within the application (coming soon)
* Any problems should be reported via the "report an issue" link in the footer of the application instance


###v3.2.0
####Bug Fixes

* Disabled cart during update and added JS spinner/success flash message to prevent cart changes from not being saved ([#528](https://github.com/YaleSTC/reservations/issues/528))


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
