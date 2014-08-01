function load_datepicker() {
  $('.date_start').datepicker({
    altField: '#date_start_alt',
    altFormat: 'yy-mm-dd',
    minDate: 0,
    onClose: function(dateText, inst) {
      var start_date = $('.date_start').datepicker("getDate");
      var end_date = $('.date_end').datepicker("getDate");
      if (start_date > end_date){
        var new_date = new Date(start_date.getTime()+86400000);
        $('.date_end').datepicker("setDate", new_date);
      }
      $('.date_end').datepicker( "option" , "minDate" , start_date);
    }
  });

  $('.date_end').datepicker({
    altField: '#date_end_alt',
    altFormat: 'yy-mm-dd',
    minDate: 0
  });

  $('.date_start_no_min').datepicker({
    altField: '#date_start_alt',
    altFormat: 'yy-mm-dd',
    onClose: function(dateText, inst) {
      var start_date = $('.date_start_no_min').datepicker("getDate");
      var end_date = $('.date_end_no_min').datepicker("getDate");
      if (start_date > end_date){
        var new_date = new Date(start_date.getTime()+86400000);
        $('.date_end_no_min').datepicker("setDate", new_date);
      }
      $('.date_end_no_min').datepicker( "option" , "minDate" , start_date);
    }
  });

  $('.date_end_no_min').datepicker({
    altField: '#date_end_alt',
    altFormat: 'yy-mm-dd',
    onClose: function(dateText, inst) {
      var start_date = $('.date_start_no_min').datepicker("getDate");
      var end_date = $('.date_end_no_min').datepicker("getDate");
      if (start_date > end_date) {
        var new_date = new Date(start_date.getTime()+86400000);
        $('.date_end_no_min').datepicker("setDate", new_date);
      }
      $('.date_end_no_min').datepicker( "option" , "minDate" , start_date);
    }
  });
};


