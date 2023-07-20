public class JWT {
    
    public String alg {get;set;}
    public String iss {get;set;}
    public String sub {get;set;}
    public String aud {get;set;}
    public String exp {get;set;}
    public String iat {get;set;}
    public Map<String, Object> claims {get;set;}
    public Integer validFor {get;set;}
    //public String cert {get;set;}//commented out by Ben Soh. Nothing with this block of code. It was just too hard to get cert going in unit test 
    public String pkcs8 {get;set;}
    public String privateKey {get;set;}
    public String type {get;set;} //type of product/service: for retrieving default validFor value in Custom Metadata Types

    //for decoding a given JWT (in string)
    public Boolean verified {get;set;}
    public Boolean expired {get;set;}
    public Map<string, string> jwtParts {get;set;}
    public String jsonBody {get;set;}
    public String now {get;set;}

    public static final String HS256 = 'HS256';
    public static final String RS256 = 'RS256';
    public static final String NONE = 'none';

    Private Map<string, List<N4LSetting__mdt>> settingsMap;
    private void getN4LSettings(){
        settingsMap = new Map<string, List<N4LSetting__mdt>>();
        List<N4LSetting__mdt> settings = [SELECT DeveloperName, Id, Label, cryptoKey__c, secretKey__c, type__c, validFrom__c, validFor__c FROM N4LSetting__mdt ORDER BY type__c, validFrom__c DESC];
        For (N4LSetting__mdt setting : settings){
            if (settingsMap.containsKey(setting.type__c)){
                settingsMap.get(setting.type__c).add(setting);
            } else {
                List<N4LSetting__mdt> list1 =  new List<N4LSetting__mdt>();
                list1.add(setting);
                settingsMap.put(setting.type__c, list1);
            }
        }

        //set default;
        if (settingsMap.get(type) == null){
            this.validFor = 5; //default to 5
            this.privateKey = 'c3VwZXJzZWNyZXQ=';
        } else {
            N4LSetting__mdt setting = settingsMap.get(type).get(0); //settingsMap returns a list based on a given key. Then get the first element in the list
            // if(String.isBlank(setting.secretKey__c)){
            //     this.privateKey = 'c3VwZXJzZWNyZXQ=';
            // } else {
                this.validFor = setting.validFor__c.intValue();    //validFor is defined in Custom Metadata Types
                this.privateKey = setting.secretKey__c; //privateKey is defined in Custom Metadata Types
            // }
        }
        
    }

    public JWT(String alg, string type) {
        this.alg = alg;
        this.type = type;
        getN4LSettings(); //get keys in custom settings: N4LSettings
        //this.validFor = 300;
    }
    
    public JWT(String alg, string type, String input, Boolean isEncrypted) {
        this.alg = alg;
        this.type = type;
        getN4LSettings();
        try {
            if(isEncrypted){
                //need to decrypt first
                Blob cryptoKey = getCryptoKey();
                Blob data = base64URLdecode(input); //convert string back to blob, with URLdecoding
                Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, data);
                input = decryptedData.toString();
            }
            
            setJWTparts(input); //prepare the 3 parts of jwt in map
            setVerified();
            setClaims();
            setExpired();
        } catch (Exception e) {
            this.verified = false;
        }
        
    }

    public String issue(Boolean isEncrypted) {
        String jwt = this.generateJWT(); //generate a jwt first
        if (isEncrypted){
            Blob cryptoKey = getCryptoKey();
            
            Blob data = Blob.valueOf(jwt);
            Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data);
            return base64URLencode(encryptedData);
        }
        return jwt;
    }

    private String generateJWT() {
    
        String jwt = '';
    
        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('alg', this.alg);
        header.writeStringField('typ', 'JWT');
        header.writeEndObject();
        String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
            
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        Long rightNow = (dateTime.now().getTime()/1000)+1;
        body.writeNumberField('iat', rightNow);
        body.writeNumberField('exp', (rightNow + validFor));
        if (claims != null) {
            for (String claim : claims.keySet()) {
                body.writeObjectField(claim, claims.get(claim));//Writes a field name and value pair using the specified field name and Apex object.
            }
        }
        body.writeEndObject();
        
        jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));
        
        if ( this.alg == HS256 ) {
            Blob key = EncodingUtil.base64Decode(privateKey);
            Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
            jwt += '.' + base64URLencode(signature);
        }
        //commented out by Ben Soh. Nothing wrong with this block of code. It was just too hard to get cert going in unit test 
        // } else if ( this.alg == RS256 ) {
        //     Blob signature = null;
        //     if (cert != null ) {
        //         signature = Crypto.signWithCertificate('rsa-sha256', Blob.valueOf(jwt), cert);
        //     } else {
        //         Blob privateKey = EncodingUtil.base64Decode(pkcs8);
        //         signature = Crypto.sign('rsa-sha256', Blob.valueOf(jwt), privateKey);
        //     }
        //     jwt += '.' + base64URLencode(signature);  
        //}
        //commented out by Ben Soh. Nothing with this block of code. It was just too hard to get cert going in unit test 

        return jwt;
    }

     public Blob getCryptoKey() {
        //pick the latest custom settings record
        N4LSetting__mdt setting = settingsMap.get(type).get(0); //settingsMap returns a list based on a given key. Then get the first element in the list
        return EncodingUtil.base64Decode(setting.cryptoKey__c);
    }

    // public String getSecretKey(String defaultVal) {
    //     N4LSetting__mdt setting = settingsMap.get(type).get(0);
    //     string stringSecretKey = setting.secretKey__c;
    //     if(stringSecretKey == null) {
    //         return defaultVal;
    //     }
    //     return stringSecretKey;
    // }

    public String base64URLencode(Blob input) {
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while ( output.endsWith('=')){
            output = output.subString(0,output.length()-1);
        }
        return output;
    }

    public Blob base64URLdecode(String input){
        input = input.replace('-', '+');
        input = input.replace('_', '/');
        input += '='; 
        return encodingUtil.base64Decode(input);
    }

    private void setJWTparts(String input){
        if(!String.isBlank(input)){
            jwtParts = new Map<string, string>();
            List<string> parts = input.split('\\.'); //Split takes a regular expression as its first parameter, not a string.  The period character means any character in regex land, so you need to escape it with a backslash.
            if(parts.size() == 3){
                jwtParts.put('Header', parts[0]);
                jwtParts.put('Body', parts[1]);
                jwtParts.put('Signature', parts[2]); 
            }
        }
    }

    private void setVerified() {
        Boolean result = false;

        Blob signature = base64URLdecode(jwtParts.get('Signature'));

        Blob data = Blob.valueof(jwtParts.get('Header') + '.' + jwtParts.get('Body'));

        //commented out by Ben Soh. Nothing with this block of code. It was just too hard to get cert going in unit test 
        // if ( this.alg == RS256 ) {
        //     if (cert != null ) {
        //         result = Crypto.verify('RSA-SHA256', data, signature, cert);
        //     }
        // }
        //commented out by Ben Soh. Nothing with this block of code. It was just too hard to get cert going in unit test 
        if ( this.alg == HS256 ) {
            Blob key = EncodingUtil.base64Decode(privateKey);
            result = Crypto.verifyHMac('HmacSHA256', data, key, signature);
        }
        
        this.verified = result;
    }

    private void setClaims() {
        Blob body = base64URLdecode(jwtParts.get('Body'));
        this.claims = (Map<String, Object>) JSON.deserializeUntyped(body.tostring());
        this.jsonBody = body.tostring(); //simply return JSON string, let lwc to process it.
    }

    private void setExpired() {
        Long rightNow = (dateTime.now().getTime()/1000)+1;       
        this.now = String.valueOf(rightNow);
        Long expiry = Long.valueOf(String.valueOf(this.claims.get('exp'))) ;//this.claims.get('exp') is object. Therefore, we need to convert to String first then to Long data type
        this.expired = (rightNow > expiry);
    }

    public string encryptString(string input){
        Blob cryptoKey = getCryptoKey();
        Blob data = Blob.valueOf(input);
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data);
        return base64URLencode(encryptedData);
    }

    public string decryptString(string input){
        //need to decrypt first
        Blob cryptoKey = getCryptoKey();
        Blob data = base64URLdecode(input); //convert string back to blob, with URLdecoding
        Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, data);
        return decryptedData.toString();
    }
}