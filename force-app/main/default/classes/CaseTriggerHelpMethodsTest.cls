/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CaseTriggerHelpMethodsTest {
    
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
		a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
		System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
		//Select d.Status__c, d.Provision_Case__c, d.Name, d.Customer__c From Device__c d
		Device__c d = new Device__c(Name='test001',status__c='Proposed',Customer__c=a.id,HostName__c='testHostname01');
		insert d;
        
		Case c = (case)TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
		Map<Id,Id> caseAccountMap = new Map<Id,Id>();
		caseAccountMap.put(c.id,a.id);
		Test.startTest();
		CaseTriggerHelpMethods.linkDeviceToTSOCase(caseAccountMap);
		Test.stopTest(); 
		System.assertEquals(c.id, [Select Provision_Case__c,id From Device__c where id=: d.id].Provision_Case__c);
    }
    
    static testMethod void oneTSOPerAccountTest() {
        // TO DO: implement unit test
        Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
		
		
		Test.startTest();
		Case c1 = (case)TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
		Test.stopTest(); 
		System.assertEquals(false, CaseTriggerHelpMethods.AccountHasNoTSOCase(a.id));
    }
}