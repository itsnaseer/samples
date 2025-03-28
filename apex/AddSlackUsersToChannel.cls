public with sharing class AddSlackUsersToChannel {
    @InvocableMethod(label='Add Users to Slack Channel' description='Invites users to a Slack channel')
    public static void inviteUsersToChannel(List<SlackInviteRequest> requests) {
        for (SlackInviteRequest request : requests) {
            if (String.isBlank(request.token) || String.isBlank(request.channelId) || request.userIds.isEmpty()) {
                System.debug('ERROR: Skipping request due to missing required fields.');
                continue;
            }

            // Convert userIds list into a comma-separated string
            String userIdsString = String.join(request.userIds, ',');
            inviteUsersAsync(request.token, request.channelId, userIdsString);
        }
    }

    // Future method with primitive parameters
    @future(callout=true)
    public static void inviteUsersAsync(String token, String channelId, String userIds) {
        System.debug('DEBUG: Processing Slack request asynchronously for Channel ID: ' + channelId);
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://slack.com/api/conversations.invite');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        // Prepare request body
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('channel', channelId);
        payload.put('users', userIds);

        req.setBody(JSON.serialize(payload));
        System.debug('DEBUG: Payload Sent: ' + req.getBody());

        try {
            HttpResponse res = http.send(req);
            System.debug('DEBUG: Response Status Code: ' + res.getStatusCode());
            System.debug('DEBUG: Response Body: ' + res.getBody());

            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (res.getStatusCode() != 200 || responseMap.get('ok') != true) {
                System.debug('ERROR: Slack API returned an error: ' + res.getBody());
            } else {
                System.debug('SUCCESS: Users invited to Slack channel: ' + channelId);
            }
        } catch (Exception e) {
            System.debug('EXCEPTION: Failed to send request to Slack - ' + e.getMessage());
        }
    }

    public class SlackInviteRequest {
        @InvocableVariable(label='Slack Bot Token' required=true description='The OAuth token with conversations.write scope')
        public String token;

        @InvocableVariable(label='Channel ID' required=true description='The ID of the Slack channel')
        public String channelId;

        @InvocableVariable(label='User IDs' required=true description='List of Slack user IDs to invite')
        public List<String> userIds;
    }
}
