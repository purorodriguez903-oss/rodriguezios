import os
import json
import requests
import dotenv

dotenv.load_dotenv()
token = os.getenv("BOT_TOKEN")
channel_id = "1569597987855007754"

headers = {"Authorization": f"Bot {token}"}
url = f"https://discord.com/api/v10/channels/{channel_id}/messages?limit=100"

res = requests.get(url, headers=headers)
print("HTTP Status:", res.status_code)
if res.status_code != 200:
    print("Error response:", res.text)
    exit(1)

messages = res.json()
print(f"Total messages retrieved: {len(messages)}")

for m in messages:
    print(f"Message ID: {m.get('id')} by {m.get('author', {}).get('username')}:")
    print("  Content:", repr(m.get('content')))
    print("  Attachments:", m.get('attachments'))
    print("  Embeds:", len(m.get('embeds', [])))
    for e in m.get('embeds', []):
        print("    Embed:", e.get('title'), e.get('url'), e.get('image'))
for msg in messages:
    content = msg.get("content", "").strip()
    atts = msg.get("attachments", [])
    author = msg.get("author", {}).get("username", "")
    for att in atts:
        filename = att.get("filename", "")
        att_url = att.get("url", "")
        content_type = att.get("content_type", "")
        size = att.get("size", 0)
        width = att.get("width")
        height = att.get("height")
        all_attachments.append({
            "msg_id": msg.get("id"),
            "author": author,
            "text": content,
            "filename": filename,
            "url": att_url,
            "content_type": content_type,
            "size": size,
            "width": width,
            "height": height
        })

print(f"Total attachments found: {len(all_attachments)}")
for idx, a in enumerate(all_attachments, 1):
    print(f"{idx}. {a['filename']} ({a['width']}x{a['height']}, {a['size']}b) - Text: '{a['text']}'")

with open("discord_attachments.json", "w", encoding="utf-8") as f:
    json.dump(all_attachments, f, indent=2)
print("Saved list to discord_attachments.json")
