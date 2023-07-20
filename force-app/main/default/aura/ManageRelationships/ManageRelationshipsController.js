({
    doInit : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: $A.get("$Label.c.Screen_ManageContact")
            });
        }).catch(function(error) {
            console.log(error);
        });

        document.title = $A.get("$Label.c.Screen_ManageContact");

        component.set("v.addButtonLabel", $A.get("$Label.c.Screen_AddNewRelationship"));
        component.set("v.saveRelButton", $A.get("$Label.c.Screen_SaveRelationship"));
        component.set("v.searchPlaceholder", $A.get("$Label.c.Screen_SearchPlaceholder"));
        component.set("v.manageContact", $A.get("$Label.c.Screen_ManageContact"));

        var hideReplace = false;

        if($A.get("$Label.c.Screen_HideReplaceAction").toLowerCase().trim() == 'yes' 
            || $A.get("$Label.c.Screen_HideReplaceAction").toLowerCase().trim() == 'true' 
            || $A.get("$Label.c.Screen_HideReplaceAction").toLowerCase().trim() == '1') {
            hideReplace = true;
        }

        console.log(hideReplace);

        component.set("v.hideReplaceAction",hideReplace);
        
        var pageReference = component.get("v.pageReference");
        component.set("v.recordId", pageReference.state.c__recordId);
        component.set("v.pageSize", pageReference.state.c__size);        

        if(pageReference.state.c__size == null || pageReference.state.c__size == ''){
            component.set("v.pageSize",10);            
        }
    },
})