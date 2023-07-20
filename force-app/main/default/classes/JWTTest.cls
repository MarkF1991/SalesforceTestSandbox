@IsTest
public with sharing class JWTTest {

    @TestSetup
    private static void setup() {
        
	}

    static testMethod void test_getN4LSettings_UnitTestSettings_method() {
        String type = 'Unit Testing';
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
        system.assertEquals(5, jwt.validFor);
        system.assertEquals('c3VwZXJzZWNyZXQ=', jwt.privateKey);
    }

    
    static testMethod void test_getN4LSettings_negative_test_method() {
        String type = 'Wrong Type';
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
        system.assertEquals(5, jwt.validFor); //should return default
        system.assertEquals('c3VwZXJzZWNyZXQ=', jwt.privateKey);//should return default
    }

    static testMethod void test_issue_without_encryption() {
        String type = 'Unit Testing';
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
        jwt.privateKey = 'c3VwZXJzZWNyZXQ=';
        String result = jwt.issue(false);//isEncrypted = false
        system.assertEquals(true, result.length() > 0); 
        system.assertEquals(true, result.contains('.')); //JWT has 2 '.'
    }

    static testMethod void test_issue_with_encryption() {
        String type = 'Unit Testing';
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
        String result = jwt.issue(true); //isEncrypted = true
        system.assertEquals(true, result.length() > 0); 
        system.assertEquals(false, result.contains('.')); //Encoded string does not have '.'
    }

    static testMethod void test_decode_JWT_constructor() {
        //step 1: generate a JWT with encryption first
        String type = 'Filtering Portal';
        Boolean isEncrypted = true;
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
        
        //add claim
        Map<String, String> claimsMap = new Map<String, String>();
        claimsMap.put('attribute1', 'value1');
        claimsMap.put('attribute2', 'value2');
        claimsMap.put('attribute3', 'value3');
        jwt.claims = claimsMap;

        String token = jwt.issue(isEncrypted);
        system.assertEquals(true, token.length() > 0); 
        system.assertEquals(false, token.contains('.')); //Encoded string does not have '.'

        //step 2: decode the JWT
        JWT testDecodedJWT = new JWT('HS256', type, token, isEncrypted);
        system.assertEquals(true, testDecodedJWT.verified); 
        system.assertEquals(false, testDecodedJWT.expired); 
        Map<String, Object> testDecodedClaimsMap = testDecodedJWT.claims;
        system.assertEquals((3+2), testDecodedClaimsMap.size()); 
        system.assertEquals('value2', testDecodedClaimsMap.get('attribute2')); 

    }

    static testMethod void test_decode_JWT_constructor_unverified() {
        //step 1: generate a JWT with encryption first
        String type = 'Filtering Portal';
        Boolean isEncrypted = true;
        String token = 'ThisIsInvalidToken';
        //step 2: decode the JWT
        JWT testDecodedJWT = new JWT('HS256', type, token, isEncrypted);
        system.assertEquals(false, testDecodedJWT.verified); 
        
        // Map<String, Object> testDecodedClaimsMap = testDecodedJWT.claims;
        // system.assertEquals((3+2), testDecodedClaimsMap.size()); 
        // system.assertEquals('value2', testDecodedClaimsMap.get('attribute2')); 

    }


    static testMethod void test_getCryptoKey() {
        String type = 'Unit Testing';
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
      	Blob cryptoKey = JWT.getCryptoKey();
        system.assertEquals('gJzpBNJtCDMRnqF1DhabJJK73nHeF/U4LV78gi4shAM=', EncodingUtil.base64Encode(cryptoKey));
    }
    //  static testMethod void test_getSecretKey() {
    //      String type = 'School Reporting';
    //     JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
	// 	String secret = jwt.getSecretKey('c3VwZXJzZWNyZXQ=', 'School Reporting');
    //     system.assertEquals('c3VwZXJzZWNyZXQ=', secret);
    // }

    static testMethod void test_base64URLencode() {
        String type = 'Unit Testing';
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
		String result = jwt.base64URLencode(Blob.valueOf('supersecret'));
        system.assertEquals('c3VwZXJzZWNyZXQ', result);

    }

    static testMethod void test_base64URLdecode() {
        String type = 'Unit Testing';
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
		Blob result = jwt.base64URLdecode('c3VwZXJzZWNyZXQ');
        system.assertEquals('supersecret', result.tostring());
    }

    // static testMethod void test_JWT() {
    //     String type = 'School Reporting';
    //     JWT jwt = new JWT('HS256', type, 'something secret', false);
    //     jwt.iss = 'd';
    //     jwt.sub = 'd';
    //     jwt.aud = 'd';
    //     jwt.exp = 'd';
    //     jwt.iat = 'd';
    //     jwt.pkcs8 = 'd';
    //     jwt.now = 'd';
    //     jwt.jsonBody = 'd';
    //     jwt.expired = true;
    //     system.assertEquals(false, jwt.verified);
    // }

    static testMethod void test_encryptString_and_decryptString() {
        String type = 'Unit Testing';
        JWT jwt = new JWT('HS256', type); //this will run getN4LSettings() method;
        String input = 'supersecret';
        String encryptedString = jwt.encryptString(input);
        String decryptedString = jwt.decryptString(encryptedString);
        system.assertEquals(input, decryptedString); //the decrypted string shall be the same as the input.
    }
}