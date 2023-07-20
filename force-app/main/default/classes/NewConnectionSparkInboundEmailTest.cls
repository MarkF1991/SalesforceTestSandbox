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
@isTest (seeAlldata=true)
private class NewConnectionSparkInboundEmailTest {

    static testMethod void myUnitTest1() {
        Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    //System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
    //perform test
    //Test.startTest();
    Case c = (case)TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
    c =[select id,casenumber from case where id=:c.id limit 1];
    system.debug('case number'+c.casenumber);
    
    //Test.stopTest(); 
        Device__c d= new Device__c(Provision_Case__c=c.id,name='test Device',Status__c='Proposed',Installed_N4L_Asset__c=null,Customer__c=a.id);
        insert d;
        system.debug('device id='+d.id);
        /*
        new Customer_Firewall_Zone__c(CLNE__c=d.id,name='INTERNET');
        Customer_Firewall_Zone__c fz2= new Customer_Firewall_Zone__c(CLNE__c=d.id,name='SERVICES');
        list<Customer_Firewall_Zone__c> fz= new list<Customer_Firewall_Zone__c>();
        fz.add(fz1); fz.add(fz2); 
        insert fz;
        system.debug('fz1 id='+fz1.id);
        system.debug('fz2 id='+fz2.id);
*/        
        Device_Port__c dp = new Device_Port__c(Device__c=d.id,LAN_WAN__c='WAN');
        insert dp;
        system.debug('dp id='+dp.id);
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.plainTextBody = '<N4L TSO Case#>:'+c.casenumber+
      ' <Internet; Service IDL Number>:120687962;120687961 '+
      ' <Circuit IDA Number>:11223344 '+
      ' <Internet VLAN IP Address>:122.56.170.55 '+
      ' <Internet VLAN Next Hop IP>:122.56.170.54 '+
      ' <Service VLAN IP Address>:122.56.174.55 '+
      ' <Service VLAN Next Hop IP>:122.56.174.54 '+
      ' Site Contact Email   test@salesforce.com '+
      ' Authorised BY  test11 '+
      ' <END> '
      ;
      
      email.subject='New Connection IPs & IDLs update';
      system.debug('xxxxxxxxxxxxxx'+email.plainTextBody);
      email.fromAddress ='xxxx@salesforce.com';
  Test.startTest(); 
  NewConnectionSparkInboundEmail ncsie = new NewConnectionSparkInboundEmail();
  ncsie.handleInboundEmail(email, env);
  
    System.assertEquals('', ncsie.errorInfo);    
    ncsie.handleInboundEmail(email, env);//update
   email.subject='progress update';   
   ncsie.handleInboundEmail(email, env);
   email.subject='xxxx'; 
   ncsie.handleInboundEmail(email, env);
   Test.stopTest(); 
    }
    
    static testMethod void myUnitTest2() {
        Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    //System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
    //perform test
    //Test.startTest();
    Case c = (case)TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
    c =[select id,casenumber from case where id=:c.id limit 1];
    system.debug('case number'+c.casenumber);
    //Test.stopTest(); 
        
         Messaging.InboundEmail email = new Messaging.InboundEmail();
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.plainTextBody = '<N4L TSO Case#>:'+c.casenumber+
      ' <Internet; Service IDL Number>:120687962;120687961 '+
      ' <Circuit IDA Number>:11223344 '+
      ' <Internet VLAN IP Address>:122.56.170.55 '+
      ' <Internet VLAN Next Hop IP>:122.56.170.54 '+
      ' <Service VLAN IP Address>:122.56.174.55 '+
      ' <Service VLAN Next Hop IP>:122.56.174.54 '+
      ' Site Contact Email   test@salesforce.com '+
      ' Authorised BY  test11 '+
      ' <END> '
      ;
      
      email.subject='New Connection IPs & IDLs update';
      system.debug('xxxxxxxxxxxxxx'+email.plainTextBody);
      email.fromAddress ='xxxx@salesforce.com';
  Test.startTest(); 
  NewConnectionSparkInboundEmail ncsie = new NewConnectionSparkInboundEmail();
  ncsie.handleInboundEmail(email, env);
  
  Test.stopTest(); 
    }
    
    static testMethod void myUnitTest3() {
        Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    //System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
    //perform test
    //Test.startTest();
    Case c = (case)TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
    c =[select id,casenumber from case where id=:c.id limit 1];
    system.debug('case number'+c.casenumber);
    //Test.stopTest(); 
        Device__c d= new Device__c(Provision_Case__c=c.id,name='test Device',Status__c='Proposed',Installed_N4L_Asset__c=null,Customer__c=a.id);
        insert d;
        system.debug('device id='+d.id);
        /*
        Customer_Firewall_Zone__c fz1= new Customer_Firewall_Zone__c(CLNE__c=d.id,name='INTERNET');
        Customer_Firewall_Zone__c fz2= new Customer_Firewall_Zone__c(CLNE__c=d.id,name='SERVICES');
        list<Customer_Firewall_Zone__c> fz= new list<Customer_Firewall_Zone__c>();
        fz.add(fz1); fz.add(fz2); 
        insert fz;
        system.debug('fz1 id='+fz1.id);
        system.debug('fz2 id='+fz2.id);
        */
        Messaging.InboundEmail email = new Messaging.InboundEmail();
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.plainTextBody = '<N4L TSO Case#>:'+c.casenumber+
      ' <Internet; Service IDL Number>:120687962;120687961 '+
      ' <Circuit IDA Number>:11223344 '+
      ' <Internet VLAN IP Address>:122.56.170.55 '+
      ' <Internet VLAN Next Hop IP>:122.56.170.54 '+
      ' <Service VLAN IP Address>:122.56.174.55 '+
      ' <Service VLAN Next Hop IP>:122.56.174.54 '+
      ' Site Contact Email   test@salesforce.com '+
      ' Authorised BY  test11 '+
      ' <END> '
      ;
      
      email.subject='New Connection IPs & IDLs update';
      system.debug('xxxxxxxxxxxxxx'+email.plainTextBody);
      email.fromAddress ='xxxx@salesforce.com';
  Test.startTest(); 
  NewConnectionSparkInboundEmail ncsie = new NewConnectionSparkInboundEmail();
  ncsie.handleInboundEmail(email, env);
  Test.stopTest(); 
    System.assertEquals('', ncsie.errorInfo);    
    }
    
    static testMethod void myUnitTest4() {
        Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    //System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
    //perform test
    //Test.startTest();
    Case c = (case)TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
    c =[select id,casenumber from case where id=:c.id limit 1];
    system.debug('case number'+c.casenumber);
    //Test.stopTest(); 
        Device__c d= new Device__c(Provision_Case__c=c.id,name='test Device',Status__c='Proposed',Installed_N4L_Asset__c=null,Customer__c=a.id);
        insert d;
        system.debug('device id='+d.id);
        Device_Port__c dp = new Device_Port__c(Device__c=d.id,LAN_WAN__c='WAN');
        insert dp;
        system.debug('dp id='+dp.id);
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.plainTextBody = '<N4L TSO Case#>:'+c.casenumber+
      ' <Internet; Service IDL Number>:120687962;120687961 '+
      ' <Circuit IDA Number>:11223344 '+
      ' <Internet VLAN IP Address>:122.56.170.55 '+
      ' <Internet VLAN Next Hop IP>:122.56.170.54 '+
      ' <Service VLAN IP Address>:122.56.174.55 '+
      ' <Service VLAN Next Hop IP>:122.56.174.54 '+
      ' Site Contact Email   test@salesforce.com '+
      ' Authorised BY  test11 '+
      ' <END> '
      ;
      
      email.subject='New Connection IPs & IDLs update';
      system.debug('xxxxxxxxxxxxxx'+email.plainTextBody);
      email.fromAddress ='xxxx@salesforce.com';
  Test.startTest(); 
  NewConnectionSparkInboundEmail ncsie = new NewConnectionSparkInboundEmail();
  ncsie.handleInboundEmail(email, env);
  Test.stopTest(); 
    System.assertEquals('', ncsie.errorInfo);    
    }
    
    static testMethod void myUnitTest5() {
        Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    //System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
    //perform test
    //Test.startTest();
    Case c = (case)TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
    c =[select id,casenumber from case where id=:c.id limit 1];
    system.debug('case number'+c.casenumber);
    
    //Test.stopTest(); 
        Device__c d= new Device__c(Provision_Case__c=c.id,name='test Device',Status__c='Proposed',Installed_N4L_Asset__c=null,Customer__c=a.id);
        insert d;
        system.debug('device id='+d.id);
        /*
        Customer_Firewall_Zone__c fz1= new Customer_Firewall_Zone__c(CLNE__c=d.id,name='INTERNET');
        Customer_Firewall_Zone__c fz2= new Customer_Firewall_Zone__c(CLNE__c=d.id,name='SERVICES');
        list<Customer_Firewall_Zone__c> fz= new list<Customer_Firewall_Zone__c>();
        fz.add(fz1); fz.add(fz2); 
        insert fz;
        system.debug('fz1 id='+fz1.id);
        system.debug('fz2 id='+fz2.id);
*/
        Device_Port__c dp = new Device_Port__c(Device__c=d.id,LAN_WAN__c='WAN');
        insert dp;
        system.debug('dp id='+dp.id);
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.plainTextBody = '<N4L TSO Case#>:'+c.casenumber+
      ' <Internet; Service IDL Number>:'+
      ' <Circuit IDA Number>:11223344 '+
      ' <Internet VLAN IP Address>:122.56.170.55 '+
      ' <Internet VLAN Next Hop IP>:122.56.170.54 '+
      ' <Service VLAN IP Address>:122.56.174.55 '+
      ' <Service VLAN Next Hop IP>:122.56.174.54 '+
      ' Site Contact Email   test@salesforce.com '+
      ' Authorised BY  test11 '+
      ' <END> '
      ;
      
      email.subject='New Connection IPs & IDLs update';
      system.debug('xxxxxxxxxxxxxx'+email.plainTextBody);
      email.fromAddress ='xxxx@salesforce.com';
  Test.startTest(); 
  NewConnectionSparkInboundEmail ncsie = new NewConnectionSparkInboundEmail();
  ncsie.handleInboundEmail(email, env);
  
    System.assertNotEquals('', ncsie.errorInfo);    
   Test.stopTest(); 
    }
    
    static testMethod void myUnitTest6() {
        Account a = TestObjectFactoryTSO.getAccount(true, 'Test Account', '4-Contract Signed');
    a = [SELECT School_Migration_Status__c FROM Account WHERE Id = :a.Id];
    //System.assertEquals('4-Contract Signed', a.School_Migration_Status__c);
    //perform test
    //Test.startTest();
    Case c = (case)TestObjectFactoryTSO.getCase(true, a.Id, 'TSO Case', 'Under Action', 'Basic Only', null);
    c =[select CaseNumber,id, description,accountId,LFC_Truck_Roll_Scheduled_Date__c,
LFC_Access_RFS_Date__c,CLNE_Truck_Roll_Scheduled_Date__c,CLNE_Installed_Date__c from case where id=:c.id limit 1];
    system.debug('case number'+c.casenumber);
    
    //Test.stopTest(); 
        Device__c d= new Device__c(Provision_Case__c=c.id,name='test Device',Status__c='Proposed',Installed_N4L_Asset__c=null,Customer__c=a.id);
        insert d;
        system.debug('device id='+d.id);
        /*
        Customer_Firewall_Zone__c fz1= new Customer_Firewall_Zone__c(CLNE__c=d.id,name='INTERNET');
        Customer_Firewall_Zone__c fz2= new Customer_Firewall_Zone__c(CLNE__c=d.id,name='SERVICES');
        list<Customer_Firewall_Zone__c> fz= new list<Customer_Firewall_Zone__c>();
        fz.add(fz1); fz.add(fz2); 
        insert fz;
        system.debug('fz1 id='+fz1.id);
        system.debug('fz2 id='+fz2.id);
*/        
        Device_Port__c dp = new Device_Port__c(Device__c=d.id,LAN_WAN__c='WAN');
        insert dp;
        system.debug('dp id='+dp.id);
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.plainTextBody = '<N4L TSO Case#>:'+c.casenumber+
      ' <LFC Access RFS Date>: 21/10/2013 '+
      ' <LFC Status>:Request Accepted '+
      ' <CLNE Truckroll Scheduled Date>:27/11/2014 '+
      ' <CLNE Installed Date>: 5/11/2014 '+
      ' <END> ' ;
      
      email.subject='New Connection update';
      system.debug('xxxxxxxxxxxxxx'+email.plainTextBody);
      email.fromAddress ='xxxx@salesforce.com';
  Test.startTest(); 
  NewConnectionSparkInboundEmail ncsie = new NewConnectionSparkInboundEmail();
  ncsie.handleInboundEmail(email, env);
  
    System.assertEquals('', ncsie.errorInfo);    
    email.plainTextBody = '<N4L TSO Case#>:'+
      ' <LFC Access RFS Date>: 21/10/2013 '+
      ' <LFC Status>:Request Accepted '+
      ' <CLNE Truckroll Scheduled Date>:27/11/2014 '+
      ' <CLNE Installed Date>: 5/11/2014 '+
      ' <END> ' ;
  NewConnectionSparkInboundEmail ncsie2 = new NewConnectionSparkInboundEmail();
  ncsie.handleInboundEmail(email, env);
  email.plainTextBody = '<N4L TSO Case#>:'+c.casenumber+
      ' <LFC Access RFS Date>: '+
      ' <LFC Status>: test'+ 
      ' <CLNE Truckroll Scheduled Date>: '+
      ' <CLNE Installed Date>:  '+
      ' <END> ' ;
  NewConnectionSparkInboundEmail ncsie3 = new NewConnectionSparkInboundEmail();
  ncsie.handleInboundEmail(email, env);
      
   Test.stopTest(); 
    }
}