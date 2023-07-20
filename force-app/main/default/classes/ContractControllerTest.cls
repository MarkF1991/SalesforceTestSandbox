@IsTest
public with sharing class ContractControllerTest {
    @TestSetup
    private static void setup(){
        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        insert schoolAccount;
        
        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
        Contact principalContact = new Contact();
        List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            //Contact principalContact = contacts[0];
            principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            update principalContact;
        } else {
            //create contacts in the school
            //Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
         List<AccountContactRelation> testrelationships =  [SELECT ContactId, Roles FROM AccountContactRelation WHERE contactId=:principalContact.id AND AccountId =: schoolAccount.Id AND IsActive = TRUE];
        AccountContactRelation acr1 = testrelationships[0];
        acr1.roles ='Principal';
        update acr1;
        
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'External ICT', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'External ICT', False));
        
        Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);
        
        newContacts.add(exPrincipalContact);
        
        insert newContacts;
        
        exPrincipalContact.Inactive_Contact_Record__c = true;
        update exPrincipalContact;
        
        
        
        //unique for MOU Contract - the principal who is signing the contract must have a user record.
        //create external user - for the school principal
        User externalUser = TestClassUtility.createExternalUser(principalContact);
        insert externalUser;
        
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser2 = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser2;
        
        //create contract
        Contract contract  = TestClassUtility.createContract(schoolAccount, Helper.getProgrammeNameMapping().get('NHR').programme__c, principalContact, 'N4L Contract');
        insert contract;
    }
    //----------------------------------------------- GET CONTRACT -----------------------------------------------------------------------
    static testMethod void test_getContract_method() {
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        Contract contract = [SELECT id FROM Contract WHERE AccountId =: account.id LIMIT 1];
       
        Map<String,String> mapContract = ContractController.getContract(contract.id);
        String JSONContent = '';
        JSONParser parser = null;
        
        //part 1a: get response from getContract()
        JSONContent = mapContract.get('response'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        MethodResponse res1a = (MethodResponse)parser.readValueAs(MethodResponse.class);
        system.assertEquals(expectedStatusCode, res1a.statusCode); 
        system.assertEquals(expectedStatus, res1a.status); 
        
        
        //part 1b: succes in part 1a, now get contract record from getContract()
        JSONContent = mapContract.get('contract'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        Contract testContract = (Contract)parser.readValueAs(Contract.class);
        
        system.assertEquals(account.Name, testContract.Account.Name); 
        system.assertEquals(principalContact.Name, testContract.CustomerSigned.Name); //Designated Signatory is principal of the school
        
        
        //part 1c: succes in part 1a, now get principal of the school
        JSONContent = mapContract.get('principal'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        Contact testPrincipalContact = (Contact)parser.readValueAs(Contact.class);
        
        system.assertEquals(principalContact.Id, testPrincipalContact.Id); 
        system.assertEquals(principalContact.Name, testPrincipalContact.Name);
        
        
    }
    
    static testMethod void test_getContract_method_negative1() {
        Id contractId = '8005O0000000QAHQA2';
        integer expectedStatusCode = 404;
        string expectedStatus = 'NOT_FOUND';
        
        Map<String,String> mapContract = ContractController.getContract(contractId);
        String JSONContent = '';
        JSONParser parser = null;
        
        //part 1a: get response from getContract()
        JSONContent = mapContract.get('response'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        MethodResponse res1a = (MethodResponse)parser.readValueAs(MethodResponse.class);
        system.assertEquals(expectedStatusCode, res1a.statusCode); 
        system.assertEquals(expectedStatus, res1a.status); 
    }
    
    static testMethod void test_getContract_method_negative2() {
        Id contractId = null;
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        
        Map<String,String> mapContract = ContractController.getContract(contractId);
        String JSONContent = '';
        JSONParser parser = null;
        
        //part 1a: get response from getContract()
        JSONContent = mapContract.get('response'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        MethodResponse res1a = (MethodResponse)parser.readValueAs(MethodResponse.class);
        system.assertEquals(expectedStatusCode, res1a.statusCode); 
        system.assertEquals(expectedStatus, res1a.status); 
    }
    //----------------------------------------------- GET CONTRACT -----------------------------------------------------------------------
    
    //----------------------------------------------- UPDATE CONTRACT -----------------------------------------------------------------------
    static testMethod void test_updateContract_method_for_Update_Customer_Signatory() {
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contract contract = [SELECT id FROM Contract WHERE AccountId =: account.id LIMIT 1];
        contract.CustomerSignedTitle = 'admin';
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = [SELECT id, username FROM User WHERE contactId =: schoolContact.Id]; //the user was created in @TestSetup above
        
         Case case1  = new Case(
             accountid = account.id,
             contactId = schoolContact.id,
             subject = 'test case',
             Cutover_Appointment__c = DateTime.parse('11/3/2020 12:00 AM'),
             ICT_Date_onsite__c = DateTime.parse('11/3/2020 12:00 AM'),
             contract__c = contract.Id,
             RecordTypeId = TestClassUtility.getRecordTypeId(Schema.SObjectType.Case, 'Onboarding')
            
         );
         insert case1;
         
        Task task1  = new Task(
            subject = 'test school - Contract Completion',
            OwnerId = externalUser.Id,
            WhatId  = case1.id,
            status = 'Waiting on someone else'
         );
         insert task1;
        
        //input from LWC MOUContractSignatory.js handleSave(event){}
        Map<string, object> fieldsMap = NEW Map<string, object>();
        fieldsMap.put('action', 'Update_Customer_Signatory');
        fieldsMap.put('id', contract.id);
        fieldsMap.put('CustomerSignedId', schoolContact.Id);
        fieldsMap.put('OwnerId', externalUser.Id);
        fieldsMap.put('CustomerSignedTitle', contract.CustomerSignedTitle);
        system.debug('>>>>fieldsMap:'+fieldsMap);
        
        Map<String,String> mapContract = ContractController.updateContract(fieldsMap);
        
        system.debug('>>>>mapContract:'+mapContract);
        
        String JSONContent = '';
        JSONParser parser = null;
        
        //part 1a: get response from getContract()
        JSONContent = mapContract.get('response'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        MethodResponse res1a = (MethodResponse)parser.readValueAs(MethodResponse.class);
        //system.assertEquals(expectedStatusCode, res1a.statusCode); 
        //system.assertEquals(expectedStatus, res1a.status); 
        
        
        //part 1b: succes in part 1a, now get contract record from getContract()
        JSONContent = mapContract.get('contract'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        Contract testContract = (Contract)parser.readValueAs(Contract.class);
        
        system.assertEquals(account.Name, testContract.Account.Name); 
        system.assertEquals(schoolContact.Name, testContract.CustomerSigned.Name); //Designated Signatory is now different person than the principal of the school
        system.assertEquals(externalUser.Id, testContract.OwnerId); //Designated Signatory is principal of the school
    }
    
    static testMethod void test_updateContract_method_for_Update_Signed_Or_Declined() {
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contract contract = [SELECT id FROM Contract WHERE AccountId =: account.id LIMIT 1];
        
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        User externalUser = [SELECT id, username FROM User WHERE contactId =: principalContact.Id]; //the user was created in @TestSetup above
        
        //input from LWC mouContract.js  updateRecord(status){}
        Map<string, object> fieldsMap = NEW Map<string, object>();
        fieldsMap.put('action', 'Update_Signed_Or_Declined');
        fieldsMap.put('id', contract.id);
        fieldsMap.put('status', 'Signed');
        fieldsMap.put('acceptedTsandCs1', true);
        fieldsMap.put('acceptedTsandCs2', true);
        fieldsMap.put('acceptedTsandCs3', true);
        fieldsMap.put('principalname', principalContact.Name);
        fieldsMap.put('principalemail', principalContact.Email);
        fieldsMap.put('customerUserId', externalUser.Id);
        
        
        Map<String,String> mapContract = ContractController.updateContract(fieldsMap);
        String JSONContent = '';
        JSONParser parser = null;
        
        //part 1a: get response from getContract()
        JSONContent = mapContract.get('response'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        MethodResponse res1a = (MethodResponse)parser.readValueAs(MethodResponse.class);
        //system.assertEquals(expectedStatusCode, res1a.statusCode); 
        //system.assertEquals(expectedStatus, res1a.status); 
        
        
        //part 1b: succes in part 1a, now get contract record from getContract()
        JSONContent = mapContract.get('contract'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        Contract testContract = (Contract)parser.readValueAs(Contract.class);
        
        system.assertEquals(account.Name, testContract.Account.Name); 
        system.assertEquals(principalContact.Name, testContract.CustomerSigned.Name); //Designated Signatory is the principal of the school
        
        system.assertEquals('Signed', testContract.Status); //the principal user signed it
        system.assertEquals(true, testContract.Accepted_N4L_Terms_and_Conditions__c);
        system.assertEquals(true, testContract.Accepted_MoE_Terms_and_Conditions__c);
        system.assertEquals(true, testContract.Accepted_N4LCharges_Terms_and_Conditions__c);
        system.assertEquals(principalContact.Name, testContract.School_Principal_Name__c);
        system.assertEquals(principalContact.Email, testContract.School_Principal_Email__c);
        
        system.assertEquals(externalUser.Id, testContract.CustomerSignedUser__c); //the principal user signed it
        system.assertEquals(date.today(), testContract.CustomerSignedDate); //the principal user signed it
    }
    
    static testMethod void test_updateContract_method_negative() {
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contract contract = [SELECT id FROM Contract WHERE AccountId =: account.id LIMIT 1];
        contract.CustomerSignedTitle = 'admin';
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = [SELECT id, username FROM User WHERE contactId =: schoolContact.Id]; //the user was created in @TestSetup above
        
        Case case1  = new Case(
             accountid = account.id,
             contactId = schoolContact.id,
             subject = 'test case',
             Cutover_Appointment__c = DateTime.parse('11/3/2020 12:00 AM'),
             ICT_Date_onsite__c = DateTime.parse('11/3/2020 12:00 AM'),
             contract__c = contract.Id,
             RecordTypeId = TestClassUtility.getRecordTypeId(Schema.SObjectType.Case, 'Onboarding')
            
         );
         insert case1;
         
        Task task1  = new Task(
            subject = 'test school - Contract Completion',
            OwnerId = externalUser.Id,
            WhatId  = case1.id,
            status = 'Waiting on someone else'
         );
         insert task1;
        
        //input from LWC MOUContractSignatory.js handleSave(event){}
        Map<string, object> fieldsMap = NEW Map<string, object>();
        fieldsMap.put('action', 'Update_Customer_Signatory');
        fieldsMap.put('id', contract.Id);
        fieldsMap.put('CustomerSignedId', schoolContact.Id);
        fieldsMap.put('OwnerIdd', externalUser.Id);
        
        Map<String,String> mapContract = ContractController.updateContract(fieldsMap);
        String JSONContent = '';
        JSONParser parser = null;
        
        //part 1a: get response from getContract() FAILED
        JSONContent = mapContract.get('response'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        MethodResponse res1a = (MethodResponse)parser.readValueAs(MethodResponse.class);
        system.assertEquals(expectedStatusCode, res1a.statusCode); 
        system.assertEquals(expectedStatus, res1a.status); 
    }
    //----------------------------------------------- UPDATE CONTRACT -----------------------------------------------------------------------
    
    //----------------------------------------------- INVITE TO SIGN CONTRACT -----------------------------------------------------------------------
    static testMethod void test_inviteToSignContract_method() {
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contract contract = [SELECT id FROM Contract WHERE AccountId =: account.id LIMIT 1];
        
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        User externalUser = [SELECT id, username FROM User WHERE contactId =: principalContact.Id]; //the user was created in @TestSetup above
        
        String type = 'MOU';
        
        String JSONContent = ContractController.inviteToSignContract(type, contract.Id);
        
        JSONParser parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        MethodResponse res = (MethodResponse)parser.readValueAs(MethodResponse.class);
        
        //system.assertEquals(expectedStatusCode, res.statusCode); 
        //system.assertEquals(expectedStatus, res.status); 
    }
    
    static testMethod void test_invite_signatory_actions_method() {
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contract contract = [SELECT id, Programme__c FROM Contract WHERE AccountId =: account.id LIMIT 1];
        contract.Educount_Rolls__c = 22;
        
        update contract; 
        
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        User externalUser = [SELECT id, username FROM User WHERE contactId =: principalContact.Id]; //the user was created in @TestSetup above
        
        Case case1  = new Case(
             accountid = account.id,
             contactId = principalContact.id,
             subject = 'test case',
             Cutover_Appointment__c = DateTime.parse('11/3/2020 12:00 AM'),
             ICT_Date_onsite__c = DateTime.parse('11/3/2020 12:00 AM'),
             contract__c = contract.Id,
             RecordTypeId = TestClassUtility.getRecordTypeId(Schema.SObjectType.Case, 'Onboarding')
            
         );
         insert case1;
         
        Task task1  = new Task(
            subject = 'test school - Contract Completion',
            OwnerId = externalUser.Id,
            WhatId  = case1.id,
            status = 'Waiting on someone else'
         );
         insert task1;
        
        String type = 'MOU';
        
        MethodResponse res = ContractController.invite_signatory_actions(type, contract.Id);
        //system.assertEquals(expectedStatusCode, res.statusCode); 
        //system.assertEquals(expectedStatus, res.status); 
    }
    
    
    
    static testMethod void test_invite_signatory_actions_method_negative() {
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contract contract = [SELECT id FROM Contract WHERE AccountId =: account.id LIMIT 1];
        
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        User externalUser = [SELECT id, username FROM User WHERE contactId =: principalContact.Id]; //the user was created in @TestSetup above
        
        String type = null;
        
        MethodResponse res = ContractController.invite_signatory_actions(type, contract.Id);
        system.assertEquals(expectedStatusCode, res.statusCode); 
        system.assertEquals(expectedStatus, res.status); 
    }
    
    static testMethod void test_create_ContractSignatoryInvite_Token_method_negative() {
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        
        MethodResponse res = ContractController.create_ContractSignatoryInvite_Token(null, null);
        system.assertEquals(expectedStatusCode, res.statusCode); 
        system.assertEquals(expectedStatus, res.status); 
    }
    
    static testMethod void test_send_ContractSignatoryInvite_Email_method_negative() {
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        
        MethodResponse res = ContractController.send_ContractSignatoryInvite_Email(null, null);
        system.assertEquals(expectedStatusCode, res.statusCode); 
        system.assertEquals(expectedStatus, res.status); 
    }
    
    
    //----------------------------------------------- INVITE TO SIGN CONTRACT -----------------------------------------------------------------------
    
    //----------------------------------------------- CONFIRM SIGNED CONTRACT -----------------------------------------------------------------------
    
    //----------------------------------------------- CONFIRM SIGNED CONTRACT -----------------------------------------------------------------------
    
    //----------------------------------------------- GET CONTRACT BY TOKEN -----------------------------------------------------------------------
    static testMethod void test_getContractByToken_method() {
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contract contract = [SELECT id, CustomerSignedId, OwnerId FROM Contract WHERE AccountId =: account.id LIMIT 1];
        
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        User externalUser = [SELECT id, username FROM User WHERE contactId =: principalContact.Id]; //the user was created in @TestSetup above
        
        contract.OwnerId = externalUser.Id;
        update contract;
        
        String type = 'MOU';
        
        Token__c token = new Token__c(
            RecordId__c = String.valueOf(contract.Id),
            Account__c = account.Id,
            Requester__c = null,
            Approver__c = contract.CustomerSignedId, //designated signatory contact id
            Type__c = type,
            Status__c = 'Invited',
            IsClosed__c = false
        );
        insert token;
        
        Map<String, Object> claimsMap = New Map<String, Object>();
        claimsMap.put('tokenId', token.id);
        
        //MethodResponse res = ContractController.getContractByToken(claimsMap, principalContact.Id); //principalContact.Id is the contract.CustomerSignedId - designated signatory contact id
        MethodResponse res = ContractController.getContractByToken(claimsMap, externalUser.Id); //externalUser.Id is the contract.OwnerId
        //system.assertEquals(expectedStatusCode, res.statusCode); 
        //system.assertEquals(expectedStatus, res.status); 
        
        Map<String, String> mapContract = res.results; //res.results = getContract(token.RecordId__c); they have the same structure Map<String, String>
        
        String JSONContent = '';
        JSONParser parser = null;
        //part 1a: get response from getContract()
        JSONContent = mapContract.get('response'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        MethodResponse res1a = (MethodResponse)parser.readValueAs(MethodResponse.class);
        system.assertEquals(expectedStatusCode, res1a.statusCode); 
        system.assertEquals(expectedStatus, res1a.status); 
        
        
        //part 1b: succes in part 1a, now get contract record from getContract()
        JSONContent = mapContract.get('contract'); //stringResponse is a json.serialized string
        parser = JSON.createParser(JSONContent);
        parser.nextToken();// Make calls to nextToken() to point to the second start object marker.
        // Retrieve the Contact object from the JSON string.
        Contract testContract = (Contract)parser.readValueAs(Contract.class);
        
        system.assertEquals(account.Name, testContract.Account.Name); 
        system.assertEquals(principalContact.Name, testContract.CustomerSigned.Name); //Designated Signatory is principal of the school
        
        //test negative - user is UNAUTHORIZED to sign the mou contract, when the contactid does not match Designated Signatory's contact id
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        expectedStatusCode = 401;
        expectedStatus = 'UNAUTHORIZED';
        MethodResponse res2 = ContractController.getContractByToken(claimsMap, schoolContact.Id); //principalContact.Id is the contract.CustomerSignedId - designated signatory contact id
        system.assertEquals(expectedStatusCode, res2.statusCode); 
        system.assertEquals(expectedStatus, res2.status); 
    }
    
    static testMethod void test_getContractByToken_method_negative() {
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        
        MethodResponse res = ContractController.getContractByToken(null, null);
        system.assertEquals(expectedStatusCode, res.statusCode); 
        system.assertEquals(expectedStatus, res.status); 
    }
    
    //ITR-1397
    static testMethod void test_createToken() {
        String userOrigin = 'N4L Invitation - Contract Signatory';
        String type = 'MOU';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        
        MethodResponse res = New MethodResponse();
        res = ContractController.createToken(contact, type, userOrigin);
        
        system.assertEquals(201, res.statuscode);
        
        
    }
    
     static testMethod void test_createUser_actions_for_sign_theorder() {
        String userOrigin = 'N4L Invitation - Contract Signatory';
        String type = 'MOU';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
         
        Token__c token = new Token__c(
                RecordId__c = String.valueOf(contact.Id),
                Account__c = contact.AccountId, //account Id
                Requester__c = null,
                Approver__c = contact.Id, //contact Id,
                Type__c = type,
                Status__c = 'Invited',
                IsClosed__c = false,
                Parent__c = null,
                UserOrigin__c = userOrigin //'N4L Invitation - Contract Signatory'
            );
            insert token;     
         
         String result = ContractController.createUser_actions_for_sign_theorder(token, userOrigin);
         
         system.assertEquals(False, string.isEmpty(result));
     }
     
    static testMethod void test_Contact_userOrign_update() {         
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contract contract = [SELECT id FROM Contract WHERE AccountId =: account.id LIMIT 1];
        
        MethodResponse res = ContractController.contact_userOrign_update(contract.Id);
        
        system.assertEquals(200, res.statuscode);
        
        
        
    }
    
    
    //----------------------------------------------- GET CONTRACT BY TOKEN -----------------------------------------------------------------------
}