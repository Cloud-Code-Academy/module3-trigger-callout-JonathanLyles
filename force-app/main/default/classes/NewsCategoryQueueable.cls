/**
 * Queueable Apex class for processing News Category records with pagination support
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {
    private Id categoryId;
    private String categoryName;
    private Integer pageSize; //The number of results to return per page (request). 20 is the default, 100 is the maximum
    private Integer page; //Use this to page through the results if the total results found is greater than the page size
    
    /**
     * Constructor
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pageSize) {
        this.page = 1;
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.pageSize = pageSize;
    }
    
    /**
     * Constructor with current page
     * @param categoryId The Id of the News_Category__c record
     * @param categoryName The category name
     * @param pages Total pages to sync
     * @param currentPage Current page being processed
     */
    public NewsCategoryQueueable(Id categoryId, String categoryName, Integer pageSize, Integer page) {
        this.page = page;
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.pageSize = pageSize;
    }
    
    /**
     * Execute method for the queueable job
     * @param context The QueueableContext
     */
    public void execute(QueueableContext context) {
        
        //Initial request
        NewsAPIResponse newsAPIResponse = NewsAPIService.getTopHeadlinesByCategory(categoryName, pageSize, page);
        //Check results
        if(newsAPIResponse.totalResults == 0){
           // throw NewsAPIService.NewsAPIException('No articles returned from callout');
            //todo add logging
        }
        //Convert newsAPIResponse into a list of Article__c and add them to the articlesToUpdate list
        List<Article__c> articlesToUpdate = new List<Article__c>();
        articlesToUpdate.addAll(newsAPIResponse.toSObjects(this.categoryName,this.categoryId));

        //Update News_Category__c record
        News_Category__c newsCat = new News_Category__c();
        newsCat.Id = this.categoryId;
        newsCat.Last_Synced__c = Datetime.now();
        newsCat.Sync__c = false;

        //Determine how many more pages to paginate. 
        //5 is the max stack depth in a dev org, and we have already sent one callout
        Integer pagesToPaginate = Integer.valueOf(Math.roundToLong(( newsAPIResponse.totalResults / pageSize ) - (page -1)));
        if(pagesToPaginate > 4 && page <= 5){
            pagesToPaginate = 4;
        }
        //increment the page
        page += 1;
        //Chain another job if there are more pages to paginate
        if(page < pagesToPaginate){
            NewsCategoryQueueable nextJob = new NewsCategoryQueueable(categoryId, categoryName, pageSize, page);
            System.enqueueJob(nextJob);
        }else{
            System.debug('Reached maximum articles or page limit. No more jobs will be enqueued');
        }
        


        update newsCat;
        insert articlesToUpdate;
        // - Call NewsAPI for the current page
        // - Process and save articles
        // - Update category if last page
        // - Chain to next page if more pages exist
    }
} 