function handleDeactivation(e, overbooked) {
  if (arguments.length > 1 && overbooked.length > 0) {
    var c = confirm("This equipment will be overbooked over the coming week from "+overbooked[0]+" to "+overbooked[overbooked.length-1]+". Are you sure you want to continue?")
  }
  else {
    var c = true
  }
  if (c == true) {
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

