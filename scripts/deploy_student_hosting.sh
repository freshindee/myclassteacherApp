#!/usr/bin/env bash
# Deploy Flutter web build to Firebase Hosting site "myclassteacher-studentweb" only.
# Does not deploy to the default site (my-class-teacher-c833a.web.app).
# See FIREBASE_HOSTING.md for maintaining both web apps.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --release
firebase deploy --only hosting:studentweb
