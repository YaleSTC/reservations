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

$(document).ready(function() {
  $('#table_woo').dataTable()
});

$.datepicker.setDefaults({
   minDate: new Date(),
});

// auto-save the reserver_id, on any click outside the box
$('.submittable').live('blur', function() {
  $.ajax({
       url: '/cart/update/',
       data: { 'reserver_id': reserver_id.value,
               'start_date_cart': cart_start_date_cart.value,
               'due_date_cart': cart_due_date_cart.value }
  });
});
// the datepicker function needs to be submitted on change
$('.submitchange').live('change', function() {
  $.ajax({
       url: '/cart/update/',
       data: { 'reserver_id': reserver_id.value,
               'start_date_cart': cart_start_date_cart.value,
               'due_date_cart': cart_due_date_cart.value }
  });
});
