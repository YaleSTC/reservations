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

$('.submittable').on('change', function() {
  $(this).parents('form:first').submit();
});

$('#fake_reserver_id').on('change', function() {
  $.ajax({
       url: '/cart/update/',
       data: { 'reserver_id': reserver_id.value,
               'cart.start_date_cart': start_date.value,
               'cart.due_date_cart': due_date.value }
  });
});
