# Welcome to Reservations

[![Build Status](https://travis-ci.org/YaleSTC/reservations.svg?branch=development)](https://travis-ci.org/YaleSTC/reservations)
[![Code Climate](https://img.shields.io/codeclimate/github/YaleSTC/reservations.svg)](https://codeclimate.com/github/YaleSTC/reservations)
[![Test Coverage](https://codeclimate.com/github/YaleSTC/reservations/coverage.png)](https://codeclimate.com/github/YaleSTC/reservations)
[![Dependency Status](https://gemnasium.com/YaleSTC/reservations.svg)](https://gemnasium.com/YaleSTC/reservations)
[![Inline docs](http://inch-ci.org/github/yalestc/reservations.svg?branch=development)](http://inch-ci.org/github/yalestc/reservations)

Reservations makes it easy to manage the checking in and out of equipment, much like a library! Here are some of the things Reservations can do:

* manage your inventory of equipment, including storing serial numbers, manuals and other documents, and more.
* present an attractive catalog of equipment, including pictures, so people can browse and search your equipment.
* allow people to reserve equipment in advance, according to rules you set.
* enforce rules on who can reserve what equipment, and for how long.
* manage checking in/out equipment, including unique checklists for each item.

Getting Started
===============

There are two mains steps to setting up Reservations: setting up a deployment server, and installing the Reservations application.

### Prerequisites
You'll need the following to run Reservations:
* [Ruby 2.1](http://www.ruby-lang.org/) and [Rails 3.2](http://rubyonrails.org/)
* a database server ([MySQL](http://www.mysql.com/) or any database supported by Rails)
* [ImageMagick](http://www.imagemagick.org/script/index.php)
* a [CAS](http://www.jasig.org/cas) authentication system

### Installation
First, checkout a copy of Reservations using git:

```
cd /your/code/directory
git clone https://github.com/YaleSTC/reservations.git
cd reservations
```

Reservations uses [Bundler](http://gembundler.com/) to manage dependencies, so if you don't have it, get it, then install dependencies:

```
gem install bundler
bundle install
```

You'll need to edit config/database.yml to point to your database, including the correct username and password. See [Rails Guides](http://guides.rubyonrails.org/configuring.html#configuring-a-database) for common database examples. We package a few example files in the ```config/``` folder for Ubuntu, Fedora, and OS X.

Then, create the database and load the database structure:

```
rake db:create
rake db:schema:load
```

Finally, start the app locally:

```rails server```

Just point your browser to ```localhost:3000``` to use Reservations.

### Deploying to a Server

Reservations is built using [Ruby on Rails](http://rubyonrails.org/), and can be set up (deployed) like most Rails apps. You'll need a server running with the following software:

* [Ruby 2.1](http://www.ruby-lang.org/)
* database server ([MySQL](http://www.mysql.com/) is preferred, but any database supported by Rails should work, including PostgreSQL)
* web server ([apache](http://apache.org/) or [nginx](http://wiki.nginx.org/Main) both work well)
* Rails application server (usually [Passenger Phusion](http://www.modrails.com/) aka mod_rails)

For a general guide to setting up your web and application servers, including hosting providers, see the [Rails Deployment Guide](http://rubyonrails.org/deploy/).

### Config

Reservations is built using the CAS authentication system, using the gem [Ruby-Cas Client](https://github.com/rubycas/rubycas-client).

> To point the gem to the correct CAS server, add the following to your app's `config/environment.rb` (make sure that you put it at the bottom of the file, after the Rails Initializer):
```
CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url => "https://cas.example.foo/"
)
```
(Change the :cas_base_url value to your CAS server's base URL; also note that many CAS servers are configured with a base URL that looks more like “cas.example.foo/cas”.)

Reservations ships with the default config time set to Eastern Time (US and Canada). To change the time, edit `config/application.rb`
`config.time_zone = 'Eastern Time (US & Canada)'`


You will need to also configure the email config in
`config/environments/production.rb`. Replace `example.com` with the
relevant hostname. This will allow links in emails to point to the
correct places.


Further Documentation
==================
* System administrators and end-users may like to review our [help documentation](https://yalestc.github.io/reservations).
* Developers interested in getting involved with *Reservations* can find information on our [project wiki](https://github.com/YaleSTC/reservations/wiki)

Suggestions and Issues
======================

If you have any suggestions, or would like to report an issue, please either:
* Create an issue for [this repository](https://github.com/YaleSTC/reservations/) on Github
* or, if you don't have a GitHub account, use our [issue submission form](https://docs.google.com/a/yale.edu/spreadsheet/viewform?formkey=dE8zTFprNVB4RTAwdURhWEVTTlpDQVE6MQ#gid=0)

