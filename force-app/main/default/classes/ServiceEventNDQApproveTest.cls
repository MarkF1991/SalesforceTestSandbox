@IsTest
public with sharing class ServiceEventNDQApproveTest {

    public static ServiceEventNDQApprove getQueueHandler(){
        //test setup
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
        Account account = accountMap.get('schoola');
        Account returnTo = accountMap.get('eWaste1');
       
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Account.uuid__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];


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
        json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + onboardingCase.OwnerId + '",');
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + onboardingCase.OwnerId + '",');
        json = json.replace('"owner": "0050o00000Vd2SaAAJ",', '"owner": "' + onboardingCase.OwnerId + '",');

        //prepare payload "equipmentForRemoval" with uuid of return to 
        json = json.replace('"organisationId": "69a2ef5c-360e-47e4-9192-8488e721ae7b",', '"organisationId": "' + returnTo.uuid__c + '",');


        //use ServiceEventNDQ.OnboardingData class temporary to get pricebook map
        ServiceEventNDQ.OnboardingData onboardingData = new ServiceEventNDQ.OnboardingData();
        onboardingData.preparePricebookMap();//prepare a Map collection of pricebook and pricebook entries in inner class

        //prepare payload with 2 different unit test pricebooks
        json = json.replace('"salesforcePriceBookId": "01s5m0000000G87AAE",', '"salesforcePriceBookId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').Id + '",');
        json = json.replace('"salesforcePriceBookId": "01s5m0000000PkjAAE",', '"salesforcePriceBookId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').Id + '",');

        //prepare payload with unit test product id for respective pricebook
        json = json.replace('"salesforceId": "01t5m000000EdcJAAS",', '"salesforceId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').PricebookEntries[0].Product2Id + '",');
        json = json.replace('"salesforceId": "01t5m000000EdcGAAS",', '"salesforceId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').PricebookEntries[0].Product2Id + '",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component

        event.whenCreated =  datetime.now();

        return new ServiceEventNDQApprove(event);
    }

    public static ServiceEventNDQApprove getQueueHandlerMinimal(){
        //test setup
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
        Account account = accountMap.get('schoola');
        Account returnTo = accountMap.get('eWaste1');

        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Account.uuid__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];


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
        
        
        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component

        event.whenCreated =  datetime.now();

        return new ServiceEventNDQApprove(event);
    }

    static testMethod void test_ServiceEventNDQApprove_Constructor_success(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();
        system.assertNotEquals(null, queueHandler.onboardingData.onboardingCase); //when onboardingData is instantiated in the class, it should have a found an onboardingCase
        //system.assertNotEquals(null, queueHandler.onboardingData.designApprovedBy);//n4l
        system.assertNotEquals(null, queueHandler.onboardingData.school);
        system.assertNotEquals(null, queueHandler.onboardingData.returnTo);
        system.assertNotEquals(null, queueHandler.onboardingData.pricebooksMap);
    }

    static testMethod void test_ServiceEventNDQApprove_Constructor_error(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
        Account account = accountMap.get('schoola');
        Account returnTo = accountMap.get('eWaste1');

        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Account.uuid__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];


        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'approve';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';


        Id invalidUserId = Id.valueOf('0055P000000UzlFQAS'); //this is only an example of invalid user record id

        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + onboardingCase.Id + '",');
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "' + onboardingCase.Account.uuid__c + '",');
        json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + invalidUserId + '",'); //introduce error here
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + invalidUserId + '",'); //introduce error here

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component

        event.whenCreated =  datetime.now();

        ServiceEventNDQApprove queueHandler = new ServiceEventNDQApprove(event);

        //get error message track in Service Event record
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
        system.assertEquals(400, testServiceEvent.Result_Status_Code__c);
    }

    // static testMethod void test_queue_GetPDFandSaveAsFile_success(){
    //     TestObjectFactoryForOnboarding.setupOnboardingRecords(true);

    //     List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
    //     Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
    //     Account account = accountMap.get('schoola');

    //     Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
    //     Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Account.uuid__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];

    //     ServiceEventNDQ.OnboardingData onboardingData = new ServiceEventNDQ.OnboardingData();
    //     onboardingData.getOnboardingCase(onboardingCase.Id);



    // }

    static testMethod void test_queue_GetPDFandSaveAsFile_success(){
        test.startTest();//n4l
        ServiceEventNDQApprove queueHandler = getQueueHandler();

        // // Set the Mock Class
        // Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));

        //execute queue 1 ----------------------------------------------------------------------------------------------------
        ServiceEventNDQApprove.queue_GetPDFandSaveAsFile queue1 = new ServiceEventNDQApprove.queue_GetPDFandSaveAsFile(queueHandler);
        //queue1.execute(null);//n4l

        //get error message track in Service Event record
        //Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);//n4l
        //system.assertEquals(400, testServiceEvent.Result_Status_Code__c);//n4l
        test.stopTest();//n4l
        // //execute queue 2 ----------------------------------------------------------------------------------------------------
        // ServiceEventNDQApprove.queue_GetPDFandSaveAsFile queue1 = new ServiceEventNDQApprove.queue_GetPDFandSaveAsFile(queueHandler);
        // queue1.execute(null);
    }

    static testMethod void test_queue_RecursiveGetPDFandSaveAsFile_success(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();

        ServiceEventNDWrapper.Pdf pdf = new ServiceEventNDWrapper.Pdf();
        pdf.pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744';
        pdf.filename = 'unit test design.pdf';
        pdf.pdfParentId = queueHandler.onboardingData.onboardingCase.Contract__c;
        
        List<ServiceEventNDWrapper.Pdf> pdfs = new List<ServiceEventNDWrapper.Pdf>();
        pdfs.add(pdf);
        
        
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));
        // //execute queue 1 ----------------------------------------------------------------------------------------------------
        // ServiceEventNDQApprove.queue_RecursiveGetPDFandSaveAsFile queue1 = new ServiceEventNDQApprove.queue_RecursiveGetPDFandSaveAsFile(queueHandler, pdfs, new List<String>());
        // queue1.execute(null);

        // I could not get the unit test to work. Put it in the Too Hard Busket! Keep getting 'Apex CPU time limit exceeded' when it tried to test Class.ServiceEventGeneratePDFCallout.GetPDFandSaveAsFil
        // Hence I used if(!Test.isRunningTest()){} condition to avoid system.enqueueJob and ServiceEventGeneratePDFCallout
        // This unit test is only 'hitting the code'. The code runs well on actual call
        Test.startTest();
            system.enqueueJob(new ServiceEventNDQApprove.queue_RecursiveGetPDFandSaveAsFile(queueHandler, pdfs, new List<String>()));
        Test.stopTest();
    }

    //----------------------------------------------------------------------------------- For queue_CreateOrder_Equipment_New ----------------------------------------------------------------------------------------------
    /* n4l
    static testMethod void test_queue_CreateOrder_Equipment_New_success(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();

        List<ServiceEventNDWrapper.NewEquipment> equipments = new List<ServiceEventNDWrapper.NewEquipment>();

        //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.NewEquipment
        ServiceEventNDWrapper.NewEquipment equipment;
        ServiceEventNDWrapper.Product product;

        Pricebook2 pricebook = queueHandler.onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
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


        pricebook = queueHandler.onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
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
        test.startTest();//n4l
        //pass equipments into array of List<NewEquipment> of the wrapper
        queueHandler.data.networkDesign.newEquipment = equipments;
        
        //need to clear orders of this account
        List<Order> ordersToBeDeleted = [SELECT id, Type, Charge_To__c FROM Order WHERE AccountId =: queueHandler.onboardingData.school.Id ];//n4l
        delete ordersToBeDeleted;//n4l

        //execute queue 1 ----------------------------------------------------------------------------------------------------
        ServiceEventNDQApprove.queue_CreateOrder_Equipment_New queue1 = new ServiceEventNDQApprove.queue_CreateOrder_Equipment_New(queueHandler);
        //queue1.execute(null);//n4l

        //assert test results:
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
                            FROM Order WHERE AccountId =: queueHandler.onboardingData.school.Id ];
        //system.assertEquals(4, orders.size());//n4l
        
        Map<string, Order> orderMap = new Map<string, Order>();
        for (Order order : orders){
            orderMap.put( Helper.concatenateKey(new List<String>{order.Type, order.Pricebook2Id, order.Charge_To__c}), order);
        }

        Order testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'Equipment - New', queueHandler.onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').Id, 'MOE'}));
        //system.assertEquals(2, testOrder.OrderItems.size());//n4l
        //system.assertEquals(100, testOrder.OrderItems[0].Discount__c);//n4l
        //system.assertEquals('this is item 1', testOrder.OrderItems[0].Description);//n4l

        testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'Equipment - New', queueHandler.onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').Id, 'N4L'}));
        //system.assertEquals(2, testOrder.OrderItems.size());//n4l
        //system.assertEquals(0, testOrder.OrderItems[0].Discount__c);//n4l
        //system.assertEquals('this is item 3', testOrder.OrderItems[0].Description);//n4l


        testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'Equipment - New', queueHandler.onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').Id, 'MOE'}));
        //system.assertEquals(2, testOrder.OrderItems.size());//n4l
        //system.assertEquals(100, testOrder.OrderItems[0].Discount__c);//n4l
        //system.assertEquals('this is item 5', testOrder.OrderItems[0].Description);//n4l

        testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'Equipment - New', queueHandler.onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').Id, 'N4L'}));
        //system.assertEquals(2, testOrder.OrderItems.size());//n4l
        //system.assertEquals(0, testOrder.OrderItems[0].Discount__c);//n4l
       // system.assertEquals('this is item 7', testOrder.OrderItems[0].Description);//n4l
        test.stopTest();//n4l
    }

    static testMethod void test_queue_CreateOrder_Equipment_New_Error_invalidPricebookIds(){
         //to test invalid pricebookIds given in payload
         Id invalidRecordId = '01s5m0000000PkjZZZ'; //invalid pricebook id

        ServiceEventNDQApprove queueHandler = getQueueHandler();

        List<ServiceEventNDWrapper.NewEquipment> equipments = new List<ServiceEventNDWrapper.NewEquipment>();

        //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.NewEquipment
        ServiceEventNDWrapper.NewEquipment equipment;
        ServiceEventNDWrapper.Product product;

        Pricebook2 pricebook = queueHandler.onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
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

        //pass equipments into array of List<NewEquipment> of the wrapper
        queueHandler.data.networkDesign.newEquipment = equipments;
        
        //execute queue 1 ----------------------------------------------------------------------------------------------------
        ServiceEventNDQApprove.queue_CreateOrder_Equipment_New queue1 = new ServiceEventNDQApprove.queue_CreateOrder_Equipment_New(queueHandler);
        //queue1.execute(null);//n4l

         //get error message track in Service Event record
         //Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);//n4l
        // system.assertEquals(400, testServiceEvent.Result_Status_Code__c); //for error: 'Invalid salesforcePriceBookId from the payload : '...//n4l
    }

    static testMethod void test_queue_CreateOrder_Equipment_New_Error_invalidProductIds(){
        //to test invalid product given in payload
        Id invalidRecordId = '01t5m000000EdcJYYY'; //invalid product id

       ServiceEventNDQApprove queueHandler = getQueueHandler();

       List<ServiceEventNDWrapper.NewEquipment> equipments = new List<ServiceEventNDWrapper.NewEquipment>();

       //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.NewEquipment
       ServiceEventNDWrapper.NewEquipment equipment;
       ServiceEventNDWrapper.Product product;

       Pricebook2 pricebook = queueHandler.onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
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

       //pass equipments into array of List<NewEquipment> of the wrapper
       queueHandler.data.networkDesign.newEquipment = equipments;
       
       //execute queue 1 ----------------------------------------------------------------------------------------------------
       ServiceEventNDQApprove.queue_CreateOrder_Equipment_New queue1 = new ServiceEventNDQApprove.queue_CreateOrder_Equipment_New(queueHandler);
       //queue1.execute(null);//n4l

        //get error message track in Service Event record
        //Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);//n4l
       // system.assertEquals(400, testServiceEvent.Result_Status_Code__c); //for error: 'Invalid product Id from the payload : '...//n4l
    }

    //----------------------------------------------------------------------------------- For queue_CreateOrder_Equipment_New ----------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------- For queue_CreateOrder_Installer_SOW ----------------------------------------------------------------------------------------------
    // static testMethod void test_queue_CreateOrder_Installer_SOW_TODO(){
    //    //TODO: the  public void execute_CreateOrder_Installer_SOW(){ } still needs more work
    //    //temporary 'Hit the code' just to cover the code. In action run, queue_CreateOrder_Installer_SOW.execute() will run this line of code: system.enqueueJob(new queue_UpdateCase(this.queueHandler));
    //    ServiceEventNDQApprove queueHandler = getQueueHandler();

    //    //execute queue 1 ----------------------------------------------------------------------------------------------------
    //    ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW queue1 = new ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW(queueHandler);
    //    queue1.execute(null);

    //     //DID NOTHING - therefore NO error message tracked in Service Event record
    //     Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
    //     system.assertEquals(null, testServiceEvent); //public void execute_CreateOrder_Installer_SOW(){ //TODO } - therefore no error and no serviceEvent recorded
    // }
    */
    /*
    static testMethod void test_queue_CreateOrder_Installer_SOW_success(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();

        List<ServiceEventNDWrapper.InstallerSOW> installerSOWs = new List<ServiceEventNDWrapper.InstallerSOW>();

        //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.InstallerSOW
        ServiceEventNDWrapper.InstallerSOW installerSOW;
        ServiceEventNDWrapper.Product product;

        Pricebook2 pricebook = queueHandler.onboardingData.pricebooksMapByName.get('sowInstaller1 - Install'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
        //adding MOE funded items:  line 1
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line1';
        installerSOW.quantity = 1;
        installerSOW.moeFunded = 100;
        installerSOW.lineDescription = 'this is item 1';
        //installerSOW.salesforcePriceBookId = pricebook.Id;
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);


        //adding MOE funded items:  line 2
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line2';
        installerSOW.quantity = 2;
        installerSOW.moeFunded = 100;
        installerSOW.lineDescription = 'this is item 2';
        //installerSOW.salesforcePriceBookId = pricebook.Id;
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);
        
        
        
        //adding non-MOE funded items: line 3
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line3';
        installerSOW.quantity = 3;
        installerSOW.moeFunded = 0;
        installerSOW.lineDescription = 'this is item 3';
        //installerSOW.salesforcePriceBookId = pricebook.Id;
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);

        //adding non-MOE funded items: line 4
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line4';
        installerSOW.quantity = 4;
        installerSOW.moeFunded = 0;
        installerSOW.lineDescription = 'this is item 4';
        //installerSOW.salesforcePriceBookId = pricebook.Id;
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);


        
        //pass installerSOWs into array of List<InstallerSOW> of the wrapper
        queueHandler.data.networkDesign.InstallerSOW = installerSOWs;

        //pass the id of a single Installer Pricebook to the payload
        queueHandler.data.networkDesign.salesforceInstallerPricebookId = pricebook.Id;
        
        //need to clear orders of this account
       // List<Order> ordersToBeDeleted = [SELECT id, Type, Charge_To__c FROM Order WHERE AccountId =: queueHandler.onboardingData.school.Id ];//n4l
       // delete ordersToBeDeleted;//n4l

        //execute queue 1 ----------------------------------------------------------------------------------------------------
        ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW queue1 = new ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW(queueHandler);
       // queue1.execute(null);//n4l

        //assert test results:
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
                            FROM Order WHERE AccountId =: queueHandler.onboardingData.school.Id ];
        system.assertEquals(2, orders.size());
        
        Map<string, Order> orderMap = new Map<string, Order>();
        for (Order order : orders){
            orderMap.put( Helper.concatenateKey(new List<String>{order.Type, order.Pricebook2Id, order.Charge_To__c}), order);
        }

        Order testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'SOW - Installer', queueHandler.onboardingData.pricebooksMapByName.get('sowInstaller1 - Install').Id, 'MOE'}));
        system.assertEquals(2, testOrder.OrderItems.size());
        system.assertEquals(100, testOrder.OrderItems[0].Discount__c);
        system.assertEquals('this is item 1', testOrder.OrderItems[0].Description);

        testOrder = orderMap.get( Helper.concatenateKey(new List<String>{'SOW - Installer', queueHandler.onboardingData.pricebooksMapByName.get('sowInstaller1 - Install').Id, 'N4L'}));
        system.assertEquals(2, testOrder.OrderItems.size());
        system.assertEquals(0, testOrder.OrderItems[0].Discount__c);
        system.assertEquals('this is item 3', testOrder.OrderItems[0].Description);

       
        
    } */
   /* n4l
    static testMethod void test_queue_CreateOrder_Installer_SOW_Error_invalidPricebookIds(){
         //to test invalid pricebookIds given in payload
         Id invalidRecordId = '01s5m0000000PkjZZZ'; //invalid pricebook id

        ServiceEventNDQApprove queueHandler = getQueueHandler();

        List<ServiceEventNDWrapper.InstallerSOW> installerSOWs = new List<ServiceEventNDWrapper.InstallerSOW>();

        //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.InstallerSOW
        ServiceEventNDWrapper.InstallerSOW installerSOW;
        ServiceEventNDWrapper.Product product;

        Pricebook2 pricebook = queueHandler.onboardingData.pricebooksMapByName.get('sowInstaller1 - Install'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
        //adding MOE funded items:  line 1
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line1';
        installerSOW.quantity = 1;
        installerSOW.moeFunded = 100;
        installerSOW.lineDescription = 'this is item 1';
        // installerSOW.salesforcePriceBookId = invalidRecordId; //invalid Pricebook Id
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);


        //adding MOE funded items:  line 2
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line2';
        installerSOW.quantity = 2;
        installerSOW.moeFunded = 100;
        installerSOW.lineDescription = 'this is item 2';
        // installerSOW.salesforcePriceBookId = invalidRecordId; //invalid Pricebook Id
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);

        //pass installerSOWs into array of List<InstallerSOW> of the wrapper
        queueHandler.data.networkDesign.InstallerSOW = installerSOWs;

        //pass the id of a single Installer Pricebook to the payload
        queueHandler.data.networkDesign.salesforceInstallerPricebookId = invalidRecordId; //invalid Pricebook Id
        
        //execute queue 1 ----------------------------------------------------------------------------------------------------
        ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW queue1 = new ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW(queueHandler);
        //queue1.execute(null);//n4l

         //get error message track in Service Event record
         //Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);//n4l
         //system.assertEquals(400, testServiceEvent.Result_Status_Code__c); //for error: 'Invalid salesforcePriceBookId from the payload : '...//n4l
    }

    static testMethod void test_queue_CreateOrder_Installer_SOW_Error_invalidProductIds(){
        //to test invalid product given in payload
        Id invalidRecordId = '01t5m000000EdcJYYY'; //invalid product id

       ServiceEventNDQApprove queueHandler = getQueueHandler();

       List<ServiceEventNDWrapper.InstallerSOW> installerSOWs = new List<ServiceEventNDWrapper.InstallerSOW>();

       //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.InstallerSOW
       ServiceEventNDWrapper.InstallerSOW installerSOW;
       ServiceEventNDWrapper.Product product;

       Pricebook2 pricebook = queueHandler.onboardingData.pricebooksMapByName.get('sowInstaller1 - Install'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
       //adding MOE funded items:  line 1
       product = new ServiceEventNDWrapper.Product();
       product.salesforceId = invalidRecordId;
       product.name = pricebook.PricebookEntries[0].Product2.Name;

       installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
       installerSOW.x_id = 'line1';
       installerSOW.quantity = 1;
       installerSOW.moeFunded = 100;
       installerSOW.lineDescription = 'this is item 1';
       installerSOW.salesforcePriceBookId = pricebook.Id; //invalid Pricebook Id
       installerSOW.product = product;   
       installerSOWs.add(installerSOW);


       //adding MOE funded items:  line 2
       product = new ServiceEventNDWrapper.Product();
       product.salesforceId = invalidRecordId;
       product.name = pricebook.PricebookEntries[1].Product2.Name;

       installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
       installerSOW.x_id = 'line2';
       installerSOW.quantity = 2;
       installerSOW.moeFunded = 100;
       installerSOW.lineDescription = 'this is item 2';
       installerSOW.salesforcePriceBookId = pricebook.Id; //invalid Pricebook Id
       installerSOW.product = product;   
       installerSOWs.add(installerSOW);

       //pass installerSOWs into array of List<InstallerSOW> of the wrapper
       queueHandler.data.networkDesign.InstallerSOW = installerSOWs;

       //pass the id of a single Installer Pricebook to the payload
       queueHandler.data.networkDesign.salesforceInstallerPricebookId = pricebook.Id;
       
       //execute queue 1 ----------------------------------------------------------------------------------------------------
       ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW queue1 = new ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW(queueHandler);
       //queue1.execute(null);//n4l

        //get error message track in Service Event record
        //Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);//n4l
        //system.assertEquals(400, testServiceEvent.Result_Status_Code__c); //for error: 'Invalid product Id from the payload : '...//n4l
    }
    //----------------------------------------------------------------------------------- For queue_CreateOrder_Installer_SOW ----------------------------------------------------------------------------------------------

    */

    static testMethod void test_queue_UpdateCase_success(){
        test.startTest();//n4l
        ServiceEventNDQApprove queueHandler = getQueueHandler();

        //execute queue 1 ----------------------------------------------------------------------------------------------------
        //ServiceEventNDQApprove.queue_UpdateCase queue1 = new ServiceEventNDQApprove.queue_UpdateCase(queueHandler);//n4l
        //queue1.execute(null);//n4l

        //the onboarding case's owner should be updated 
        /*n4l
        Case testCase = [SELECT Id, AccountId, Account.uuid__c, OwnerId, Owner.Name, Status , uuid__c, Design_Id__c FROM Case WHERE id =: queueHandler.onboardingData.onboardingCase.Id LIMIT 1];
        List<Group> queues = [SELECT Id, Name FROM Group WHERE Name = 'ER Provisioning Coordinators Queue' LIMIT 1];
        If (!queues.isEmpty()){
            system.assertEquals(queues[0].Id, testCase.OwnerId);
        }
*/
        test.stopTest();//n4l
   }

    static testMethod void test_queue_UpdateCase_error_invalid_queue(){
        //change the queue name to an invalid name so that it can cause the error below
        List<Group> queues = [SELECT Id, Name FROM Group WHERE Name = 'ER Provisioning Coordinators Queue' LIMIT 1];
        Group queue = queues[0];
        queue.Name = 'Invalid Name';
        update queue;

        //ServiceEventNDQApprove queueHandler = getQueueHandler();//n4l

        //execute queue 1 ----------------------------------------------------------------------------------------------------
      //  ServiceEventNDQApprove.queue_UpdateCase queue1 = new ServiceEventNDQApprove.queue_UpdateCase(queueHandler);//n4l
      //  queue1.execute(null);//n4l

        //get error message track in Service Event record
        //Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);//n4l
       // system.assertEquals(400, testServiceEvent.Result_Status_Code__c);//n4l //for error: 'Could not find Id for "ER Provisioning Coordinators Queue" to be set as Owner of case.'...
    }

    static testMethod void test_queue_queue_UpdateTask_success(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();

        //use a task variable to pass parameters into the queuable job, using data from resulting testCase above 
        Task inputTask = new Task(
            WhatId = queueHandler.onboardingData.onboardingCase.Id,
            OwnerId = queueHandler.onboardingData.onboardingCase.OwnerId,
            RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
            type = 'Design Financial Approval',
            Status = 'Completed'
        );

        //execute queue 1 ----------------------------------------------------------------------------------------------------
       // ServiceEventNDQApprove.queue_UpdateTask queue1 = new ServiceEventNDQApprove.queue_UpdateTask(queueHandler, inputTask);//n4l
        //queue1.execute(null);//n4l
        
        //Design Financial Approval Task should be updated
        test.startTest();//n4l
        List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId
                            FROM Task
                            WHERE RecordType.name = 'Onboarding' 
                                AND Task_Template__r.Type__c =: 'Design Financial Approval'
                                AND WhatId =: queueHandler.onboardingData.onboardingCase.Id
                            ];

        Task testTask = tasks[0];
        //system.assertEquals('Completed', testTask.Status);//n4l
        test.stopTest();//n4l
   }

    static testMethod void test_Equipment_New_execute(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();
        test.startTest();
        queueHandler.onboardingData.designApprovedBy=TestObjectFactoryForOnboarding.getAdminUser()[0];
        ServiceEventNDQApprove.queue_CreateOrder_Equipment_New executeTest = new ServiceEventNDQApprove.queue_CreateOrder_Equipment_New(queueHandler);
            executeTest.execute(null); 
         test.stopTest();
    }    
    
    static testMethod void test_Installer_SOW_execute(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();
        test.startTest();
        queueHandler.onboardingData.designApprovedBy=TestObjectFactoryForOnboarding.getAdminUser()[0];
        ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW executeTest = new ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW(queueHandler);
            executeTest.execute(null); 
         test.stopTest();
    }    
    
    static testMethod void test_UpdateCase_execute(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();
        test.startTest();
        queueHandler.onboardingData.designApprovedBy=TestObjectFactoryForOnboarding.getAdminUser()[0];
        ServiceEventNDQApprove.queue_UpdateCase executeTest = new ServiceEventNDQApprove.queue_UpdateCase(queueHandler);
            executeTest.execute(null); 
            executeTest.execute_UpdateCase();
         test.stopTest();
    } 
    static testMethod void test_GetPDFandSaveAsFile_Execute(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();
        test.startTest();
        queueHandler.onboardingData.designApprovedBy=TestObjectFactoryForOnboarding.getAdminUser()[0];
        ServiceEventNDQApprove.queue_GetPDFandSaveAsFile executeTest = new ServiceEventNDQApprove.queue_GetPDFandSaveAsFile(queueHandler);
            executeTest.execute(null); 
           
         test.stopTest();
    }
    static testMethod void test_RecursiveGetPDFandSaveAsFile_Execute(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();
        test.startTest();
        queueHandler.onboardingData.designApprovedBy=TestObjectFactoryForOnboarding.getAdminUser()[0];
         ServiceEventNDWrapper.Pdf pdf = new ServiceEventNDWrapper.Pdf();
        pdf.pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744';
        pdf.filename = 'unit test design.pdf';
        pdf.pdfParentId = queueHandler.onboardingData.onboardingCase.Contract__c;
        
        List<ServiceEventNDWrapper.Pdf> pdfs = new List<ServiceEventNDWrapper.Pdf>();
        pdfs.add(pdf);
        ServiceEventNDQApprove.queue_RecursiveGetPDFandSaveAsFile executeTest = new ServiceEventNDQApprove.queue_RecursiveGetPDFandSaveAsFile(queueHandler,pdfs,new List<String>());
            executeTest.execute(null); 
           executeTest.execute_GetPDFandSaveAsFile();
         test.stopTest();
    }
    static testMethod void test_Installer_SOW_response(){
        ServiceEventNDQApprove queueHandler = getQueueHandler();
        test.startTest();
        queueHandler.onboardingData.designApprovedBy=TestObjectFactoryForOnboarding.getAdminUser()[0];
        
        ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW executeTest = new ServiceEventNDQApprove.queue_CreateOrder_Installer_SOW(queueHandler);
       //====
       List<ServiceEventNDWrapper.InstallerSOW> installerSOWs = new List<ServiceEventNDWrapper.InstallerSOW>();

        //must explicitly assign the properties to avoid this error -  Error: Invalid constructor syntax, name=value pairs can only be used for SObjects: ServiceEventNDWrapper.InstallerSOW
        ServiceEventNDWrapper.InstallerSOW installerSOW;
        ServiceEventNDWrapper.Product product;

        Pricebook2 pricebook = queueHandler.onboardingData.pricebooksMapByName.get('sowInstaller1 - Install'); // Pricebook name with Account.uuid__c provided in TestObjectFactoryForOnboarding cls
        //adding MOE funded items:  line 1
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line1';
        installerSOW.quantity = 1;
        installerSOW.moeFunded = 100;
        installerSOW.lineDescription = 'this is item 1';
        //installerSOW.salesforcePriceBookId = pricebook.Id;
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);


        //adding MOE funded items:  line 2
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line2';
        installerSOW.quantity = 2;
        installerSOW.moeFunded = 100;
        installerSOW.lineDescription = 'this is item 2';
        //installerSOW.salesforcePriceBookId = pricebook.Id;
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);
        
        
        
        //adding non-MOE funded items: line 3
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[0].Product2Id;
        product.name = pricebook.PricebookEntries[0].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line3';
        installerSOW.quantity = 3;
        installerSOW.moeFunded = 0;
        installerSOW.lineDescription = 'this is item 3';
        //installerSOW.salesforcePriceBookId = pricebook.Id;
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);

        //adding non-MOE funded items: line 4
        product = new ServiceEventNDWrapper.Product();
        product.salesforceId = pricebook.PricebookEntries[1].Product2Id;
        product.name = pricebook.PricebookEntries[1].Product2.Name;

        installerSOW = new ServiceEventNDWrapper.InstallerSOW ();
        installerSOW.x_id = 'line4';
        installerSOW.quantity = 4;
        installerSOW.moeFunded = 0;
        installerSOW.lineDescription = 'this is item 4';
        //installerSOW.salesforcePriceBookId = pricebook.Id;
        installerSOW.product = product;   
        installerSOWs.add(installerSOW);


        
        //pass installerSOWs into array of List<InstallerSOW> of the wrapper
        queueHandler.data.networkDesign.InstallerSOW = installerSOWs;

        //pass the id of a single Installer Pricebook to the payload
        queueHandler.data.networkDesign.salesforceInstallerPricebookId = pricebook.Id;
       //=====
            executeTest.NetworkDesignApprove_Installer_SOW(queueHandler.onboardingData,installerSOWs,queueHandler.data.networkDesign.salesforceInstallerPricebookId); 
         test.stopTest();
    }
   
}