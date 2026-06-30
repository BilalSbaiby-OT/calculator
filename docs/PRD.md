# Product Requirements Document
## HostCompliant — Short-term Rental Compliance Platform

**Version:** 1.0  
**Status:** MVP Specification  
**Date:** June 2026

---

## 1. Product Overview

### What It Is

HostCompliant is a web application that helps Airbnb and short-term rental (STR) hosts in European cities stay compliant with local regulations. It gives hosts a personalized compliance checklist, tracks deadlines, stores their documents, and sends email alerts when regulations change.

### What It Is Not

- It is **not** a legal advice service
- It is **not** a booking management platform
- It is **not** a channel manager (Airbnb, Booking.com integration is not in V1)
- It is **not** a tax filing service

### One-Sentence Description

HostCompliant tells EU Airbnb hosts exactly what permits, registrations, and filings they need — and reminds them before each deadline.

---

## 2. Problem Statement

European cities are rapidly passing short-term rental regulations. Barcelona requires a HUTB license. Paris limits rentals to 120 nights per year and mandates a registration number on every listing. Amsterdam caps rentals at 30 nights per year. Italy now requires a national CIN code on all listings with fines up to €8,000 for non-compliance.

**The problem:** Hosts do not know what applies to them, do not know when deadlines are, and do not know when rules change. The only alternatives are:

- Facebook groups (outdated, anecdotal information)
- Expensive lawyers (€300–€1,000 per consultation)
- Airbnb's own notifications (legally cautious, incomplete, delayed)
- Government websites (in local language, complex, hard to find)

**The consequence:** Hosts receive fines ranging from €450 (Paris) to €90,000 (Barcelona). Some lose their license permanently.

---

## 3. Target Users

### Primary: The Individual Host

**Profile:**
- Rents 1–3 properties on Airbnb and/or Booking.com
- Earns €500–€5,000/month from STR
- Operates in a major EU city
- Is not a real estate professional — this is side income
- Age 30–60, typically owns their property or has long-term lease

**Pain:** Does not know which permits they need. Gets anxious every time they read about new regulations. Afraid of a surprise fine.

**Willingness to pay:** €9–€19/month easily. This is less than 1% of their monthly STR income.

### Secondary: The Professional Host

**Profile:**
- Manages 4–20 properties
- Operates as a business (sole proprietor or small company)
- May have staff or co-hosts

**Pain:** Tracking compliance across multiple cities and multiple properties is unmanageable. Currently uses a mix of spreadsheets and calendar reminders.

**Willingness to pay:** €49/month for unlimited properties.

### Tertiary: The Property Manager (B2B)

**Profile:**
- Property management company managing 20–200 short-term rentals for property owners
- Needs to demonstrate compliance to their clients

**Willingness to pay:** €99–€299/month, possibly white-label.

---

## 4. Value Proposition

| User | Before HostCompliant | After HostCompliant |
|---|---|---|
| Individual host | Stressed, unsure if compliant, relies on Facebook groups | Knows exactly what to do, gets reminders, sleeps well |
| Professional host | Spreadsheet per city, manual deadline tracking | Centralized dashboard, automated alerts, document archive |
| Property manager | Hours per month on compliance research | One tool for all properties, client-ready compliance reports |

---

## 5. Core Features — MVP (Version 1)

### F1: City Compliance Pages (Public)

Every covered city has a public page showing:
- Summary of STR regulations in plain language
- List of all compliance requirements (what, why, penalty for non-compliance)
- Rough difficulty rating (Easy / Moderate / Complex)
- Last updated date with source links
- CTA to create an account and track compliance for their property

This serves as SEO content and trust builder. No login required to read.

### F2: Property Setup

After registration, user creates a property:
- Name (e.g., "Apartment Montmartre")
- City (dropdown of covered cities)
- Property type (apartment / house / room in primary residence / B&B)
- Which platforms it's listed on (Airbnb, Booking.com, both)

Based on these inputs, the system generates a personalized compliance checklist.

### F3: Personalized Compliance Checklist

The checklist shows every compliance requirement that applies to the user's property given their city and property type.

Each item shows:
- Title (e.g., "Register with the municipality")
- Short description of what it is
- Why it matters / what fine applies
- How to comply (step-by-step guide with link to official source)
- Status: Not Started / In Progress / Done / Not Applicable
- Deadline date (if applicable)
- Document upload area (to store their permit, certificate, etc.)

### F4: Deadline Tracker

Dashboard view showing all upcoming compliance deadlines across all properties:
- Overdue items (red)
- Due within 30 days (orange)
- Due within 90 days (yellow)
- Done (green)

### F5: Email Deadline Reminders

Automated email reminders sent:
- 90 days before a deadline
- 30 days before a deadline
- 7 days before a deadline
- 1 day before a deadline

Users can configure which reminders they receive.

### F6: Regulatory Change Alerts

When a regulation changes in a covered city, all users with properties in that city receive an email alert:
- What changed
- Why it matters
- What action they need to take (if any)
- Link to the full regulatory alert page

### F7: Document Storage

For each compliance item, users can upload a document (PDF, image):
- Permit / license document
- Registration confirmation
- Tax filing receipt

Storage: Supabase Storage, 50MB per property on free tier, 500MB on paid.

### F8: Subscription & Billing (Stripe)

**Free tier:**
- 1 property
- 1 city
- Basic checklist (no reminders)
- No document storage

**Solo plan — €9/month:**
- 1 property
- Email reminders
- Regulatory alerts
- Document storage (100MB)

**Host plan — €19/month:**
- Up to 3 properties
- All free + Solo features
- Priority regulatory updates

**Professional plan — €49/month:**
- Unlimited properties
- All above features
- Multi-city coverage
- PDF compliance report export
- Early access to new cities

---

## 6. Features Explicitly Out of Scope for V1

The following will NOT be built in V1. Document this clearly to avoid scope creep.

- Booking channel synchronization (Airbnb API, Booking.com API)
- Automatic form submission to government agencies
- Legal advice or legal document templates
- Tax calculation or VAT filing
- Night count tracking (Airbnb provides this natively)
- Guest check-in reporting automation
- Mobile native app (iOS/Android) — web only
- API for third parties
- White-label for property managers
- Review/rating system for compliance consultants
- Payment processing between users
- Live chat support

---

## 7. Cities in V1 (Launch Cities)

| City | Country | Key Regulation | Complexity |
|---|---|---|---|
| Paris | France | 120-night limit, déclaration, registration number | Medium |
| Barcelona | Spain | HUTB license, 30-night/day limit in some zones | High |
| Amsterdam | Netherlands | 30-night annual limit, short-stay permit | High |
| Lisbon | Portugal | Alojamento Local registration, RNAL number | Medium |
| Rome | Italy | CIN national code, municipal registration | Medium |

**Cities for V2 (Month 2–3):** Berlin, Madrid, London (post-Brexit), Vienna, Dublin, Florence, Seville, Porto

---

## 8. Non-Functional Requirements

### Performance
- Pages load in under 2 seconds on 4G mobile
- Checklist updates (status change) respond in under 500ms
- Email delivery within 5 minutes of trigger

### Reliability
- 99.5% uptime (Vercel + Supabase guarantee covers this)
- Regulatory content reviewed monthly per city

### Security
- All user data stored in EU region (Supabase EU West)
- GDPR compliant: privacy policy, cookie consent, right to deletion
- No user data sold to third parties
- Documents stored in private Supabase Storage buckets (not public URLs)

### Accessibility
- WCAG 2.1 AA compliance for all core flows
- All text at minimum 4.5:1 contrast ratio

### Legal
- Disclaimer on every compliance page: "HostCompliant provides informational checklists only. This is not legal advice. Always consult a qualified lawyer for legal questions."
- Terms of Service limiting liability for inaccurate regulatory information
- GDPR privacy policy
- Cookie consent banner

---

## 9. Success Metrics (Month 1–3)

| Metric | Month 1 Target | Month 3 Target |
|---|---|---|
| Registered users | 100 | 500 |
| Properties created | 75 | 400 |
| Paying users | 10 | 100 |
| MRR | €90 | €1,200 |
| Email open rate (alerts) | >40% | >40% |
| Churn rate | <10% | <8% |
| NPS | >30 | >40 |

---

## 10. User Stories

### US-01: City Research (Unauthenticated)
> As a potential host, I want to read a plain-language summary of STR compliance requirements in my city so I can understand what I need before signing up.

**Acceptance criteria:**
- City page loads without login
- Lists all compliance items with descriptions
- Shows fines for non-compliance
- Has a clear CTA to create an account

### US-02: Property Registration
> As a new user, I want to set up my property so I get a checklist tailored to my specific situation.

**Acceptance criteria:**
- User selects city from dropdown (only covered cities available)
- User selects property type
- System generates personalized checklist immediately after
- Checklist shows only items applicable to their city and property type

### US-03: Mark Compliance Status
> As a host, I want to mark each compliance item as done, in progress, or not applicable so I can track my progress.

**Acceptance criteria:**
- Status can be updated with a single click/tap
- Timestamp recorded when status changes to "done"
- Dashboard shows overall % compliance score
- Overdue items highlighted in red

### US-04: Upload Compliance Document
> As a host, I want to upload my license or permit document against a compliance item so I have everything in one place.

**Acceptance criteria:**
- Accepts PDF, JPG, PNG up to 10MB per file
- File is stored securely (not publicly accessible URL)
- File can be downloaded by the user
- File can be deleted by the user

### US-05: Receive Deadline Reminder
> As a host, I want to receive email reminders before my compliance deadlines so I never miss them.

**Acceptance criteria:**
- Email sent at 90, 30, 7, 1 days before deadline
- Email contains the item name, deadline date, and link to the compliance item
- User can unsubscribe from individual reminder types in account settings

### US-06: Receive Regulatory Alert
> As a host, I want to be notified by email when regulations change in my city so I can act quickly.

**Acceptance criteria:**
- Email sent within 24 hours of alert being published
- Email contains plain-language summary of what changed
- Severity level clearly shown (Info / Warning / Critical)
- Link to full alert page in the app

### US-07: Upgrade to Paid Plan
> As a free user with 1 property who wants to add a second property, I want to upgrade my plan easily.

**Acceptance criteria:**
- Upgrade CTA shown when user tries to add second property on free plan
- Stripe Checkout opens in the same tab
- After payment, user is redirected back to dashboard with upgraded access
- Subscription can be managed (cancelled, downgraded) from account settings

### US-08: Admin Publishes Regulatory Alert
> As an admin, I want to publish a regulatory change alert for a city so all hosts in that city receive an email.

**Acceptance criteria:**
- Admin panel accessible only to users with admin role
- Form to create alert: city, title, summary, full text, severity, source URL
- On publish: alert appears in the app and emails are queued to all users with properties in that city
- Admin can preview email before sending

---

## 11. Assumptions and Dependencies

### Assumptions
- Regulatory information is available publicly from government sources
- Hosts are willing to self-manage their compliance status (no automation of government filings)
- Email delivery is the primary communication channel (no SMS/push in V1)
- Stripe is available in the founders' country of operation

### Dependencies
- Supabase (auth, database, storage)
- Resend or Postmark (transactional email)
- Stripe (subscriptions and billing)
- Vercel (hosting and cron jobs)
- Government regulatory sources (manually researched; no API)

---

## 12. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Regulatory info becomes outdated | High | High | Monthly review process + user reports + admin alerts |
| Legal liability for wrong information | Medium | High | Strong disclaimer, ToS, "not legal advice" everywhere |
| Airbnb builds this natively | Low | High | Go to market fast; Airbnb moves slowly on compliance |
| Low willingness to pay | Medium | High | Test with €9/month first; validate before building paid features |
| City regulations are too complex to summarize | Medium | Medium | Focus on the 3–5 most critical items per city, not 100% exhaustive |

---

*This PRD governs the V1 build of HostCompliant. Any feature not listed here requires a PRD amendment before being built.*
