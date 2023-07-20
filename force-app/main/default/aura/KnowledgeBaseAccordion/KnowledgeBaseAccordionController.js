({
    init: function (cmp) {
        var action = cmp.get("c.getList");
        action.setParams({ kbTopic : cmp.get("v.dataTopic"), kbType : cmp.get("v.dataType")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.data', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);  
    }
})