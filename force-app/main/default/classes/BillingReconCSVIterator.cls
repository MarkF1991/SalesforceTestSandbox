/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Custom interator class for splitting up a CSV into processable lines
*
* CHANGE LOG
**/
public with sharing class BillingReconCSVIterator implements Iterator<String>, Iterable<String>{

   private String m_CSVData;
   private String m_introValue;

    public BillingReconCSVIterator(String fileData, String introValue) {
        m_CSVData = fileData;
        m_introValue = introValue;
    }

    public Boolean hasNext() {
        return m_CSVData.length() > 1 ? true : false;
    }

    public String next(){
        String row = m_CSVData.subString(0, m_CSVData.indexOf(m_introValue));
        m_CSVData = m_CSVData.subString(m_CSVData.indexOf(m_introValue) + m_introValue.length(),m_CSVData.length());
        return row;
    }

    public Iterator<string> Iterator() {
        return this;
    }

}