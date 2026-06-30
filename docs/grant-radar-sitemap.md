# Sitemap & Route Structure
## GrantRadar

---

## Public Routes (no auth)

### `/` — Landing Page
**Purpose:** Convert visitors into signups  
**Content:**
- Hero: "Stop missing EU grants. GrantRadar monitors 100+ programs in 4 languages."
- Social proof: "€2.4M in grants discovered for our users"
- How it works: 3 steps (create profile → get matches → track deadlines)
- Grant counter: live count of active grants in the database
- Country section: France / Spain / Germany / EU-wide with top 3 grants in each
- Pricing preview (3 plans)
- FAQ
- Footer

**SEO target:** "EU grants for SMEs", "European funding for small business"

---

### `/grants` — Public Grant Directory
**Purpose:** SEO + free value / lead gen  
**Content:**
- Search bar + filters (country, category, amount range, deadline)
- Grid of grant cards (name, country, max amount, deadline, category tag)
- Free users see all but get CTA to sign up for personalized matches
- Pagination / infinite scroll

**SEO target:** "EU grants 2026", "business grants France", "SME funding Spain"

---

### `/grants/[slug]` — Grant Detail Page
**Purpose:** SEO content pages, one per grant  
**Content:**
- Grant name + funding body
- Max amount, deadline, eligibility summary
- Full description
- How to apply (numbered steps)
- Official source link
- "Does this grant match your company? Create a free profile →"
- Related grants sidebar

**SEO target:** "[Grant name] eligibility", "how to apply for [grant]", "[Grant name] 2026"

---

### `/countries/france` — Country Hub Page
**Purpose:** SEO hub for French grants  
**Content:**
- Intro: "France offers X grants totaling €Xbn per year for SMEs"
- Top grants by category
- Key funding bodies (BPI France, ADEME, regional)
- Link to filtered `/grants?country=france`

**Same pattern for:** `/countries/spain`, `/countries/germany`, `/countries/eu`

---

### `/blog` — Blog / Resource Hub
**Purpose:** Organic SEO content, grant application guides  
**Key posts:**
- "Top 10 EU grants for French SMEs in 2026"
- "How to write a BPI France innovation grant application"
- "CDTI Spain: complete guide for startups"
- "EU Horizon Europe for SMEs: what you need to know"

---

### `/pricing` — Pricing Page

---

### `/login` — Login Page (email + password or magic link)

### `/register` — Registration Page

### `/forgot-password` — Password Reset

---

## Dashboard Routes (auth required)

### `/dashboard` — Main Dashboard
**Content:**
- Welcome + subscription status
- Quick stats: X companies tracked, Y new grants this week, Z grants approaching deadline
- "New matches" section: grants added in last 7 days across all company profiles
- "Upcoming deadlines" section: grants closing in next 30 days
- "Your pipeline" summary: X applied, Y researching

---

### `/dashboard/companies` — Company List
**Content:**
- List of all company profiles
- Per company: name, country, sector, match count, last updated
- Button: "Add company"
- Free users see upgrade CTA if they try to add a second company

---

### `/dashboard/companies/new` — Create Company Profile
**Multi-step form:**
- Step 1: Basic info (name, country, region, founded year)
- Step 2: Size & financials (employees, revenue range)
- Step 3: Activity (sector, R&D, export, digital, green transition)
- Step 4: Preview — "Based on your profile, we found X matching grants"
- CTA: "Save and see my matches"

---

### `/dashboard/companies/[id]` — Company Dashboard
**Content:**
- Company name + edit button
- Match feed: grants filtered + ranked for this company
  - Filter tabs: All / Strong Match / Due Soon / New This Week
  - Sort: by deadline / by amount / by match confidence
- Each grant card shows: name, amount, deadline, match reason, save/dismiss buttons

---

### `/dashboard/companies/[id]/pipeline` — Grant Pipeline
**Content:**
- Kanban or list view: Saved → Researching → Applied → Won / Lost
- Each grant: name, deadline, notes, uploaded docs, last action date

---

### `/dashboard/companies/[id]/edit` — Edit Company Profile

---

### `/dashboard/grants` — All Saved Grants (across all companies)
**Content:**
- Unified view of all saved/tracked grants across all company profiles
- Filter by: company, status, deadline

---

### `/dashboard/alerts` — Notification History
**Content:**
- Log of all alerts sent: date, company, grant name, type (new match / deadline reminder)
- Alert preferences link

---

### `/dashboard/reports` — PDF Report Generator (Growth+ only)
**Content:**
- Select company
- Select grant list (top matches, or curated selection)
- Preview report
- Download PDF / send via email
- History of generated reports

---

### `/account` — Account Settings
**Tabs:**
- Profile (name, email, preferred language)
- Notifications (alert preferences per company)
- Billing (plan, Stripe portal link)
- Team (invite co-user — Agency plan)
- Danger zone (delete account)

---

### `/account/billing` — Billing & Subscription
**Content:**
- Current plan + renewal date
- Usage: X/Y company profiles used
- Upgrade / downgrade options
- Link to Stripe Customer Portal for payment method, invoices

---

## Admin Routes (role = 'admin')

### `/admin` — Admin Dashboard
**Stats:** Total users, paying users, MRR, grants in DB, matches generated this week, most saved grants

### `/admin/grants` — Grant Database Management
- Table: all grants with status, last verified, saves count
- Filter: by country, category, active/expired
- Bulk actions: mark expired, re-trigger matching

### `/admin/grants/new` — Add New Grant
**Form fields:** All grant fields (name, description, country, category, amount, deadline, eligibility criteria JSON, official URL, difficulty, language)

### `/admin/grants/[id]` — Edit Grant

### `/admin/companies` — Browse All Company Profiles (read-only for support)

### `/admin/users` — User Management
- List users, filter by plan, impersonate for support

### `/admin/alerts` — Manual Alert Triggers
- Send a "new grant" alert to all matching users manually
- Send broadcast announcement to all users

---

## Email Templates

| Template | Trigger |
|---|---|
| Welcome email | Registration complete |
| New match alert | New grant added that matches company profile |
| Deadline reminder (30d) | 30 days before grant deadline |
| Deadline reminder (7d) | 7 days before grant deadline |
| Weekly digest | Every Monday — new grants this week |
| Upgrade confirmation | Stripe webhook: subscription created |
| Payment failed | Stripe webhook: invoice payment failed |
| Account deletion confirmation | User deletes account |

---

## Redirect Rules

| From | To | Reason |
|---|---|---|
| `/dashboard` (no companies) | `/dashboard/companies/new` | Force profile creation |
| `/dashboard/reports` (free/starter) | `/dashboard/reports` with upgrade modal | Feature gate |
| `/admin/*` (non-admin user) | `/dashboard` with 403 toast | Access control |
| `/login` (already logged in) | `/dashboard` | Avoid double-login |

---

## Empty States

| Page | Empty State | CTA |
|---|---|---|
| Dashboard (no companies) | "Welcome to GrantRadar! Create your first company profile to see matching grants." | "Create company profile →" |
| Company matches (no matches) | "No grants matched your profile. Try adjusting your sector or R&D activity." | "Edit profile" |
| Pipeline (nothing saved) | "Save grants from your match feed to start tracking your pipeline." | "View matches" |
| Alerts (no history) | "Alert history will appear here once you receive your first match alert." | — |
| Reports (none generated) | "Generate your first grant report to share with your client." | "Create report" |
