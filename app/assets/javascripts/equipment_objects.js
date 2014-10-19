function handleDeactivation(e) {
  var p = prompt("Write down the reason for deactivation of this equipment object.")
  e.href += "?deactivation_reason=" + encodeURIComponent(p)
};

