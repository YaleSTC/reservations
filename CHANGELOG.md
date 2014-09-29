Changelog
==================

### About this file
* This file will be updated whenever a new release is put into production.
* Any problems should be reported via the "report an issue" link in the footer of the application.

### v4.0.0
*Released on 5 October 2014*
#### Bug Fixes
* Fixed CodeClimate testing coverage ([#682](https://github.com/YaleSTC/reservations/issues/682)).
* Fixed unescaped HTML on some views ([#860](https://github.com/YaleSTC/reservations/issues/860)).
* Fixed broken migration due to switch to Rails Admin ([#853](https://github.com/YaleSTC/reservations/issues/853), see below).
* The 'superuser' option now appears in the View Mode menu from any view mode when logged in as a superuser ([#976](https://github.com/YaleSTC/reservations/issues/976)).

#### New Features
* Updated to Rails 4.1.4 ([#585](https://github.com/YaleSTC/reservations/issues/585)).
* The maximum reservation length is now shown on the equipment model page ([#303](https://github.com/YaleSTC/reservations/issues/303)).
* Users are now notified via e-mail when requests have been processed ([#726](https://github.com/YaleSTC/reservations/issues/726)).
* Reservation notes are now edited in append mode ([#752](https://github.com/YaleSTC/reservations/issues/752)).

#### Enhancements
* Switched to Rails Admin from Active Admin ([#691](https://github.com/YaleSTC/reservations/issues/691)).
* Added equipment model-specific validation parameters ([#749](https://github.com/YaleSTC/reservations/issues/749)).
* Reorganized all JavaScript files ([#234](https://github.com/YaleSTC/reservations/issues/234)).
* Added .ruby-version file ([#697](https://github.com/YaleSTC/reservations/issues/697)).
* Added testing coverage for the Reservations controller ([#874](https://github.com/YaleSTC/reservations/issues/874)).
* Added persistent flash for superusers in other view modes ([#974](https://github.com/YaleSTC/reservations/issues/974)).
* Replaced Airbrake with Party Foul ([#501](https://github.com/YaleSTC/reservations/issues/501)).
* The first user is now created as a superuser ([#753](https://github.com/YaleSTC/reservations/issues/753)).

### v3.4.5
*Released on 22 September 2014*
#### Bug Fixes
* Ensured that only reservations with notes or missed procedures were being sent in the notes e-mail ([#948](https://github.com/YaleSTC/reservations/issues/948)).
* Finally resolved the issue where the links in e-mails were broken ([#868](https://github.com/YaleSTC/reservations/issues/868)).
* Fixed an issue where the catalog was showing negative equipment availability ([#982](https://github.com/YaleSTC/reservations/issues/982)).
* Fixed some holes in our admin and default new user permissions ([#966](https://github.com/YaleSTC/reservations/issues/966)).

### v3.4.4
*Released on 2 September 2014*
#### New Features
* An email will now be sent to the administrators when a new request is created ([#943](https://github.com/YaleSTC/reservations/issues/943)).

#### Enhancements
* Made sure that there were no redundant prompts when a custom request prompt was defined ([#940](https://github.com/YaleSTC/reservations/issues/940)).

### v3.4.3
#### Bug Fixes
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

#### New Features
* Added equipment import functionality ([#494](https://github.com/YaleSTC/reservations/issues/494)).
* Added an option to disable renewals ([#916](https://github.com/YaleSTC/reservations/issues/916)).
* Added a customizable prompt to the reservation request page ([#746](https://github.com/YaleSTC/reservations/issues/746)).

#### Enhancements
* Made version number visible to all users ([#856](https://github.com/YaleSTC/reservations/issues/856)).
* The request notes are now shown on the request review page ([#901](https://github.com/YaleSTC/reservations/issues/901)).
* Made the search box more noticable ([#293](https://github.com/YaleSTC/reservations/issues/293)).

### v3.4.2
*Released on 28 July 2014*
#### Bug Fixes
* Added requirements to cart validations to prevent unqualified users from being granted reservations inappropriately ([#763](https://github.com/YaleSTC/reservations/issues/763))
* Tweaked the check-in UI to fix an issue where clicking in the notes field would toggle item selection ([#840](https://github.com/YaleSTC/reservations/issues/840))
* Updated scopes to ensure that reservations could be checked out any time before due date ([#844](https://github.com/YaleSTC/reservations/issues/844))

### v3.4.1
#### Enhancements
* Updated Ruby version to 2.1.2

### v3.4.0
#### Bug Fixes
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

#### New Features
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

#### Enhancements
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

#### Deprecations
* It's no-longer possible to delete categories, equipment models, or equipment items. Deactivation is now the only method ([#802](https://github.com/YaleSTC/reservations/issues/802))

###v3.3.0
*Please don't use this version. Use 3.4.x instead: it has undergone more bugtesting.*
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
