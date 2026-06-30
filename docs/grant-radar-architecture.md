# Architecture
## GrantRadar

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         VERCEL                              │
│                                                             │
│  Next.js 14 (App Router)                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌────────────────┐  │
│  │  Public pages  │  │  Dashboard    │  │  Admin panel   │  │
│  │  /grants/...  │  │  /dashboard/  │  │  /admin/       │  │
│  │  /countries/  │  │  SSR per req  │  │  SSR, role gated│  │
│  │  SSG + ISR    │  │               │  │               │  │
│  └───────────────┘  └───────────────┘  └────────────────┘  │
│                                                             │
│  API Routes (/app/api/...)                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  /api/companies  /api/grants  /api/matches           │   │
│  │  /api/pipeline   /api/reports /api/billing           │   │
│  │  /api/cron/match-companies                           │   │
│  │  /api/cron/deadline-reminders                        │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────┬─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┬──────────────┐
        ▼           ▼           ▼              ▼
   ┌─────────┐  ┌────────┐  ┌───────┐  ┌──────────┐
   │Supabase │  │ Resend │  │Stripe │  │ Puppeteer│
   │         │  │        │  │       │  │(PDF gen) │
   │- Postgres│  │- Match │  │- Sub  │  │ (Vercel  │
   │- Auth   │  │  alerts│  │  mgmt │  │  function│
   │- Storage│  │- 30/7d │  │- Wbhk │  │  for rpt)│
   │- RLS    │  │  reminders│        │  └──────────┘
   └─────────┘  │- Digest│  └───────┘
                └────────┘
```

---

## Rendering Strategy

| Route | Strategy | Why |
|---|---|---|
| `/` | Static (SSG) | Marketing content, fast |
| `/grants` | ISR (revalidate: 3600) | Updates when grants are added |
| `/grants/[slug]` | ISR (revalidate: 3600) | Grant detail pages, SEO |
| `/countries/[slug]` | ISR (revalidate: 86400) | Country hubs, slow-changing |
| `/blog/[slug]` | ISR (revalidate: 86400) | Blog posts |
| `/pricing` | Static (SSG) | Rarely changes |
| `/dashboard/*` | SSR (per request) | User-specific data |
| `/admin/*` | SSR (per request) | Admin data |

ISR pages revalidate on-demand when admin adds/updates a grant (via `revalidatePath`).

---

## Folder Structure

```
/app
  /(public)
    /page.tsx                    # Landing page
    /grants
      /page.tsx                  # Grant directory
      /[slug]/page.tsx           # Grant detail
    /countries/[slug]/page.tsx   # Country hub pages
    /pricing/page.tsx
    /blog
      /page.tsx
      /[slug]/page.tsx
    /login/page.tsx
    /register/page.tsx
  /(dashboard)
    /layout.tsx                  # Sidebar + auth gate
    /dashboard/page.tsx
    /dashboard/companies
      /page.tsx
      /new/page.tsx
      /[id]/page.tsx             # Match feed
      /[id]/pipeline/page.tsx
      /[id]/edit/page.tsx
    /dashboard/grants/page.tsx   # Cross-company saved grants
    /dashboard/alerts/page.tsx
    /dashboard/reports/page.tsx
    /account
      /page.tsx
      /billing/page.tsx
  /(admin)
    /layout.tsx                  # Admin auth gate
    /admin/page.tsx
    /admin/grants
      /page.tsx
      /new/page.tsx
      /[id]/page.tsx
    /admin/users/page.tsx
    /admin/alerts/page.tsx

/app/api
  /companies/route.ts            # GET (list), POST (create)
  /companies/[id]/route.ts       # GET, PUT, DELETE
  /companies/[id]/matches/route.ts # GET match feed, POST trigger re-match
  /companies/[id]/pipeline/route.ts
  /grants/route.ts               # GET (public list with filters)
  /grants/[slug]/route.ts        # GET single grant
  /pipeline/[id]/route.ts        # PATCH status, notes
  /pipeline/[id]/documents/route.ts
  /documents/[id]/route.ts       # DELETE
  /reports/route.ts              # POST generate PDF (Growth+)
  /billing/create-checkout/route.ts
  /billing/portal/route.ts
  /billing/webhook/route.ts
  /admin/grants/route.ts         # POST create
  /admin/grants/[id]/route.ts    # PUT, DELETE
  /admin/users/route.ts
  /admin/stats/route.ts
  /cron/match-companies/route.ts
  /cron/deadline-reminders/route.ts

/components
  /ui/                           # shadcn/ui components
  /grants
    /GrantCard.tsx
    /GrantDetail.tsx
    /GrantDirectory.tsx
    /MatchFeed.tsx
    /MatchBadge.tsx
  /companies
    /CompanyForm.tsx             # Multi-step new company wizard
    /CompanyCard.tsx
  /pipeline
    /PipelineBoard.tsx
    /PipelineEntry.tsx
  /reports
    /ReportPreview.tsx
    /GrantReportPDF.tsx          # React-PDF template
  /dashboard
    /Sidebar.tsx
    /DashboardStats.tsx
  /admin
    /GrantForm.tsx
    /EligibilityEditor.tsx       # JSON editor for eligibility criteria

/lib
  /supabase/
    /client.ts
    /server.ts
    /middleware.ts
  /matching/
    /matchCompany.ts             # TypeScript version of matching logic
  /pdf/
    /generateReport.ts
  /email/
    /sendMatchAlert.ts
    /sendDeadlineReminder.ts
    /sendWeeklyDigest.ts
  /stripe/
    /client.ts
    /plans.ts
  /utils/
    /grants.ts                   # Multilingual field helpers
    /companies.ts

/middleware.ts                   # Supabase auth session refresh

/public
  /logos/                        # Funding body logos (BPI, CDTI, KfW, etc.)
  /flags/                        # Country flag SVGs
```

---

## Key Data Flows

### 1. User Creates Company Profile → Gets Matches

```
User submits company form
  │
  ▼
POST /api/companies
  ├── Validate input
  ├── Insert into companies table
  ├── Call match_company_to_grants(company_id) [Postgres function]
  │     ├── Loops all active grants
  │     ├── Scores each against company eligibility criteria
  │     ├── Inserts/updates grant_matches rows
  │     └── Updates companies.match_count
  ├── Return: company + match_count
  │
  ▼
Redirect to /dashboard/companies/[id]
  │
  ▼
GET /api/companies/[id]/matches
  ├── Query company_match_feed view
  ├── Apply subscription filter (free = top 10 only)
  └── Return ranked match list
```

---

### 2. Admin Adds New Grant → All Companies Re-Matched

```
Admin submits grant form
  │
  ▼
POST /api/admin/grants
  ├── Validate + insert grant
  ├── on_grant_changed trigger fires
  │     └── Sets companies.last_matched_at = NULL for all
  ├── Revalidate ISR pages: /grants, /grants/[slug], /countries/[slug]
  │
  ▼
/api/cron/match-companies (runs every 15 min via Vercel cron)
  ├── SELECT id FROM companies WHERE last_matched_at IS NULL OR last_matched_at < now() - interval '1 hour'
  ├── For each: call match_company_to_grants(id)
  ├── For new strong matches: queue alert email
  └── Send batch alerts via Resend
```

---

### 3. Daily Deadline Reminder Cron

```
/api/cron/deadline-reminders (runs daily 08:00 UTC)
  │
  ├── Query pipeline_deadline_reminders view
  ├── Filter: days_until = 30 AND reminded_30d = false → send 30d reminder, set reminded_30d = true
  ├── Filter: days_until = 7 AND reminded_7d = false → send 7d reminder, set reminded_7d = true
  ├── Check user's notif_deadline_30d / notif_deadline_7d preferences
  └── Log in email_logs table
```

---

### 4. Stripe Subscription Upgrade

```
User clicks "Upgrade to Growth"
  │
  ▼
POST /api/billing/create-checkout { plan: 'growth', billing_period: 'monthly' }
  │
  ▼
Stripe Checkout hosted page
  │
  ▼
Stripe webhook → POST /api/billing/webhook
  ├── checkout.session.completed → update user_profiles.subscription_tier
  ├── customer.subscription.updated → sync tier
  └── customer.subscription.deleted → downgrade to 'free'
  │
  ▼
User redirected to /dashboard?upgrade=success
```

---

### 5. PDF Report Generation (Growth+ plans)

```
User clicks "Generate Report" for a company
  │
  ▼
POST /api/reports { company_id, grant_ids[] }
  ├── Auth check: subscription_tier in ['growth', 'agency']
  ├── Fetch company + grants data
  ├── Render GrantReportPDF with React-PDF
  ├── Upload PDF to Supabase Storage: reports/{user_id}/{company_id}/report-{date}.pdf
  ├── Insert into reports table
  └── Return signed URL (valid 1 hour)
```

---

## Environment Variables

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Stripe
STRIPE_SECRET_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_STARTER_MONTHLY_PRICE_ID=
STRIPE_STARTER_ANNUAL_PRICE_ID=
STRIPE_GROWTH_MONTHLY_PRICE_ID=
STRIPE_GROWTH_ANNUAL_PRICE_ID=
STRIPE_AGENCY_MONTHLY_PRICE_ID=
STRIPE_AGENCY_ANNUAL_PRICE_ID=

# Resend
RESEND_API_KEY=
RESEND_FROM_EMAIL=alerts@grantradar.eu

# Cron security
CRON_SECRET=

# App
NEXT_PUBLIC_APP_URL=https://grantradar.eu
```

---

## vercel.json

```json
{
  "crons": [
    {
      "path": "/api/cron/match-companies",
      "schedule": "*/15 * * * *"
    },
    {
      "path": "/api/cron/deadline-reminders",
      "schedule": "0 8 * * *"
    },
    {
      "path": "/api/cron/weekly-digest",
      "schedule": "0 8 * * 1"
    }
  ]
}
```

---

## Subscription Plan Limits (enforced in API)

| Limit | Free | Starter | Growth | Agency |
|---|---|---|---|---|
| Company profiles | 1 | 1 | 5 | Unlimited |
| Grant matches shown | 10 | All | All | All |
| Email alerts | ✗ | ✓ | ✓ | ✓ |
| PDF reports | ✗ | ✗ | ✓ | ✓ White-label |
| Pipeline tracking | Save only | Full | Full | Full |
| Document uploads | ✗ | ✓ | ✓ | ✓ |
| Team members | 1 | 1 | 1 | 3 |

---

## Multilingual Strategy

All user-facing text comes from two sources:
1. **UI strings**: `next-intl` library, locale files in `/messages/en.json`, `/messages/fr.json`, etc.
2. **Grant content**: Stored in DB as `name_en`, `name_fr`, `name_es`, `name_de` columns. API helper picks the right column based on `user.preferred_language`. Falls back to `_en` if translation missing.

URL structure: `/grants/[slug]` — same URL for all languages (content switches via language preference, not URL). This avoids hreflang complexity at launch.

---

## SEO Strategy

Key pages for organic:
- `/grants` directory — target "EU grants for SMEs 2026"
- `/grants/[slug]` — one page per grant, target grant name searches
- `/countries/france` etc. — target "business grants France 2026"
- `/blog/` — long-form guides, "how to apply for BPI France grant"

Each grant detail page includes:
- Structured data (JSON-LD: `GovernmentGrant` schema type)
- Meta title: "[Grant Name] — Eligibility, Amount & How to Apply | GrantRadar"
- Meta description: "[Short description] — Up to €X available. Deadline: [date]."

Grant pages are ISR (revalidate 1h) so they stay current without full rebuilds.
