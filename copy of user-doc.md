---
layout: page
title: User Documentation
permalink: /user-doc/
---

<ul>
{% for page in site.pages %}
  {% if page.layout == 'user-page' %}  
    <li><a href="/reservations{{ page.url }}">{{ page.title }}</a></li>
  {% endif %}
{% endfor %}
</ul>
