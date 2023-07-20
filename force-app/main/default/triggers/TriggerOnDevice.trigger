/**
On Raspberry Pi (a record type of device "Monitoring Device" record type id="01290000000TIx6") record, we would like an automation to update related record in N4L Asset Register status field. The use case as below:
1. User brings up a RasperryPi record on screen.
2. User selectes "Installed N4L Asset" from look up.
3. User saves the record.
4. Salesforce to check the status of the selected N4L Installed Asset record in N4L Asset Register object.
5. Salesforce updates the N4L Asset record status to "In Transit" if the current status is "Spare".
6. Salesforce updates the N4L Asset record "current location" to device.customer name.
**/

trigger TriggerOnDevice on Device__c (before update) {    
    map<id,id> deviceWithAsset = new map<id,id>();
    map<id,string> deviceWithCustomerName = new map<id,string>();
    for(Device__c d:trigger.new){
        if(d.Installed_N4L_Asset__c!=null && d.Installed_N4L_Asset__c != trigger.oldmap.get(d.id).Installed_N4L_Asset__c){
            deviceWithAsset.put(d.id,d.Installed_N4L_Asset__c);
            deviceWithCustomerName.put(d.Installed_N4L_Asset__c,d.Customer_Name__c);
        }
      }
      
      if(deviceWithAsset.size()>0){
        
        TriggerOnDeviceHelpMethods.updateN4LAsset(deviceWithAsset,deviceWithCustomerName); 
      
      }
}