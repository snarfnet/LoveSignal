#!/usr/bin/env python3
import os, sys, time, json, jwt, requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
APP_VERSION = os.environ.get("APP_VERSION", "1.1")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "1")
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
apps = r.json().get("data", [])
if not apps:
    print(f"App not found for bundle id {BUNDLE_ID}")
    sys.exit(1)
app_id = apps[0]["id"]
print(f"App ID: {app_id}")

# Wait for build to be processed
print("Waiting for build processing...")
for attempt in range(60):
    r = api("get", f"builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&sort=-uploadedDate&limit=1")
    builds = r.json().get("data", [])
    if builds:
        build_id = builds[0]["id"]
        print(f"Build ready: {build_id}")
        break
    print(f"  Attempt {attempt+1}/60 - waiting 30s...")
    time.sleep(30)
else:
    print("Build not ready after 30 minutes")
    sys.exit(1)

# Get or create version
r = api("get", f"apps/{app_id}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION,REJECTED,DEVELOPER_REJECTED&filter[platform]=IOS")
versions = r.json().get("data", [])
if versions:
    version_id = versions[0]["id"]
    print(f"Existing version: {version_id}")
else:
    r = api("post", "appStoreVersions", {
        "data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": APP_VERSION},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}
        }
    })
    version_id = r.json()["data"]["id"]
    print(f"Created version: {version_id}")

# Set build
r = api("patch", f"appStoreVersions/{version_id}/relationships/build", {
    "data": {"type": "builds", "id": build_id}
})
print(f"Set build: {r.status_code}")

# Update whatsNew
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

# Cancel any existing review submissions
for state in ["UNRESOLVED_ISSUES", "READY_FOR_REVIEW"]:
    r = api("get", f"apps/{app_id}/reviewSubmissions?filter[state]={state}")
    for sub in r.json().get("data", []):
        sid = sub["id"]
        api("patch", f"reviewSubmissions/{sid}", {"data": {"type": "reviewSubmissions", "id": sid, "attributes": {"canceled": True}}})
        print(f"Canceled existing submission {sid}")
    time.sleep(5)

# Create review submission
r = api("post", "reviewSubmissions", {
    "data": {"type": "reviewSubmissions", "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}
})
if r.status_code != 201:
    print(f"Create reviewSubmission failed: {r.status_code} {r.text[:500]}")
    sys.exit(1)
submission_id = r.json()["data"]["id"]
print(f"ReviewSubmission created: {submission_id}")

# Add version to submission
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

# Submit for review
r = api("patch", f"reviewSubmissions/{submission_id}", {
    "data": {"type": "reviewSubmissions", "id": submission_id, "attributes": {"submitted": True}}
})
print(f"Submit: {r.status_code} {r.text[:500]}")
