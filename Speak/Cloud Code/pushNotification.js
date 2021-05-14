Parse.Cloud.define("sendPushToUser", function(request, response) {
  var senderUser = request.user;
  //var recipientUserId = request.params.recipientId;
  var message = request.params.message;
  var members = request.params.members;
  var _groupId = request.params.groupId;
  var groupTitle = request.params.groupTitle;
  var _text = request.params.groupTitle;
  // Validate the message text.
  // For example make sure it is under 140 characters
  if (message.length > 140) {
  // Truncate and add a ...
    message = message.substring(0, 137) + "...";
  }

  //removing the sender user from the recipients
                   var me_ID = senderUser.objectId;
  for (var i=members.length-1; i>=0; i--) {
    if (members[i] === me_ID) {
        members.splice(i, 1);
        // break;       //<-- Uncomment  if only the first term has to be removed
    }
  }
  var query = new Parse.Query(Parse.User);
  query.containedIn("objectId", members);
  //query.notEqualTo("objectId", senderUser.objectId);

  var pushQuery = new Parse.Query(Parse.Installation);
  pushQuery.matchesQuery("user", query);
  // Send the push notification to results of the query
  console.log('Sending a message push');
  Parse.Push.send({
    where: pushQuery,
    data: {
      alert: message,
      badge: "Increment",
      category: "ACTIONABLE",
      sound : "105.caf",
      groupId : _groupId,
      title : groupTitle,
      sendingUserId : senderUser.objectId,
      text : _text
    }
  }, { useMasterKey: true })
  .then(function() {
      response.success("Push was sent successfully.")
  }, function(error) {
      response.error("Push failed to send with error: " + error.message);
  });
});
