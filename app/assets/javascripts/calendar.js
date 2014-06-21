function decCellValue(cell) {
  var obj = cell.children('.num').children()[0];
  obj.innerHTML = parseInt(obj.innerHTML) - 1;
};

function dateToRubyString(date) {
  return date.toISOString().substring(0,10);
};

function dateToHeading(date) {
  var days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  var day = days[date.getDay()];
  return date.getDate().toString() + " - " + day;
};

function renderCalendar(reservations, week_start, max) {
  //set initial values and date ids
  var date = new Date(week_start.getTime());
  $('.calendar_cell').each(function() {
    $(this).children('.head').children()[0].innerHTML = dateToHeading(date);
    $(this).children('.num').children()[0].innerHTML = max.toString();
    $(this).attr('id',dateToRubyString(date));
    date.setDate(date.getDate()+1);
  });
  //set cell values based on reservations
  for(var d = 0; d < reservations.length; d++) {
      var end = new Date (reservations[d].end);
      var start = new Date (reservations[d].start);
      var week_end = new Date();
      week_end.setDate(week_start.getDate() + 7);
      if ((start < week_end) && (end >= week_start)) {
        //for each reservation, decrement availability per day
        var begin_date = ((week_start > start) ? week_start : start);
        var end_date = ((week_end < end) ? week_end : end);
        for (var date = begin_date;
             date <= end_date;
             date.setDate(date.getDate()+1)) {
          decCellValue($('#'+dateToRubyString(date)));
        }
      }
  }

  //color cells appropriately
  $('.calendar_cell').each(function() {
    var val = parseInt($(this).children('.num').children()[0].innerHTML);
    var red = Math.min(Math.floor(510 - val*510/max),255).toString();
    var green = Math.min(Math.floor(val*510/max),255).toString();
    var color = 'rgba(' + red + ',' + green + ',0,0.5)';
    $(this).css("background-color",color);
  });

};

function shiftCalendar(offset) {
  var reservations = $('#res-data').data('url');
  var week_start = new Date($('.calendar_cell').first().attr('id'));
  var max = $('#res-data').data('max');
  week_start.setDate(week_start.getDate() + offset);
  renderCalendar(reservations,week_start,max);
};


$('#reservation-calendar').ready(function() {

  shiftCalendar(0);

  $('.calendar_cell').click(function() {
    //set cart dates to day clicked
  });

  $('.forward1').click(function() {
    shiftCalendar(1);
  });



});
