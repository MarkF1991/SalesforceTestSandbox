/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 29th May 2020
* @description Wrapper class for serialising and de-serialising Xero Contacts
*
* CHANGE LOG
**/
public class XeroContact {

    public String ContactID;
	public String ContactStatus;
	public String Name;
	public String FirstName;
	public String LastName;
	public String EmailAddress;
	public String BankAccountDetails;
	public List<Address> Addresses;
	public List<Phone> Phones;
	public String UpdatedDateUTC;
	public Boolean IsSupplier;
	public Boolean IsCustomer;
	public Boolean HasAttachments;
	public Boolean HasValidationErrors;
    public List<XeroValidationError> ValidationErrors;

    public class Address {
        public String AddressType; // POBOX, STREET
        public String AddressLine1;
        public String AddressLine2;
        public String AddressLine3;
        public String AddressLine4;
        public String City;
        public String Region;
        public String PostalCode;
        public String Country;
        public String AttentionTo;

        public Address (Account account, String addressType) {

            this.AddressType = addressType;

            if (addressType == 'POBOX') {

                this.AddressLine1 = account.BillingStreet;
                this.City = account.BillingCity;
                this.Region = account.BillingState;
                this.PostalCode = account.BillingPostalCode;
                this.Country = account.BillingCountry;
            }
            else {

                this.AddressLine1 = account.ShippingStreet;
                this.City = account.ShippingCity;
                this.Region = account.ShippingState;
                this.PostalCode = account.ShippingPostalCode;
                this.Country = account.ShippingCountry;
            }
        }
    }

    public class Phone {

        public String PhoneType; // DEFAULT, DDI, MOBILE, FAX
        public String PhoneNumber;
        public String PhoneAreaCode;
        public String PhoneCountryCode;

        public Phone(Account account, String phoneType) {

            this.PhoneType = phoneType;

            switch on phoneType {
                when 'DEFAULT' {
                    this.PhoneNumber = account.Phone;
                }
                when 'FAX' {
                    this.PhoneNumber = account.Fax;
                }
            }
        }  
    }
    
    // Constructor to convert Salesforce Account
    // To a Xero Contact
    public XeroContact(Account account) {

        this.ContactID = account.Xero_Id__c;
        this.ContactStatus = 'ACTIVE';
        this.Name = account.Name;
        this.Addresses = new List<XeroContact.Address>();
        this.Phones = new List<Phone>();

        if (!account.Contacts.isEmpty()) { 

            this.FirstName = account.Contacts[0].FirstName;
            this.LastName = account.Contacts[0].LastName;
            this.EmailAddress = account.Contacts[0].Email;
        }

        this.addAddresses(account);
        this.addPhones(account);
    }

    public XeroContact(String xeroContactId) {
        this.ContactID = xeroContactId;
    }

    public void addAddresses(Account account) {

        if (String.isNotBlank(account.BillingStreet)) {
            this.Addresses.add(new Address(account, 'POBOX'));
        }

        if (String.isNotBlank(account.ShippingStreet)) {
            this.Addresses.add(new Address(account, 'STREET'));
        }
    }

    public void addPhones(Account account) {

        if (String.isNotBlank(account.Phone)) {
            this.Phones.add(new Phone(account, 'DEFAULT'));
        }

        if (String.isNotBlank(account.Fax)) {
            this.Phones.add(new Phone(account, 'FAX'));
        }
    }

    // Serialise to JSON String for Xero
    public String serialize() {
        return JSON.serialize(this, true);
    }

}