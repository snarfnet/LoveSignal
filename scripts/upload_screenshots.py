#!/usr/bin/env python3
import os, sys, time, json, hashlib, jwt, requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_VERSION = os.environ.get("APP_VERSION", "1.1")
SCREENSHOT_DIR = os.environ.get("SCREENSHOT_DIR", "AppStoreScreenshots")
BUNDLE_ID = "com.tokyonasu.LoveSignal"

key_path = os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")
with open(key_path) as f:
    private_key = f.read()

def get_token():
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})

def api(method, path, data=None):
    url = f"https://api.appstoreconnect.apple.com/v1/{path}"
    headers = {"Authorization": f"Bearer {get_token()}", "Content-Type": "application/json"}
    r = getattr(requests, method)(url, headers=headers, json=data)
    return r

# Find app
r = api("get", f"apps?filter[bundleId]={BUNDLE_ID}")
app_id = r.json()["data"][0]["id"]

# Find version
r = api("get", f"apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=1&sort=-versionString")
version_id = r.json()["data"][0]["id"]

# Get localizations
r = api("get", f"appStoreVersions/{version_id}/appStoreVersionLocalizations")
locs = r.json().get("data", [])

DISPLAY_TYPES = {
    "": "APP_IPHONE_67",
    "iphone_65": "APP_IPHONE_65",
    "ipad_129": "APP_IPAD_PRO_129",
}

for subdir, display_type in DISPLAY_TYPES.items():
    ss_path = os.path.join(SCREENSHOT_DIR, subdir) if subdir else SCREENSHOT_DIR
    if not os.path.isdir(ss_path):
        continue
    pngs = sorted([f for f in os.listdir(ss_path) if f.endswith(".png")])
    if not pngs:
        continue
    print(f"\nUploading {len(pngs)} screenshots for {display_type} from {ss_path}")

    for loc in locs:
        loc_id = loc["id"]
        locale = loc["attributes"]["locale"]

        # Get existing screenshot set
        r = api("get", f"appStoreVersionLocalizations/{loc_id}/appScreenshotSets?filter[screenshotDisplayType]={display_type}")
        sets = r.json().get("data", [])

        if sets:
            set_id = sets[0]["id"]
            # Delete existing screenshots
            r = api("get", f"appScreenshotSets/{set_id}/appScreenshots")
            for ss in r.json().get("data", []):
                api("delete", f"appScreenshots/{ss['id']}")
        else:
            r = api("post", "appScreenshotSets", {
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": display_type},
                    "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}
                }
            })
            set_id = r.json()["data"]["id"]

        for idx, png in enumerate(pngs):
            filepath = os.path.join(ss_path, png)
            filesize = os.path.getsize(filepath)
            with open(filepath, "rb") as f:
                checksum = hashlib.md5(f.read()).hexdigest()

            r = api("post", "appScreenshots", {
                "data": {
                    "type": "appScreenshots",
                    "attributes": {"fileName": png, "fileSize": filesize, "sourceFileChecksum": checksum},
                    "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}
                }
            })
            if r.status_code != 201:
                print(f"  Failed to reserve {png}: {r.status_code}")
                continue

            ss_data = r.json()["data"]
            ss_id = ss_data["id"]
            upload_ops = ss_data["attributes"].get("uploadOperations", [])

            with open(filepath, "rb") as f:
                file_data = f.read()

            for op in upload_ops:
                headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
                offset = op["offset"]
                length = op["length"]
                requests.put(op["url"], headers=headers, data=file_data[offset:offset+length])

            api("patch", f"appScreenshots/{ss_id}", {
                "data": {"type": "appScreenshots", "id": ss_id, "attributes": {"uploaded": True, "sourceFileChecksum": checksum}}
            })
            print(f"  Uploaded {png} for {locale}")

print("\nDone!")
