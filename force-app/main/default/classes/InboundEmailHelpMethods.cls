public without sharing class InboundEmailHelpMethods {
	
	public static String getsubstringBetween(String body,String startS,string endS ){
     	
	 system.Debug('xxxx='+startS+'== ends=='+endS+'=='+body.substringBetween(starts,ends));
	 return  body.substringBetween(starts,ends)!=null ? body.substringBetween(starts,ends).trim() :'';
	 
	}
    
    public static String getsubstring(String body,String keyString ){
	 system.Debug('yyyyyyyy='+body.substring(body.indexOf(keyString)+keyString.length()));
	 return  body.substring(body.indexOf(keyString)+keyString.length())!=null ? body.substring(body.indexOf(keyString)+keyString.length()):'';
	}
	
	public static Case getTSOCase(String CaseNumber ){
	 system.Debug('TSO Case Number='+CaseNumber);
	 list<case> tso = [select CaseNumber,id, description,accountId,TCNZ_Work_Stream_Status__c,LFC_Truck_Roll_Scheduled_Date__c,IP_IDL_Update_Status__c,
LFC_Access_RFS_Date__c,CLNE_Truck_Roll_Scheduled_Date__c,CLNE_Installed_Date__c from Case where CaseNumber like: '%'+CaseNumber];
	if(tso!=null && tso.size()>0 ){
	system.debug('tso case id ='+tso.get(0).id);
	return tso.get(0);
	}
	else
	return null;
	
	}
	
	public static Device__c getDevice(string caseNumber){
	
	List<Device__c> dev = [SELECT id,Provision_Case__r.CaseNumber,TCNZ_IDA__c , (SELECT LAN_WAN__c, id FROM Ports__r where LAN_WAN__c=:'WAN' ) ,
	   (SELECT name, id FROM Customer_Firewall_Zones__r where name=:'INTERNET' or name=:'SERVICES')
       FROM Device__c where Provision_Case__r.CaseNumber like: '%'+caseNumber and recordtypeid=:SparkInboundEmail__c.getInstance('N4L Managed Router RecordType Id').value__c ];
	
	if(dev!=null && dev.size()>0 ){
	system.debug('dev id ='+dev.get(0).id);
	return dev.get(0); 
	}
	else
	return null;
	}
	@future
	public static void sendingEmail(string body,string attachmentbody){
	list<string> toaddressList = new list<string>();	
	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 	
	Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('emailfromspark.txt');
        efa.setBody(Blob.valueOf(attachmentbody));
    string address = SparkInboundEmail__c.getInstance('alert address').value__c;
    if (address.contains(',')) {
     for(string s:address.split(',')){
      if(s.contains('@'))
      toaddressList.add(s);
     
     }
    } 
    else
     toaddressList.add(address);
    //String[] toAddresses = new String[] {SparkInboundEmail__c.getInstance('alert address').value__c};  
    if(body.contains('after CLNE Installed with Service Configuration')) {
       email.setSubject('Attention Needed for inbound email from Spark - Billing related dates change received after CLNE Installed with Service Configuration' );
    }else{ 
    email.setSubject( 'Attention Needed for inbound email from Spark' );
    }
        email.setToAddresses( toaddressList );
        email.setPlainTextBody( body );
        email.setHtmlBody( body );
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
        // Sends the email
        Messaging.SendEmailResult [] r = 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
	}
	/**
	public static Date getDate(string dateString){
		list<String> info = new list<String>();
		info = dateString.split('/');
		if(info.size()==3 && info.get(0).isNumeric() && info.get(1).isNumeric() && info.get(2).isNumeric()){
		
		 return date.newInstance(integer.valueOf(info.get(2)),integer.valueOf(info.get(1)),integer.valueOf(info.get(0)));
		}else
		 return null;
	
	}
	**/
	public static DateTime getDateTime(string dateString){
		list<String> info = new list<String>();
		info = dateString.split('/');
		if(info.size()==3 && info.get(0).isNumeric() && info.get(1).isNumeric() && info.get(2).isNumeric()){
		
		 return datetime.newInstance(integer.valueOf(info.get(2)),integer.valueOf(info.get(1)),integer.valueOf(info.get(0)),17,0,0);
		}else
		 return null;
	
	}
}