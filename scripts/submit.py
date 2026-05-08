#!/usr/bin/env python3
import os, sys, time, json, hashlib, jwt, requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_VERSION = os.environ.get("APP_VERSION", "1.1")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "1")
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

# ── Find app ──
r = api("get", f"apps?filter[bundleId]={BUNDLE_ID}")
apps = r.json().get("data", [])
if not apps:
    print(f"App not found for bundle id {BUNDLE_ID}")
    sys.exit(1)
app_id = apps[0]["id"]
print(f"App ID: {app_id}")

# ── Wait for build ──
print("Waiting for build processing...")
build_id = None
for attempt in range(60):
    r = api("get", f"builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&sort=-uploadedDate&limit=1")
    builds = r.json().get("data", [])
    if builds:
        build_id = builds[0]["id"]
        print(f"Build ready: {build_id}")
        break
    print(f"  Attempt {attempt+1}/60 - waiting 30s...")
    time.sleep(30)
if not build_id:
    print("Build not ready after 30 minutes")
    sys.exit(1)

# ── Export compliance ──
r = api("patch", f"builds/{build_id}", {
    "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
})
print(f"Export compliance: {r.status_code}")

# ── Cancel existing review submissions ──
canceled = False
for state in ["UNRESOLVED_ISSUES", "READY_FOR_REVIEW", "WAITING_FOR_REVIEW"]:
    r = api("get", f"apps/{app_id}/reviewSubmissions?filter[state]={state}")
    for sub in r.json().get("data", []):
        sid = sub["id"]
        api("patch", f"reviewSubmissions/{sid}", {
            "data": {"type": "reviewSubmissions", "id": sid, "attributes": {"canceled": True}}
        })
        print(f"Canceled submission {sid}")
        canceled = True
if canceled:
    time.sleep(15)

# ── Delete old PREPARE_FOR_SUBMISSION version, create fresh ──
r = api("get", f"apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION&filter[platform]=IOS")
for v in r.json().get("data", []):
    vid = v["id"]
    dr = api("delete", f"appStoreVersions/{vid}")
    print(f"Deleted version {vid}: {dr.status_code}")
    time.sleep(5)

r = api("post", "appStoreVersions", {
    "data": {
        "type": "appStoreVersions",
        "attributes": {"platform": "IOS", "versionString": APP_VERSION},
        "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}
    }
})
if r.status_code != 201:
    print(f"Create version failed: {r.status_code} {r.text[:500]}")
    sys.exit(1)
version_id = r.json()["data"]["id"]
print(f"Created version: {version_id}")

# ── Set build ──
r = api("patch", f"appStoreVersions/{version_id}/relationships/build", {
    "data": {"type": "builds", "id": build_id}
})
print(f"Set build: {r.status_code}")

# ── Update whatsNew ──
r = api("get", f"appStoreVersions/{version_id}/appStoreVersionLocalizations")
locs = r.json().get("data", [])
for loc in locs:
    loc_id = loc["id"]
    api("patch", f"appStoreVersionLocalizations/{loc_id}", {
        "data": {
            "type": "appStoreVersionLocalizations", "id": loc_id,
            "attributes": {"whatsNew": "UIの改善とパフォーマンス向上"}
        }
    })

# ── Upload screenshots ──
DISPLAY_TYPES = {
    "": "APP_IPHONE_67",
    "iphone_65": "APP_IPHONE_65",
    "ipad_129": "APP_IPAD_PRO_3GEN_129",
}

for subdir, display_type in DISPLAY_TYPES.items():
    ss_path = os.path.join(SCREENSHOT_DIR, subdir) if subdir else SCREENSHOT_DIR
    if not os.path.isdir(ss_path):
        continue
    pngs = sorted([f for f in os.listdir(ss_path) if f.endswith(".png")])
    if not pngs:
        continue
    print(f"\nUploading {len(pngs)} screenshots for {display_type}")

    for loc in locs:
        loc_id = loc["id"]
        locale = loc["attributes"]["locale"]

        # Create screenshot set
        r = api("post", "appScreenshotSets", {
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display_type},
                "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}
            }
        })
        if r.status_code != 201:
            print(f"  Create set failed ({locale}): {r.status_code}")
            continue
        set_id = r.json()["data"]["id"]

        for png in pngs:
            filepath = os.path.join(ss_path, png)
            filesize = os.path.getsize(filepath)
            with open(filepath, "rb") as f:
                checksum = hashlib.md5(f.read()).hexdigest()

            r = api("post", "appScreenshots", {
                "data": {
                    "type": "appScreenshots",
                    "attributes": {"fileName": png, "fileSize": filesize},
                    "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}
                }
            })
            if r.status_code != 201:
                print(f"  Reserve {png} failed: {r.status_code} {r.text[:200]}")
                continue

            ss_data = r.json()["data"]
            ss_id = ss_data["id"]
            upload_ops = ss_data["attributes"].get("uploadOperations", [])

            with open(filepath, "rb") as f:
                file_data = f.read()

            for op in upload_ops:
                hdrs = {h["name"]: h["value"] for h in op["requestHeaders"]}
                requests.put(op["url"], headers=hdrs, data=file_data[op["offset"]:op["offset"]+op["length"]])

            api("patch", f"appScreenshots/{ss_id}", {
                "data": {"type": "appScreenshots", "id": ss_id, "attributes": {"uploaded": True, "sourceFileChecksum": checksum}}
            })
            print(f"  {png} -> {locale}")

# ── Wait for screenshot processing ──
print("\nWaiting for screenshot processing...")
for wait in range(20):
    processing = False
    for loc in locs:
        r2 = api("get", f"appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")
        for ss_set in r2.json().get("data", []):
            r3 = api("get", f"appScreenshotSets/{ss_set['id']}/appScreenshots")
            for ss in r3.json().get("data", []):
                state = ss["attributes"].get("assetDeliveryState", {}).get("state", "")
                if state not in ["COMPLETE", "UPLOAD_COMPLETE"]:
                    processing = True
    if not processing:
        print("Screenshots ready!")
        break
    print(f"  Processing... ({wait+1}/20, 30s)")
    time.sleep(30)

# ── Create review submission ──
submission_id = None
for attempt in range(5):
    r = api("post", "reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
    })
    if r.status_code == 201:
        submission_id = r.json()["data"]["id"]
        print(f"ReviewSubmission: {submission_id}")
        break
    print(f"Create submission {attempt+1}/5: {r.status_code} {r.text[:300]}")
    time.sleep(15)

if not submission_id:
    print("Could not create review submission")
    sys.exit(1)

# ── Add version and submit ──
r = api("post", "reviewSubmissionItems", {
    "data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
        }
    }
})
print(f"Add item: {r.status_code}")
if r.status_code != 201:
    print(f"  Error: {r.text[:1000]}")
    sys.exit(1)

r = api("patch", f"reviewSubmissions/{submission_id}", {
    "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
})
if r.status_code == 200:
    print(f"Submitted! State: {r.json()['data']['attributes']['state']}")
else:
    print(f"Submit failed: {r.status_code} {r.text[:1000]}")
    sys.exit(1)
