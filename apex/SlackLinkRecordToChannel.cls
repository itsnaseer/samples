public with sharing class SlackLinkRecordToChannel {
    public class Request {
        @InvocableVariable(label='Slack Bot Token' required=true)
        public String botToken;

        @InvocableVariable(label='Slack Channel ID' required=true)
        public String channelId;

        @InvocableVariable(label='Salesforce Record ID' required=true)
        public String recordId;
    }

    public class Response {
        @InvocableVariable(label='Linking Status')
        public String status;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(label='Link Salesforce Record to Slack Channel')
    public static List<Response> linkRecord(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request r : requests) {
            Response result = new Response();
            Http http = new Http();

            try {
                // Prepare query parameters
                String encodedChannelId = EncodingUtil.urlEncode(r.channelId, 'UTF-8');
                String encodedRecordId = EncodingUtil.urlEncode(r.recordId, 'UTF-8'); // Slack does NOT want base64
                String encodedOrgId = EncodingUtil.urlEncode(UserInfo.getOrganizationId(), 'UTF-8');

                String fullUrl = 'https://slack.com/api/admin.conversations.linkObjects' +
                    '?channel=' + encodedChannelId +
                    '&record_id=' + encodedRecordId +
                    '&salesforce_org_id=' + encodedOrgId;

                // Configure POST request with query string
                HttpRequest linkReq = new HttpRequest();
                linkReq.setEndpoint(fullUrl);
                linkReq.setMethod('POST');
                linkReq.setHeader('Authorization', 'Bearer ' + r.botToken);
                linkReq.setHeader('Content-Type', 'application/x-www-form-urlencoded'); // Optional
                linkReq.setBody(''); // Required by Slack

                HttpResponse linkRes = http.send(linkReq);

                if (linkRes.getStatusCode() != 200) {
                    result.errorMessage = 'HTTP error: ' + linkRes.getStatus();
                    results.add(result);
                    continue;
                }

                Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(linkRes.getBody());
                if (!(Boolean) resBody.get('ok')) {
                    result.errorMessage = 'Slack error: ' + (String) resBody.get('error');
                } else {
                    result.status = 'Linked successfully';
                }

            } catch (Exception e) {
                result.errorMessage = 'Exception: ' + e.getMessage();
            }

            results.add(result);
        }

        return results;
    }
}