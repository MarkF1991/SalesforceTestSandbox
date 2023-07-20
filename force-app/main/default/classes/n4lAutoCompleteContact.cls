/** 
     * @Date: June 15, 2021
     * in order to separate the functionality from internal front page,
     * a separate class is needed. this class is based on N4LFormScreen
**/
public without sharing class n4lAutoCompleteContact {

    /** 
     * String objectName - the object of the record
     * String fieldName - field name to be search
     * String value - value inputted in the search
    **/
    @AuraEnabled(cacheable=false)
    public static List<SObJectResult> getResults(String ObjectName, String fieldName, String value, String accountId) {
        //system.debug('getResults parameters 1 objectname= :'+ObjectName+' 2 fieldName= :'+fieldName+' 3 value= :'+value+' 4 accountId= :'+accountId);
        
        try {
            List<SObJectResult> sObjectResultList = new List<SObJectResult>();
            Set<Id> directContactId = new Set<Id>();
            for(AccountContactRelation acr : [SELECT Id,ContactId,IsActive FROM AccountContactRelation WHERE AccountId = :accountId]){
                if(acr.IsActive){
                directContactId.add(acr.ContactId);
                }
            }
            if(String.isNotEmpty(value)) {            
                value = value.trim();

                Set<Id> acctIdSet = new Set<Id>();
                Account acct = null;

                // get records based on account conditions
                if(!String.isEmpty(accountId)) {
                   //by lh test: 
                    //acctIdSet.add(accountId);//add by lh
                    // Get parent id and host school
                    acct = [SELECT Id,ParentId,Host_School__c FROM Account WHERE Id = :accountId];

                    if(acct.ParentId != null) {acctIdSet.add(acct.ParentId);}
                    if(acct.Host_School__c != null) {acctIdSet.add(acct.Host_School__c);}

                    // get child accounts
                    for(Account childAccount : [SELECT Id FROM Account WHERE ParentId = :accountId OR Host_School__c = :accountId]) {
                        acctIdSet.add(childAccount.Id);
                    }
                    
                    // get related ict provider which is not equal to the current account
                    for(Related_School_ICTProvider__c provider : [SELECT Id,School__c,ICT_Provider__c FROM Related_School_ICTProvider__c
                                                                    WHERE School__c = :accountId OR ICT_Provider__c =:accountId]) {
                        if(provider.School__c != accountId) {acctIdSet.add(provider.School__c);}
                        if(provider.ICT_Provider__c != accountId) {acctIdSet.add(provider.ICT_Provider__c);}
                    }
                }
               List<AccountContactRelation> accRelList = new List<AccountContactRelation>();
               string soql = 'Select Id,Email,Secondary_Email__c,account.name,Name FROM Contact WHERE Email LIKE \'%' + value + '%\'';
               string detail='';
                    if(acctIdSet != null) {
                        List<Id> acctIds = new List<Id>(acctIdSet);
                        soql += ' AND AccountId IN :acctIds';
                        //system.debug('Final soql string= :'+soql);
                        for(Contact con : Database.Query(soql)) {
                            if(!directContactId.contains(con.id)){
                                
                           detail=con.email+' ('+con.name+'  '+' from '+con.account.name+')';
                           sObjectResultList.add(new SObjectResult(con.name, con.Id, con.email,con.Secondary_Email__c,con.account.name,detail));
                            }
                    
                }
                    }
                /** remove direct contact relationship
                    String newSearchText = '%'+value+'%';
                    accRelList = [SELECT Id,ContactId,account.name,contact.name,contact.email,contact.Secondary_Email__c FROM AccountContactRelation WHERE contact.email like:newSearchText and AccountId = :accountId];
                    system.debug('fieldName empty set = Name soql string= :'+soql);
                    system.debug('fieldName empty accRelList= :'+accRelList);
                    if(accRelList.size()>0){
                        for(AccountContactRelation accRel : accRelList) {
                            detail='Direct Contact Name : '+accRel.contact.name+'  '+' -> School : '+accRel.account.name;
                            sObjectResultList.add(new SObjectResult(accRel.contact.name, accRel.ContactId, accRel.contact.email,accRel.contact.Secondary_Email__c,accRel.account.name,detail));
                        }
                    }**/
            }
            //system.debug('getResult sObjectResultList= :'+sObjectResultList);
            return sObjectResultList;
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }
    /** 
     * @Date: January 26, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that searches result within school
    **/
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getResultFromExistingSchool(String value, String accountId) {
        try {
            List<SObJectResult> sObjectResultList = new List<SObJectResult>();

            if(String.isNotEmpty(value)) {      
                value = value.trim();      
                String soql = 'Select Id,Contact.Email,Contact.Secondary_Email__c,Contact.Name,ContactId FROM AccountContactRelation WHERE (Contact.Email LIKE \'%' + value + '%\''+' OR Contact.Secondary_Email__c LIKE \'%' + value + '%\''+' OR Contact.FirstName LIKE \'%' + value + '%\''+' OR Contact.LastName LIKE \'%' + value + '%\''+' OR Contact.Name LIKE \'%' + value + '%\')';
                soql += ' AND AccountId = :accountId';

                for(sObject so : Database.Query(soql)) {
                    String fieldvalue = (String) so.getSObject('Contact').get('Name');
                    String email = (String) so.getSObject('Contact').get('Email');
                    String secondaryEmail = (String) so.getSObject('Contact').get('Secondary_Email__c');
                    Id recId = (Id) so.get('ContactId');
                    ///disable for now
                    ///sObjectResultList.add(new SObjectResult(fieldvalue, recId, email,secondaryEmail));
                }
            }
            return sObjectResultList;
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }
    public class SObJectResult {

        @AuraEnabled public String recName;
        @AuraEnabled public Id recId;
        @AuraEnabled public String recEmail;
        @AuraEnabled public String recSecondaryEmail;
        @AuraEnabled public String recAccountName;
        @AuraEnabled public String recDetail;
        @AuraEnabled public Boolean showSecondaryEmail;

        public SObJectResult(String recNameTemp, Id recIdTemp,String recEmailTemp,String recSecondaryEmailTemp,String recAccountNameTemp,String recDetailTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
            recEmail = recEmailTemp;
            recDetail=recDetailTemp;
            recAccountName=recAccountNameTemp;
            recSecondaryEmail = recSecondaryEmailTemp;
            showSecondaryEmail = !String.isEmpty(recSecondaryEmail) ? true : false;
        }
    }
    
    /** 
     * @Date: January 26, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that adds new contact
    **/
    @AuraEnabled (cacheable = false)
    public static Object addNewContact(Object newEmail, Object firstName, Object lastName, Object jobTitle,Object mobilePhone,
        String accountId,String recordId,Boolean isReplace, String replaceValue,Boolean isInherit){
        //system.debug('lh addNewContact newEmail:'+newEmail);
       // system.debug('lh addNewContact firstName:'+firstName);
       // system.debug('lh addNewContact lastName:'+lastName);
      //  system.debug('lh addNewContact jobTitle:'+jobTitle);
      //  system.debug('lh addNewContact isReplace:'+isReplace);
     //   system.debug('lh addNewContact replaceValue:'+replaceValue);
    //    system.debug('lh addNewContact isInherit:'+isInherit);
        Contact objContact = null;

        try{
            // change old contact email address
            if(isInherit) {
                AccountContactRelation oldRelation = [SELECT Id,ContactId,Contact.Email FROM AccountContactRelation WHERE Id = :recordId];
                Contact con = new Contact(Id=oldRelation.ContactId, Email=oldRelation.Contact.Email);

                // check if contact is related to 1 account only, update email address
                String uuid = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));
                String emailShortenStr = con.Email.SubStringBefore('.com');
                //('##### '+uuid);
                con.Email = emailShortenStr+'.com'+uuid.SubString(0,8)+uuid.SubString(8,12)+uuid.substring(20);
                update con;
            }
            
            //if(Boolean.valueOf(createSupportHubUser) == true && String.isEmpty((String) newEmail)) {
               //throw new N4LFormScreenException(Label.Screen_NoEmailSupportHub);
            //} else {
                objContact = new Contact();

                if(!String.isEmpty(recordId) && !isReplace) {
                    AccountContactRelation accRelation = [SELECT ContactId FROM AccountContactRelation WHERE Id = :recordId];
                    objContact.Id = accRelation.ContactId;
                }

                // check if outaage notification is uncheck and check whether its the only default checked for an account contact relation
                /*
                if((!(Boolean) outageNotif) && objContact.Id != null) {
                    Account acct = [SELECT RecordType.DeveloperName FROM Account WHERE Id =:accountId];

                    if(acct.RecordType.DeveloperName == N4LStringConstants.ACCOUNT_RECTYPE_SCHOOL) {
                        List<AccountContactRelation> accRelations = [SELECT Id FROM AccountContactRelation 
                                                                    WHERE AccountId = :accountId
                                                                    AND ContactId != :objContact.Id 
                                                                    AND Contact.Outage_notifications__c = true];
                        if(accRelations.isEmpty()) {
                            throw new N4LFormScreenException(Label.Screen_OutageNotif);
                        }
                    }
                } */

                // update inactive checkbox
                /*
                if((Boolean) isActive) {
                    objContact.Inactive_Contact_Record__c = false;
                } else if(!(Boolean) isActive && objContact.Id != null) {
                    List<AccountContactRelation> contactRelationList = [SELECT Id,isActive,ContactId FROM AccountContactRelation 
                    WHERE ContactId = :objContact.Id AND isActive = true];

                    if(contactRelationList.isEmpty()) {
                        objContact.Inactive_Contact_Record__c = true;
                    }
                }*/
                // default active
                objContact.Inactive_Contact_Record__c = false;
                objContact.Email = (String) newEmail;
                //objContact.Secondary_Email__c = (String) secondaryEmail;
                objContact.LastName = (String) lastName;
                objContact.FirstName = (String) firstName;
                objContact.Title = (String) jobTitle;
                objContact.MobilePhone = (String) mobilePhone;
                //objContact.Outage_notifications__c = (Boolean) outageNotif;
                //objContact.Periodic_Survey_Emails__c = (Boolean) periodicEmail;
                //objContact.Current_N4L_product_and_service_updates__c = (Boolean) operational;
               // objContact.System_Accessible__c = (String) systemAccessible;

                if(objContact.Id == null) {
                    objContact.AccountId = accountId;
                }

                upsert objContact;
            //}
        }  catch (Exception ex) {
            handleException(ex);
        }

        return objContact;
    }
    public static string getAuthorityByRoles(String roleString){
        set<String> authorityValueSet = new set<String>();
        for(N4L_Role_Authority_Match__mdt ram : [SELECT Id,MasterLabel,Default_authority_types__c
                                                 FROM N4L_Role_Authority_Match__mdt ORDER BY Role_Priority_Level__c DESC]){
                                                     if(roleString.contains(ram.MasterLabel) && ram.Default_authority_types__c!=null){
                                                         authorityValueSet.addall(ram.Default_authority_types__c.split(';'));
                                                     }                                         
                                                 }
       list<String> authorityString =  new list<String>(authorityValueSet); 
       return String.join(authorityString, ';');
    }
    /** 
     * @Date: January 21, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves related name of an object
     * @Params:
     * String recordId - the id of the record
     * String contactId - the contact id related to a record
     * String objectName - the object api name
    **/
    @AuraEnabled (cacheable = false)
    public static void saveRelationship(String recordId,String accountId,String contactId,Object isActive, 
        Object canProvideSiteAccess, Object roles, Object authorities,Object createSupportHubUser,
        String currentRecordId,Boolean isReplace, String replaceValue,Boolean isChangeOldEmail, Boolean isInherit,
        Object systemAccessible){
        try{
            systemAccessible = systemAccessible == null ? '' : systemAccessible;
            AccountContactRelation acctConRel = new AccountContactRelation();

            if(String.isEmpty(contactId)) {
                throw new N4LFormScreenException('Please search a contact first before saving a relationship.');
            } else {
                if(isChangeOldEmail) {
                    acctConRel.ContactId = contactId;
                    acctConRel.AccountId = accountId;        
                } else {
                    List<AccountContactRelation> existingConRel = [SELECT Id,AccountId,ContactId FROM AccountContactRelation 
                    WHERE ContactId = :contactId AND AccountId = :accountId];                

                    if(!existingConRel.isEmpty()) {
                        acctConRel.Id = existingConRel[0].Id;
                    } else {
                        acctConRel.ContactId = contactId;
                        acctConRel.AccountId = accountId;        
                    }
                }
            }
            
            // populate fields for account contact relation
            acctConRel.isActive = (Boolean) isActive;
            acctConRel.Can_Provide_Site_Access__c =(Boolean) canProvideSiteAccess;
            acctConRel.Roles = (String) roles;
            acctConRel.Authority__c = getAuthorityByRoles((String) roles);//remove for now

            // check if its the only principal
            if(!isReplace) {
                List<AccountContactRelation> accRelations = [SELECT Id,ContactId FROM AccountContactRelation WHERE AccountId = :accountId
                    AND Roles includes ('Principal') AND isActive = true AND ContactId != :contactId];

                if(accRelations.isEmpty()) {
                    Account acct = [SELECT RecordType.DeveloperName FROM Account WHERE Id =:accountId];

                    if(acct.RecordType.DeveloperName == N4LStringConstants.ACCOUNT_RECTYPE_SCHOOL) {
                        if(acctConRel.Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL) && !acctConRel.isActive) {
                            throw new N4LFormScreenException(Label.Screen_PrincipalActive);
                        } else if(!acctConRel.Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL)) {
                            if(acctConRel.Id != null) {
                                // check if old roles has principal
                                List<AccountContactRelation> oldAcctConRel = [SELECT Id,Roles FROM AccountContactRelation wHERE Id = :acctConRel.Id LIMIT 1];
    
                                if(!oldAcctConRel.isEmpty()) {
                                    if(oldAcctConRel[0].Roles != null && oldAcctConRel[0].Roles != ''){
                                        if(oldAcctConRel[0].Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL)) {
                                            throw new N4LFormScreenException(Label.Screen_PrincipalActive);
                                        }        
                                    }
                                }
                            }
                        }
                    }
                }
            }

            upsert acctConRel;

            // deactivate current role if any
            if(!String.isEmpty(currentRecordId)) {
                AccountContactRelation oldAcctConRel = [SELECT Id, isActive FROM AccountContactRelation WHERE Id = :currentRecordId];
                oldAcctConRel.isActive = false;
                update oldAcctConRel;
            }
            
            // change old contact email address
            if(isInherit) {
                AccountContactRelation oldRelation = [SELECT Id,isActive,ContactId,Contact.Email FROM AccountContactRelation WHERE Id = :recordId];
                Contact con = new Contact(Id=oldRelation.ContactId, Email=oldRelation.Contact.Email);

                String uuid = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));
                String emailShortenStr = con.Email.SubStringBefore('.com');
                con.Email = emailShortenStr+'.com'+uuid.SubString(0,8)+uuid.SubString(8,12)+uuid.substring(20);
                update con;

                // deactive old contact relationship
                oldRelation.isActive = false;
                update oldRelation;

                List<User> oldUserList = [SELECT Id FROM User WHERE ContactId = :con.Id];

                if(oldUserList.isEmpty()) {
                    createSupportHubUser(contactId,(String) systemAccessible);
                }
            }

            // create support hub user function
            if(Boolean.valueOf(createSupportHubUser) == true && !isInherit) {
                //createSupportHubUser(contactId,(String) systemAccessible);
                SupportHubInviteSignupController.InviteToCreateCustomerUser(contactId,'N4L Invitation - Default');
            }
        }  catch (Exception ex) {
            handleException(ex);
        }
    } 
    /** 
     * @Date: January 21, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that creates the support hub user.
     * @Params:
     * String contactId - the contact id related to a record
    **/
    private static void createSupportHubUser(String contactId, String systemAccessible) {
        Map<String, String> resMap = New Map<String, String>(); //for adding into list result

        List<Contact> contacts =  [SELECT Id, FirstName, LastName, Title, Phone, MobilePhone, Email,AccountId, Account.Name FROM Contact WHERE Id =: contactId];
		
        //error
        if(contacts.isEmpty()){
            if (String.isNotBlank(contactId)){
                throw new N4LFormScreenException('Could not find a Contact record with id = ' + contactId);
            } else {
                throw new N4LFormScreenException('Missing contactId');
            }
        }

        //get contact successful
        Contact contact = contacts[0];
        
        // Otherwise, we can start generating a new user
        Profile profileObj = [SELECT id, Name FROM Profile WHERE Name = 'Support Hub Community Member User - Login Licence MFA'];
        User newUser = new User(
            profileId = profileObj.id,
            FirstName = contact.FirstName, 
            LastName = contact.LastName, 
            Username = contact.Email, 
            Email = contact.Email, 
            MobilePhone = contact.MobilePhone, 
            Phone = contact.phone,
            EmailEncodingKey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'Pacific/Auckland',
            alias = contact.firstName.left(1) + contact.lastName.left(5),
            CompanyName = contact.Account.Name,
            ContactId = contact.Id,
            Title = contact.Title,
            approved_Email_With_Unmatch_Email_Domain__c = true,
            UserPermissionsFilteringPortalUser__c = systemAccessible.contains('Fortiportal') ? true: false,
            UserPermissionsNMSUser__c = systemAccessible.contains('Network Management System') ? true: false,
            UserPermissionsSchoolReportingUser__c = systemAccessible.contains('Reporting') ? true: false                
        );

        // Make the Nickname Unique
        Integer randomNumber = Integer.valueof((Math.random() * 10000)); //4 digit random number
        String nickname = contact.firstName.toLowerCase() + '.' + contact.lastname.toLowerCase();
        newUser.CommunityNickname = nickname.left(36) + String.valueOf(randomNumber); //user.CommunityNickname allows maximum 40 characters
        
        try {
            insert newUser;
        } catch (Exception ex) {
            throw new N4LFormScreenException(ex.getMessage());
        }
    }
    /** 
     * @Date: July 5, 2021
     * @Author: n4lSalesroce@gmail.com
     * @Description: Method that determines if showing add new contact button
     * @Params:
     * String accountId - the current school Id
    **/
    @AuraEnabled (cacheable = false)
    public static Boolean checkShowAddNewContact(String accountId){
        User loginUser = [SELECT Id,ContactId,AccountId,Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            List<N4L_ManageContactsProfile__mdt> allowedProfiles = [SELECT Id FROM N4L_ManageContactsProfile__mdt WHERE MasterLabel = :loginUser.Profile.Name];

            if(!allowedProfiles.isEmpty()) {
                return true;
            } else{
                if(loginUser.ContactId != null) {
                    if(!String.isEmpty(accountId)) {
                        //check if login user belongs (primary) current account.
                        List<AccountContactRelation> relationOfLoginContact = [SELECT Id,Authority__c,Roles FROM AccountContactRelation 
                                                                            WHERE AccountId = :accountId AND ContactId = :loginUser.ContactId];                        
                        if(!relationOfLoginContact.isEmpty()) {
                            AccountContactRelation loginUserRelation = relationOfLoginContact[0]; 
                            if((loginUserRelation.Roles!=null && loginUserRelation.Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL)) 
                                           ||(loginUserRelation.Authority__c != null && 
                                              loginUserRelation.Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT))){
                                                  return true;
                                              }
                        }
                    }  
                }     
                return false;
            }
    }
    /** 
     * @Date: January 28, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that determines if contact details should be editable or not
     * @Params:
     * String recordId - the id of the record
     * String accountId - the contact id related to a record
    **/
    @AuraEnabled (cacheable = false)
    public static List<Boolean> validateContactFieldEdits(String recordId,String accountId){
           List<Boolean> disableFields = new List<Boolean>();
           Boolean disableContact=true;
           Boolean disableRelation=true;
           try {
            
            
            User loginUser = [SELECT Id,ContactId,AccountId,Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            List<N4L_ManageContactsProfile__mdt> allowedProfiles = [SELECT Id FROM N4L_ManageContactsProfile__mdt WHERE MasterLabel = :loginUser.Profile.Name];

            if(!allowedProfiles.isEmpty()) {
                disableContact=false;
                disableRelation=false;
            } else {
                if(loginUser.ContactId != null) {
                    if(!String.isEmpty(accountId)) {
                        //check if login user belongs (primary) current account.
                        List<AccountContactRelation> relationOfLoginContact = [SELECT Id,Authority__c,Roles FROM AccountContactRelation 
                                                                            WHERE AccountId = :accountId AND ContactId = :loginUser.ContactId];                        
                        if(!relationOfLoginContact.isEmpty()) {
                            AccountContactRelation loginUserRelation = relationOfLoginContact[0];
                            //check authority and warning or error for email domain
                            //then check if login user is updating own record
                            if(!String.isEmpty(recordId)) {
                                AccountContactRelation relatedAccountRelation = [SELECT Id,ContactId,Contact.AccountId FROM AccountContactRelation WHERE Id = :recordId];
                                //user can edit own record
                                if(relatedAccountRelation.ContactId == loginUser.ContactId) {
                                    disableContact=false;
                                    disableRelation=false;
                                } else {  // if it is not own record then check authority.
                                       //if edit record is a primary contact under current account
                                    if(relatedAccountRelation.Contact.AccountId == accountId) {
                                        if((loginUserRelation.Roles!=null && loginUserRelation.Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL)) 
                                           ||(loginUserRelation.Authority__c != null && 
                                              loginUserRelation.Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT))){
                                                disableContact=false;
                                                disableRelation=false;  
                                              }else{
                                                disableContact=true;
                                                disableRelation=true;
                                              }
                                    } else {
                                         disableContact=true;
                                         disableRelation=false;
                                        /*
                                        //check if login user also has rights under edit record primary account.
                                        List<AccountContactRelation> accRelList = [SELECT Id,Roles,Authority__c FROM AccountContactRelation 
                                                                                    WHERE ContactId = :loginUser.ContactId 
                                                                                    AND AccountId = :relatedAccountRelation.Contact.AccountId];
                                        if(!accRelList.isEmpty()) {
                                             if((accRelList[0].Roles!=null && accRelList[0].Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL)) 
                                           ||(accRelList[0].Authority__c != null && 
                                              accRelList[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT))){
                                                disableContact=true;
                                                disableRelation=false;  
                                              }else{
                                                disableContact=true;
                                                disableRelation=false;
                                              }
                                        }else{ // login user does not belongs to shall not show add button.
                                                disableContact=true;
                                                disableRelation=true;
                                              } */
                                    }    
                                }
                            } else {  // recordId is null so it is add new
                                if((loginUserRelation.Roles!=null && loginUserRelation.Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL)) 
                                           ||(loginUserRelation.Authority__c != null && 
                                              loginUserRelation.Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT))){
                                                disableContact=false;
                                                disableRelation=false;  
                                              }else{
                                                disableContact=true;
                                                disableRelation=true;
                                              }
                            }

                            
                        }
                    }
                }
            }
            disableFields.add(disableContact);
            disableFields.add(disableRelation);   
            return disableFields;
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }
    @AuraEnabled (cacheable = false)
    public static Boolean checkEmailDuplicates(String email,String recordId,Boolean emailEditable){
       // system.debug('checkEmailDuplicates pars: email = '+email +'+recordId='+recordId+'+emailEditable='+emailEditable);
        try{
            if(!String.isEmpty(email)){
                // String newSearchText = email+'%';
                List<User> userList = [SELECT Id FROM User WHERE ContactId = NULL AND Username = :email];

                // check if email has been use for the internal users
                if(userList.isEmpty()) {
                    List<Contact> contactList = [SELECT Id,email FROM Contact WHERE email =:email];
                    //system.debug('exist contact size :'+contactList.size());
                    if(!String.isEmpty(recordId)) {
                        AccountContactRelation accRelation = [SELECT ContactId FROM AccountContactRelation WHERE Id = :recordId];
                        
                        // check if email is used for other contacts
                        if(!emailEditable) {
                            contactList = [SELECT Id,Secondary_Email__c FROM Contact WHERE (Email = :email AND Id != :accRelation.ContactId) OR Secondary_Email__c = :email];
                        }
                    }

                    return !contactList.isEmpty() ? true : false;

                } else {
                    return true;
                }
            } else {
                return false;
            }
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }
    /** 
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Handle an exception for Aura
     * @Params:
     * Exception - ex - the exception that was thrown and needs to be handled
    **/
    private static void handleException(Exception ex) {
        throw new AuraHandledException(ex.getMessage());
    }
    /** 
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Used for custom exceptions
    **/
    public class N4LFormScreenException extends Exception {}
}