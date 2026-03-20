public with sharing class SendSlackBKMessage {
    private static final String LOG_PREFIX = 'SendSlackBKMessage';

    @InvocableMethod(
        label='Send Slack Block Kit Message'
        description='Sends a formatted Block Kit message to Slack. Use Success and Error Message outputs in Flow to branch or log.'
        callout=true
    )
    public static List<MessageResult> sendMessage(List<RequestData> requests) {
        List<MessageResult> results = new List<MessageResult>();
        for (RequestData req : requests) {
            results.add(sendToSlack(req.channelId, req.botToken, req.blocks, req.threadTs));
        }
        return results;
    }

    private static MessageResult sendToSlack(String channelId, String botToken, String blocks, String threadTs) {
        MessageResult out = new MessageResult();
        out.success = false;
        try {
            if (String.isEmpty(channelId) || String.isEmpty(botToken) || String.isEmpty(blocks)) {
                out.errorMessage = 'Missing required parameters: channel ID, bot token, and blocks are mandatory.';
                logError(out.errorMessage);
                return out;
            }

            Map<String, Object> payload = new Map<String, Object>();
            payload.put('channel', channelId);

            try {
                payload.put('blocks', JSON.deserializeUntyped(blocks));
            } catch (Exception e) {
                out.errorMessage = 'Invalid JSON in blocks: ' + e.getMessage();
                logError(out.errorMessage);
                return out;
            }

            if (!String.isEmpty(threadTs)) {
                payload.put('thread_ts', threadTs);
            }

            String requestBody = JSON.serialize(payload);
            logInfo('Request channel=' + channelId + ' bodyLength=' + requestBody.length());

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://slack.com/api/chat.postMessage');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + botToken);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(requestBody);

            HttpResponse response = http.send(request);
            Integer status = response.getStatusCode();
            String body = response.getBody();
            logInfo('Response HTTP ' + status);

            if (status != 200) {
                out.errorMessage = 'HTTP ' + status + ': ' + truncateForLog(body);
                logError(out.errorMessage);
                return out;
            }

            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(body);
            Boolean ok = responseBody.containsKey('ok') && (Boolean) responseBody.get('ok');

            if (ok) {
                if (responseBody.containsKey('ts')) {
                    out.success = true;
                    out.messageTimestamp = (String) responseBody.get('ts');
                    logInfo('Message sent ts=' + out.messageTimestamp);
                } else {
                    out.errorMessage = 'Slack returned ok but no message timestamp (ts).';
                    logError(out.errorMessage + ' body=' + truncateForLog(body));
                }
            } else {
                Object err = responseBody.get('error');
                out.errorMessage = 'Slack API error: ' + (err != null ? String.valueOf(err) : 'unknown');
                logError(out.errorMessage + ' body=' + truncateForLog(body));
            }
        } catch (Exception e) {
            out.errorMessage = e.getTypeName() + ': ' + e.getMessage();
            logError(out.errorMessage);
        }
        return out;
    }

    private static void logInfo(String message) {
        System.debug(LoggingLevel.INFO, LOG_PREFIX + ' | ' + message);
    }

    private static void logError(String message) {
        System.debug(LoggingLevel.ERROR, LOG_PREFIX + ' | ' + message);
    }

    private static String truncateForLog(String s) {
        if (String.isBlank(s)) {
            return '';
        }
        Integer max = 2000;
        return s.length() > max ? s.substring(0, max) + '…' : s;
    }

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

    public class MessageResult {
        @InvocableVariable(label='Success' description='True when Slack accepted the message and a timestamp was returned.')
        public Boolean success;

        @InvocableVariable(label='Message Timestamp' description='Slack message ts when successful; use for threading.')
        public String messageTimestamp;

        @InvocableVariable(label='Error Message' description='Empty when successful; otherwise validation, HTTP, Slack API, or exception details.')
        public String errorMessage;
    }
}
