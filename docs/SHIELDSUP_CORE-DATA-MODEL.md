# GRCToolKit — Core GRC Data Model

**Scope**: Scenario submission → AI analysis → control recommendations → HITL review → audit trail.
**Datastore**: Firestore (document model, nested subcollections).
**Status**: Draft spec — pairs with `pqc/DATABASE-SCHEMA.md` (PQC migration data, separate scope).

## Collection layout

```
scenarios/{scenarioId}
  └─ analyses/{analysisId}
       └─ recommendations/{recId}
            └─ reviews/{reviewId}
controls/{controlId}      ← top-level, reference data, seeded from OSCAL catalog
users/{userId}             ← top-level
auditTrail/{entryId}       ← top-level, flat, append-only
```

Nesting keeps "load a scenario with everything under it" to one collection-group read. Cross-cutting queries (e.g. "all recommendations citing SC-13") use Firestore **collection group queries** on `recommendations`.

---

## `users/{userId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | |
| `email` | string | yes | Must match email format; unique (enforce in Cloud Function, Firestore has no native unique constraint) |
| `role` | string enum | yes | `compliance_officer` \| `security_expert` \| `auditor` \| `admin` |
| `active` | boolean | yes | Default `true`. Soft-disable, never delete — preserves referential integrity for audit history |
| `createdAt` | timestamp | yes | Server-generated |

Doc ID = Firebase Auth UID.

---

## `scenarios/{scenarioId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| `submittedBy` | reference → `users` | yes | |
| `scenarioText` | string | yes | Cap at ~5,000 chars (validate client + rules) |
| `scenarioType` | string enum | yes | `standard` \| `pqc_migration` \| `quantum_risk`. Default `standard`; set by scenario-recognition keyword matching |
| `status` | string enum | yes | `submitted` → `analyzed` → `under_review` → `closed`. Default `submitted` |
| `submittedAt` | timestamp | yes | Server-generated |
| `closedAt` | timestamp | no | Set when `status` → `closed` |

---

## `scenarios/{id}/analyses/{analysisId}`

AI is the only writer for this collection (via Cloud Function calling Gemini) — never written directly by client.

| Field | Type | Required | Notes |
|---|---|---|---|
| `model` | string | yes | e.g. `gemini-2.5-flash` |
| `analyzedAt` | timestamp | yes | |
| `keywords` | array\<string\> | yes | Extracted scenario keywords |
| `confidenceScore` | number | yes | 0–100. **Immutable once written** — this is the AI's original output |
| `confidenceFactors` | map | yes | `{ keywordMatch, controlRelevance, scenarioComplexity, historicalAccuracy }`, each 0–1 |
| `tier` | string enum | yes | `tier1_automated` (>90) \| `tier2_review` (70–90) \| `tier3_guided` (<70). Derived from `confidenceScore`, **immutable** |
| `rawResponse` | string | no | Raw Gemini JSON, for debugging/audit. Truncate/omit if it risks the 1MB doc limit |

A scenario can be re-analyzed (new model, manual re-run) — each run is a new `analyses` doc, never an overwrite. This preserves history for the "Feedback Impact" / accuracy-trend KPIs in the HITL framework.

---

## `controls/{controlId}`

Reference data. `controlId` (doc ID) = NIST control ID, e.g. `AC-3`, `SC-13`. Seeded once from `oscal/catalog/`; writable only by an admin seed script, never by the app at request time.

| Field | Type | Required | Notes |
|---|---|---|---|
| `family` | string | yes | e.g. `Access Control` |
| `title` | string | yes | |
| `description` | string | yes | |
| `csfMapping` | array\<string\> | no | CSF 2.0 function/category IDs |
| `pqcRelated` | boolean | yes | Default `false`. `true` for SC-12, SC-13, SC-17, etc. |
| `source` | string | yes | Default `"NIST SP 800-53 R5 OSCAL catalog"` |

---

## `.../analyses/{id}/recommendations/{recId}`

| Field | Type | Required | Notes |
|---|---|---|---|
| `controlId` | reference → `controls` | yes | |
| `controlSnapshot` | map | yes | `{ title, family }` — denormalized copy at recommendation time, avoids a join on every render |
| `rationale` | string | yes | AI-generated explanation |
| `aiConfidence` | number | yes | 0–100, **immutable** |
| `status` | string enum | yes | `pending_review` \| `approved` \| `rejected` \| `modified`. Default `pending_review` |

`status` only changes via a review write (ideally inside the same Cloud Function transaction that writes the review doc — see rules below).

---

## `.../recommendations/{id}/reviews/{reviewId}`

Reviews are **append-only** — a correction is a new review doc, never an edit to an old one. This is what makes the audit trail trustworthy.

| Field | Type | Required | Notes |
|---|---|---|---|
| `reviewerId` | reference → `users` | yes | |
| `decision` | string enum | yes | `approved` \| `rejected` \| `modified` |
| `reviewerConfidence` | number | no | 0–100. Only set if the reviewer overrides the AI's `aiConfidence`. Original AI value is untouched on the parent doc |
| `reviewerTier` | string enum | no | Only set if the reviewer overrides the AI's `tier`. Same immutability principle |
| `feedback` | string | no | Free-text, feeds the AI feedback loop |
| `corrections` | array\<map\> | no | `{ field, oldValue, newValue }` structured diffs, for training data |
| `reviewedAt` | timestamp | yes | Server-generated |

This keeps the AI's original output permanently intact for accuracy measurement, while giving reviewers a place to record what they'd change — exactly the "track both" model.

---

## `auditTrail/{entryId}`

Flat and generic on purpose: HITL-FRAMEWORK.md requires OSCAL-formatted, **immutable**, 7-year-retained logs queryable across any entity type. A flat collection with the right composite indexes beats per-entity audit tables for that.

| Field | Type | Required | Notes |
|---|---|---|---|
| `entityType` | string enum | yes | `scenario` \| `analysis` \| `recommendation` \| `review` |
| `entityId` | string | yes | Doc ID of the referenced entity |
| `entityPath` | string | yes | Full Firestore path, for direct lookup |
| `action` | string | yes | e.g. `created`, `status_changed`, `reviewed` |
| `actorId` | string | yes | `users/{userId}` or literal `"system"` |
| `oscalObservation` | map | no | OSCAL-formatted observation object, per HITL-FRAMEWORK.md §4 |
| `timestamp` | timestamp | yes | Server-generated |

Written only by trusted backend code (Cloud Functions triggered on writes to the other collections) — never directly by the client.

---

## Firestore security rules (sketch)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() { return request.auth != null; }
    function role() { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role; }
    function isReviewer() { return role() in ['compliance_officer', 'security_expert']; }
    function isAuditor() { return role() in ['auditor', 'admin']; }

    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if false; // admin only, via Cloud Function
    }

    match /controls/{controlId} {
      allow read: if isSignedIn();
      allow write: if false; // seed script only
    }

    match /scenarios/{scenarioId} {
      allow create: if isSignedIn();
      allow read: if isSignedIn();
      allow update: if isSignedIn() &&
        (resource.data.submittedBy == /databases/$(database)/documents/users/$(request.auth.uid) || isReviewer());

      match /analyses/{analysisId} {
        allow read: if isSignedIn();
        allow write: if false; // Cloud Function only (calls Gemini)

        match /recommendations/{recId} {
          allow read: if isSignedIn();
          allow write: if false; // status changes go through the review-write Cloud Function

          match /reviews/{reviewId} {
            allow create: if isReviewer();
            allow read: if isSignedIn();
            allow update, delete: if false; // append-only
          }
        }
      }
    }

    match /auditTrail/{entryId} {
      allow read: if isAuditor();
      allow write: if false; // Cloud Function only
      allow update, delete: if false; // immutable
    }
  }
}
```

## Composite indexes to create

| Collection | Fields | Purpose |
|---|---|---|
| `recommendations` (group) | `controlId` asc, `status` asc | "All open recommendations citing control X" |
| `auditTrail` | `entityType` asc, `timestamp` desc | Audit queries by entity type |
| `auditTrail` | `actorId` asc, `timestamp` desc | "Everything reviewer Y did" |
| `scenarios` | `status` asc, `submittedAt` desc | Dashboard: open scenarios queue |

---

## Open items

- **Email uniqueness** — Firestore has no native unique constraint; enforce via a Cloud Function check on `users` create, or key `users` docs by email hash.
- **`rawResponse` size** — Gemini's structured JSON output could push an `analyses` doc close to Firestore's 1MB limit on complex scenarios. Consider storing large raw responses in Cloud Storage with a reference instead.
- **7-year retention** — Firestore has no built-in WORM/retention lock. If regulatory retention needs to be provably immutable (not just rules-enforced), consider mirroring `auditTrail` writes to a Cloud Storage bucket with a retention policy, or BigQuery export.
