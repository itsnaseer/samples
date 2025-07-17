public with sharing class SlackCreateChannel {
    public class Request {
        @InvocableVariable(label='Slack Bot Token' required=true)
        public String botToken;

        @InvocableVariable(label='Record ID' required=true)
        public String recordId;
    }

    public class Response {
        @InvocableVariable(label='Slack Channel ID')
        public String channelId;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(label='Create Slack Channel')
    public static List<Response> createSlackChannel(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request r : requests) {
            Response result = new Response();
            Http http = new Http();

            try {
                HttpRequest createReq = new HttpRequest();
                createReq.setEndpoint('https://slack.com/api/conversations.create');
                createReq.setMethod('POST');
                createReq.setHeader('Authorization', 'Bearer ' + r.botToken);
                createReq.setHeader('Content-Type', 'application/json');

                String channelName = 'record-' + r.recordId.replaceAll('[^a-zA-Z0-9]', '').toLowerCase();

                Map<String, Object> createBody = new Map<String, Object>{
                    'name' => channelName,
                    'team_id' => 'T06J0EC7CUQ', // Replace with your actual team ID
                    'is_private' => false
                };

                createReq.setBody(JSON.serialize(createBody));
                HttpResponse createRes = http.send(createReq);

                if (createRes.getStatusCode() != 200) {
                    result.errorMessage = 'HTTP error creating channel: ' + createRes.getStatus();
                    results.add(result);
                    continue;
                }

                Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(createRes.getBody());
                if (!(Boolean) resBody.get('ok')) {
                    result.errorMessage = 'Slack error: ' + (String) resBody.get('error');
                } else {
                    Map<String, Object> channel = (Map<String, Object>) resBody.get('channel');
                    result.channelId = (String) channel.get('id');
                }

            } catch (Exception e) {
                result.errorMessage = 'Exception: ' + e.getMessage();
            }

            results.add(result);
        }

        return results;
    }
}