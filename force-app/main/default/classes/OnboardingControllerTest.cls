/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2019-08-30
* @description Using AuraEnabled method to handle user request for access to various product: Filtering Portal, School Reporting and etc 
*
* CHANGE LOG
**/

@IsTest
public with sharing class OnboardingControllerTest {
    @TestSetup
    private static void setup(){
        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        schoolAccount.Fortinet_Adom_Name__c = 'n4l-adom-name';
        schoolAccount.Onboarding_Filtering_Portal__c = 'Opt In';
        insert schoolAccount;
        
        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
        List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            Contact principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            update principalContact;
        } else {
            //create contacts in the school
            Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
        
        
        Contact schoolContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False);
        insert schoolContact;

        Contact ictContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@mismatched-domain.com', '02733333333', 'External ICT', False);
        insert ictContact;
        
        //create internal user - relationship manager
        User rmUser = TestClassUtility.createInternalUser();
        insert rmUser;
        
        //create external user - for the principal
        /*Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(principalContact);
        insert externalUser;
        */
    }
    
    static testMethod void test_request_access_prerequisite_method() {
        test.startTest();
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        test.stopTest(); 
        
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];

        String testUserId = testUser.Id;
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        string expectedResultString = 'allow request access';
        string expectedJSONContent = '{"statusCode":200,"status":"OK","prerequisite":"allow request access"}';

        
        String JSONContent = OnboardingController.request_access_prerequisite('filtering-portal', testUserId);
        system.assertEquals(expectedJSONContent, JSONContent); 

       
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the statusCode - integer.
        Integer testStatusCode = parser.getIntegerValue();
        system.assertEquals(expectedStatusCode, testStatusCode); 
        

        parser.nextValue();
        // Get the status - text.
        String testStatus = parser.getText();
        system.assertEquals(expectedStatus, testStatus); 


         parser.nextValue();
        // Get the status - text.
        String testResultString = parser.getText();
        system.assertEquals(expectedResultString, testResultString); 
    }

    static testMethod void test_request_access_prerequisite_method_other_Products() {
        test.startTest();
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        test.stopTest(); 
        
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];

        String testUserId = testUser.Id;
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        string expectedResultString = 'allow request access';
        string expectedJSONContent = '{"statusCode":200,"status":"OK","prerequisite":"allow request access"}';

        
        String JSONContent = OnboardingController.request_access_prerequisite('Other', testUserId);
        system.assertEquals(expectedJSONContent, JSONContent); 

       
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the statusCode - integer.
        Integer testStatusCode = parser.getIntegerValue();
        system.assertEquals(expectedStatusCode, testStatusCode); 
        

        parser.nextValue();
        // Get the status - text.
        String testStatus = parser.getText();
        system.assertEquals(expectedStatus, testStatus); 


         parser.nextValue();
        // Get the status - text.
        String testResultString = parser.getText();
        system.assertEquals(expectedResultString, testResultString); 
    }

    static testMethod void test_request_access_prerequisite_method_negative1() {
        test.startTest();
        //create external user - for the other contact
        Contact ictContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email3@mismatched-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(ictContact);
        insert externalUser;
        test.stopTest(); 
        
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email3@mismatched-domain.com' ];

        String testUserId = testUser.Id;
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        string expectedResultString = 'forbid request access';
        string expectedJSONContent = '{"statusCode":400,"status":"BAD_REQUEST","prerequisite":"forbid request access","email":"email3@mismatched-domain.com","domain":"invalid-domain.com"}';

        
        String JSONContent = OnboardingController.request_access_prerequisite('filtering-portal', testUserId);
        system.assertEquals(expectedJSONContent, JSONContent); 

       
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the statusCode - integer.
        Integer testStatusCode = parser.getIntegerValue();
        system.assertEquals(expectedStatusCode, testStatusCode); 
        

        parser.nextValue();
        // Get the status - text.
        String testStatus = parser.getText();
        system.assertEquals(expectedStatus, testStatus); 


         parser.nextValue();
        // Get the status - text.
        String testResultString = parser.getText();
        system.assertEquals(expectedResultString, testResultString); 
    }

    static testMethod void test_request_access_prerequisite_method_negative2() {

        String testUserId = '0055P000000UzlFQAS';
        integer expectedStatusCode = 404;
        string expectedStatus = 'NOT_FOUND';
        string expectedResultString = 'Could not find a User record with id = ' + testUserId;
        string expectedJSONContent = '{"statusCode":404,"status":"NOT_FOUND","error":"Could not find a User record with id = 0055P000000UzlFQAS"}';

        
        String JSONContent = OnboardingController.request_access_prerequisite('filtering-portal', testUserId);
        system.assertEquals(expectedJSONContent, JSONContent); 

       
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the statusCode - integer.
        Integer testStatusCode = parser.getIntegerValue();
        system.assertEquals(expectedStatusCode, testStatusCode); 
        

        parser.nextValue();
        // Get the status - text.
        String testStatus = parser.getText();
        system.assertEquals(expectedStatus, testStatus); 


         parser.nextValue();
        // Get the status - text.
        String testResultString = parser.getText();
        system.assertEquals(expectedResultString, testResultString); 
    }

    static testMethod void test_request_access_prerequisite_method_negative3() {
        
        String testUserId = null;
        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        string expectedResultString = 'Missing userId';
        string expectedJSONContent = '{"statusCode":400,"status":"BAD_REQUEST","error":"Missing userId"}';

        
        String JSONContent = OnboardingController.request_access_prerequisite('filtering-portal', testUserId);
        system.assertEquals(expectedJSONContent, JSONContent); 

       
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the statusCode - integer.
        Integer testStatusCode = parser.getIntegerValue();
        system.assertEquals(expectedStatusCode, testStatusCode); 
        

        parser.nextValue();
        // Get the status - text.
        String testStatus = parser.getText();
        system.assertEquals(expectedStatus, testStatus); 


         parser.nextValue();
        // Get the status - text.
        String testResultString = parser.getText();
        system.assertEquals(expectedResultString, testResultString); 
    }

    static testMethod void test_request_access_prerequisite_method_negative4() {
        test.startTest();
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        test.stopTest(); 
        
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];

        //intended to get 401 UNAUTHORIZED response.
        Account account = [SELECT id, Onboarding_Filtering_Portal__c FROM Account WHERE id =: testUser.Contact.AccountId ];
        account.Onboarding_Filtering_Portal__c = null;
        update account;

        String testUserId = testUser.Id;
        integer expectedStatusCode = 401;
        string expectedStatus = 'UNAUTHORIZED';
        string expectedResultString = 'forbid request access';
        string expectedJSONContent = '{"statusCode":401,"status":"UNAUTHORIZED","prerequisite":"forbid request access"}';

        
        String JSONContent = OnboardingController.request_access_prerequisite('filtering-portal', testUserId);
        system.assertEquals(expectedJSONContent, JSONContent); 

       
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the statusCode - integer.
        Integer testStatusCode = parser.getIntegerValue();
        system.assertEquals(expectedStatusCode, testStatusCode); 
        

        parser.nextValue();
        // Get the status - text.
        String testStatus = parser.getText();
        system.assertEquals(expectedStatus, testStatus); 


         parser.nextValue();
        // Get the status - text.
        String testResultString = parser.getText();
        system.assertEquals(expectedResultString, testResultString); 
    }

    static testMethod void test_request_access_AuraEnabled_method_negative1() {
        //just to test and make sure it returns JSON string. It's ok to be 400 in this test. The rest of the detailed test are carried out in request_access_actions tests methods below.
        String testUserId = null;
        String testProductName = 'invalid-product-name';
        String testPartialURL = '';

        integer expectedStatusCode = 400;
        string expectedStatus = 'BAD_REQUEST';
        string expectedResultString = 'Invalid Product Name: ' + testProductName;
        string expectedJSONContent = '{"statusCode":400,"status":"BAD_REQUEST","error":"Invalid Product Name: invalid-product-name"}';

        
        String JSONContent = OnboardingController.request_access(testProductName, testUserId, testPartialURL);
        system.assertEquals(expectedJSONContent, JSONContent); 

       
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the statusCode - integer.
        Integer testStatusCode = parser.getIntegerValue();
        system.assertEquals(expectedStatusCode, testStatusCode); 
        

        parser.nextValue();
        // Get the status - text.
        String testStatus = parser.getText();
        system.assertEquals(expectedStatus, testStatus); 


         parser.nextValue();
        // Get the status - text.
        String testResultString = parser.getText();
        system.assertEquals(expectedResultString, testResultString); 
    }


    static testMethod void test_createOnboardingToken_method() {
        test.startTest();
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        test.stopTest(); 
        
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];

        Map<string, List<Contact>> roleBasedContacts = ContactController.getRoleBaseContacts(testUser.Contact.AccountId);
        Contact testApprover =  roleBasedContacts.get('Principal').get(0);

         MethodResponse testResponse = OnboardingController.createOnboardingToken(testUser, 'Filtering Portal');
         system.assertEquals(201,  testResponse.statusCode);
         
         Token__c testToken = testResponse.token;
         system.assertEquals(testUser.Contact.AccountId,  testToken.Account__c);
         system.assertEquals(testUser.ContactId,  testToken.Requester__c);
         system.assertEquals(testApprover.Id,  testToken.Approver__c); //the when creating the onboarding token, it should be able to pick approver of the school automatically
         system.assertEquals('Filtering Portal',  testToken.Type__c);
         system.assertEquals('Awaiting Approval',  testToken.Status__c);
         system.assertEquals(false,  testToken.IsClosed__c);
    }
    
    static testMethod void test_createOnboardingToken_Negative_method() {
        User testUser = null; //this should cause error in createOnboardingToken()
        String productName = 'Filtering Portal';
        MethodResponse testResponse = OnboardingController.createOnboardingToken(testUser, productName);
        system.assertEquals(400,  testResponse.statusCode); //should fail
        system.assertEquals(NULL,  testResponse.token);
    }
    
    static testMethod void test_generateResponseTokens_method() {
        test.startTest();
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        test.stopTest(); 
        
        //step 1: create a request case for external user
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];
        
        String productName = 'Filtering Portal';
        MethodResponse testResponse = OnboardingController.createOnboardingToken(testUser, productName);
        Token__c testToken = testResponse.token;

        //step 2: encode 2 JWT
        String type = productName;
        Map<String, String> testResponseTokens =  OnboardingController.generateResponseTokens(testToken, type);
        String testApprovedToken = testResponseTokens.get('approvedToken');
        String testDeclinedToken = testResponseTokens.get('declinedToken');
        
       
        //step 3: decode JWT to complete test - Approved Token
        Boolean isEncrypted = true;
        JWT testDecoded_ApprovedToken = JWTController.decodeJWT(type, testApprovedToken, isEncrypted);
        system.assertEquals(true, testDecoded_ApprovedToken.verified); 
        system.assertEquals(false, testDecoded_ApprovedToken.expired); 
        Map<String, Object> testDecoded_ApprovedToken_ClaimsMap = testDecoded_ApprovedToken.claims;
        system.assertEquals((2+2), testDecoded_ApprovedToken_ClaimsMap.size()); 
        system.assertEquals(testToken.Id, testDecoded_ApprovedToken_ClaimsMap.get('tokenId')); 
        system.assertEquals('approved', testDecoded_ApprovedToken_ClaimsMap.get('response')); 
        
        //step 4: decode JWT to complete test - Declined Token
        JWT testDecoded_DeclinedToken = JWTController.decodeJWT(type, testDeclinedToken, isEncrypted);
        system.assertEquals(true, testDecoded_DeclinedToken.verified); 
        system.assertEquals(false, testDecoded_DeclinedToken.expired); 
        Map<String, Object> testDecoded_DeclinedToken_ClaimsMap = testDecoded_DeclinedToken.claims;
        system.assertEquals((2+2), testDecoded_DeclinedToken_ClaimsMap.size()); 
        system.assertEquals(testToken.Id, testDecoded_DeclinedToken_ClaimsMap.get('tokenId')); 
        system.assertEquals('declined', testDecoded_DeclinedToken_ClaimsMap.get('response'));
        
    }
    
    static testMethod void test_request_access_actions_method() {
        test.startTest();
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        test.stopTest(); 
        
        //step 1: create a request case for external user
        User testUser = [SELECT id, username, name, contactId, AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];
        
        String productName = 'filtering-portal';
        String partialURL = 'https://onboarding-n4lportal.cs152.force.com/schoolictsupport/s/';
        MethodResponse testResponse = OnboardingController.request_access_actions(productName, testUser.Id, partialURL);
        system.assertEquals(200, testResponse.statusCode);
    }

    static testMethod void test_request_access_actions_method_negative1() {
        //to test wrong product name situation
        test.startTest();
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        test.stopTest(); 
        
        //step 1: create a request case for external user
        User testUser = [SELECT id, username, name, contactId, AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];
        
        String productName = 'invalid-product-name';
        String partialURL = 'https://onboarding-n4lportal.cs152.force.com/schoolictsupport/s/';
        MethodResponse testResponse = OnboardingController.request_access_actions(productName, testUser.Id, partialURL);
        system.assertEquals(400, testResponse.statusCode);
    }
    
    static testMethod void test_request_access_actions_method_negative2() {
        //to test could not find user record situation
        String testUserId = '0055P000000UzlFQAS';
        String productName = 'filtering-portal';
        String partialURL = 'https://onboarding-n4lportal.cs152.force.com/schoolictsupport/s/';
        MethodResponse testResponse = OnboardingController.request_access_actions(productName, testUserId, partialURL);
        system.assertEquals(404, testResponse.statusCode);
    }

    static testMethod void test_request_access_actions_method_negative3() {
        //to test missing userId
        String testUserId = null;
        String productName = 'filtering-portal';
        String partialURL = 'https://onboarding-n4lportal.cs152.force.com/schoolictsupport/s/';
        MethodResponse testResponse = OnboardingController.request_access_actions(productName, testUserId, partialURL);
        system.assertEquals(400, testResponse.statusCode);
    }

    static testMethod void test_Filtering_Portal_Request_Being_Approved(){
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        

        test.startTest(); //to test the result of @future method in @invocableMethod called from Process Builder, the DML must be seperated from the creation of external user above; and then test the result out side of test.stopTest();
        
        //step 1: create a request case for external user
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];
        
        String productName = 'Filtering Portal';
        MethodResponse testResponse = OnboardingController.createOnboardingToken(testUser, productName);
        Token__c testToken = testResponse.token;
        Id tokenId = testToken.Id;
        system.debug('>>>> testToken is ' + JSON.serializePretty(testToken));

        //step 2: generate Tokens
        String type = productName;
        Map<String, String> testResponseTokens =  OnboardingController.generateResponseTokens(testToken, type);
        String testApprovedToken = testResponseTokens.get('approvedToken');
        
        //step 3: test - processToken :Approved
        Boolean isEncrypted = true;
        JWT jwtApproved = JWTController.decodeJWT(type, testApprovedToken, isEncrypted); 
        
        system.debug('>>>> jwtApproved.claims is ' + JSON.serializePretty(jwtApproved.claims));
        MethodResponse res = OnboardingController.Filtering_Portal_Request_Approved_or_Declined(jwtApproved.claims); //DML occurs here.
        system.debug('>>>> res is ' + JSON.serializePretty(res));

        //step 4: run @invocableMethod of Process Builder. Otherwise Step 5's tests will fail
        //in unit test, we got to assume that Process Builder is not activated in production yet. Therefore we must explicitly call the @invocableMethod during unit test.
        //@InvocableMethod(label='Update User of a Contact' description='using @future method to update a customer user when a customer contact is updated.')
    	List<ID> ids = new List<ID>();
        ids.add(schoolContact.id);
        ContactController.updateUserOfContact(ids); //there is a @future method involved here. Therefore step 4 must be ran within test.stopTest()
            
        test.stopTest(); 
                
        //system.assertEquals('success', requestApprovedResult); 
        system.assertEquals(200, res.statusCode); 

        //the updated token should be Closed - Approved by now, and the contact should have access to FortiPortal
        testToken  = [SELECT id, Account__c, Account__r.Name, Requester__c, Requester__r.FirstName, Requester__r.Name, Requester__r.Email, Approver__r.FirstName, Approver__r.Name, Approver__r.Email,  Type__c, Status__c, IsClosed__c, ClosedDate__c, JWT1__c, JWT2__c FROM Token__c WHERE id =: tokenId LIMIT 1];

        system.assertEquals('Approved', testToken.Status__c); 
        system.assertEquals(TRUE, testToken.IsClosed__c); 
        system.assertEquals(TRUE, datetime.now().isSameDay(testToken.ClosedDate__c));
        
        //there is a @future method running when a Contact's Process Builder tries to update User record.
        Contact testContact = [SELECT id, FortiPortal_Access__c, FortiPortal_User_Role__c, account.Fortinet_Adom_Name__c FROM Contact WHERE id =: testToken.Requester__c LIMIT 1];
        system.assertEquals(true, testContact.FortiPortal_Access__c); 
        
        
        //step 5: test - user should have been updated based on contact's changes - now has access to forti portal
        //unit test assertions below were copied from ContactControllerTest.test_updateUser_FortiPortalfields_method()
        testUser = [SELECT id, username, contactId, accountId, FederationIdentifier, FortiPortal_User_Role__c, FortiPortal_Customer_Name__c, Fortinet_Adom_Name__c, UserPermissionsFilteringPortalUser__c FROM User WHERE contactId =: testContact.Id LIMIT 1];
        system.assertEquals(testUser.username, testUser.FederationIdentifier);
        system.assertEquals('Advanced', testUser.FortiPortal_User_Role__c);
        system.assertEquals(testContact.account.Fortinet_Adom_Name__c, testUser.Fortinet_Adom_Name__c);
        system.assertEquals('sparkb.co.nz', testUser.FortiPortal_Customer_Name__c);
        system.assertEquals(true, testUser.UserPermissionsFilteringPortalUser__c);
    }
    
    static testMethod void test_Filtering_Portal_Request_Being_Declined(){
        
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        
        test.startTest(); //to test the result of @future method in @invocableMethod called from Process Builder, the DML must be seperated from the creation of external user above; and then test the result out side of test.stopTest();

        //step 1: create a request case for external user
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];
        
        String productName = 'Filtering Portal';
        MethodResponse testResponse = OnboardingController.createOnboardingToken(testUser, productName);
        Token__c testToken = testResponse.token;        
        Id tokenId = testToken.Id;

        //step 2: generate Tokens
        String type = productName;
        Map<String, String> testResponseTokens =  OnboardingController.generateResponseTokens(testToken, type);
        String testDeclinedToken = testResponseTokens.get('declinedToken');
        
        
        Boolean isEncrypted = true;

        //step 5: test - processToken :Declined
        JWT jwtDeclined = JWTController.decodeJWT(type, testDeclinedToken, isEncrypted); 
        
        MethodResponse res = OnboardingController.Filtering_Portal_Request_Approved_or_Declined(jwtDeclined.claims); //DML occurs here.
        
        test.stopTest(); 

        //system.assertEquals('success', requestDeclinedResult); 
        system.assertEquals(200, res.statusCode); 

        //the updated token should be Closed - Approved by now, and the contact should have access to FortiPortal
        testToken  = [SELECT id, Account__c, Account__r.Name, Requester__c, Requester__r.FirstName, Requester__r.Name, Requester__r.Email, Approver__r.FirstName, Approver__r.Name, Approver__r.Email,  Type__c, Status__c, IsClosed__c, ClosedDate__c, JWT1__c, JWT2__c FROM Token__c WHERE id =: tokenId LIMIT 1];

        system.assertEquals('Declined', testToken.Status__c); 
        system.assertEquals(TRUE, testToken.IsClosed__c); 
        system.assertEquals(TRUE, datetime.now().isSameDay(testToken.ClosedDate__c));

        Contact testContact = [SELECT id, FortiPortal_Access__c, FortiPortal_User_Role__c, account.Fortinet_Adom_Name__c FROM Contact WHERE id =: testToken.Requester__c LIMIT 1];
        system.assertEquals(false, testContact.FortiPortal_Access__c); 

        //step 6: test - user should have been updated based on contact's changes and the user should not have access to FortiPortal
        testUser = [SELECT id, username, contactId, accountId, FederationIdentifier, FortiPortal_User_Role__c, FortiPortal_Customer_Name__c, Fortinet_Adom_Name__c, UserPermissionsFilteringPortalUser__c FROM User WHERE contactId =: schoolContact.Id LIMIT 1];
        system.assertEquals(testUser.username, testUser.FederationIdentifier);
        system.assertEquals('Advanced', testUser.FortiPortal_User_Role__c);
        system.assertEquals(testContact.account.Fortinet_Adom_Name__c, testUser.Fortinet_Adom_Name__c);
        system.assertEquals(true, String.isBlank(testUser.FortiPortal_Customer_Name__c));
        system.assertEquals(false, testUser.UserPermissionsFilteringPortalUser__c);

    }
    
     static testMethod void test_Filtering_Portal_Request_Approved_or_Declined_negative_test1(){
         //Expectation: when a JWT is generated but missing a case id, it should return 400
        test.startTest(); //to test the result of @future method in @invocableMethod called from Process Builder, the DML must be seperated from the creation of external user above; and then test the result out side of test.stopTest();
        //step 1: no Case!

        //step 2: generate Tokens
        String type = 'Filtering Portal';
		Boolean isEncrypted = true;
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('response', 'approved');
        String testApprovedToken = JWTController.issueJWT(type, claimsMap, isEncrypted); //creating jwt without tokenId
        
        //step 3: test - processToken :Approved without case
        JWT jwtApproved = JWTController.decodeJWT(type, testApprovedToken, isEncrypted); 
        MethodResponse res = OnboardingController.Filtering_Portal_Request_Approved_or_Declined(jwtApproved.claims); //DML occurs here.

        test.stopTest(); 
       
        system.assertEquals(400, res.statusCode); 
        system.assertEquals('BAD_REQUEST', res.status); 
        system.assertEquals('Missing Token__c id in token claims', res.results.get('error')); 
    }
    
    static testMethod void test_Filtering_Portal_Request_Approved_or_Declined_negative_test2(){
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        Token__c testToken = new Token__c(account__c = schoolContact.AccountId);
        insert testToken;
        system.debug('>>>> testToken is ' + JSON.serializePretty(testToken));
        
        //Expectation: when a JWT is generated but with a non-existing case id, it should return 400
        test.startTest(); //to test the result of @future method in @invocableMethod called from Process Builder, the DML must be seperated from the creation of external user above; and then test the result out side of test.stopTest();
        //step 1: no Request Token!
        //String testTokenId = '5003000000D8cuIAAR'; //this is only an example record id. The code should not be able to find it here. from https://help.salesforce.com/articleView?id=000324087&language=en_US&type=1&mode=1
        String testTokenId = testToken.Id;
        

        //step 2: generate Tokens
        String type = 'Filtering Portal';
		Boolean isEncrypted = true;
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('tokenId', testTokenId);
        claimsMap.put('response', 'approved');
        String testApprovedToken = JWTController.issueJWT(type, claimsMap, isEncrypted); //creating jwt without caseId
        
        //step 3: test - processToken :Approved without case
        JWT jwtApproved = JWTController.decodeJWT(type, testApprovedToken, isEncrypted); 

        system.debug('>>>> jwtApproved.claims is ' + JSON.serializePretty(jwtApproved.claims));

        delete testToken; //remove the record, so that we cannot find it in this test, and cause the next line to fail and return 404.

        MethodResponse res = OnboardingController.Filtering_Portal_Request_Approved_or_Declined(jwtApproved.claims); //DML occurs here.

        
        test.stopTest(); 
       
        system.debug('>>>> res is ' + JSON.serializePretty(res));

        system.assertEquals(404, res.statusCode); 
        system.assertEquals('NOT_FOUND', res.status); 
        system.assertEquals('Could not find a Request Token__c record with id = "' + testTokenId + '"', res.results.get('error')); 
    }
}