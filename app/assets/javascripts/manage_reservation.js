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
      if( confirm("Oops! We've noticed one of the following issues:\n\n"+
        "You didn't check off all procedures for an item your're checking "+
        "in/out,\n\n\tor\n\nYou didn't select an item for a reservation you "+
        "checked off procedures for.\n\nAre you sure you want to continue?")){
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
    //if ($(this).hasClass("overdue")) {
    //  $(this).toggleClass("selected-overdue",box.prop("checked"));
    //} else {
    $(this).toggleClass("selected",box.prop("checked"));
    //}
    //above code commented out to remove coloring overdue
    //reservations with a different color. may be reimplemented
    //later but possibly to signal incomplete checkin procedures
    //instead
    $(this).find('.c-box').toggleClass("fa-check-square-o check",box.prop("checked"));
    $(this).find('.c-box').toggleClass("fa-square-o",!box.prop("checked"));
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

});

