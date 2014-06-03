---
layout: page
title: User Documentation
permalink: /user-doc/
---

{% comment %} TODO: Implement an automatic generator later with solution like http://stackoverflow.com/questions/9110803/make-custom-page-based-loop-in-jekyll {% endcomment %}

{% for page in site.pages %}
  {% if page.layout == 'user-page' %}  
    <h3><a href="{{ page.url }}">{{ page.title }}</a></h3>
  {% endif %}
{% endfor %}
