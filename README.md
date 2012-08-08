Welcome to Reservations [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/YaleSTC/reservations)
=======================

Reservations makes it easy to manage the checking in and out of equipment, much like a library! Here are some of the things Reservations can do:

* Manage your inventory of equipment, including storing serial number, manuals and other documents, and more.
* Present an attractive catalog of equipment, inclduing pictures, so people can browse and search your equipment.
* Allow people to reserve equipment in advance, according to rules you set.
* Enforce rules on who can reserve equipment, and for how long.
* Manage checking in/out equipment, including unique checklists for each item.

Getting Started
===============

There are two mains steps to setting up Reservations, setting up a deployment server, and installing the Reservations application.

Installing Reservations locally
-------------------------------

###Prerequisites
You'll need the following to run Reservations:
* [Ruby 1.9](http://www.ruby-lang.org/), with Bundler
* a database server ([Sqlite](http://www.sqlite.org/), [MySQL](http://www.mysql.com/) or any database supported by Rails)
* [ImageMagick](http://www.imagemagick.org/script/index.php)

###Installing 
First, checkout a copy of Reservations using git:

```
cd /your/code/directory
git clone https://github.com/YaleSTC/reservations.git
cd reservations
```

Rerservations uses [Bundler](http://gembundler.com/) to manage dependencies, so if you don't have it, get it, then install dependencies

```
gem install bundler
bundle install
```


You'll need to edit config/database.yml to point to your database, including the correct user and password. See the [Rails guide](http://guides.rubyonrails.org/getting_started.html#configuring-a-database) for common database examples.

Then, create the database and run migrations to build the structure:

```
rake db:create
rake db:migrate
```

Finally, start the app locally:

```rails server```

Just point your browser to ```localhost:3000``` to use Reservations.

Deploying to a Server
---------------------

Reservations is built using [Ruby on Rails](http://rubyonrails.org/), and can be set up (deployed) like most Rails apps. You'll need a server running with the following software:

* [Ruby 1.9](http://www.ruby-lang.org/)
* database server ([MySQL](http://www.mysql.com/) is preferred, but any database supported by Rails should work, including PostgreSQL)
* web server ([apache](http://apache.org/) or [nginx](http://wiki.nginx.org/Main) both work well) 
* Rails application server (usually [Passenger Phusion](http://www.modrails.com/) aka mod_rails)

For a general guide to setting up your web and application servers, including hosting providers, see the [Rails Deployment Guide](http://rubyonrails.org/deploy/).

Using Reservations
==================

Initial Setup
-------------

The first time you run the app, you'll be guided through creating your Admin account (you can add more later) and setting up things like the site title, contact address, and so on. Once you're done, it's time to add items to the catalog!

Managing Equipment
------------------

Reservations organizes your equipment on three levels, Categories, Equipment Models and Equipment Items. 

Categories provide organization to your catalog, making it easy for people to find what they need. Examples might be "Video Cameras", "Digital SLRs", or "Laptops".

Equipment Models represent a general model of equipment, such as a Nikon D90. Equipment Models contain a name and general description, as well as a photo for the catalog. You can also upload documents related to an Equipment Model (such as for a user's guide PDF), and set limits on the lenght of time and number a person can checkout.

Equipment Items represent real, physical copies of an Equipment Model. These are used to determine how many are available for checkout on the catalog, and Reservations tracks them by identifiers you specify so you know who checked out a specific item. You can also store item-level information on Equipment Items such as serial numbers.

To get started, you'll need to create your first category by choosing Equipment -> Categories from the menu bar at the top. When you're creating a category, you'll see a lot of options for things like how many a person can check out at a time. These are used as the default for all Equipment Models in this category, but can be over-ridden for a specific model when you create it.

Once you've added your first Category, create your first Equipment Model by clicking the 'Add Model' button on the category page and entering the details. Finally, create at least one new Equipment Item for that model by clicking the 'Create New Item' button on the Equipment Model page.

Managing Users
--------------

Currently, Reservations only supports [CAS](http://www.jasig.org/cas/), but we are working on adding built-in authentication so anyone can use it.

When a new user logs in for the first time, an account will automatically be created for them (if using CAS), or they will have to register (when built-in authentication is enabled). As an admin, you can also manually create users.

To manage users, click 'Users' in the menu bar. You can add, deactivate, or edit users, as well as view their profile. Profiles give you at-a-glance information about a user, such as what items they've reserved (past, current, and future), and stats on missed and overdue reservations.

There are three types of users:
* *Normal users*, who can browse the catalog and create reservations for themselves.
* *Checkout Persons* who can do all of the above, plus create reservations for other people and check equipment in and out.
* *Admins*, who can do all of the aboe, plus change settings, update equipment, and add/deactive users.

Reservations
------------

###Creating Reservations
Users can easily reserve equipement on their own, through the catalog. To do so, set the desired start and end dates, check availability on the catalog (updated automatically), and add itmes to your cart. Once you'veve added all items you'd like to reserve, click the 'finalize reservation' button, which confirms the reservation is valid (doesn't violate any limitations on reservation length, number, etc.) and then approves it.

Admins and Checkout Persons can create reservations for other users, and in some cases, override restrictions on length and number of items in the reservation.

###Checking in/out
To check equipment in or out, an Admin or Checkout Person can simply enter a persons name or login into the 'Find User' search box.

(Temporarily disabled in version 3.0) Reservations supports sending emails automatically to users when reservations are upcoming, missed, and due or overdue to be returned.

###Requirements
You can optionally create requirements, which are essentially qualifications. This allows you to require that a person be tagged as meeting that requirement before reserving an Equipment Model. 

For example, you might offer saftey training to checkout light kits. In this case, you could create a requirement for 'Light Kit Training', and add that requirement to all your Light Kit Equipment Models. Before a user can reserve a light kit, an admin must add the 'Light Kit Training' qualification to that user's account.

###Blackout Dates
There are two types of blackout dates:

*Blackout* - If you're closed on a certain date, you can add a blackout date to prevent users from creating a reservation that starts or ends on that date (though it may still span that date).
*Notice* - This is useful if you close earlier than normal on a date. Any user creatign a reservation starting or ending on that date will be presented with the the notice you provide.

Suggestions and Issues
======================

If you have any suggestions, or would like to report an issue, please either:
* Create an issue for [this repository](https://github.com/YaleSTC/reservations/) on Github 
* or, if you don't have a GitHub account, use our [issue submission form](https://docs.google.com/a/yale.edu/spreadsheet/viewform?formkey=dE8zTFprNVB4RTAwdURhWEVTTlpDQVE6MQ#gid=0)

