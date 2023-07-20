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
public class TriggerOnSimpleSurveyTest { 

    static testMethod void updateSurveyCompletedTest(){
    
       // Account a1 = new Account(Name = 'test account', School_Migration_Status__c = '1-Unregistered');
        
        
        Account a1 = TestObjectFactory.getAccount(true, 'Test Account', '1-Unregistered');
        //insert a1;
		
        
        system.debug('account id='+a1.id);
        //Case c1 = new Case (status ='New',Origin='Email',AccountId=a1.id,RecordTypeId='01290000000SzFV',Product_Category__c='Pond');    
        Case c1 = TestObjectFactory.getCase(true, a1.Id, 'TSO Case', 'New', null);
        //insert c1;
        system.debug('case id='+c1.id);
         Test.startTest();
        simplesurvey__Survey__c s1 = new simplesurvey__Survey__c (simplesurvey__Case__c=c1.id);
        insert s1;
        system.debug('survey id='+s1.id);
        Test.stopTest();
        system.assertNotEquals(null, [select id,Survey_Completed__c from case where id=: c1.id ].Survey_Completed__c);
    }
}