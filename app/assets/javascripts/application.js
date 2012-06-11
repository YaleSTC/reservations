// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//= require jquery
//= require jquery_ujs
//= require_self
//= require_tree .

$(document).ready(function() {
   $('.toggleLink').click(function() {
     $('#quicksearch_hidden').toggle('slow', function() {
       // Animation complete.
     });
   });
 });
