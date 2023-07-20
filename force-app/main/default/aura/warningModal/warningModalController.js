({
    init : function (component) {
        // Find the component whose aura:id is "flowData"
        var inDesignMode = document.location.href.toLowerCase().indexOf( 
            'editor' ) >= 0;
        if(!inDesignMode) {
            component.set("v.showModal", true);
            var flow = component.find("flowData");
            var inputVariables = [
                // Set the recordId varieable to the value of the component's recordId
                // attribute. 
                { name : "recordID", type : "String", value: component.get("v.recordId") },
                
            ];
                flow.startFlow("ER_Prioritisation_Resolution_MoE_Email", inputVariables);
                
                }
           },
            
	handleStatusChange : function (component, event) {
		if(event.getParam("status") === "FINISHED") {
                //close modal
                component.set("v.showModal", false);
                //refresh view to show changes in record detail
                $A.get('e.force:refreshView').fire();
                //get output variable from screen flow to fire toast if emails were sent to MoE
                var outputVariables = event.getParam("outputVariables");
                var outputVar;
                for(var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
            
            
            if(outputVar.name === "emailSent" && outputVar.value == true) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success", 
                    "message": "Emails have been sent to MoE Team"
                });
                toastEvent.fire()
            } 
        }
             
        } 
    
	},
 })