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
  for(var d = 0; d < reservations.length; d++) {
      var end = new Date (reservations[d].end);
      var start = new Date (reservations[d].start);
      var week_end = new Date();
      week_end.setDate(week_start.getDate() + 7);
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
      date = new Date($(this).attr('id'));
      if ((new Date(blackouts[b].start) <= date) && (new Date(blackouts[b].end) >= date)) {
        blacked = true;
        break;
      }
    }
    if (blacked) {
      var color = '#999999';
    } else {
      var val = parseInt($(this).children('.num').children()[0].innerHTML);
      var red = Math.min(Math.floor(510 - val*510/max),255).toString();
      var green = Math.min(Math.floor(val*510/max),255).toString();
      var color = 'rgba(' + red + ',' + green + ',0,0.5)';
    }
    $(this).css("background-color",color);

  });

};

function shiftCalendar(offset) {
  var reservations = $('#res-data').data('url');
  var blackouts = $('#res-data').data('blackouts');
  var week_start = new Date($('.calendar_cell').first().attr('id'));
  var today = new Date($('#res-data').data('today'));
  var date_max = new Date($('#res-data').data('dateMax'));
  var max = $('#res-data').data('max');
  week_start.setDate(week_start.getDate() + offset);
  if (week_start < today) {
    week_start.setTime(today.getTime());
  }
  if (week_start > date_max) {
    week_start.setTime(date_max.getTime());
  }
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
