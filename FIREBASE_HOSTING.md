# Two web apps on one Firebase project (`my-class-teacher-c833a`)

You use **one Firebase project** with **two Hosting sites**:

| App | Hosting site ID | Typical URL |
|-----|-----------------|-------------|
| **Original / main web** | `my-class-teacher-c833a` (default site) | `https://my-class-teacher-c833a.web.app` |
| **This student web** | `myclassteacher-studentweb` | `https://myclassteacher-studentweb.web.app` |

Deploying the student app from **this repository** only updates the **student** site. It does **not** upload to the default site.

---

## 1. One-time in Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com) → project **my-class-teacher-c833a** → **Hosting**.
2. Ensure the **default** site exists (it usually does).
3. **Add another site** with site ID **`myclassteacher-studentweb`** if it is not there yet.

---

## 2. Deploy **this** app (student web)

From **this** project root:

```bash
firebase use my-class-teacher-c833a
flutter build web --release
firebase deploy --only hosting:studentweb
```

Or:

```bash
./scripts/deploy_student_hosting.sh
```

Always use **`hosting:studentweb`** (or the script) so only the student URL is updated.

---

## 3. Deploy the **original** web app (other repo or folder)

Keep that app in a **separate folder** (or Git repo). Its `firebase.json` should use the **simple** hosting shape (one object, **no** `target`):

```json
{
  "hosting": {
    "public": "YOUR_BUILD_FOLDER",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

`.firebaserc`:

```json
{
  "projects": {
    "default": "my-class-teacher-c833a"
  }
}
```

Then from **that** folder:

```bash
firebase use my-class-teacher-c833a
firebase deploy --only hosting
```

That updates only the **default** site (`my-class-teacher-c833a.web.app`), not the student site.

---

## 4. Authentication

In **Authentication → Settings → Authorized domains**, include both:

- `my-class-teacher-c833a.web.app`
- `myclassteacher-studentweb.web.app`

so sign-in works on both URLs (same `firebase_options` / `projectId` is fine).

---

## Summary

- **Student app** → this repo → `firebase deploy --only hosting:studentweb`
- **Original app** → other folder → classic `firebase.json` + `firebase deploy --only hosting`

Never point both configs at the same `public` folder unless you intentionally want the same files on both sites.
