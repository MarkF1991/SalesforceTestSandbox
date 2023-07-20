public class TestClassUtility {

    //Reference - https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Schema_RecordTypeInfo.htm#apex_Schema_RecordTypeInfo_methods
    public static ID getRecordTypeId(Schema.DescribeSObjectResult descSObject, String recordTypeName){
        Map<String,Schema.RecordTypeInfo> rtMapByName = descSObject.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtInfo =  rtMapByName.get(recordTypeName);
        return rtInfo.getRecordTypeId();
    }

    public static Account createAccount(String accName, String recordTypeName){
		Account newAccount = new account(
            Name = accName ,
            RecordTypeId = getRecordTypeId(Schema.SObjectType.Account, recordTypeName),
            Phone = '021 123 456',
            Fax = '09 134 4567'
		);
		return newAccount;
	}

    public static Account createAccountWithUUID(String accName, String recordTypeName, String uuid){
        Account newAccount = createAccount(accName, recordTypeName);
        newAccount.uuid__c = uuid;
		return newAccount;
	}
    

    public static Contact createContact(Id accountId, String fName, String lName, String email, String phone, String businessRole, boolean IsCurrentPrincipal){
	//2021-02-19 Deloitte has removed the dysfunctional Record Type 'Business Contact (Role Based)', now use 'Default'
        Contact contact = new contact(
				AccountId = accountId,
				FirstName = fName,
				LastName = lName,
				Email = email,
				RecordTypeId = getRecordTypeId(Schema.SObjectType.Contact, 'Default'),
				Phone = phone,
                Business_Role__c = businessRole,
                Current_Principal_Of_This_School__c = IsCurrentPrincipal
		);
		return contact;
	}
    //create Non School contact
    //2021-02-19 Deloitte has removed the dysfunctional Record Type 'Non School', now use 'Default'
    public static Contact createContact(Id accountId, String fName, String lName, String email, String phone){
		Contact contact = new contact(
				AccountId = accountId,
				FirstName = fName,
				LastName = lName,
				Email = email,
				RecordTypeId = getRecordTypeId(Schema.SObjectType.Contact, 'Default'),
				Phone = phone
		);
		return contact;
	}

    //create Basic contact info
    public static Contact createContactBasic(Id accountId, String fName, String lName, String email, String phone){
        Contact contact = new contact(
                AccountId = accountId,
                FirstName = fName,
                LastName = lName,
                Email = email,
                Phone = phone
        );
        return contact;
    }    
    
    //create system admin profile
    // 2021-03-03 Deloitte has added method for admin user creation
    public static User createAdminUser(String lastName,String email){
        
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User adminUser = new User();
        adminUser.ProfileId = adminProfile.id;
        adminUser.Alias = 'standt';
        adminUser.Email= email;
        adminUser.UserName = email + System.currentTimeMillis();
        adminUser.EmailEncodingKey='UTF-8';
        adminUser.LastName=lastname;
        adminUser.LanguageLocaleKey='en_US';
        adminUser.LocaleSidKey='en_US';
        adminUser.department = 'STP';
        adminUser.TimeZoneSidKey='America/Los_Angeles';
        
        return adminUser;
    }

    //create user role for community
    // 2021-03-03 Deloitte has added method for user role cration
    public static UserRole createUserRole(String roleName) {
        UserRole userRole = new UserRole(Name = roleName);
        return userRole;
    }

    public static User createInternalUser(){
		Profile profileObj = [SELECT id, Name FROM Profile WHERE Name = 'N4L Customer Acquisitions User'];
		User newUser = new User(
				profileId = profileObj.id,
				username = 'internaluser@invalid-domain.com',
				email = 'internaluser@invalid-domain.com',
				emailencodingkey = 'UTF-8',
				localesidkey = 'en_US',
				languagelocalekey = 'en_US',
				timezonesidkey = 'Pacific/Auckland',
				alias = 'iuser',
				firstname = 'Internal',
				lastname = 'User'
		);
		return newUser;
	}

	public static User createInternalUser(string firstName, string LastName){
		Profile profileObj = [SELECT id, Name FROM Profile WHERE Name = 'N4L Customer Acquisitions User'];
		User newUser = new User(
				profileId = profileObj.id,
				username = firstName + lastName + '@test.com',
				email = firstName + lastName + '@test.com',
				emailencodingkey = 'UTF-8',
				localesidkey = 'en_US',
				languagelocalekey = 'en_US',
				timezonesidkey = 'Pacific/Auckland',
				alias = firstName.left(1) + lastName.left(5),
				firstname = firstName,
				lastname = lastName
		);
		return newUser;
	}

    public static User createExternalUser(Contact contact){
        Profile profileObj = [SELECT id, Name FROM Profile WHERE Name = 'Support Hub Community Member User - Login Licence MFA'];

		User newUser = new User(
				profileId = profileObj.id,
				username = contact.Email+'.sandbox', //'newuser@test.com',
				email = contact.Email, //'newuser@test.com',
				emailencodingkey = 'UTF-8',
				localesidkey = 'en_US',
				languagelocalekey = 'en_US',
				timezonesidkey = 'Pacific/Auckland',
				alias = 'nuser',
				contactId = contact.Id, //; first error: INVALID_CROSS_REFERENCE_KEY, Cannot create a portal user without contact: [ContactId]
				//accountId = contact.AccountId, //commented out: portal user automatically has accountId of contact.
				firstname = contact.FirstName,
                lastname = contact.LastName//,
                //userroleId = [Select Id From UserRole Where PortalType = 'None' Limit 1].Id  //was added by Deloitte sometime in Jun 2020, but commented out by Ben Soh 23/07/2020: System.DmlException: Insert failed. First exception on row 0; first error: FIELD_INTEGRITY_EXCEPTION, High Volume Portal Users cannot have a user role: [UserRoleId]
		);
		return newUser;
	}
    
	public static User createPowerCustomerSuccessUser(Contact contact){
		Profile profileObj = [SELECT id, Name FROM Profile WHERE Name = 'Support Hub ICT Provider Admin User']; //ProfileId = '00e90000002B64YAAS'
		User newUser = new User(
				profileId = profileObj.id,
				username = contact.Email, //'PowerCustomerSuccessUser@test.com',
				email = contact.Email, //'PowerCustomerSuccessUser@test.com',
				emailencodingkey = 'UTF-8',
				localesidkey = 'en_US',
				languagelocalekey = 'en_US',
				timezonesidkey = 'Pacific/Auckland',
				alias = 'pcsuser',
				contactId = contact.Id, //; first error: INVALID_CROSS_REFERENCE_KEY, Cannot create a portal user without contact: [ContactId]
				//accountId = contact.AccountId, //commented out: portal user automatically has accountId of contact.
				firstname = contact.FirstName,
				lastname = contact.LastName
		);
		return newUser;
	}

public static string generateJSONfromMap(Map<string, string> claims){
	JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        if (claims != null) {
            for (String claim : claims.keySet()) {
                body.writeObjectField(claim, claims.get(claim));//Writes a field name and value pair using the specified field name and Apex object.
            }
        }
        body.writeEndObject();
				return body.tostring();
}

public static Campaign createCampaign(String name, string programme, string product, String type, String status, String recordTypeName){
	//product: Filtering Portal; Identity Awareness; School Reporting
	//type: Onboarding; Email; Other
	//status: Planned; In Progress; Completed; Aborted
	Campaign campaign = new Campaign(
				IsActive = true,
				Name = name,
				Programme__c = programme,
				Product__c = product,
				Type = type,
				Status = status,
				CampaignMemberRecordTypeId = getRecordTypeId(Schema.SObjectType.CampaignMember, 'Generic Campaign Member'),
				RecordTypeId = getRecordTypeId(Schema.SObjectType.Campaign, recordTypeName)//'Generic Campaign'
		);
		return campaign;
}

public static Campaign_Account__c createCampaignAccount(Campaign campaign, Account account){
	Campaign_Account__c campaignAccount = new Campaign_Account__c(
        Campaign__c = campaign.id,
        Account__c = account.id
		);
		return campaignAccount;
}

//campaign Account Contact
public static Campaign_Account_Contact__c createCampaignAccountContact(Campaign campaign, Contact contact, Campaign_Account__c campaignAccount){
	Campaign_Account_Contact__c campaignAccountContact = new Campaign_Account_Contact__c(
        Campaign__c = campaign.id,
        Contact__c = contact.id,
        Campaign_Account__c = campaignAccount.id
		);
		return campaignAccountContact;
}

public static Opportunity createOpportunity(Account account, Campaign campaign, Date closeDate, String type, String stageName, String recordTypeName  ){
	Opportunity opportunity = new Opportunity(
			Name = (account.Name + ' - ' + campaign.name),
			AccountId = account.id,
			CampaignId = campaign.id,
			CloseDate = closeDate,
			StageName = stageName, //New
			Type = type, //Onboarding
			RecordTypeId = getRecordTypeId(Schema.SObjectType.Opportunity, recordTypeName)
	);
	return opportunity;
}

public static OpportunityContactRole createOpportunityContactRole(Contact contact, Opportunity opportunity, String role){
	OpportunityContactRole opportunityContactRole = new OpportunityContactRole(
		ContactId = contact.Id, 
		OpportunityId = opportunity.Id, 
		Role = role
	);
	return opportunityContactRole;
}



public static Contract createContract(Account account, String programme, Contact customerContact, String recordTypeName  ){
	Contract contract = new Contract(
			Name = (account.Name + ' - ' + programme),
			Programme__c = programme,
			AccountId = account.id,
			CustomerSignedId  = customerContact.id,
			StartDate = Date.Today(),
			Status = 'Draft',
			Contract_Type__c = 'Master',
			RecordTypeId = getRecordTypeId(Schema.SObjectType.Contract, recordTypeName)
	);
	return contract;
}

	public static ConfigAutoRecord__c createConfigAutoRecord(String name, String programme, String product, String ProductVariation, String type, String sobjectType, String caseOwnerQueue){
		//programme: Network Hardware Replacement, Network Support Extension
		//product: Managed Network Extension, Managed Network To The Classroom
		//type: Onboarding
		//sObjectType: 'Case;Task;Contract;'
		ConfigAutoRecord__c configAutoRecord = new ConfigAutoRecord__c(
					Name = name,
					Programme__c = programme,
					Product__c = product,
                    Product_variation__c = ProductVariation,
					Type__c = type,
					SObjectType__c = sobjectType,
                    Case_Owner_Queue__c = caseOwnerQueue
			);
			return configAutoRecord;
	}

	public static TaskTemplate__c createTaskTemplate(Id configAutoRecordId, String type, String status, String sequence, String recordTypeName, String owner){
		//type: Design, Quoted...
		//status: Not Started, In Progress
		//sequence: 010, 011 or 01, 02
		//recordTypeName: Onboarding
		TaskTemplate__c taskTemplate = new TaskTemplate__c(
				ConfigAutoRecord__c = configAutoRecordId,
				RecordTypeName__c = recordTypeName,
				Sequence__c = sequence,
				Status__c = status,
				Type__c = type,
				Owner__c = owner
			);
		return taskTemplate;
	}

    public static TaskTemplateAction__c createTaskTemplateAction(Id sourceTaskTemplateId, Id targetTaskTemplateId, String onStatusChanged, String changeStatusTo, String emailTemplateName, String erLiteEmailTemplateName, String sendEmailFrom, String sendEmailTo, String sendEmailCc, String name, String SearchKeyWord){	
		// SourceTaskTemplate__c: TaskTemplate id of the task that has Status Changed with this TaskTemplate 	
		// OnStatusChanged__c : Completed, 	
		// TargetTaskTemplate__c : TaskTemplate id of targeted task with this TaskTemplate	
		// ChangeStatusTo__c : In Progress, 	
			
		TaskTemplateAction__c taskTemplateAction = new TaskTemplateAction__c(	
			SourceTaskTemplate__c = sourceTaskTemplateId, 	
			OnStatusChanged__c = onStatusChanged, 	
			ChangeStatusTo__c = changeStatusTo, 	
			TargetTaskTemplate__c = targetTaskTemplateId,	
            EmailTemplateName__c = emailTemplateName,
            ER_Lite_EmailTemplateName__c = erLiteEmailTemplateName,
            SendEmailFrom__c = sendEmailFrom, 	
            SendEmailTo__c = sendEmailTo,	
            SendEmailCc__c = sendEmailCc, 	
            Name = name,
            SearchKeyWord__c = SearchKeyWord
            	
            	
			);	
		return taskTemplateAction;	
	}
    
    /**
    * 	@author Ben Soh
    *	@description create Product and Product Bundle
    **/
    public static Product2 createProduct(String name, String productCode, String stockKeepingUnit, String description, String family, String productType, String quantityUnitOfMeasure, String recordTypeName){
        Product2 product = new Product2(
            Name = name,
            ProductCode = productCode,
            StockKeepingUnit = stockKeepingUnit,
            Description = description,
            Family = family,
            QuantityUnitOfMeasure = quantityUnitOfMeasure,
            RecordTypeId = getRecordTypeId(Schema.SObjectType.Product2, recordTypeName)       
        );  
        product.Warranty_Term_Months__c = (product.Family == 'Equipment'? 12 : 0); //to prevent validation error FIELD_CUSTOM_VALIDATION_EXCEPTION, Warranty term field cannot be blank.: [Warranty_Term_Months__c]
        return product;
    }
    
    public static ProductBundle__c createProductBundle(Id equipmentProductId, String Family, Id requiresProductId){
        ProductBundle__c productBundle = new ProductBundle__c(
            EquipmentProduct__c = equipmentProductId, 
            Family__c = Family, 
            RequiresProduct__c = requiresProductId
        );
		return productBundle;
    }
    
    //TO DO: Post Xero Integration deployment Refactor - consider creating TestObjectFactoryOrder
	public static Order createOrderAndRelatedData() {

        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        insert schoolAccount;
        
        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
        Contact principalContact = new Contact();
        List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            //Contact principalContact = contacts[0];
            principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            update principalContact;
        } else {
            //create contacts in the school
            //Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
        
        
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'External ICT', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'External ICT', False));
        
        Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);
        
        newContacts.add(exPrincipalContact);
        insert newContacts;
        
        exPrincipalContact.Inactive_Contact_Record__c = true;
        update exPrincipalContact;
        
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser2 = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser2;
        
        //create contract
        Contract contract  = TestClassUtility.createContract(schoolAccount, Helper.getProgrammeNameMapping().get('NHR').Programme__c, principalContact, 'N4L Contract');
        insert contract;
        contract.Status = 'Activated';
        update contract;
        
        //create case
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola']; 
        
        String testEmail = 'email1@invalid-domain.com'; //to get principal contact
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];
        
        Case case1  = new Case(
            accountid = account.id,
            contactId = contact.id,
            subject = 'test case',
            Cutover_Appointment__c = DateTime.parse('11/3/2020 12:00 AM'),
            RecordTypeId = TestClassUtility.getRecordTypeId(Schema.SObjectType.Case, 'Onboarding')
        );
        insert case1;
        
        //create provider
        Account provider = TestClassUtility.createAccount('exeed',  'Non-School Organisation');
        insert provider;
        
        //create provider.contact
        Contact providerContact = TestClassUtility.createContact(provider.Id, 'FirstName6', 'LastName6', 'email6@invalid-domain.com', '027666666', 'ICT Leader', False);
        insert providerContact;
        
        //update provider's billing contact and address to show in order
        provider.Billing_Contact__c = providerContact.Id;
        provider.BillingStreet = '123 Beautiful Street';
        provider.BillingCity = 'Auckland';
        provider.BillingPostalCode = '1234';
        provider.BillingCountry = 'New Zealand';
        update provider;
        
        //create pricebook
        //List<Pricebook2> pricebooks = [SELECT id, Name FROM Pricebook2 WHERE Name = 'exeed' LIMIT 1];
        Pricebook2 pricebook = new Pricebook2(
            name = 'exeed',
            provider__c = provider.Id
        );
        insert pricebook;
        
        //create standard pricebook
        Id standardpricebookid = Test.getStandardPricebookId();
        
        
        //create product2
        List<Product2> products = new List<Product2>();
        Product2 product = new Product2(
            name = 'R650 Dual Band 11ax Indoor AP, 2/4 Stream',
            ProductCode = '901-R650-WW00',
            Description = 'To install a new 24 port Network Switch including mounting, labelling, all patching, testing and commissioning'
        );  
        insert product;
        
        //Create PricebookEntry
        List<PricebookEntry> pricebookEntries =  new List<PricebookEntry>();
        pricebookEntries.add(new PricebookEntry(
            Product2Id = product.Id,
            Pricebook2Id = standardpricebookid,
            UnitPrice = 10,
            BuyPrice__c = 12,
            isActive = true       
        ));
        
        pricebookEntries.add(new PricebookEntry(
            Product2Id = product.Id,
            Pricebook2Id = pricebook.Id,
            UnitPrice = 10,
            BuyPrice__c = 12,
            isActive = true
        ));
        
        
        insert pricebookEntries;
        
        //create Order
        Order order = new Order();
        order.AccountId = schoolAccount.Id;
        order.Case__c = case1.id;
        order.Status = 'Draft';
        order.PoDate = date.today();
        order.EffectiveDate = date.today();
        order.PoNumber = 'PO123123';
        order.Provider__c = provider.Id;
        order.Pricebook2Id = pricebook.Id;
        order.ContractId = contract.Id;
        order.ShippingCountry = 'New Zealand';
        order.ShippingCity = 'Auckland';
        order.ShippingStreet = '123 Queen Street';
        order.ShippingPostalCode = '0622';
        order.CompanyAuthorizedById = UserInfo.getUserId();
        order.Type = 'SOW - Installer';
        Insert order;
        
        
        List<OrderItem> orderItems = new List<OrderItem>();
        List<PricebookEntry> entries = [SELECT Id,Pricebook2Id,Product2Id FROM pricebookentry WHERE Pricebook2Id =: pricebook.Id];          
        For(PricebookEntry entry : entries){
            orderItems.add(new OrderItem(
                OrderId = order.Id,
                Quantity = 10,
                UnitPrice = 12,
                Discount__c = 0,
                PricebookEntryid = entries[0].id
            ));
        }
        Insert orderItems;
        
        return order;
    }

    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Generate the Mock instance from named Static Resource
    **/
    public static StaticResourceCalloutMock setStaticMock (String mockName) {

        return setStaticMock(200, mockName);
    }
   
    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Generate the Mock instance from named Static Resource
    **/
    public static StaticResourceCalloutMock setStaticMock (Integer responseCode, String mockName) {

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(mockName);
        mock.setStatusCode(responseCode);
        mock.setHeader('Content-Type', 'application/json');
        return mock;
    }

    /**
    * 	@author Ben Edwards (beedwards@deloitte.co.nz)
    *	@description Generate the Mock instance from named Static Resource
    **/
    public static MultiStaticResourceCalloutMock setMultiStaticMock (Map<String, String> endpointToMockName) {

        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');

        // Set a Mockf or each endpoint
        for (String endpoint :endpointToMockName.keySet()) {

            multimock.setStaticResource(endpoint, endpointToMockName.get(endpoint));
        }

        return multimock;
    }

}