@isTest
public class DaylightSavingFixdForDateTimeCtl_Test {
@TestSetup
    
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        
    }
    
    static testMethod void test_formatNZdatetime(){
        
        Test.startTest();
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Case testCase = [SELECT Id, accountId FROM Case WHERE accountId =: account.id limit 1];
        
        List<DaylightSavingFixdForDateTimeController.FlowInputs> flowInputs = new List<DaylightSavingFixdForDateTimeController.FlowInputs>();
        DaylightSavingFixdForDateTimeController.FlowInputs flowInput = new DaylightSavingFixdForDateTimeController.FlowInputs();
        flowInput.id = testCase.Id;
        flowInput.dt1 = '2022-11-01 14:51:31';
        flowInput.dt2 = '2022-11-03 14:33:31';
        
        flowInputs.add(flowInput);
        
        DaylightSavingFixdForDateTimeController.formatNZdatetime(flowInputs);
        
        
        Test.stopTest();
    }
}