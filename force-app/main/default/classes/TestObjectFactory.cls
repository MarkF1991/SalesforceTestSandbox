/**
 * TestObjectFactory.cls
 * Collection of static methods that produce records for use in unit tests.
 * @author Logan Moore (Trineo)
 */
@isTest
public class TestObjectFactory {

    public static Account getAccount(Boolean doInsert, String accountName, String schoolMigrationStatus) {
        //MoE_School_Site__c moe = new MoE_School_Site__c(name='testmoe'); //commented out by Ben Soh 30/07/2020
        MoE_School_Site__c moe = new MoE_School_Site__c(); //Field is not writeable: MoE_School_Site__c.Name | This field became Autonumber after this class was created.
        insert moe;
        /*KLiu Added starts*/
        Device_Make_Model__c dev=new  Device_Make_Model__c(name='Cisco 2951',device_type__c='Router(CLNE)');
        insert dev;
        Product2 mn = new product2(Service_Bandwidth__c='50Mbps',name='50M Connection',Device_make_model__C=dev.Id,Product_type__C='Base Connection');
        insert mn;
        /*KLiu Added ends*/
        
        Account a = new Account();
        a.Name = accountName;
        a.School_Migration_Status__c = schoolMigrationStatus;
        a.MoE_Site_ID_Lookup__c=moe.id;
        a.Total_School_Roll__c=5;
        a.Teacher_Head_Count__c=2;
        a.Authority__c='State: Integrated'; //added by Ben Soh 30/07/2020 to avoid FIELD_CUSTOM_VALIDATION_EXCEPTION, Please specify the Authority type, as it is required with submission of new connection requests to Spark to associate the correct Spark Acc No: []
/*KLiu Added starts*/
      a.School_Signed_Base_Connection__c=mn.id;
/*KLiu Added ends*/    
        if (doInsert) {
            insert a;
        }
        return a;
    }

    public static Case getCase(Boolean doInsert, Id accountId, String recordTypeName, String status, String workStreamStatus) {
        Case c = new Case();
        c.Subject = 'Test Case';
        c.AccountId = accountId;
        c.Status = status;
        c.TCNZ_Work_Stream_Status__c = workStreamStatus;
        if (c.Status == 'Service Activated') {
            //c.Cutover_Date_Actual__c = Date.today();
            c.Cutover_Date_Actual__c = Datetime.now();
        }
        if (c.TCNZ_Work_Stream_Status__c == 'CLNE Installed with Service Configuration') {
            c.TCNZ_Service_Order_Completed_Date__c = Date.today();
        }
        // set the record type
        if (recordTypeName != null) {
            c.RecordTypeId = getCaseRecordTypeId(recordTypeName);
            System.assertNotEquals(null, c.RecordTypeId);
        }
        if (doInsert) {
            insert c;
        }
        return c;
    }

    static Map<String,Schema.RecordTypeInfo> caseRecordTypeMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
    static Id getCaseRecordTypeId(String recordTypeName){
        if (caseRecordTypeMapByName.containsKey(recordTypeName)) {
            return caseRecordTypeMapByName.get(recordTypeName).getRecordTypeId();
        }
        return null;
    }
}