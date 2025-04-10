/**
 * Handler class for NewsCategoryTrigger
 */
public with sharing class NewsCategoryTriggerHandler {
    /**
     * Handles after insert events for News_Category__c
     * Uses Future method for callouts when Sync__c is true
     * @param newRecords List of newly inserted News_Category__c records
     */
    public static void handleInsert(List<News_Category__c> newRecords) {
        // - Filter categories that need to be synced
        Map<String, Id> categoryNameToIdMap = new Map<String, Id>();
        for(News_Category__c newRecord : newRecords){
            categoryNameToIdMap.put(newRecord.Name, newRecord.Id);
        }
        syncCategoriesWithFuture(categoryNameToIdMap);
    }

    /**
     * Handles after update events for News_Category__c
     * Uses Queueable Apex for callouts when Sync__c is true
     * @param newRecords List of updated News_Category__c records
     * @param oldMap Map of old record states
     */
    public static void handleUpdate(List<News_Category__c> newRecords, Map<Id, News_Category__c> oldMap) {
        // - Filter categories that need to be synced
        List<News_Category__c> categoriesToSync = new List<News_Category__c>();
        for(News_Category__c newRecord : newRecords){
            if(newRecord.Sync__c == true){
                categoriesToSync.add(newRecord);
            }
        }
        // - Call queueable method for callouts
        syncCategoriesWithQueueable(categoriesToSync);        
    }
    /**
     * Future method to sync categories using the NewsAPI
     * Used for insert operations
     * @param categoryNames List of category names to sync
     */
    @future(callout=true)
    public static void syncCategoriesWithFuture(Map<String, Id> categoryNameToIdMap) {
        // List of articles (Article__c) which will be inserted
        List<Article__c> articlesToInsert = new List<Article__c>();

        // List of categories (News_Category__c) which will be updated
        List<News_Category__c> categoriesToUpdate = new List<News_Category__c>();
        
        // Loop - Makes callouts to NewsAPI for each category
        for(String categoryName : categoryNameToIdMap.keySet()){

            try{
                List<Article__c> articles = new List<Article__c>();

                // Callout
                NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(categoryName, null, null);
                
                if(response != null && !response.articles.isEmpty()){
                    articles = response.toSObjects(categoryName, categoryNameToIdMap.get(categoryName));
                    articlesToInsert.addAll(articles);
                }else{
                    throw new NewsAPIException('Something bad happened and this message is supposed to help.');
                }
            }catch(Exception e){
                System.debug(e.getMessage());
            }
                  
            News_Category__c categoryToUpdate = new News_Category__c();
            categoryToUpdate.Id = categoryNameToIdMap.get(categoryName);
            categoryToUpdate.Last_Synced__c = Datetime.now();
            categoryToUpdate.Sync__c = false;
            categoriesToUpdate.add(categoryToUpdate);
        }
        //Insert articles
        try{
            if(articlesToInsert == null){
                throw new NewsAPIException('NewsAPIException: No articles to insert.');
            } 
            insert articlesToInsert;
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        //Update categories
        try{
            if(categoriesToUpdate == null){
                throw new NewsAPIException('NewsAPIException: No categories to insert');
            }
            update categoriesToUpdate;
        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }
    /**
     * Queueable method to sync categories using the NewsAPI
     * Used for update operations
     * @param categoriesToSync List of News_Category__c records to sync
     */
    private static void syncCategoriesWithQueueable(List<News_Category__c> categoriesToSync) {
        for(News_Category__c categoryToSync : categoriesToSync){
            Id categoryId = categoryToSync.Id;
            String categoryName = categoryToSync.Name;
            Integer pageSize = Integer.valueOf(categoryToSync.Pages__c);
            NewsCategoryQueueable queueableJob = new NewsCategoryQueueable(categoryId, categoryName, pageSize);
            System.enqueueJob(queueableJob);
        }
    }
}