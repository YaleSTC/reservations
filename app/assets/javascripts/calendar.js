function decCellValue(cell) {
  var obj = cell.children('.num').children()[0];
  obj.innerHTML = parseInt(obj.innerHTML) - 1;
};

$('#reservation-calendar').ready(function() {
    var reservations = $('#res-data').data('url');
    var week_start = new Date($('#res-data').data('day'));
    var max = $('#res-data').data('max');
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
          var cell = $('.'+date.toISOString().substring(0,10));
          decCellValue(cell);
        }
      }
    }
    $('.calendar_cell').cells.each(function() {
      var val = parseInt($(this).children('.num').children()[0].innerHTML);
      var red = Math.min(Math.floor(510 - val*510/max),255).toString();
      var green = Math.min(Math.floor(val*510/max),255).toString();
      var color = 'rgba(' + red + ',' + green + ',0,0.25)';
      $(this).css("background-color",color);
    });

  });

