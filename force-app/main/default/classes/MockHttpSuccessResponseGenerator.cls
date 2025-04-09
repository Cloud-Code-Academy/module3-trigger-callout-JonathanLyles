public with sharing class MockHttpSuccessResponseGenerator implements HttpCalloutMock{
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        String successBody = '{' +
            '"status": "ok",' +
            '"totalResults": 2,' +
            '"articles": [' +
                '{' +
                    '"source": {"id": "test-1", "name": "Test Source 1"},' +
                    '"title": "Test Article 1",' +
                    '"description": "Test Description 1",' +
                    '"url": "https://test1.com",' +
                    '"urlToImage": "https://test1.com/image.jpg",' +
                    '"publishedAt": "2024-03-28T12:00:00Z"' +
                '},' +
                '{' +
                    '"source": {"id": "test-2", "name": "Test Source 2"},' +
                    '"title": "Test Article 2",' +
                    '"description": "Test Description 2",' +
                    '"url": "https://test2.com",' +
                    '"urlToImage": "https://test2.com/image.jpg",' +
                    '"publishedAt": "2024-03-28T13:00:00Z"' +
                '}' +
            ']' +
        '}';
        res.setBody(successBody);
        return res;
    }
}