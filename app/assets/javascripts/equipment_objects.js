function handleDeactivation(e) {
  var p = prompt("Write down the reason for deactivation of this equipment object.")
  if (p != null) {
    e.href += "?deactivation_reason=" + encodeURIComponent(p)
  }
};

