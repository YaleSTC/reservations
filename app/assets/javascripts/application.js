// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery.sticky
//= require jquery.dotdotdot-1.5.1
//= require cocoon
//= require autocomplete-rails
//= require dataTables/jquery.dataTables
//= require dataTables_numhtml_sort.js
//= require dataTables_numhtml_detect.js
//= require dataTables/jquery.dataTables.bootstrap
//= require bootstrap
//= require_self

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
	
	$('.history_table').dataTable({
	  "sDom": "<'row'<l><f>r>t<'row'<'span3'i><p>>",
		"bLengthChange": false,
	  "sPaginationType": "bootstrap",
		"aoColumnDefs": [
		      { "bSortable": false, "aTargets": [ "no_sort" ] }
		    ]
	});

// For fading out flash notices
	$(".alert .close").click( function() {
	     $(this).parent().addClass("fade");
	});
	
	$("#sidebarbottom").sticky({topSpacing: 50, bottomSpacing: 200});

	$(".caption_cat").dotdotdot({
		height: 126,
		after: ".more_info",
		watch: 'window',
		});
		
	$(".equipment_title").dotdotdot({
		height: 54, // must match .equipment_title height
		watch: 'window'
		});

	$(".equipment_title").each(function(){
		$(this).trigger("isTruncated", function( isTruncated ) {
		  if ( isTruncated ) {
		   	$(this).children(".equipment_title_link").tooltip();
		  }
		});
	});

	$(".btn#modal").tooltip();
	
	// Equipment Model - show - progress bar
	
  $('.progress .bar').each(function() {
      var me = $(this);
      var perc = me.attr("data-percentage");
      var current_perc = 0;

      var progress = setInterval(function() {
          if (current_perc>=perc) {
              clearInterval(progress);
          } else {
              current_perc = perc;
              me.css('width', (current_perc)+'%');
          }
      }, 100);
  });

$('.associated_em_box img').popover({ placement: 'bottom' });

$('#subnavbar').scrollspy();
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
  } else if (scrollTop <= navTop && isFixed) {
    isFixed = 0
    $nav.removeClass('subnav-fixed')
		$hiddenName.addClass('hide')
  }
}

});
// to disable selection of dates in the past with datepicker
$.datepicker.setDefaults({
   minDate: new Date(),
});

// auto-submit cart dates #only-cart-dates
  $(document).on('change', '.submitchange', function() {
      $('#cart_dates').load( update_cart_path.value, // defined in _cart_dates in hidden field
// params need to be passed
        { 'reserver_id': reserver_id.value,
          'start_date_cart': cart_start_date_cart.value,
          'due_date_cart': cart_due_date_cart.value }
      );
  });

// auto-submit cart dates #only-cart-reserver
  $(document).on('blur', '.submittable', function() {
      $('#cart_dates').load( update_cart_path.value, // defined in _cart_dates in hidden field
// params need to be passed
        { 'reserver_id': reserver_id.value,
          'start_date_cart': cart_start_date_cart.value,
          'due_date_cart': cart_due_date_cart.value }
      );
  });

// general submit on change class
  $(document).on('change', '.autosubmitme', function() {
    $(this).parents('form:first').submit();
  });

// general submit on click class
  $(document).on('click', '.autosubmitmeclick', function() {
    $(this).parents('form:first').submit();
  });

//Load the user/new into the modal div for the new reserver button in the cart
$().ready(function() {
  $('#modal').click(function() {
    $('#userModal div.modal-body').load(new_user_path.value, {from_cart : true }); // new_user_path defined in _cart_dates
  });
});
