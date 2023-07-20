/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 29th May 2020
* @description Test class for XeroValidationError
**/
@isTest
public class XeroValidationErrorTest {
    
    @isTest 
    static void testProcessValidationErrors () {

        XeroValidationError xeroError = new XeroValidationError();
        xeroError.Message = 'Test Error';

        XeroValidationError.processValidationErrors(new List<XeroValidationError>{xeroError});
    }
}