//= require jquery
//= require jquery_ujs
//= require jquery-ui/datepicker
//= require jquery-ui/autocomplete
//= require cocoon
//= require autocomplete-rails
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/2/jquery.dataTables.bootstrap
//= require bootstrap/transition
//= require bootstrap/alert
//= require bootstrap/button
//= require bootstrap/collapse
//= require bootstrap/dropdown
//= require bootstrap/modal
//= require bootstrap/scrollspy
//= require bootstrap/tab
//= require bootstrap/tooltip
//= require bootstrap/popover
//= require variables.js
//= require select2
//= require_tree
//= require_self

function truncate() {
  if ($(".caption_cat").length) {
    $(".caption_cat").dotdotdot({
      height: 150,
      after: ".more_info",
      watch: 'window'
    });
  }

  if ($(".equipment_title").length) {
    $(".equipment_title").dotdotdot({
      height: 27, // must match .equipment_title height
      watch: 'window'
    });
  }

  // TODO: Refactor this so it won't so drastically impact client-side performance.
  // Until it's refactored, it's better off disabled.
  // This code displays a tooltip in the catalog if the equipment model name is truncated.
  //
  // This code was re-enabled on 2014-07-28 and no noticeable
  // performance hit was noted

   $(".equipment_title").each(function(){
     $(this).trigger("isTruncated", function( isTruncated ) {
       if ( isTruncated ) {
         $(this).children(".equipment_title_link").tooltip();
       }
     });
   });
};

// general submit on change class
$(document).on('change', '.autosubmitme', function() {
  // test for cart date fields to toggle cart spinner
  if ( $(this).parents('div:first').is("#cart_dates") ) {
    pause_cart();
  }
  $(this).parents('form:first').submit();
});

$(document).on('railsAutocomplete.select', '#fake_searched_id', function(){
  $(this).parents('form').submit();
});

$(document).ready(function() {

  // For DataTables and Bootstrap
  $('.datatable').dataTable({
    "sDom": "<'row'<'span4'l><'span5'f>r>t<'row'<'span3'i><'span6'p>>",
    "sPaginationType": "bootstrap",
    "sScrollX": "100%",
    "aoColumnDefs": [
          { "bSortable": false, "aTargets": [ "no_sort" ] }
        ]
  });

  wideDataTables = $('.datatable-wide').dataTable({
    "sDom": "<'row'<'span5'l><'span7'f>r>t<'row'<'span5'i><'span7'p>>",
    "sPaginationType": "bootstrap",
    "sScrollX": "100%",
    "aoColumnDefs": [
          { "bSortable": false, "aTargets": [ "no_sort" ] }
        ]
  });

  // ### REPORTS JS ### //

  $('.report_table').dataTable({
    "sDom": "<'row'<'span3'l>fr>t<'row'<'span3'i><p>>",
    "sPaginationType": "bootstrap",
    "iDisplayLength" : 25,
    "aLengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
    "aoColumnDefs": [{ "bSortable": false, "aTargets": [ "no_sort" ] }]
  });

  // For fading out flash notices
  $(".alert .close").click( function() {
       $(this).parent().addClass("fade");
  });

  // make the sidebar follow you down the page
  if ($(window).width() > 767) {
    $("#sidebarbottom").sticky({topSpacing: 50, bottomSpacing: 200});
  }

  // truncate catalog descriptions
  truncate();

  $(".btn#modal").tooltip();
  $(".not-qualified-icon").tooltip();
  $(".not-qualified-icon-em").tooltip();

  $('.associated_em_box img').popover({ placement: 'bottom' });
  $("#my_reservations .dropdown-menu a").popover({ placement: 'bottom' });
  $("#my_equipment .dropdown-menu a").popover({ placement: 'bottom' });

  // fix sub nav on scroll
  var $win = $(window)
    , $nav = $('.subnav')
    , navTop = $('.subnav').length && $('.subnav').offset().top - 40
    , isFixed = 0
    , $hiddenName = $('.subnav .hide')

  processScroll()

  // hack sad times - holdover until rewrite for 2.1
  $nav.on('click', function () {
    if (!isFixed) setTimeout(function () {  $win.scrollTop($win.scrollTop() - 47) }, 10)
  })

  $win.on('scroll', processScroll)

  function processScroll() {
    var i, scrollTop = $win.scrollTop()
    if (scrollTop >= navTop && !isFixed) {
      isFixed = 1
      $nav.addClass('subnav-fixed')
      $hiddenName.removeClass('hide')
      if (!$('.subnav li').hasClass('active')) {
        $('.subnav li:eq(1)').addClass('active')
      }
    } else if (scrollTop <= navTop && isFixed) {
      isFixed = 0
      $nav.removeClass('subnav-fixed')
      $hiddenName.addClass('hide')
      $('.subnav li').removeClass('active')
    }
  }

  $('#modal').click(function() {
    $('#userModal div.modal-body').load(new_user, {possible_netid : $('#fake_reserver_id').val() }); // new_user defined in variables.js.erb
  });

  load_datepicker();

  // Select2 - fancy select lists
  $('select#equipment_model_category_id').select2();
  $('select#equipment_model_associated_equipment_model_ids').select2();
  $('select#equipment_model_requirements').select2();
  $('select#equipment_object_equipment_model_id').select2();
  $('select#requirement_equipment_model').select2();
  $('select.dropdown.dropselect').select2();

  // Popup confirmation when editing reservation equipment objects
  $('.reservation_eq_objects').on('change', function() {
    newMsg = ($('.select2-choice > .select2-chosen').text() == $('#equipment_object').attr('placeholder'))
      ? ""
      : "Be aware that changing the reservation equipment item may have an effect on another reservation. If you set this reservation's equipment item to an item that has already been checked out, the reservations will be swapped.";
    $('.form-actions').children('input').data('confirm', newMsg);
  });


});
