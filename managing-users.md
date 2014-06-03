---
layout: admin-page
title: Managing Users
permalink: /user-doc/managing-users/
---

## Preliminaries

Currently, Reservations only supports [CAS](http://www.jasig.org/cas/) for user authentication. Support for built-in authentication and OmniAuth is underway.

*Reservations* maintains a strict separation of user roles. There are three types of users:

* **Normal users**, who can browse the catalog and create reservations for themselves.
* **Checkout Persons** who can do all of the above, plus create reservations for other people and check equipment in and out.
* **Admins**, who can do all of the above. In addition, the can change settings, update equipment, and add/remove users.

## User Creation

When a new user logs in for the first time, an account will automatically be created for them (if using CAS), or they will have to register (when built-in authentication is enabled). As an admin, you can also manually create users.

## User Management

To manage users, click 'Users' in the menu bar. You can add, deactivate, or edit users, as well as view their profile. Profiles give you at-a-glance information about a user, such as what items they've reserved (past, current, and future), and stats on missed and overdue reservations.

## Import CSV
*Reservations* allows you to import a comma-separated list of users. To do so, go to the `Users` screen and click the `Import Users` button.

![image](/reservations/images/user_import_1.png)

You will select what kind of users you are importing; you can even import users to ban. Otherwise, the form provides all the information you will need.

![image](/reservations/images/user_import_2.png)
