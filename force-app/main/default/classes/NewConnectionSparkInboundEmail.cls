/**
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 */
global class NewConnectionSparkInboundEmail implements Messaging.InboundEmailHandler {
    
    global String caseNumber = '';
    global String internetIDLNumber = '';
    global String serviceIDLNumber = '';
    global String internetVLANIP = '';
    global String serviceVLANIP = '';
    global String internetVLANNextHotIP = '';
    global String serviceVLANNextHotIP = '';
    global String circuitIDANumber = '';
    global String errorInfo = '';
    global String IDLs = '';
    global String LFCAccessRFSDate = '';
    global String LFCStatus = '';
    global String CLNETruckrollScheduledDate = '';
    global String CLNEInstalledDate = '';
    
    //global id accountId = '';
    global id deviceId ;
    global id portId ;
    global id internetFirewallId ;
    global id serviceFirewallId ;
    global Case TSOCase;
    global Device__c dev;
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        system.Debug('Email body+++++='+email.plainTextBody);	
        if(email.plainTextBody.contains('<Circuit IDA Number>') || email.plainTextBody.contains('<Internet; Service IDL Number>'))//New Connection IPs & IDLs update 
        {
           caseNumber = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<N4L TSO Case#>:','<Internet; Service IDL Number>');
           IDLs= InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<Internet; Service IDL Number>:','<Circuit IDA Number>').trim();
           if(IDLs!=''){
           list<string> IDLlist=IDLs.splitByCharacterTypeCamelCase();
           for(string s:IDLlist){
           if(internetIDLNumber=='' && s.isNumeric()){
              internetIDLNumber=s;
              continue;
           }
           if(serviceIDLNumber=='' && s.isNumeric()){
              serviceIDLNumber=s;
              break;
           }
           }
           
           }
           //internetIDLNumber = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<Internet; Service IDL Number>:','<Circuit IDA Number>').substringBefore(';').trim();
           //serviceIDLNumber  = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<Internet; Service IDL Number>:','<Circuit IDA Number>').substringafter(';').trim();
           System.debug('eeeeeeeee='+internetIDLNumber+'eeeeeeeeeee='+serviceIDLNumber);
           internetVLANIP = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<Internet VLAN IP Address>:','<Internet VLAN Next Hop IP>');
           serviceVLANIP = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<Service VLAN IP Address>:','<Service VLAN Next Hop IP>');
           internetVLANNextHotIP = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<Internet VLAN Next Hop IP>:','<Service VLAN IP Address>');
           serviceVLANNextHotIP = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<Service VLAN Next Hop IP>:','<END>');
           circuitIDANumber = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<Circuit IDA Number>:','<Internet VLAN IP Address>:');
        
           if(caseNumber!=''){
         TSOCase = InboundEmailHelpMethods.getTSOCase(caseNumber);
         
         if(TSOCase!=null){
         	    boolean updated = false;
                system.debug('My debug 4 :'+TSOCase.id);
                dev=InboundEmailHelpMethods.getDevice(caseNumber);
                if(dev!=null){
                if(circuitIDANumber!=''){
                dev.TCNZ_IDA__c = circuitIDANumber;
                  try{
                update dev;
                
                }catch (DMLException e)
                {
            System.debug('update failed : ' + e.getmessage());
                }
                }	
                
                deviceId=dev.id;
                  if(dev.Ports__r!=null && dev.Ports__r.size()>0){
                    portId=dev.Ports__r.get(0).id;
                  system.debug('dev.Ports__r size='+dev.Ports__r.size()); 	
                  }else{
          
                         errorInfo  = errorInfo +'</b> Can not find device port.';
                       }     
                  if(dev.Customer_Firewall_Zones__r!=null && dev.Customer_Firewall_Zones__r.size()>0){
                    system.debug('Firewall_Zone size='+dev.Customer_Firewall_Zones__r.size()); 	
                    for(Customer_Firewall_Zone__c fz:dev.Customer_Firewall_Zones__r){
                        if(fz.name=='INTERNET' && internetFirewallId==null){
                        internetFirewallId=fz.id;
                        system.debug('INTERNET ID='+internetFirewallId);
                        }
                        if(fz.name=='SERVICES' && serviceFirewallId==null){
                        serviceFirewallId=fz.id;
                        system.debug('SERVICES ID='+serviceFirewallId);
                        }
                    }
                    
                  }else{
          
                         errorInfo  = errorInfo +'</b> Can not find firewall zones.';
                       } 
                
                if(internetVLANIP !='') {
         list<IP_Subnet__c> oldipis = [select id,Customer__c,Assigned_Device__c,Assigned_Port__c,Default_Gateway__c,Firewall_Zone__c,name,TCNZ_IDL__c,VRF__c from IP_Subnet__c where Assigned_Device__c=:deviceId and VRF__c=:SparkInboundEmail__c.getInstance('VRF Internet Id').value__c ];
         IP_Subnet__c ipi = new IP_Subnet__c();
         if (oldipis!=null && oldipis.size()>0){
         ipi.id=oldipis.get(0).id;
         }
         ipi.Customer__c=TSOCase.accountid;
         ipi.Assigned_Device__c=dev.id;
         ipi.Assigned_Port__c=portId;
         ipi.Default_Gateway__c=internetVLANNextHotIP;
         ipi.Firewall_Zone__c=internetFirewallId;
         ipi.name=internetVLANIP;
         if(internetIDLNumber!='' && internetIDLNumber.isNumeric()){
         ipi.TCNZ_IDL__c=internetIDLNumber;
         }else{
          errorInfo  = errorInfo +'</b> internet IDL Number is not right.';
         }  
         ipi.VRF__c=SparkInboundEmail__c.getInstance('VRF Internet Id').value__c;
         ipi.recordtypeid=SparkInboundEmail__c.getInstance('N4L WAN IP Recordtype Id').value__c;
         try{
                upsert ipi;
                updated= true;
                }catch (DMLException e)
        {
            System.debug('update failed : ' + e.getmessage());
        }
         
         } else{
          
           errorInfo  = errorInfo +'</b> internet VLAN IP is empty.';
       }     
         
         if(serviceVLANIP!='') {
         List<IP_Subnet__c> oldipss = [select id,Customer__c,Assigned_Device__c,Assigned_Port__c,Default_Gateway__c,Firewall_Zone__c,name,TCNZ_IDL__c,VRF__c from IP_Subnet__c where Assigned_Device__c=:deviceId and VRF__c=:SparkInboundEmail__c.getInstance('VRF Services Id').value__c limit 1 ];
         IP_Subnet__c ips = new IP_Subnet__c();
         if (oldipss!=null && oldipss.size()>0){
         ips.id=oldipss.get(0).id;
         }
         ips.Customer__c=TSOCase.accountid;
         ips.Assigned_Device__c=dev.id;
         ips.Assigned_Port__c=portId;
         ips.Default_Gateway__c=serviceVLANNextHotIP;
         ips.Firewall_Zone__c=serviceFirewallId;
         ips.name=serviceVLANIP;
         if(serviceIDLNumber!='' && serviceIDLNumber.isNumeric()){
         ips.TCNZ_IDL__c=serviceIDLNumber;
         }else{
          errorInfo  = errorInfo +'</b> service IDL Number is not right.';
         }  
         ips.VRF__c=SparkInboundEmail__c.getInstance('VRF Services Id').value__c;
         ips.recordtypeid=SparkInboundEmail__c.getInstance('N4L WAN IP Recordtype Id').value__c;
         try{
                upsert ips;
                updated= true;
                }catch (DMLException e)
        {
            System.debug('update failed : ' + e.getmessage());
        }
         
         } else{
          
           errorInfo  = errorInfo +'</b> service VLAN IP is empty.';
       }  
                
                }else{
          
           errorInfo  = errorInfo +'</b> can not find device. failed to create ip-subnet records. email attached to case';
       }  
                if(updated){
                
                if(TSOCase.IP_IDL_Update_Status__c=='Received'){
                  TSOCase.IP_IDL_Update_Status__c='Updated';
                }else{
                  TSOCase.IP_IDL_Update_Status__c='Received';
                }
                }   
                
                Attachment attachment = new Attachment();
                if (email.htmlBody != null){
                attachment.Body = Blob.valueOf(email.htmlBody);
                attachment.ContentType = 'text/html';}
                else {
                attachment.Body = Blob.valueOf(email.plainTextBody);
                attachment.ContentType = 'text/plain';
                }
                //attachment.Name = String.valueOf(email.subject);
                attachment.Name = email.subject.remove(':');
                attachment.ParentId = TSOCase.id;
                try{
                if(updated)
                update 	TSOCase;
                insert attachment;
                result.success = true;
                }catch (Exception e)
        {
            System.debug('update failed : ' + e);
        }
                }else {
         errorInfo  = errorInfo +'</b> can not find case:'+caseNumber;
         
         }
         
         
         }else {
         errorInfo  = errorInfo +'</b> can not find case number within email';
         
         }
         
         }
         //New Connection progress update 
         else if(email.plainTextBody.contains('<LFC Access RFS Date>:')){
         
         caseNumber = InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<N4L TSO Case#>:','<LFC Access RFS Date>');
           
         if(caseNumber!=''){
         TSOCase = InboundEmailHelpMethods.getTSOCase(caseNumber);
         system.debug('My debug 4 :'+TSOCase.id);
         if(TSOCase!=null){
         if(TSOCase.TCNZ_Work_Stream_Status__c!='CLNE Installed with Service Configuration'){	
         LFCAccessRFSDate=InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<LFC Access RFS Date>:','<LFC Status>');
         LFCStatus =InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<LFC Status>:','<CLNE Truckroll Scheduled Date>');
         CLNETruckrollScheduledDate  =InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<CLNE Truckroll Scheduled Date>:','<CLNE Installed Date>');
         CLNEInstalledDate =InboundEmailHelpMethods.getsubstringBetween(email.plainTextBody,'<CLNE Installed Date>:','<END>');
         datetime RFSDate;
         datetime ScheduledDate;
         datetime InstalledDate;
         
         //if(LFCStatus==''){
            
         //errorInfo  = errorInfo +'</b> LFC Status is not right!' ;
         //}
         
         if(LFCAccessRFSDate!='' && InboundEmailHelpMethods.getDateTime(LFCAccessRFSDate)!=null){
            RFSDate = InboundEmailHelpMethods.getDateTime(LFCAccessRFSDate);
         }
         
         if(CLNETruckrollScheduledDate!='' && InboundEmailHelpMethods.getDateTime(CLNETruckrollScheduledDate)!=null){
            ScheduledDate = InboundEmailHelpMethods.getDateTime(CLNETruckrollScheduledDate);
         }
         if(CLNEInstalledDate!='' && InboundEmailHelpMethods.getDateTime(CLNEInstalledDate)!=null){
            InstalledDate = InboundEmailHelpMethods.getDateTime(CLNEInstalledDate);
         }
         try{
                 boolean ischanged=false;
               
                if(LFCStatus!='' && RFSDate!=null){
                  if(!LFCStatus.containsIgnoreCase('service given') && !LFCStatus.containsIgnoreCase('request completed')){
                     if( RFSDate!=TSOCase.LFC_Truck_Roll_Scheduled_Date__c){
                     	//Scenario 1: LFC Truckroll booked/changed
                        TSOCase.LFC_Truck_Roll_Scheduled_Date__c = RFSDate;
                        ischanged=true;
                     }
                  }else{
                     if( RFSDate!=TSOCase.LFC_Access_RFS_Date__c){
                     	//Scenario 2: LFC access installed
                        TSOCase.LFC_Access_RFS_Date__c = RFSDate;
                        ischanged=true;
                     }
                   
                  }
                }
               //Scenario#3 do nothing for now
               if(ScheduledDate!=null && ScheduledDate!=TSOCase.CLNE_Truck_Roll_Scheduled_Date__c) {
               
               //TSOCase.CLNE_Truck_Roll_Scheduled_Date__c = ScheduledDate;
               }
               // Scenario 4: Billing Date
               if(InstalledDate!=null && InstalledDate!=TSOCase.CLNE_Installed_Date__c) {
               system.debug('install date'+InstalledDate);
               TSOCase.CLNE_Installed_Date__c = InstalledDate;
               ischanged=true;
               }
               
               if(ischanged){
               update TSOCase;
               }
                
                }catch (DMLException e)
                {
            System.debug('TSOCase update failed : ' + e.getmessage());
                }
         //////
         	
         Attachment attachment = new Attachment();
                if (email.htmlBody != null){
                attachment.Body = Blob.valueOf(email.htmlBody);
                attachment.ContentType = 'text/html';}
                else {
                attachment.Body = Blob.valueOf(email.plainTextBody);
                attachment.ContentType = 'text/plain';
                }
                //attachment.Name = String.valueOf(email.subject);
                attachment.Name = email.subject.remove(':');
                attachment.ParentId = TSOCase.id;
                try{
                insert attachment;
                result.success = true;
                }catch (Exception e)
        {
            System.debug('update failed : ' + e);
        }
         
         }else{
         
          errorInfo  = errorInfo +'</b> Changes to CLNE Install Date or LFC Access RFS Date received after CLNE Installed with Service Configuration. Salesforce has ignored this update to protect agreed billing impacting dates.'+' </b> CaseNumber: '+caseNumber ;
         }
         
         }else{
         
         errorInfo  = errorInfo +'</b> Can not find TSO case by Case Number:'+caseNumber ;
         }
         }else{
         
         errorInfo  = errorInfo +'</b> There is not a case number within email' ;
         }
         
         
         }
         
         else{
         
         errorInfo  = errorInfo +'</b> this is not a email from spark to update TSO case' ;
         }
         
         if(errorInfo!=''){
         InboundEmailHelpMethods.sendingEmail(errorInfo,email.plainTextBody);
         }
         return result;
        }

       
    }