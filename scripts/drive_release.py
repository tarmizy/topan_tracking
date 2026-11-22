"""Configure and publish the Topan Tracking APK on Google Drive."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
from zipfile import ZipFile

from google.auth.exceptions import RefreshError
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload


DRIVE_SCOPE = "https://www.googleapis.com/auth/drive.file"
APK_MIME_TYPE = "application/vnd.android.package-archive"
FILE_FIELDS = "id,appProperties,sha256Checksum,md5Checksum,webViewLink,trashed"
REPO_PROPERTY = "topanReleaseRepository"
VERSION_PROPERTY = "topanVersionCode"
TAG_PROPERTY = "topanReleaseTag"


def apk_checksums(path):
    with ZipFile(path) as apk:
        apk.getinfo("AndroidManifest.xml")
    hashes = {
        "sha256Checksum": hashlib.sha256(),
        "md5Checksum": hashlib.md5(usedforsecurity=False),
    }
    with path.open("rb") as apk:
        while chunk := apk.read(1024 * 1024):
            for checksum in hashes.values():
                checksum.update(chunk)
    return {key: checksum.hexdigest() for key, checksum in hashes.items()}


def matches_apk(file, checksums):
    for key, expected in checksums.items():
        if actual := file.get(key):
            return actual == expected
    return False


def upload(request):
    response = None
    while response is None:
        _, response = request.next_chunk(num_retries=3)
    return response


def apk_media(path):
    return MediaFileUpload(
        str(path), mimetype=APK_MIME_TYPE, resumable=True, chunksize=8 * 1024 * 1024
    )


def setup(args):
    from google_auth_oauthlib.flow import InstalledAppFlow

    checksums = apk_checksums(args.apk)
    subprocess.run(["gh", "auth", "status", "--hostname", "github.com"], check=True)
    flow = InstalledAppFlow.from_client_secrets_file(
        str(args.client_secrets), scopes=[DRIVE_SCOPE]
    )
    credentials = flow.run_local_server(port=0, prompt="consent", access_type="offline")
    if not credentials.refresh_token:
        raise SystemExit("Google did not return a refresh token. Repeat authorization.")

    files = build("drive", "v3", credentials=credentials).files()
    result = files.list(
        q=f"trashed = false and appProperties has {{ key = '{REPO_PROPERTY}' and value = '{args.repo}' }}",
        fields=f"nextPageToken,files({FILE_FIELDS})",
    ).execute(num_retries=3)
    matches = result.get("files", [])
    if len(matches) > 1 or result.get("nextPageToken"):
        raise SystemExit("Drive has multiple release files for this repo. Keep a single file before re-running setup.")
    if matches:
        release = matches[0]
    else:
        release = upload(files.create(
            body={
                "name": "topan-tracking.apk",
                "appProperties": {REPO_PROPERTY: args.repo},
            },
            media_body=apk_media(args.apk),
            fields=FILE_FIELDS,
        ))
        if not matches_apk(release, checksums):
            raise SystemExit("Drive did not confirm the initial APK checksum.")

    oauth = json.dumps({
        "client_id": credentials.client_id,
        "client_secret": credentials.client_secret,
        "refresh_token": credentials.refresh_token,
    })
    subprocess.run(
        ["gh", "secret", "set", "TOPAN_DRIVE_OAUTH", "--repo", args.repo],
        input=oauth,
        text=True,
        check=True,
    )
    subprocess.run(
        ["gh", "variable", "set", "TOPAN_DRIVE_FILE_ID", "--repo", args.repo,
         "--body", release["id"]],
        check=True,
    )
    print(f"Drive release file: {release.get('webViewLink') or drive_link(release['id'])}")


def drive_link(file_id):
    return f"https://drive.google.com/file/d/{file_id}/view"


def publish(args):
    oauth = os.environ.get("TOPAN_DRIVE_OAUTH")
    file_id = os.environ.get("TOPAN_DRIVE_FILE_ID")
    if not oauth or not file_id:
        raise SystemExit("Set up TOPAN_DRIVE_OAUTH and TOPAN_DRIVE_FILE_ID before publishing.")

    checksums = apk_checksums(args.apk)
    credentials = Credentials.from_authorized_user_info(json.loads(oauth), scopes=[DRIVE_SCOPE])
    files = build("drive", "v3", credentials=credentials).files()
    current = files.get(fileId=file_id, fields=FILE_FIELDS, supportsAllDrives=True).execute(
        num_retries=3
    )
    current_properties = current.get("appProperties", {})
    if current.get("trashed") or current_properties.get(REPO_PROPERTY) != args.repo:
        raise SystemExit("The configured Drive file does not belong to this release pipeline.")

    current_version = int(current_properties.get(VERSION_PROPERTY, "0"))
    if current_version > args.version_code:
        print("A newer APK is already on Drive. This run did not change it.")
        return
    if current_version == args.version_code:
        if current_properties.get(TAG_PROPERTY) == args.tag and matches_apk(current, checksums):
            print(f"{args.tag} is already on Drive with the same checksum.")
            return
        raise SystemExit("This Android version code is already published with different APK content.")

    updated = upload(files.update(
        fileId=file_id,
        body={"appProperties": {
            REPO_PROPERTY: args.repo,
            VERSION_PROPERTY: str(args.version_code),
            TAG_PROPERTY: args.tag,
        }},
        media_body=apk_media(args.apk),
        fields=FILE_FIELDS,
        supportsAllDrives=True,
    ))
    if updated.get("id") != file_id or not matches_apk(updated, checksums):
        raise SystemExit("Drive did not confirm the updated APK file ID and checksum.")
    print(f"Published {args.tag} to Google Drive and verified its checksum.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    setup_command = commands.add_parser("setup", help="Authorize Drive and configure GitHub")
    setup_command.add_argument("--client-secrets", required=True, type=Path)
    publish_command = commands.add_parser("publish", help="Update the existing release APK")
    publish_command.add_argument("--tag", required=True)
    publish_command.add_argument("--version-code", required=True, type=int)
    for command in (setup_command, publish_command):
        command.add_argument("--apk", required=True, type=Path)
        command.add_argument("--repo", required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+", args.repo):
        parser.error("--repo must be a GitHub owner/repository name")

    try:
        if args.command == "setup":
            setup(args)
        else:
            if args.version_code < 1:
                parser.error("--version-code must be positive")
            publish(args)
    except RefreshError:
        raise SystemExit("Google authorization expired or was revoked. Run Drive setup again.") from None
    except HttpError as error:
        raise SystemExit(f"Google Drive API returned HTTP {error.resp.status}. Check Drive access.") from None


if __name__ == "__main__":
    main()
