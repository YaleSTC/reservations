# Welcome to Reservations

[![Build Status](https://travis-ci.org/YaleSTC/reservations.svg)](https://travis-ci.org/YaleSTC/reservations)
[![Code Climate](https://codeclimate.com/github/YaleSTC/reservations/badges/gpa.svg)](https://codeclimate.com/github/YaleSTC/reservations)
[![Test Coverage](https://codeclimate.com/github/YaleSTC/reservations/badges/coverage.svg)](https://codeclimate.com/github/YaleSTC/reservations)
[![Dependency Status](https://gemnasium.com/YaleSTC/reservations.svg)](https://gemnasium.com/YaleSTC/reservations)
[![Inline docs](http://inch-ci.org/github/yalestc/reservations.svg)](http://inch-ci.org/github/yalestc/reservations)

![](http://yalestc.github.io/reservations/screenshot.png)

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
* [Ruby 2.1](http://www.ruby-lang.org/)
* [Bundler](http://bundler.io/)
* a database server ([MySQL](http://www.mysql.com/) or any database supported by Rails)
* [ImageMagick](http://www.imagemagick.org/script/index.php)
* [GhostScript](http://www.ghostscript.com/)
* a [CAS](http://www.jasig.org/cas) authentication system (optional)

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

### Configuration
Reservations uses environment variables for configuration (following the principles of the [Twelve-Factor App](http://12factor.net/config)). The gems [`dotenv`](https://github.com/bkeepers/dotenv) and [`dotenv-deployment`](https://github.com/bkeepers/dotenv-deployment) can be used to simulate system environment variables at runtime.

In the `development` and `test` Rails environments, most of the configuration is set in the `config/secrets.yml` file. **IMPORTANT** You should copy the `config/secrets.yml` file and regenerate all of the secret keys / tokens using `rake secret`. You should also copy over the `config/database.yml.example.*` file relevant to your platform and follow the instructions linked to above to set up your database.

In `production`, the `config/database.yml.example.production` should be used as it will refer to the relevant environment variables. Additionally, you must define most of the configuration environment variables listed [here](https://github.com/YaleSTC/reservations/wiki/Configuration) in order for Reservations to work.

#### Authentication
By default, Reservations uses e-mail addresses and passwords to authenticate users. It also supports the CAS authentication system, using the gem [devise_cas_authenticatable](https://github.com/nbudin/devise_cas_authenticatable). If you want to use CAS authentication you must set the `CAS_AUTH` environment variable to some value (see above). Attempting to switch between authentication methods after initial setup is highly discouraged and will likely fail. If this is necessary, you may need to install a fresh copy of the application and manually migrate over user data (see our [wiki](https://github.com/YaleSTC/reservations/wiki/Authentication) for more details).

To point the gem to the correct CAS server in the development and test Rails environments, modify the following setting in your app's `config/secrets.yml` file (see [above](#configuration)):
```yaml
  cas_base_url: https://secure.its.yale.edu/cas/
```
Change the `cas_base_url` parameter to your CAS server's base URL; also note that many CAS servers are configured with a base URL that looks more like “cas.example.com/cas”.

#### Time Zone
Reservations ships with the default config time set to Eastern Time (US and Canada). To change the time, edit `config/application.rb`
`config.time_zone = 'Eastern Time (US & Canada)'`.


Further Documentation
==================
* Administrators and end-users may like to review our [help documentation](https://yalestc.github.io/reservations).
* IT System Administrators and developers interested in deploying or getting involved with *Reservations* can find information on our [project wiki](https://github.com/YaleSTC/reservations/wiki)

Suggestions and Issues
======================

If you have any suggestions, or would like to report an issue, please either:
* Create an issue for [this repository](https://github.com/YaleSTC/reservations/) on Github
* or, if you don't have a GitHub account, use our [issue submission form](https://docs.google.com/a/yale.edu/spreadsheet/viewform?formkey=dE8zTFprNVB4RTAwdURhWEVTTlpDQVE6MQ#gid=0)

