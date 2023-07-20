public without sharing class CallOutHelpMethods {
	

      public static String getPostXML (Case c){
      
      XmlStreamWriter w = new XmlStreamWriter();  
    w.writeStartDocument('utf-8','1.2');
      w.writeStartElement(null,'N4LServiceRequest', null);// need to be closed
        w.writeAttribute(null,null,'xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
        w.writeAttribute(null,null,'xmlns:xsd','http://www.w3.org/2001/XMLSchema');
      //
        w.writeStartElement(null,'OrderId', null);
        w.writeAttribute(null,null,'xsi:nil','true');
        w.writeEndElement();
      //
        w.writeStartElement(null,'CreatedByUserFirstName', null);
        w.writeCharacters(userinfo.getFirstName());
        w.writeEndElement();
      //
        w.writeStartElement(null,'CreatedByUserLastName', null);
        w.writeCharacters(userinfo.getLastName());
        w.writeEndElement();
      //
        w.writeStartElement(null,'CreatedByEmail', null);
        w.writeCharacters(userinfo.getUserEmail());
        w.writeEndElement();
      //
        w.writeStartElement(null,'CreatedByMobileNo', null);
        w.writeCharacters(Call_Out_Setting__c.getInstance('standard mobile number').value__c); // mandatory?
        w.writeEndElement();  
      //
        w.writeStartElement(null,'CreatedByPhoneNo', null);
        w.writeCharacters(Call_Out_Setting__c.getInstance('standard phone number').value__c); // mandatory?
        w.writeEndElement();   
      //  
        w.writeStartElement(null,'CreatedByUserName', null);
        w.writeCharacters(userinfo.getUserName());
        w.writeEndElement();   
      //
        w.writeStartElement(null,'RequestedDate', null);
        w.writeAttribute(null,null,'xsi:nil','true');
        w.writeEndElement();  
      //  
        //w.writeStartElement(null,'UpdatedByUserName', null);
        //w.writeCharacters('test updatedby name');// from where?
        //w.writeEndElement();  
      //  
        w.writeStartElement(null,'Status', null);
        w.writeCharacters('Submitted');// hard code?
        w.writeEndElement();  
      //
        w.writeStartElement(null,'DueDate', null);
        w.writeAttribute(null,null,'xsi:nil','true');
        w.writeEndElement();   
      //  
        //w.writeStartElement(null,'OrderReference', null);
        //w.writeCharacters('OrderReference1');// hard code?
        //w.writeEndElement();   
      //  
        w.writeStartElement(null,'RequestReference', null);
        w.writeCharacters(c.CaseNumber);
        w.writeEndElement();  
      //  
        //w.writeStartElement(null,'Comments', null);
        //w.writeCharacters(c.Web_Filtering_Administrator_Username__c);
        //w.writeEndElement();  
      //  new connection part start
        w.writeStartElement(null,'NewConnection', null);
        //
          w.writeStartElement(null,'Id', null);
          w.writeAttribute(null,null,'xsi:nil','true');
          w.writeEndElement();  
        //  
          w.writeStartElement(null,'LineItemStatus', null);// hard code?
          w.writeCharacters('Submitted');
          w.writeEndElement();  
        //  
          w.writeStartElement(null,'CoordinatorFirstName', null);
          w.writeCharacters(c.owner.firstname);
          w.writeEndElement();
        //  
          w.writeStartElement(null,'CoordinatorLastName', null);
          w.writeCharacters(c.owner.lastname);
          w.writeEndElement();
        //  
          w.writeStartElement(null,'CoordinatorPhoneNumber', null);
          w.writeCharacters(Call_Out_Setting__c.getInstance('standard phone number').value__c);// hard code?
          w.writeEndElement();
        //  
          w.writeStartElement(null,'CoordinatorEmailAddress', null);
          w.writeCharacters(c.Owner.Email);// 
          w.writeEndElement();
        //  
          w.writeStartElement(null,'SiteIdentifier', null);
          if(c.Account.TCNZ_Common_Name__c!=null)
          w.writeCharacters(c.Account.TCNZ_Common_Name__c);// 
          w.writeEndElement();  
        //  
          w.writeStartElement(null,'SchoolName', null);
          w.writeCharacters(c.Account.Name);// 
          w.writeEndElement();  
        //  
          w.writeStartElement(null,'MoESchoolId', null);
           if(c.Account.MoE_School_ID__c!=null)
          w.writeCharacters(c.Account.MoE_School_ID__c);// 
          w.writeEndElement();  
        //  
          w.writeStartElement(null,'MoESiteId', null);
          if(c.Account.MoE_Site_ID_Lookup__r.name!=null)
          w.writeCharacters(c.Account.MoE_Site_ID_Lookup__r.name);// 
          w.writeEndElement();  
        //  
          w.writeStartElement(null,'NumberofUsers', null);
          if(c.Account.Total_Users__c!=null)
          w.writeCharacters(String.valueOf(c.Account.Total_Users__c));// 
          w.writeEndElement();
        //  
          w.writeStartElement(null,'InstallationBuilding', null);
          if(c.CLNE_Installation_Building__c!=null)
          w.writeCharacters(c.CLNE_Installation_Building__c);// 
          w.writeEndElement();
        //  
          w.writeStartElement(null,'InstallationLevel', null);
          if(c.CLNE_Installation_Level__c!=null)
          w.writeCharacters(c.CLNE_Installation_Level__c);// 
          w.writeEndElement();
        //  
          w.writeStartElement(null,'InstallationRoom', null);
          if(c.CLNE_Installation_Room__c!=null)
          w.writeCharacters(c.CLNE_Installation_Room__c);// 
          w.writeEndElement();
        //  
          w.writeStartElement(null,'InstallationLocation', null);
          if(c.CLNE_Installation_In_Room_Location__c!=null)
          w.writeCharacters(c.CLNE_Installation_In_Room_Location__c);// bring it to page layout
          w.writeEndElement();
        //  
          w.writeStartElement(null,'IsLongCableRequired', null);
          if(c.X10m_Cable_Required__c!=null)
          w.writeCharacters(c.X10m_Cable_Required__c);// 
          w.writeEndElement();  
        //  
          w.writeStartElement(null,'IsCLNESiteAdheresSchoolSite', null);
          if(c.CLNE_Adheres_School_Site__c!=null)
          w.writeCharacters(c.CLNE_Adheres_School_Site__c);// bring it to the page layout
          w.writeEndElement();
        //  
          w.writeStartElement(null,'IsFibreServiceExistAlready', null);
          //if(Call_Out_Setting__c.getInstance('IsReadRromRecord').value__c=='no'){
          //w.writeCharacters(Call_Out_Setting__c.getInstance('IsFibreServiceExistAlready').value__c);// hard code?
         // }
         // else{
          w.writeCharacters(c.Currently_Connected_To_A_Fibre_Service__c);
          //}
          w.writeEndElement();
        //  
          w.writeStartElement(null,'ExistingFibreServiceProvider', null);
         // w.writeCharacters();// leave it brank
          if(c.Currently_Connected_To_A_Fibre_Service__c=='Yes' && c.Listed_ISP__c!=null)
          w.writeCharacters(c.Listed_ISP__c);
          w.writeEndElement();
        //  
          w.writeStartElement(null,'ExistingFibreServiceDetails', null);
          //w.writeCharacters(c.CLNE_Adheres_School_Site__c);//leave it brank
          if(c.Currently_Connected_To_A_Fibre_Service__c=='Yes' && c.Legacy_Internet_Connection_Type__c!=null )
          w.writeCharacters(c.Legacy_Internet_Connection_Type__c);
          w.writeEndElement();    
        //  
          w.writeStartElement(null,'IsUPSAvailable', null);
          if(c.Is_UPS_Available__c!=null)
          w.writeCharacters(c.Is_UPS_Available__c); // bring it to page layout
          w.writeEndElement();
        //  
          w.writeStartElement(null,'IsRestrictedAccess', null);
          if(c.Is_Restricted_Access__c!=null)
          w.writeCharacters(c.Is_Restricted_Access__c); // bring it to page layout
          w.writeEndElement();  
        //  
          w.writeStartElement(null,'ExistingRestrictedAccessDetails', null);
          w.writeCharacters(Call_Out_Setting__c.getInstance('ExistingRestrictedAccessDetails').value__c);// hard code?
          w.writeEndElement();
        //  
          w.writeStartElement(null,'HaveEnvironmentRisks', null);
          if(c.Has_Environment_Risk__c!=null)
          w.writeCharacters(c.Has_Environment_Risk__c);// bring it to page layout
          w.writeEndElement();
        //  
          w.writeStartElement(null,'EnvironmentRiskDetails', null);
          if(c.Environment_Risk_Details__c!=null)
          w.writeCharacters(c.Environment_Risk_Details__c);// bring it to page layout
          w.writeEndElement();
        //  
          w.writeStartElement(null,'HealthandSafetySecurityRequirements', null);// Owner:User.FirstName?
           if(c.HealthandSafetySecurityRequirements__c!=null)
          w.writeCharacters(c.HealthandSafetySecurityRequirements__c);
          w.writeEndElement();  
        //    
          w.writeStartElement(null,'PreferredInstallationTime', null);
          w.writeCharacters(Call_Out_Setting__c.getInstance('PreferredInstallationTime').value__c);//hard code?
          w.writeEndElement();
        //    
          w.writeStartElement(null,'AdditionalDetails', null);
          if(c.CLNE_Installation_Comment__c!=null)
          w.writeCharacters(c.CLNE_Installation_Comment__c);
          w.writeEndElement();
        //    
          w.writeStartElement(null,'NetworkConnectionsContractTerm', null);
           if(c.Account.Managed_Network_Contract_Term__c!=null)
          w.writeCharacters(c.Account.Managed_Network_Contract_Term__c);
          w.writeEndElement();
        //    
          w.writeStartElement(null,'NetworkConnectionsServiceOption', null);
           if(c.Account.School_Signed_Base_Connection__r.TCNZ_Standard_Service_Option__c!=null)
          w.writeCharacters(c.Account.School_Signed_Base_Connection__r.TCNZ_Standard_Service_Option__c);
          //w.writeCharacters('50/50/10 with Cisco 2921 ISR');
          
          w.writeEndElement();  
        //    
          w.writeStartElement(null,'NetworkConnectionsServiceLevel', null);
          if(c.Account.Service_Level__c!=null)
          w.writeCharacters(c.Account.Service_Level__c);
          w.writeEndElement();
        //
          w.writeStartElement(null,'PostalAddress', null);
           //
            w.writeStartElement(null,'AddressLine1', null);
            if(c.Account.Postal_Address_1__c!=null)
            w.writeCharacters(c.Account.Postal_Address_1__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'AddressLine2', null);
            if(c.Account.Postal_Address_2__c!=null)
            w.writeCharacters(c.Account.Postal_Address_2__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'AddressLine3', null);
            if(c.Account.Postal_Address_3__c!=null)
            w.writeCharacters(c.Account.Postal_Address_3__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'Suburb', null);
            w.writeCharacters(c.Account.Suburb__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'City', null);
            w.writeCharacters(c.Account.City__c);
            w.writeEndElement(); 
           //
            w.writeStartElement(null,'PostCode', null);
            if(c.Account.Postal_Code__c!=null)
            w.writeCharacters(c.Account.Postal_Code__c);
            w.writeEndElement(); 
         
          w.writeEndElement();//close PostalAddress
          w.writeStartElement(null,'PhysicalAddress', null);
           //
            w.writeStartElement(null,'PropertyOwner', null);
            //w.writeCharacters();
            w.writeEndElement();
           //
            w.writeStartElement(null,'Street', null);
            w.writeCharacters(c.Account.Street__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'Suburb', null);
            w.writeCharacters(c.Account.Suburb__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'City', null);
            w.writeCharacters(c.Account.City__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'PostCode', null);
            if(c.Account.Postal_Code__c!=null)
            w.writeCharacters(c.Account.Postal_Code__c);
            w.writeEndElement(); 
           //
            w.writeStartElement(null,'Directions', null);
            //w.writeCharacters();leave blank
            w.writeEndElement(); 
           //
            w.writeStartElement(null,'GPSLatitude', null);
            //w.writeCharacters();leave blank
            w.writeEndElement(); 
            //
            w.writeStartElement(null,'GPSLongitude', null);
            //w.writeCharacters();leave blank
            w.writeEndElement();
         
          w.writeEndElement();//close PostalAddress
        //
           w.writeStartElement(null,'PrimarySiteContact', null);
           //
            w.writeStartElement(null,'Title', null);
            if(c.Contact.Title!=null)
            w.writeCharacters(c.Contact.Title);
            else
            w.writeCharacters('Unknown');
            w.writeEndElement();
           //
            w.writeStartElement(null,'FirstName', null);
            w.writeCharacters(c.Contact.FirstName);
            w.writeEndElement();
           //
            w.writeStartElement(null,'LastName', null);
            w.writeCharacters(c.Contact.LastName);
            w.writeEndElement();
           //
            w.writeStartElement(null,'PhoneNumber', null);
            w.writeCharacters(c.Contact.Phone!=null? c.Contact.Phone:c.Contact.MobilePhone);
            w.writeEndElement();
           //
            w.writeStartElement(null,'MobileNumber', null);
            w.writeCharacters(c.Contact.MobilePhone!=null? c.Contact.MobilePhone : c.Contact.Phone);
            w.writeEndElement(); 
           //
            w.writeStartElement(null,'EmailAddress', null);
            w.writeCharacters(c.Contact.Email);
            w.writeEndElement(); 
           w.writeEndElement();//close PrimarySiteContact 
          //
           w.writeStartElement(null,'SecondarySiteContact', null);
           //
            w.writeStartElement(null,'Title', null);
            if(c.Secondary_Contact__r.title!=null)
            w.writeCharacters(c.Secondary_Contact__r.title);
            else
            w.writeCharacters('Unknown');
            w.writeEndElement();
           //
            w.writeStartElement(null,'FirstName', null);
            w.writeCharacters(c.Secondary_Contact__r.FirstName);
            w.writeEndElement();
           //
            w.writeStartElement(null,'LastName', null);
            w.writeCharacters(c.Secondary_Contact__r.LastName);
            w.writeEndElement();
           //
            w.writeStartElement(null,'PhoneNumber', null);
            w.writeCharacters(c.Secondary_Contact__r.Phone!=null? c.Secondary_Contact__r.Phone:c.Secondary_Contact__r.MobilePhone);
            w.writeEndElement();
           //
            w.writeStartElement(null,'MobileNumber', null);
            w.writeCharacters(c.Secondary_Contact__r.MobilePhone!=null? c.Secondary_Contact__r.MobilePhone:c.Secondary_Contact__r.Phone);
            w.writeEndElement(); 
           //
            w.writeStartElement(null,'EmailAddress', null);
            w.writeCharacters(c.Secondary_Contact__r.Email);
            w.writeEndElement(); 
           w.writeEndElement();//close SecondarySiteContact 
           
           w.writeStartElement(null,'WebFilterAdministrationDetails', null);
           
            w.writeStartElement(null,'FirstName', null);
            w.writeCharacters(Call_Out_Setting__c.getInstance('standard first name').value__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'LastName', null);
            w.writeCharacters(Call_Out_Setting__c.getInstance('standard last name').value__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'PhoneNumber', null);
            w.writeCharacters(Call_Out_Setting__c.getInstance('standard phone number').value__c);
            w.writeEndElement();
           //
            w.writeStartElement(null,'MobileNumber', null); 
            w.writeCharacters(Call_Out_Setting__c.getInstance('standard mobile number').value__c);
            w.writeEndElement(); 
           //
            w.writeStartElement(null,'EmailAddress', null);
            w.writeCharacters(c.Web_Filtering_Administrator_Username__c);
            w.writeEndElement(); 
           w.writeEndElement();//close WebFilterAdministrationDetails 
             
        w.writeEndElement(); //NewConnection close  
       //
      w.writeEndElement(); //N4LServiceRequest
	w.writeEndDocument();
      String xmlOutput =w.getXmlString();
      System.debug('The XML :'+w.getXmlString());    
      w.close();
      return  xmlOutput;
      }

}