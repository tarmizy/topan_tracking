"""Sync the Google Play store listing from play/listing/<language>/*.txt.

Each language folder holds title.txt (max 30 chars), short_description.txt
(max 80) and full_description.txt (max 4000). The script opens an edit,
updates every language found, and commits the edit.

Credentials: the service account JSON in the PLAY_SERVICE_ACCOUNT_JSON
environment variable (never written to disk).
"""

import argparse
import json
import os
from pathlib import Path
import sys

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

SCOPE = "https://www.googleapis.com/auth/androidpublisher"
LIMITS = {"title": 30, "shortDescription": 80, "fullDescription": 4000}
FILES = {
    "title": "title.txt",
    "shortDescription": "short_description.txt",
    "fullDescription": "full_description.txt",
}


def read_listings(root):
    listings = {}
    for folder in sorted(p for p in root.iterdir() if p.is_dir()):
        listing = {}
        for field, name in FILES.items():
            text = (folder / name).read_text(encoding="utf-8").strip()
            if len(text) > LIMITS[field]:
                raise SystemExit(
                    f"{folder.name}/{name} is {len(text)} chars; "
                    f"Google Play allows {LIMITS[field]}"
                )
            listing[field] = text
        listings[folder.name] = listing
    if not listings:
        raise SystemExit(f"No listing folders found in {root}")
    return listings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", required=True)
    parser.add_argument("--listing-dir", default="play/listing", type=Path)
    parser.add_argument("--check", action="store_true", help="validate only")
    args = parser.parse_args()

    listings = read_listings(args.listing_dir)
    if args.check:
        for language, listing in listings.items():
            print(f"{language}: {listing['title']!r} OK")
        return

    info = json.loads(os.environ["PLAY_SERVICE_ACCOUNT_JSON"])
    credentials = service_account.Credentials.from_service_account_info(
        info, scopes=[SCOPE]
    )
    service = build("androidpublisher", "v3", credentials=credentials, cache_discovery=False)
    edits = service.edits()

    try:
        edit_id = edits.insert(packageName=args.package, body={}).execute()["id"]
        for language, listing in listings.items():
            edits.listings().update(
                packageName=args.package,
                editId=edit_id,
                language=language,
                body={"language": language, **listing},
            ).execute()
            print(f"Updated {language} listing: {listing['title']}")
        edits.commit(packageName=args.package, editId=edit_id).execute()
    except HttpError as error:
        print(f"::error::Google Play listing update failed: {error}", file=sys.stderr)
        raise SystemExit(1)
    print("Store listing committed.")


if __name__ == "__main__":
    main()
