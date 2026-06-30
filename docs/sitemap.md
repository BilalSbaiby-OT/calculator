# Sitemap & Route Architecture
## HostCompliant

---

## Route Tree

```
/
├── (public)
│   ├── /                           → Landing page
│   ├── /cities                     → All covered cities directory
│   ├── /cities/[slug]              → City compliance overview (public, SEO)
│   │   └── /cities/[slug]/alerts   → City regulatory alerts archive (public)
│   ├── /pricing                    → Pricing page
│   ├── /blog                       → Regulatory news blog
│   │   └── /blog/[slug]            → Individual blog post
│   ├── /about                      → About page
│   ├── /legal/privacy              → Privacy policy
│   ├── /legal/terms                → Terms of service
│   └── /legal/disclaimer           → Compliance disclaimer
│
├── (auth)
│   ├── /login                      → Email + password login
│   ├── /register                   → Sign up form
│   ├── /forgot-password            → Password reset request
│   └── /reset-password             → Password reset form (from email link)
│
├── /dashboard                      → Main dashboard (auth required)
│   ├── /dashboard                  → Overview: compliance score, upcoming deadlines
│   ├── /dashboard/properties       → All properties list
│   │   ├── /dashboard/properties/new         → Add property form
│   │   └── /dashboard/properties/[id]        → Property compliance checklist
│   │       └── /dashboard/properties/[id]/documents  → Documents for this property
│   ├── /dashboard/alerts           → Regulatory alerts inbox (all subscribed cities)
│   └── /dashboard/calendar         → Deadline calendar view (all properties)
│
└── /account
    ├── /account                    → Account overview
    ├── /account/settings           → Profile, email, notifications preferences
    ├── /account/billing            → Subscription, invoices, upgrade/cancel
    └── /account/cities             → Manage city subscriptions (alert preferences)

/admin                              → Admin panel (admin role only)
├── /admin                          → Admin dashboard (stats)
├── /admin/cities                   → Manage cities (add, edit, toggle active)
├── /admin/cities/[id]              → Edit city details
├── /admin/compliance-items         → All compliance items across all cities
├── /admin/compliance-items/new     → Add compliance item
├── /admin/compliance-items/[id]    → Edit compliance item
├── /admin/alerts                   → Manage regulatory alerts
├── /admin/alerts/new               → Create and publish alert (with email preview)
├── /admin/alerts/[id]              → Edit/view alert
└── /admin/users                    → User list, roles, subscription status
```

---

## Page Descriptions

### Public Pages

#### `/` — Landing Page

**Purpose:** Convert visitors into registered users.

**Sections:**
1. Hero: Headline + city search bar + CTA ("Check my city")
2. Pain section: "Are you at risk? Here's what's changing in EU cities"
3. How it works: 3 steps (Pick city → Set up property → Get compliance checklist + alerts)
4. City coverage grid: 5 city cards with regulation status badge
5. Testimonial/social proof (placeholder for beta users)
6. Pricing tease (link to /pricing)
7. FAQ: 5 common questions
8. Final CTA: "Get your free compliance checklist"

**SEO title:** "EU Airbnb Host Compliance Tracker — Stay legal in Paris, Barcelona, Amsterdam"

---

#### `/cities` — City Directory

**Purpose:** SEO landing page for all covered cities + trust builder.

**Content:**
- Grid of all covered cities with card per city:
  - City name + country flag
  - "Regulation status" badge: Active / Changing / Strict
  - Number of compliance items
  - Highest penalty for non-compliance
  - Link to city page

---

#### `/cities/[slug]` — City Compliance Page

**Purpose:** Public, SEO-optimized page showing all STR regulations for one city. This is the highest-value SEO page — people search "Airbnb Barcelona rules" or "Paris STR regulations 2025."

**URL examples:** `/cities/barcelona`, `/cities/paris`, `/cities/amsterdam`

**Content:**
- H1: "Short-term Rental Rules in [City] — [Year] Guide"
- Last updated date + source links
- Summary box: "Key facts in 60 seconds" (3–5 bullet points)
- Full compliance checklist table (public):
  - Requirement name
  - Description
  - Applicable to (all hosts / only primary residence / only tourist apartments)
  - Penalty for non-compliance
  - Official source link
- Section: "What changed recently" (last 2 regulatory alerts)
- CTA: "Track your compliance automatically — Free account"
- FAQ section (city-specific, 5–7 Q&A)

**SEO targets:**
- "Airbnb [city] rules [year]"
- "[city] short term rental license"
- "[city] STR compliance"
- "Airbnb [city] illegal"

---

#### `/pricing` — Pricing Page

**Plans:**

| | Free | Solo €9/mo | Host €19/mo | Pro €49/mo |
|---|---|---|---|---|
| Properties | 1 | 1 | 3 | Unlimited |
| Email reminders | — | ✓ | ✓ | ✓ |
| Regulatory alerts | — | ✓ | ✓ | ✓ |
| Document storage | — | 100MB | 250MB | 1GB |
| PDF report | — | — | — | ✓ |
| Priority updates | — | — | — | ✓ |

**CTA:** Monthly / Annual toggle (Annual = 2 months free)

---

### Auth Pages

#### `/login`

Fields: Email, Password
Links: "Forgot password" → `/forgot-password`, "No account" → `/register`
Redirect after login: `/dashboard`

#### `/register`

Fields: Full name, Email, Password, Country
Note: No phone number required in V1
After register: Email verification → redirect to `/dashboard/properties/new`

#### `/forgot-password` / `/reset-password`

Standard Supabase Auth flow.

---

### Dashboard Pages

#### `/dashboard` — Main Dashboard

**What the user sees:**
- Compliance score card: "Your properties are X% compliant"
- Overdue items list (red): items past deadline, not marked done
- Upcoming deadlines: next 5 deadlines across all properties
- Recent alerts: last 3 regulatory alerts for their cities
- Quick stats: Total properties / Total items / Items done / Documents uploaded

**Empty state (new user, no properties):**
- Single CTA card: "Add your first property to get your compliance checklist"

---

#### `/dashboard/properties` — Properties List

Each property card shows:
- Property name
- City + country flag
- Compliance score (% done)
- Next deadline (date + item name)
- Number of overdue items (red badge)
- Quick actions: View checklist, Add document, Edit property

---

#### `/dashboard/properties/new` — Add Property

**Step 1: Basic info**
- Property nickname (required)
- City (searchable dropdown, only active cities)
- Property type:
  - Entire apartment or house
  - Private room in primary residence
  - B&B (Bed & Breakfast)

**Step 2: Platforms**
- Which platforms? (checkboxes: Airbnb, Booking.com, Vrbo, Own website, Other)

**Step 3: Review**
- Shows generated checklist preview
- CTA: "Create property and view checklist"

---

#### `/dashboard/properties/[id]` — Property Compliance Checklist

**Header:**
- Property name, city, compliance score badge
- Progress bar: X of Y items complete

**Filter tabs:**
- All | Overdue | Pending | Done | Not Applicable

**Compliance item card:**
```
[Category icon]  Registration Number on Listing          [Status dropdown: ✓ Done]
                 You must display your registration number on your Airbnb listing.
                 Penalty: Up to €5,000 for non-compliance.
                 [How to comply ▼]    [View official source ↗]    [Upload document]
                 Deadline: Annual — Next due: January 31, 2027    [Set reminder]
```

---

#### `/dashboard/properties/[id]/documents` — Document Storage

Grid of uploaded documents:
- Thumbnail (PDF preview or file icon)
- File name
- Linked compliance item
- Upload date
- Download button
- Delete button

Upload button: drag-and-drop or click to upload (PDF, JPG, PNG)

---

#### `/dashboard/alerts` — Regulatory Alerts Inbox

List of all alerts for user's subscribed cities:
- Severity badge (Info / Warning / Critical)
- City name + date
- Title
- 2-line summary
- "Read more" → full alert page

---

#### `/dashboard/calendar` — Deadline Calendar

Monthly calendar view showing all compliance deadlines across all properties.
Click on deadline → opens the compliance item in a side panel.
Toggle: Month / List view.

---

### Account Pages

#### `/account/settings`

- Full name (editable)
- Email (editable, requires verification)
- Password (change password)
- Notification preferences:
  - Email reminders: 90 days / 30 days / 7 days / 1 day before deadline (toggles)
  - Regulatory alerts: On/Off
  - Product updates: On/Off
- Danger zone: Delete account

#### `/account/billing`

- Current plan + next billing date
- "Upgrade" / "Change plan" button
- Invoice history (links to Stripe)
- Cancel subscription (with confirmation dialog)

---

### Admin Pages

#### `/admin` — Admin Dashboard

Stats:
- Total users / Active subscribers / MRR
- Total properties / Cities covered / Compliance items
- Alerts sent this month
- Emails delivered (opens, clicks)

#### `/admin/cities` — City Management

Table: City name | Country | Active | # Items | Last reviewed | Actions (Edit, Deactivate)
Button: "Add city"

#### `/admin/compliance-items` — Compliance Items

Filterable table:
- City filter
- Category filter
- All compliance items with Edit action

#### `/admin/alerts/new` — Create Regulatory Alert

Fields:
- City (dropdown)
- Severity (Info / Warning / Critical)
- Title
- Short summary (used in email subject line, 120 chars max)
- Full text (rich text editor)
- Source URL
- Publish date (default: now)

Actions:
- "Preview email" → shows email template with this alert
- "Send to X users" → count of users in this city
- "Publish and send" → creates alert + queues emails

---

## SEO URL Strategy

Priority SEO pages (highest organic search potential):

| URL | Target keyword | Monthly search est. |
|---|---|---|
| /cities/barcelona | "Airbnb Barcelona rules" / "Barcelona STR license" | 2,400/mo |
| /cities/paris | "Paris Airbnb rules" / "Paris 120 night limit" | 3,200/mo |
| /cities/amsterdam | "Amsterdam Airbnb rules" / "Amsterdam 30 nights" | 1,800/mo |
| /cities/lisbon | "Lisbon Airbnb rules" / "Alojamento Local" | 1,200/mo |
| /cities/rome | "Rome Airbnb rules" / "Italy CIN code" | 900/mo |

Each city page = free SEO traffic + conversion to sign-up. These are the most important pages to get right.

---

## Redirect Rules

| Source | Destination | Reason |
|---|---|---|
| `/` (logged-in user) | `/dashboard` | Skip landing if authenticated |
| `/register` (logged-in) | `/dashboard` | Can't register again |
| `/dashboard/*` (logged-out) | `/login?redirect=[url]` | Auth guard |
| `/admin/*` (non-admin) | `/dashboard` | Role guard |
| After login | `redirect` param or `/dashboard` | Preserve intended destination |

---

## Page Status Indicators

Every compliance city page must show:
- "Last verified: [date]" in the header
- Specific official source links (no dead links)
- Any page older than 60 days without review shows a warning banner: "This information may be outdated. We're working on updating it."
