# Build & Launch Checklist
## HostCompliant

Use this checklist to track progress from zero to first paying customer.  
Work top to bottom. Mark each item complete before moving to the next section.

---

## Phase 0: Setup (Day 1 — 2 hours)

### Project Initialization
- [ ] Create GitHub repository: `hostcompliant`
- [ ] Initialize Next.js 14: `npx create-next-app@latest hostcompliant --typescript --tailwind --app --src-dir`
- [ ] Install core dependencies:
  ```
  npm install @supabase/supabase-js @supabase/ssr
  npm install stripe @stripe/stripe-js
  npm install resend @react-email/components
  npm install zod
  npm install lucide-react
  npm install date-fns
  npm install clsx tailwind-merge
  ```
- [ ] Create Supabase project (region: EU West / Frankfurt)
- [ ] Copy Supabase credentials to `.env.local`
- [ ] Run `schema.sql` in Supabase SQL Editor
- [ ] Create Supabase Storage bucket: `documents` (private, 10MB limit)
- [ ] Generate TypeScript types: `npx supabase gen types typescript --project-id [id] > src/lib/supabase/types.ts`
- [ ] Create Stripe account (or use existing)
- [ ] Create Stripe products: Solo, Host, Professional (monthly + annual)
- [ ] Copy Stripe keys and Price IDs to `.env.local`
- [ ] Create Resend account, verify domain
- [ ] Push to GitHub, connect to Vercel
- [ ] Set all environment variables on Vercel

---

## Phase 1: Foundation (Days 2–4 — Core infrastructure)

### Auth
- [ ] Create Supabase auth client (`src/lib/supabase/client.ts`, `server.ts`)
- [ ] Create auth middleware (`middleware.ts`) — guards `/dashboard/*` and `/admin/*`
- [ ] Build `/login` page — email + password form
- [ ] Build `/register` page — with full_name field
- [ ] Build `/forgot-password` page
- [ ] Build `/reset-password` page (handles Supabase redirect)
- [ ] Test: register → verify email → login → redirect to dashboard

### Layout
- [ ] Build main `Navbar` component (logo, city dropdown, login/register CTAs)
- [ ] Build `Footer` component (links: Privacy, Terms, About, Cities)
- [ ] Build `DashboardSidebar` (links: Overview, Properties, Alerts, Calendar)
- [ ] Build `DashboardHeader` (user menu, upgrade badge)
- [ ] Apply layouts to public routes and dashboard routes

### Design System
- [ ] `Button` component (variants: primary, secondary, ghost, danger)
- [ ] `Card` component
- [ ] `Badge` component (variants: status colors, severity colors)
- [ ] `Input`, `Select`, `Textarea` components
- [ ] `Modal` component (accessible, focus trap)
- [ ] `Toast` notification component
- [ ] `Progress` bar component

---

## Phase 2: Cities & Public Pages (Days 4–6 — SEO foundation)

### Seed City Data
- [ ] Insert 5 cities into `cities` table via Supabase dashboard or SQL
- [ ] Insert all compliance items from `docs/compliance-data.md` into `compliance_items` table
  - [ ] Paris: 6 items
  - [ ] Barcelona: 5 items
  - [ ] Amsterdam: 5 items
  - [ ] Lisbon: 4 items
  - [ ] Rome: 5 items
- [ ] Verify all items show correct `deadline_type`, `deadline_day`, `deadline_month`
- [ ] Verify RLS: anonymous user can read cities and compliance items

### API Routes
- [ ] `GET /api/cities` — returns active cities list
- [ ] `GET /api/cities/[slug]` — returns city with compliance items
- [ ] `GET /api/cities/[slug]/alerts` — returns city alerts

### Public Pages
- [ ] Build `/cities` page — grid of city cards
- [ ] Build `/cities/[slug]` page (SSG with generateStaticParams)
  - [ ] Hero: city name, regulation status, last reviewed date
  - [ ] Summary box: "Key facts in 60 seconds"
  - [ ] Compliance items table (title, description, penalty, category)
  - [ ] Recent alerts section (last 2)
  - [ ] CTA: "Track my compliance — Free"
  - [ ] FAQ section (5 Q&A per city)
  - [ ] Meta tags for SEO (title, description, og:image)
- [ ] Build landing page `/`
  - [ ] Hero section with search bar
  - [ ] How it works (3 steps)
  - [ ] City coverage grid
  - [ ] Pricing tease
  - [ ] FAQ
  - [ ] CTA at bottom
- [ ] Build `/pricing` page
- [ ] Build `/legal/privacy`, `/legal/terms`, `/legal/disclaimer` pages
  - [ ] Get basic legal templates (use a GDPR-compliant template generator)
  - [ ] Add disclaimer: "Not legal advice"

---

## Phase 3: Core Product — Properties & Checklist (Days 6–10)

### API Routes
- [ ] `GET /api/properties` — user's properties list
- [ ] `POST /api/properties` — create property + auto-generate compliance statuses
  - [ ] Subscription tier check (max 1 on free)
  - [ ] Insert property
  - [ ] Query applicable compliance items (filter by city + property type)
  - [ ] Insert compliance_status row for each item
  - [ ] Calculate next_deadline_at for each
- [ ] `GET /api/properties/[id]` — property + full checklist with statuses
- [ ] `PUT /api/properties/[id]` — update name/platforms
- [ ] `DELETE /api/properties/[id]` — soft delete
- [ ] `PATCH /api/properties/[id]/items/[itemId]` — update status
  - [ ] Update status, completed_at, notes
  - [ ] Recalculate next_deadline_at if status = 'done' and deadline_type = annual/quarterly
- [ ] `GET /api/dashboard` — dashboard overview data

### Pages
- [ ] Build `/dashboard` page
  - [ ] Compliance score card
  - [ ] Overdue items list (red)
  - [ ] Upcoming deadlines (next 5)
  - [ ] Recent alerts
  - [ ] Empty state for new users
- [ ] Build `/dashboard/properties` page — property cards list
- [ ] Build `/dashboard/properties/new` page — 3-step form
- [ ] Build `/dashboard/properties/[id]` page — compliance checklist
  - [ ] Progress header
  - [ ] Filter tabs (All / Overdue / Pending / Done)
  - [ ] Compliance item cards (expandable)
  - [ ] Status selector (click to update)
  - [ ] "Mark as Done" modal with date + notes + upload
  - [ ] How to comply expandable section
  - [ ] Official source link
  - [ ] Deadline badge (overdue/days remaining)

### Deadline Calculation
- [ ] Implement `calculateNextDeadline()` utility in `src/lib/utils/deadline.ts`
- [ ] Annual deadlines: next occurrence of day/month
- [ ] Quarterly: next quarter-end + 15 days
- [ ] Test: all 5 cities, all deadline types

---

## Phase 4: Documents (Day 10–11)

### API Routes
- [ ] `POST /api/properties/[id]/documents` — upload file to Supabase Storage
  - [ ] Validate file type (PDF, JPG, PNG only)
  - [ ] Validate file size (max 10MB)
  - [ ] Check subscription storage quota
  - [ ] Upload to `documents/{user_id}/{property_id}/{uuid}-{filename}`
  - [ ] Insert document record
- [ ] `GET /api/properties/[id]/documents` — list with signed URLs
- [ ] `DELETE /api/documents/[docId]` — delete from storage + DB

### Pages
- [ ] Document upload component (drag & drop + click) in compliance item modal
- [ ] Build `/dashboard/properties/[id]/documents` page
  - [ ] Document grid
  - [ ] Download button (signed URL)
  - [ ] Delete button with confirmation
  - [ ] Upload area

---

## Phase 5: Alerts (Day 11–12)

### API Routes
- [ ] `GET /api/alerts` — alerts for user's cities
- [ ] `GET /api/alerts/[id]` — single alert

### Pages
- [ ] Build `/dashboard/alerts` page
  - [ ] Alert list (severity badge, city, date, title, summary)
  - [ ] Filter by severity
  - [ ] Click to expand full text
- [ ] Build city alerts page `/cities/[slug]/alerts`

---

## Phase 6: Email System (Day 12–14)

### Email Templates (React Email)
- [ ] Create `Welcome.tsx` email template
- [ ] Create `DeadlineReminder.tsx` template
  - [ ] Subject: "Reminder: [item] due in [X] days — [property]"
  - [ ] Body: item, deadline, penalty, how to start, CTA button
  - [ ] Unsubscribe link
- [ ] Create `RegulatoryAlert.tsx` template
  - [ ] Severity banner (color-coded)
  - [ ] Affected property
  - [ ] What changed, what to do
  - [ ] Source link
- [ ] Test all templates with Resend preview

### Cron Jobs
- [ ] Build `/api/cron/deadline-reminders` route
  - [ ] CRON_SECRET header validation
  - [ ] Query `upcoming_deadlines` view for items due in 1/7/30/90 days
  - [ ] For each: check user notification prefs, send email, mark reminded
  - [ ] Log to `email_logs`
- [ ] Build `/api/cron/reset-annual-reminders` route
- [ ] Build `/api/cron/reset-quarterly-reminders` route
- [ ] Create `vercel.json` with cron schedules
- [ ] Test: manually trigger cron, verify emails sent and reminded flags set

---

## Phase 7: Billing (Day 14–16)

### API Routes
- [ ] `POST /api/billing/create-checkout` — create Stripe Checkout session
- [ ] `POST /api/billing/portal` — create Stripe Customer Portal session
- [ ] `POST /api/billing/webhook` — handle Stripe webhook events
  - [ ] Signature verification
  - [ ] `checkout.session.completed` → set subscription_tier
  - [ ] `customer.subscription.updated` → sync tier
  - [ ] `customer.subscription.deleted` → downgrade to free
  - [ ] `invoice.payment_failed` → send email warning

### Subscription Enforcement
- [ ] Create `src/lib/stripe/plans.ts` with plan limits (properties, storage)
- [ ] Wrap `POST /api/properties` with subscription check
- [ ] Wrap document upload with storage quota check

### Pages
- [ ] Build `/account/billing` page
  - [ ] Current plan display
  - [ ] Upgrade button (opens Checkout)
  - [ ] Manage billing button (opens Customer Portal)
  - [ ] Next billing date
- [ ] Build upgrade modal component (triggered when user hits plan limit)
- [ ] Update `/pricing` page with functional upgrade CTAs

### Stripe Testing
- [ ] Test complete checkout flow with test card (4242 4242 4242 4242)
- [ ] Test subscription management via Customer Portal
- [ ] Test webhook handling (use Stripe CLI for local testing)
- [ ] Test downgrade flow (cancel → verify free tier restrictions apply)

---

## Phase 8: Account & Settings (Day 16–17)

### API Routes
- [ ] `GET /api/account` — user profile + subscription
- [ ] `PATCH /api/account` — update name
- [ ] `PATCH /api/account/notifications` — update notification prefs
- [ ] `DELETE /api/account` — full account deletion (GDPR)

### Pages
- [ ] Build `/account` page — profile overview
- [ ] Build `/account/settings` page
  - [ ] Name and email fields
  - [ ] Password change
  - [ ] Notification preferences (toggles for each reminder type)
  - [ ] Delete account (with confirmation)

---

## Phase 9: Admin Panel (Day 17–19)

### API Routes
- [ ] `GET /api/admin/stats`
- [ ] `POST/PUT /api/admin/cities`
- [ ] `POST/PUT/DELETE /api/admin/compliance-items`
- [ ] `POST /api/admin/alerts` (with email sending)

### Pages
- [ ] Build `/admin` dashboard (stats overview)
- [ ] Build `/admin/cities` — table with edit/toggle active
- [ ] Build `/admin/compliance-items` — filterable table
- [ ] Build `/admin/compliance-items/new` — form (all compliance_items fields)
- [ ] Build `/admin/alerts/new` — create + preview + publish alert
- [ ] Build `/admin/users` — user list with subscription tier
- [ ] Admin auth guard: redirect non-admin users to `/dashboard`

---

## Phase 10: Polish & Pre-Launch (Days 19–21)

### SEO & Performance
- [ ] Add `metadata` to every public page (title, description, og:image)
- [ ] Generate `sitemap.xml` dynamically (include all active city pages)
- [ ] Add `robots.txt`
- [ ] Generate og:image for city pages (using `@vercel/og` or static images)
- [ ] Verify Lighthouse score: Performance > 85, SEO > 95, Accessibility > 90
- [ ] Test all pages on mobile (Chrome DevTools → iPhone 12 Pro)

### GDPR & Legal
- [ ] Add cookie consent banner (react-cookie-consent or custom)
- [ ] Add GDPR compliance to privacy policy (data controller, retention, rights)
- [ ] Add "not legal advice" disclaimer to every city page and compliance item
- [ ] Add unsubscribe handling in email footer (Resend List-Unsubscribe header)

### Error Handling
- [ ] Create `404.tsx` page
- [ ] Create `error.tsx` page (global error boundary)
- [ ] Add `not-found.tsx` for cities that don't exist
- [ ] Add Sentry error tracking (optional but recommended)

### Quality
- [ ] Test all 5 user flows end-to-end in an incognito browser
- [ ] Test on mobile (iPhone, Android)
- [ ] Test email delivery (use a real email, not just preview)
- [ ] Test Stripe checkout on production (make a real €1 test charge)
- [ ] Fix any broken links or missing pages

---

## Phase 11: Content (Days 20–21 — parallel with Phase 10)

### Compliance Content
- [ ] Verify every compliance item against its official URL (links still work)
- [ ] Verify penalty amounts are current
- [ ] Verify deadline dates are correct for current year
- [ ] Add `last_reviewed_at` timestamp to each city in DB
- [ ] Write FAQ section for each city page (5–7 Q&A)

### Landing Page Content
- [ ] Write final hero headline and sub-headline
- [ ] Write "How it works" section
- [ ] Write FAQ (7 questions)
- [ ] Add testimonials placeholder (or remove for launch)

### Email Setup
- [ ] Test welcome email goes to spam? Improve DKIM/SPF/DMARC on domain
- [ ] Set up DNS records: SPF, DKIM, DMARC for `hostcompliant.com`

---

## Pre-Launch Checklist (Day 21)

### Security
- [ ] Verify RLS is enabled on all tables
- [ ] Verify admin routes are protected (try accessing /admin as non-admin)
- [ ] Verify document URLs are not publicly accessible (test unsigned URL — should 403)
- [ ] Verify cron routes require CRON_SECRET
- [ ] Verify Stripe webhook validates signature
- [ ] Review all API routes: none return data from other users

### Stripe Production
- [ ] Switch from test mode to live mode keys in Vercel env
- [ ] Verify Stripe webhook is configured for production URL (not localhost)
- [ ] Create live Stripe products and price IDs
- [ ] Update Vercel env with live price IDs

### Analytics
- [ ] Add Posthog or Google Analytics (GA4)
- [ ] Verify analytics loads and events fire
- [ ] Set up basic conversion funnel: Landing → Register → Property → Paid

### Monitoring
- [ ] Set up Vercel alerts for function errors
- [ ] Set up Supabase email alerts for DB errors
- [ ] Create a simple status page or use a free uptime monitor (UptimeRobot)

### Final Checks
- [ ] Try the complete flow from landing to paid subscription in a fresh incognito window
- [ ] Verify cron jobs work in Vercel (trigger manually from Vercel dashboard)
- [ ] Verify domain is configured with HTTPS
- [ ] Check all redirects work (logged-in user → /dashboard, etc.)

---

## Launch Day Checklist

- [ ] Announce on LinkedIn (post in English, French)
- [ ] Post in 3 Airbnb host Facebook groups (Paris, Barcelona, Amsterdam)
- [ ] DM 20 Airbnb hosts found in host communities
- [ ] Email any beta testers who signed up
- [ ] Post on Reddit: r/airbnb, r/airbnbbost, r/expats
- [ ] Submit to Product Hunt (optional — plan the launch date ahead)
- [ ] Set up a simple Notion page or Google Doc to track user feedback

---

## Post-Launch Monitoring (Week 1–2)

### Daily checks
- [ ] Monitor email delivery (Resend dashboard — any bounces?)
- [ ] Check Supabase for any RLS errors or failed queries
- [ ] Check Stripe for any failed payments
- [ ] Read all user feedback emails

### First week goals
- [ ] 50 registered users
- [ ] 5 paying users
- [ ] 0 reported compliance data errors
- [ ] Fix any critical bugs within 24 hours

### Content review trigger
If any user reports inaccurate compliance information:
1. Verify against official source
2. Correct in DB immediately
3. Publish regulatory alert if the correction is material
4. Email affected users

---

## Build Time Estimates

| Phase | Estimated Time | Cumulative |
|---|---|---|
| Phase 0: Setup | 2 hours | Day 1 |
| Phase 1: Foundation | 1.5 days | Day 2–3 |
| Phase 2: Public pages | 2 days | Day 4–6 |
| Phase 3: Properties + checklist | 4 days | Day 6–10 |
| Phase 4: Documents | 1 day | Day 10–11 |
| Phase 5: Alerts | 1 day | Day 11–12 |
| Phase 6: Email + cron | 2 days | Day 12–14 |
| Phase 7: Billing | 2 days | Day 14–16 |
| Phase 8: Account settings | 1 day | Day 16–17 |
| Phase 9: Admin panel | 2 days | Day 17–19 |
| Phase 10: Polish + legal | 2 days | Day 19–21 |
| Phase 11: Content | Parallel | Day 20–21 |
| **Total** | **~21 working days** | **4 weeks** |

**Working assumption:** 6–8 focused hours per day using Claude Code.  
**Reality:** Plan for 5 weeks to account for debugging, edge cases, and content research.

---

## Claude Code Build Prompts (Reference)

### Prompt to start Phase 1

```
I'm building HostCompliant — an EU Airbnb host STR compliance tracker.
Stack: Next.js 14 App Router, TypeScript, Tailwind, Supabase, Stripe, Resend.

Initialize the project with:
1. Supabase client setup (client.ts and server.ts using @supabase/ssr)
2. Auth middleware that protects /dashboard/* and /admin/* routes
3. A reusable Button component (variants: primary, secondary, ghost, danger, sizes: sm/md/lg)
4. A reusable Card component (with optional header, body, footer slots)
5. A login page at /login with email+password form, Supabase signInWithPassword, 
   error handling, and redirect to /dashboard on success

Supabase URL: [your URL]
Supabase Anon Key: [your key]
```

### Prompt to build the compliance checklist

```
Build the property compliance checklist page at /dashboard/properties/[id].

The page should:
1. Fetch the property and its compliance items from GET /api/properties/[id]
2. Group items by category (permits, tax_registration, safety, display_requirements, guest_reporting)
3. Show a progress header: "X of Y items complete" with a progress bar
4. Show overdue items first (red banner)
5. Each compliance item card shows:
   - Category icon (use lucide-react icons)
   - Title and short description
   - Status badge (color-coded: not_started=gray, in_progress=yellow, done=green, not_applicable=gray strikethrough)
   - Deadline badge (overdue=red, due within 7 days=orange, due within 30 days=yellow, ok=green)
   - Expandable section with full_description, how_to_comply (numbered steps), official URL
   - "Mark as Done" button that opens an inline modal
6. The "Mark as Done" modal has:
   - Date picker (default today)
   - Optional notes textarea
   - File upload (drag & drop or click, accepts PDF/JPG/PNG, max 10MB)
   - Cancel and Confirm buttons
   - On confirm: PATCH /api/properties/[id]/items/[itemId] and optimistically update the UI

Use the database types from src/lib/supabase/types.ts.
```
