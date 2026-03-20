# 🚀 SendSlackBKMessage

This Apex class makes it easy to send formatted [Slack Block Kit](https://api.slack.com/block-kit) messages directly from Salesforce. It's designed to be reusable in Flows (both record-triggered and screen flows), supports threaded replies, and allows full control over Slack message blocks.

---

## ✨ Features

- ✅ Send rich Block Kit messages to any Slack channel.
- 🧵 Support for threaded messages using `thread_ts`.
- 🔄 Usable directly in **Record-Triggered Flows** or **Screen Flows**.
- 💬 Full message customization via JSON blocks input.
- 🔐 Secure integration using Remote Site Settings.
- 📊 **Flow outputs**: `Success`, `Message Timestamp`, and `Error Message` for decisions and logging.
- 📝 **Debug logs**: `INFO`/`ERROR` lines prefixed with `SendSlackBKMessage` (filter in Developer Console or Setup → Debug Logs).

---

## 🔧 Setup Instructions

### 1. Add Slack to Remote Site Settings

Go to **Setup → Remote Site Settings** and click **"New Remote Site"**:

- **Remote Site Name**: `SlackAPI`
- **Remote Site URL**: `https://slack.com`
- ✅ **Active**: Checked

### 2. Deploy Apex Class

Deploy the class from this repo: `SendSlackBKMessage.cls` (keep org copy in sync with this repo).

### Flow monitoring

After the action, use a **Decision** on **Success** (or on **Error Message** not empty). On failure, **Create Records** on a custom log object, send email, etc., using **Error Message**.

For troubleshooting, add a **Debug Log** for the running user (or integration user) and search for `SendSlackBKMessage`.
