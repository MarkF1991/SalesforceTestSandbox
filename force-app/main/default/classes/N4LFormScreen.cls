/**
 * @Date               : January 15, 2021
 * @Description        : controller class for n4l form screen lwc
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
public without sharing class N4LFormScreen {

    /** 
     * @Date: March 12, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Gets user license
    **/
    @AuraEnabled (cacheable = false)
    public static String getUserLicense(){
        User loginUser = [SELECT Id, Profile.UserLicense.Name FROM User WHERE Id = :UserInfo.getUserId()];
        return loginUser.Profile.UserLicense.Name;
    }

    /** 
     * @Date: January 15, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves related name of an object
     * @Params:
     * String recordId - the id of the record
     * String email - email typed on the search bar
    **/
    @AuraEnabled (cacheable = false)
    public static List<FieldProperties> getRecordDetails(String recordId,String contactId,String objectName, 
                                                            Boolean isReplace, String accountId, String replaceValue){
        try{
            List<FieldProperties> fProperties = new List<FieldProperties>();

            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType objectSchema = schemaMap.get(objectName);
            Map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();

            for (String fieldName: fieldMap.keySet()) {

                FieldProperties fProperty = new FieldProperties();
                fProperty.label = fieldMap.get(fieldName).getDescribe().getLabel();
                fProperty.fieldName = fieldName;
                fProperty.fieldHelpText = fieldMap.get(fieldName).getDescribe().getInlineHelpText();

                if(objectName == N4LStringConstants.OBJFIELD_ACRELATION && fieldName.equals('isactive')) {
                    fProperty.fieldValue = true;
                }

                fProperties.add(fProperty);
            }
            
            if(!String.isEmpty(recordId) || !String.isEmpty(contactId)){

                String whereClause = 'Id = :contactId';

                if(!String.isEmpty(recordId)) {
                    if(objectName.equals('Contact')) {
                        if(isReplace && !String.isEmpty(contactId)) {
                            whereClause = 'Id = :contactId';
                        } else {
                            AccountContactRelation acctConRel = [SELECT Id,ContactId FROM AccountContactRelation WHERE Id = :recordId];
                            String conId = acctConRel.ContactId;
                            whereClause = 'Id = :conId';
                        }
                    } else {
                        if(isReplace && !String.isEmpty(contactId) && replaceValue == 'existingSchool') {
                            AccountContactRelation acctConRel = [SELECT Id,ContactId FROM AccountContactRelation 
                                                                    WHERE AccountId = :accountId AND ContactId = :contactId];
                            String acctConRelId = acctConRel.Id;
                            whereClause = 'Id = :acctConRelId';                            
                        } else {
                            whereClause = 'Id = :recordId';
                        }
                    }
                } else if(!String.isEmpty(contactId) && objectName.equals(N4LStringConstants.OBJFIELD_ACRELATION)){
                    whereClause = 'ContactId = :contactId AND AccountId = :accountId';
                }

                // Build the Query
                String soql  = String.format('SELECT {0} FROM {1} WHERE ({2}) LIMIT 1', new String[]{
                    String.join(new List<String>(fieldMap.keySet()), ','),
                    objectName,
                   whereClause
                });
                
                // Set contact record to be display on the form
                List<SObject> contactRecords = Database.query(soql);
                
                if(contactRecords.isEmpty()){
                    throw new N4LFormScreenException('No records found!');
                } else {
                    for(FieldProperties fProperty : fProperties){
                        fProperty.fieldValue = contactRecords[0].get(fProperty.fieldName);
                    }
                }
            }

            return fProperties;
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }

    /** 
     * @Date: January 26, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that check if email already exists
     * @Params:
     * String email - the email of the contact
    **/
    @AuraEnabled (cacheable = false)
    public static Boolean checkEmailDuplicates(String email,String recordId,Boolean emailEditable){
        try{
            if(!String.isEmpty(email)){
                List<User> userList = [SELECT Id FROM User WHERE ContactId = NULL AND Username = :email];

                // check if email has been use for the internal users
                if(userList.isEmpty()) {
                    List<Contact> contactList = [SELECT Id FROM Contact WHERE Email = :email OR Secondary_Email__c = :email];
                    
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
     * @Date: February 17, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that check if email matches the email domain of account
     * @Params:
     * String email - the email of the contact
     * String accountId - the related account
    **/
    @AuraEnabled (cacheable = false)
    public static Boolean checkEmailDomain(String email,String accountId){
        try{
            if(!String.isEmpty(email) && !String.isEmpty(accountId)){
                Account acct = [SELECT Id,Email_Domain__c FROM Account WHERE Id = :accountId];

                if(!String.isEmpty(acct.Email_Domain__c)) {
                    if(email.split('@')[email.split('@').size()-1].contains(acct.Email_Domain__c)) {
                        return false;
                    } else {
                        return true;
                    }    
                } else {
                    return false;
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
     * @Date: January 21, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves related name of an object
     * @Params:
     * String recordId - the id of the record
     * String contactId - the contact id related to a record
     * String objectName - the object api name
    **/
    @AuraEnabled (cacheable = false)
    public static Boolean checkSupportHubUser(String recordId,String contactId,String objectName,Boolean isReplace){
        try{
            Boolean isSupportHubUser = false;

            String conId = contactId;

            System.debug('####'+objectName);

            if(!String.isEmpty(recordId) && objectName.equals(N4LStringConstants.OBJFIELD_ACRELATION) && !isReplace) {
                AccountContactRelation acctConRel = [SELECT Id,ContactId FROM AccountContactRelation WHERE Id = :recordId];
                conId = acctConRel.ContactId;
            }

            List<User> supportHubUserList = new List<User>([SELECT Id FROM User WHERE ContactId = :conId AND ContactId != null]);
            if(!supportHubUserList.isEmpty()){
                isSupportHubUser = true;
            }

            return isSupportHubUser;
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }

    /** 
     * @Date: January 20, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that gets multipicklist values
     * @Params:
     * String objectName - the object of the field
     * String fieldName - multipicklist field
    **/
    @AuraEnabled(cacheable=true)
    public static MultipicklistValues retrieveMultipicklistValues(String objectName, String fieldName, 
                                                                    String accountId){
        system.debug('lh retrieveMultipicklistValues objectname = '+objectName); 
        system.debug('lh retrieveMultipicklistValues fieldName = '+fieldName);   
        system.debug('lh retrieveMultipicklistValues accountId = '+accountId);   
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        User loginUser = [SELECT Id,ContactId,AccountId,Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        system.debug('lh loginUser Profile.Name='+loginUser.Profile.Name);                                                               
        List<N4L_ManageContactsProfile__mdt> allowedProfiles = [SELECT Id FROM N4L_ManageContactsProfile__mdt WHERE MasterLabel = :loginUser.Profile.Name];
        system.debug('lh allowedProfiles='+allowedProfiles);
        Set<String> availablePicklistValues = new Set<String>();

        if(allowedProfiles.isEmpty()) {
            system.debug('lh allowedProfiles is empty');
            AccountContactRelation accConRelation = [SELECT Id,Roles,Authority__c FROM AccountContactRelation 
                                                        WHERE ContactId = :loginUser.ContactId AND AccountId = :accountId LIMIT 1];
            for(N4L_Contact_Management__mdt contactManagementSetting : [SELECT Id,MasterLabel,Authority_Selectable__c,
                                                                        Roles_Selectable__c,Systems_Accessible__c
                                                                        FROM N4L_Contact_Management__mdt]) {
                if(accConRelation.Roles != null) {
                    if(accConRelation.Roles.contains(contactManagementSetting.MasterLabel)) {
                        if(objectName.equals(N4LStringConstants.OBJFIELD_ACRELATION) && fieldName.toLowerCase().equals(N4LStringConstants.OBJFIELD_ACRELATION_ROLES.toLowerCase())) {
                            availablePicklistValues.addAll(String.isEmpty(contactManagementSetting.Roles_Selectable__c) ? new Set<String>() : new Set<String>(contactManagementSetting.Roles_Selectable__c.split(';')));
                        } else if(objectName.equals(N4LStringConstants.OBJFIELD_ACRELATION) && fieldName.toLowerCase().equals(N4LStringConstants.OBJFIELD_ACRELATION_AUTHORITY.toLowerCase())) {
                            availablePicklistValues.addAll(String.isEmpty(contactManagementSetting.Authority_Selectable__c) ? new Set<String>() : new Set<String>(contactManagementSetting.Authority_Selectable__c.split(';')));
                        }
                    }
                }

                if(accConRelation.Authority__c != null) {
                    if(accConRelation.Authority__c.contains(contactManagementSetting.MasterLabel)) {
                        if(objectName.equals(N4LStringConstants.OBJFIELD_ACRELATION) && fieldName.toLowerCase().equals(N4LStringConstants.OBJFIELD_ACRELATION_ROLES.toLowerCase())) {
                            availablePicklistValues.addAll(String.isEmpty(contactManagementSetting.Roles_Selectable__c) ? new Set<String>() : new Set<String>(contactManagementSetting.Roles_Selectable__c.split(';')));
                        } else if(objectName.equals(N4LStringConstants.OBJFIELD_ACRELATION) && fieldName.toLowerCase().equals(N4LStringConstants.OBJFIELD_ACRELATION_AUTHORITY.toLowerCase())) {
                            availablePicklistValues.addAll(String.isEmpty(contactManagementSetting.Authority_Selectable__c) ? new Set<String>() : new Set<String>(contactManagementSetting.Authority_Selectable__c.split(';')));
                        } 
                    }
                }
            }
        }
                                                                    
        List<String> roleAccesses = new List<String>();

        // get allowed picklist value base on account record type
        if(objectName.equals(N4LStringConstants.OBJFIELD_ACRELATION) && 
            fieldName.toLowerCase().equals(N4LStringConstants.OBJFIELD_ACRELATION_ROLES.toLowerCase())) {
            Account acct = [SELECT Id,RecordType.DeveloperName FROM Account WHERE Id = :accountId];
            
            String acctRecType = acct.RecordType.DeveloperName == N4LStringConstants.ACCOUNT_RECTYPE_SCHOOL ? '%'+N4LStringConstants.ACCOUNT_RECTYPE_SCHOOL+'_Rec'+'%' : '%'+acct.RecordType.DeveloperName+'%';

            for(N4L_Roles_Access__mdt roleAccessSetting : [SELECT Id,MasterLabel FROM N4L_Roles_Access__mdt
                                                            WHERE Organisation_Record_Type_API_Name__c LIKE :acctRecType]) {
                roleAccesses.add(roleAccessSetting.MasterLabel);
                                                              
            }
        }

        MultipicklistValues multipicklistWrapper = new MultipicklistValues();
        multipicklistWrapper.fieldName = fieldName;

        Map<String,String> options = new Map<String,String>();
        Map<String,String> orderredOptions = new Map<String,String>();
        if(allowedProfiles.isEmpty() && (
            objectName.equals(N4LStringConstants.OBJFIELD_ACRELATION) && (
                fieldName.toLowerCase().equals(N4LStringConstants.OBJFIELD_ACRELATION_ROLES.toLowerCase()) 
                || fieldName.toLowerCase().equals(N4LStringConstants.OBJFIELD_ACRELATION_AUTHORITY.toLowerCase())
                )
            )
        ) {
            for(String picklistValue : availablePicklistValues) {
                if(!roleAccesses.isEmpty()) {
                    for(String roleAccess : roleAccesses) {
                        if(roleAccess == picklistValue){ options.put(picklistValue,picklistValue); }
                    }                
                } else { options.put(picklistValue,picklistValue); }
            }
        } else {
            for(Schema.PicklistEntry f : ple) {
                if(!roleAccesses.isEmpty()) {
                    for(String roleAccess : roleAccesses) {
                        if(roleAccess == f.getLabel()) { options.put(f.getValue(),f.getLabel()); }
                    }                
                } else { options.put(f.getValue(),f.getLabel()); }
            }       
        }
        for(N4L_Role_Authority_Match__mdt nram : [SELECT Id,MasterLabel,Role_Priority_Level__c
                                                FROM N4L_Role_Authority_Match__mdt ORDER BY Role_Priority_Level__c]){
                                                    if(options.containskey(nram.MasterLabel)){
                                                       orderredOptions.put(nram.MasterLabel,nram.MasterLabel); 
                                                    }                  
                                                }
       // multipicklistWrapper.picklistValues = options;
        multipicklistWrapper.picklistValues =orderredOptions;
        system.debug('lh retrieveMultipicklistValues options = '+options);
        return multipicklistWrapper;         
    }   

    /** 
     * @Date: February 04, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that gets screen settings to manipulate view of the form
    **/
    @AuraEnabled(cacheable=true)
    public static N4L_Screen_Settings__c retrieveScreenSettings(){        
        return N4L_Screen_Settings__c.getOrgDefaults();       
    }   

    /** 
     * @Date: January 19, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves search results
     * @Params:
     * String objectName - the object of the record
     * String fieldName - field name to be search
     * String value - value inputted in the search
    **/
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getResults(String ObjectName, String fieldName, String value, String accountId) {
        system.debug('getResults parameters 1 objectname= :'+ObjectName+' 2 fieldName= :'+fieldName+' 3 value= :'+value+' 4 accountId= :'+accountId);
        try {
            List<SObJectResult> sObjectResultList = new List<SObJectResult>();
            Set<Id> directContactId = new Set<Id>();

            if(String.isNotEmpty(value)) {            
                value = value.trim();

                Set<Id> acctIdSet = new Set<Id>();
                Account acct = null;

                // get records based on account conditions
                if(!String.isEmpty(accountId)) {
                   //by lh test: acctIdSet.add(accountId);//add by lh
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
                system.debug('related account ids= :'+acctIdSet);
                String soql = 'Select Id,'+fieldName+' FROM '+ObjectName+' WHERE '+fieldName+' LIKE \'%' + value + '%\'';
                system.debug('query string name search string= :'+soql);
                List<AccountContactRelation> accRelList = new List<AccountContactRelation>();

                if(String.isEmpty(fieldName) && ObjectName.equals('Contact')) {
                    fieldName = 'Name';
                    soql = 'Select Id,Email,Secondary_Email__c,'+fieldName+' FROM '+ObjectName+' WHERE (Email LIKE \'%' + value + '%\''+' OR FirstName LIKE \'%' + value + '%\''+' OR LastName LIKE \'%' + value + '%\''+' OR Secondary_Email__c LIKE \'%' + value + '%\''+' OR Name LIKE \'%' + value + '%\')';

                    if(acct != null) {
                        List<Id> acctIds = new List<Id>(acctIdSet);
                        soql += ' AND AccountId IN :acctIds';
                    }

                    accRelList = [SELECT Id,ContactId FROM AccountContactRelation WHERE AccountId = :accountId];
                    system.debug('fieldName empty set = Name soql string= :'+soql);
                    system.debug('fieldName empty accRelList= :'+accRelList);
                    
                }
                system.debug('Final soql string= :'+soql);
                for(sObject so : Database.Query(soql)) {
                    system.debug('sObject so= :'+so);
                    String fieldvalue = (String)so.get(fieldName);
                    String email = '';
                    String secondaryEmail = '';

                    if(ObjectName.equals('Contact')) {
                        Boolean isNewContact = true;

                        for(AccountContactRelation accRel : accRelList) {
                            if(so.Id == accRel.ContactId) {
                                system.debug('accRel.ContactId = : '+accRel.ContactId);
                                //by lh test: sObjectResultList.add(new SObjectResult(fieldvalue, so.Id, email,secondaryEmail));
                                isNewContact = false;
                            }
                        }

                        if(isNewContact) {
                            email = (String) so.get('email');
                            secondaryEmail = (String) so.get('Secondary_Email__c');
                            directContactId.add(so.Id);    
                            sObjectResultList.add(new SObjectResult(fieldvalue, so.Id, email,secondaryEmail));
                            system.debug('isNewContact so.id= ' +so.Id);
                        }
                    } else {
                        sObjectResultList.add(new SObjectResult(fieldvalue, so.Id, email,secondaryEmail));
                    }

                }

                system.debug('410 fieldName=:'+fieldName);
                if(String.isEmpty(fieldName) && ObjectName.equals('Contact')) {
                    List<Id> acctIds = new List<Id>(acctIdSet);
                    Set<Id> contactRelIdSet = new Set<Id>();

                    for(AccountContactRelation acRel : [SELECT Id,ContactId FROM AccountContactRelation 
                                                        WHERE AccountId IN :acctIds AND ContactId NOT IN :new List<Id>(directContactId)]) {
                        contactRelIdSet.add(acRel.ContactId);
                    }
                    system.debug('fieldName empty & contact contactRelIdSet= :'+contactRelIdSet);
                    if(!contactRelIdSet.isEmpty()) {
                        List<Id> conIds = new List<Id>(contactRelIdSet);

                        soql = 'Select Id,Email,'+fieldName+' FROM '+ObjectName+' WHERE Id IN :conIds AND (Email LIKE \'%' + value + '%\''+' OR FirstName LIKE \'%' + value + '%\''+' OR LastName LIKE \'%' + value + '%\''+' OR Name LIKE \'%' + value + '%\')';
                        system.debug('fieldName empty & contact Final soql string= :'+soql);
                        for(sObject so : Database.Query(soql)) {
                            sObjectResultList.add(new SObjectResult((String)so.get(fieldName), so.Id, (String) so.get('email'),(String) so.get('Secondary_Email__c')));
                        }
                    }
                }
            }
            system.debug('getResult sObjectResultList= :'+sObjectResultList);
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

                    sObjectResultList.add(new SObjectResult(fieldvalue, recId, email,secondaryEmail));
                }
            }
            return sObjectResultList;
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }

    /** 
     * @Date: February 09, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: method that fetch account details
    **/
    @AuraEnabled (cacheable = false)
    public static Account getAccountDetails(String recordId,String accountId){
        Account acc = new Account();
        
        try {
            if(Id.valueOf(accountId).getSObjectType() != Account.sObjectType) {
                String sObjName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();

                List<SObject> objRecords = Database.query('SELECT Id,Account.Name,Account.Email_Domain__c, AccountId FROM '+sObjName+' WHERE Id = :recordId');

                acc = new Account(Id = (Id) objRecords[0].get('AccountId'),
                                    Name= (String) objRecords[0].getSObject('Account').get('Name'),
                                    Email_Domain__c = (String) objRecords[0].getSObject('Account').get('Email_Domain__c'));
            } else {
                acc = [SELECT Id,Name,Email_Domain__c FROM Account WHERE Id = :accountId];
            }    
        } catch(Exception ex) {
            handleException(ex);
            acc = null;
        }

        return acc;
    }

    /** 
     * @Date: January 26, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that adds new contact
    **/
    @AuraEnabled (cacheable = false)
    public static Object addNewContact(Object newEmail, Object firstName, Object lastName, Object jobTitle,
        Object mobilePhone, Object outageNotif, Object periodicEmail, Object operational, Object createSupportHubUser,
        String accountId,String recordId,Boolean isReplace, String replaceValue,Boolean isInherit,Object secondaryEmail,
        Object systemAccessible,Object isActive){

        Contact objContact = null;

        try{
            // change old contact email address
            if(isInherit) {
                AccountContactRelation oldRelation = [SELECT Id,ContactId,Contact.Email FROM AccountContactRelation WHERE Id = :recordId];
                Contact con = new Contact(Id=oldRelation.ContactId, Email=oldRelation.Contact.Email);

                // check if contact is related to 1 account only, update email address
                String uuid = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128));
                String emailShortenStr = con.Email.SubStringBefore('.com');
                System.debug('##### '+uuid);
                con.Email = emailShortenStr+'.com'+uuid.SubString(0,8)+uuid.SubString(8,12)+uuid.substring(20);
                update con;
            }
            
            if(Boolean.valueOf(createSupportHubUser) == true && String.isEmpty((String) newEmail)) {
                throw new N4LFormScreenException(Label.Screen_NoEmailSupportHub);
            } else {
                objContact = new Contact();

                if(!String.isEmpty(recordId) && !isReplace) {
                    AccountContactRelation accRelation = [SELECT ContactId FROM AccountContactRelation WHERE Id = :recordId];
                    objContact.Id = accRelation.ContactId;
                }

                // check if outaage notification is uncheck and check whether its the only default checked for an account contact relation
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
                }

                // update inactive checkbox
                if((Boolean) isActive) {
                    objContact.Inactive_Contact_Record__c = false;
                } else if(!(Boolean) isActive && objContact.Id != null) {
                    List<AccountContactRelation> contactRelationList = [SELECT Id,isActive,ContactId FROM AccountContactRelation 
                    WHERE ContactId = :objContact.Id AND isActive = true];

                    if(contactRelationList.isEmpty()) {
                        objContact.Inactive_Contact_Record__c = true;
                    }
                }

                objContact.Email = (String) newEmail;
                objContact.Secondary_Email__c = (String) secondaryEmail;
                objContact.LastName = (String) lastName;
                objContact.FirstName = (String) firstName;
                objContact.Title = (String) jobTitle;
                objContact.MobilePhone = (String) mobilePhone;
                objContact.Outage_notifications__c = (Boolean) outageNotif;
                objContact.Periodic_Survey_Emails__c = (Boolean) periodicEmail;
                objContact.Current_N4L_product_and_service_updates__c = (Boolean) operational;
                objContact.System_Accessible__c = (String) systemAccessible;

                if(objContact.Id == null) {
                    objContact.AccountId = accountId;
                }

                upsert objContact;
            }
        }  catch (Exception ex) {
            handleException(ex);
        }

        return objContact;
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
            acctConRel.Authority__c = (String) authorities;

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
     * @Date: February 02, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that captures primary account name of the related contact
     * @Params:
     * String contactId - the contact id related to a record
    **/
    @AuraEnabled (cacheable = false)
    public static String captureContactPrimaryAccountName(String accConRelId){
        if(!String.isEmpty(accConRelId)) {
            AccountContactRelation accConRel = [SELECT Id,Contact.Account.Name FROM AccountContactRelation WHERE Id = :accConRelId];
            return accConRel.Contact.Account.Name;
        } else {
            return null;
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
        try {
            List<Boolean> disableFields = new List<Boolean>();
            User loginUser = [SELECT Id,ContactId,AccountId,Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];

            disableFields.add(false);
            disableFields.add(false);
            disableFields.add(true);    

            List<N4L_ManageContactsProfile__mdt> allowedProfiles = [SELECT Id FROM N4L_ManageContactsProfile__mdt WHERE MasterLabel = :loginUser.Profile.Name];

            if(!allowedProfiles.isEmpty()) {
                disableFields = new List<Boolean>();
                disableFields.add(true);
                disableFields.add(true);
                disableFields.add(false);
            } else {
                if(loginUser.ContactId != null) {
                    if(!String.isEmpty(accountId)) {
                        List<AccountContactRelation> relationOfLoginContact = [SELECT Id,Authority__c,Roles FROM AccountContactRelation 
                                                                            WHERE AccountId = :accountId AND ContactId = :loginUser.ContactId];                        
                        if(!relationOfLoginContact.isEmpty()) {
                            disableFields = new List<Boolean>();

                            //check authority and warning or error for email domain
                            if(!String.isEmpty(recordId)) {
                                AccountContactRelation relatedAccountRelation = [SELECT Id,ContactId,Contact.AccountId FROM AccountContactRelation WHERE Id = :recordId];

                                if(relatedAccountRelation.ContactId == loginUser.ContactId) {
                                    disableFields.add(true);
                                    disableFields.add(true);
                                } else {
                                    if(relatedAccountRelation.Contact.AccountId == accountId) {
                                        disableFields.add(relationOfLoginContact[0].Authority__c != null ? 
                                            relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT) ||
                                            relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_NOMINATOR)? true : false : false);
                                        disableFields.add(relationOfLoginContact[0].Authority__c != null ? 
                                            relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT) || 
                                            relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_NOMINATOR)? true : false : false);
                                    } else {
                                        disableFields.add(false);
                                        disableFields.add(false);

                                        List<AccountContactRelation> accRelList = [SELECT Id,Authority__c FROM AccountContactRelation 
                                                                                    WHERE ContactId = :loginUser.ContactId 
                                                                                    AND AccountId = :relatedAccountRelation.Contact.AccountId];
                                        if(!accRelList.isEmpty()) {
                                            if(accRelList[0].Authority__c != null) {
                                                if(accRelList[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT) 
                                                    || relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_NOMINATOR)) {
                                                    disableFields.add(false);
                                                    disableFields.add(false);
                                                }
                                            }
                                        }
                                    }    
                                }
                            } else {
                                disableFields.add(relationOfLoginContact[0].Authority__c != null ? 
                                    relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT) || 
                                    relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_NOMINATOR) ? true : false : false);
                                disableFields.add(relationOfLoginContact[0].Authority__c != null ? 
                                    relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT) || 
                                    relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_NOMINATOR) ? true : false : false);
                            }

                            if(!String.isEmpty(recordId)) {
                                AccountContactRelation relatedAccountRelation = [SELECT Id,ContactId,Contact.AccountId FROM AccountContactRelation WHERE Id = :recordId];

                                // check role edit or not
                                if(relatedAccountRelation.ContactId == loginUser.ContactId) {
                                    disableFields.add(false);
                                } else {
                                    if(relationOfLoginContact[0].Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL)) {
                                        disableFields.add(false);
                                    } else{
                                        if(!String.isEmpty(recordId)) {
                                            AccountContactRelation recordRelation = [SELECT Id,Authority__c,Roles FROM AccountContactRelation WHERE Id = :recordId];
        
                                            if(!recordRelation.Roles.toLowerCase().contains(N4LStringConstants.ROLE_PRINCIPAL)){
                                                if(relationOfLoginContact[0].Authority__c != null) {
                                                    disableFields.add(relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_MANAGECONTACT) || 
                                                                        relationOfLoginContact[0].Authority__c.toLowerCase().contains(N4LStringConstants.AUTHORITY_NOMINATOR) ? false : true);
                                                } else {
                                                    disableFields.add(recordRelation.Authority__c == null || recordRelation.Authority__c == '' ? false : true);
                                                }
                                            } else {
                                                disableFields.add(true);
                                            }
                                        } else {
                                            disableFields.add(false);
                                        }
                                    }
                                }
                            } else {
                                disableFields.add(true);
                            }
                        }
                    }
                }
            }

            return disableFields;
        }  catch (Exception ex) {
            handleException(ex);
            return null;
        }
    }

    /** 
     * @Date: February 03, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves contact email if it has only 1 relationship
     * @Params:
     * String recordId - the id of the record
    **/
    @AuraEnabled (cacheable = false)
    public static String getContactEmail(String recordId){
        String email = '';

        AccountContactRelation oldRelation = [SELECT Id,ContactId,Contact.Email FROM AccountContactRelation WHERE Id = :recordId];
        List<AccountContactRelation> conRelations = [SELECT Id,ContactId FROM AccountContactRelation 
                                                        WHERE ContactId = :oldRelation.ContactId AND isActive = true];

        // check if contact is related to 1 account only, update email address
        if(conRelations.size() == 1) {
            email = oldRelation.Contact.Email;
        }

        return email;
    }

    /** 
     * @Date: February 15, 2021
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Method that retrieves roles and authorities match
    **/
    @AuraEnabled (cacheable = false)
    public static List<N4L_Role_Authority_Match__mdt> matchRolesAndAuthorities(){
        return [SELECT Id,MasterLabel,Default_authority_types__c,Is_Operational_emails_checked__c,
                    Is_Outage_notifications_checked__c, Is_periodic_emails_checked__c ,Role_Priority_Level__c
                    FROM N4L_Role_Authority_Match__mdt ORDER BY Role_Priority_Level__c DESC];
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

    /** 
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Description: Dynamic Wrapper class for sObject field properties
    **/
    public class FieldProperties{
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Object fieldValue;
        @AuraEnabled public Object fieldHelpText;
    }

    /** 
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Date : February 03, 2021
     * @Description: Dynamic Wrapper class for sobject search
    **/
    public class SObJectResult {

        @AuraEnabled public String recName;
        @AuraEnabled public Id recId;
        @AuraEnabled public String recEmail;
        @AuraEnabled public String recSecondaryEmail;
        @AuraEnabled public Boolean showSecondaryEmail;

        public SObJectResult(String recNameTemp, Id recIdTemp,String recEmailTemp,String recSecondaryEmailTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
            recEmail = recEmailTemp;
            recSecondaryEmail = recSecondaryEmailTemp;
            showSecondaryEmail = !String.isEmpty(recSecondaryEmail) ? true : false;
        }
    }

    /** 
     * @Author: Heidi Tang (heitang@deloitte.com)
     * @Date : February 03, 2021
     * @Description: Dynamic Wrapper class for multi-picklist values of a field
    **/
    public class MultipicklistValues {
        @AuraEnabled public Map<String,String> picklistValues;
        @AuraEnabled public String fieldName;   
    }
}