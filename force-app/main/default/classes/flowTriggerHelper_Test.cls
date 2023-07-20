@isTest
public class flowTriggerHelper_Test{
    
    static testMethod void testCheckingTheCheckbox(){
        //insert the school record.
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account acc = new Account();
        acc.RecordTypeId = accountRecordTypeMapByName.get('School').getRecordTypeId();
        acc.Name = 'Test School Account Record';
        acc.Type = 'Base/Host School';
        acc.School_Migration_Status__c = '7-In Use';
        acc.MoE_School_ID__c = '98jiuiu098TEST';
        insert acc;
        
        Account acc1 = new Account();
        acc1.RecordTypeId = accountRecordTypeMapByName.get('Non-School Organisation').getRecordTypeId();
        acc1.Name = 'Test ICT Account Record';
        //acc1.Type = 'Commercial';//n4l
        acc1.Type = 'School ICT Provider';
        acc1.N4L_accreditation__c = 'RFP Approved';
        insert acc1;
        
        Test.startTest();
        
        Map<String,Schema.RecordTypeInfo> junctionRecordTypeMapByName = Schema.SObjectType.Related_School_ICTProvider__c.getRecordTypeInfosByName();
        
        Related_School_ICTProvider__c junctionRec = new Related_School_ICTProvider__c();
        junctionRec.RecordTypeId = junctionRecordTypeMapByName.get('School ICT Provider').getRecordTypeId();
        junctionRec.ICT_Provider__c = acc1.id;
        junctionRec.School__c = acc.id;
        junctionRec.Relationship__c = 'Primary / Contracted';
        junctionRec.School_Data_Sharing_on_Portal_Authorised__c = true;
        junctionRec.Status__c = 'Current';
        insert junctionRec;
        
        Test.stopTest();
        Related_School_ICTProvider__c finalRec = [select Public_Group_ID__c, Account_Share_ID__c from Related_School_ICTProvider__c where id =: junctionRec.id];
        system.assertNotEquals(finalRec.Public_Group_ID__c, Null);
        system.assertNotEquals(finalRec.Account_Share_ID__c, Null);
        
        
    }  

    static testMethod void testUncheckingTheCheckbox(){
        //insert the school record.
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account acc = new Account();
        acc.RecordTypeId = accountRecordTypeMapByName.get('School').getRecordTypeId();
        acc.Name = 'Test School Account Record';
        acc.Type = 'Base/Host School';
        acc.School_Migration_Status__c = '7-In Use';
        acc.MoE_School_ID__c = '98jiuiu098TEST';
        insert acc;
        
        Account acc1 = new Account();
        acc1.RecordTypeId = accountRecordTypeMapByName.get('Non-School Organisation').getRecordTypeId();
        acc1.Name = 'Test ICT Account Record';
        //acc1.Type = 'Commercial';//n4l
        acc1.Type = 'School ICT Provider';
        acc1.N4L_accreditation__c = 'RFP Approved';
        insert acc1;
        
        Map<String,Schema.RecordTypeInfo> junctionRecordTypeMapByName = Schema.SObjectType.Related_School_ICTProvider__c.getRecordTypeInfosByName();
        
        Related_School_ICTProvider__c junctionRec = new Related_School_ICTProvider__c();
        junctionRec.RecordTypeId = junctionRecordTypeMapByName.get('School ICT Provider').getRecordTypeId();
        junctionRec.ICT_Provider__c = acc1.id;
        junctionRec.School__c = acc.id;
        junctionRec.Relationship__c = 'Primary / Contracted';
        junctionRec.School_Data_Sharing_on_Portal_Authorised__c = true;
        junctionRec.Status__c = 'Current';
        insert junctionRec;
        
        Test.startTest();
        
        junctionRec.School_Data_Sharing_on_Portal_Authorised__c = false;
        update junctionRec;
        
        Test.stopTest();
        Related_School_ICTProvider__c finalRec = [select Public_Group_ID__c, Account_Share_ID__c from Related_School_ICTProvider__c where id =: junctionRec.id];
        system.assertEquals(finalRec.Public_Group_ID__c, Null);
        system.assertEquals(finalRec.Account_Share_ID__c, Null);
        
    }

    static testMethod void testCreatingAnUser(){
        //insert the school record.
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account acc1 = new Account();
        acc1.RecordTypeId = accountRecordTypeMapByName.get('Non-School Organisation').getRecordTypeId();
        acc1.Name = 'Test ICT Account Record';
        acc1.Type = 'Commercial';
        acc1.N4L_accreditation__c = 'RFP Approved';
        insert acc1;
        
        Map<String,Schema.RecordTypeInfo> contactRecordTypeMapByName = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact c = new Contact();
        c.accountId = acc1.id;
        c.LastName = 'Contact Test';
        c.FirstName = 'First Name';
        //c.RecordTypeId = contactRecordTypeMapByName.get('Generic Contact (Role Based)').getRecordTypeId();//n4l
        c.Created_From__c = 'SF Front End';
        c.Role_Based_Contact_Profile__c = 'Central Contact; Outage Contact';
        c.email ='flowTriggerHelperTest01@n4l.com';//n4l
        insert c;
        
        Test.startTest();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Support Hub ICT Provider Admin User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, contactId = c.id,
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');
        insert u;
        
        Test.stopTest();
        
        
    }
}