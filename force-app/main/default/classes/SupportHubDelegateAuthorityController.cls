/**
* @author n4l developer
* @date 2021-05-03
* @description Controller for the SupportHubDelegate page
*
* CHANGE LOG
**/
public without sharing class SupportHubDelegateAuthorityController { 
    
    //Declare and initialize containers.
    public Id campaignId {get;set;}
    public Id accountId {get;set;}
    public Boolean noEmailDomain {get;set;}
    public String webSiteLink {get;set;}
    public SupportHubDelegateAuthorityController() {
        initializeVariables();

    }
  public ErrorFlags errors {
        get {
            if (errors == null) {
                errors = new ErrorFlags();
            }
            return errors;
        }
        set;
    }
   
 public Registration registration {
        get {
            if (registration == null) {
                registration = new Registration();
            }
            return registration;
        }
        set;
    }
 public Account selectedSchool {
        get {
            if (selectedSchool == null){
                selectedSchool = new Account(); 
            }
            return selectedSchool;
        }
        set;
    }
 
    public void initializeVariables() {
        webSiteLink =Helper.supportHubURL();
        getSelectedValue = 'Office Administrator';
        registration = null;
        selectedSchool = null;
        errors = null;
        registration = null;
        errors = null;
        campaignId = ApexPages.currentPage().getParameters().get('camid')=='null'? null:ApexPages.currentPage().getParameters().get('camid');
        accountId = ApexPages.currentPage().getParameters().get('accid')=='null'? null:ApexPages.currentPage().getParameters().get('accid');
        selectSchool();
        system.debug('accid & camid='+accountId+'  '+campaignId);
    }
    
    public void selectSchool() {
        
        noEmailDomain = false;
        
        if (accountId != null) {
            
            try {
                
                // Query for the selected school
                selectedSchool = [SELECT Name, Email_Domain__c FROM Account WHERE Id = :accountId];
                
                if (String.isBlank(selectedSchool.Email_Domain__c)){
                    noEmailDomain = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Support_Hub_No_Email_Domain_Error));
                }
            }
            catch (Exception ex) {
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Support_Hub_Signup_Error_Selecting_School));
                selectedSchool = null;
            }
        } 
        else {
            selectedSchool = null;
            registration = null;
            errors = null;
        }
    }
    public PageReference doDelegate() {
        
        // Clear the errors, we need to re-evaluate them
        errors = null;
        String addEmail;
        if(selectedSchool.Email_Domain__c != null){
            addEmail = registration.email + '@' + selectedSchool.Email_Domain__c;
        }else{
            addEmail = registration.email;
        }
        
        if (!validateUserInput()){
            List<Contact> contacts = [SELECT Id, FirstName, LastName, AccountId, Email, MobilePhone, Phone, UserOrigin__c FROM Contact WHERE Email =: addEmail ];
                Contact relatedContact;
            N4L_Role_Authority_Match__mdt roleAuthorityMDT = helper.getAuthorityMatchBySingleRole(this.getSelectedValue);
                if(contacts.isEmpty()){
                    relatedContact = new Contact(
                        FirstName = registration.firstName.capitalize(),
                        LastName = registration.lastName.capitalize(),
                        AccountId = accountId,
                        Email = addEmail,
                        MobilePhone = registration.mobile,
                        Phone = registration.phone,
                        UserOrigin__c = 'N4L Invitation - Delegate Person',
                        created_from__c = 'Principal Delegation',
                        Periodic_Survey_Emails__c = roleAuthorityMDT.Is_Operational_emails_checked__c,
                        Outage_notifications__c = roleAuthorityMDT.Is_Outage_notifications_checked__c,
                        Current_N4L_product_and_service_updates__c = roleAuthorityMDT.Is_periodic_emails_checked__c
                    );
                    try{
                        insert relatedContact;
                        List<AccountContactRelation> accountContactRelationList = [SELECT Id,Roles,Authority__c FROM AccountContactRelation WHERE AccountId =:accountid AND ContactId =:relatedContact.id];
                        if(!accountContactRelationList.isEmpty()){
                            AccountContactRelation updateacr = accountContactRelationList[0];
                            
                            updateacr.Roles=this.getSelectedValue;
                            updateacr.Authority__c = roleAuthorityMDT.Default_authority_types__c;
                            update updateacr;
                        }
                    }catch (Exception ex) {
                
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to create a contact, please contact your administrator'));
                }
                    
                } else {
                    //copy the logic from original code above
                    relatedContact = contacts[0]; 
                    
                    // Update the contact with the new details
                    relatedContact.FirstName = registration.firstName.capitalize();
                    relatedContact.LastName = registration.lastName.capitalize(); 
                    
                    // Update the mobile phone value if it has a value
                    if (String.isNotBlank(registration.mobile)) {
                        relatedContact.MobilePhone = registration.mobile;
                    }
                    
                    // Uplodate the phone value if it has a value
                    if (String.isNotBlank(registration.phone)) {
                        relatedContact.Phone = registration.phone;
                    }
                    update(relatedContact);
                }
            
                   //-------------------------------05.08.2021 Delegate issue fixed for existing user who dont have contact manage authority------
            try{
            List<AccountContactRelation> accountContactRelationList = [SELECT Id,Roles,Authority__c FROM AccountContactRelation WHERE AccountId =:accountid AND ContactId =:relatedContact.id];
            AccountContactRelation updateacr = accountContactRelationList[0];
            if(!updateacr.Roles.contains(getSelectedValue)){
                updateacr.Roles = updateacr.Roles + ';'+ getSelectedValue;
                updateacr.Authority__c = 'Manage contacts' + ';' + updateacr.Authority__c;
                update updateacr;
                
            }
            }catch (Exception ex) {
                
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'no issue, unit test only'));
                }
            //-----------------------end------------------------------------
            
            Campaign_Account__c RelatedCampaignAccount = getRelatedCampaignAccount();
            Campaign_Account_Contact__c RelatedCampaignAccountContact = getRelatedCampaignAccountContact(relatedContact.id,RelatedCampaignAccount.id); 
            String partialURL = Helper.supportHubURL();
            RelatedCampaignAccountContact = [SELECT id, Campaign__c, Contact__c, Contact__r.Email, Contact__r.FirstName, Campaign_Account__r.Account__c 
            FROM Campaign_Account_Contact__c WHERE id =: RelatedCampaignAccountContact.id];
            MethodResponse mrs = CampaignController.campaign_email_actions(RelatedCampaignAccountContact, partialURL, true); 
            final PageReference target = new PageReference(partialURL + 'request-authorisation?p=delegate-completed');
            target.setRedirect(true);
            return target;
        }
        
        return null;
    }
    public Campaign_Account_Contact__c getRelatedCampaignAccountContact(Id cid,Id caid){
        Campaign_Account_Contact__c RelatedCAC = new Campaign_Account_Contact__c(
                                    Campaign__c = campaignId, 
                                    Account__c = accountId, 
                                    Contact__c = cid, 
                                    Campaign_Account__c = caid, 
                                    External_Id__c = String.valueof(campaignId) + String.valueof(accountId) + String.valueof(cid));
       upsert RelatedCAC External_Id__c; 
       return RelatedCAC;
    }
    
    public Campaign_Account__c getRelatedCampaignAccount(){
        List<Campaign_Account__c> relatedCAs = [select id,Account__c,Campaign__c from Campaign_Account__c where Account__c=:accountId and Campaign__c =:campaignId];
        if(relatedCAs.isEmpty()){
            Campaign_Account__c newCA = new Campaign_Account__c(Account__c = accountId,Campaign__c = campaignId); 
            insert newCA;
            return newCA;
            
        }else{
            return relatedCAs[0];
        }      
    }
    public Boolean validateUserInput() {
        
        
        errors.firstNameErrors = String.isBlank(registration.firstName) ? Label.Support_Hub_Signup_First_Name_Error : null;
        errors.lastNameErrors = String.isBlank(registration.lastName) ? Label.Support_Hub_Signup_Last_Name_Error : null;
        errors.emailErrors = String.isBlank(registration.email) ? Label.Support_Hub_Signup_No_Email_Error : null;
        
        if (registration.email != null && registration.email.contains('@') && selectedSchool.Email_Domain__c != null) {
            errors.emailErrors = Label.Support_Hub_Invalid_Email_Address;
        }
        
        if(campaignId==null || accountId==null){
            errors.otherErrors='An unexpected error occurred, Please Contact Site Admin.'; 
        }
        // Validate the phone
        if (String.isNotBlank(registration.mobile)) {
            // If the mobile isn't in correct format, raise an error
            if (!Pattern.matches('[0]\\d\\d?\\d?\\d?\\s\\d\\d\\d\\s\\d+', registration.mobile)) {
                // Apply the error
                errors.phoneErrors = Label.Support_Hub_Signup_Mobile_Format_Error;
                errors.mobileHasError = true;
            }
        }
        
        // Validate the phone
        if (String.isNotBlank(registration.phone)) {
            // If the mobile isn't in correct format, raise an error
            if (!Pattern.matches('[0]\\d\\d?\\d?\\s\\d\\d\\d\\s\\d+', registration.phone)) { 
                
                if (errors.phoneErrors != null) {
                    errors.phoneErrors += '<br/>' + Label.Support_Hub_Signup_Phone_Format_Error;
                }
                else {
                    errors.phoneErrors = Label.Support_Hub_Signup_Phone_Format_Error; 
                }
                errors.phoneHasError = true;
            }
        }
        
        // Validate the email
        if (String.isNotBlank(registration.email) && selectedSchool.Email_Domain__c == null) {
            // If the email isn't in correct format, raise an error
            if (!Pattern.matches('^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$', registration.email)) { 
                
                if (errors.emailErrors != null) {
                    errors.emailErrors += '<br/>' + Label.Support_Hub_Invalid_Email_Address;
                }
                else {
                    errors.emailErrors = Label.Support_Hub_Invalid_Email_Address; 
                }
            }
        }
        
        return 
            String.isNotBlank(errors.firstNameErrors) || 
            String.isNotBlank(errors.lastNameErrors) || 
            String.isNotBlank(errors.emailErrors) || 
            String.isNotBlank(errors.otherErrors) ||
            String.isNotBlank(errors.phoneErrors); //||  
        //errors.termsNotAccepted;
    }
       
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description Wrapper class to hold the details of the user registration
**/
    public class Registration {
        
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String email {get;set;}
        public String mobile {get;set;}
        public String phone {get;set;}
        //public Boolean acceptTerms {get;set;}
    }
    
    /**
*   @author David Catindoy (@cloudinit.nz)
*   @description Wrapper class to hold error boolean flags
**/
    public class ErrorFlags {
        
        public String firstNameErrors {get;set;}
        public String lastNameErrors {get;set;}
        public String emailErrors {get;set;}
        public String phoneErrors {get;set;}
        public String otherErrors {get;set;}
        public Boolean mobileHasError {get;set;}
        public Boolean phoneHasError {get;set;}
    }
    public String getSelectedValue {get; set;}
    public static List<SelectOption> getSelectOptionListByField() {
        
        List<SelectOption> listOptions = new List<SelectOption>();
        for(N4L_Business_Contact_Role__mdt contactRole : [SELECT ID, MasterLabel FROM N4L_Business_Contact_Role__mdt where MasterLabel !='Principal' ]) {
            listOptions.add(new SelectOption(contactRole.MasterLabel , contactRole.MasterLabel ));  
        }
        return listOptions;
    } 
}