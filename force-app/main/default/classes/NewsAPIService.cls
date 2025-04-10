/**
 * Service class to interact with the NewsAPI for fetching top headlines
 */
public with sharing class NewsAPIService {

    // API endpoint
    private static final String API_NAMED_CREDENTIAL = 'callout:NewsAPI'; //https://newsapi.org
    private static final String API_ENDPOINT = '/v2/top-headlines';

    // Default parameters
    private static final Integer DEFAULT_PAGE_SIZE = 20;  
    private static final Integer DEFAULT_PAGE = 1;
    private static final String API_KEY = API_Credential__mdt.getInstance('apiKey').NewsAPI_apiKey__c;
    
    /**
     * Fetches top headlines for a specified category with pagination support
     * @param category The news category (business, entertainment, general, health, science, sports, technology)
     * @param pageSize Number of results per page (default: 20, max: 100)
     * @param page Page number for pagination
     * @return NewsAPIResponse The wrapper object containing the API response
     */
    public static NewsAPIResponse getTopHeadlinesByCategory(String category, Integer pageSize, Integer page) {
        //Set defaults if null
        if(pageSize == null){
            pageSize = DEFAULT_PAGE_SIZE;
        }
        if(page == null){
            page = DEFAULT_PAGE;
        }
        
        // - Build the request URL
        String endpoint = API_NAMED_CREDENTIAL + API_ENDPOINT + '?apiKey=' + API_KEY + '&category=' + category + '&pageSize=' + pageSize + '&page=' + page;

        HttpResponse response = new HttpResponse();
        
        response = makeCallout(endpoint);
        // - Parse and return the response
        NewsAPIResponse newsData = parseResponse(response.getBody());
        return newsData;    
    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    private static HttpResponse makeCallout(String endpoint) {

        //Create logging object
        News_API_Log__c myLog = new News_API_Log__c();

        // - Create and configure HTTP request
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(endpoint);
        
        // - Make the callout
        HttpResponse response = new Http().send(request); 
        try{ 

            // - Handle exceptions
            if (response.getStatusCode() != 200) {
                throw new NewsAPIException('Callout error');
            }
        }catch(NewsAPIException e){
            myLog.Message__c = e.getMessage() + '. Status code: ' + response.getStatusCode();
            myLog.Success__c = false;
        }catch(Exception e){
            myLog.Message__c = 'Unexpected exception. Message: ' + e.getMessage() + ' - Status code: ' + response.getStatusCode();
        }
        myLog.Message__c = 'Status code 200 - Callout successful.';
        insert myLog;
        return response;
    }
    
    /**
     * Helper method to parse the JSON response
     * @param jsonResponse The JSON response string
     * @return NewsAPIResponse The parsed response object
     */
    private static NewsAPIResponse parseResponse(String jsonResponse) {

        //Initialize logger
        News_API_Log__c myLog = new News_API_Log__c();

        // - Deserialize JSON to NewsAPIResponse
        // - Handle exceptions
        if(String.isBlank(jsonResponse) || String.isBlank(jsonResponse)){
            myLog.Message__c = 'NewsAPI response is blank or empty';
            throw new NewsAPIException('NewsAPI response is blank or empty');
            
        }else{
            NewsAPIResponse newsData = (NewsAPIResponse) JSON.deserialize(jsonResponse, NewsAPIResponse.class);
            myLog.Message__c = 'JSON body successfully parsed.';
            return newsData;
        }
    }
    
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
} 