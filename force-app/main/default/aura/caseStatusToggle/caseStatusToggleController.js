({
    //Save the record using the Lightning Data Service 
    saveUsingLDS : function(component, event, helper) {
       
         //show spinner
        component.set('v.showSpinner', true);
        //use saveRecord function on Record Handler
        component.find("caseRecord").saveRecord($A.getCallback(function(saveResult) {
            // use the recordUpdated event handler to handle generic logic when record is changed
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                // handle component related logic in event handler
                // //hide spinner
                component.set('v.showSpinner', false);
            } else if (saveResult.state === "INCOMPLETE") {
                //hide spinner
                component.set('v.showSpinner', false);
                helper.displayErrorToast();
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                //hide spinner
                component.set('v.showSpinner', false);
                //reload record because the change did not save
                component.find("caseRecord").reloadRecord();
                //get message for all errors and show in toast
                var msg = "";
                for (var i = 0; saveResult.error.length > i; i++){
                    msg = msg + saveResult.error[i].message;
                };                    
                helper.displayErrorToast(msg);
                //Print errors to log
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            } else {
                //hide spinner
                component.set('v.showSpinner', false);
                helper.displayErrorToast();
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
    },
    
    /**
     * Control the component behavior here when record is changed (via any component)
     */
    handleRecordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            // get the fields that changed for this record
            var changedFields = eventParams.changedFields;
            console.log('Fields that are changed: ' + JSON.stringify(changedFields));
            // record is changed, so refresh the component (or other component logic)
              component.find("caseRecord").reloadRecord();

        } else if(eventParams.changeType === "LOADED") {
            // record is loaded in the cache
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted and removed from the cache
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving or deleting the record
             helper.displayErrorToast();
        }
    },
    
    
    
    
})