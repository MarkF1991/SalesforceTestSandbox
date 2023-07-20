@IsTest
public with sharing class JWTControllerTest {
    @TestSetup
    private static void setup() {
        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola'; //for reporting test
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

       /*N4Lsettings__c setting = new N4Lsettings__c();
        setting.name = 'test';
        setting.secretKey__c = 'c3VwZXJzZWNyZXQ=';
        setting.cryptoKey__c = 'c3VwZXJzZWNyZXQ=';
        setting.certificate__c = 'jwtcert=';
        insert setting;
        */
        //create external user - for the principal
        /*Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(principalContact);
        insert externalUser;
		*/
	}

    static testMethod void test_authenticate_method() {
        //create internal user - relationship manager
        User rmUser = TestClassUtility.createInternalUser();
        insert rmUser;
        test.startTest();

        String uuid = 'schoola';
        String result = JWTController.authenticate(rmUser.Id);
        system.assertEquals(true, result.length() > 0); 
        test.stopTest(); 
    }

    static testMethod void test_issueJWT_method() {
        test.startTest();

        String type = 'Filtering Portal';
        Boolean isEncrypted = true;

        Map<String, Object> claimsMap = new Map<String, Object>();
        claimsMap.put('attribute1', 'value1');
        claimsMap.put('attribute2', 'value2');
        claimsMap.put('attribute3', 'value3');
        
        String result = JWTController.issueJWT(type, claimsMap, isEncrypted);
        system.assertEquals(true, result.length() > 0); 

        test.stopTest(); 
    }

    static testMethod void test_decodeJWT_method() {
         test.startTest();
        
        //step 1: encode a JWT
        String type = 'Filtering Portal';
        Boolean isEncrypted = true;

        Map<String, Object> claimsMap = new Map<String, Object>();
        claimsMap.put('attribute1', 'value1');
        claimsMap.put('attribute2', 'value2');
        claimsMap.put('attribute3', 'value3');

        String token = JWTController.issueJWT(type, claimsMap, isEncrypted);

        system.assertEquals(true, token.length() > 0); 
        system.assertEquals(false, token.contains('.')); //Encoded string does not have '.'


        //step 2: decode the JWT
        JWT testDecodedJWT = JWTController.decodeJWT(type, token, isEncrypted);
        system.assertEquals(true, testDecodedJWT.verified); 
        system.assertEquals(false, testDecodedJWT.expired); 
        Map<String, Object> testDecodedClaimsMap = testDecodedJWT.claims;
        system.assertEquals((3+2), testDecodedClaimsMap.size()); 
        system.assertEquals('value2', testDecodedClaimsMap.get('attribute2')); 

     
        test.stopTest(); 
    }

    static testMethod void test_decodeJWTintoMap_method() {
        test.startTest();
        
        //step 1: encode a JWT
        String type = 'Filtering Portal';
        Boolean isEncrypted = true;

        Map<String, Object> claimsMap = new Map<String, Object>();
        claimsMap.put('attribute1', 'value1');
        claimsMap.put('attribute2', 'value2');
        claimsMap.put('attribute3', 'value3');

        String token = JWTController.issueJWT(type, claimsMap, isEncrypted);

        system.assertEquals(true, token.length() > 0); 
        system.assertEquals(false, token.contains('.')); //Encoded string does not have '.'


        //step 2: decode the JWT for LWC
        Map<String, String> testDecodedJWTintoMap = JWTController.decodeJWTintoMap(type, token, isEncrypted);
        system.assertEquals('true', testDecodedJWTintoMap.get('verified')); 
        system.assertEquals('false', testDecodedJWTintoMap.get('expired')); 
     
        test.stopTest(); 
    }

    static testMethod void test_request_authorisation_action_method(){
        
        test.startTest();
            
        //step 1: encode a JWT
        String type = 'Filtering Portal';
        Boolean isEncrypted = true;

        Map<String, Object> claimsMap = new Map<String, Object>();
        claimsMap.put('unitTestEscaped', true); //for unit test to escape from method: OnboardingController.Filtering_Portal_Request_Approved_or_Declined()
        //claimsMap.put('response', 'approved');

        String token = JWTController.issueJWT(type, claimsMap, isEncrypted);

        //step 2: decode the JWT for LWC
        string productName = 'filtering-portal'; ////input comes from LWC ./request-authorisation page with url = ...?p=filtering-portal&t=blahblahblah
        MethodResponse authResponse = JWTController.request_authorisation_action(productName, token, null);
        
        system.assertEquals(200, authResponse.statusCode); 
        system.assertEquals('OK', authResponse.status); 
        //system.assertEquals('approved', authResponse.results.get('request_authorisation')); 
        
        //Invalid token
        token = 'thisIsInvalidToken-toshort-nobody';
        authResponse = JWTController.request_authorisation_action(productName, token, null);
        
        system.assertEquals(401, authResponse.statusCode); 
        system.assertEquals('UNAUTHORIZED', authResponse.status); 
        // system.assertEquals('Invalid Token', authResponse.results.get('request_authorisation')); 
        system.assertEquals('Unverified Token', authResponse.results.get('request_authorisation')); 

        //expired token
        //hardcoded token will not work here. token = 'I4ojeolJaiqey5JVxmcllUAxYpM2-hIIeahz8Hlbs779CeJqIIhYm6tYO9BnW1gxW7NMVRVZl3Rh1VgAeuZAzuEVt3Z1WaviBEcrJInuQX-5etxjkxPRWPNUgXfQsHzwOPl6lwwr7Hle1KFISnAr_JFYOItkvES4OpklcxKIXbLgvNeeCw3BU7GKgP1nB8gg-9JZpohNuKTked-XdCYZlI1XfZ7hZLtCN407X3C1k1yyf_z1o0H4gWQBfH6JEkWgTti-0vzv2MDM8SRu4_afP4P3qVsSg132XToa5LL7MHw';
        JWT jwt = new JWT('HS256', type); //so use HS256 instead, passing in type for JWT() constructor to get settings from Custom Metadata Types
        jwt.claims = claimsMap;
        jwt.validfor = -300; //make this token expired
        String expiredToken = jwt.issue(isEncrypted);
        
        authResponse = JWTController.request_authorisation_action(productName, expiredToken, null);
        
        system.assertEquals(401, authResponse.statusCode); 
        system.assertEquals('UNAUTHORIZED', authResponse.status); 
        system.assertEquals('Token Expired', authResponse.results.get('request_authorisation')); 

        //Unverified token
        token = 'thisisinvalidI4ojeolJaiqey5JVxmcllUAxYpM2-hIIeahz8Hlbs779CeJqIIhYm6tYO9BnW1gxW7NMVRVZl3Rh1VgAeuZAzuEVt3Z1WaviBEcrJInuQX-5etxjkxPRWPNUgXfQsHzwOPl6lwwr7Hle1KFISnAr_JFYOItkvES4OpklcxKIXbLgvNeeCw3BU7GKgP1nB8gg-9JZpohNuKTked-XdCYZlI1XfZ7hZLtCN407X3C1k1yyf_z1o0H4gWQBfH6JEkWgTti-0vzv2MDM8SRu4_afP4P3qVsSg132XToa5LL7MHw';
        authResponse = JWTController.request_authorisation_action(productName, token, null);
        
        system.assertEquals(401, authResponse.statusCode); 
        system.assertEquals('UNAUTHORIZED', authResponse.status); 
        system.assertEquals('Unverified Token', authResponse.results.get('request_authorisation')); 

        test.stopTest();
    }

    static testMethod void test_request_authorisation_action_method_400_BADREQUEST(){
        
        test.startTest();
            
        //step 1: encode a JWT
        String type = 'Filtering Portal';
        Boolean isEncrypted = true;

        Map<String, Object> claimsMap = new Map<String, Object>();
        //claimsMap.put('unitTestEscaped', true); //for unit test to escape from method: OnboardingController.Filtering_Portal_Request_Approved_or_Declined()
        claimsMap.put('unitTestEscaped', true);
        claimsMap.put('response', 'approved');

        String token = JWTController.issueJWT(type, claimsMap, isEncrypted);

        //step 2: decode the JWT for LWC
        string productName = 'invalid-product-name'; ////input comes from LWC ./request-authorisation page with url = ...?p=filtering-portal&t=blahblahblah
        MethodResponse authResponse = JWTController.request_authorisation_action(productName, token, null);
        
        system.assertEquals(400, authResponse.statusCode); 
        system.assertEquals('BAD_REQUEST', authResponse.status); 
        system.assertEquals('Invalid Product Name', authResponse.results.get('request_authorisation')); 
        
    }

    static testMethod void test_request_authorisation_AuraEnabled_method(){
        //only testing the 200 OK part. The rest of the 400 and 401 has been tested in test_request_authorisation_action_method() above
        test.startTest();
            
        //step 1: encode a JWT
        String type = 'Filtering Portal';
        Boolean isEncrypted = true;

        Map<String, Object> claimsMap = new Map<String, Object>();
        claimsMap.put('unitTestEscaped', true); //for unit test to escape from method: OnboardingController.Filtering_Portal_Request_Approved_or_Declined()
        //claimsMap.put('response', 'approved');

        String token = JWTController.issueJWT(type, claimsMap, isEncrypted);

        //step 2: decode the JWT for LWC
        string productName = 'filtering-portal'; ////input comes from LWC ./request-authorisation page with url = ...?p=filtering-portal&t=blahblahblah
        String JSONContent = JWTController.request_authorisation(productName, token);
        
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        string expectedJSONContent = '{"statusCode":200,"status":"OK","messages":[]}';

                
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


        test.stopTest();
    }

    static testMethod void test_request_authorisation_with_credential_AuraEnabled_method(){
        //only testing the 200 OK part. The rest of the 400 and 401 has been tested in test_request_authorisation_action_method() above
        test.startTest();
            
        //step 1: encode a JWT
        String type = 'MOU';
        Boolean isEncrypted = true;

        Map<String, Object> claimsMap = new Map<String, Object>();
        claimsMap.put('unitTestEscaped', true); //for unit test to escape from method: OnboardingController.Filtering_Portal_Request_Approved_or_Declined()
        //claimsMap.put('response', 'approved');

        String token = JWTController.issueJWT(type, claimsMap, isEncrypted);

        //step 2: decode the JWT for LWC
        string productName = 'mou'; ////input comes from LWC ./request-authorisation page with url = ...?p=filtering-portal&t=blahblahblah
        String JSONContent = JWTController.request_authorisation_with_credential(productName, token, null); //contactId is not nessary in this unit test. ContractControllerTest.test_getContractByToken_method() will take care of the details.
        
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        string expectedJSONContent = '{"statusCode":200,"status":"OK","messages":[]}';

                
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


        test.stopTest();
    }
}