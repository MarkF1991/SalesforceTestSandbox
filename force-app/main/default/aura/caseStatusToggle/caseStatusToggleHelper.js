({
	displayErrorToast : function(msg) {
        console.log("Message received: " + msg);
        var errorMsg = msg ? msg : "Salesforce has encountered an error and cannot update the Case Status at this time. You may need to refresh the page.";
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Cannot update Case Status!",
            "type" : "error",
            "message": errorMsg
        });
    toastEvent.fire();
		
	}
})