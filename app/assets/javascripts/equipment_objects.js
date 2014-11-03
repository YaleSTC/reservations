function handleDeactivation(e, reservation_id, overbooked) {
  if (arguments.length > 1 && reservation_id) {
    var c = confirm("This equipment is currently checked out. If you continue then reservation #"+reservation_id+" will be archived. Do you want to proceed?")
  } else {
    var c = true
  }
  if (c == true && arguments.length > 2 && overbooked.length > 0) {
    var d = confirm("This equipment will be overbooked over the coming week from"+overbooked[0]+" to"+overbooked[overbooked.length-1]+". Are you sure you want to continue?")
  }
  else {
    var d = true
  }
  if (c == true && d == true) {
    var p = prompt("Write down the reason for deactivation of this equipment object.")
    if (p == null) {
      e.href += "?deactivation_cancelled=1"
    } else if (p != "") {
      e.href += "?deactivation_reason=" + encodeURIComponent(p)
    }
  }
  else {
    e.href += "?deactivation_cancelled=1"
  }
};