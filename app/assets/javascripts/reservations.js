function getArchiveNote(e) {
  var archiveReason = prompt("Write down the reason for archiving this reservation.")
  if(archiveReason == null) {
    e.href += "?archive_cancelled=1"
  } else {
    e.href += "?archive_note=" + encodeURIComponent(archiveReason)
  }
};
