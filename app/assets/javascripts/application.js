// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require dataTables/jquery.dataTables
//= require_self
//= require_tree .
//= require cocoon
//= require autocomplete-rails


$(document).ready(function() {
   $('.toggleLink').click(function() {
     $('#quicksearch_hidden').toggle('slow', function() {
       // Animation complete.
     });
   });
 });
 
$(document).ready(function() {
  $('#table_woo').dataTable()
});

/* necessary to run datePickerOptions after all partials have
   loaded; (document).ready() executes after DOM tree loads
   and partials have not yet loaded by this point */
var datePickerOptions = function() {
  $(".hasDatepicker").datepicker("option", "minDate", new Date());
  $('.hasDatepicker').datepicker("option", "prevText", "");
};

window.addEventListener ?
window.addEventListener("load",datePickerOptions,false) :
window.attachEvent && window.attachEvent("onload",datePickerOptions);
// end datePickerOptions
