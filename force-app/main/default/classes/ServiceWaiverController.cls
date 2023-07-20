public with sharing class ServiceWaiverController {
    @InvocableMethod(label='Process Service Waiver and Acknowledgement' description='update account and Send acknowledgement email to submitter, contact and principal')
    public static void processWaiver(List<ID> ids){
        List<Service_Waiver__c> waivers = [SELECT Submitter_Name__c, Submitter_Email__c, InitiatedBy__r.email, Contact__c, Contact__r.FirstName, Contact__r.email, Account__c
                                           , Waiver_Link__c, Firewall_Removed__c, Web_Security_Removed__c, Default_Categories_Removed__c, Default_Categories__c
                                           FROM Service_Waiver__c WHERE Id in :ids];
        if(!waivers.isEmpty()){
            Service_Waiver__c waiver = waivers[0];
            updateAccount(waiver);
            sendWaiverAcknowledgementEmail(waiver);
        }
        
    }

    public static void updateAccount(Service_Waiver__c waiver){
        Account account = [SELECT id, Waiver_Firewall_Removed__c, Waiver_Web_Security_Removed__c, Waiver_Default_Categories_Removed__c, Waiver_Default_Categories__c FROM Account WHERE Id =: waiver.Account__c];

        if (waiver.Firewall_Removed__c!=null && waiver.Firewall_Removed__c.toLowerCase() == 'yes') {
            account.Waiver_Firewall_Removed__c =true; 
        } else {
            account.Waiver_Firewall_Removed__c =false; 
        }

        if (waiver.Web_Security_Removed__c!=null && waiver.Web_Security_Removed__c.toLowerCase() == 'yes') {
            account.Waiver_Web_Security_Removed__c = true;
        } else {
            account.Waiver_Web_Security_Removed__c =false; 
        }
        
        if (waiver.Default_Categories_Removed__c!=null && waiver.Default_Categories_Removed__c.toLowerCase() == 'yes') {
            account.Waiver_Default_Categories_Removed__c = true;
        } else {
            account.Waiver_Default_Categories_Removed__c =false; 
        }
        
        account.Waiver_Default_Categories__c = waiver.Default_Categories__c;

        update account;
    }
    
    public static void sendWaiverAcknowledgementEmail(Service_Waiver__c waiver){
        //if contact's email is different from principals' email then cc the principal. CC the RM anyway
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(waiver.Contact__c!=null && String.isNotBlank(waiver.Contact__r.email)) toAddresses.add(waiver.Contact__r.email); //add designated contact's email to address
            if(!toAddresses.contains(waiver.Submitter_Email__c)) toAddresses.add(waiver.Submitter_Email__c); 
            
            //ccAddresses
            List<String> ccAddresses = new List<String>();
            if(waiver.InitiatedBy__c != null && String.isNotBlank(waiver.InitiatedBy__r.email)) ccAddresses.add(waiver.InitiatedBy__r.email); //add RM's email to cc
            
            //get principal of the school
            Contact principal = [SELECT id, name, email FROM Contact WHERE AccountId =: waiver.Account__c and Current_Principal_Of_This_School__c = true LIMIT 1];
            if (principal != null && String.isNotBlank(principal.email) ){
                if(!toAddresses.contains(principal.email)) ccAddresses.add(principal.email); //add principal's email to cc if it does not exist in toAddresses
            }
            
            //get Email Template Name based on MetaData - Email Template Mapping
            Map<String, Email_Template_Mapping__mdt> emailTemplateMap = EmailController.getEmailTemplateMappings();
            String masterLabel = 'ServiceWaiverAcknowledgement';
            String templateName = '';
            if(emailTemplateMap.containsKey(masterLabel)) {
                templateName = emailTemplateMap.get(masterLabel).DeveloperName;
            }
            
            EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE developerName =: templateName];
            
            //prepare string waivedOption to replace html with  option selected within form: Default Categories, Firewall, Web Security. 
            
            List<String> listOptions = new List<String>();
            if (waiver.Default_Categories_Removed__c!=null && waiver.Default_Categories_Removed__c.toLowerCase() == 'yes') listOptions.add('Default Categories');
            if (waiver.Firewall_Removed__c!=null && waiver.Firewall_Removed__c.toLowerCase() == 'yes') listOptions.add('Firewall');
            if (waiver.Web_Security_Removed__c!=null && waiver.Web_Security_Removed__c.toLowerCase() == 'yes') listOptions.add('Web Security');
            String waivedOptions = '';
            waivedOptions = String.join(listOptions, ', ');
            
            
            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('[hyperlink]', waiver.Waiver_Link__c);
            htmlBody = htmlBody.replace('[submitterName]', waiver.Submitter_Name__c);
            htmlBody = htmlBody.replace('{!Contact.FirstName}', waiver.Contact__r.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('[waivedOptions]', waivedOptions);
            
            
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('[hyperlink]', waiver.Waiver_Link__c);
            plainBody = plainBody.replace('[submitterName]', waiver.Submitter_Name__c);
            plainBody = plainBody.replace('{!Contact.FirstName}', waiver.Contact__r.FirstName);
            plainBody = plainBody.replace('[waivedOptions]', waivedOptions);
            
            
            EmailController.sendEmail(waiver.Contact__c, waiver.Account__c, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody);    
        
        
    }
    

    @AuraEnabled() //LWC Service Waiver will call this method to send email
    public static string sendWaiverRequestEmail(ID contactId, ID accountId, ID userId, String hyperlink, String additionalNote){
        try{
            Contact contact = [SELECT id, FirstName, Email FROM Contact WHERE Id =: contactId];
            Account account = [SELECT id, FortiGate_Rollout_Completed_Date__c FROM Account WHERE Id =: accountId];
            User user = [SELECT id, Name FROM User WHERE Id =: userId];

            //toAddresses
            List<String> toAddresses = new List<String>();
            if(contact != null && String.isNotBlank(contact.Email)) toAddresses.add(contact.Email); //add designated contact's email to address
            
            //ccAddresses - no cc required, but leave it as empty list
            List<String> ccAddresses = new List<String>();
            
            //get Email Template Name based on MetaData - Email Template Mapping
            Map<String, Email_Template_Mapping__mdt> emailTemplateMap = EmailController.getEmailTemplateMappings();
            String masterLabel = '';
             if (account.FortiGate_Rollout_Completed_Date__c != null){
                masterLabel = 'ServiceWaiverAfterUpdate';
            } else {
                masterLabel = 'ServiceWaiverDuringUpdate';
            }
            String templateName = '';
            if(emailTemplateMap.containsKey(masterLabel)) {
                templateName = emailTemplateMap.get(masterLabel).DeveloperName;
            }
            
            EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE developerName =: templateName];
            
            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('[hyperlink]', hyperlink); //using js in LWC to concatenate hyperlink
            htmlBody = htmlBody.replace('[additionalNote]', additionalNote); //additional note comes from js in LWC
            htmlBody = htmlBody.replace('{!Contact.FirstName}', contact.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('[relationshipManagerName]', user.Name);
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('[hyperlink]', hyperlink); //using js in LWC to concatenate hyperlink
            plainBody = plainBody.replace('[additionalNote]', additionalNote); //additional note comes from js in LWC
            plainBody = plainBody.replace('{!Contact.FirstName}', contact.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('[relationshipManagerName]', user.Name);
            
            EmailController.sendEmail(contactId, accountId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody);    
        
            return 'Successfully sent email to ' + contact.Email;
        
        } catch (System.Exception ex) {
			return ex.getMessage();
		}
        
        
    }
}