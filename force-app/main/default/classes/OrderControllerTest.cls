@isTest()
public with sharing class OrderControllerTest {
    public static Map<String, Order> orderMap;
    
    @TestSetup
    Static void Setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
    }
    // Static void Setup(){
    
    // //create account
    // Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
    // schoolAccount.uuid__c = 'schoola';
    // schoolAccount.MoE_School_ID__c = '200';
    // schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
    // schoolAccount.NZ_Region__c = 'West Coast';
    // insert schoolAccount;
    
    // //there is a process/trigger on account that automatically create a principal contact at the time account record is created
    // Contact principalContact = new Contact();
    // List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
    // if (contacts.size()==1){
    //     //Contact principalContact = contacts[0];
    //     principalContact = contacts[0];
    //     principalContact.FirstName = 'FirstName1';
    //     principalContact.LastName = 'LastName1';
    //     principalContact.Email = 'email1@invalid-domain.com';
    //     update principalContact;
    // } else {
    //     //create contacts in the school
    //     //Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
    //     principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
    //     insert principalContact;    
    // }
    
    
    // List<Contact> newContacts = new List<Contact>();
    // newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False));
    // newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'External ICT', False));
    // newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'External ICT', False));
    
    // Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);
    
    // newContacts.add(exPrincipalContact);
    
    // insert newContacts;
    
    // exPrincipalContact.Inactive_Contact_Record__c = true;
    // update exPrincipalContact;
    
    // Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
    // User externalUser2 = TestClassUtility.createExternalUser(schoolContact);
    // insert externalUser2;
    
    // //create contract
    // Contract contract  = TestClassUtility.createContract(schoolAccount, Helper.getProgrammeNameMapping().get('NHR').Programme__c, principalContact, 'N4L Contract');
    // insert contract;
    // contract.Status = 'Activated';
    // update contract;
    
    // //create case
    // Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola']; 
    
    // String testEmail = 'email1@invalid-domain.com'; //to get principal contact
    // Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];
    
    // Case case1  = new Case(
    //     accountid = account.id,
    //     contactId = contact.id,
    //     subject = 'test case',
    //     Cutover_Appointment__c = DateTime.parse('11/3/2020 12:00 AM'),
    //     ICT_Date_onsite__c = DateTime.parse('11/3/2020 12:00 AM'),
    
    //     RecordTypeId = TestClassUtility.getRecordTypeId(Schema.SObjectType.Case, 'Onboarding')
    
    // );
    // insert case1;
    
    // //create provider
    // Account provider = TestClassUtility.createAccount('exeed',  'Non-School Organisation');
    // insert provider;
    
    // //create provider.contact
    // Contact providerContact = TestClassUtility.createContact(provider.Id, 'FirstName6', 'LastName6', 'email6@invalid-domain.com', '027666666', 'ICT Leader', False);
    // insert providerContact;
    
    // //update provider's billing contact and address to show in order
    // provider.Billing_Contact__c = providerContact.Id;
    // provider.BillingStreet = '123 Beautiful Street';
    // provider.BillingCity = 'Auckland';
    // provider.BillingPostalCode = '1234';
    // provider.BillingCountry = 'New Zealand';
    // update provider;
    
    // //create pricebook
    // //List<Pricebook2> pricebooks = [SELECT id, Name FROM Pricebook2 WHERE Name = 'exeed' LIMIT 1];
    // Pricebook2 pricebook = new Pricebook2(
    //     name = 'exeed',
    //     provider__c = provider.Id
    // );
    // insert pricebook;
    
    // //create standard pricebook
    // Id standardpricebookid = Test.getStandardPricebookId();
    
    
    // //create product2
    // List<Product2> products = new List<Product2>();
    // products.add(new Product2(
    //     name = '48-Port Switch, 4x1G SFP+ Uplink Ports',
    //     ProductCode = 'ICX7150-48-4X1G',
    //     Description = 'ICX 7150 Switch, 48x 10/100/1000 ports, 2x 1G RJ45 uplink-ports, 4x 1G SFP uplink-ports upgradable to up to 4x 10G SFP+',
    //     QuantityUnitOfMeasure = 'Each'
    // ));  
    // products.add(new Product2(
    //     name = 'R650 Dual Band 11ax Indoor AP, 2/4 Stream',
    //     ProductCode = '901-R650-WW00',
    //     Description = 'R650 Dual Band, Wi-Fi 6, 4x4:4 5GHz, 2x2:2 2.4GHz Access Point',
    //     QuantityUnitOfMeasure = 'Each'
    // ));  
    // products.add(new Product2(
    //     name = '48-Port POE+ 370W Switch, 4x1G SFP+ Uplink Ports',
    //     ProductCode = 'ICX7150-48P-4X1G',
    //     Description = 'ICX 7150 Switch, 48x 10/100/1000 PoE+ ports, 2x 1G RJ45 uplink-ports, 2x 1G SFP and 2x 10G SFP+ uplink-ports upgradable to 4x 10G SFP+',
    //     QuantityUnitOfMeasure = 'Each'
    // )); 
    // insert products;
    
    // List<PricebookEntry> pricebookEntries =  new List<PricebookEntry>();
    // for(Product2 product : products){
    //     //Create PricebookEntry
    //     pricebookEntries.add(new PricebookEntry(
    //         Product2Id = product.Id,
    //         Pricebook2Id = standardpricebookid,
    //         UnitPrice = 10,
    //         BuyPrice__c = 12,
    //         isActive = true       
    //     ));
    
    //     pricebookEntries.add(new PricebookEntry(
    //         Product2Id = product.Id,
    //         Pricebook2Id = pricebook.Id,
    //         UnitPrice = 10,
    //         BuyPrice__c = 12,
    //         isActive = true
    //     ));
    // }
    // insert pricebookEntries;
    
    // //create Order
    // Order order = new Order();
    // order.AccountId = schoolAccount.Id;
    // order.Case__c = case1.id;
    // order.Status = 'Draft';
    // order.PoDate = date.today();
    // order.EffectiveDate = date.today();
    // order.PoNumber = 'PO123123';
    // order.Provider__c = provider.Id;
    // order.Pricebook2Id = pricebook.Id;
    // order.ContractId = contract.Id;
    // order.Xero_Error__c = '';
    // order.ShippingCountry = 'New Zealand';
    // order.ShippingCity = 'Auckland';
    // order.ShippingStreet = '123 Queen Street';
    // order.ShippingPostalCode = '0622';
    // //order.uuid__c = '053da310-06f7-4b3d-97ab-7e56d2e43c36'; //added in NP-581 to satistfy validation rule
    // Insert order;
    
    
    // List<OrderItem> orderItems = new List<OrderItem>();
    // List<PricebookEntry> entries = [SELECT Id,Pricebook2Id,Product2Id FROM pricebookentry WHERE Pricebook2Id =: pricebook.Id];          
    // For(PricebookEntry entry : entries){
    //     orderItems.add(new OrderItem(
    //         OrderId = order.Id,
    //         Product2Id = entry.Product2Id,
    //         Quantity = 10,
    //         UnitPrice = 12,
    //         Discount__c = 0,
    //         PricebookEntryid = entries[0].id
    //     ));
    // }
    // Insert orderItems;
    // system.debug('~~~orderItems+'+orderItems);
    // }
    
    public static void setupXeroApiMock(){
        //copied from XeroAPITest.testSendPurchaseOrderSuccess()
        String xeroEndpoint = 'callout:Xero/api.xro/2.0';
        // Set the Mock Classes for the multiple callouts
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setMultiStaticMock(new Map<String, String>{
            xeroEndpoint + '/Contacts'  => 'XeroContactMock',
                xeroEndpoint + '/PurchaseOrders' => 'XeroPurchaseOrderMock'
                }));
    }
    
    public static Map<String, Order> getOrderMap(){
        Map<String, Order> result = new Map<String, Order>();
        List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, 
                              Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Earliest_Delivery_Date__c, Latest_Delivery_Date__c,
                              OrderNumber, OrderReferenceNumber, Xero_Id__c, Charge_To__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                              Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
                              Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry, Description, Planned_Install_Date__c FROM Order];
        For(Order order : orders){
            result.put(order.Description , order);
        }
        return result;
    }
    
    public static Contract activateOrderContract(Id contractId){
        Contract contract = [SELECT id, Status FROM Contract WHERE id =: contractId];
        contract.status = 'Activated';
        update contract;
        return contract; 
    }
    
    static testMethod void test_approveOrder1_success(){
        setupXeroApiMock();
        
        //Order order = [SELECT Id, Type, PoNumber, PoDate, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order LIMIT 1];
        Order order = getOrderMap().get('equipmentProvider1Order');
        order.type = 'Equipment - New';
        order.PoNumber = null; //xero integration will populate this field
        order.PoDate = null; //xero integration will populate this field
        update order;
        
        Test.startTest();
        
        Map<String,String> results = OrderController.approveOrder1(order.id);
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(200, res.statuscode);
        
        Order testOrder = OrderController.listOrders(order.id)[0]; //get the latest updated order
        //expected test value came from static resource: XeroPurchaseOrderMock
        system.assertEquals('PO-0079', testOrder.PoNumber); 
        system.assertEquals('475f4d8e-88f9-4a54-b025-9ecf8ee99b52', testOrder.Xero_Id__c);
        
        Test.stopTest();
        
    }
    
    static testMethod void test_approveOrder1_error() {
        Test.startTest();
        //this test invokes 1; 2.1, 2.2 and 2.3 and 3
        //Order order = [SELECT Id, Type, PoNumber, PoDate, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order LIMIT 1];
        Order order = getOrderMap().get('equipmentProvider1Order');
        order.type = 'Equipment - New';
        update order;
        
        //valid order.id but does not exist
        Map<String,String> results = OrderController.approveOrder1('8012O000000LM7GQAW'); //random Order.Id that this unit test cannot find
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(404, res.statuscode);
        
        //order.id cannot be null
        results = OrderController.approveOrder1(null);
        res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        //PO Number already exist, skip Xero Integration
        results = OrderController.approveOrder1(order.id);
        res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(200, res.statuscode);
        //system.assertEquals(true, res.results.get('Xero Integration').contains('Skipped Xero Integration'));
        
        
        //test error from Xero Api
        TestClassUtility.setStaticMock(400,'XeroPurchaseOrderMock');
      
        order.PoNumber = null; //xero integration will populate this field
        order.PoDate = null; //xero integration will populate this field
        update order;
        
        results = OrderController.approveOrder1(order.id);
        res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        //system.assertEquals(true, res.results.containsKey('Xero Integration Error')); 
        //Helper.createLogFile(results.get('response'), 'test_approveOrder1_error', '.txt', 'System Admin Log Files');
        Test.stopTest();
        
    }
    
    /* Retired MARCH 2023 (MW-67)
    static testMethod void test_approveOrder2_Equipment_success() {
        Test.startTest();
        //this test invokes 1; 2.1, 2.2 and 2.3 and 3
        //List<Order> orders = [SELECT Id, Type, PoDate, PoNumber, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order WHERE PoNumber = 'PO123123'];
        //Order order = orders[0];
        Order order = getOrderMap().get('equipmentProvider1Order');
        order.type = 'Equipment - New';
        order.PoNumber = 'PO123123';
        order.uuid__c = 'd1ea9a33-d89a-4815-aa92-2a411b36ce3c'; //this uuid appears in json body
        update order;
        
        activateOrderContract(order.ContractId); //get ready contract status = activated, because OrderController.approveOrder2() will set order.Status = 'Activated';
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'NetworkDesignMock'));
        
        Map<String,String> results = OrderController.approveOrder2(order.id);
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        
        
        system.assertEquals(400, res.statuscode);
        
        //Integer invocations = Limits.getEmailInvocations();
        //system.assertEquals(TRUE, (invocations >= 1), 'at least an email should be sent');
        Test.stopTest();
    } */
    
    static testMethod void test_approveOrder2_SOW_success() {
        //this test invokes 1; 2.1, 2.2 and 2.3 and 3
        // List<Order> orders = [SELECT Id, Type, PoDate, PoNumber, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        Test.startTest();
        Order order = getOrderMap().get('sowInstaller1Order');
        order.type = 'SOW - Installer';
        order.PoNumber = 'PO123123';
        order.uuid__c = 'd1ea9a33-d89a-4815-aa92-2a411b36ce3c'; //this uuid appears in json body
        update order;
        
        activateOrderContract(order.ContractId); //get ready contract status = activated, because OrderController.approveOrder2() will set order.Status = 'Activated';
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'NetworkDesignMock'));
        
        
        
        Map<String,String> results = OrderController.approveOrder2(order.id);
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(200, res.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations >= 1), 'at least an email should be sent');
        
        Test.stopTest();
        
    }
    
    
    static testMethod void test_approveOrder2_Error() {
        //this test invokes 1; 2.1, 2.2 and 2.3 and 3
        // List<Order> orders = [SELECT Id, Type, PoDate, PoNumber, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        Test.startTest();
        Order order = getOrderMap().get('equipmentProvider1Order');
        order.type = 'Equipment - New';
        order.PoNumber = null;
        order.PoDate = null;
        order.uuid__c = ''; //this uuid appears in json body
        update order;
        
        activateOrderContract(order.ContractId); //get ready contract status = activated, because OrderController.approveOrder2() will set order.Status = 'Activated';
        
        //valid order.id but does not exist
        Map<String,String> results = OrderController.approveOrder2('8012O000000LM7GQAW'); //random Order.Id that this unit test cannot find
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(404, res.statuscode);
        
        //order.id cannot be null
        results = OrderController.approveOrder2(null);
        res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        //expecting to fail when PONumber is null
        results = OrderController.approveOrder2(order.id);
        res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations == 0), 'at least an email should be sent');
        Test.stopTest();
    }
    
    static testMethod void test_approveOrder2_SOW_Error() {
        //this test invokes 1; 2.1, 2.2 and 2.3 and 3
        // List<Order> orders = [SELECT Id, Type, PoDate, PoNumber, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        Order order = getOrderMap().get('sowInstaller1Order');
        order.type = 'SOW - Installer';
        order.uuid__c = 'd1ea9a33-d89a-4815-aa92-2a411b36ce3c'; //this uuid appears in json body
        update order;
        
        // Call method to test
        Test.startTest();
        system.assertEquals(True, order.Type.contains('SOW'));
        
        //When PODate ==  null, return 400
        order.PoDate = null;
        update order;
        
        activateOrderContract(order.ContractId); //get ready contract status = activated, because OrderController.approveOrder2() will set order.Status = 'Activated';
        
        Map<String,String> results = OrderController.approveOrder2(order.id);
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        //order.PoNumber == null, return 400
        order.PoNumber = null;
        update order;
        
        results = OrderController.approveOrder2(order.id);
        res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        Map<String,String> result = OrderController.approveOrder2('8012O000000SSk1QAG');
        res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        system.assertEquals(404, res.statuscode);
        
        //Map<String,String> result1 = OrderController.approveOrder2(null);
        //res = (MethodResponse) JSON.deserialize(result1.get('response'), MethodResponse.class);
        //system.assertEquals(200, res.statuscode);
        
        List<OrderItem> orderItems = [select Id, OrderId from OrderItem where OrderId =: order.Id];
        Delete orderItems;
        
        results = OrderController.approveOrder2(order.id);
        res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        Test.stopTest();
    }
      /* Retired MARCH 2023 (MW-67)
    static testMethod void test_approveOrder2_getNetworkDesign_Error() {
        //this test invokes 2.1, 2.2 and 2.3
        // List<Order> orders = [SELECT Id, Type, PoNumber, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        Order order = getOrderMap().get('equipmentProvider1Order');
        order.type = 'Equipment - New';
        order.uuid__c = 'd1ea9a33-d89a-4815-aa92-2a411b36ce3c'; //this uuid appears in json body
        update order;  
        
        //prepare negative response        
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(400,'GetNetworkDesignResponse'));
        
        
        Test.startTest();
        activateOrderContract(order.ContractId); //get ready contract status = activated, because OrderController.approveOrder2() will set order.Status = 'Activated';
        Map<String,String> results = OrderController.approveOrder2(order.Id);
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        Test.stopTest();
    }
    
    */
    static testMethod void test_SendPurchaseOrder_Equipment() {
        // List<Order> orders = [SELECT Id, Type, PoNumber FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0]; 
        test.startTest();
        Order order = getOrderMap().get('equipmentProvider1Order');
        order.type = 'Equipment - New';
        order.uuid__c = 'd1ea9a33-d89a-4815-aa92-2a411b36ce3c'; //added in NP-581 to satistfy validation rule
        update order;
        
        activateOrderContract(order.ContractId); //get ready to set order.Status = 'Activated';
        
        order.Status = 'Activated'; //I had to seperate DML in setting Status to 'Activated in order to satisfy UUID validation rule
        update order;
        
        // List<ID> ids = new List<ID>();
        // ids.add(order.Id);
        //OrderController.SendPurchaseOrder(ids); //this will send email PO - Equipment with CSV attachment
        
        List<Order> orders = OrderController.listOrders(order.id);
        order = orders[0]; 
        
        
        MethodResponse res = OrderController.PurchaseOrderEquipment(order);
        system.assertEquals(200, res.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
        test.stopTest();
    }
    
    static testMethod void test_SendPurchaseOrder_Installer() {
        // List<Order> orders = [SELECT Id, Status, Type, PoNumber FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        test.startTest();
        Order order = getOrderMap().get('sowInstaller1Order');
        order.type = 'SOW - Installer';
        order.uuid__c = 'ed4f580f-5914-459e-b784-a784cb015fc3'; //added in NP-581 to satistfy validation rule
        update order;
        
        Case c = [SELECT Id, ER_Lite__c FROM Case WHERE Id = :order.Case__c];
        c.ER_Lite__c = true; // added by Carolyn for ER Lite coverage (MNTC-1278)
        update c;
        
        activateOrderContract(order.ContractId); //get ready to set order.Status = 'Activated';
        
        order.Status = 'Activated'; //I had to seperate DML in setting Status to 'Activated in order to satisfy UUID validation rule
        update order;
        
        List<Order> orders = OrderController.listOrders(order.id);
        order = orders[0]; 
        
        MethodResponse res = OrderController.PurchaseOrderInstaller(order);
        system.assertEquals(200, res.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
        test.stopTest();
    }
    
    static testMethod void test_SendPurchaseOrder_ICT() {
        // List<Order> orders = [SELECT Id, Status, Type, PoNumber FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        test.startTest();
        Order order = getOrderMap().get('sowInstaller1Order');
        order.type = 'SOW - ICT';
        order.uuid__c = 'ed4f580f-5914-459e-b784-a784cb015fc3'; //added in NP-581 to satistfy validation rule
        update order;
        
        activateOrderContract(order.ContractId); //get ready to set order.Status = 'Activated';
        
        order.Status = 'Activated'; //I had to seperate DML in setting Status to 'Activated in order to satisfy UUID validation rule
        update order;
        
        List<Order> orders = OrderController.listOrders(order.id);
        order = orders[0]; 
        
        MethodResponse res = OrderController.PurchaseOrderInstaller(order);
        system.assertEquals(200, res.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
        test.stopTest();
    }
    
    
    static testMethod void test_ValidationRule_Populated_UUID_cannot_be_modified() {
        test.startTest();
        String uuid = 'b5417e4e-5c36-4619-98eb-700997d1f955';
        // List<Order> orders = [SELECT Id, Type, PoNumber FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        Order order = getOrderMap().get('equipmentProvider1Order');
        order.type = 'Equipment - New';
        order.uuid__c = uuid;
        update order;
        
        //when uuid was NULL at first, validation should allow changes to uuid.
        Order testOrder = [SELECT Id, uuid__c FROM Order WHERE Id =: order.Id];
        system.assertEquals(uuid, testOrder.uuid__c, 'order uuid should be the same as given uuid ');
        
        try{
            String changing_uuid = '696a27d9-fb02-4c93-b92f-fc6646b5b40a';
            order.uuid__c = changing_uuid;
            update order;
        }
        catch (System.DmlException ex){
            //when the uuid already has a value, validation should prevent changes to uuid.
            System.assertEquals( StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, ex.getDmlType(0));             
            //expecting - System.DmlException: Update failed. First exception on row 0 with id 8015P000000E2h3QAC; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, After Order UUID has been populated, it should not be modified.: [uuid__c]'
        }
        test.stopTest();
    }
    
    static testMethod void cancelOrder_success() {
        // List<Order> orders = [SELECT Id, Type, PoNumber, Xero_Error__c, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        // Set the Mock Classes for the multiple callouts
        String xeroEndpoint = 'callout:Xero/api.xro/2.0';
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setMultiStaticMock(new Map<String, String>{
            xeroEndpoint + '/Contacts'  => 'XeroContactMock',
                xeroEndpoint + '/PurchaseOrders' => 'XeroPurchaseOrderMock'
                }));
        
         test.startTest();
        Order order = getOrderMap().get('equipmentProvider1Order');
        
        activateOrderContract(order.ContractId); //get ready to set order.Status = 'Activated';
        
        order.type = 'Equipment - New';
        order.PoNumber = '0079';
        order.Xero_Id__c = '475f4d8e-88f9-4a54-b025-9ecf8ee99b52';
        order.Xero_Error__c = null;
        order.uuid__c = null; //this uuid appears in json body
        
        order.Status = 'Activated';
        update order;
        
        Map<String,String> results = OrderController.cancelOrder(order.Id);
        test.stopTest();
        system.debug('S##$#)@(FE(#@#@Debuging: '+results);
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
         
        system.assertEquals(400, res.statuscode);
        
        
    }
    
    static testMethod void cancelOrder_fail() {
        // List<Order> orders = [SELECT Id, Type, PoNumber, Xero_Error__c, Case__r.caseNumber, uuid__c, Account.uuid__c FROM Order WHERE PoNumber = 'PO123123'];
        // Order order = orders[0];
        Order order = getOrderMap().get('equipmentProvider1Order');
        order.type = 'Equipment - New';
        order.Xero_Id__c = '475f4d8e-88f9-4a54-b025-9ecf8ee99b52';
        order.uuid__c = 'd1ea9a33-d89a-4815-aa92-2a411b36ce3c'; //this uuid appears in json body
        
        //test error from Xero Api
        TestClassUtility.setStaticMock(400,'XeroPurchaseOrderMock');
        
        test.startTest();             
        activateOrderContract(order.ContractId); //get ready to set order.Status = 'Activated';
        order.Status = 'Activated';
        update order;
        
        Map<String,String> results = OrderController.cancelOrder(order.Id);
        
        MethodResponse res = (MethodResponse) JSON.deserialize(results.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        test.stopTest();
    }
    
    static testMethod void test_GetChargeToCode(){
        //positive test
        system.assertEquals('MOE', OrderController.GetChargeToCode('MOE'));
        system.assertEquals('TNFL:MOE', OrderController.GetChargeToCode('N4L'));
        system.assertEquals('TNFL', OrderController.GetChargeToCode('EQONLY'));
        //negative test
        system.assertEquals('', OrderController.GetChargeToCode('invalid_name'));
        system.assertEquals('', OrderController.GetChargeToCode(''));
        system.assertEquals('', OrderController.GetChargeToCode(null));
    }
    
    static testMethod void test_GetTravelTimeAndVehicleMileage(){
        Order order = getOrderMap().get('sowInstaller1Order');
        order.type = 'SOW - ICT';
        order.PoNumber = 'PO123123';
        order.uuid__c = 'd1ea9a33-d89a-4815-aa92-2a411b36ce3c'; //this uuid appears in json body
        update order;
        
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        
        Test.startTest();
        OrderController.GetTravelTimeAndVehicleMileage(order.id);
        Test.stopTest();
        
        
        
    }
    
    
    
}