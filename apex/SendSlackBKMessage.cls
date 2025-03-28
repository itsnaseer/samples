public with sharing class SendSlackBKMessage {
    @InvocableMethod(label='Send Slack Block Kit Message' description='Sends a formatted BlockKit message to Slack and returns the timestamp')
    public static List<String> sendMessage(List<RequestData> requests) {
        List<String> messageTimestamps = new List<String>();
        for (RequestData req : requests) {
            String ts = sendToSlack(req.channelId, req.botToken, req.blocks, req.threadTs);
            messageTimestamps.add(ts);
        }
        return messageTimestamps;
    }

    private static String sendToSlack(String channelId, String botToken, String blocks, String threadTs) {
        try {
            // Validate input parameters
            if (String.isEmpty(channelId) || String.isEmpty(botToken) || String.isEmpty(blocks)) {
                System.debug('Error: Missing required parameters. Channel ID, Bot Token, and Blocks are mandatory.');
                return null;
            }

            // Construct the request body
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('channel', channelId);

            // Validate JSON format of Blocks
            try {
                payload.put('blocks', JSON.deserializeUntyped(blocks));
            } catch (Exception e) {
                System.debug('Error: Invalid JSON format in Blocks parameter - ' + e.getMessage());
                return null;
            }

            // Add thread timestamp if provided (to reply in a thread)
            if (!String.isEmpty(threadTs)) {
                payload.put('thread_ts', threadTs);
            }

            // Convert the payload to JSON
            String requestBody = JSON.serialize(payload);
            System.debug('Slack API Request Payload: ' + requestBody);

            // Set up the HTTP request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://slack.com/api/chat.postMessage');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + botToken);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(requestBody);

            // Send the request
            HttpResponse response = http.send(request);
            System.debug('Slack API Response Code: ' + response.getStatusCode());
            System.debug('Slack API Response Body: ' + response.getBody());

            // Parse the response
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                if (responseBody.containsKey('ok') && (Boolean) responseBody.get('ok')) {
                    if (responseBody.containsKey('ts')) {
                        String ts = (String) responseBody.get('ts');
                        System.debug('Message sent successfully. Timestamp: ' + ts);
                        return ts;  // Return message timestamp
                    } else {
                        System.debug('Error: Slack response missing "ts" (timestamp).');
                    }
                } else {
                    System.debug('Slack API Error: ' + responseBody.get('error'));
                }
            } else {
                System.debug('Slack API HTTP Error: ' + response.getStatusCode() + ' ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Error sending message to Slack: ' + e.getMessage());
        }
        return null;
    }

    // Invocable Method Input Wrapper
    public class RequestData {
        @InvocableVariable(label='Slack Channel ID' required=true)
        public String channelId;

        @InvocableVariable(label='Slack Bot Token' required=true)
        public String botToken;

        @InvocableVariable(label='Blocks (JSON String)' required=true)
        public String blocks;

        @InvocableVariable(label='Thread Timestamp (Optional)' required=false)
        public String threadTs;
    }
}
