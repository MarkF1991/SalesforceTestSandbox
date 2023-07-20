/** created by n4lsalesforce@gmail.com on 17/05/2020
 *  receive email notifications from n4l internal platform.
 *  store latest email content into "Last_Usage_Alert_Email_Content__c" under student household object.
 *  create a chatter post.
**/
public class FarmsideApexRestHelper {
    /** sendEmail method no longer needed.keep method here for future debug purpose.
    public static void sendEmail(String JsonBody){
        Blob body = Blob.valueOf('Daily Farmside Update');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{'n4lsalesforce@gmail.com'}); 
        mail.setSubject('Farmside Daily Update '+ date.today());
        mail.setPlainTextBody('Farmside Daily Update '+ date.today());
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType('text/plain');
        attach.setFileName('farmsideJson.txt');  
        attach.Body = blob.valueOf(JsonBody);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
    }
    **/ 
       // json validater 
       public static boolean isJsonValid(String JsoneString){
          try{
              FarmsideEmailWrapper wrpper = (FarmsideEmailWrapper) JSON.deserialize(JsoneString,FarmsideEmailWrapper.class);
              return true;
             }catch(Exception e){
              return false;
             }
       }
    // createErrorFile method will drop request body into folder "FarmSide Errors" as a text file.
   @future    
        public static void createErrorFile(String JsoneString){
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S';
            conVer.PathOnClient = 'FarmsideErrorJson'+String.ValueOf(date.today())+'.txt'; 
            conVer.Title = 'FarmsideError Json File'+String.ValueOf(date.today()); 
            conVer.VersionData = Blob.valueOf(JsoneString);
            insert conVer;    
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            ContentWorkspace ws = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name = 'FarmSide Errors' LIMIT 1];
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = conDoc;
            cdl.ShareType = 'I';
            cdl.Visibility = 'AllUsers';
            cdl.LinkedEntityId = ws.Id; 
            insert cdl;
       }

    // query existing record by key "RSP_Customer_No" then save email content into Last_Usage_Alert_Email_Content__c.
    @future
    public static void updateRecord(String JsonBody){
        
        FarmsideEmailWrapper wrpper = new FarmsideEmailWrapper();
        map<string,FarmsideEmailWrapper.Email_alerts>  jsonMap = new map<string,FarmsideEmailWrapper.Email_alerts>();
        map<string,Student_House_Hold__c> studentMap = new map<string,Student_House_Hold__c>();
        list<FeedItem> postlist = new list<FeedItem>();
        try{
            JsonBody= JsonBody.replaceAll('\n','').replaceAll('\r','');
            wrpper = (FarmsideEmailWrapper) JSON.deserialize(JsonBody,FarmsideEmailWrapper.class);
            system.debug(wrpper.email_alerts.size()); 
        }catch(Exception e){
         system.debug('Deserialize Error:'+e.getMessage());  
         //sendEmail('Deserialize Error:');   
        }
        if(wrpper.email_alerts.size()>0){
           for(FarmsideEmailWrapper.Email_alerts fwe :wrpper.email_alerts){
                jsonMap.put(fwe.RSP_Customer_No,fwe);
            } 
        }
        if(jsonMap.size()>0){
            for( Student_House_Hold__c shh :[select id,name,Last_Usage_Alert_Email_Date_Time__c,
                                             Alert_Email_Type__c,Last_Usage_Alert_Email_Content__c,RSP_Customer_No__c 
                                             from Student_House_Hold__c where RSP_Customer_No__c in : jsonMap.keyset()]){
                 shh.Last_Usage_Alert_Email_Content__c = 'Email Sent to: '+jsonMap.get(shh.RSP_Customer_No__c).Email_Sent_to +'\n'+jsonMap.get(shh.RSP_Customer_No__c).Last_Usage_Alert_Email_Content;
                 shh.Alert_Email_Type__c = jsonMap.get(shh.RSP_Customer_No__c).Alert_Email_Type;
                 shh.Last_Usage_Alert_Email_Date_Time__c = DateTime.valueOf(jsonMap.get(shh.RSP_Customer_No__c).Last_Usage_Alert_Email_Date_Time);                                
                 FeedItem post = new FeedItem();
                 post.ParentId = shh.Id; 
                 post.Body = '#FarmsideAlertEmail\n'+ 'Email Sent to: '+jsonMap.get(shh.RSP_Customer_No__c).Email_Sent_to +'\n'+ shh.Last_Usage_Alert_Email_Content__c;
                 post.title = '#FarmsideAlertEmail';                                
                 studentMap.put(shh.RSP_Customer_No__c,shh); 
                 postlist.add(post);                                
            }
        }
        if(studentMap.size()>0){
            system.debug('student size:'+studentMap.values().size());  
            update studentMap.values();
            insert postlist;
        }
    }
}