---
layout: page
title: Documentation
permalink: /user-doc/
---
What you want on this page depends on your role within the *Reservations* application.

If you are an Admin, you might want to read more about:

* Setting up the *Reservations* application
* Managing App Configuration
* [Managing Categories, Equipment Models and Equipment Items](/reservations/user-doc/managing-equipment/)
* Managing Requirements
* Managing Users
* Managing Announcements
* Managing Blackouts
* Managing Emails
* and Usage Reports.

If you're an employee that oversees Reservation checkins and checkouts, you're a Checkout Person. You might want to read more about:

<ul>
{% for page in site.pages %}
  {% if page.layout == 'cp-page' %}  
    <li><a href="{{ page.url | prepend: site.baseurl }}">{{ page.title }}</a></li>
  {% endif %}
{% endfor %}
</ul>

* Checking In Equipment
* Checking Out Equipment

If you're using Reservations to occasionally check items out, you're a Patron. You might want to read more about:

<ul>
{% for page in site.pages %}
  {% if page.layout == 'user-page' %}  
    <li><a href="{{ page.url | prepend: site.baseurl }}">{{ page.title }}</a></li>
  {% endif %}
{% endfor %}
</ul>
* Terms of Service
