# 🚀 SendSlackBKMessage

This Apex class makes it easy to send formatted [Slack Block Kit](https://api.slack.com/block-kit) messages directly from Salesforce. It's designed to be reusable in Flows (both record-triggered and screen flows), supports threaded replies, and allows full control over Slack message blocks.

---

## ✨ Features

- ✅ Send rich Block Kit messages to any Slack channel.
- 🧵 Support for threaded messages using `thread_ts`.
- 🔄 Usable directly in **Record-Triggered Flows** or **Screen Flows**.
- 💬 Full message customization via JSON blocks input.
- 🔐 Secure integration using Remote Site Settings.

---

## 🔧 Setup Instructions

### 1. Add Slack to Remote Site Settings

Go to **Setup → Remote Site Settings** and click **"New Remote Site"**:

- **Remote Site Name**: `SlackAPI`
- **Remote Site URL**: `https://slack.com`
- ✅ **Active**: Checked

### 2. Deploy Apex Class

Deploy the class from this repo: `SendSlackBKMessage.cls`

Or create a new Apex class in your org:

```apex
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
            if (String.isEmpty(channelId) || String.isEmpty(botToken) || String.isEmpty(blocks)) {
                System.debug('Missing required parameters');
                return null;
            }

            Map<String, Object> payload = new Map<String, Object>();
            payload.put('channel', channelId);
            payload.put('blocks', JSON.deserializeUntyped(blocks));
            if (!String.isEmpty(threadTs)) {
                payload.put('thread_ts', threadTs);
            }

            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://slack.com/api/chat.postMessage');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + botToken);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(payload));

            HttpResponse response = new Http().send(request);
            System.debug('Slack Response: ' + response.getBody());

            if (response.getStatusCode() == 200) {
                Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if ((Boolean) res.get('ok')) {
                    return (String) res.get('ts');
                }
                System.debug('Slack error: ' + res.get('error'));
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        return null;
    }

    public class RequestData {
        @InvocableVariable(required=true)
        public String channelId;
        @InvocableVariable(required=true)
        public String botToken;
        @InvocableVariable(required=true)
        public String blocks;
        @InvocableVariable
        public String threadTs;
    }
}
