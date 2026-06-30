-- GrantRadar Database Schema
-- PostgreSQL / Supabase
-- All tables have RLS enabled
-- Users own their companies, pipeline, and saved grants
-- Grants are public content managed by admin

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE funding_type AS ENUM (
  'grant',          -- non-repayable money
  'soft_loan',      -- below-market interest loan
  'tax_credit',     -- reduction in tax owed
  'guarantee',      -- loan guarantee
  'equity'          -- investment (rare in SME grants)
);

CREATE TYPE grant_deadline_type AS ENUM (
  'rolling',        -- applications accepted any time
  'annual',         -- same window every year
  'specific_date',  -- one-time deadline
  'quarterly',      -- opens every quarter
  'closed'          -- no longer accepting
);

CREATE TYPE company_size AS ENUM (
  'micro',    -- < 10 employees
  'small',    -- 10–49 employees
  'medium',   -- 50–249 employees
  'large'     -- 250+ (rarely eligible but included)
);

CREATE TYPE match_confidence AS ENUM (
  'strong',    -- all criteria met
  'likely',    -- most criteria met
  'possible'   -- some criteria met, worth checking
);

CREATE TYPE pipeline_status AS ENUM (
  'saved',
  'researching',
  'applied',
  'won',
  'lost',
  'ineligible'
);

CREATE TYPE subscription_tier AS ENUM (
  'free',
  'starter',
  'growth',
  'agency'
);

CREATE TYPE grant_category AS ENUM (
  'rd_innovation',
  'green_sustainability',
  'sme_growth',
  'export_internationalisation',
  'digital_transformation',
  'youth_new_business',
  'employment_training',
  'regional_development',
  'other'
);

CREATE TYPE difficulty_level AS INTEGER CHECK (VALUE BETWEEN 1 AND 3);
-- 1 = simple online form
-- 2 = moderate (business plan required)
-- 3 = complex (technical dossier, consultants recommended)

-- ============================================================
-- USER PROFILES
-- ============================================================

CREATE TABLE user_profiles (
  id                UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name         TEXT NOT NULL,
  email             TEXT NOT NULL,
  preferred_language TEXT NOT NULL DEFAULT 'en', -- en, fr, es, de, ar
  role              TEXT NOT NULL DEFAULT 'user', -- 'user' | 'admin'
  subscription_tier subscription_tier NOT NULL DEFAULT 'free',
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  subscription_current_period_end TIMESTAMPTZ,
  notif_new_matches BOOLEAN NOT NULL DEFAULT true,
  notif_deadline_30d BOOLEAN NOT NULL DEFAULT true,
  notif_deadline_7d  BOOLEAN NOT NULL DEFAULT true,
  notif_weekly_digest BOOLEAN NOT NULL DEFAULT true,
  notif_product      BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins read all profiles"
  ON user_profiles FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Auto-create profile on auth signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- GRANTS DATABASE (admin-managed, public-readable)
-- ============================================================

CREATE TABLE grants (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug                  TEXT UNIQUE NOT NULL, -- for SEO URLs: /grants/bpi-france-innovation

  -- Names (multilingual)
  name_en               TEXT NOT NULL,
  name_fr               TEXT,
  name_es               TEXT,
  name_de               TEXT,
  name_ar               TEXT,

  -- Descriptions (multilingual)
  short_description_en  TEXT NOT NULL, -- 1-2 sentences
  short_description_fr  TEXT,
  short_description_es  TEXT,
  short_description_de  TEXT,
  full_description_en   TEXT NOT NULL,
  full_description_fr   TEXT,
  full_description_es   TEXT,
  full_description_de   TEXT,

  -- How to apply (multilingual, markdown ok)
  how_to_apply_en       TEXT,
  how_to_apply_fr       TEXT,
  how_to_apply_es       TEXT,
  how_to_apply_de       TEXT,

  -- Classification
  category              grant_category NOT NULL,
  funding_type          funding_type NOT NULL DEFAULT 'grant',

  -- Geography
  country_code          TEXT NOT NULL, -- 'FR', 'ES', 'DE', 'EU', 'PT', 'NL', 'MA'
  region                TEXT, -- null = national/EU-wide; 'Île-de-France', 'Catalonia', etc.

  -- Funding body
  funding_body_name     TEXT NOT NULL, -- 'BPI France', 'CDTI', 'KfW'
  funding_body_logo_url TEXT,
  official_url          TEXT NOT NULL,

  -- Amounts
  min_amount            INTEGER, -- euros
  max_amount            INTEGER, -- euros; null = not specified
  typical_award_min     INTEGER, -- euros (typical range, lower)
  typical_award_max     INTEGER, -- euros (typical range, upper)

  -- Deadlines
  deadline_type         grant_deadline_type NOT NULL DEFAULT 'rolling',
  next_deadline_at      DATE, -- null for rolling
  deadline_notes        TEXT, -- 'Quarterly: Jan 15, Apr 15, Jul 15, Oct 15'

  -- Eligibility (structured for matching)
  eligibility_criteria  JSONB NOT NULL DEFAULT '{}',
  -- Example structure:
  -- {
  --   "min_employees": 1,
  --   "max_employees": 250,
  --   "min_revenue_eur": null,
  --   "max_revenue_eur": null,
  --   "company_age_min_years": null,
  --   "company_age_max_years": null,
  --   "eligible_sectors": ["manufacturing", "tech", "agri"],  -- null = all
  --   "excluded_sectors": ["financial_services", "real_estate"],
  --   "requires_rd": false,
  --   "requires_export": false,
  --   "requires_hiring": false,
  --   "requires_green_transition": false,
  --   "requires_digital_transition": false,
  --   "eligible_countries": ["FR"],  -- where company must be registered
  --   "eligible_regions": null  -- null = all regions of eligible_countries
  -- }

  difficulty            INTEGER NOT NULL DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 3),
  is_active             BOOLEAN NOT NULL DEFAULT true,
  is_featured           BOOLEAN NOT NULL DEFAULT false, -- shown on homepage/country pages

  -- Metadata
  last_verified_at      DATE NOT NULL DEFAULT CURRENT_DATE,
  verified_by           TEXT, -- admin user email
  internal_notes        TEXT, -- admin-only notes
  view_count            INTEGER NOT NULL DEFAULT 0,
  save_count            INTEGER NOT NULL DEFAULT 0,

  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Grants are public (anyone can read)
ALTER TABLE grants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read active grants"
  ON grants FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins full access to grants"
  ON grants FOR ALL
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE INDEX idx_grants_country ON grants(country_code) WHERE is_active;
CREATE INDEX idx_grants_category ON grants(category) WHERE is_active;
CREATE INDEX idx_grants_deadline ON grants(next_deadline_at) WHERE is_active AND deadline_type != 'closed';
CREATE INDEX idx_grants_eligibility ON grants USING gin(eligibility_criteria);

-- ============================================================
-- COMPANIES (user-owned profiles)
-- ============================================================

CREATE TABLE companies (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

  name                  TEXT NOT NULL,
  country_code          TEXT NOT NULL, -- where company is registered
  region                TEXT, -- for regional grant targeting
  city                  TEXT,
  founded_year          INTEGER,

  -- Size
  employee_count        INTEGER, -- actual number
  company_size          company_size NOT NULL DEFAULT 'small', -- derived from employee_count
  annual_revenue_eur    BIGINT, -- approximate, in euros

  -- Sector
  sector                TEXT NOT NULL, -- simplified: 'technology', 'manufacturing', 'agriculture', etc.
  nace_code             TEXT, -- optional precise NACE classification

  -- Activities (for eligibility matching)
  has_rd_activity       BOOLEAN NOT NULL DEFAULT false,
  rd_revenue_pct        INTEGER DEFAULT 0, -- % of revenue spent on R&D
  is_exporting          BOOLEAN NOT NULL DEFAULT false,
  export_regions        TEXT[], -- ['EU', 'MENA', 'Americas']
  is_hiring             BOOLEAN NOT NULL DEFAULT false,
  in_green_transition   BOOLEAN NOT NULL DEFAULT false,
  in_digital_transition BOOLEAN NOT NULL DEFAULT false,
  has_received_funding  BOOLEAN NOT NULL DEFAULT false, -- raised VC/PE in last 2 years

  -- Internal
  is_active             BOOLEAN NOT NULL DEFAULT true,
  last_matched_at       TIMESTAMPTZ, -- when match engine last ran for this company
  match_count           INTEGER NOT NULL DEFAULT 0, -- current active match count

  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own companies"
  ON companies FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Admins read all companies"
  ON companies FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE INDEX idx_companies_user ON companies(user_id) WHERE is_active;

-- ============================================================
-- GRANT MATCHES (computed, refreshed when grants or company profiles change)
-- ============================================================

CREATE TABLE grant_matches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  grant_id        UUID NOT NULL REFERENCES grants(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

  confidence      match_confidence NOT NULL,
  score           INTEGER NOT NULL, -- 0–100, used for ranking within confidence tier
  match_reasons   TEXT[], -- ['Company size matches', 'R&D activity qualifies', 'Sector eligible']
  mismatch_notes  TEXT[], -- ['Company may exceed revenue cap', 'Regional restriction applies']

  is_new          BOOLEAN NOT NULL DEFAULT true, -- shown as "new" until user opens it
  is_dismissed    BOOLEAN NOT NULL DEFAULT false, -- user clicked "not relevant"
  alerted_at      TIMESTAMPTZ, -- when alert email was sent for this match

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(company_id, grant_id)
);

ALTER TABLE grant_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own grant matches"
  ON grant_matches FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users dismiss own matches"
  ON grant_matches FOR UPDATE
  USING (auth.uid() = user_id);

CREATE INDEX idx_grant_matches_company ON grant_matches(company_id, confidence, score DESC);
CREATE INDEX idx_grant_matches_new ON grant_matches(user_id) WHERE is_new AND NOT is_dismissed;

-- ============================================================
-- GRANT PIPELINE (saved grants with status tracking)
-- ============================================================

CREATE TABLE grant_pipeline (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  grant_id        UUID NOT NULL REFERENCES grants(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

  status          pipeline_status NOT NULL DEFAULT 'saved',
  notes           TEXT,
  applied_at      DATE,
  result_at       DATE,
  amount_won      INTEGER, -- if status = 'won', how much was awarded

  reminded_30d    BOOLEAN NOT NULL DEFAULT false,
  reminded_7d     BOOLEAN NOT NULL DEFAULT false,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(company_id, grant_id)
);

ALTER TABLE grant_pipeline ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own pipeline"
  ON grant_pipeline FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_pipeline_company ON grant_pipeline(company_id, status);
CREATE INDEX idx_pipeline_deadlines ON grant_pipeline(user_id, reminded_30d, reminded_7d)
  WHERE status NOT IN ('won', 'lost', 'ineligible');

-- ============================================================
-- DOCUMENTS (uploaded to Supabase Storage)
-- ============================================================

CREATE TABLE documents (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  company_id          UUID REFERENCES companies(id) ON DELETE CASCADE,
  pipeline_entry_id   UUID REFERENCES grant_pipeline(id) ON DELETE CASCADE,

  original_filename   TEXT NOT NULL,
  storage_path        TEXT NOT NULL, -- 'documents/{user_id}/{company_id}/{filename}'
  mime_type           TEXT NOT NULL,
  file_size_bytes     INTEGER NOT NULL,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own documents"
  ON documents FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- EMAIL LOGS (for debugging + GDPR compliance)
-- ============================================================

CREATE TABLE email_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
  email_to        TEXT NOT NULL,
  template        TEXT NOT NULL, -- 'welcome', 'new_match', 'deadline_30d', 'deadline_7d', 'weekly_digest'
  company_id      UUID REFERENCES companies(id) ON DELETE SET NULL,
  grant_id        UUID REFERENCES grants(id) ON DELETE SET NULL,
  resend_id       TEXT, -- Resend message ID for tracking
  sent_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Admins only (for debugging)
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins read email logs"
  ON email_logs FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- REPORT HISTORY (PDF reports generated for accountants)
-- ============================================================

CREATE TABLE reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  title           TEXT NOT NULL, -- 'Grant Opportunities Report — Acme SAS — June 2026'
  grant_ids       UUID[] NOT NULL, -- which grants were included
  storage_path    TEXT NOT NULL, -- PDF stored in Supabase Storage

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own reports"
  ON reports FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- VIEWS
-- ============================================================

-- All active grants approaching deadline in next 30 days
CREATE VIEW grants_closing_soon AS
  SELECT
    g.id,
    g.slug,
    g.name_en,
    g.country_code,
    g.max_amount,
    g.next_deadline_at,
    g.next_deadline_at - CURRENT_DATE AS days_until_deadline,
    g.category,
    g.difficulty
  FROM grants g
  WHERE g.is_active
    AND g.deadline_type = 'specific_date'
    AND g.next_deadline_at BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
  ORDER BY g.next_deadline_at ASC;

-- Per-user pipeline items needing reminder
CREATE VIEW pipeline_deadline_reminders AS
  SELECT
    p.id AS pipeline_id,
    p.user_id,
    p.company_id,
    p.grant_id,
    p.reminded_30d,
    p.reminded_7d,
    g.name_en AS grant_name,
    g.next_deadline_at,
    g.next_deadline_at - CURRENT_DATE AS days_until,
    c.name AS company_name
  FROM grant_pipeline p
  JOIN grants g ON g.id = p.grant_id
  JOIN companies c ON c.id = p.company_id
  WHERE p.status NOT IN ('won', 'lost', 'ineligible')
    AND g.next_deadline_at IS NOT NULL
    AND g.next_deadline_at >= CURRENT_DATE;

-- Match feed for a company (used by API)
CREATE VIEW company_match_feed AS
  SELECT
    m.id AS match_id,
    m.company_id,
    m.user_id,
    m.confidence,
    m.score,
    m.match_reasons,
    m.is_new,
    g.id AS grant_id,
    g.slug,
    g.name_en,
    g.category,
    g.funding_type,
    g.country_code,
    g.max_amount,
    g.next_deadline_at,
    g.next_deadline_at - CURRENT_DATE AS days_until_deadline,
    g.difficulty,
    g.funding_body_name,
    g.funding_body_logo_url,
    g.short_description_en
  FROM grant_matches m
  JOIN grants g ON g.id = m.grant_id
  WHERE NOT m.is_dismissed
    AND g.is_active
  ORDER BY
    CASE m.confidence WHEN 'strong' THEN 1 WHEN 'likely' THEN 2 ELSE 3 END,
    COALESCE(g.next_deadline_at, '2099-01-01') ASC,
    m.score DESC;

-- ============================================================
-- MATCHING FUNCTION
-- Called when: new grant added, company profile updated, daily cron
-- ============================================================

CREATE OR REPLACE FUNCTION match_company_to_grants(p_company_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_company companies%ROWTYPE;
  v_grant grants%ROWTYPE;
  v_score INTEGER;
  v_confidence match_confidence;
  v_reasons TEXT[];
  v_mismatches TEXT[];
  v_matches_created INTEGER := 0;
  v_criteria JSONB;
BEGIN
  SELECT * INTO v_company FROM companies WHERE id = p_company_id;

  FOR v_grant IN SELECT * FROM grants WHERE is_active LOOP
    v_score := 0;
    v_reasons := ARRAY[]::TEXT[];
    v_mismatches := ARRAY[]::TEXT[];
    v_criteria := v_grant.eligibility_criteria;

    -- Country check (hard filter)
    IF v_criteria->'eligible_countries' IS NOT NULL THEN
      IF NOT (v_criteria->'eligible_countries' ? v_company.country_code) THEN
        CONTINUE; -- Skip this grant entirely
      END IF;
    END IF;

    -- Size check
    IF (v_criteria->>'max_employees')::INTEGER IS NOT NULL THEN
      IF v_company.employee_count > (v_criteria->>'max_employees')::INTEGER THEN
        CONTINUE;
      END IF;
    END IF;
    IF v_company.employee_count <= COALESCE((v_criteria->>'max_employees')::INTEGER, 999999) THEN
      v_score := v_score + 20;
      v_reasons := v_reasons || 'Company size qualifies';
    END IF;

    -- R&D check
    IF (v_criteria->>'requires_rd')::BOOLEAN = true THEN
      IF v_company.has_rd_activity THEN
        v_score := v_score + 25;
        v_reasons := v_reasons || 'R&D activity qualifies';
      ELSE
        v_score := v_score - 30;
        v_mismatches := v_mismatches || 'Grant requires R&D activity';
      END IF;
    END IF;

    -- Sector check
    IF v_criteria->'eligible_sectors' IS NOT NULL THEN
      IF v_criteria->'eligible_sectors' ? v_company.sector THEN
        v_score := v_score + 25;
        v_reasons := v_reasons || 'Sector eligible';
      ELSE
        v_score := v_score - 20;
        v_mismatches := v_mismatches || 'Sector may not be eligible';
      END IF;
    ELSE
      v_score := v_score + 10; -- open to all sectors
    END IF;

    -- Green/digital transition
    IF (v_criteria->>'requires_green_transition')::BOOLEAN = true AND v_company.in_green_transition THEN
      v_score := v_score + 20;
      v_reasons := v_reasons || 'Green transition activity matches';
    END IF;

    IF (v_criteria->>'requires_digital_transition')::BOOLEAN = true AND v_company.in_digital_transition THEN
      v_score := v_score + 20;
      v_reasons := v_reasons || 'Digital transition activity matches';
    END IF;

    -- Export check
    IF (v_criteria->>'requires_export')::BOOLEAN = true AND v_company.is_exporting THEN
      v_score := v_score + 15;
      v_reasons := v_reasons || 'Export activity qualifies';
    END IF;

    -- Skip if score too low
    IF v_score < 10 THEN
      CONTINUE;
    END IF;

    -- Determine confidence
    IF v_score >= 60 THEN
      v_confidence := 'strong';
    ELSIF v_score >= 35 THEN
      v_confidence := 'likely';
    ELSE
      v_confidence := 'possible';
    END IF;

    -- Upsert match
    INSERT INTO grant_matches (company_id, grant_id, user_id, confidence, score, match_reasons, mismatch_notes)
    VALUES (p_company_id, v_grant.id, v_company.user_id, v_confidence, v_score, v_reasons, v_mismatches)
    ON CONFLICT (company_id, grant_id) DO UPDATE SET
      confidence = EXCLUDED.confidence,
      score = EXCLUDED.score,
      match_reasons = EXCLUDED.match_reasons,
      mismatch_notes = EXCLUDED.mismatch_notes,
      updated_at = now();

    v_matches_created := v_matches_created + 1;
  END LOOP;

  -- Update company match count and last_matched_at
  UPDATE companies SET
    match_count = (SELECT COUNT(*) FROM grant_matches WHERE company_id = p_company_id AND NOT is_dismissed),
    last_matched_at = now()
  WHERE id = p_company_id;

  RETURN v_matches_created;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-match all companies when a new grant is added or updated
CREATE OR REPLACE FUNCTION rematch_all_on_grant_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Queue re-matching by setting last_matched_at to null
  -- The cron job picks these up and calls match_company_to_grants()
  UPDATE companies SET last_matched_at = NULL WHERE is_active;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_grant_changed
  AFTER INSERT OR UPDATE ON grants
  FOR EACH ROW EXECUTE FUNCTION rematch_all_on_grant_change();

-- ============================================================
-- SEED: GRANT CATEGORIES FOR REFERENCE
-- (Actual grant data inserted via admin panel, not seed)
-- ============================================================

-- Example grant record structure (for reference):
-- INSERT INTO grants (slug, name_en, short_description_en, full_description_en,
--   category, funding_type, country_code, funding_body_name, official_url,
--   max_amount, deadline_type, next_deadline_at, eligibility_criteria, difficulty)
-- VALUES (
--   'bpi-france-innovation-individuelle',
--   'BPI France — Individual Innovation Aid (Aide à l''Innovation Individuelle)',
--   'Non-repayable grant for French SMEs conducting R&D projects. Up to €600,000.',
--   'The Individual Innovation Aid from BPI France supports SMEs...',
--   'rd_innovation', 'grant', 'FR', 'BPI France',
--   'https://www.bpifrance.fr/nos-solutions/soutenir-linnovation/aides-individuelles-linnovation',
--   600000, 'rolling', NULL,
--   '{"eligible_countries": ["FR"], "max_employees": 250, "requires_rd": true,
--     "eligible_sectors": null, "excluded_sectors": ["financial_services"]}',
--   2
-- );
