@IsTest
public with sharing class SupportHubInviteSignupControllerTest {
    @TestSetup
    
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        
    }

    static testMethod void test_createToken() {
        test.startTest();

        String type='Invite-SignUp';
        String userOrigin = 'N4L Invitation - Default';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        test.stopTest(); 

        MethodResponse testResponse = SupportHubInviteSignupController.createToken(contact, type, userOrigin);

        System.assertEquals(201, testResponse.statuscode);

    }

    static testMethod void test_generateResponseTokens() {
        test.startTest();

        String type='Invite-SignUp';
        String userOrigin = 'N4L Invitation - Default';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        test.stopTest(); 

        MethodResponse testResponse = SupportHubInviteSignupController.createToken(contact, type, userOrigin);

        Token__c token = testResponse.token;

        Map<String, String> testResult = SupportHubInviteSignupController.generateResponseTokens(token, type);

        system.assertEquals(False, testResult.isEmpty());

    }

    static testMethod void test_InviteToCreateUser_email_actions() {
        test.startTest();

        String userOrigin = 'N4L Invitation - Default';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        test.stopTest(); 

        MethodResponse testResponse = SupportHubInviteSignupController.InviteToCreateUser_email_actions(contact, userOrigin);
        
        System.assertEquals(200, testResponse.statuscode);

    }

    //without contact 
    static testMethod void test_InviteToCreateCustomerUser() {
        test.startTest();

        String userOrigin = 'Self-SignUp';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        contact.clear();
        test.stopTest(); 

        List<Map<String, String>> testResult = SupportHubInviteSignupController.InviteToCreateCustomerUser(contact.id, userOrigin);
       
        system.assertEquals(False, testResult.isEmpty());


    }

        //another nagetive test for with contact and user;
        static testMethod void negativeTest01_InviteToCreateCustomerUser() {
            test.startTest();

            String userOrigin = 'Self-SignUp';
            Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
            test.stopTest(); 
    
            List<Map<String, String>> testResult = SupportHubInviteSignupController.InviteToCreateCustomerUser(contact.id, userOrigin);
           
            system.assertEquals(False, testResult.isEmpty());

            
        }

        //with contact and no user
    static testMethod void negativeTest02_InviteToCreateCustomerUser() {
        test.startTest();

        String userOrigin = 'Self-SignUp';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email3@invalid-domain.com'];
        test.stopTest(); 

        List<Map<String, String>> testResult = SupportHubInviteSignupController.InviteToCreateCustomerUser(contact.id, userOrigin);

        system.assertEquals(False, testResult.isEmpty());


    }

    static testMethod void test_RespondedToCreateUserByInvitation01() {
        test.startTest();
  
        String type='Invite-SignUp';
        String userOrigin = 'N4L Invitation - Default';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];

        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';

        MethodResponse testResponse = SupportHubInviteSignupController.createToken(contact, type, userOrigin);
        Token__c token = testResponse.token;

        Map<String, Object> claimsMap = New Map<String, Object>();
        claimsMap.put('tokenId', token.id);
        
        test.stopTest(); 

        MethodResponse res = SupportHubInviteSignupController.RespondedToCreateUserByInvitation(claimsMap); 
        system.assertEquals(expectedStatusCode, res.statusCode); 
        system.assertEquals(expectedStatus, res.status); 
    }

    static testMethod void test_RespondedToCreateUserByInvitation02() {
        test.startTest();
  
        String type='Invite-SignUp';
        String userOrigin = 'N4L Invitation - Default';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email3@invalid-domain.com'];

        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';

        MethodResponse testResponse = SupportHubInviteSignupController.createToken(contact, type, userOrigin);
        Token__c token = testResponse.token;

        Map<String, Object> claimsMap = New Map<String, Object>();
        claimsMap.put('tokenId', token.id);
        
        test.stopTest(); 

        MethodResponse res = SupportHubInviteSignupController.RespondedToCreateUserByInvitation(claimsMap); 
        system.assertEquals(expectedStatusCode, res.statusCode); 
        system.assertEquals(expectedStatus, res.status); 
    }

    static testMethod void test_RespondedToCreateUserByInvitation03() {
        test.startTest();
  
        String type='Invite-SignUp';
        String userOrigin = 'N4L Invitation - Default';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email3@invalid-domain.com'];

        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';

        MethodResponse testResponse = SupportHubInviteSignupController.createToken(contact, type, userOrigin);
        Token__c token = testResponse.token;
        token.IsClosed__c = true;
        update token;

        Map<String, Object> claimsMap = New Map<String, Object>();
        claimsMap.put('tokenId', token.id);
        
        test.stopTest(); 

        MethodResponse res = SupportHubInviteSignupController.RespondedToCreateUserByInvitation(claimsMap); 
        system.assertEquals(expectedStatusCode, res.statusCode); 
        system.assertEquals(expectedStatus, res.status); 
    }
    
    static testMethod void test_inviteBtnIsClicked() {
        test.startTest();
  
        String type='Invite-SignUp';
        String userOrigin = 'N4L Invitation - Default';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email3@invalid-domain.com'];

        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';

        MethodResponse testResponse = SupportHubInviteSignupController.createToken(contact, type, userOrigin);
        Token__c token = testResponse.token;
        token.IsClosed__c = true;
        update token;
        
        test.stopTest(); 
        
        boolean isTrue = SupportHubInviteSignupController.inviteBtnIsClicked(contact.Id);
        
        system.assertEquals(True, isTrue);
    }
    
    static testMethod void test_InviteBtnClickedTime() {
        test.startTest();
  
        String type='Invite-SignUp';
        String userOrigin = 'N4L Invitation - Default';
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email3@invalid-domain.com'];

        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';

        MethodResponse testResponse = SupportHubInviteSignupController.createToken(contact, type, userOrigin);
        Token__c token = testResponse.token;
        token.IsClosed__c = true;
        update token;
        
        test.stopTest(); 
        
        string clickedTime = SupportHubInviteSignupController.inviteBtnClickedTime(contact.Id);
        
        system.assertEquals(False, string.isEmpty(clickedTime));
    }
    

}