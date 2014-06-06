---
layout: page
title: Features
permalink: /features/
---

## Application Setup

*Reservations* provides a standard set-up for a server-side application. [Learn how to do it &rarr;](/reservations/user-doc/setting-up-reservations/)

## Equipment Organization

Reservations organizes your equipment on three levels: Categories, Equipment Models, and Equipment Items.

**Categories** provide organization to your catalog, making it easy for people to find what they need. Your categories might be "Video Cameras", "Digital SLRs", and "Laptops".

**Equipment Models** represent a more-specific type of equipment, such as a Nikon D90. Equipment Models have a name and general description, as well as a photo for the catalog. You can also upload documents related to an Equipment Model (e.g. a user's guide) and set limits on the length of time and number of items a person can check out of this model.

**Equipment Items** represent real, physical instances of an Equipment Model. These are used to determine how many are available for checkout on the catalog. Reservations tracks them by identifiers, so that you know who checked out a specific item. You can also store item-level information on Equipment Items, such as serial numbers.

## Managing Users

Currently, *Reservations* only supports [CAS](http://www.jasig.org/cas/) for user authentication. Support for built-in authentication and OmniAuth is under development.

*Reservations* maintains a strict separation of user roles. There are three types of users:

* **Normal users**, who can browse the catalog and create reservations for themselves.
* **Checkout Persons** who can do all of the above, plus create reservations for other people and check equipment in and out.
* **Admins**, who can do all of the above. In addition, they can change settings, update equipment, and add/remove users.

## Announcements

Administrators can set up announcements for different contexts and audiences.

## Reservations

### Creating Reservations

Users can easily reserve equipment through the catalog. They can use the Cart to collect items they want to check out.

Additionally, Admins and Checkout Persons can create reservations for other users and, if necessary, override restrictions on length and number of items in the reservation.

### Checking in/out
*Reservations* tracks whether reservations are upcoming, missed, and due or overdue to be returned. Reservations supports sending emails automatically to users when their reservations reach a pre-defined stage.

To confirm equipment checkin or checkout, an Admin or Checkout Person can simply enter a patron's name/identifier into the 'Find User' search box and resolve their reservations.

### Requirements

You can require that a patron be tagged as meeting a given requirement before they can reserve a specific Equipment Model.

For example, you might offer safety training to check out light kits. In this case, you could create a requirement for 'Light Kit Training', and add that requirement to all your Light Kit Equipment Models. Before a user can reserve a light kit, an admin must add the 'Light Kit Training' qualification to that user's account.

### Blackout Dates

Blackout Dates allow you to specify dates during which users' reservations cannot begin or end, although they can still span said dates. This is useful if your office is closed on certain days, such as weekends or holidays.

*Reservations* implements two types of blackout dates:

* **Recurring blackouts** automatically renew themselves after a set period of time. They are useful, for example, if your office closes for weekends.
* **One-time blackouts** are set for a specific date. They are useful, for example, for holidays such as Memorial Day.

