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
private class calloutcontrollerTest {

    static testMethod void myUnitTest1() {
        Account a1 = TestObjectFactory.getAccount(true, 'Test Account', '1-Unregistered');
        system.debug('account id='+a1.id);
        Case c1 = TestObjectFactory.getCase(true, a1.Id, 'TSO Case', 'New', null);
        
         ApexPages.StandardController stdcase = new ApexPages.StandardController(c1);
	        calloutcontroller coc = new calloutcontroller(stdcase);
	        
	        coc.getExistingRestrictedAccessDetails();
            //coc.getIsFibreServiceExistAlready();
            coc.getPreferredInstallationTime();
            coc.getstandardfirstname();
            coc.getstandardlastname();
            coc.getstandardmobilenumber() ;
            coc.getstandardphonenumber(); 
            coc.checking();
            System.assertEquals(false,coc.isStatusOk);
            System.assertEquals(false,coc.allGood);
            //
            c1.New_Connection_Request_Order_ID__c='11111';
            update c1;
            coc.checking();
            System.assertEquals(true,coc.isExist);
            System.assertEquals(false,coc.allGood);
            c1.New_Connection_Request_Order_ID__c=null;
            c1.TCNZ_Work_Stream_Status__c='To Be Actioned';
            c1.Has_Environment_Risk__c='Yes';
            update c1;
            coc.checking();
            
    }
    
    static testMethod void myUnitTest2() {
        MoE_School_Site__c moes= new MoE_School_Site__c(MoE_Site_Name__c='site name');
        insert moes;
        Account a1 = TestObjectFactory.getAccount(true, 'Test Account', '1-Unregistered');
        system.debug('account id='+a1.id);
        a1= [select name,id from Account where id=:a1.id];
        //a1.name='test account name';
        a1.MoE_School_ID__c='12345';
        a1.MoE_Site_ID_Lookup__c= moes.id;
        a1.Managed_Network_Contract_Term__c ='5';
        a1.Service_Level__c='test level';
        a1.Postal_Address_1__c='test address1';
        a1.Postal_Address_2__c='test address2';
        a1.Postal_Address_3__c='test address3';
        a1.Suburb__c='test suburb';
        a1.City__c='test city';
        a1.Postal_Code__c='556677';
        a1.Street__c='test street';
        update a1;
        contact PrimaryContact = new contact(
        title='primary',firstname='primaryfirst',lastname='primarylast',
        phone='	021 345 678',mobilephone='021 345 678',email='primary@n4l.co.nz',accountid=a1.id);
        insert PrimaryContact;
        
        contact SecondaryContact = new contact(
        title='Secondary',firstname='Secondaryfirst',lastname='Secondarylast',
        phone='021 345 678',mobilephone='021 345 678',email='Secondary@n4l.co.nz',accountid=a1.id);
        insert SecondaryContact;
        
        Case c1 = TestObjectFactory.getCase(true, a1.Id, 'TSO Case', 'New', null);
          
	        c1.TCNZ_Work_Stream_Status__c='To Be Actioned';
            c1.Has_Environment_Risk__c='Yes';
            c1.contactid=PrimaryContact.id;
            c1.Secondary_Contact__c = SecondaryContact.id;
            c1.Web_Filtering_Administrator_Username__c='Web@n4l.co.nz';
            update c1;
            c1=[select owner.firstname,owner.lastname,owner.email,casenumber,account.name,Account.TCNZ_Common_Name__c,Account.MoE_School_ID__c,Account.MoE_Site_ID_Lookup__r.name,Account.Total_Users__c,Account.Managed_Network_Contract_Term__c,Account.School_Signed_Base_Connection__r.TCNZ_Standard_Service_Option__c,Account.Service_Level__c,Account.Postal_Address_1__c,Account.Postal_Address_2__c,Account.Postal_Address_3__c,Account.Suburb__c,Account.City__c,Account.Postal_Code__c,Account.Street__c,Web_Filtering_Administrator_Username__c,
            contact.title,CLNE_Installation_Comment__c,Currently_Connected_To_A_Fibre_Service__c,Listed_ISP__c,Legacy_Internet_Connection_Type__c,HealthandSafetySecurityRequirements__c,Environment_Risk_Details__c,Has_Environment_Risk__c,Is_Restricted_Access__c,Is_UPS_Available__c,CLNE_Adheres_School_Site__c,X10m_Cable_Required__c,CLNE_Installation_In_Room_Location__c,CLNE_Installation_Room__c,CLNE_Installation_Building__c,CLNE_Installation_Level__c,Contact.FirstName,Contact.LastName,Contact.Phone,Contact.MobilePhone,Contact.Email,Secondary_Contact__r.title,Secondary_Contact__r.FirstName,Secondary_Contact__r.LastName,Secondary_Contact__r.Phone,Secondary_Contact__r.MobilePhone,Secondary_Contact__r.Email from case where id=:c1.id];
            ApexPages.StandardController stdcase = new ApexPages.StandardController(c1);
	        calloutcontroller coc = new calloutcontroller(stdcase);
	        coc.isTest=true;
	        HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/xml');
            res.setBody('<OrderId>112233</OrderId>');
            res.setStatusCode(201);
	        coc.resForTesting = res;
            coc.postRequest(); 
            res.setStatusCode(202);
            coc.resForTesting = res;
            coc.postRequest(); 
    }
}