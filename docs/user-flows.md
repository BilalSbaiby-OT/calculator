# User Flows
## HostCompliant

Key journeys from first visit to power user. Use these to design and QA every screen.

---

## Flow 1: First-Time Visitor → Registered User

```
Landing page (/)
    │
    ├── Reads headline: "Stay compliant with EU Airbnb rules"
    ├── Sees city search bar or city grid
    │
    ▼
User types or clicks their city (e.g. "Barcelona")
    │
    ▼
City page (/cities/barcelona)
    │
    ├── Reads summary: "Barcelona requires a HUTB license, guest registration..."
    ├── Sees compliance items table with fines listed
    ├── Feels: "I need to check if I'm compliant"
    │
    ▼
Clicks CTA: "Track my compliance — Free"
    │
    ▼
Register page (/register)
    │
    ├── Enter: Full name, email, password, country
    ├── Submit → verification email sent
    ├── Click verification link in email
    │
    ▼
Redirect to: Add first property (/dashboard/properties/new)
    │
    [See Flow 2]
```

**Key design notes:**
- The city page is the highest-converting page. It must clearly show pain (the fines) and the solution (the checklist).
- Don't require email verification before showing the dashboard. Let users see value immediately; verify before they can use paid features.

---

## Flow 2: Add First Property

```
/dashboard/properties/new

Step 1: Property details
    │
    ├── Field: Property nickname (e.g. "Apartment Raval")
    │           [placeholder: Give it a name you'll recognize]
    ├── Field: City (searchable dropdown — only active cities)
    │           [If their city is not listed: "We'll notify you when [city] launches"]
    ├── Field: Property type
    │           ○ Entire apartment or house
    │           ○ Private room in my primary residence
    │           ○ Bed & Breakfast
    │
    ▼
Step 2: Platforms
    │
    ├── Checkboxes:
    │    ☑ Airbnb
    │    ☐ Booking.com
    │    ☐ Vrbo
    │    ☐ My own website / direct bookings
    │    ☐ Other
    │
    ▼
Step 3: Preview
    │
    ├── "Based on your answers, here are the compliance items we'll track:"
    ├── List: [5 items for Barcelona entire apartment]
    ├── "We'll remind you before each deadline."
    ├── CTA: "Create my checklist →"
    │
    ▼
Property created → redirect to /dashboard/properties/[id]
    │
    [See Flow 3]
```

**Key design note:** Step 3 preview is important — it shows immediate value before the user commits. The user should think "oh wow, I didn't know about 3 of those items."

---

## Flow 3: First Compliance Checklist View

```
/dashboard/properties/[id]

Page loads with:
    │
    ├── Header: "Apartment Raval — Barcelona"
    ├── Progress bar: "1 of 5 items complete (20%)"
    ├── Alert if overdue items: "⚠ 1 item overdue"
    │
    ▼
Compliance checklist:
    │
    [OVERDUE — red banner]
    ├── ✗ Register guests with Mossos d'Esquadra (GES)
    │     "Due: Per guest check-in (event-based)"
    │     "Fine: €30,000–€600,000"
    │     [EXPAND ▼]
    │         "You must register each guest's ID within 24 hours..."
    │         Steps: 1. Register at GES portal 2. For each guest...
    │         [Official source ↗]
    │     [Mark as In Progress] [Mark as Done] [Upload document]
    │
    [PERMITS]
    ├── ✓ Hold valid HUTB license
    │     Status: Done  |  Renewed: Nov 15, 2025
    │     Next renewal: Nov 30, 2026
    │     [View document]
    │
    ├── ✗ Annual HUTB renewal
    │     Due: November 30, 2026 (153 days)
    │     [Mark as In Progress] [Mark as Done] [Upload document]
    │
    [TAX]
    ├── ✗ Quarterly tourist tax filing
    │     Due: July 15, 2026 (15 days)  ← highlighted orange
    │     [Mark as Done] [Upload document]
    │
    [DISPLAY]
    └── ✗ Display HUTB number on Airbnb listing
          Status: Not started
          Penalty: Up to €90,000
          [Mark as Done]
```

**Key design note:** The overdue item should be impossible to miss. The ones with upcoming deadlines should be sorted to the top. The user should feel "OK, I need to do the guest registration and the tax filing this week."

---

## Flow 4: Mark Item as Done

```
User clicks "Mark as Done" on a compliance item
    │
    ▼
Inline modal / slide-in panel:
    ├── Title: "Mark 'Quarterly tourist tax filing' as done"
    ├── Completed on: [date picker — default: today]
    ├── Notes: [optional text field] "Filed via Airbnb — ref #XXXX"
    ├── Upload document: [drag & drop] (optional)
    ├── [Cancel] [Mark as Done ✓]
    │
    ▼
Item updated:
    ├── Status changes to ✓ Done (green)
    ├── Next deadline auto-calculated (next quarter)
    ├── Toast: "Marked as done. Next deadline: October 15, 2026"
    └── Compliance score updates: "3 of 5 items complete (60%)"
```

---

## Flow 5: Receive and Act on Deadline Reminder

```
[Email arrives — 30 days before deadline]

Subject: "Reminder: HUTB Annual Renewal due in 30 days — Apartment Raval"

Body:
    ├── Property name + city
    ├── Item: "HUTB Annual Renewal"
    ├── Due: November 30, 2026 (30 days)
    ├── Penalty: Fine up to €90,000
    ├── How to start: "Renew via Generalitat de Catalunya portal"
    ├── [VIEW CHECKLIST button]
    └── "Already done? Mark it complete to stop reminders"

User clicks [VIEW CHECKLIST]
    │
    ▼
/dashboard/properties/[id]
    (scrolled to / highlighted: HUTB renewal item)
    │
    ▼
User follows the how-to-comply steps
    │
    ▼
User clicks "Mark as Done" → [See Flow 4]
```

---

## Flow 6: Receive Regulatory Alert

```
[Email arrives — admin published critical alert for Barcelona]

Subject: "🚨 Barcelona HUTB Update — Action may be required"

Body:
    ├── Severity: CRITICAL
    ├── Your affected property: "Apartment Raval — Barcelona"
    ├── Title: "Barcelona extends HUTB license suspension until 2029"
    ├── Summary: "The Barcelona city council has extended..."
    ├── [READ FULL ALERT button]
    └── "Review your compliance checklist for updates"

User clicks [READ FULL ALERT]
    │
    ▼
/dashboard/alerts/[id]
    │
    ├── Full alert text
    ├── Source link
    ├── "Affected properties" list
    └── "What you should do" action items (if applicable)
```

---

## Flow 7: Upgrade to Paid Plan

```
User tries to add second property on free plan
    │
    ▼
[Upgrade Modal appears]
    │
    ├── "You've reached the limit for your free plan"
    ├── "Upgrade to Host Plan to add up to 3 properties"
    │
    ├── Plan comparison:
    │    Free    Solo €9/mo   Host €19/mo
    │    1 prop  1 prop       3 props
    │    No email Reminders   Reminders
    │    alerts  + alerts     + alerts
    │                         + docs
    │
    ├── [Stay on Free] [Upgrade to Host — €19/mo →]
    │
    ▼
User clicks "Upgrade"
    │
    ▼
POST /api/billing/create-checkout
    │
    ▼
Stripe Checkout page (hosted by Stripe)
    ├── Plan: Host Monthly — €19.00
    ├── Enter card details
    ├── [Pay and subscribe]
    │
    ▼
Stripe webhook → subscription created
    │
    ▼
User redirected to /dashboard?upgrade=success
    ├── Toast: "You're now on the Host plan! Add up to 3 properties."
    └── User can now add second property [See Flow 2]
```

---

## Flow 8: Admin Publishes Regulatory Alert

```
Admin → /admin/alerts/new
    │
    ├── City: Barcelona [dropdown]
    ├── Severity: Critical [radio: Info / Warning / Critical]
    ├── Title: "HUTB renewal deadline extended to December 2026"
    ├── Summary: "The Generalitat de Catalunya has..."  [120 char limit]
    ├── Full text: [rich text editor]
    ├── Source URL: https://...
    │
    ├── [Preview email →]  (shows email template with this content)
    │
    ├── "This alert will be sent to 47 users with properties in Barcelona"
    │
    ├── [Save draft] [Publish without email] [Publish and send to 47 users]
    │
    ▼
Admin clicks "Publish and send"
    │
    ▼
POST /api/admin/alerts {send_emails: true}
    ├── Alert inserted
    ├── 47 emails queued via Resend
    └── Redirect to /admin/alerts/[id] with stats
```

---

## Flow 9: User Deletes Account (GDPR Right to Deletion)

```
/account/settings → Danger Zone → "Delete my account"
    │
    ▼
Confirmation dialog:
    ├── "Are you sure? This will permanently delete:"
    │    - Your account and profile
    │    - All 2 properties and their compliance data
    │    - All 5 uploaded documents
    │    - Your subscription (cancels immediately)
    │   "This cannot be undone."
    ├── Type "DELETE" to confirm: [text input]
    ├── [Cancel] [Delete account permanently]
    │
    ▼
DELETE /api/account
    ├── Cancel Stripe subscription immediately
    ├── Delete all documents from Supabase Storage
    ├── Delete all properties, compliance_statuses, documents (cascade)
    ├── Delete user_profile
    ├── Delete auth.users record (triggers Supabase cascade)
    ├── Log deletion in email_logs for compliance
    └── Redirect to / with message "Your account has been deleted"
```

---

## Empty States

Every key page needs an empty state that guides the user to their next action.

| Page | Empty State | CTA |
|---|---|---|
| Dashboard (no properties) | "Welcome to HostCompliant! Let's get you compliant." | "Add your first property →" |
| Properties list (0 properties) | Icon + "No properties yet" | "Add property" |
| Documents (0 documents) | "Upload your licenses and permits to keep them organized" | "Upload document" |
| Alerts inbox (no properties) | "Add a property to start receiving regulatory alerts for your city" | "Add property" |
| Calendar (no deadlines) | "No upcoming deadlines — all caught up!" | — |

---

## Error States

| Scenario | User sees |
|---|---|
| City not covered yet | "We don't cover [city] yet. Leave your email and we'll notify you when we do." + email capture |
| File upload fails | "Upload failed. Please try again. Max file size: 10MB. Accepted: PDF, JPG, PNG." |
| Stripe checkout fails | "Payment didn't go through. Please try again or contact us." |
| Session expired | Redirect to /login with message "Your session expired. Please log in again." |
| Network error on status update | Toast: "Couldn't save. Check your connection and try again." + retry button |
