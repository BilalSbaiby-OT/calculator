# Technical Architecture
## HostCompliant

---

## Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| Framework | Next.js 14 (App Router) | SSR for SEO-critical city pages; API routes; single deployment |
| Language | TypeScript | Type safety, better autocomplete, fewer runtime bugs |
| Styling | Tailwind CSS | Fast development, no CSS file management |
| Database | Supabase (PostgreSQL) | Auth + DB + Storage + RLS in one; free tier generous |
| Auth | Supabase Auth | Email/password; magic link optional; JWT sessions |
| File storage | Supabase Storage | Private document storage, signed URLs |
| Email | Resend | Developer-friendly, React email templates, EU data centers |
| Payments | Stripe | Standard, well-documented, Stripe Checkout handles complexity |
| Hosting | Vercel | Native Next.js support, cron jobs, edge functions, free tier |
| Analytics | Posthog (self-hosted or cloud) | GDPR-safe, free tier |
| Error tracking | Sentry | Free tier, Next.js plugin available |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          VERCEL                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │                    Next.js App                             │   │
│  │                                                            │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐  │   │
│  │  │  Public      │  │  Dashboard  │  │  Admin Panel     │  │   │
│  │  │  Pages (SSG) │  │  (SSR/CSR)  │  │  (SSR, admin     │  │   │
│  │  │              │  │             │  │   role only)     │  │   │
│  │  │  /           │  │  /dashboard │  │  /admin          │  │   │
│  │  │  /cities/*   │  │  /account   │  │                  │  │   │
│  │  │  /pricing    │  │             │  │                  │  │   │
│  │  └─────────────┘  └──────┬──────┘  └────────┬─────────┘  │   │
│  │                           │                  │             │   │
│  │  ┌────────────────────────┴──────────────────┴──────────┐ │   │
│  │  │                   API Routes (/api/...)               │ │   │
│  │  │  properties, compliance-statuses, documents,         │ │   │
│  │  │  alerts, dashboard, billing, admin, cron              │ │   │
│  │  └──────────────────────────────┬───────────────────────┘ │   │
│  │                                 │                          │   │
│  │  ┌──────────────────────────────┴───────────────────────┐ │   │
│  │  │               Middleware (auth guard)                 │ │   │
│  │  │  Validates Supabase session on every /dashboard/*    │ │   │
│  │  │  and /admin/* request                                │ │   │
│  │  └───────────────────────────────────────────────────────┘ │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                   Vercel Cron Jobs                        │    │
│  │  Daily 08:00 UTC → /api/cron/deadline-reminders          │    │
│  │  Jan 1 → /api/cron/reset-annual-reminders                │    │
│  │  Quarterly → /api/cron/reset-quarterly-reminders         │    │
│  └──────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
          │               │              │
          ▼               ▼              ▼
   ┌──────────┐    ┌──────────┐   ┌──────────┐
   │ Supabase │    │  Stripe  │   │  Resend  │
   │          │    │          │   │          │
   │ - Auth   │    │ - Checkout│   │ - Email  │
   │ - Postgres│   │ - Webhooks│   │   alerts │
   │ - Storage│    │ - Portal  │   │ - Reminders│
   │ - RLS    │    └──────────┘   └──────────┘
   └──────────┘
```

---

## Folder Structure

```
hostcompliant/
├── app/
│   ├── (public)/
│   │   ├── page.tsx                    # Landing page
│   │   ├── pricing/page.tsx
│   │   ├── cities/
│   │   │   ├── page.tsx                # Cities directory
│   │   │   └── [slug]/
│   │   │       ├── page.tsx            # City compliance page (SSG)
│   │   │       └── alerts/page.tsx
│   │   ├── blog/
│   │   │   ├── page.tsx
│   │   │   └── [slug]/page.tsx
│   │   └── legal/
│   │       ├── privacy/page.tsx
│   │       ├── terms/page.tsx
│   │       └── disclaimer/page.tsx
│   │
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   ├── register/page.tsx
│   │   ├── forgot-password/page.tsx
│   │   └── reset-password/page.tsx
│   │
│   ├── dashboard/
│   │   ├── layout.tsx                  # Dashboard shell (sidebar + header)
│   │   ├── page.tsx                    # Overview
│   │   ├── properties/
│   │   │   ├── page.tsx
│   │   │   ├── new/page.tsx
│   │   │   └── [id]/
│   │   │       ├── page.tsx            # Compliance checklist
│   │   │       └── documents/page.tsx
│   │   ├── alerts/page.tsx
│   │   └── calendar/page.tsx
│   │
│   ├── account/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── settings/page.tsx
│   │   └── billing/page.tsx
│   │
│   ├── admin/
│   │   ├── layout.tsx                  # Admin guard
│   │   ├── page.tsx
│   │   ├── cities/
│   │   │   ├── page.tsx
│   │   │   └── [id]/page.tsx
│   │   ├── compliance-items/
│   │   │   ├── page.tsx
│   │   │   ├── new/page.tsx
│   │   │   └── [id]/page.tsx
│   │   ├── alerts/
│   │   │   ├── page.tsx
│   │   │   ├── new/page.tsx
│   │   │   └── [id]/page.tsx
│   │   └── users/page.tsx
│   │
│   └── api/
│       ├── cities/
│       │   ├── route.ts                # GET /api/cities
│       │   └── [slug]/
│       │       ├── route.ts            # GET /api/cities/[slug]
│       │       └── alerts/route.ts
│       ├── properties/
│       │   ├── route.ts                # GET, POST
│       │   └── [id]/
│       │       ├── route.ts            # GET, PUT, DELETE
│       │       ├── items/[itemId]/route.ts  # PATCH status
│       │       └── documents/route.ts
│       ├── documents/[docId]/route.ts  # DELETE
│       ├── alerts/
│       │   ├── route.ts
│       │   └── [id]/route.ts
│       ├── dashboard/route.ts
│       ├── account/
│       │   ├── route.ts
│       │   └── notifications/route.ts
│       ├── billing/
│       │   ├── create-checkout/route.ts
│       │   ├── portal/route.ts
│       │   └── webhook/route.ts
│       ├── admin/
│       │   ├── stats/route.ts
│       │   ├── cities/route.ts
│       │   ├── compliance-items/route.ts
│       │   └── alerts/route.ts
│       └── cron/
│           ├── deadline-reminders/route.ts
│           ├── reset-annual-reminders/route.ts
│           └── reset-quarterly-reminders/route.ts
│
├── components/
│   ├── ui/                             # Base design system components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Badge.tsx
│   │   ├── Input.tsx
│   │   ├── Select.tsx
│   │   ├── Modal.tsx
│   │   ├── Toast.tsx
│   │   └── Progress.tsx
│   ├── layout/
│   │   ├── Navbar.tsx
│   │   ├── Footer.tsx
│   │   ├── DashboardSidebar.tsx
│   │   └── DashboardHeader.tsx
│   ├── cities/
│   │   ├── CityCard.tsx
│   │   └── CityComplianceTable.tsx
│   ├── properties/
│   │   ├── PropertyCard.tsx
│   │   ├── PropertyForm.tsx
│   │   └── ComplianceChecklist.tsx
│   ├── compliance/
│   │   ├── ComplianceItemCard.tsx
│   │   ├── StatusSelector.tsx
│   │   ├── DeadlineBadge.tsx
│   │   └── DocumentUpload.tsx
│   ├── alerts/
│   │   ├── AlertCard.tsx
│   │   └── AlertBadge.tsx
│   └── billing/
│       ├── PricingCard.tsx
│       └── UpgradeModal.tsx
│
├── lib/
│   ├── supabase/
│   │   ├── client.ts                   # Browser client
│   │   ├── server.ts                   # Server component client
│   │   └── types.ts                    # Generated types (supabase gen types)
│   ├── stripe/
│   │   ├── client.ts
│   │   └── plans.ts                    # Plan definitions and limits
│   ├── resend/
│   │   ├── client.ts
│   │   └── templates/
│   │       ├── DeadlineReminder.tsx    # React email template
│   │       ├── RegulatoryAlert.tsx
│   │       └── Welcome.tsx
│   └── utils/
│       ├── deadline.ts                 # Deadline calculation helpers
│       ├── subscription.ts             # Plan limit checks
│       └── compliance.ts              # Compliance score calculations
│
├── hooks/
│   ├── useProperties.ts
│   ├── useComplianceItems.ts
│   └── useSubscription.ts
│
├── types/
│   └── index.ts                        # Shared TypeScript types
│
├── middleware.ts                        # Auth guard for dashboard/* and admin/*
│
├── vercel.json                          # Cron job configuration
│
└── .env.local                           # (not committed)
    # NEXT_PUBLIC_SUPABASE_URL
    # NEXT_PUBLIC_SUPABASE_ANON_KEY
    # SUPABASE_SERVICE_ROLE_KEY
    # STRIPE_SECRET_KEY
    # NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
    # STRIPE_WEBHOOK_SECRET
    # RESEND_API_KEY
    # CRON_SECRET
    # NEXT_PUBLIC_APP_URL
```

---

## Data Flow Examples

### Flow 1: User adds a property

```
User submits property form
    │
    ▼
POST /api/properties
    │
    ├── Verify auth (Supabase session)
    ├── Check property count vs. subscription tier
    ├── INSERT into properties table
    │
    ├── Query compliance_items WHERE city_id = ? AND is_active = true
    │   AND (applies_to_property_types IS NULL 
    │        OR property_type = ANY(applies_to_property_types))
    │
    ├── For each compliance item:
    │   ├── INSERT into compliance_statuses (status = 'not_started')
    │   └── Calculate and set next_deadline_at
    │
    └── Return property with generated checklist
```

### Flow 2: Daily deadline reminder cron

```
Vercel Cron fires at 08:00 UTC
    │
    ▼
POST /api/cron/deadline-reminders (with CRON_SECRET header)
    │
    ├── Query upcoming_deadlines view
    │   WHERE days_until_deadline IN (1, 7, 30, 90)
    │   AND reminded_Xd = false
    │
    ├── For each result:
    │   ├── Check user's notification preferences
    │   ├── If notif_reminder_Xd = true:
    │   │   ├── Send email via Resend
    │   │   ├── INSERT into email_logs
    │   │   └── UPDATE compliance_statuses SET reminded_Xd = true
    │   └── If notif_reminder_Xd = false: skip
    │
    └── Return { sent: N, skipped: M }
```

### Flow 3: Admin publishes regulatory alert

```
Admin fills in alert form and clicks "Publish and send"
    │
    ▼
POST /api/admin/alerts (with admin role check)
    │
    ├── INSERT into regulatory_alerts
    │
    ├── If send_emails = true:
    │   ├── Query all users with properties in city_id
    │   ├── Filter: notif_alerts = true
    │   ├── Batch emails via Resend (100 per batch)
    │   ├── INSERT into email_logs for each sent email
    │   └── UPDATE regulatory_alerts SET emails_sent = count
    │
    └── Return alert with emails_sent count
```

### Flow 4: User upgrades plan via Stripe

```
User clicks "Upgrade to Host Plan"
    │
    ▼
POST /api/billing/create-checkout
    │
    ├── Create/get Stripe customer
    ├── Create Stripe Checkout session
    │   (mode: subscription, price: STRIPE_HOST_PRICE_ID)
    └── Return { checkout_url }

User completes Stripe Checkout
    │
    ▼
Stripe sends webhook: checkout.session.completed
    │
    ▼
POST /api/billing/webhook
    │
    ├── Verify Stripe signature
    ├── Get customer_id from session
    ├── Find user by stripe_customer_id
    ├── UPDATE user_profiles SET subscription_tier = 'host'
    └── Return 200 OK
```

---

## Rendering Strategy

| Route | Strategy | Reason |
|---|---|---|
| `/` | SSG | Static content, revalidate daily |
| `/cities` | SSG | SEO content, revalidate weekly |
| `/cities/[slug]` | SSG | Most important SEO pages, revalidate when compliance items update |
| `/pricing` | SSG | Static content |
| `/dashboard` | SSR | User-specific, cannot cache |
| `/dashboard/properties/[id]` | SSR | Per-user data |
| `/admin/*` | SSR | Admin data, no caching |
| API routes | Dynamic | Always server-computed |

City pages use `generateStaticParams` to pre-render all active cities at build time, with `revalidate = 3600` for ISR (regenerate if compliance items change).

---

## Email Templates (Resend + React Email)

### Template 1: Deadline Reminder

```
Subject: Reminder: "[Item title]" due in [X] days — [Property name]

Body:
Hi [first name],

This is a reminder that "[compliance item title]" for your property 
"[property name]" in [city] is due in [X] days.

Due date: [date]
Penalty for non-compliance: [penalty description]

[How to comply - 3-line summary]

[VIEW CHECKLIST BUTTON → /dashboard/properties/[id]]

If you've already completed this, mark it as done in HostCompliant to 
stop receiving reminders.

Need help? Reply to this email.

— The HostCompliant team
[Unsubscribe from reminders]
```

### Template 2: Regulatory Alert (Critical)

```
Subject: 🚨 Important change in [City] STR rules — action may be required

Body:
[CRITICAL ALERT BANNER]

Hi [first name],

The short-term rental rules in [city] have changed. This may affect 
your property "[property name]."

What changed:
[alert title]

Summary:
[alert summary]

[READ FULL ALERT BUTTON → /dashboard/alerts/[id]]

What you should do:
[If action required: short bullet list of actions]
[If informational: "Review your compliance checklist to see if any 
items need updating."]

Source: [source_url]

— The HostCompliant team
```

---

## Security Considerations

### Auth
- Supabase RLS enforces data isolation — users cannot access other users' data even if they guess a UUID
- Admin panel protected by both middleware (role check) and API-level role check (defense in depth)
- Webhook endpoint validates Stripe signature (not user auth)
- Cron endpoints validate `CRON_SECRET` header

### File uploads
- Files are uploaded to a private Supabase Storage bucket
- Access is via signed URLs (expiry: 1 hour for download)
- File type validation on both client (accept attribute) and server (mime type check)
- File size limited to 10MB per file
- Storage path includes user_id to prevent path traversal

### Input validation
- All API route inputs validated with Zod
- Supabase parameterized queries (no SQL injection risk)
- XSS: React's default escaping + no `dangerouslySetInnerHTML` except for rich text alert content (sanitized with DOMPurify before display)

### GDPR
- EU data storage: Supabase EU West region
- Cookie consent banner on first visit
- Privacy policy covers all data collected
- Right to deletion: `DELETE /api/account` removes user, all properties, statuses, and documents
- Email unsubscribe: one-click via Resend unsubscribe header + in-app notification preferences

---

## Environment Variables

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...   # Server-only, never exposed to client

# Stripe
STRIPE_SECRET_KEY=sk_live_...       # Server-only
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
# Price IDs
STRIPE_SOLO_MONTHLY_PRICE_ID=price_...
STRIPE_SOLO_ANNUAL_PRICE_ID=price_...
STRIPE_HOST_MONTHLY_PRICE_ID=price_...
STRIPE_HOST_ANNUAL_PRICE_ID=price_...
STRIPE_PRO_MONTHLY_PRICE_ID=price_...
STRIPE_PRO_ANNUAL_PRICE_ID=price_...

# Resend
RESEND_API_KEY=re_...
RESEND_FROM_EMAIL=alerts@hostcompliant.com

# App
NEXT_PUBLIC_APP_URL=https://hostcompliant.com
CRON_SECRET=your-random-256-bit-secret

# Analytics (optional)
NEXT_PUBLIC_POSTHOG_KEY=phc_...
SENTRY_DSN=https://...
```

---

## Vercel Configuration (vercel.json)

```json
{
  "crons": [
    {
      "path": "/api/cron/deadline-reminders",
      "schedule": "0 8 * * *"
    },
    {
      "path": "/api/cron/reset-annual-reminders",
      "schedule": "1 0 1 1 *"
    },
    {
      "path": "/api/cron/reset-quarterly-reminders",
      "schedule": "1 0 1 1,4,7,10 *"
    }
  ]
}
```

---

## Third-party Service Setup Checklist

### Supabase
- [ ] Create project (select EU West region)
- [ ] Run `schema.sql` in SQL editor
- [ ] Enable Email Auth (Supabase Auth settings)
- [ ] Configure redirect URLs: `https://hostcompliant.com/auth/callback`
- [ ] Create `documents` storage bucket (private, 10MB limit)
- [ ] Generate TypeScript types: `supabase gen types typescript --project-id xxx > lib/supabase/types.ts`

### Stripe
- [ ] Create products: Solo, Host, Professional (monthly + annual)
- [ ] Copy all Price IDs to `.env`
- [ ] Set up webhook endpoint: `https://hostcompliant.com/api/billing/webhook`
- [ ] Enable events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`
- [ ] Copy webhook signing secret to `.env`

### Resend
- [ ] Add and verify domain: `hostcompliant.com`
- [ ] Create API key
- [ ] Set up `alerts@hostcompliant.com` as sending address

### Vercel
- [ ] Connect GitHub repo
- [ ] Set all environment variables
- [ ] Enable cron jobs (requires Vercel Pro or use free tier with 1 cron)
- [ ] Set Node.js version: 20.x
