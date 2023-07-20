@isTest
public class SandboxRefresh_test {
@TestSetup
    
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        
    }

        static testMethod void SandboxRefresh_RevertUserEmail_Ctl_test(){
            SandboxRefresh_RevertUserEmail_Ctl sdbxRevertUserEmail = new SandboxRefresh_RevertUserEmail_Ctl();
            Test.startTest();
            if (Test.isRunningTest()){
                Id batchJobId = Database.executeBatch(sdbxRevertUserEmail);
            }          
            Test.stopTest();
            
        }
    
    static testMethod void SandboxRefresh_ModifyCttEmail_Ctl_test(){
            SandboxRefresh_ModifyCttEmail_Ctl sdbxMdfCttEmail = new SandboxRefresh_ModifyCttEmail_Ctl();
            Test.startTest();
            if (Test.isRunningTest()){
                Id batchJobId = Database.executeBatch(sdbxMdfCttEmail);
            }          
            Test.stopTest();
            
        }
    
    static testMethod void SandboxRefresh_ModifyActEmail_Ctl_test(){
            SandboxRefresh_ModifyActEmail_Ctl sdbxMdfActEmail = new SandboxRefresh_ModifyActEmail_Ctl();
            Test.startTest();
            if (Test.isRunningTest()){
                Id batchJobId = Database.executeBatch(sdbxMdfActEmail);
            }          
            Test.stopTest();
            
        }
}