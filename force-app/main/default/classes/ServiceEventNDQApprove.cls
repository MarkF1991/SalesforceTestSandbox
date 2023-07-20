/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2021-01-15
* @description to chain Queueable Apex jobs: Create Equipment New Orders > Create Installer SOW Orders > Update Case > Get PDF and Safe as File > Update Task and finally trigger TaskActions process builder
* CHANGE LOG
* 2021-02-18 MNTC-414 Add error handling on GetPDFandSaveAsFile method when Get PDF HttpResponse return status code other than 200
* 2021-02-20 MNTC-366: Extend method queue_CreateOrder_Installer_SOW() for Network Design - create SOW - Installer Order on approve event
* 2021-03-02 MNTC-487: OrderItem UnitPrice = (pricebookEntry.UnitPrice == 0 ? installerSOW.cost : pricebookEntry.UnitPrice)
* 2021-03-04 MNTC-488: SOW - Installer order should not have Relinquished Equipment Return to populated
**/
public with sharing class ServiceEventNDQApprove extends ServiceEventNDQ {
    public ServiceEventNDQApprove(ServiceEventWrapper event) {
        super(event);

        //get user for the approver of the design
        this.onboardingData.getUser(this.data.networkDesign.approvedBy, 'approvedBy');

        //get school record
        this.onboardingData.getAccount(this.data.networkDesign.schoolId, 'school');

        //get Relinquished Equipment Return to (to populate Order.ReturnTo__c - Lookup(Organisation)) //default to null
        List<ServiceEventNDWrapper.EquipmentForRemoval> removals = data.networkDesign.equipmentForRemoval;
        if(removals.size() > 0){
            this.onboardingData.getAccount(removals[0].organisationId, 'returnTo');
        }

        //prepare a Map collection of pricebook and pricebook entries in inner class
        this.onboardingData.preparePricebookMap();

        //validation
        if(!this.onboardingData.errorMessages.isEmpty()){
            this.trackServiceEvent(this.onboardingData.getErrorMessage(), 400, this.onboardingData.onboardingCase.id);
            return;
        }
        
        if(!Test.isRunningTest()){ //to prevent unit test failure: System.AsyncException: Maximum stack depth has been reached.  
            system.enqueueJob(new queue_CreateOrder_Equipment_New(this));
        }

    }

    //NP-1403: Create Order and Order Items for Order Type: Equipment - New
    public class queue_CreateOrder_Equipment_New implements Queueable {
        Private ServiceEventNDQApprove queueHandler;
        Private ServiceEventNDQ.OnboardingData onboardingData;
        Private ServiceEventWrapper.Data_NetworkDesign data;

        public queue_CreateOrder_Equipment_New(ServiceEventNDQApprove queueHandler){
            this.queueHandler = queueHandler;
            this.onboardingData = queueHandler.onboardingData;
            this.data = queueHandler.data;
        }

        public void execute(QueueableContext context) {
            Boolean isSuccessful = execute_CreateOrder_Equipment_New();

            if(!Test.isRunningTest() && isSuccessful){ //to prevent unit test failure: System.AsyncException: Maximum stack depth has been reached.  
                system.enqueueJob(new queue_CreateOrder_Installer_SOW(this.queueHandler));
            }
        }

        public Boolean execute_CreateOrder_Equipment_New(){
            Boolean isSuccessful = true;
            List<ServiceEventNDWrapper.NewEquipment> equipments = this.data.networkDesign.newEquipment;
            if(equipments.size() > 0){
                // newEquipment list is not null, therefore, need to create Order with Order Type = 'Equipment - New'
                MethodResponse res = NetworkDesignApprove_Equipment_New(this.onboardingData, equipments);
                if (res.statuscode >= 400){
                    this.queueHandler.trackServiceEvent(res.results.get('error'),  res.statuscode, this.onboardingData.onboardingCase.id);//display as error message
                    isSuccessful = false;
                }
            }
            return isSuccessful;
        }

        //main Create Order and Order Items for Order Type: Equipment - New
        public MethodResponse NetworkDesignApprove_Equipment_New(OnboardingData onboardingData, List<ServiceEventNDWrapper.NewEquipment> equipments){
            MethodResponse res = new MethodResponse();
            
            Map<String, Order> ordersMap = new Map<String, Order>();
            List<Order> orders  = new List<Order>();
            List<OrderItem> orderItems = new List<OrderItem>();
            
    
            //validate pricebookIds given in payload
            Set<String> validPricebookIds = new Set<String>();
            Set<String> invalidPricebookIds = new Set<String>();
            For(ServiceEventNDWrapper.NewEquipment equipment : equipments){
                if (onboardingData.pricebooksMap.containsKey(equipment.salesforcePriceBookId)) {
                    validPricebookIds.add(equipment.salesforcePriceBookId);
                } else {
                    invalidPricebookIds.add(equipment.salesforcePriceBookId);
                }
            }
            if (!invalidPricebookIds.isEmpty()){
                res.setStatus(400);
                res.setResult('error', 'Invalid salesforcePriceBookId from the payload : ' + invalidPricebookIds.toString());
                return res;
            }
    
            //prepare a mapping for Pricebook and Product so that we can get valid PricebookEntry
            OnboardingData.preparePricebookProductMap(validPricebookIds);
    
            For(ServiceEventNDWrapper.NewEquipment equipment : equipments){
                Pricebook2 pricebook = onboardingData.pricebooksMap.get(equipment.salesforcePriceBookId);
    
                String key = ServiceEventNDQController.getPricebookChargeToKey(pricebook.Id, equipment.moeFunded);
    
                //add map item when the key does not exist
                if (!ordersMap.containsKey(key)) {
                    Order value = new Order(
                        AccountId = onboardingData.school.Id,
                        Case__c = onboardingData.onboardingCase.Id,
                        ContractId = onboardingData.onboardingCase.Contract__c,
                        OpportunityId = onboardingData.onboardingCase.Opportunity__c,
                        uuid__c = onboardingData.designId,
                        CompanyAuthorizedById = onboardingData.designApprovedBy.Id,
                        CompanyAuthorizedDate = date.today(),

                        EffectiveDate = date.today(),
                        Status = 'Draft',
                        Type = 'Equipment - New',
                        OwnerId = onboardingData.school.ownerId,
                        
                        Charge_To__c = ServiceEventNDQController.getChargeTo(equipment.moeFunded),
                        ReturnTo__c = (onboardingData.returnTo != null ? onboardingData.returnTo.Id : null ),
                        Equipment_Returns_not_required__c = (onboardingData.returnTo == null),
                        Pricebook2Id = pricebook.Id,
                        Provider__c = pricebook.Provider__c,
                        Allow_Part_Shipment__c = FALSE,
                        Urgent_Delivery_Required__c = FALSE,
                        IsReductionOrder = FALSE,
                        
                        BillingCity= onboardingData.school.BillingCity,
                        BillingCountry= onboardingData.school.BillingCountry,
                        BillingCountryCode= onboardingData.school.BillingCountryCode,
                        BillingGeocodeAccuracy= onboardingData.school.BillingGeocodeAccuracy,
                        BillingLatitude= onboardingData.school.BillingLatitude,
                        BillingLongitude= onboardingData.school.BillingLongitude,
                        BillingPostalCode= onboardingData.school.BillingPostalCode,
                        BillingState= onboardingData.school.BillingState,
                        BillingStateCode= onboardingData.school.BillingStateCode,
                        BillingStreet= onboardingData.school.BillingStreet,
                        
                        ShippingCity= onboardingData.school.ShippingCity,
                        ShippingCountry= onboardingData.school.ShippingCountry,
                        ShippingCountryCode= onboardingData.school.ShippingCountryCode,
                        ShippingGeocodeAccuracy= onboardingData.school.ShippingGeocodeAccuracy,
                        ShippingLatitude= onboardingData.school.ShippingLatitude,
                        ShippingLongitude= onboardingData.school.ShippingLongitude,
                        ShippingPostalCode= onboardingData.school.ShippingPostalCode,
                        ShippingState= onboardingData.school.ShippingState,
                        ShippingStateCode= onboardingData.school.ShippingStateCode,
                        ShippingStreet= onboardingData.school.ShippingStreet
                    );
                    ordersMap.put(key, value);
                    //System.debug('order Id ' + value.Id);
                    //System.debug('order AccountId ' + value.AccountId);
                    //System.debug('order Case__c ' + value.Case__c);
                    //System.debug('order ContractId ' + value.ContractId);
                    //System.debug('order OpportunityId ' + value.OpportunityId);
                    //System.debug('order CompanyAuthorizedById ' + value.CompanyAuthorizedById);
                    //System.debug('order OwnerId ' + value.OwnerId);
                    //System.debug('order Pricebook2Id ' + value.Pricebook2Id);
                    //System.debug('order ReturnTo__c ' + value.ReturnTo__c);
                    //System.debug('order Provider__c ' + value.Provider__c);
                }
            }
    
            try {
                //add the unique orders from map to a list for bulk insert
                for(String key : ordersMap.keyset()){
                    orders.add(ordersMap.get(key));  
                }
                insert orders;
            } catch (Exception e) {
                res.setStatus(500);
                res.setResult('error', (e instanceof System.DmlException ? e.getDmlType(0) + ' ' + e.getDmlMessage(0) : '')  + '     ' + e.getStackTraceString());//display as internal error
                return res;
            }
    
    
            //validate productIds given in payload
            String pricebookId = '';
            String productId = '';
            Set<String> validProductIds = new Set<String>();
            Set<String> invalidProductIds = new Set<String>();
            For(ServiceEventNDWrapper.NewEquipment equipment : equipments){
                pricebookId = equipment.salesforcePriceBookId;
                productId = equipment.product.salesforceId;
                String pricebookProductKey = Helper.concatenateKey(new List<String>{pricebookId, productId});
                if (onboardingData.pricebookProductMap.containsKey(pricebookProductKey)) {
                    validProductIds.add(productId);
                } else {
                    invalidProductIds.add(productId);
                }
            }
            if (!invalidProductIds.isEmpty()){
                res.setStatus(400);
                res.setResult('error', 'Invalid product Id from the payload : ' + invalidProductIds.toString());
                return res;
            }
            
            //add Order Line items to Orders
            For(ServiceEventNDWrapper.NewEquipment equipment : equipments){
                    pricebookId = equipment.salesforcePriceBookId;
                    productId = equipment.product.salesforceId;
                    String key = ServiceEventNDQController.getPricebookChargeToKey(pricebookId, equipment.moeFunded);
    
                    //add map item when the key does not exist
                    if (ordersMap.containsKey(key)) {
                        
                        PricebookEntry pricebookEntry = onboardingData.pricebookProductMap.get( Helper.concatenateKey(new List<String>{pricebookId, productId}));
    
                        orderItems.add(new OrderItem(
                                                    OrderId = ordersMap.get(key).Id,
                                                    Quantity = equipment.quantity,
                                                    Description = equipment.lineDescription,
                                                    ListPrice = pricebookEntry.UnitPrice,
                                                    UnitPrice = pricebookEntry.UnitPrice,
                                                    Discount__c = equipment.moeFunded,
                                                    Product2Id = equipment.product.salesforceId,
                                                    PricebookEntryid = pricebookEntry.Id
                        ));
                    }                  
            }
    
            try{
                insert orderItems;
            } catch (Exception e) {
                res.setStatus(500);
                res.setResult('error', (e instanceof System.DmlException ? e.getDmlType(0) + ' ' + e.getDmlMessage(0) : '')  + '     ' + e.getStackTraceString());//display as internal error
                return res;
            }

            res.setStatus(200);
            return res;
        }

    }

    //MNTC-366: Network Design - create SOW - Installer Order on approve event
    public class queue_CreateOrder_Installer_SOW implements Queueable {
        Private ServiceEventNDQApprove queueHandler;
        Private ServiceEventNDQ.OnboardingData onboardingData;
        Private ServiceEventWrapper.Data_NetworkDesign data;

        public queue_CreateOrder_Installer_SOW(ServiceEventNDQApprove queueHandler){
            this.queueHandler = queueHandler;
            this.onboardingData = queueHandler.onboardingData;
            this.data = queueHandler.data;
        }

        public void execute(QueueableContext context) {
            Boolean isSuccessful = execute_CreateOrder_Installer_SOW();

            if(!Test.isRunningTest() && isSuccessful){ //to prevent unit test failure: System.AsyncException: Maximum stack depth has been reached.  
                system.enqueueJob(new queue_UpdateCase(this.queueHandler));
            }
        }

        public Boolean execute_CreateOrder_Installer_SOW(){
            Boolean isSuccessful = true;
            List<ServiceEventNDWrapper.InstallerSOW> installerSOWs = this.data.networkDesign.installerSOW;
            String installerPriceBookId = this.data.networkDesign.salesforceInstallerPricebookId; //from Platform Services point of view, there is only one installer per case. Hence, single installerPriceBookId is enough to cover all items in networkDesign.installerSOW

            if(!installerSOWs.isEmpty()){
                
                // newEquipment list is not null, therefore, need to create Order with Order Type = 'Equipment - New'
                MethodResponse res = NetworkDesignApprove_Installer_SOW(this.onboardingData, installerSOWs, installerPriceBookId);
                if (res.statuscode >= 400){
                    this.queueHandler.trackServiceEvent(res.results.get('error'),  res.statuscode, this.onboardingData.onboardingCase.id);//display as error message
                    isSuccessful = false;
                }
            }
            return isSuccessful;
        }

        //main Create Order and Order Items for Order Type: SOW - Installer
        public MethodResponse NetworkDesignApprove_Installer_SOW(OnboardingData onboardingData, List<ServiceEventNDWrapper.InstallerSOW> installerSOWs, String installerPriceBookId){
            MethodResponse res = new MethodResponse();
            
            Map<String, Order> ordersMap = new Map<String, Order>();
            List<Order> orders  = new List<Order>();
            List<OrderItem> orderItems = new List<OrderItem>();
            
    
            //validate pricebookIds given in payload
            Set<String> validPricebookIds = new Set<String>();
            Set<String> invalidPricebookIds = new Set<String>();

            
            
            if (onboardingData.pricebooksMap.containsKey(installerPriceBookId)) {
                validPricebookIds.add(installerPriceBookId);
            } else {
                invalidPricebookIds.add(installerPriceBookId);
            }
            
            if (!invalidPricebookIds.isEmpty()){
                res.setStatus(400);
                res.setResult('error', 'Invalid salesforcePriceBookId from the payload : ' + invalidPricebookIds.toString());
                return res;
            }
    
            //prepare a mapping for Pricebook and Product so that we can get valid PricebookEntry
            OnboardingData.preparePricebookProductMap(validPricebookIds);
    
            //set pricebook variable for the given installerPriceBookId
            Pricebook2 pricebook = onboardingData.pricebooksMap.get(installerPriceBookId);

            For(ServiceEventNDWrapper.InstallerSOW installerSOW : installerSOWs){
    
                String key = ServiceEventNDQController.getPricebookChargeToKey(pricebook.Id, installerSOW.moeFunded);
    
                //add map item when the key does not exist
                if (!ordersMap.containsKey(key)) {
                    ordersMap.put(key, new Order(
                                                AccountId = onboardingData.school.Id,
                                                Case__c = onboardingData.onboardingCase.Id,
                                                ContractId = onboardingData.onboardingCase.Contract__c,
                                                OpportunityId = onboardingData.onboardingCase.Opportunity__c,
                                                uuid__c = onboardingData.designId,
                                                CompanyAuthorizedById = onboardingData.designApprovedBy.Id,
                                                CompanyAuthorizedDate = date.today(),
    
                                                EffectiveDate = date.today(),
                                                Status = 'Draft',
                                                Type = 'SOW - Installer',
                                                OwnerId = onboardingData.school.ownerId,
                                                
                                                Charge_To__c = ServiceEventNDQController.getChargeTo(installerSOW.moeFunded),
                                                // ReturnTo__c = (onboardingData.returnTo != null ? onboardingData.returnTo.Id : null ),
                                                // Equipment_Returns_not_required__c = (onboardingData.returnTo == null),
                                                Pricebook2Id = pricebook.Id,
                                                Provider__c = pricebook.Provider__c,
                                                Allow_Part_Shipment__c = FALSE,
                                                Urgent_Delivery_Required__c = FALSE,
                                                IsReductionOrder = FALSE,
                                                
                                                BillingCity= onboardingData.school.BillingCity,
                                                BillingCountry= onboardingData.school.BillingCountry,
                                                BillingCountryCode= onboardingData.school.BillingCountryCode,
                                                BillingGeocodeAccuracy= onboardingData.school.BillingGeocodeAccuracy,
                                                BillingLatitude= onboardingData.school.BillingLatitude,
                                                BillingLongitude= onboardingData.school.BillingLongitude,
                                                BillingPostalCode= onboardingData.school.BillingPostalCode,
                                                BillingState= onboardingData.school.BillingState,
                                                BillingStateCode= onboardingData.school.BillingStateCode,
                                                BillingStreet= onboardingData.school.BillingStreet,
                                                
                                                ShippingCity= onboardingData.school.ShippingCity,
                                                ShippingCountry= onboardingData.school.ShippingCountry,
                                                ShippingCountryCode= onboardingData.school.ShippingCountryCode,
                                                ShippingGeocodeAccuracy= onboardingData.school.ShippingGeocodeAccuracy,
                                                ShippingLatitude= onboardingData.school.ShippingLatitude,
                                                ShippingLongitude= onboardingData.school.ShippingLongitude,
                                                ShippingPostalCode= onboardingData.school.ShippingPostalCode,
                                                ShippingState= onboardingData.school.ShippingState,
                                                ShippingStateCode= onboardingData.school.ShippingStateCode,
                                                ShippingStreet= onboardingData.school.ShippingStreet
                                                ));
                }                  
            }
    
            try {
                //add the unique orders from map to a list for bulk insert
                for(String key : ordersMap.keyset()){
                    orders.add(ordersMap.get(key));  
                }
                insert orders;
            } catch (Exception e) {
                res.setStatus(500);
                res.setResult('error', (e instanceof System.DmlException ? e.getDmlType(0) + ' ' + e.getDmlMessage(0) : '')  + '     ' + e.getStackTraceString());//display as internal error
                return res;
            }
    
    
            //validate productIds given in payload
            String pricebookId = '';
            String productId = '';
            Set<String> validProductIds = new Set<String>();
            Set<String> invalidProductIds = new Set<String>();
            For(ServiceEventNDWrapper.InstallerSOW installerSOW : installerSOWs){
                pricebookId = pricebook.Id;
                productId = installerSOW.product.salesforceId;
                String pricebookProductKey = Helper.concatenateKey(new List<String>{pricebookId, productId});
                if (onboardingData.pricebookProductMap.containsKey(pricebookProductKey)) {
                    validProductIds.add(productId);
                } else {
                    invalidProductIds.add(productId);
                }
            }
            if (!invalidProductIds.isEmpty()){
                res.setStatus(400);
                res.setResult('error', 'Invalid product Id from the payload : ' + invalidProductIds.toString());
                return res;
            }
            
            //add Order Line items to Orders
            For(ServiceEventNDWrapper.InstallerSOW installerSOW : installerSOWs){
                    pricebookId = pricebook.Id;
                    productId = installerSOW.product.salesforceId;
                    String key = ServiceEventNDQController.getPricebookChargeToKey(pricebookId, installerSOW.moeFunded);
    
                    //add map item when the key does not exist
                    if (ordersMap.containsKey(key)) {
                        
                        PricebookEntry pricebookEntry = onboardingData.pricebookProductMap.get( Helper.concatenateKey(new List<String>{pricebookId, productId}));
    
                        orderItems.add(new OrderItem(
                                                    OrderId = ordersMap.get(key).Id,
                                                    Quantity = installerSOW.quantity,
                                                    Description = installerSOW.lineDescription,
                                                    ListPrice = pricebookEntry.UnitPrice, //List price for the order product. Value is inherited from the associated PriceBookEntry upon order product creation. To prevent error: FIELD_INTEGRITY_EXCEPTION An Order Product must have the same List Price as the related Price Book Entry.: List Price
                                                    UnitPrice = (pricebookEntry.UnitPrice == 0 ? installerSOW.cost : pricebookEntry.UnitPrice),
                                                    Discount__c = installerSOW.moeFunded,
                                                    Product2Id = installerSOW.product.salesforceId,
                                                    PricebookEntryid = pricebookEntry.Id
                        ));
                    }                  
            }
    
            try{
                insert orderItems;
            } catch (Exception e) {
                res.setStatus(500);
                res.setResult('error', (e instanceof System.DmlException ? e.getDmlType(0) + ' ' + e.getDmlMessage(0) : '')  + '     ' + e.getStackTraceString());//display as internal error
                return res;
            }

            res.setStatus(200);
            return res;
        }

    }

    //inner class for queuable job
    public class queue_UpdateCase implements Queueable {
        Private ServiceEventNDQApprove queueHandler;
        Private ServiceEventNDQ.OnboardingData onboardingData;
        Private ServiceEventWrapper.Data_NetworkDesign data;
        
        public queue_UpdateCase(ServiceEventNDQApprove queueHandler){
        //public queue_UpdateCase(ServiceEventNDQApprove queueHandler, ServiceEventNDQ.OnboardingData onboardingData, ServiceEventWrapper.Data_NetworkDesign data){
            this.queueHandler = queueHandler;
            this.onboardingData = queueHandler.onboardingData;
            this.data = queueHandler.data;
        }

        public void execute(QueueableContext context) {
            Boolean isSuccessful = execute_UpdateCase();
            if(!Test.isRunningTest() && isSuccessful){ //to prevent unit test failure: System.AsyncException: Maximum stack depth has been reached.  
                system.enqueueJob(new queue_GetPDFandSaveAsFile(this.queueHandler));
            }
        }
 
        public Boolean execute_UpdateCase(){
            Boolean isSuccessful = true;
            //NP-1887: update Case Owner (Assigned To) to queue ‘ER Provisioning Coordinators Queue’
            List<Group> queues = [SELECT Id, Name FROM Group WHERE Name = 'ER Provisioning Coordinators Queue' LIMIT 1];
            If (!queues.isEmpty()){
                this.onboardingData.onboardingCase.OwnerId = queues[0].Id;
        
                try{
                    update this.onboardingData.onboardingCase;
                } catch (System.Exception e) {
                    this.queueHandler.trackServiceEvent(e, 400, this.onboardingData.onboardingCase.id);
                    isSuccessful = false;
                }

            } else {
                this.queueHandler.trackServiceEvent('Could not find Id for "ER Provisioning Coordinators Queue" to be set as Owner of case.', 400, this.onboardingData.onboardingCase.id);
                isSuccessful = false;
            }
            return isSuccessful;
        }

    }


    public class queue_GetPDFandSaveAsFile implements Queueable {
        Private ServiceEventNDQApprove queueHandler;
        Private ServiceEventNDQ.OnboardingData onboardingData;
        Private ServiceEventWrapper.Data_NetworkDesign data;
        Private List<ServiceEventNDWrapper.Pdf> pdfs;

        public queue_GetPDFandSaveAsFile(ServiceEventNDQApprove queueHandler){
            this.queueHandler = queueHandler;
            this.onboardingData = queueHandler.onboardingData;
            this.data = queueHandler.data;

            //prepare a list of pdfs for chaining queues to get and save pdfs 
            this.pdfs = new List<ServiceEventNDWrapper.Pdf>(this.data.networkDesign.pdfs);
            for (ServiceEventNDWrapper.Pdf pdf : this.pdfs){
                pdf.pdfParentId = this.onboardingData.onboardingCase.Contract__c;
            }
        }

        public void execute(QueueableContext context) {
            try{
                if(Test.isRunningTest()){ //to prevent it from running the chained queue. System.LimitException: Apex CPU time limit exceeded  
                    CalloutException e = new CalloutException();
                    e.setMessage('Read timed out');
                    throw e;
                } else {
                    system.enqueueJob(new ServiceEventNDQApprove.queue_RecursiveGetPDFandSaveAsFile(this.queueHandler, this.pdfs, new List<String>()));
                }
            } catch (System.Exception e) {
                this.queueHandler.trackServiceEvent(e, 400, this.onboardingData.onboardingCase.id);
            }
        }
    }

    public class queue_RecursiveGetPDFandSaveAsFile implements Queueable, Database.AllowsCallouts {
        Private ServiceEventNDQApprove queueHandler;
        Private ServiceEventNDQ.OnboardingData onboardingData;
        Private List<ServiceEventNDWrapper.Pdf> pdfs;
        Private List<String> entityIds;

        public queue_RecursiveGetPDFandSaveAsFile(ServiceEventNDQApprove queueHandler, List<ServiceEventNDWrapper.Pdf> pdfs, List<String> entityIds){
            this.queueHandler = queueHandler;
            this.onboardingData = queueHandler.onboardingData;
            this.pdfs = pdfs;
            this.entityIds = entityIds;
            
        }

        public void execute(QueueableContext context) {
            Boolean isSuccessful = execute_GetPDFandSaveAsFile(); //get pdf and safe as file, and then remove 1 item from the list.
            
            if (!this.pdfs.isEmpty()){
                //when there are more pdf to get, chain to another queue and do it again
                if(!Test.isRunningTest() && isSuccessful){
                    system.enqueueJob(new ServiceEventNDQApprove.queue_RecursiveGetPDFandSaveAsFile(this.queueHandler, this.pdfs, this.entityIds));    
                }
            } else {
                //NP-1886: update ‘Design Financial Approval’ onboarding task status to ‘Completed’
                //use a task variable to pass parameters into the queuable job. This allows us to extend the code if we add new custom fields for task 
                Task inputTask = new Task(
                    WhatId = this.onboardingData.onboardingCase.id,
                    RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
                    type = 'Design Financial Approval',
                    Status = 'Completed',
                    Entity_Attachment_Ids__c = String.join(this.entityIds, ';')
                );
                if(!Test.isRunningTest() && isSuccessful){
                    system.enqueueJob(new queue_UpdateTask(this.queueHandler, inputTask));//chain queuable job
                }
            }
        }
 
        public Boolean execute_GetPDFandSaveAsFile(){
            Boolean isSuccessful = true;
            if (!this.pdfs.isEmpty()){
                try{
                    ServiceEventNDWrapper.Pdf pdf = this.pdfs.remove(0);
                    if(!Test.isRunningTest()){
                        //MNTC-414 : Add error handling on GetPDFandSaveAsFile method when Get PDF HttpResponse return status code other than 200
                        MethodResponse res  = ServiceEventGeneratePDFCallout.GetPDFandSaveAsFile(pdf.pdfId, pdf.filename, pdf.pdfParentId);
                        this.entityIds.add(res.results.get('fileRecordId')); //even if the Get PDF HttpResponse return error, the recordId will be null
                        if(res.statuscode >= 400){
                            this.queueHandler.trackServiceEvent('Network Design - approve failed to execute_GetPDFandSaveAsFile(). ' + res.results.get('HttpResponse'), res.statuscode, this.onboardingData.onboardingCase.id);
                            isSuccessful = false;
                        }
                    }
                } catch (System.Exception e) {
                    this.queueHandler.trackServiceEvent(e, 400, this.onboardingData.onboardingCase.id);
                    isSuccessful = false;
                }    
            }
            return isSuccessful;
        }
    }

    //inner class - extends ServiceEventNDQ.queue_UpdateTask inner class for queuable job
    public class queue_UpdateTask extends ServiceEventNDQ.queue_UpdateTask {
        public queue_UpdateTask (ServiceEventNDQApprove queueHandler, Task input) {
            super(queueHandler, input);
        }
    }
}