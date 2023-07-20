/** 
  * @author Jayson Faderanga (jfaderanga@deloitte.co.nz)
  * @date December 2019
  * @class AddGoogleDocController.cls
 **/
@isTest
public with sharing class AddGoogleDocControllerTest {
    
    @isTest
    static void attachAsReferenceTest() {

        String name = 'TestFile.doc';
        String url = 'https://docs.google.com/document/d/1Py3Xzzr4r49EvcGiEUoqRMc63k9HORBksU3RN5Ft343/edit';
        
        Account account = TestClassUtility.createAccount('Test Account', 'Non-School Organisation');

        Test.startTest();

        AddGoogleDocController.attachAsReference(account.Id, name, url);

        System.assertEquals(1, [SELECT count() FROM ContentVersion]);
        
        Test.stopTest();
    }
}