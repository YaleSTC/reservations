---
layout: page
title: Features
permalink: /features/
---
**Reservations** is *the* app to use for keeping track of item loans! Whether you're an office loaning out work laptops, a library loaning out photography equipment, or a department loaning out various other things, **Reservations** makes your life easier, because it:

* Manages your inventory of equipment, including storing serial number, manuals and other documents, and more.
* Presents an attractive catalog of equipment, including pictures, so people can browse and search your equipment.
* Allows people to reserve equipment in advance, according to the rules you set.
* Enforces rules on who can reserve equipment, and for how long.
* Manages checking equipment in and out, including a requirement checklists for each item.

## Specific Overview
### Application Setup
*Reservations* provides an easy set-up.

### Managing Equipment

#### Terminology

Reservations organizes your equipment on three levels: Categories, Equipment Models, and Equipment Items.

**Categories** provide organization to your catalog, making it easy for people to find what they need. Your categories might be "Video Cameras", "Digital SLRs", and "Laptops".

**Equipment Models** represent a general type of equipment, such as a Nikon D90. Equipment Models have a name and general description, as well as a photo for the catalog. You can also upload documents related to an Equipment Model (e.g. a user's guide) and set limits on the lenght of time and number a person can check out the instances of this model.

**Equipment Items** represent real, physical instances of an Equipment Model. These are used to determine how many are available for checkout on the catalog. Reservations tracks them by identifiers, so that you know who checked out a specific item. You can also store item-level information on Equipment Items, such as serial numbers.

#### Management

To get started, you will create your first category by choosing `Equipment -> Categories` from the top menu bar. When creating a category, Reservations provides options for things like how many a person can check out at a time. These are used as the default for all Equipment Models in this category, but can be over-ridden for a specific model when you create it.

Once you've added your first Category, create your first Equipment Model by clicking the 'Add Model' button on the category page and entering the details. Finally, create at least an Equipment Item for that model by clicking the 'Create New Item' button on the Equipment Model page.

*Reservations* includes

### Managing Users

Currently, Reservations only supports [CAS](http://www.jasig.org/cas/) for user authentication, but we are working on adding built-in authentication so anyone can use it.

When a new user logs in for the first time, an account will automatically be created for them (if using CAS), or they will have to register (when built-in authentication is enabled). As an admin, you can also manually create users.

To manage users, click 'Users' in the menu bar. You can add, deactivate, or edit users, as well as view their profile. Profiles give you at-a-glance information about a user, such as what items they've reserved (past, current, and future), and stats on missed and overdue reservations.

There are three types of users:

* **Normal users**, who can browse the catalog and create reservations for themselves.
* **Checkout Persons** who can do all of the above, plus create reservations for other people and check equipment in and out.
* **Admins**, who can do all of the above. In addition, the can change settings, update equipment, and add/remove users.

*Reservations* maintains a strict separation of roles.


### Reservations

#### Creating Reservations
Users can easily reserve equipement on their own, through the catalog. To do so, set the desired start and end dates, check availability on the catalog (updated automatically), and add itmes to your cart. Once you'veve added all items you'd like to reserve, click the 'finalize reservation' button, which confirms the reservation is valid (doesn't violate any limitations on reservation length, number, etc.) and then approves it.

(Users use the Cart to collect items they want to check out.)

Admins and Checkout Persons can create reservations for other users, and in some cases, override restrictions on length and number of items in the reservation.

#### Checking in/out
To check equipment in or out, an Admin or Checkout Person can simply enter a persons name or login into the 'Find User' search box.

*Reservations* tracks whether reservations are upcoming, missed, and due or overdue to be returned.

*(Temporarily disabled in version 3.0)* ~~Reservations supports sending emails automatically to users when their reservations reach a pre-defined stage.~~

#### Requirements
Requirements are optional; they are, in other words, qualifications. You can require that a person be tagged as meeting a given requirement before reserving a specific Equipment Model.

For example, you might offer safety training to check out light kits. In this case, you could create a requirement for 'Light Kit Training', and add that requirement to all your Light Kit Equipment Models. Before a user can reserve a light kit, an admin must add the 'Light Kit Training' qualification to that user's account.

#### Blackout Dates
Blackout Dates allow you to specify dates during which users' reservations cannot begin or end, although they can still span said dates. This is useful if your office is closed on some days.

There are two types of blackout dates:

* **Recurring blackouts** automatically renew themselves after a set period of time. They are useful, for example, if your office closes for weekends.
* **One-time blackouts** are set for a specific date. They are useful, for example, for holidays such as the Memorial Day.

### Announcements
Users can set up announcements for different contexts.

