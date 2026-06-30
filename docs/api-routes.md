# API Routes Reference
## HostCompliant

All routes are Next.js App Router API routes (`/app/api/...`).  
All authenticated routes require a valid Supabase session cookie.  
All admin routes additionally require `user_profiles.role = 'admin'`.

Base path: `/api`

---

## Authentication

Authentication is handled by Supabase Auth. The Next.js middleware validates the session on every protected route. API routes call `createServerComponentClient` to verify the user.

No custom auth endpoints needed — use Supabase Auth UI or the Supabase JS client directly.

---

## Cities

### `GET /api/cities`
Returns all active cities.

**Auth:** Public  
**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Paris",
    "slug": "paris",
    "country": "France",
    "country_code": "FR",
    "regulatory_summary": "...",
    "last_reviewed_at": "2026-06-01T00:00:00Z",
    "compliance_item_count": 6
  }
]
```

---

### `GET /api/cities/[slug]`
Returns a city with all its active compliance items.

**Auth:** Public  
**Response:**
```json
{
  "id": "uuid",
  "name": "Paris",
  "slug": "paris",
  "country": "France",
  "country_code": "FR",
  "regulatory_summary": "...",
  "official_source_url": "https://...",
  "last_reviewed_at": "2026-06-01T00:00:00Z",
  "compliance_items": [
    {
      "id": "uuid",
      "category": "permits",
      "title": "Complete municipal declaration",
      "short_description": "...",
      "deadline_type": "one_time",
      "penalty_description": "Fine up to €450",
      "difficulty": 1,
      "is_mandatory": true
    }
  ],
  "recent_alerts": [
    {
      "id": "uuid",
      "title": "...",
      "severity": "warning",
      "published_at": "2026-05-15T00:00:00Z",
      "summary": "..."
    }
  ]
}
```

---

### `GET /api/cities/[slug]/alerts`
Returns all regulatory alerts for a city.

**Auth:** Public  
**Query params:** `?limit=20&offset=0`  
**Response:** Array of alert objects.

---

## Properties

### `GET /api/properties`
Returns all properties for the authenticated user.

**Auth:** Required  
**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Apartment Montmartre",
    "property_type": "entire_apartment",
    "city": {
      "id": "uuid",
      "name": "Paris",
      "slug": "paris",
      "country": "France"
    },
    "compliance_summary": {
      "total_items": 6,
      "done_items": 3,
      "overdue_items": 1,
      "pending_items": 2,
      "compliance_pct": 50.0
    },
    "next_deadline": {
      "item_title": "Tourist tax quarterly filing",
      "due_date": "2026-07-15"
    }
  }
]
```

---

### `POST /api/properties`
Creates a new property for the authenticated user.

**Auth:** Required  
**Subscription check:** Free tier: max 1 property. Solo/Host/Pro: as per plan.  
**Body:**
```json
{
  "name": "Apartment Montmartre",
  "city_id": "uuid",
  "property_type": "entire_apartment",
  "platforms": ["airbnb", "booking_com"]
}
```
**Response:** Created property object.  
**Side effect:** Automatically creates `compliance_status` rows for all active compliance items in the property's city that apply to the property type. Calculates `next_deadline_at` for each.

---

### `GET /api/properties/[id]`
Returns a single property with its full compliance checklist.

**Auth:** Required (must own property)  
**Response:**
```json
{
  "id": "uuid",
  "name": "Apartment Montmartre",
  "property_type": "entire_apartment",
  "city": { "...": "..." },
  "compliance_items": [
    {
      "compliance_status_id": "uuid",
      "compliance_item_id": "uuid",
      "category": "permits",
      "title": "Complete municipal declaration",
      "short_description": "...",
      "full_description": "...",
      "how_to_comply": "...",
      "official_url": "https://...",
      "penalty_description": "Fine up to €450",
      "difficulty": 1,
      "deadline_type": "one_time",
      "next_deadline_at": null,
      "status": "done",
      "completed_at": "2026-01-15T10:30:00Z",
      "notes": "Filed online",
      "documents": [
        {
          "id": "uuid",
          "original_filename": "declaration_confirmation.pdf",
          "created_at": "2026-01-15T10:30:00Z"
        }
      ]
    }
  ]
}
```

---

### `PUT /api/properties/[id]`
Updates property name or platforms.

**Auth:** Required (must own property)  
**Body:** Partial property fields (name, platforms only — city cannot be changed after creation).

---

### `DELETE /api/properties/[id]`
Soft-deletes a property (sets `is_active = false`).

**Auth:** Required (must own property)

---

## Compliance Statuses

### `PATCH /api/properties/[id]/items/[itemId]`
Updates the compliance status for one item on one property.

**Auth:** Required (must own property)  
**Body:**
```json
{
  "status": "done",
  "notes": "Filed online on 2026-01-15"
}
```
**Response:** Updated compliance status object.  
**Side effect:** When status changes to "done", sets `completed_at = now()`. Recalculates `next_deadline_at` for annual/quarterly items (moves to next cycle).

---

## Documents

### `POST /api/properties/[id]/documents`
Uploads a document for a property (tied to a specific compliance item or general).

**Auth:** Required (must own property)  
**Content-Type:** `multipart/form-data`  
**Body fields:**
- `file`: The file (PDF, JPG, PNG, max 10MB)
- `compliance_item_id`: UUID (optional — can be a general property document)

**Response:**
```json
{
  "id": "uuid",
  "original_filename": "hutb_license.pdf",
  "storage_path": "documents/{user_id}/{property_id}/hutb_license.pdf",
  "created_at": "2026-06-01T10:00:00Z"
}
```
**Storage:** Uploaded to Supabase Storage. A signed URL is generated for download (valid 1 hour).

---

### `GET /api/properties/[id]/documents`
Lists all documents for a property.

**Auth:** Required (must own property)  
**Response:** Array of document objects with signed download URLs.

---

### `DELETE /api/documents/[docId]`
Deletes a document from storage and database.

**Auth:** Required (must own document)

---

## Alerts

### `GET /api/alerts`
Returns all regulatory alerts for cities where the user has properties.

**Auth:** Required  
**Query params:** `?limit=20&offset=0&severity=critical`  
**Response:** Array of alert objects, sorted by `published_at` desc.

---

### `GET /api/alerts/[id]`
Returns a single alert with full text.

**Auth:** Public (alerts are public content)

---

## Dashboard

### `GET /api/dashboard`
Returns the data needed to render the main dashboard.

**Auth:** Required  
**Response:**
```json
{
  "overall_compliance_pct": 72.5,
  "properties_count": 2,
  "overdue_items": [
    {
      "property_id": "uuid",
      "property_name": "Apartment Montmartre",
      "item_title": "Tourist tax quarterly filing",
      "deadline_date": "2026-04-15",
      "days_overdue": 45
    }
  ],
  "upcoming_deadlines": [
    {
      "property_id": "uuid",
      "property_name": "Studio Amsterdam",
      "item_title": "Short-stay permit annual renewal",
      "deadline_date": "2026-09-01",
      "days_until": 63
    }
  ],
  "recent_alerts": [
    {
      "id": "uuid",
      "city_name": "Barcelona",
      "title": "HUTB renewal deadline extended to December 2026",
      "severity": "info",
      "published_at": "2026-05-20T00:00:00Z"
    }
  ]
}
```

---

## Account / Billing

### `GET /api/account`
Returns authenticated user's profile and subscription info.

**Auth:** Required

---

### `POST /api/billing/create-checkout`
Creates a Stripe Checkout session for upgrading to a paid plan.

**Auth:** Required  
**Body:**
```json
{
  "plan": "host",
  "billing_period": "monthly"
}
```
**Response:**
```json
{
  "checkout_url": "https://checkout.stripe.com/..."
}
```

---

### `POST /api/billing/portal`
Creates a Stripe Customer Portal session for managing subscription.

**Auth:** Required  
**Response:**
```json
{
  "portal_url": "https://billing.stripe.com/..."
}
```

---

### `POST /api/billing/webhook`
Stripe webhook endpoint. Handles:
- `checkout.session.completed` → update subscription_tier in user_profiles
- `customer.subscription.updated` → sync subscription status
- `customer.subscription.deleted` → downgrade to free tier
- `invoice.payment_failed` → send payment failure email

**Auth:** Stripe webhook signature (not user auth)  
**Headers:** `Stripe-Signature: ...`

---

## Email Preferences

### `PATCH /api/account/notifications`
Updates notification preferences.

**Auth:** Required  
**Body:**
```json
{
  "notif_reminder_90d": true,
  "notif_reminder_30d": true,
  "notif_reminder_7d": true,
  "notif_reminder_1d": false,
  "notif_alerts": true,
  "notif_product": false
}
```

---

## Admin Routes

All admin routes require: `user_profiles.role = 'admin'`

### `GET /api/admin/stats`
Platform statistics for admin dashboard.

### `POST /api/admin/cities`
Create a new city.

### `PUT /api/admin/cities/[id]`
Update a city (including toggling `is_active`).

### `POST /api/admin/compliance-items`
Create a compliance item for a city.

### `PUT /api/admin/compliance-items/[id]`
Update a compliance item.

### `DELETE /api/admin/compliance-items/[id]`
Soft-delete a compliance item (set `is_active = false`).

### `POST /api/admin/alerts`
Publish a regulatory alert. Body includes all alert fields plus `send_emails: boolean`.

When `send_emails: true`:
1. Insert alert into `regulatory_alerts`
2. Query all users with properties in the affected city
3. Filter users where `notif_alerts = true`
4. Queue emails via Resend (batch up to 100/call)
5. Update `emails_sent` count on the alert

**Auth:** Admin only

---

## Cron Job Endpoints

These endpoints are called by Vercel Cron (see `vercel.json`). They are protected by a shared `CRON_SECRET` environment variable, not user auth.

### `POST /api/cron/deadline-reminders`
Runs daily at 08:00 UTC.

Logic:
1. Query `upcoming_deadlines` view
2. For each item where `days_until_deadline` in [1, 7, 30, 90] and the corresponding `reminded_Xd = false`
3. Check that the property's user has `notif_reminder_Xd = true`
4. Send reminder email via Resend
5. Mark `reminded_Xd = true` on the compliance_status

### `POST /api/cron/reset-annual-reminders`
Runs on January 1 at 00:01 UTC.

Logic:
1. For all compliance items with `deadline_type = 'annual'`
2. Reset `reminded_90d`, `reminded_30d`, `reminded_7d`, `reminded_1d` to `false`
3. Recalculate `next_deadline_at` for the new year

### `POST /api/cron/reset-quarterly-reminders`
Runs on April 1, July 1, October 1, January 1.

Same as annual reset but for `deadline_type = 'quarterly'`.

---

## Error Format

All API errors return:
```json
{
  "error": {
    "code": "PROPERTY_LIMIT_EXCEEDED",
    "message": "Your current plan allows 1 property. Upgrade to add more.",
    "status": 403
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|---|---|---|
| `UNAUTHORIZED` | 401 | Not logged in |
| `FORBIDDEN` | 403 | Logged in but no permission |
| `NOT_FOUND` | 404 | Resource doesn't exist or not owned by user |
| `PROPERTY_LIMIT_EXCEEDED` | 403 | Subscription plan limit reached |
| `FILE_TOO_LARGE` | 413 | Upload exceeds 10MB limit |
| `INVALID_FILE_TYPE` | 415 | Only PDF, JPG, PNG allowed |
| `STRIPE_ERROR` | 400 | Stripe operation failed |
| `VALIDATION_ERROR` | 422 | Request body validation failed |
| `INTERNAL_ERROR` | 500 | Unexpected server error |
