-- =====================================================
-- COLLINA PLATFORM - DATABASE REFERENCE
-- =====================================================
-- Version: 2.0
-- Last Updated: January 20, 2026
-- Gist URL: https://gist.github.com/markosavic82-droid/632f3e59823fc26ae18f985e8dd40c4f
-- 
-- ⚠️ INSTRUKCIJE ZA AI:
-- Pre SVAKOG SQL upita ili koda koji radi sa bazom:
-- 1. PROČITAJ ovaj fajl
-- 2. PROVERI tačna imena kolona
-- 3. KORISTI ispravne JOIN patterne
-- 4. POŠTUJ redosled brisanja (foreign key dependencies)
--
-- NIKADA ne piši SQL "iz glave" - UVEK proveri ovde prvo!
-- =====================================================


-- #####################################################
-- PART A: DATABASE TABLES
-- #####################################################


-- =====================================================
-- SECTION 1: AUTHENTICATION & USERS
-- =====================================================

-- TABLE: pazar_users (glavni employee table)
-- Napomena: Planirano preimenovanje u "employees" u budućnosti
-- KORISTI SE U: AuthContext, pazarAuthStore, svi JOIN-ovi za user imena
-- =====================================================
/*
KOLONE:
  id                  UUID PRIMARY KEY        -- Primarni ključ
  first_name          VARCHAR NOT NULL        -- Ime
  last_name           VARCHAR NOT NULL        -- Prezime
  pin                 VARCHAR(5)              -- 5-cifreni PIN (null za management)
  role                VARCHAR NOT NULL        -- admin, finansije, menadzer, konobar, vozac
  email               VARCHAR                 -- Email za management login
  default_location_id UUID                    -- Podrazumevana lokacija
  auth_user_id        UUID                    -- Veza sa Supabase Auth
  is_active           BOOLEAN NOT NULL        -- Da li je aktivan

ROLES:
  'admin'      - Email+Password login, Desktop, full access
  'finansije'  - Email+Password login, Desktop, Analytics (view), Finance, Pazar
  'menadzer'   - Email+Password login, Desktop, Analytics (view), Orders, Team (view), Pazar
  'konobar'    - PIN login, Mobile, Staff App - Shift cards
  'vozac'      - PIN login, Mobile, Staff App - Pickup cards

RPC FUNKCIJA:
  search_pazar_users(search_term) - Koristi se za PIN login pretragu
*/

-- Primer: Dohvati sve aktivne konobara
SELECT id, first_name, last_name, pin, default_location_id
FROM pazar_users
WHERE role = 'konobar' AND is_active = true;

-- AuthContext koristi ovaj upit:
SELECT * FROM pazar_users 
WHERE email = 'user@email.com' OR auth_user_id = 'uuid';


-- TABLE: module_permissions (STARIJI SISTEM)
-- KORISTI SE U: AuthContext.fetchEmployeeData
-- =====================================================
/*
KOLONE:
  id          UUID PRIMARY KEY
  role        VARCHAR NOT NULL        -- Role name (string match)
  module      VARCHAR NOT NULL        -- Module name
  can_view    BOOLEAN DEFAULT false
  can_create  BOOLEAN DEFAULT false
  can_edit    BOOLEAN DEFAULT false
  can_delete  BOOLEAN DEFAULT false

MODULES:
  'analytics', 'finance', 'orders', 'team', 'pazar', 'magacin'
*/

-- AuthContext koristi ovaj upit:
SELECT module, can_view, can_edit, can_delete
FROM module_permissions
WHERE role = 'admin';


-- TABLE: role_module_permissions (NOVIJI SISTEM)
-- KORISTI SE U: PermissionGuard.jsx
-- =====================================================
/*
KOLONE:
  id          UUID PRIMARY KEY
  role_id     UUID                    -- FK to roles table?
  module_id   UUID                    -- FK to modules table?
  can_view    BOOLEAN
  can_edit    BOOLEAN
  can_delete  BOOLEAN

⚠️ NAPOMENA: Dva sistema permisija postoje paralelno!
  - module_permissions: koristi role kao STRING
  - role_module_permissions: koristi role_id kao UUID
*/


-- =====================================================
-- SECTION 2: LOCATIONS
-- =====================================================

-- TABLE: pazar_locations
-- KORISTI SE U: StaffHeader, pickupService, pazarFinanceService
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY        -- UUID format: a1000000-0000-0000-0000-00000000000X
  name            VARCHAR NOT NULL        -- Ime lokacije
  code            VARCHAR NOT NULL        -- Kratki kod (MP-PAL, MP-P47, etc.)
  address         VARCHAR                 -- Adresa
  current_deposit NUMERIC                 -- Trenutni depozit
  is_active       BOOLEAN DEFAULT true    -- Da li je aktivna
  created_at      TIMESTAMPTZ
  updated_at      TIMESTAMPTZ
  deleted_at      TIMESTAMPTZ             -- Soft delete

⚠️ VAŽNO - LOCATION ID TYPES:
  - pazar_locations.id = UUID (a1000000-0000-0000-0000-000000000001)
  - eMeni company_id = INTEGER/STRING (310, 1513, 1514, etc.)
  
  NIKADA ne mešaj ove tipove! Frontend mora slati UUID, ne eMeni ID.

PRODUCTION LOCATIONS:
  UUID                                     | Name                    | Code
  a1000000-0000-0000-0000-000000000001    | Palacinkarnica Collina  | MP-PAL
  a1000000-0000-0000-0000-000000000002    | Collina Pozeska 47      | MP-P47
  a1000000-0000-0000-0000-000000000003    | Collina Pozeska 96      | MP-P96
  a1000000-0000-0000-0000-000000000004    | Collina Novi Beograd    | MP-NBG
  a1000000-0000-0000-0000-000000000005    | Collina Dravska         | MP-DRV
  a1000000-0000-0000-0000-000000000006    | Pekarica Collina        | PRO-PEK
  a1000000-0000-0000-0000-000000000007    | Food Truck              | FT
*/

-- StaffHeader koristi ovaj upit:
SELECT id, name, code FROM pazar_locations WHERE is_active = true ORDER BY name;


-- TABLE: emeni_locations
-- KORISTI SE U: analyticsService.fetchLocations
-- =====================================================
/*
KOLONE:
  company_id      INTEGER/VARCHAR         -- eMeni company ID (310, 1513, etc.)
  location_name   VARCHAR                 -- Ime lokacije u eMeni sistemu

⚠️ OVO JE ODVOJENA TABELA OD pazar_locations!
  - emeni_locations: za Analytics modul (eMeni podaci)
  - pazar_locations: za Pazar modul (cash management)
*/


-- =====================================================
-- SECTION 3: PAZAR - SHIFTS
-- =====================================================

-- TABLE: pazar_shifts
-- KORISTI SE U: pazarService (sve shift funkcije), pazarFinanceService
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY
  location_id     UUID NOT NULL           -- FK → pazar_locations(id)
  date            DATE NOT NULL           -- Datum smene
  user_id         UUID NOT NULL           -- FK → pazar_users(id) - ko radi smenu
  shift_order     INTEGER                 -- Redni broj smene tog dana (1, 2, 3...)
  starting_amount NUMERIC                 -- Početni iznos (depozit)
  ending_amount   NUMERIC                 -- Završni iznos (keš u kasi)
  status          VARCHAR                 -- 'active', 'handed_over', 'closed'
  is_first_shift  BOOLEAN DEFAULT false   -- Da li je prva smena dana
  is_last_shift   BOOLEAN DEFAULT false   -- Da li je poslednja smena dana
  started_at      TIMESTAMPTZ
  ended_at        TIMESTAMPTZ
  created_at      TIMESTAMPTZ

STATUS VALUES:
  'active'       - Smena je u toku
  'handed_over'  - Predato kolegi (prelazak smene)
  'closed'       - Zatvoreno (kraj dana)

⚠️ NAPOMENA: is_last_shift = true označava kraj radnog dana na lokaciji
*/

-- Primer: Dohvati aktivnu smenu za lokaciju
SELECT * FROM pazar_shifts 
WHERE location_id = 'a1000000-0000-0000-0000-000000000001' 
  AND date = CURRENT_DATE 
  AND status = 'active';

-- pazarFinanceService.loadPazarData koristi:
SELECT *, 
  user:pazar_users!user_id(id, first_name, last_name),
  location:pazar_locations(id, code, name)
FROM pazar_shifts
WHERE date >= '2026-01-19' AND date <= '2026-01-19'
ORDER BY date DESC, location_id, shift_order;


-- TABLE: pazar_shift_handovers
-- KORISTI SE U: pazarService (createHandover, takeoverShift)
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY
  location_id     UUID NOT NULL           -- FK → pazar_locations(id)
  date            DATE NOT NULL
  from_shift_id   UUID NOT NULL           -- FK → pazar_shifts(id) - prethodna smena
  to_shift_id     UUID NOT NULL           -- FK → pazar_shifts(id) - nova smena
  from_user_id    UUID                    -- FK → pazar_users(id)
  to_user_id      UUID                    -- FK → pazar_users(id)
  reported_amount NUMERIC                 -- Prijavljeni iznos
  received_amount NUMERIC                 -- Primljeni iznos
  handover_type   VARCHAR                 -- Tip predaje
  confirmed_at    TIMESTAMPTZ
  created_at      TIMESTAMPTZ

⚠️ GREŠKA KOJA SE DEŠAVALA:
  Kolona se zove "from_shift_id", NE "handed_over_shift_id"!
*/


-- =====================================================
-- SECTION 4: PAZAR - DAILY SPECIFICATIONS
-- =====================================================

-- TABLE: pazar_daily_specifications
-- KORISTI SE U: pazarService (createSpecification, endShiftHandover)
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY
  location_id     UUID NOT NULL           -- FK → pazar_locations(id)
  date            DATE NOT NULL
  shift_id        UUID                    -- FK → pazar_shifts(id)
  user_id         UUID                    -- FK → pazar_users(id)
  
  -- eBar podaci
  ebar_total      NUMERIC                 -- Ukupno sa eBara
  ebar_cash       NUMERIC                 -- Gotovina
  ebar_card       NUMERIC                 -- Kartice
  ebar_transfer   NUMERIC                 -- Transfer
  ebar_printed_at TIMESTAMPTZ             -- Kada je štampano
  
  -- Prebrojano
  terminal_amount NUMERIC                 -- Terminal (kartice)
  deposit_amount  NUMERIC                 -- Depozit u kasi
  counted_amount  NUMERIC                 -- Prebrojani keš
  
  -- Kalkulacije
  expected_cash   NUMERIC                 -- Očekivani keš = ebar_cash - terminal
  for_safe_actual NUMERIC                 -- Za sef
  difference      NUMERIC                 -- Razlika
  difference_type VARCHAR                 -- 'shortage', 'surplus', 'balanced'
  
  -- Dopuna
  topup_amount    NUMERIC                 -- Dopuna iznos
  topup_source    VARCHAR                 -- Izvor dopune
  topup_comment   TEXT                    -- Komentar
  
  -- Manjak
  shortage_reason VARCHAR
  shortage_comment TEXT
  
  -- Meta
  photo_url       VARCHAR
  confirmed_at    TIMESTAMPTZ
  created_at      TIMESTAMPTZ
  updated_at      TIMESTAMPTZ
*/

-- FORMULA ZA SRAVNJENJE (KRITIČNO!):
-- expected_cash = ebar_cash - terminal_amount (NE ebar_total!)
-- difference = counted_amount - expected_cash


-- TABLE: pazar_specification_denominations
-- KORISTI SE U: pazarService, pazarFinanceService
-- =====================================================
/*
KOLONE:
  id                UUID PRIMARY KEY
  specification_id  UUID NOT NULL           -- FK → pazar_daily_specifications(id)
  denomination      INTEGER NOT NULL        -- Apoenska vrednost
  quantity          INTEGER NOT NULL        -- Broj novčanica/kovanica (NE "count"!)
  created_at        TIMESTAMPTZ

APOENI (Serbian RSD):
  5000, 2000, 1000, 500, 200, 100, 50, 20, 10

⚠️ NAPOMENA: Kolona se zove "quantity", ne "count"!
*/


-- TABLE: pazar_cash_collections
-- KORISTI SE U: pazarService.endShiftEndOfDay
-- =====================================================
/*
KOLONE:
  id                UUID PRIMARY KEY
  specification_id  UUID NOT NULL           -- FK → pazar_daily_specifications(id)
  location_id       UUID
  date              DATE
  amount            NUMERIC
  status            VARCHAR
  created_at        TIMESTAMPTZ

⚠️ DEPENDENCY: Mora se obrisati PRE pazar_daily_specifications!
*/


-- =====================================================
-- SECTION 5: PAZAR - CASH PICKUP & FINANCE
-- =====================================================

-- TABLE: pazar_cash_pickups
-- KORISTI SE U: pickupService, pazarFinanceService, AdminPickupsPage
-- =====================================================
/*
KOLONE:
  id                  UUID PRIMARY KEY
  location_id         UUID NOT NULL           -- FK → pazar_locations(id)
  date                DATE NOT NULL
  driver_id           UUID                    -- FK → pazar_users(id) - vozač
  picked_at           TIMESTAMPTZ             -- Kada je pokupljeno
  delivered_at        TIMESTAMPTZ             -- Kada je dostavljeno
  created_at          TIMESTAMPTZ
  pickup_photos       JSONB                   -- Array base64 fotografija
  
  -- Verifikacija (opciono, može biti null)
  verified_at         TIMESTAMPTZ
  verified_amount     NUMERIC
  verified_by         UUID                    -- FK → pazar_users(id)
  amount_difference   NUMERIC
  verification_notes  TEXT

⚠️ NAPOMENA: Ova tabela NEMA kolonu "status"!
   Status se određuje po tome koja polja su popunjena:
   - picked_at IS NOT NULL = pokupljeno
   - delivered_at IS NOT NULL = dostavljeno
   - verified_at IS NOT NULL = verifikovano
*/

-- pickupService koristi:
SELECT *, driver:pazar_users!driver_id(id, first_name, last_name)
FROM pazar_cash_pickups
WHERE date = '2026-01-19';


-- TABLE: pazar_finance_records (GLAVNA TABELA ZA TOK NOVCA)
-- KORISTI SE U: pazarFinanceService, ReceiveModal, CountModal, BankDepositModalNew
-- =====================================================
/*
KOLONE:
  id                    UUID PRIMARY KEY
  pickup_id             UUID UNIQUE             -- FK → pazar_cash_pickups(id), UNIQUE CONSTRAINT!
  location_id           UUID NOT NULL           -- FK → pazar_locations(id)
  date                  DATE NOT NULL
  
  -- Prijem keša
  received_by           UUID                    -- FK → pazar_users(id)
  received_at           TIMESTAMPTZ
  
  -- Prebrojavanje
  counted_amount        INTEGER
  counted_at            TIMESTAMPTZ
  original_amount       INTEGER
  original_denominations JSONB                  -- {"5000": 2, "2000": 5, ...}
  modified_denominations JSONB
  spec_modified         BOOLEAN DEFAULT false
  modification_reason   TEXT
  modification_comment  TEXT
  
  -- Verifikacija (stavljanje u sef)
  verified_by           UUID                    -- FK → pazar_users(id)
  verified_at           TIMESTAMPTZ
  in_safe_at            TIMESTAMPTZ
  safe_transaction_id   UUID
  
  -- Preuzimanje iz sefa
  taken_from_safe_at    TIMESTAMPTZ
  taken_by              UUID                    -- FK → pazar_users(id)
  
  -- Uplatnica podaci
  payer_company_id      UUID                    -- FK → companies(id)
  recipient_company_id  UUID                    -- FK → companies(id)
  bank_account_id       UUID                    -- FK → bank_accounts(id)
  purpose_id            UUID                    -- FK → payment_purposes(id)
  
  -- Deponovanje u banku
  banked_at             TIMESTAMPTZ
  banked_by             UUID                    -- FK → pazar_users(id)
  bank_reference        VARCHAR
  bank_deposit_id       UUID
  
  -- Diskrepancija
  discrepancy_reason    TEXT
  discrepancy_comment   TEXT
  
  created_at            TIMESTAMPTZ

⚠️ KRITIČNE NAPOMENE:
  1. pickup_id ima UNIQUE CONSTRAINT - ne možeš imati dva recorda za isti pickup!
     Greška: "duplicate key value violates unique constraint pazar_finance_records_pickup_id_key"
     
  2. STATUS SE ODREĐUJE PO KOLONAMA (nema eksplicitna "status" kolona):
     - PRIMLJENO: received_at IS NOT NULL
     - PREBROJANO: counted_amount IS NOT NULL
     - U SEFU: verified_at IS NOT NULL AND taken_from_safe_at IS NULL
     - NA PUTU: taken_from_safe_at IS NOT NULL AND banked_at IS NULL
     - DEPONOVANO: banked_at IS NOT NULL

  3. VIŠE FK KA pazar_users - Supabase ne zna automatski koji JOIN da koristi!
*/


-- TABLE: pazar_bank_deposits
-- KORISTI SE U: pazarService.endShiftEndOfDay, CountModal, FinanceBankPage
-- =====================================================
/*
KOLONE:
  id                  UUID PRIMARY KEY
  location_id         UUID                    -- FK → pazar_locations(id)
  date                DATE
  amount              NUMERIC
  status              VARCHAR                 -- 'in_safe', 'in_transit', 'deposited', 'confirmed'
  denomination_counts JSONB                   -- {"5000": 2, "2000": 5, ...}
  deposit_date        DATE
  notes               TEXT
  deposited_at        TIMESTAMPTZ
  deposited_by        UUID                    -- FK → pazar_users(id)
  confirmed_at        TIMESTAMPTZ
  bank_reference      VARCHAR
  created_at          TIMESTAMPTZ

STATUS VALUES:
  'in_safe'     - Novac je u sefu
  'in_transit'  - Novac je na putu do banke
  'deposited'   - Deponovano u banku
  'confirmed'   - Potvrđeno
*/


-- TABLE: pazar_safe_transactions
-- KORISTI SE U: FinanceSafePage, FinanceBankPage
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY
  type            VARCHAR                 -- 'deposit', 'withdraw'
  amount          NUMERIC
  source          VARCHAR                 -- Izvor transakcije
  reference_id    UUID                    -- Referenca na drugi zapis
  notes           TEXT
  created_by      UUID                    -- FK → pazar_users(id)
  created_at      TIMESTAMPTZ
*/


-- =====================================================
-- SECTION 6: BANK DEPOSIT SUPPORTING TABLES
-- =====================================================

-- TABLE: companies
-- KORISTI SE U: TakeFromSafeModal, BankSettingsPage
-- =====================================================
/*
KOLONE:
  id          UUID PRIMARY KEY
  name        VARCHAR NOT NULL        -- Collina DOO, etc.
  pib         VARCHAR                 -- PIB
  address     VARCHAR
  is_active   BOOLEAN DEFAULT true
  is_default  BOOLEAN DEFAULT false   -- Podrazumevana kompanija
  created_at  TIMESTAMPTZ
*/


-- TABLE: bank_accounts
-- KORISTI SE U: TakeFromSafeModal, BankSettingsPage
-- =====================================================
/*
KOLONE:
  id            UUID PRIMARY KEY
  company_id    UUID                    -- FK → companies(id)
  bank_name     VARCHAR NOT NULL        -- Raiffeisen, Intesa, etc.
  account_number VARCHAR NOT NULL       -- Broj računa (NE "account_no"!)
  is_active     BOOLEAN DEFAULT true
  is_primary    BOOLEAN DEFAULT false   -- Primarni račun
  created_at    TIMESTAMPTZ
*/


-- TABLE: payment_purposes
-- KORISTI SE U: TakeFromSafeModal, BankSettingsPage
-- =====================================================
/*
KOLONE:
  id          UUID PRIMARY KEY
  name        VARCHAR NOT NULL        -- Pazar, Dnevni pazar, etc.
  code        VARCHAR                 -- Šifra svrhe plaćanja
  is_active   BOOLEAN DEFAULT true
  is_default  BOOLEAN DEFAULT false   -- Podrazumevana svrha
  created_at  TIMESTAMPTZ
*/


-- =====================================================
-- SECTION 7: EMENI / ORDERS TABLES
-- =====================================================

-- TABLE: emeni_orders
-- KORISTI SE U: analyticsService, LiveOrdersPage
-- =====================================================
/*
KOLONE:
  order_id        VARCHAR PRIMARY KEY     -- eMeni order ID
  company_id      INTEGER/VARCHAR         -- Lokacija (310, 1513, etc.)
  provider        VARCHAR                 -- 'wolt', 'ebar', 'gloriafood', 'emeniwaiter'
  status          INTEGER                 -- Status kod
  total           NUMERIC                 -- Ukupan iznos (RSD)
  order_total     NUMERIC                 -- Alternativno polje za iznos
  amount          NUMERIC                 -- Još jedno polje za iznos
  items           JSONB                   -- Stavke porudžbine
  raw_payload     JSONB                   -- Originalni webhook payload
  created_at      TIMESTAMPTZ
  
STATUS CODES:
  8, 9, 11 = Canceled/Rejected (filtrira se out)
  Ostali = Aktivne porudžbine

REALTIME: LiveOrdersPage koristi Supabase Realtime subscription
*/


-- TABLE: emeni_order_lifecycle
-- KORISTI SE U: analyticsService.fetchOrderLifecycle, LiveOrdersPage
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY
  order_id        VARCHAR                 -- FK → emeni_orders(order_id)
  status          INTEGER                 -- Status kod
  timestamp       TIMESTAMPTZ

STATUS CODES:
  3 = Accepted
  5 = Ready
  7 = Delivered
*/


-- TABLE: wolt_orders (ISTORIJSKI PODACI - 2025)
-- KORISTI SE U: analyticsService (fetchProjectionData, fetchComparisonOrders)
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY
  created_at      TIMESTAMPTZ
  amount          INTEGER                 -- Iznos u CENTIMA!
  order_status    VARCHAR                 -- 'delivered', 'rejected', 'cancelled', etc.
  venue_name      VARCHAR                 -- Ime lokacije

⚠️ NAPOMENA: amount je u CENTIMA, mora se deliti sa 100 za RSD!
  Koristi se samo za 2025 podatke, za 2026+ koristi emeni_orders
*/


-- TABLE: table_discounts
-- KORISTI SE U: ordersService.fetchTableDiscounts
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY
  table_id        VARCHAR                 -- ID stola
  filter_name     VARCHAR                 -- Filter ime
  discount_percent NUMERIC                -- Procenat popusta
  is_active       BOOLEAN DEFAULT true
*/


-- TABLE: product_margins
-- KORISTI SE U: analyticsService.fetchMargins
-- =====================================================
/*
KOLONE:
  id              UUID PRIMARY KEY
  product_name    VARCHAR
  margin_pct      NUMERIC                 -- Procenat marže
  cost_per_unit   NUMERIC                 -- Cena po jedinici
*/


-- =====================================================
-- SECTION 8: JOIN PATTERNS (KRITIČNO!)
-- =====================================================

/*
⚠️ PROBLEM: PGRST200/PGRST201 GREŠKE

Kada tabela ima VIŠE foreign key-eva ka istoj tabeli (npr. pazar_finance_records 
ima received_by, verified_by, taken_by, banked_by - sve ka pazar_users),
Supabase ne zna automatski koji FK da koristi.

GREŠKA:
"Could not find a relationship between 'pazar_finance_records' and 'pazar_users'"

REŠENJE: Eksplicitno navedi FK ime ili koristi plain SQL JOIN.
*/

-- ❌ POGREŠNO - Supabase ne zna koji FK
-- .select('*, user:pazar_users(first_name, last_name)')

-- ✅ ISPRAVNO - Navedi eksplicitni FK (ako postoji)
-- .select('*, received_by_user:pazar_users!fk_received_by(first_name, last_name)')

-- ✅ ISPRAVNO - Koristi FK ime iz baze
-- .select('*, user:pazar_users!user_id(first_name, last_name)')
-- .select('*, driver:pazar_users!driver_id(first_name, last_name)')

-- ✅ ISPRAVNO - Koristi plain SQL za kompleksne JOINove
SELECT 
  fr.*,
  ru.first_name || ' ' || ru.last_name as received_by_name,
  vu.first_name || ' ' || vu.last_name as verified_by_name,
  bu.first_name || ' ' || bu.last_name as banked_by_name,
  loc.name as location_name
FROM pazar_finance_records fr
LEFT JOIN pazar_users ru ON fr.received_by = ru.id
LEFT JOIN pazar_users vu ON fr.verified_by = vu.id
LEFT JOIN pazar_users bu ON fr.banked_by = bu.id
LEFT JOIN pazar_locations loc ON fr.location_id = loc.id
WHERE fr.date = CURRENT_DATE;

-- FALLBACK PATTERN (koristi se u pazarFinanceService):
-- Prvo pokušaj sa JOIN-om, ako ne radi, koristi SELECT * bez JOIN-a


-- =====================================================
-- SECTION 9: DELETE ORDER (FOREIGN KEY DEPENDENCIES)
-- =====================================================

/*
⚠️ KRITIČNO: Kada brišeš podatke, MORAŠ poštovati ovaj redosled!

REDOSLED BRISANJA ZA DATUM:

1. pazar_bank_deposits
2. pazar_finance_records
3. pazar_cash_pickups
4. pazar_cash_collections         -- referencira pazar_daily_specifications
5. pazar_specification_denominations -- referencira pazar_daily_specifications
6. pazar_daily_specifications     -- referencira pazar_shifts
7. pazar_shift_handovers          -- referencira pazar_shifts (from_shift_id, to_shift_id)
8. pazar_shifts                   -- ZADNJE!
9. pazar_safe_transactions        -- po created_at timestamp

GREŠKA AKO NE POŠTUJEŠ:
"update or delete on table X violates foreign key constraint Y_fkey on table Z"
*/

-- KOMPLETAN RESET ZA DATUM (copy-paste ready):
DO $$
DECLARE
  target_date DATE := '2026-01-19';  -- PROMENI DATUM OVDE
  deleted_count INT;
BEGIN
  -- 1. Bank deposits
  DELETE FROM pazar_bank_deposits WHERE date = target_date;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_bank_deposits: % rows', deleted_count;
  
  -- 2. Finance records
  DELETE FROM pazar_finance_records WHERE date = target_date;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_finance_records: % rows', deleted_count;
  
  -- 3. Cash pickups
  DELETE FROM pazar_cash_pickups WHERE date = target_date;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_cash_pickups: % rows', deleted_count;
  
  -- 4. Cash collections (referencira specifications)
  DELETE FROM pazar_cash_collections 
  WHERE specification_id IN (
    SELECT id FROM pazar_daily_specifications 
    WHERE shift_id IN (SELECT id FROM pazar_shifts WHERE date = target_date)
  );
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_cash_collections: % rows', deleted_count;
  
  -- 5. Specification denominations (referencira specifications)
  DELETE FROM pazar_specification_denominations 
  WHERE specification_id IN (
    SELECT id FROM pazar_daily_specifications 
    WHERE shift_id IN (SELECT id FROM pazar_shifts WHERE date = target_date)
  );
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_specification_denominations: % rows', deleted_count;
  
  -- 6. Daily specifications (referencira shifts)
  DELETE FROM pazar_daily_specifications 
  WHERE shift_id IN (SELECT id FROM pazar_shifts WHERE date = target_date);
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_daily_specifications: % rows', deleted_count;
  
  -- 7. Shift handovers (referencira shifts)
  DELETE FROM pazar_shift_handovers 
  WHERE from_shift_id IN (SELECT id FROM pazar_shifts WHERE date = target_date)
     OR to_shift_id IN (SELECT id FROM pazar_shifts WHERE date = target_date);
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_shift_handovers: % rows', deleted_count;
  
  -- 8. Shifts (ZADNJE)
  DELETE FROM pazar_shifts WHERE date = target_date;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_shifts: % rows', deleted_count;
  
  -- 9. Safe transactions
  DELETE FROM pazar_safe_transactions 
  WHERE created_at >= target_date::timestamp 
    AND created_at < (target_date + 1)::timestamp;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RAISE NOTICE 'pazar_safe_transactions: % rows', deleted_count;
  
  RAISE NOTICE '✅ Reset completed for %', target_date;
END $$;


-- =====================================================
-- SECTION 10: COMMON ERRORS & SOLUTIONS
-- =====================================================

/*
ERROR 1: "invalid input syntax for type uuid: '310'"
---------------------------------------------------------
UZROK: Šalješ eMeni company_id (310, 1513) umesto UUID-a
REŠENJE: Frontend mora slati UUID iz pazar_locations tabele
PROVERA: SELECT id, name FROM pazar_locations;


ERROR 2: "duplicate key value violates unique constraint pazar_finance_records_pickup_id_key"
---------------------------------------------------------
UZROK: Pokušavaš kreirati drugi finance_record za isti pickup
REŠENJE: Prvo proveri da li već postoji record za taj pickup_id
PROVERA: SELECT * FROM pazar_finance_records WHERE pickup_id = 'xxx';


ERROR 3: "Could not find a relationship between 'pazar_finance_records' and 'pazar_users'"
---------------------------------------------------------
UZROK: Supabase ne zna koji FK da koristi (ima ih više ka istoj tabeli)
REŠENJE: Eksplicitno navedi FK ime ili koristi plain SQL JOIN
PRIMER: Vidi SECTION 8 iznad


ERROR 4: "column 'status' does not exist" (na pazar_cash_pickups)
---------------------------------------------------------
UZROK: pazar_cash_pickups NEMA kolonu status
REŠENJE: Status se određuje po picked_at, delivered_at, verified_at kolonama


ERROR 5: "column 'handed_over_shift_id' does not exist"
---------------------------------------------------------
UZROK: Kolona se zove "from_shift_id", ne "handed_over_shift_id"
REŠENJE: Koristi from_shift_id i to_shift_id


ERROR 6: "violates foreign key constraint on table 'pazar_shift_handovers'"
---------------------------------------------------------
UZROK: Pokušavaš obrisati shift koji je referenciran u handovers
REŠENJE: Prvo obriši handovers, pa onda shifts (vidi SECTION 9)


ERROR 7: "cannot alter type of a column used by a view"
---------------------------------------------------------
UZROK: Postoji view koji koristi tu kolonu
VIEW: pazar_specifications_summary
REŠENJE: DROP view, ALTER kolonu, CREATE view ponovo


ERROR 8: "column 'count' does not exist" (na pazar_specification_denominations)
---------------------------------------------------------
UZROK: Kolona se zove "quantity", ne "count"
REŠENJE: Koristi quantity za broj novčanica


ERROR 9: "column 'account_no' does not exist" (na bank_accounts)
---------------------------------------------------------
UZROK: Kolona se zove "account_number", ne "account_no"
REŠENJE: Koristi account_number
*/


-- =====================================================
-- SECTION 11: VIEWS
-- =====================================================

-- VIEW: pazar_specifications_summary
-- =====================================================
/*
Ovaj view se koristi za summary prikaz specifikacija.
ZAVISI OD: pazar_daily_specifications, pazar_locations, pazar_users

Ako treba menjati location_id tip, MORAŠ:
1. DROP VIEW pazar_specifications_summary;
2. ALTER TABLE ...
3. CREATE VIEW pazar_specifications_summary AS ...
*/


-- =====================================================
-- SECTION 12: TEST CREDENTIALS
-- =====================================================

/*
| Role      | Name              | PIN   | Email                    |
|-----------|-------------------|-------|--------------------------|
| admin     | Admin Test        | 99999 | markosavic82@gmail.com   |
| finansije | Marko Mišić       | -     | markomisic@collina.rs    |
| konobar   | Jelena Popovic    | 05002 | -                        |
| vozac     | Petar Dostavljač  | 22222 | -                        |
| menadzer  | Stefan Djordjevic | 03001 | -                        |
*/


-- #####################################################
-- PART B: APPLICATION QUERIES BY MODULE
-- #####################################################


-- =====================================================
-- SECTION 13: AUTH MODULE QUERIES
-- =====================================================

/*
FILE: src/core/auth/AuthContext.jsx

1. fetchEmployeeData - učitava employee i permisije
   - SELECT * FROM pazar_users WHERE email = ? OR auth_user_id = ?
   - SELECT module, can_view, can_edit, can_delete FROM module_permissions WHERE role = ?

2. Supabase Auth metode:
   - supabase.auth.getSession() - dohvata sesiju
   - supabase.auth.onAuthStateChange() - listener za auth promene
   - supabase.auth.signInWithPassword() - login
   - supabase.auth.signOut() - logout

FILE: src/core/auth/PermissionGuard.jsx
   - SELECT * FROM role_module_permissions WHERE role_id IN (?) AND module_id = ?
*/


-- =====================================================
-- SECTION 14: PAZAR MODULE QUERIES
-- =====================================================

/*
FILE: src/modules/pazar/services/pazarService.js

getCurrentShift:
  SELECT * FROM pazar_shifts 
  WHERE location_id = ? AND date = ? AND user_id = ? AND status = 'active'

getTodayShifts:
  SELECT * FROM pazar_shifts WHERE location_id = ? AND date = ?
  ORDER BY shift_order ASC
  
  SELECT id, first_name, last_name FROM pazar_users WHERE id IN (?)

startFirstShift:
  SELECT shift_order FROM pazar_shifts 
  WHERE location_id = ? AND date = ? 
  ORDER BY shift_order DESC LIMIT 1
  
  INSERT INTO pazar_shifts (location_id, user_id, date, shift_order, status, ...)
  INSERT INTO pazar_shift_handovers (location_id, date, to_shift_id, ...)

endShift:
  UPDATE pazar_shifts SET status = ?, ended_at = ?, ending_amount = ? WHERE id = ?

createSpecification:
  INSERT INTO pazar_daily_specifications (...)
  INSERT INTO pazar_specification_denominations (...) -- bulk

takeoverShift:
  SELECT * FROM pazar_shifts WHERE id = ?
  UPDATE pazar_shifts SET status = ?, ended_at = ? WHERE id = ?
  SELECT shift_order FROM pazar_shifts ... ORDER BY shift_order DESC LIMIT 1
  INSERT INTO pazar_shifts (...)
  INSERT INTO pazar_shift_handovers (...)

endShiftEndOfDay:
  UPDATE pazar_shifts SET status = ?, is_last_shift = ? WHERE id = ?
  INSERT INTO pazar_cash_collections (...)
  SELECT denomination, quantity FROM pazar_specification_denominations WHERE specification_id = ?
  INSERT INTO pazar_bank_deposits (...)


FILE: src/modules/pazar/stores/pazarAuthStore.js

searchUsers:
  RPC: search_pazar_users(search_term)
*/


-- =====================================================
-- SECTION 15: STAFF MODULE QUERIES
-- =====================================================

/*
FILE: src/modules/staff/services/pickupService.js

getLocationsWithClosedShifts:
  SELECT * FROM pazar_locations WHERE is_active = true ORDER BY name
  
  SELECT *, user:pazar_users!user_id(id, first_name, last_name)
  FROM pazar_shifts
  WHERE is_last_shift = true AND status = 'closed' AND date = ?
  
  SELECT *, driver:pazar_users!driver_id(id, first_name, last_name)
  FROM pazar_cash_pickups WHERE date = ?

createPickup:
  INSERT INTO pazar_cash_pickups (date, location_id, driver_id, picked_at, pickup_photos)

markAsDelivered:
  UPDATE pazar_cash_pickups SET delivered_at = ? WHERE id = ?

deliverAll:
  UPDATE pazar_cash_pickups SET delivered_at = ? WHERE id IN (?)


FILE: src/modules/staff/components/layout/StaffHeader.jsx

loadLocations:
  SELECT id, name, code FROM pazar_locations WHERE is_active = true ORDER BY name
*/


-- =====================================================
-- SECTION 16: ADMIN PAZAR QUERIES
-- =====================================================

/*
FILE: src/pages/admin/pazar/services/pazarFinanceService.js

loadPazarData:
  SELECT *, user:pazar_users!user_id(...), location:pazar_locations(...)
  FROM pazar_shifts WHERE date >= ? AND date <= ?
  
  SELECT * FROM pazar_daily_specifications WHERE shift_id IN (?)
  
  SELECT *, driver:pazar_users!driver_id(...), location:pazar_locations(...)
  FROM pazar_cash_pickups WHERE date >= ? AND date <= ?
  
  SELECT *, received_by_user:pazar_users!fk_received_by(...), 
            verified_by_user:pazar_users!fk_verified_by(...),
            banked_by_user:pazar_users!fk_banked_by(...)
  FROM pazar_finance_records WHERE date >= ? AND date <= ?
  -- FALLBACK: SELECT * bez JOIN-ova
  
  SELECT *, deposited_by_user:pazar_users!deposited_by(...)
  FROM pazar_bank_deposits WHERE created_at >= ?
  
  SELECT * FROM pazar_specification_denominations WHERE specification_id IN (?)


FILE: src/pages/admin/pazar/components/ReceiveModal.jsx
  INSERT INTO pazar_finance_records (pickup_id, location_id, date, received_by, received_at)


FILE: src/pages/admin/pazar/components/CountModal.jsx
  UPDATE pazar_finance_records SET verified_at = ?, verified_by = ?, counted_amount = ?, ... WHERE id = ?
  SELECT id, status FROM pazar_bank_deposits WHERE location_id = ? AND date = ?
  INSERT INTO pazar_bank_deposits (...) -- ako ne postoji
  UPDATE pazar_bank_deposits SET amount = ?, ... WHERE id = ? -- ako postoji


FILE: src/pages/admin/pazar/components/TakeFromSafeModal.jsx
  SELECT * FROM companies WHERE is_active = true ORDER BY is_default DESC
  SELECT * FROM bank_accounts WHERE is_active = true ORDER BY is_primary DESC
  SELECT * FROM payment_purposes WHERE is_active = true ORDER BY is_default DESC
  UPDATE pazar_finance_records SET taken_from_safe_at = ?, taken_by = ?, ... WHERE id = ?


FILE: src/pages/admin/pazar/components/BankDepositModalNew.jsx
  SELECT *, location:pazar_locations!location_id(...)
  FROM pazar_finance_records
  WHERE verified_at IS NOT NULL AND banked_at IS NULL
  ORDER BY date DESC
  
  UPDATE pazar_finance_records SET banked_at = ?, banked_by = ? WHERE id = ?
*/


-- =====================================================
-- SECTION 17: ANALYTICS MODULE QUERIES
-- =====================================================

/*
FILE: src/modules/analytics/services/analyticsService.js

fetchLocations:
  SELECT company_id, location_name FROM emeni_locations

fetchOrders:
  SELECT * FROM emeni_orders LIMIT 1 -- debug
  SELECT * FROM emeni_orders 
  WHERE created_at >= ? AND created_at <= ?
  ORDER BY created_at ASC
  -- PAGINACIJA: limit 1000, max 50000

fetchOrderLifecycle:
  REST API: /rest/v1/emeni_order_lifecycle?order_id=in.(...)&status=in.(3,5,7)
  FALLBACK: SELECT order_id, status, timestamp FROM emeni_order_lifecycle WHERE order_id IN (?) AND status IN (3,5,7)

fetchMargins:
  SELECT product_name, margin_pct, cost_per_unit FROM product_margins

fetchProjectionData:
  SELECT created_at, amount, order_status FROM wolt_orders
  WHERE created_at >= ? AND created_at < ?
  LIMIT 2000 -- paralelno za svaki matching datum

fetchTrendOrders:
  SELECT * FROM emeni_orders WHERE created_at >= ? AND created_at <= ?
  ORDER BY created_at ASC
  -- PAGINACIJA: limit 1000, max 10000

fetchComparisonOrders:
  -- Ako year < 2026: SELECT * FROM wolt_orders ...
  -- Ako year >= 2026: SELECT * FROM emeni_orders ...
  -- PAGINACIJA: limit 1000, max 10000

fetchLocationPerformance:
  SELECT * FROM emeni_orders WHERE created_at >= ? AND created_at <= ?
  ORDER BY created_at ASC
  -- PAGINACIJA: limit 1000, max 10000
*/


-- =====================================================
-- SECTION 18: ORDERS MODULE QUERIES
-- =====================================================

/*
FILE: src/modules/orders/services/ordersService.js

fetchTableDiscounts:
  SELECT table_id, filter_name, discount_percent FROM table_discounts WHERE is_active = true
  FALLBACK: Hardcoded TABLE_DISCOUNTS objekat


FILE: src/modules/orders/pages/LiveOrdersPage.jsx

fetchOrders:
  SELECT * FROM emeni_orders 
  WHERE created_at >= ? AND created_at < ?
  ORDER BY created_at DESC
  
  SELECT order_id, status, timestamp FROM emeni_order_lifecycle WHERE order_id IN (?)

REALTIME SUBSCRIPTION:
  supabase.channel('orders-changes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'emeni_orders' }, callback)
*/


-- =====================================================
-- SECTION 19: USEFUL DIAGNOSTIC QUERIES
-- =====================================================

-- Proveri sve tabele za datum
SELECT 'pazar_shifts' as tbl, COUNT(*) FROM pazar_shifts WHERE date = '2026-01-19'
UNION ALL SELECT 'pazar_cash_pickups', COUNT(*) FROM pazar_cash_pickups WHERE date = '2026-01-19'
UNION ALL SELECT 'pazar_finance_records', COUNT(*) FROM pazar_finance_records WHERE date = '2026-01-19'
UNION ALL SELECT 'pazar_shift_handovers', COUNT(*) FROM pazar_shift_handovers WHERE date = '2026-01-19';


-- Dohvati finance records sa svim statusima za datum
SELECT 
  fr.id,
  loc.name as location,
  fr.counted_amount,
  CASE 
    WHEN fr.banked_at IS NOT NULL THEN 'DEPONOVANO'
    WHEN fr.taken_from_safe_at IS NOT NULL THEN 'NA PUTU'
    WHEN fr.verified_at IS NOT NULL THEN 'U SEFU'
    WHEN fr.counted_amount IS NOT NULL THEN 'PREBROJANO'
    WHEN fr.received_at IS NOT NULL THEN 'PRIMLJENO'
    ELSE 'NEPOZNATO'
  END as status
FROM pazar_finance_records fr
JOIN pazar_locations loc ON fr.location_id = loc.id
WHERE fr.date = CURRENT_DATE;


-- Proveri strukturu bilo koje tabele
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'pazar_finance_records'  -- PROMENI IME TABELE
ORDER BY ordinal_position;


-- Proveri foreign key constraints
SELECT
  tc.constraint_name,
  kcu.column_name,
  ccu.table_name AS foreign_table,
  ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'pazar_finance_records'  -- PROMENI IME TABELE
  AND tc.constraint_type = 'FOREIGN KEY';


-- Proveri sve tabele u bazi
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;


-- Proveri sve views u bazi
SELECT table_name as view_name
FROM information_schema.views
WHERE table_schema = 'public';


-- =====================================================
-- SECTION 20: MAGACIN MODULE (EXTERNAL API)
-- =====================================================

/*
⚠️ NAPOMENA: Magacin modul NE KORISTI Supabase!
Koristi eksterni API: https://magacin.collina.co.rs/api/trebovanje

BASE URL: https://magacin.collina.co.rs/api/trebovanje

ENDPOINTS:

1. GET /radnje
   - Lista radnji (sifra, naziv)

2. GET /artikli
   - Svi artikli

3. GET /stanje
   - Stanje po skladištima
   - Format: { "Centralni magacin": { "A2023": { stock: 79, reserved: 0 } } }

4. GET /lista
   - Lista trebovanja (acKey, id, status, radnja, datum, brojStavki)

5. POST /submit
   - Kreiraj trebovanje
   - Body: { radnja: "sifra", stavke: [{ sifra, naziv, jm, kolicina }] }
   - Return: { success: true, trebovanjeKey: "TREB-2026-001" }

6. GET /artikli-radnja/{radnjaSifra}
   - Artikli za radnju sa stanjem (anStockCM, anStockMP, anMinStock)

7. GET /artikli-ostalo/{radnjaSifra}?search={term}
   - Pretraga artikala koje radnja NE koristi

8. GET /detalji/{key}
   - Detalji trebovanja sa stavkama
   - FALLBACK: /{key}

9. POST /posalji/{key}
   - Pošalji robu
   - Body: { userId: 5, izmene: [{ sifra, kolicina, razlog }] }

10. POST /primi/{key}
    - Primi robu
    - Body: { userId: 5 }

11. GET /prenosi
    - Lista prenosa (acKey, id, datum, primalac, vrednost)

12. GET /prenos/{key}
    - Detalji prenosa sa stavkama

13. GET /nedostaje
    - Nedostajući artikli (sifra, naziv, radnja, trazeno, poslato, nedostaje)

14. POST /nedostaje/resi/{id}
    - Označi kao rešeno

STATUS KODOVI TREBOVANJA:
  'N' = NOVO
  'T' = NA PUTU
  'Z' = ZAVRŠENO

RAZLOZI IZMENE:
  'NEMA_NA_STANJU' - Nema na stanju u CM
  'OSTECENO' - Oštećena roba
  'GRESKA' - Greška u trebovanju
*/


-- =====================================================
-- END OF REFERENCE DOCUMENT
-- =====================================================
/*
CHANGELOG:
- 2026-01-20 v2.0: Dodato:
  - Svi moduli (Auth, Pazar, Staff, Analytics, Orders)
  - Svi Supabase upiti po fajlovima
  - emeni_* tabele za Analytics/Orders
  - Realtime subscription dokumentacija
  - Dva sistema permisija (module_permissions vs role_module_permissions)
  - Više error rešenja
  - Diagnostic queries
  
- 2026-01-20 v1.0: Initial version
  - Pazar tabele
  - Common errors
  - JOIN patterns
  - DELETE order

TODO:
- [x] Dodati MAGACIN modul (eksterni API) ✅
- [ ] Proveriti strukturu role_module_permissions u bazi
- [ ] Dokumentovati Edge Functions
- [ ] Proveriti stvarnu strukturu tabela u Supabase

MAINTENANCE:
Kada dodaješ novu kolonu ili tabelu:
1. Ažuriraj ovaj fajl
2. Push na gist
3. Claude će automatski videti promene

Za pitanja: markosavic82@gmail.com
*/
