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
        List<String> categoryNames = filterCategoryNames(newRecords);
        syncCategoriesWithFuture(categoryNames);
    }
    /**
     * Handles filtering of categories
     * @param List<News_Category__c> newRecords - from Trigger.new
     * @return List<String> categoryNames - List of category names where sync is true
     */
    private static List<String> filterCategoryNames(List<News_Category__c> newRecords){
        List<String> categoryNames = new List<String>();
        for(News_Category__c newRecord : newRecords){
            if(newRecord.Sync__c == true){
                categoryNames.add(newRecord.Name);
            }
        }
        return categoryNames;
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
    public static void syncCategoriesWithFuture(List<String> categoryNames) {
        // List of articles (Article__c) which will be inserted
        List<Article__c> articlesToInsert = new List<Article__c>();
        // List of News_Category__c records to update
        List<News_Category__c> categoriesToUpdate = new List<News_Category__c>();
        // Map of categories to their callout response
        Map<String, NewsAPIResponse> categoryToNewsAPIResponseMap = new Map<String, NewsAPIResponse>();
        // Map of category names to their record Id
        Map<String, Id> categoryNameToIdMap = new Map<String, Id>();
        // Retrieve categories
        List<News_Category__c> newsCategories = [SELECT Name, Id FROM News_Category__c WHERE Name IN :categoryNames];
        // Builds categoryNameToIdMap
        for(News_Category__c newsCategory : newsCategories){
            //Todo: why is this not writing to map?
            categoryNameToIdMap.put(newsCategory.Name, newsCategory.Id);
        }
        // Loop - Makes callouts to NewsAPI for each category
        for(String category : categoryNames){
            // Callout
            NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(category, null, null);
            // Add category name (key) and its response (value) to categoryToNewsAPIResponseMap
            categoryToNewsAPIResponseMap.put(category, response);
            // Converts the articles in response to a list of Article__c sObjects and adds the list to articlesToInsert 
            articlesToInsert.addAll(response.toSObjects(category, categoryNameToIdMap.get(category)));
            System.debug(articlesToInsert);
            News_Category__c categoryToUpdate = new News_Category__c();
            categoryToUpdate.Id = categoryNameToIdMap.get(category);
            categoryToUpdate.Last_Synced__c = Datetime.now();
            categoryToUpdate.Sync__c = false;
            categoriesToUpdate.add(categoryToUpdate);
        }
        try{
            if(articlesToInsert == null){
                throw new NewsAPIException('NewsAPIException: No articles to insert.');
            }else if(categoriesToUpdate == null){
                throw new NewsAPIException('NewsAPIException: No categories to update.');
            }
            insert articlesToInsert;
            System.debug('articles inserted: ' + articlesToInsert);
            update categoriesToUpdate;
        }catch(NewsAPIException e){
            //TODO: LOG EXCEPTIONS
        }catch(DMLException e){
            System.debug('something happened dml exception: ' + e.getMessage());
            //TODO: LOG EXCEPTIONS
        }catch(Exception e){
            System.debug('Regular exception: ' + e.getMessage());
            //TODO: LOG EXCEPTIONS
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
            //Todo: add error handling, and logging
        }
         

        // - Determine pages to sync for each category
        // - Create and enqueue NewsCategoryQueueable job for each category
    }
}