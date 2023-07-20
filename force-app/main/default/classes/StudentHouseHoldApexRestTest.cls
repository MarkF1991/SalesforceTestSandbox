/** created by n4lsalesforce@gmail.com on 7/7/2020
 *  test calss for both StudentHouseHoldApexRestHelper and StudentHouseHoldApexRest.
**/
@isTest
private class StudentHouseHoldApexRestTest {
    static testMethod void happypathtest(){
        String json = 
                 '['+
				    '{'+
                       '         \"Name\":\"insert-test001\",'+
                       '         \"RSP__c\":\"4b604188\",'+
                       '         \"RSP_Customer_No__c\":\"test001\",'+
					   '         \"GPS_co_ordinates__c\":null,'+
					   '         \"Street_Address__c\":\"1 Ocean View Road\",'+
					   '         \"Suburb__c\":\"Albany\",'+
					   '         \"City__c\":\"Auckland\",'+
					   '         \"Postcode__c\":\"0678\",'+
					   '         \"Student_School__c\":\"moetest01\"'+
                       '        }'+
                       '    ]';
        account testacc = new account();
        testacc.name = 'testaccname';
        testacc.MoE_School_ID__c = 'moetest01';
        testacc.uuid__c ='4b604188';
        insert testacc;
        Student_House_Hold__c testshh = new Student_House_Hold__c();
        testshh.name = 'testshhname';
        testshh.RSP__c = testacc.id; 
        testshh.Street_Address__c ='testaddress';
        testshh.City__c ='testcity';
        testshh.RSP_Customer_No__c ='test001';
        insert testshh;
         RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/welcome-calls';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        RestContext.request = request;
		system.Test.startTest();
        StudentHouseHoldApexRest.doPost();
        system.Test.stopTest();
    }
    
    static testMethod void JsonErrortest(){
        String json = 
                 '['+
				    '{'+
                       '         \"Name\":\"insert-test001\",'+
                       '         \"RSP__c\":\"4b604188\",'+
                       '         \"RSP_Customer_No__c\":\"test001\",'+
					   '         \"GPS_co_ordinates__c\":null,'+
					   '         \"Street_Address__c\":\"1 Ocean View Road\",'+
					   '         \"Suburb__c\":\"Albany\",'+
					   '         \"City__c\":\"Auckland\",'+
					   '         \"Postcode__c\":\"0678\",'+
					   '         \"Student_School__c\":\"moetest01\"'+
                       '        },'+
                       '    ]';
        account testacc = new account();
        testacc.name = 'testaccname';
        testacc.MoE_School_ID__c = 'moetest01';
        testacc.uuid__c ='4b604188';
        insert testacc;
        Student_House_Hold__c testshh = new Student_House_Hold__c();
        testshh.name = 'testshhname';
        testshh.RSP__c = testacc.id; 
        testshh.Street_Address__c ='testaddress';
        testshh.City__c ='testcity';
        testshh.RSP_Customer_No__c ='test001';
        insert testshh;
         RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/welcome-calls';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        RestContext.request = request;
		system.Test.startTest();
        StudentHouseHoldApexRest.doPost();
        system.Test.stopTest();
    }
       
    static testMethod void upsertErrortest(){
        String json = 
                 '['+
				    '{'+
                       '         \"Name\":\"insert-test001\",'+
                       '         \"RSP__c\":\"4b604188\",'+
                       '         \"RSP_Customer_No__c\":\"test001\",'+
					   '         \"GPS_co_ordinates__c\":null,'+
					   '         \"Street_Address__c\":\"1 Ocean View Road\",'+
					   '         \"Suburb__c\":\"Albany\",'+
					   '         \"City__c\":\"Auckland\",'+
					   '         \"Postcode__c\":\"0678\",'+
					   '         \"Student_School__c\":\"moetest01\"'+
                      '        },'+
                       '        {'+
					   '         \"Name\":\"insert-test002\",'+
                       '         \"RSP__c\":\"4b604188\",'+
                       '         \"RSP_Customer_No__c\":\"test001\",'+
					   '         \"GPS_co_ordinates__c\":{'+
					   '         \"latitude\":\"-45.0\",'+ 
					   '         \"longitude\":\"45.0\"'+ 
					   '        },'+
					   '         \"Street_Address__c\":\"length over 80 address test length over 80 address test length over 80 address test length over 80 address test length over 80 address test length over 80 address test\",'+
					   '         \"Suburb__c\":\"Albany\",'+
					   '         \"City__c\":\"Auckland\",'+
					   '         \"Postcode__c\":\"0678\",'+
					   '         \"Student_School__c\":\"moetest01\"'+
                       '        }'+
					   '    ]';
        account testacc = new account();
        testacc.name = 'testaccname';
        testacc.MoE_School_ID__c = 'moetest01';
        testacc.uuid__c ='4b604188';
        insert testacc;
        Student_House_Hold__c testshh = new Student_House_Hold__c();
        testshh.name = 'testshhname';
        testshh.RSP__c = testacc.id; 
        testshh.Street_Address__c ='testaddress';
        testshh.City__c ='testcity';
        testshh.RSP_Customer_No__c ='test001';
        insert testshh;
         RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/welcome-calls';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        RestContext.request = request;
		system.Test.startTest();
        StudentHouseHoldApexRest.doPost();
        system.Test.stopTest();
    }
}