function decCellValue(cell) {
  var obj = cell.children('.num').children()[0];
  obj.innerHTML = parseInt(obj.innerHTML) - 1;
};

function parseDate(dateString){
//why the fck cant we have normal datestrings
  var d = new Date(dateString);
  var string = d.toISOString();
  return string.substring(5,7) + "/" + string.substring(8,10) + '/' + string.substring(0,4);
}

function dateInTimeZone(dateString) {
  // parse an ISO date string and returns
  // midnight of that date in the system time
  date = new Date(dateString);
  date.setTime(date.getTime() + date.getTimezoneOffset()*60*1000);
  return date;
}

function dateToRubyString(date) {
  return date.toISOString().substring(0,10);
};

function dateToHeading(date) {
  var days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  return ' ' + days[date.getUTCDay()];
};

function renderCalendar(reservations, week_start, max, blackouts) {
  //set initial values and date ids
  var date = new Date(week_start.getTime());
  $('.calendar_cell').each(function() {
    $(this).children('.head').children()[0].innerHTML = date.getUTCDate().toString();
    $(this).children('.head').children()[1].innerHTML = dateToHeading(date);
    $(this).children('.num').children()[0].innerHTML = max.toString();
    $(this).attr('id',dateToRubyString(date));
    date.setDate(date.getDate()+1);
  });
  var months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

  $('.month').children()[0].innerHTML = months[week_start.getMonth()] + " " + date.getFullYear().toString();

  //set cell values based on reservations
  var week_end = new Date(week_start.getTime());
  week_end.setDate(week_start.getDate() + 6);

  for(var d = 0; d < reservations.length; d++) {
      var end = new Date (reservations[d].end);
      var start = new Date (reservations[d].start);
      if ((start < week_end) && (end >= week_start)) {
        //for each reservation, decrement availability per day
        var begin_date = ((week_start > start) ? week_start : start);
        var end_date = ((week_end < end) ? week_end : end);
        for (var date = new Date(begin_date.getTime());
             date <= end_date;
             date.setDate(date.getDate()+1)) {
          decCellValue($('#'+dateToRubyString(date)));
        }
      }
  }

  //color cells appropriately
  $('.calendar_cell').each(function() {
    var blacked = false;
    for(var b = 0; b < blackouts.length; b++) {
      date = dateInTimeZone($(this).attr('id'));
      if ((new Date(blackouts[b].start) <= date) && (new Date(blackouts[b].end) >= date)) {
        blacked = true;
        break;
      }
    }
    if (blacked) {
      var color = '#aaaaaa';
    } else {
      var val = parseInt($(this).children('.num').children()[0].innerHTML);
      var red = Math.min(Math.floor(510 - val*510/max),255).toString();
      var green = Math.min(Math.floor(val*510/max),255).toString();
      var color = 'rgba(' + red + ',' + green + ',0,0.3)';
    }
    $(this).css("background-color",color);

  });

};

function shiftCalendar(offset) {
  var reservations = $('#res-data').data('url');
  var blackouts = $('#res-data').data('blackouts');
  var week_start = dateInTimeZone($('.calendar_cell').first().attr('id'));
  var today = dateInTimeZone($('#res-data').data('today'));
  var date_max = dateInTimeZone($('#res-data').data('dateMax'));
  var max = $('#res-data').data('max');

  week_start.setDate(week_start.getDate() + offset);
  block_left = week_start <= today;
  if (block_left) {
    week_start.setTime(today.getTime());
  }
  $('.c-left').children().toggleClass('disabled-control',block_left);

  block_right = week_start >= date_max;
  if (block_right) {
    week_start.setTime(date_max.getTime());
  }
  $('.c-right').children().toggleClass('disabled-control',block_right);
  renderCalendar(reservations,week_start,max,blackouts);
};


$('#reservation-calendar').ready(function() {

  //quit if no reservation calendar present
  //there's probably a better way to do this?

  if ($('#reservation-calendar').size() == 0) {
    return false;
  }

  shiftCalendar(0);

  $('.calendar_cell').click(function() {
    //set cart dates to day clicked
    $('#cart_start_date_cart').attr('value', parseDate($(this).attr('id'))).trigger('change');
  });

  $('.control').click(function() {
    shiftCalendar(parseInt($(this).attr('change')));
  });

});
