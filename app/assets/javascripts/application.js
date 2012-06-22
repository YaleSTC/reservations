// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require dataTables/jquery.dataTables
//= require dataTables_numhtml_sort.js
//= require dataTables_numhtml_detect.js
//= require_self
//= require_tree .
//= require cocoon
//= require autocomplete-rails

/* quicksearch is gone
$(document).ready(function() {
   $('.toggleLink').click(function() {
     $('#quicksearch_hidden').toggle('slow', function() {
       // Animation complete.
     });
   });
 });
*/

$(document).ready(function() {
  $('#table_woo').dataTable()
});

$.datepicker.setDefaults({
   minDate: new Date(),
   prevText: '' });
