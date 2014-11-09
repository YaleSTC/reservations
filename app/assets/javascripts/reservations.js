function getArchiveNote(e) {
  var archiveReason = prompt("Write down the reason for archiving this reservation.")
  e.href += "?archive_note=" + encodeURIComponent(archiveReason)
};
