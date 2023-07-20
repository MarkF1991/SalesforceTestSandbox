@isTest
public class SelfServiceRestTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(true); //Parameter False is for not creating Onboarding Case, Tasks, and Contract so that we can test it here.
    }
    
    static testMethod void PositiveCreateSSuserAccountTest(){
        //create account
        Account account1 = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        
        //create account
        Account account2 = TestClassUtility.createAccount('N4l Test School',  'School');
        account2.uuid__c = 'schoolb';
        account2.MoE_School_ID__c = '200';
        account2.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        insert account2;
        
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email4@invalid-domain.com'];
        String json = 
            '{'+
            '\"User\":'+
            '{'+
            '         \"FirstName\":\"Matt4\",'+
            '         \"LastName\":\"Jones\",'+
            '         \"Alias\":\"mjone4\",'+
            '         \"username\":\"Matt4.Jones@example.com\",'+
            '         \"email\":\"Matt4.Jones@example.com\",'+
            '         \"displayName\":\"Matt Jones\",'+
            '         \"ContactId\":\"'+contact.Id+'\"'+
            '},'+
            '         \"PWD\":\"Start00123!#\",'+
            '\"accountIds\":'+
            '['+
            '         \"'+account1.Id+'\",'+
            '         \"'+account2.Id+'\"'+
            '],'+
            '\"removeACRs\":'+
            '['+
            '         \"'+account2.Id+'\"'+
            ']'+
            '}';
           
        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/ss-user-registration';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        RestContext.request = request;
		system.Test.startTest();
        SelfServiceRest.doPost();
        system.Test.stopTest();
        
    }
    
}