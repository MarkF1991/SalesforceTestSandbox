({
    init : function (cmp) {
        var flow = cmp.find("Email_or_MFA_Flow");
        var inputVariables = [
        {
            name : 'LoginFlow_UserId',
            type : 'String',
            value : cmp.get('v.UserId')
        }
        ];
        flow.startFlow("Email_or_MFA_Flow", inputVariables);
    },
    
    handleStatusChange : function (cmp, event) {
        if (event.getParam('status') === "FINISHED") {
            cmp.set("v.flowOfStatus", 'Quit');
        }
    },
    
    handleStatusChangeMain : function (cmp, event) {
        var navigate = cmp.get("v.navigateFlow");
        navigate("FINISH");
    },
   
 
})