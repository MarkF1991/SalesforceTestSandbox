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
@isTest (SeeAllData=true)
private class ScheduleBatchManageTSOCalculationTest {

    static testMethod void myUnitTest() {
    	
    	Account a1 = TestObjectFactory.getAccount(true, 'Test Account', '1-Unregistered');
        system.debug('account id='+a1.id);
        Case c1 = TestObjectFactory.getCase(true, a1.Id, 'TSO Case', 'New', null);
        system.debug('case id='+c1.id);
        c1.TCNZ_Work_Order_Submitted_Date__c= system.now().addDays(-7);
        c1.TCNZ_Service_Order_Accepted_Date__c = system.now().addDays(-6);
        c1.LFC_Order_Submitted_Date__c = system.now().addDays(-5);
        c1.LFC_Access_RFS_Date__c = system.now().addDays(-4);
        c1.SoW_Submitted_Date__c = system.now().addDays(-3);
    	c1.Audit_Completed_Date__c = system.now().addDays(-2);
    	update c1;
        test.startTest();
    ScheduleBatchManageTSOCalculation mytest = new ScheduleBatchManageTSOCalculation();
    system.debug('mydebug.......'+mytest.bolIsTest);
    
    mytest.bolIsTest=true;
    system.debug('mydebug.......'+mytest.bolIsTest);
    String jobId = System.schedule('ScheduleBatchManageTSOCalculationTEST', '0 0 0-23 * * ?', mytest);
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        System.debug('## TEST METHOD - CronTrigger Next Fire Time: ' + ct.NextFireTime);
        Test.stopTest();
        System.debug('## TEST METHOD - Stop test');    
    
    }
}