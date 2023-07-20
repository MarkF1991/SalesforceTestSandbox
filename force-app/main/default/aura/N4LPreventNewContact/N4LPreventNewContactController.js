({
    doInit : function(component, event, helper) {
        alert($A.get("$Label.c.Screen_PreventNewContact"));
        window.history.back();
    }
})