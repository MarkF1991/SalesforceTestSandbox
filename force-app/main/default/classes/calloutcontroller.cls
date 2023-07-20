public without sharing class calloutcontroller {

public case calloutCase {get;set;}
public HttpResponse resForTesting;
public boolean isTest;
public boolean validation {get;set;}
public boolean isStatusOk {get;set;}
public boolean isExist {get;set;}
public boolean allGood {get;set;}
public boolean created {get;set;}
public boolean beforeSubmit {get;set;}
public list<string> missingFields {get;set;}
public string errorMessage{get;set;}
public string repMessage{get;set;}
public String getExistingRestrictedAccessDetails() {
        return Call_Out_Setting__c.getInstance('ExistingRestrictedAccessDetails').value__c;
    }
    /**
public String getIsFibreServiceExistAlready() {
         if(Call_Out_Setting__c.getInstance('IsReadRromRecord').value__c=='no')
        return Call_Out_Setting__c.getInstance('IsFibreServiceExistAlready').value__c;
        else{
        return calloutCase.Currently_Connected_To_A_Fibre_Service__c;
        }
    }
    **/
public String getPreferredInstallationTime() {
        return Call_Out_Setting__c.getInstance('PreferredInstallationTime').value__c;
    }
public String getstandardfirstname() {
        return Call_Out_Setting__c.getInstance('standard first name').value__c;
    }
public String getstandardlastname() {
        return Call_Out_Setting__c.getInstance('standard last name').value__c;
    }
public String getstandardmobilenumber() {
        return Call_Out_Setting__c.getInstance('standard mobile number').value__c;
    }
public String getstandardphonenumber() {
        return Call_Out_Setting__c.getInstance('standard phone number').value__c;
    }
public calloutcontroller(ApexPages.StandardController stdController){
 
 this.calloutCase = (case)stdController.getRecord();
 this.missingFields = new list<string>();
 this.isTest=false;
 }

 public PageReference checking()
    {
        allGood=true;
        validation=true;
        isExist=false;
        isStatusOk=true;
        beforeSubmit=true;
        if(calloutCase.New_Connection_Request_Order_ID__c!=null){
           isExist=true;
           allGood=false;
        }else if(calloutCase.TCNZ_Work_Stream_Status__c!='To Be Actioned'){
           isStatusOk=false;
           allGood=false;
        }else{
        
        
        
        if(calloutCase.Account.TCNZ_Common_Name__c==null) 
          missingFields.add('Case -> Account -> '+Schema.SobjectType.Account.fields.TCNZ_Common_Name__c.label);
        if(calloutCase.Account.MoE_School_ID__c==null) 
          missingFields.add('Case -> Account -> '+Schema.SobjectType.Account.fields.MoE_School_ID__c.label);
        if(calloutCase.Account.MoE_Site_ID_Lookup__r.name==null) 
          missingFields.add('Case -> Account -> MoE Site ID -> '+Schema.SobjectType.MoE_School_Site__c.fields.name.label);
        if(calloutCase.Account.Total_Users__c==null) 
          missingFields.add('Case -> Account -> '+Schema.SobjectType.Account.fields.Total_Users__c.label);
        if(calloutCase.CLNE_Installation_Building__c==null) 
          missingFields.add('Case -> '+Schema.SobjectType.Case.fields.CLNE_Installation_Building__c.label);
          
        if(calloutCase.CLNE_Installation_Room__c==null) 
          missingFields.add('Case -> '+Schema.SobjectType.Case.fields.CLNE_Installation_Room__c.label);
        if(calloutCase.CLNE_Installation_In_Room_Location__c==null) 
          missingFields.add('Case -> '+Schema.SobjectType.Case.fields.CLNE_Installation_In_Room_Location__c.label);
        if(calloutCase.X10m_Cable_Required__c==null) 
          missingFields.add('Case ->'+Schema.SobjectType.Case.fields.X10m_Cable_Required__c.label);
        if(calloutCase.CLNE_Adheres_School_Site__c==null) 
          missingFields.add('Case ->'+Schema.SobjectType.Case.fields.CLNE_Adheres_School_Site__c.label);
        if(calloutCase.Is_UPS_Available__c==null) 
          missingFields.add('Case ->'+Schema.SobjectType.Case.fields.Is_UPS_Available__c.label);
        if(calloutCase.Is_Restricted_Access__c==null) 
          missingFields.add('Case ->'+Schema.SobjectType.Case.fields.Is_Restricted_Access__c.label);
        if(calloutCase.Has_Environment_Risk__c==null) 
          missingFields.add('Case ->'+Schema.SobjectType.Case.fields.Has_Environment_Risk__c.label);
        if(calloutCase.Environment_Risk_Details__c==null && calloutCase.Has_Environment_Risk__c=='Yes') 
          missingFields.add('Case ->'+Schema.SobjectType.Case.fields.Environment_Risk_Details__c.label);
        if(calloutCase.Account.Managed_Network_Contract_Term__c==null) 
          missingFields.add('Case -> Account -> '+Schema.SobjectType.Account.fields.Managed_Network_Contract_Term__c.label);
        if(calloutCase.Account.School_Signed_Base_Connection__r.TCNZ_Standard_Service_Option__c==null) 
          missingFields.add('Case -> Account -> School Signed Base Connection -> '+Schema.SobjectType.Product2.fields.TCNZ_Standard_Service_Option__c.label);
        if(calloutCase.Account.Service_Level__c==null) 
          missingFields.add('Case -> Account -> '+Schema.SobjectType.Account.fields.Service_Level__c.label);
        if(calloutCase.Account.Street__c==null) 
          missingFields.add('Case -> Account -> '+Schema.SobjectType.Account.fields.Street__c.label);
        if(calloutCase.Account.Suburb__c==null) 
          missingFields.add('Case -> Account -> '+Schema.SobjectType.Account.fields.Suburb__c.label);
        if(calloutCase.Account.City__c==null) 
          missingFields.add('Case -> Account -> '+Schema.SobjectType.Account.fields.City__c.label);      
        if(calloutCase.Contact.FirstName==null) 
          missingFields.add('Case -> Contact -> '+Schema.SobjectType.Contact.fields.FirstName.label);
        if(calloutCase.Contact.LastName==null) 
          missingFields.add('Case -> Contact -> '+Schema.SobjectType.Contact.fields.LastName.label);
        if(calloutCase.Contact.Phone==null && calloutCase.Contact.MobilePhone==null) {
          missingFields.add('Case -> Contact -> '+Schema.SobjectType.Contact.fields.Phone.label);
          missingFields.add('Case -> Contact -> '+Schema.SobjectType.Contact.fields.MobilePhone.label);
        }
        if(calloutCase.Contact.Email==null) 
          missingFields.add('Case -> Contact -> '+Schema.SobjectType.Contact.fields.Email.label);      
        
        if(calloutCase.Secondary_Contact__r.FirstName==null) 
          missingFields.add('Case -> Secondary Contact -> '+Schema.SobjectType.Contact.fields.FirstName.label);
        if(calloutCase.Secondary_Contact__r.LastName==null) 
          missingFields.add('Case -> Secondary Contact -> '+Schema.SobjectType.Contact.fields.LastName.label);
        if(calloutCase.Secondary_Contact__r.Phone==null && calloutCase.Secondary_Contact__r.MobilePhone==null) {
          missingFields.add('Case -> Secondary Contact -> '+Schema.SobjectType.Contact.fields.Phone.label);
          missingFields.add('Case -> Secondary Contact -> '+Schema.SobjectType.Contact.fields.MobilePhone.label);
        }
        if(calloutCase.Secondary_Contact__r.Email==null) 
          missingFields.add('Case -> Secondary Contact -> '+Schema.SobjectType.Contact.fields.Email.label); 
        if(calloutCase.Web_Filtering_Administrator_Username__c==null) 
          missingFields.add('Case -> '+Schema.SobjectType.Case.fields.Web_Filtering_Administrator_Username__c.label); 
        
        
        
        
        
        
        
        if(missingFields.size()>0){
          validation=false;  
          allGood=false;
          //errorMessage = geterrorMessage(missingFields);  
          //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,errorMessage));
          //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'the below fields can not be blank:'));
           for(integer i=0;i<missingFields.size();i++){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,missingFields.get(i)));
         }
          
           
        }
        }
        return null;
    }   

public PageReference postRequest() {
        list<Attachment> atts = new list<Attachment>();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        req.setEndpoint(Call_Out_Setting__c.getInstance('post end point').value__c);
        req.setMethod('POST');
        string postXML = CallOutHelpMethods.getPostXML(this.calloutCase);
        
     String username = Call_Out_Setting__c.getInstance('username').value__c;
     String password = Call_Out_Setting__c.getInstance('password').value__c;
     Blob headerValue = Blob.valueOf(username + ':' + password);
     String authorizationHeader = 'BASIC ' +
     EncodingUtil.base64Encode(headerValue);
     req.setHeader('Authorization', authorizationHeader);
     //req.setHeader('Content-Type', 'application/xml;text/html;text/xml;charset=utf-8');
     req.setHeader('Content-Type', 'application/xml');
     req.setTimeout(120000);
     req.setHeader('Connection','keep-alive');
     req.setHeader('Accept', 'application/xml;text/html;text/xml; charset=UTF-8');  
     req.setBody(postXML); 
       
     //////////////////////////////////////////////// 
        try {
            beforeSubmit=false;
            if(isTest){
            res = resForTesting;
            }else{
            res = http.send(req);
            }
            
            System.debug('respons body:'+res.getBody());
            System.debug('STATUS:'+res.getStatus());
            System.debug('STATUS_CODE:'+res.getStatusCode());
            string response = res.getBody();
            if(res.getStatusCode()==201){
               created = true;   
               calloutCase.New_Connection_Request_Order_ID__c = response.substringBetween('<OrderId>','</OrderId>').trim();
               calloutCase.TCNZ_Work_Order_Submitted_Date__c = datetime.now();
                update calloutCase;
               Attachment requestXML = new Attachment(); //Make an attachment
               requestXML.Name ='New Connection Post Request.xml';  
               requestXML.Body = Blob.valueOf(postXML);
               requestXML.ContentType= 'application/xml'; //Signal what the file's MIME type is
               requestXML.ParentID = this.calloutCase.Id;
               atts.add(requestXML);
               Attachment responseXML = new Attachment(); //Make an attachment
               responseXML.Name ='New Connection Post Response.xml';  
               responseXML.Body = Blob.valueOf(response);
               responseXML.ContentType= 'application/xml'; //Signal what the file's MIME type is
               responseXML.ParentID = this.calloutCase.Id;
               atts.add(responseXML);
               insert atts;
            }else{
               created = false;
               repMessage = response;
               Attachment requestXML = new Attachment(); //Make an attachment
               requestXML.Name ='Failed New Connection Post Request.xml';  
               requestXML.Body = Blob.valueOf(postXML);
               requestXML.ContentType= 'application/xml'; //Signal what the file's MIME type is
               requestXML.ParentID = this.calloutCase.Id;
               atts.add(requestXML);
               Attachment responseXML = new Attachment(); //Make an attachment
               responseXML.Name ='Failed New Connection Post Response.xml';  
               responseXML.Body = Blob.valueOf(response);
               responseXML.ContentType= 'application/xml'; //Signal what the file's MIME type is
               responseXML.ParentID = this.calloutCase.Id;
               atts.add(responseXML);
               insert atts;
            
            }
        
            } catch(System.CalloutException e) {
              created = false;  
              System.debug('Callout error: '+ e.getMessage());
              System.debug('error response==='+res.toString());
            }
          return null;
    }

}