//= require jquery
//= require jquery_ujs
//= require jquery.ui.datepicker
//= require jquery.ui.autocomplete
//= require jquery.sticky
//= require jquery.dotdotdot-1.5.1
//= require jquery.spin
//= require cocoon
//= require autocomplete-rails
//= require dataTables/bootstrap/2/jquery.dataTables.bootstrap
//= require dataTables/jquery.dataTables
//= require dataTables_numhtml_sort.js
//= require dataTables_numhtml_detect.js
//= require bootstrap-transition
//= require bootstrap-alert
//= require bootstrap-button
//= require bootstrap-collapse
//= require bootstrap-dropdown
//= require bootstrap-modal
//= require bootstrap-scrollspy
//= require bootstrap-tab
//= require bootstrap-tooltip
//= require bootstrap-popover
//= require variables.js
//= require select2
//= require_self
//= require calendar.js

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
    // $(".equipment_title").each(function(){
    //   $(this).trigger("isTruncated", function( isTruncated ) {
    //     if ( isTruncated ) {
    //       $(this).children(".equipment_title_link").tooltip();
    //     }
    //   });
    // });
  };

  function validate_checkin(){
    flag = false;
    $.each( $(".checkin"), function(i, l){
      var steps = $(this).find(':checkbox').length;
      var steps_completed = $(this).find("input:checked").length;
      var selected = $(this).find("input.checkin-select").is(':checked');
      if ( selected  && (steps_completed < steps) ){
        flag = true;
      }
      //If they don't select a given item to checkin, but select some of the steps
      if ( !selected && (steps_completed > 0) ){
        flag = true;
      }

    });
    return flag;
  };

  function validate_checkout(){
    flag = false;
    $.each( $(".checkout"), function(i, l){
      var steps = $(this).find(':checkbox').length;
      var steps_completed = $(this).find("input:checked").length;
      var selected = $(this).find("select.dropselect").val();
      //If they select a given item to checkin, but not all the steps
      if ((selected != "") && (steps_completed < steps) ){
        flag = true;
      }
      //If they don't select a given item to checkin, but select some of the steps
      if ((selected == "") && (steps_completed > 0) ){
        flag = true;
      }

    });
    return flag;
  };

  function confirm_checkinout(flag){
    if (flag){
      if( confirm("Oops! We've noticed one of the following issues:\n\nYou checked off procedures for an item you're not checking in/out.\n\n       or\n\nYou didn't check off all procedures for an item that you are checking in/out.\n\nAre you sure you want to continue?")){
        (this).submit();
        return false;
      } else {
        //they clicked no.
        return false;
      }
    }
    else {
      (this).submit();
    }
  };

$(document).ready(function() {

  $('.checkin-click').click( function() {
    var box = $(":checkbox:eq(0)", this);
    box.prop("checked", !box.prop("checked"));
    if ($(this).hasClass("overdue")) {
      $(this).toggleClass("selected-overdue",box.prop("checked"));
    } else {
      $(this).toggleClass("selected",box.prop("checked"));
    }
    $(this).find('.check').toggleClass("hidden",!box.prop("checked"));
  });

  $('#checkout_button').click(function() {
    var flag = validate_checkout();
    confirm_checkinout(flag);
    return false;
  });

  $('#checkin_button').click(function() {
    var flag = validate_checkin();
    confirm_checkinout(flag);
    return false;
  });

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

  // Ugly hack to avoid reinitializing #table_log with the correct order
  try {
    if (wideDataTables[0].id == "table_log") {
      wideDataTables.fnSort([[0, "desc"]]);
    }
  } catch (TypeError) {}

  $('.history_table').dataTable({
    "sDom": "<'row'<l><f>r>t<'row'<'span3'i><p>>",
    "bLengthChange": false,
    "sPaginationType": "bootstrap",
    "aoColumnDefs": [
          { "bSortable": false, "aTargets": [ "no_sort" ] }
        ]
  });

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

// perform truncate, which is also defined outside of document ready
// it needs to be both places due to a webkit bug not loading named
// JS functions in (document).ready() until AFTER displaying all the things

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
  // $(".equipment_title").each(function(){
  //   $(this).trigger("isTruncated", function( isTruncated ) {
  //     if ( isTruncated ) {
  //       $(this).children(".equipment_title_link").tooltip();
  //     }
  //   });
  // });

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
    $('#userModal div.modal-body').load(new_user, {from_cart : true, possible_netid : $('#fake_reserver_id').val() }); // new_user defined in variables.js.erb
  });

  $('.date_start').datepicker({
    altField: '#date_start_alt',
    altFormat: 'yy-mm-dd',
    onClose: function(dateText, inst) {
      var start_date = $('.date_start').datepicker("getDate");
      var end_date = $('.date_end').datepicker("getDate");
      if (start_date > end_date){
        $('.date_end').datepicker("setDate", start_date)
      }
      $('.date_end').datepicker( "option" , "minDate" , start_date);
    }
  });


  // Select2 - fancy select lists
  $('select#equipment_model_category_id').select2();
  $('select#equipment_model_associated_equipment_model_ids').select2();
  $('select#equipment_model_requirements').select2();
  $('select#equipment_object_equipment_model_id').select2();
  $('select#requirement_equipment_model').select2();
  $('select.dropdown.dropselect').select2();


});
// to disable selection of dates in the past with datepicker
$.datepicker.setDefaults({
   minDate: new Date()
});

// function to hold cart during update
function pause_cart () {
  // disable the cart form (using `readonly` to avoid breaking the session)
  $('#fake_reserver_id').prop('readonly', true);
  $('#modal').addClass('disabled');
  $('#cart_start_date_cart').prop('readonly', true);
  $('#cart_due_date_cart').prop('readonly', true);
  $('#cart_buttons').children('a').addClass("disabled"); // disable cart buttons
  $('.add_to_cart_box').children('#add_to_cart').addClass("disabled"); // disable add to cart buttons
  $('#cartSpinner').spin("large"); // toggle cart spinner
}

// function to unlock cart after update
function resume_cart () {
  // enable the cart form
  $('#fake_reserver_id').prop('readonly', false);
  $('#modal').removeClass('disabled');
  $('#cart_start_date_cart').prop('readonly', false);
  $('#cart_due_date_cart').prop('readonly', false);
  $('#cart_buttons').children('a').removeClass("disabled"); // disable cart buttons
  $('.add_to_cart_box').children('#add_to_cart').removeClass("disabled"); // enable add to cart buttons
  $('#cartSpinner').spin(false); // turn off cart spinner
}

// general submit on change class
$(document).on('change', '.autosubmitme', function() {
  // test for cart date fields to toggle cart spinner
  if ( $(this).parents('div:first').is("#cart_dates") ) {
    pause_cart();
  }
  $(this).parents('form:first').submit();
});

//$(document).on('change', '.autosubmitme2', function() {
//  $.ajax("update_dates");
//});

// click add to cart button
$(document).on('click', '.add_to_cart', function () {
  pause_cart();
});

// click remove from cart button
$(document).on('click', '#remove_button > a', function () {
  pause_cart();
});

$(document).on('railsAutocomplete.select', '#fake_reserver_id', function(event, data){
  pause_cart();
  $(this).parents('form').submit();
});

$(document).on('change','#fake_reserver_id',function() {
    if (!$('#fake_reserver_id').val()) {
      $('#reserver_id').val('');
      pause_cart();
      $(this).parents('form').submit();
    };

});

$(document).on('railsAutocomplete.select', '#fake_searched_id', function(){
  $(this).parents('form').submit();
});


function getDeactivationReason(e) {
  var p = prompt("Write down the reason for deactivation of this equipment object.")
  e.href += "?deactivation_reason=" + encodeURIComponent(p)
};


