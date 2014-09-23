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
// click add to cart button
$(document).on('click', '.add_to_cart', function () {
  pause_cart();
});

$(document).on('click', '#empty_cart_btn', function () {
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

