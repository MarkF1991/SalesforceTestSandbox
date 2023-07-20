@IsTest
public class ServiceEventNetworkDesignControllerTest {
    @TestSetup
    private static void setup(){
        //TestObjectFactoryForOnboarding.setupOnboardingRecords(True); //Parameter True is for creating Onboarding Case, Tasks, and Contract we need them here in these test.
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
    }
    static testMethod void test_NetworkDesignLink_success(){
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];


        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'link';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + onboardingCase.Id + '",');
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "schoola",');
        json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + onboardingCase.OwnerId + '",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 
        
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        
        test.startTest();
        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignRouting(event); //hit NetworkDesignRouting to get to NetworkDesignLink
        //system.assertEquals(200, result.statusCode); n4l
        test.stopTest();

        //a case should be updated
        Case testCase = [SELECT Id, AccountId, Account.uuid__c, OwnerId, Owner.Name, Status , uuid__c, Design_Id__c FROM Case WHERE id =: onboardingCase.Id LIMIT 1];
        //system.assertEquals(data.networkDesign.x_id, testCase.Design_Id__c); n4l
        //system.assertEquals(data.networkDesign.assignedTo, testCase.OwnerId); n4l
        //system.assertEquals(data.networkDesign.salesforceCaseId, testCase.Id); n4l
        //system.assertEquals(data.networkDesign.caseId, testCase.uuid__c); n4l

        //Design Task should be updated
        List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId
                                FROM Task
                                WHERE RecordType.name = 'Onboarding' 
                                    AND Task_Template__r.Type__c =: 'Design'
                                    AND WhatId =: testCase.Id
                                ];
        Task testTask = tasks[0];
        //system.assertEquals(data.networkDesign.assignedTo, testTask.OwnerId); n4l
        //system.assertEquals('In Progress', testTask.Status); n4l
    }

    static testMethod void test_NetworkDesignLink_error_invalidCaseId(){
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      

        Id invalidRecordId = Id.valueOf('5003000000D8cuIAAR'); //this is only an example of invalid case record id

        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'link';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + invalidRecordId + '",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        
        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignLink(event);
        system.assertEquals(400, result.statusCode);

    }

    static testMethod void test_NetworkDesignLink_error_invalidAccountId(){
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];

        //Id invalidRecordId = Id.valueOf('001xa000003DIlo'); //this is only an example of invalid account record id

        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'link';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "invalid_school_uuid",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        
        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignLink(event);
        system.assertEquals(400, result.statusCode);
    }

    static testMethod void test_NetworkDesignLink_error_invalidUserId(){
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];

        Id invalidRecordId = Id.valueOf('0055P000000UzlFQAS'); //this is only an example of invalid user record id

        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'link';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + invalidRecordId + '",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        
        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignLink(event);
        system.assertEquals(400, result.statusCode);
    }

    static testMethod void test_update_statusOf_DesignTask_DesignTask_error(){
    Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
    //get NHR opportunity
    Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
    Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];

    MethodResponse res = ServiceEventNetworkDesignController.update_statusOf_DesignTask(onboardingCase.Id, onboardingCase.OwnerId, 'Design', null);
    system.assertEquals(500, res.statusCode);
    }

    static testMethod void test_getPricebookChargeToKey(){
        system.assertEquals('MOE',ServiceEventNetworkDesignController.getChargeTo(100));
        system.assertEquals('N4L',ServiceEventNetworkDesignController.getChargeTo(0));
        system.assertEquals('N4L',ServiceEventNetworkDesignController.getChargeTo(50));
        system.assertEquals('N4L',ServiceEventNetworkDesignController.getChargeTo(-100));

        String pricebookId = '01s5m0000000G87AAE';
        system.assertEquals('01s5m0000000G87AAE-MOE',ServiceEventNetworkDesignController.getPricebookChargeToKey(pricebookId, 100));
        system.assertEquals('01s5m0000000G87AAE-N4L',ServiceEventNetworkDesignController.getPricebookChargeToKey(pricebookId, 0));
        system.assertEquals('01s5m0000000G87AAE-N4L',ServiceEventNetworkDesignController.getPricebookChargeToKey(pricebookId, 50));
        system.assertEquals('01s5m0000000G87AAE-N4L',ServiceEventNetworkDesignController.getPricebookChargeToKey(pricebookId, -100));
    }
    static testMethod void test_OnboardingData_InnerClass(){
        ServiceEventNetworkDesignController.OnboardingData onboardingData = new ServiceEventNetworkDesignController.OnboardingData();
        System.assertEquals(TRUE, onboardingData.pricebooksMap.isEmpty());
        System.assertEquals(TRUE, onboardingData.pricebookProductMap.isEmpty());

        onboardingData.preparePricebookMap();
        System.assertEquals(FALSE, onboardingData.pricebooksMap.isEmpty());

        Pricebook2 pricebook = onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment');
        System.assertEquals('equipmentProvider1 - Equipment', pricebook.Name);
        System.assertEquals(TRUE, onboardingData.pricebooksMap.containsKey(pricebook.Id));

        PricebookEntry pricebookEntry = pricebook.PricebookEntries[0];
        String key = Helper.concatenateKey(new List<String>{pricebook.Id, pricebookEntry.Product2Id});
        
        onboardingData.preparePricebookProductMap(new Set<String>{pricebook.Id});
        System.assertEquals(FALSE, onboardingData.pricebookProductMap.isEmpty());
        System.assertEquals(TRUE, onboardingData.pricebookProductMap.containsKey(key));
        System.assertEquals(pricebookEntry.Id, onboardingData.pricebookProductMap.get(key).Id);
    }
   //n4l error test method
    static testMethod void test_NetworkDesignApprove_Equipment_New_success(){
        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');

        Account account = AccountController.getAccount_uuid('schoola'); //this method returns more fields in SOQL query 

    
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, CaseNumber, Account.uuid__c, Contract__c, Opportunity__c, Programme__c, Product__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //need to clear orders of this account
        List<Order> ordersToBeDeleted = [SELECT id, Type, Charge_To__c FROM Order WHERE AccountId =: account.Id ];
        delete ordersToBeDeleted;
        ServiceEventNetworkDesignController.OnboardingData onboardingData = new ServiceEventNetworkDesignController.OnboardingData();
        onboardingData.designId = 'this_is_design_id';//set design id
        onboardingData.school = account; //get school record
        onboardingData.returnTo = accountMap.get('eWaste1'); //get Relinquished Equipment Return to (to populate Order.ReturnTo__c - Lookup(Organisation));
        onboardingData.onboardingCase = onboardingCase;//get onboarding case
        MethodResponse res1= UserController.getCustomerUser(UserInfo.getUserId());//get User for Design Approver
        onboardingData.designApprover = res1.user;

        onboardingData.preparePricebookMap();//prepare a Map collection of pricebook and pricebook entries in inner class
        


        List<ServiceEventNDWrapper.NewEquipment> equipments = new List<ServiceEventNDWrapper.NewEquipment>();

        //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.NewEquipment
        ServiceEventNDWrapper.NewEquipment equipment;
        ServiceEventNDWrapper.Product product;

        Pricebook2 pricebook = onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
        //adding MOE funded items:  line 1
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line1';
        equipment.quantity = 1;
        equipment.moeFunded = 100;
        equipment.lineDescription = 'this is item 1';
        equipment.salesforcePriceBookId = pricebook.Id;
        equipment.product = product;   
        equipments.add(equipment);


        //adding MOE funded items:  line 2
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line2';
        equipment.quantity = 2;
        equipment.moeFunded = 100;
        equipment.lineDescription = 'this is item 2';
        equipment.salesforcePriceBookId = pricebook.Id;
        equipment.product = product;   
        equipments.add(equipment);
        
        
        
        //adding non-MOE funded items: line 3
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line3';
        equipment.quantity = 3;
        equipment.moeFunded = 0;
        equipment.lineDescription = 'this is item 3';
        equipment.salesforcePriceBookId = pricebook.Id;
        equipment.product = product;   
        equipments.add(equipment);

        //adding non-MOE funded items: line 4
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line4';
        equipment.quantity = 4;
        equipment.moeFunded = 0;
        equipment.lineDescription = 'this is item 4';
        equipment.salesforcePriceBookId = pricebook.Id;
        equipment.product = product;   
        equipments.add(equipment);


        pricebook = onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
        //adding MOE funded items:  line 5
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line5';
        equipment.quantity = 5;
        equipment.moeFunded = 100;
        equipment.lineDescription = 'this is item 5';
        equipment.salesforcePriceBookId = pricebook.Id;
        equipment.product = product;   
        equipments.add(equipment);


        //adding MOE funded items:  line 6
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line6';
        equipment.quantity = 6;
        equipment.moeFunded = 100;
        equipment.lineDescription = 'this is item 6';
        equipment.salesforcePriceBookId = pricebook.Id;
        equipment.product = product;   
        equipments.add(equipment);
        
        
        
        //adding non-MOE funded items: line 7
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line7';
        equipment.quantity = 7;
        equipment.moeFunded = 0;
        equipment.lineDescription = 'this is item 7';
        equipment.salesforcePriceBookId = pricebook.Id;
        equipment.product = product;   
        equipments.add(equipment);

        //adding non-MOE funded items: line 8
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line8';
        equipment.quantity = 8;
        equipment.moeFunded = 0;
        equipment.lineDescription = 'this is item 8';
        equipment.salesforcePriceBookId = pricebook.Id;
        equipment.product = product;   
        equipments.add(equipment);
             
        //system.debug('n4l limits 444 ='+limits.getQueries());  
        test.startTest(); //n4l
        MethodResponse res = ServiceEventNetworkDesignController.NetworkDesignApprove_Equipment_New( onboardingData, equipments);
        system.assertEquals(200, res.statusCode);

        //4 orders should be created
        List<Order> orders = [
                            SELECT id
                                    , Type
                                    , Pricebook2Id
                                    , Charge_To__c 
                                    , (
                                            SELECT 
                                                Description
                                                , Discount__c 
                                                , Product_SKU__c
                                                , Product2.Description
                                                , Quantity
                                                , UnitPrice
                                            FROM 
                                                OrderItems
                                            ORDER BY
                                                Description
                                        )
                            FROM Order WHERE AccountId =: account.Id ];
        system.assertEquals(4, orders.size());
        
        Map<string, Order> orderMap = new Map<string, Order>();
        for (Order order : orders){
            orderMap.put( Helper.concatenateKey(new List<String>{order.Type, order.Pricebook2Id, order.Charge_To__c}), order);
        }

        Order testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'Equipment - New', onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').Id, 'MOE'}));
        system.assertEquals(2, testOrder.OrderItems.size());
        system.assertEquals(100, testOrder.OrderItems[0].Discount__c);
        system.assertEquals('this is item 1', testOrder.OrderItems[0].Description);

        testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'Equipment - New', onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').Id, 'N4L'}));
        system.assertEquals(2, testOrder.OrderItems.size());
        system.assertEquals(0, testOrder.OrderItems[0].Discount__c);
        system.assertEquals('this is item 3', testOrder.OrderItems[0].Description);


        testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'Equipment - New', onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').Id, 'MOE'}));
        system.assertEquals(2, testOrder.OrderItems.size());
        system.assertEquals(100, testOrder.OrderItems[0].Discount__c);
        system.assertEquals('this is item 5', testOrder.OrderItems[0].Description);

        testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'Equipment - New', onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').Id, 'N4L'}));
        system.assertEquals(2, testOrder.OrderItems.size());
        system.assertEquals(0, testOrder.OrderItems[0].Discount__c);
        system.assertEquals('this is item 7', testOrder.OrderItems[0].Description);
        test.stopTest(); //n4l
    }

    static testMethod void test_NetworkDesignApprove_Equipment_New_Error_invalidPricebookIds(){
        //to test invalid pricebookIds given in payload
        Id invalidRecordId = '01s5m0000000PkjZZZ'; //invalid pricebook id

        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');

        Account account = AccountController.getAccount_uuid('schoola'); //this method returns more fields in SOQL query 

    
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, CaseNumber, Account.uuid__c, Contract__c, Opportunity__c, Programme__c, Product__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //need to clear orders of this account
        List<Order> ordersToBeDeleted = [SELECT id, Type, Charge_To__c FROM Order WHERE AccountId =: account.Id ];
        delete ordersToBeDeleted;

        ServiceEventNetworkDesignController.OnboardingData onboardingData = new ServiceEventNetworkDesignController.OnboardingData();
        onboardingData.designId = 'this_is_design_id';//set design id
        onboardingData.school = account; //get school record
        onboardingData.returnTo = accountMap.get('eWaste1'); //get Relinquished Equipment Return to (to populate Order.ReturnTo__c - Lookup(Organisation));
        onboardingData.onboardingCase = onboardingCase;//get onboarding case

        MethodResponse res1= UserController.getCustomerUser(UserInfo.getUserId());//get User for Design Approver
        onboardingData.designApprover = res1.user;

        onboardingData.preparePricebookMap();//prepare a Map collection of pricebook and pricebook entries in inner class
        
        List<ServiceEventNDWrapper.NewEquipment> equipments = new List<ServiceEventNDWrapper.NewEquipment>();

        //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.NewEquipment
        ServiceEventNDWrapper.NewEquipment equipment;
        ServiceEventNDWrapper.Product product;

        Pricebook2 pricebook = onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
        //adding MOE funded items:  line 1
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line1';
        equipment.quantity = 1;
        equipment.moeFunded = 100;
        equipment.lineDescription = 'this is item 1';
        equipment.salesforcePriceBookId = invalidRecordId; //invalid Pricebook Id
        equipment.product = product;   
        equipments.add(equipment);


        //adding MOE funded items:  line 2
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line2';
        equipment.quantity = 2;
        equipment.moeFunded = 100;
        equipment.lineDescription = 'this is item 2';
        equipment.salesforcePriceBookId = invalidRecordId; //invalid Pricebook Id
        equipment.product = product;   
        equipments.add(equipment);
        
                     
        
        MethodResponse res = ServiceEventNetworkDesignController.NetworkDesignApprove_Equipment_New( onboardingData, equipments);
        system.assertEquals(400, res.statusCode);
        
    }
 
    
    static testMethod void test_NetworkDesignApprove_Equipment_New_Error_invalidProductIds(){
        //to test invalid product given in payload
        Id invalidRecordId = '01t5m000000EdcJYYY'; //invalid product id

        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');

        Account account = AccountController.getAccount_uuid('schoola'); //this method returns more fields in SOQL query 

    
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, CaseNumber, Account.uuid__c, Contract__c, Opportunity__c, Programme__c, Product__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //need to clear orders of this account
        List<Order> ordersToBeDeleted = [SELECT id, Type, Charge_To__c FROM Order WHERE AccountId =: account.Id ];
        delete ordersToBeDeleted;

        ServiceEventNetworkDesignController.OnboardingData onboardingData = new ServiceEventNetworkDesignController.OnboardingData();
        onboardingData.designId = 'this_is_design_id';//set design id
        onboardingData.school = account; //get school record
        onboardingData.returnTo = accountMap.get('eWaste1'); //get Relinquished Equipment Return to (to populate Order.ReturnTo__c - Lookup(Organisation));
        onboardingData.onboardingCase = onboardingCase;//get onboarding case

        MethodResponse res1= UserController.getCustomerUser(UserInfo.getUserId());//get User for Design Approver
        onboardingData.designApprover = res1.user;

        onboardingData.preparePricebookMap();//prepare a Map collection of pricebook and pricebook entries in inner class
        
        List<ServiceEventNDWrapper.NewEquipment> equipments = new List<ServiceEventNDWrapper.NewEquipment>();

        //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.NewEquipment
        ServiceEventNDWrapper.NewEquipment equipment;
        ServiceEventNDWrapper.Product product;

        Pricebook2 pricebook = onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
        //adding MOE funded items:  line 1
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = invalidRecordId;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line1';
        equipment.quantity = 1;
        equipment.moeFunded = 100;
        equipment.lineDescription = 'this is item 1';
        equipment.salesforcePriceBookId = pricebook.Id; //invalid Pricebook Id
        equipment.product = product;   
        equipments.add(equipment);


        //adding MOE funded items:  line 2
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = invalidRecordId;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        equipment = new ServiceEventNDWrapper.NewEquipment ();
        equipment.x_id = 'line2';
        equipment.quantity = 2;
        equipment.moeFunded = 100;
        equipment.lineDescription = 'this is item 2';
        equipment.salesforcePriceBookId = pricebook.Id; //invalid Pricebook Id
        equipment.product = product;   
        equipments.add(equipment);
        
                     
        
        MethodResponse res = ServiceEventNetworkDesignController.NetworkDesignApprove_Equipment_New( onboardingData, equipments);
        system.assertEquals(400, res.statusCode);
        
    }
    static testMethod void test_NetworkDesignApprove_success(){
        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
        Account account = accountMap.get('schoola');
        Account returnTo = accountMap.get('eWaste1');
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, CaseNumber, Account.uuid__c, Contract__c, Opportunity__c, Programme__c, Product__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];

        //use existing functions in a inner class
        ServiceEventNetworkDesignController.OnboardingData onboardingData = new ServiceEventNetworkDesignController.OnboardingData();
        onboardingData.preparePricebookMap();


        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'approve';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + onboardingCase.Id + '",');
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "' + onboardingCase.Account.uuid__c + '",');
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + onboardingCase.OwnerId + '",');

        //prepare payload "equipmentForRemoval" with uuid of return to 
        json = json.replace('"organisationId": "69a2ef5c-360e-47e4-9192-8488e721ae7b",', '"organisationId": "' + returnTo.uuid__c + '",');
        
        //prepare payload with 2 different unit test pricebooks
        json = json.replace('"salesforcePriceBookId": "01s5m0000000G87AAE",', '"salesforcePriceBookId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').Id + '",');
        json = json.replace('"salesforcePriceBookId": "01s5m0000000PkjAAE",', '"salesforcePriceBookId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').Id + '",');
        
        //prepare payload with unit test product id for respective pricebook
        json = json.replace('"salesforceId": "01t5m000000EdcJAAS",', '"salesforceId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').PricebookEntries[0].Product2Id + '",');
        json = json.replace('"salesforceId": "01t5m000000EdcGAAS",', '"salesforceId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').PricebookEntries[0].Product2Id + '",');

        ServiceEventWrapper.Data_NetworkDesign build_data = new ServiceEventWrapper.Data_NetworkDesign();
        build_data.networkDesign = ServiceEventNDWrapper.parse(json); 
        
        event.data = build_data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        //ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignApprove(event);
        test.startTest();
        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignRouting(event); //hit NetworkDesignRouting to get to NetworkDesignApprove()
        //system.assertEquals(200, result.statusCode); n4l
        test.stopTest();
       
    }

    static testMethod void test_NetworkDesignApprove_error_invalidUserId(){
        Id invalidRecordId = Id.valueOf('0055P000000UzlFQAS'); //this is only an example of invalid user record id

        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'approve';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + invalidRecordId + '",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();
        
        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignApprove(event);
        system.assertEquals(TRUE, result.statusCode >= 400);
    }

    static testMethod void test_NetworkDesignApprove_error_invalidAccountId(){
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'approve';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();

        //good unit test values
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + UserInfo.getUserId() + '",');
        
        //invalid unit test values
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "invalid_school_uuid",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();
        
        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignApprove(event);
        system.assertEquals(400, result.statusCode);
    }

    static testMethod void test_NetworkDesignApprove_error_invalidReturnToAccountId(){
        Account account = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c = 'schoola'];      

        //Id invalidRecordId = Id.valueOf('001xa000003DIlo'); //this is only an example of invalid account record id

        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'approve';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();

        //good unit test values
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + UserInfo.getUserId() + '",');
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "' + account.uuid__c + '",');

        //invalid unit test values
        json = json.replace('"organisationId": "69a2ef5c-360e-47e4-9192-8488e721ae7b",', '"organisationId": "invalid_returnTo_uuid",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignApprove(event);
        system.assertEquals(400, result.statusCode);
    }


    static testMethod void test_NetworkDesignApprove_error_invalidCaseId(){
        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
        Account account = accountMap.get('schoola');
        Account returnTo = accountMap.get('eWaste1');
        
        Id invalidRecordId = Id.valueOf('5003000000D8cuIAAR'); //this is only an example of invalid case record id

        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'approve';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();

        //good unit test values
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "' + account.uuid__c + '",');
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + UserInfo.getUserId() + '",');
        json = json.replace('"organisationId": "69a2ef5c-360e-47e4-9192-8488e721ae7b",', '"organisationId": "' + returnTo.uuid__c + '",');//prepare payload "equipmentForRemoval" with uuid of return to 
        
        //invalid unit test values
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + invalidRecordId + '",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();
        
        ApiResponse result = ServiceEventNetworkDesignController.NetworkDesignApprove(event);
        system.assertEquals(400, result.statusCode);
    }

    
    
}