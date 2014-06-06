---
layout: page
title: Documentation
permalink: /user-doc/
---
What you want on this page depends on your role within the *Reservations* application.

## Admin

If you are an Admin, you might want to read more about:

* [Setting up the *Reservations* application](/reservations/user-doc/setting-up-reservations/)
* [Managing App Configuration](/reservations/user-doc/managing-app-config/)
* [Managing Categories, Equipment Models and Equipment Items](/reservations/user-doc/managing-equipment/)
* [Managing Requirements](reservations/user-doc/managing-requirements/)
* [Managing Users](/reservations/user-doc/managing-users/)
* [Managing Blackouts](/reservations/user-doc/blackouts/)
* [Managing Emails](/reservations/user-doc/emails/)
* [Usage Reports](/reservations/user-doc/reports/)
* [Managing Announcements](/reservations/user-doc/announcements/)

## Checkout Person

If you're an employee who oversees Reservation checkins and checkouts, you're a Checkout Person. You might want to read more about:

<ul>
{% for page in site.pages %}
  {% if page.layout == 'cp-page' %}  
    <li><a href="{{ page.url | prepend: site.baseurl }}">{{ page.title }}</a></li>
  {% endif %}
{% endfor %}
</ul>

## Patron

If you're using Reservations to occasionally check items out, you're a Patron. You might want to read more about:

<ul>
{% for page in site.pages %}
  {% if page.layout == 'user-page' %}  
    <li><a href="{{ page.url | prepend: site.baseurl }}">{{ page.title }}</a></li>
  {% endif %}
{% endfor %}
</ul>

If you can't find an answer to your question in this documentation, please [report the issue](https://docs.google.com/a/yale.edu/spreadsheet/viewform?formkey=dE8zTFprNVB4RTAwdURhWEVTTlpDQVE6MQ#gid=0) to us!
