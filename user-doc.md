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
* [Managing Users](/reservations/user-doc/managing-users/)
* Managing Announcements
* [Managing Blackouts](/reservations/user-doc/blackouts/)
* [Managing Emails](/reservations/user-doc/emails/)
* [Usage Reports](/reservations/user-doc/reports/)

If you're an employee that oversees Reservation checkins and checkouts, you're a Checkout Person. You might want to read more about:

<ul>
{% for page in site.pages %}
  {% if page.layout == 'cp-page' %}  
    <li><a href="{{ page.url | prepend: site.baseurl }}">{{ page.title }}</a></li>
  {% endif %}
{% endfor %}
</ul>

If you're using Reservations to occasionally check items out, you're a Patron. You might want to read more about:

<ul>
{% for page in site.pages %}
  {% if page.layout == 'user-page' %}  
    <li><a href="{{ page.url | prepend: site.baseurl }}">{{ page.title }}</a></li>
  {% endif %}
{% endfor %}
</ul>
