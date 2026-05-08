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
    print(f"App not found"); sys.exit(1)
app_id = apps[0]["id"]
print(f"App ID: {app_id}")

# ── Wait for build ──
print("Waiting for build...")
build_id = None
for attempt in range(60):
    r = api("get", f"builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&sort=-uploadedDate&limit=1")
    builds = r.json().get("data", [])
    if builds:
        build_id = builds[0]["id"]
        print(f"Build ready: {build_id}")
        break
    print(f"  {attempt+1}/60 - 30s...")
    time.sleep(30)
if not build_id:
    print("Build not ready"); sys.exit(1)

# ── Export compliance ──
r = api("patch", f"builds/{build_id}", {
    "data": {"type": "builds", "id": build_id, "attributes": {"usesNonExemptEncryption": False}}
})
print(f"Export compliance: {r.status_code}")

# ── Cancel ALL review submissions ──
canceled = False
for state in ["UNRESOLVED_ISSUES", "READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "CANCELING"]:
    r = api("get", f"apps/{app_id}/reviewSubmissions?filter[state]={state}")
    for sub in r.json().get("data", []):
        sid = sub["id"]
        st = sub["attributes"]["state"]
        if st != "CANCELING":
            r2 = api("patch", f"reviewSubmissions/{sid}", {
                "data": {"type": "reviewSubmissions", "id": sid, "attributes": {"canceled": True}}
            })
            print(f"Cancel {sid} ({st}): {r2.status_code}")
        else:
            print(f"Already canceling: {sid}")
        canceled = True
if canceled:
    print("Waiting 60s for cancellations...")
    time.sleep(60)
    # Verify all canceled
    for state in ["READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "CANCELING"]:
        r = api("get", f"apps/{app_id}/reviewSubmissions?filter[state]={state}")
        remaining = r.json().get("data", [])
        if remaining:
            print(f"  Still {len(remaining)} in {state}, waiting 30s more...")
            time.sleep(30)

# ── Get or create version ──
r = api("get", f"apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION,REJECTED,DEVELOPER_REJECTED&filter[platform]=IOS")
versions = r.json().get("data", [])
if versions:
    version_id = versions[0]["id"]
    print(f"Using version: {version_id}")
else:
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

# ── Clean up ALL existing screenshot sets ──
print("Cleaning up old screenshots...")
for loc in locs:
    loc_id = loc["id"]
    r = api("get", f"appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
    for ss_set in r.json().get("data", []):
        set_id = ss_set["id"]
        # Delete all screenshots in this set
        r2 = api("get", f"appScreenshotSets/{set_id}/appScreenshots")
        for ss in r2.json().get("data", []):
            api("delete", f"appScreenshots/{ss['id']}")
        # Delete the set itself
        api("delete", f"appScreenshotSets/{set_id}")
print("Cleanup done, waiting 10s...")
time.sleep(10)

# ── Upload fresh screenshots ──
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
    print(f"\nUploading {len(pngs)} for {display_type}")

    for loc in locs:
        loc_id = loc["id"]
        locale = loc["attributes"]["locale"]

        r = api("post", "appScreenshotSets", {
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display_type},
                "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}
            }
        })
        if r.status_code != 201:
            print(f"  Create set failed ({locale}): {r.status_code} {r.text[:200]}")
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
print("\nWaiting for screenshots to process...")
for wait in range(20):
    processing = False
    for loc in locs:
        r2 = api("get", f"appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")
        for ss_set in r2.json().get("data", []):
            r3 = api("get", f"appScreenshotSets/{ss_set['id']}/appScreenshots")
            for ss in r3.json().get("data", []):
                ds = ss["attributes"].get("assetDeliveryState", {})
                state = ds.get("state", "")
                if state not in ["COMPLETE", "UPLOAD_COMPLETE"]:
                    processing = True
                    if wait == 0:
                        print(f"  {ss['id']}: {state}")
    if not processing:
        print("Screenshots ready!")
        break
    print(f"  Processing... ({wait+1}/20)")
    time.sleep(30)

# ── Submit: find or create review submission ──
submission_id = None

# First try to reuse an existing READY_FOR_REVIEW submission without items
r = api("get", f"apps/{app_id}/reviewSubmissions?filter[state]=READY_FOR_REVIEW&limit=10")
for sub in r.json().get("data", []):
    sid = sub["id"]
    # Check if it has items
    r2 = api("get", f"reviewSubmissions/{sid}/items")
    items = r2.json().get("data", [])
    if not items:
        submission_id = sid
        print(f"Reusing empty submission: {submission_id}")
        break
    else:
        # Has items - try to remove them and reuse
        for item in items:
            api("delete", f"reviewSubmissionItems/{item['id']}")
        submission_id = sid
        print(f"Cleared and reusing submission: {submission_id}")
        break

if not submission_id:
    # Try to create new one
    r = api("post", "reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
    })
    if r.status_code == 201:
        submission_id = r.json()["data"]["id"]
        print(f"Created submission: {submission_id}")
    else:
        print(f"Create failed: {r.status_code} {r.text[:500]}")
        sys.exit(1)

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
    print(f"  {r.text[:1000]}")
    sys.exit(1)

r = api("patch", f"reviewSubmissions/{submission_id}", {
    "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
})
if r.status_code == 200:
    print(f"Submitted! State: {r.json()['data']['attributes']['state']}")
else:
    print(f"Submit failed: {r.status_code} {r.text[:1000]}")
    sys.exit(1)
