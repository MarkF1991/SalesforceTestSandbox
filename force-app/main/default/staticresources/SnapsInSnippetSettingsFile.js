window._snapinsSnippetSettingsFile = (function() {

    // Logs that the snippet settings file was loaded successfully
    console.log("Snippet settings file loaded.");   

    // set all fields entered in the pre-chat widown into custom fields on the chat transcript object
    // fields without a value entered here - will get the value from the form itself
    embedded_svc.snippetSettingsFile.extraPrechatFormDetails = [
        {
            "label": "First Name",
            "transcriptFields": ["First_Name__c"],
            "displayToAgent": false
        },
        {
            "label": "Last Name",
            "transcriptFields": ["Last_Name__c"],
            "displayToAgent": false
        },
        {
            "label": "Email",
            "transcriptFields": ["Email__c"],
            "displayToAgent": false
        },
        {
            "label": "Phone",
            "transcriptFields": ["Phone__c"],
            "displayToAgent": false
        }
    ]; 
})();