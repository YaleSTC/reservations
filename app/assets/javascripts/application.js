//= require jquery
//= require jquery_ujs
//= require datatables.min.js
//= require jquery-ui/datepicker
//= require jquery-ui/autocomplete
//= require cocoon
//= require autocomplete-rails
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
//= require bootstrap/affix
//= require variables.js
//= require select2
//= require jquery.sticky.js
//= require jquery.dotdotdot.js
//= require moment
//= require fullcalendar
//= require_tree
//= require_self

function truncate() {
  if ($(".caption_cat").length) {
    $(".caption_cat").dotdotdot({
      height: 100,
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
    "pagingType": "full_numbers",
    "scrollX": false,
    "columnDefs": [
      { "orderable": false, "targets": [ "no_sort" ] }
    ]
  });

  $('.datatable-wide').dataTable({
    "pagingType": "full_numbers",
    "scrollX": false,
    "columnDefs": [
      { "orderable": false, "targets": [ "no_sort" ] }
    ]
  });

  // For DataTables in Bootstrap tabs
  // see https://datatables.net/examples/api/tabs_and_scrolling.html
  $('a[data-toggle="tab"]').on( 'shown.bs.tab', function (e) {
    $.fn.dataTable.tables( {visible: true, api: true} ).columns.adjust();
  } );

  // User profile history datatable default sorting
  $("#res-history-checked_out").DataTable().order([3, "asc"]).draw();
  $("#res-history-future").DataTable().order([2, "asc"]).draw();
  $("#res-history-overdue,#res-history-past,#res-history-past_overdue").DataTable().order([4, "desc"]).draw();

  // For reservation calendars
  $('.res-cal').fullCalendar({
    events: $('.res-cal').attr('data-src'),
    eventRender: function(event, element) {
      element.attr('data-role', 'cal-item');
      if(event.hasItem) {
        $(element).tooltip({title: event.location});
      }
    },
    buttonText: { today: 'Today' }
  });

  // ### REPORTS JS ### //

  $('.report_table').dataTable({
    "pagingType": "full_numbers",
    "pageLength": 25,
    "lengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
    "columnDefs": [{ "orderable": false, "targets": [ "no_sort" ] }]
  });

  // For fading out flash notices
  $(".alert .close").click( function() {
    $(this).parent().addClass("fade");
  });

  // make the sidebar follow you down the page
  if ($(window).width() > 767) {
    $("#sidebarbottom").sticky({topSpacing: 60, bottomSpacing: 200});
  }

  // truncate catalog descriptions
  truncate();

  $(".btn#userModalBtn").tooltip();
  $(".not-qualified-icon").tooltip();
  $(".not-qualified-icon-em").tooltip();
  $('[data-toggle="tooltip"]').tooltip();

  $('.associated_em_box img').popover({
    placement: 'bottom',
    trigger: 'hover',
    html: true,
    container: 'body'
  });
  $("#my_reservations .dropdown-menu a").popover({
    placement: 'bottom',
    trigger: 'hover',
    html: true,
    container: 'body'
  });
  $("#my_equipment .dropdown-menu a").popover({
    placement: 'bottom',
    trigger: 'hover',
    html: true,
    container: 'body'
  });

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

  $('#userModalBtn').click(function() {
    $.post(new_user, {possible_login: $('#fake_reserver_id').val() }); // new_user defined in variables.js.erb
  });

  load_datepicker();

  // Select2 - fancy select lists
  $('select#equipment_model_category_id').select2();
  $('select#equipment_model_associated_equipment_model_ids').select2();
  $('select#equipment_model_requirements').select2();
  $('select#equipment_item_equipment_model_id').select2();
  $('select#requirement_equipment_model').select2();
  $('select.dropdown.dropselect').select2();

  // Popup confirmation when editing reservation equipment items
  $('.reservation_eq_items').on('change', function() {
    newMsg = ($('.select2-choice > .select2-chosen').text() == $('#equipment_item').attr('placeholder'))
      ? ""
      : "Be aware that changing the reservation equipment item may have an effect on another reservation. If you set this reservation's equipment item to an item that has already been checked out, the reservations will be swapped.";
    $('input[type="submit"]').data('confirm', newMsg);
  });

});
