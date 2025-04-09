    /**
     * Wrapper class for parsing the NewsAPI response
     */
    public class NewsAPIResponse {
        // TODO: Define fields to match the NewsAPI response structure
        public String status { get; set; }
        public Integer totalResults { get; set; }
        public List<Article> articles { get; set; }

        /**
         * Inner class representing a news article
         */
        public class Article {
            // TODO: Define article fields
            
            public String author { get; set; }
            public String title { get; set; }
            public String description { get; set; }
            public String url { get; set; }
            public String urlToImage { get; set; }
            public Datetime publishedAt { get; set; }
            public String content { get; set; }
            public Source source { get; set; }
            
            /**
             * Converts the API article to a Salesforce Article__c record
             * @return Article__c The Salesforce record
             */
            public Article__c toSObject(String category, Id categoryId) {
                Article__c newArticle = new Article__c();
                UUID randomUUID = UUID.randomUUID();
                newArticle.Name = randomUUID.toString();
                newArticle.Author__c = this.author;
                newArticle.Title__c = this.title;
                newArticle.Category__c = category;
                newArticle.Content__c = this.content;
                newArticle.Description__c = this.description;
                newArticle.News_Category__c = categoryId;
                if(this.source == null){
                    newArticle.Source__c = null;
                }else{
                    newArticle.Source__c = this.source.name;
                }
                if( this.url != null && this.url.length() > 255){
                    newArticle.url__c = null;
                }else{
                    newArticle.url__c = this.url;
                }
                if( this.urlToImage != null && this.urlToImage.length() > 255){
                    newArticle.urlToImage__c = null;
                }else{
                    newArticle.urlToImage__c = this.urlToImage;
                }
                newArticle.published_At__c = this.publishedAt;


                // TODO: // - Handling date conversion
                // Consider:
                // - Handling date conversion
                
                // - Generating a unique record name
                // - Handling field length limits
                
                return newArticle;
            }
        }
        
        /**
         * Inner class representing a news source
         */
        public class Source {
            // TODO: Define source fields
            public String id;
            public String name;
        }
        
        /**
         * Helper method to convert all articles in this response to Salesforce records
         * @return List<Article__c> List of Salesforce records
         */
        public List<Article__c> toSObjects(String category, Id categoryId) {
            // TODO: Implement conversion of all articles to Salesforce records
            List<Article__c> sObjectList = new List<Article__c>();
            if(articles != null){
                for(Article article : articles){
                    sObjectList.add(article.toSObject(category, categoryId));
                }
            }
            return sObjectList;
        }
    } 