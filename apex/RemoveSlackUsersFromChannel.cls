public with sharing class RemoveSlackUsersFromChannel {
    private static final String SLACK_KICK_ENDPOINT = 'https://slack.com/api/conversations.kick';

    @InvocableMethod(
        label='Remove Users from Slack Channel'
        description='Removes users from a Slack channel using conversations.kick. Add https://slack.com to Remote Site Settings.'
    )
    public static List<RemoveSlackUsersResult> removeUsersFromChannels(List<RemoveSlackUsersRequest> requests) {
        List<RemoveSlackUsersResult> results = new List<RemoveSlackUsersResult>();
        for (RemoveSlackUsersRequest req : requests) {
            results.add(executeRemove(req));
        }
        return results;
    }

    private static RemoveSlackUsersResult executeRemove(RemoveSlackUsersRequest req) {
        RemoveSlackUsersResult result = new RemoveSlackUsersResult();
        result.success = true;
        result.message = '';

        if (String.isBlank(req.slackToken)) {
            result.success = false;
            result.message = 'Slack Token is required.';
            return result;
        }
        if (req.slackUserIds == null || req.slackUserIds.isEmpty()) {
            result.success = false;
            result.message = 'At least one Slack User ID is required.';
            return result;
        }
        if (String.isBlank(req.slackChannelId)) {
            result.success = false;
            result.message = 'Slack Channel ID is required.';
            return result;
        }

        Http http = new Http();
        List<String> errors = new List<String>();
        Integer successCount = 0;
        String channelId = req.slackChannelId;

        for (String userId : req.slackUserIds) {
            if (String.isBlank(userId)) continue;

            HttpRequest kickReq = new HttpRequest();
            kickReq.setEndpoint(SLACK_KICK_ENDPOINT);
            kickReq.setMethod('POST');
            kickReq.setHeader('Authorization', 'Bearer ' + req.slackToken);
            kickReq.setHeader('Content-Type', 'application/json');

            Map<String, String> payload = new Map<String, String>{
                'channel' => channelId,
                'user' => userId
            };
            kickReq.setBody(JSON.serialize(payload));

            try {
                HttpResponse res = http.send(kickReq);
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Boolean ok = (Boolean) body.get('ok');
                if (res.getStatusCode() == 200 && ok == true) {
                    successCount++;
                } else {
                    String err = (String) body.get('error');
                    if (String.isNotBlank(err)) {
                        errors.add('User ' + userId + ': ' + err);
                    } else {
                        errors.add('User ' + userId + ': ' + res.getBody());
                    }
                }
            } catch (Exception e) {
                errors.add('User ' + userId + ': ' + e.getMessage());
            }
        }

        if (!errors.isEmpty()) {
            result.success = false;
            result.message = String.join(errors, '; ');
        } else {
            result.message = successCount + ' user(s) removed from channel.';
        }
        result.kicksSucceeded = successCount;
        result.errors = errors;
        return result;
    }

    public class RemoveSlackUsersRequest {
        @InvocableVariable(label='Slack Token' required=true description='OAuth token with channels:manage (or channels:write) and groups:write for private channels')
        public String slackToken;

        @InvocableVariable(label='Slack User IDs' required=true description='Collection of Slack user IDs to remove from the channel(s)')
        public List<String> slackUserIds;

        @InvocableVariable(label='Slack Channel ID' required=true description='The Slack channel ID (single text) to remove the users from')
        public String slackChannelId;
    }

    public class RemoveSlackUsersResult {
        @InvocableVariable(label='Success' description='True if all kick requests succeeded')
        public Boolean success;

        @InvocableVariable(label='Message' description='Summary or error message')
        public String message;

        @InvocableVariable(label='Kicks Succeeded' description='Number of users successfully removed')
        public Integer kicksSucceeded;

        @InvocableVariable(label='Errors' description='List of error messages for failed kicks')
        public List<String> errors;
    }
}
