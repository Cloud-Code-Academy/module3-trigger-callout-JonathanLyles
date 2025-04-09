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
        // TODO Validate and set defaults for parameters
        if(pageSize == null){
            pageSize = DEFAULT_PAGE_SIZE;
        }
        if(page == null){
            page = DEFAULT_PAGE;
        }
        
        // - Build the request URL
        String endpoint = API_NAMED_CREDENTIAL + API_ENDPOINT + '?apiKey=' + API_KEY + '&category=' + category + '&pageSize=' + pageSize + '&page=' + page;

        
        HttpResponse response = new HttpResponse();
        
        // if(Test.isRunningTest()){
        //     String successBody = '{' +
        //     '"status": "ok",' +
        //     '"totalResults": 2,' +
        //     '"articles": [' +
        //         '{' +
        //             '"source": {"id": "test-1", "name": "Test Source 1"},' +
        //             '"title": "Test Article 1",' +
        //             '"description": "Test Description 1",' +
        //             '"url": "https://test1.com",' +
        //             '"urlToImage": "https://test1.com/image.jpg",' +
        //             '"publishedAt": "2024-03-28T12:00:00Z"' +
        //         '},' +
        //         '{' +
        //             '"source": {"id": "test-2", "name": "Test Source 2"},' +
        //             '"title": "Test Article 2",' +
        //             '"description": "Test Description 2",' +
        //             '"url": "https://test2.com",' +
        //             '"urlToImage": "https://test2.com/image.jpg",' +
        //             '"publishedAt": "2024-03-28T13:00:00Z"' +
        //             '}' +
        //         ']' +
        //     '}';
        //     response.setBody(successBody);
        //     NewsAPIResponse newsDataMock = parseResponse(response.getBody());
        //     return newsDataMock;
        // }else{
            response = makeCallout(endpoint);
            // - Parse and return the response
            NewsAPIResponse newsData = parseResponse(response.getBody());
            return newsData;
        // }
        
    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    private static HttpResponse makeCallout(String endpoint) {
        // - Create and configure HTTP request
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(endpoint);
        // - Make the callout
        
            HttpResponse response = new Http().send(request); 
            try{ 
                // - Handle exceptions
                if (response.getStatusCode() != 200) {
                    throw new NewsAPIException(response.getStatusCode() + ': ' + response.getStatus());
                }
            }catch(NewsAPIException e){
                //TODO: 
            }catch(Exception e){
                //TODO:
            }
            return response;
        
    }
    
    /**
     * Helper method to parse the JSON response
     * @param jsonResponse The JSON response string
     * @return NewsAPIResponse The parsed response object
     */
    private static NewsAPIResponse parseResponse(String jsonResponse) {
        // - Deserialize JSON to NewsAPIResponse
        // - Handle exceptions
        if(String.isBlank(jsonResponse) || String.isBlank(jsonResponse)){
            throw new NewsAPIException('NewsAPI response is blank or empty');
            //todo add logging
        }else{
            NewsAPIResponse newsData = (NewsAPIResponse) JSON.deserialize(jsonResponse, NewsAPIResponse.class);
            //todo add logging
            return newsData;
        }
    }
    
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
} 