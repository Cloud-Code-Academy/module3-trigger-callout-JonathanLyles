
News_Category__c nc = [SELECT Id, Name FROM News_Category__c WHERE Name = 'sports' LIMIT 1];
System.debug(nc);
NewsCategoryQueueable q = new NewsCategoryQueueable(nc.Id, nc.Name,5);
System.debug(q);
q.execute(context);

System.debug(Math.roundToLong(3.5));