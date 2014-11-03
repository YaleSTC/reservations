function getArchiveNote(e) {
  var p = prompt("Write down the reason for archiving this reservation.")
  e.href += "?archive_note=" + encodeURIComponent(p)
};