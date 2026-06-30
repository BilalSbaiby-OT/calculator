# Product Requirements Document
## GrantRadar — EU Grant & Funding Navigator for SMEs

**Version:** 1.0  
**Date:** June 2026  
**Team:** 2-person founding team (multilingual: Arabic, French, English, Spanish, German)

---

## 1. Problem Statement

The EU and its member states distribute hundreds of billions of euros in grants, subsidies, and soft loans to SMEs every year. Most of that money goes unclaimed — not because businesses are ineligible, but because:

1. **Discovery is broken.** Grants are published in Dutch, French, Spanish, German, Italian. A Spanish SME doesn't know about a French innovation grant even though they have an office in Lyon.
2. **Fragmentation is extreme.** There are EU-level programs, national programs (BPI France, CDTI Spain, KfW Germany), and regional programs — all in different portals, different languages, different deadline formats.
3. **Deadlines are missed.** Grant windows are typically 30–90 days. By the time a business hears about one from their accountant, it's closed.
4. **Accountants are bottlenecked.** Most SME accountants would love to offer grant-finding as a value-add, but have no systematic way to scan all programs for 50 clients simultaneously.

**The result:** Billions in grants go unclaimed every year by businesses that would have qualified.

---

## 2. Solution

GrantRadar is a multilingual grant discovery and monitoring platform. It:

- Maintains a curated, structured database of EU, national, and regional grant programs across France, Spain, Germany, and EU-wide (launch markets)
- Matches grants to company profiles based on sector, size, country, activity, and eligibility criteria
- Sends alerts when new matching grants open or when deadlines approach
- Allows accountants to manage multiple company profiles and export grant matches to clients

The moat is data + language. GrantRadar is the only tool that monitors grants in 4 languages simultaneously and presents them in the user's preferred language.

---

## 3. Target Users

### Persona 1: The SME Owner (primary)
- **Name:** Miguel, 38, runs a 22-person manufacturing company in Valencia, Spain
- **Pain:** He knows EU grants exist but has no time to research them. His accountant mentioned one grant last year — deadline had already passed.
- **Goal:** Know which grants he qualifies for right now, get alerted before deadlines
- **WTP:** €49–79/month if it saves him a few hours and finds real money
- **Channel:** LinkedIn, accountant referral, Google search "EU grants for SMEs Spain"

### Persona 2: The Accountant / Fiscal Advisor (high-value)
- **Name:** Claire, 44, runs a 3-person accounting practice in Lyon, France
- **Pain:** Clients ask about grants but she has no tool to scan systematically. She manually checks BPI France every few months. She's losing clients to larger firms that offer this.
- **Goal:** A white-label tool she can use for all clients, generate a "grants report" per client
- **WTP:** €150–299/month for something that saves her 10h/month per client
- **Channel:** Accountant association newsletters, LinkedIn, referrals from other accountants
- **Note:** One accountant sale = 20–50 SME clients worth of data. This is the growth lever.

### Persona 3: The Grant Consultant (power user)
- **Name:** Omar, 31, freelance grant consultant working with Morocco-EU businesses
- **Pain:** Manually tracks 60+ grant programs across 3 countries. Uses a spreadsheet. Misses things.
- **Goal:** Automated monitoring, multi-client management, deadline tracking
- **WTP:** €199–299/month for a professional-grade tool
- **Channel:** Freelancer communities, LinkedIn, MENA-EU business networks

---

## 4. Launch Markets

**Phase 1 (launch):**
- 🇫🇷 France — BPI France, ADEME, regional councils (Grand Est, Île-de-France, etc.)
- 🇪🇸 Spain — CDTI, ICEX, IVACE, regional programs (Catalonia ACCIÓ, Basque SPRI)
- 🇩🇪 Germany — KfW, BAFA, BMWK programs
- 🇪🇺 EU-wide — Horizon Europe SME components, COSME successor, InvestEU SME window

**Phase 2 (month 3–6):**
- 🇵🇹 Portugal — IAPMEI, Portugal 2030
- 🇳🇱 Netherlands — RVO, WBSO
- 🇧🇪 Belgium — Wallonie Entreprises, Flanders Innovation
- 🇲🇦 Morocco/MENA — ANPME, CCG (unique angle for Arabic-speaking users)

---

## 5. Grant Categories

| Category | Examples |
|---|---|
| R&D & Innovation | Horizon Europe SME Instrument, CDTI IDI, BPI Innovation |
| Green & Sustainability | ADEME decarbonization grants, KfW renewable energy |
| SME Growth & Employment | COSME, national job creation subsidies |
| Export & Internationalization | ICEX Spain Export, BPI France Export |
| Digital Transformation | France Num, German Mittelstand digital |
| Youth & New Business | EU Erasmus for Young Entrepreneurs, national startup grants |

---

## 6. Core Features

### F1: Company Profile
Users create a profile for each company with:
- Legal name, country, region
- Founded year
- Employee count (micro/small/medium)
- Annual revenue range
- Sector (simplified 15-category taxonomy + NACE code optional)
- R&D activity (yes/no + % of revenue)
- Export activity (yes/no + destination regions)
- Recent investment (raised funding in last 2 years?)
- Specific activities: hiring, training, green transition, digital transition

**Why it matters:** Eligibility matching depends on these fields. More fields = better matches.

---

### F2: Grant Database
Admin-curated database of grants with:
- Name (in original language + English)
- Program (parent funding program)
- Country / region applicability
- Funding type: grant / soft loan / tax credit / guarantee
- Maximum amount
- Typical award range
- Deadline type: rolling / annual / specific date
- Next deadline (if known)
- Eligibility criteria (structured: min/max employees, sectors, countries, activities)
- Short description (1–2 sentences, multilingual)
- Full description (translated)
- Application process summary
- Official source URL
- Last verified date
- Difficulty: 1 (simple form) → 3 (complex application, consultants usually needed)
- Is active: boolean

**Target at launch:** 80–120 grants across 4 markets.

---

### F3: Match Engine
When a company profile is submitted or updated:
1. Score each active grant against the company profile
2. Filter out clear ineligibles (wrong country, wrong size, sector excluded)
3. Rank remaining by: match confidence, deadline urgency, funding amount
4. Present as a match feed: "47 grants match your profile"

Match confidence levels:
- **Strong match** — all criteria met
- **Likely match** — most criteria met, 1–2 uncertain
- **Possible match** — some criteria met, worth reviewing

---

### F4: Grant Cards & Detail Pages
Each grant shows:
- Name + funding body logo
- Max amount (€) — shown prominently
- Deadline + days remaining (color-coded: red <14d, orange <30d, green >30d)
- Match confidence badge
- 2-sentence why-it-matches explanation
- Expand to see: full eligibility, how to apply, steps, official link
- Actions: Save, Mark Applied, Mark Ineligible (removes from feed)
- Share via email link

---

### F5: Alerts & Notifications
- Email alert when a new grant opens that matches the company profile
- Email reminder: 30 days before deadline, 7 days before deadline
- Weekly digest: "New grants this week for [Company Name]" (opt-in)
- Alert preferences per company profile

---

### F6: Saved Grants & Pipeline
For each saved grant, users can track:
- Status: Saved / Researching / Applied / Won / Lost / Ineligible
- Notes
- Uploaded documents (draft application, supporting docs)
- Deadline reminder set
- Assigned to (for accountant multi-client accounts)

---

### F7: Accountant Dashboard (multi-company)
For Starter+ plans:
- Manage multiple company profiles from one account
- See a unified "new matches this week" across all clients
- Generate a **Grant Opportunities Report** (PDF) per client with their top 10 matches
- Mark grants as "sent to client"
- Client list with compliance summary (how many active grants they should be tracking)

---

### F8: Admin Panel
- Add/edit/delete grants in the database
- Mark grants as expired or updated
- See which grants have the most saves/views
- Trigger re-match for all companies when a new grant is added
- Publish announcements ("New French R&D grant added — 47 companies affected")

---

## 7. Out of Scope (V1)

- Writing or submitting grant applications
- Legal advice or guarantee of grant success
- Tax filing automation
- Accounting software integration (QuickBooks, Sage)
- Mobile app
- Grant application templates (V2)
- Application deadline calendar sync (V2)
- Success-fee tracking (V2)
- Non-EU markets except Morocco (V2)
- Real-time scraping (V1 is manually curated; scraper is V2)

---

## 8. Pricing

| Plan | Price | Company Profiles | Alerts | PDF Reports | Grant Pipeline |
|---|---|---|---|---|---|
| Free | €0 | 1 | ✗ | ✗ | Save only |
| Starter | €29/mo | 1 | ✓ | ✗ | Full |
| Growth | €79/mo | 5 | ✓ | ✓ | Full |
| Agency | €199/mo | Unlimited | ✓ | ✓ White-label | Full + client mgmt |

Annual discount: 20% (2 months free)

**Free plan limits:** Shows up to 10 grant matches. No email alerts. No saving pipeline status. CTA to upgrade on every alert.

---

## 9. User Stories

**US-01:** As an SME owner, I want to enter my company details once and see a list of grants I actually qualify for, so I don't waste time reading irrelevant programs.

**US-02:** As an SME owner, I want to receive an email when a new grant matching my company opens, so I never miss an opportunity due to late discovery.

**US-03:** As an SME owner, I want to see how many days until each grant deadline, so I can prioritize which ones to pursue this month.

**US-04:** As an accountant, I want to manage 20 client profiles from one dashboard, so I can offer grant-finding as a standard service without 20 different logins.

**US-05:** As an accountant, I want to generate a PDF report of top grant matches per client, so I can send them a professional summary with minimal effort.

**US-06:** As a user, I want to mark a grant as "Applied" and add notes, so I can track my pipeline without a separate spreadsheet.

**US-07:** As a free user, I want to see some matches immediately (without paying), so I can evaluate whether the platform is worth subscribing to.

**US-08:** As a grant consultant, I want to be alerted 30 days and 7 days before each grant deadline, so I have time to prepare applications for my clients.

---

## 10. Technical Constraints

- Next.js 14 (App Router) with TypeScript
- Supabase (Postgres + Auth + Storage + RLS)
- Resend for email (alerts, digests, reminders)
- Stripe for subscriptions
- Vercel for hosting + cron jobs
- Grant database: manually curated at launch, schema supports future scraper ingestion
- PDF generation: server-side with Puppeteer or React-PDF (Growth+ only)
- All text content stored in original language + English translation; UI language follows user preference
- GDPR compliant: EU data storage (Supabase EU region), right to deletion

---

## 11. Success Metrics

| Milestone | Target |
|---|---|
| Week 2 | 10 company profiles created (validation) |
| Month 1 | 5 paying users, €145 MRR |
| Month 2 | 20 paying users, €580 MRR |
| Month 3 | 1 accountant on Agency plan + 30 Starter users = €1,367 MRR |
| Month 6 | 3 agency accounts + 80 starters = €3,917 MRR |
| Month 12 | 10 agency + 200 starters + 30 growth = €6,270 MRR |

**Key leading indicators:**
- Company profiles created per week
- Grant match click-through rate (did they visit the official grant page?)
- Alert email open rate (target >40%)
- Free → paid conversion (target >8%)
- Accountant referral rate (each accountant should refer 0.5 others)
