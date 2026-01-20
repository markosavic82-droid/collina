/*
 * ============================================================================
 * COLLINA PLATFORM - MASTER INDEX TEHNIČKE DOKUMENTACIJE
 * ============================================================================
 * 
 * Naziv projekta: Collina Platform
 * Verzija dokumentacije: 1.0
 * Datum kreiranja: 2026-01-17
 * 
 * VALIDATION CODE: COLLINA-2026-PAZAR
 * 
 * Ovaj fajl je centralni index za kompletnu tehničku dokumentaciju Collina
 * platforme. Koristi ga kao početnu tačku za pronalaženje informacija o
 * bilo kom aspektu sistema.
 */

/* ============================================================================
 * 1. PROJECT OVERVIEW
 * ============================================================================
 */

/*
 * 1.1. ŠTA JE COLLINA
 * ---------------------
 * 
 * Collina Platform je kompletan sistem za upravljanje restoranom za Collina,
 * lanac restorana sa više lokacija u Beogradu, Srbija. Platforma integriše
 * analytics, upravljanje porudžbinama, cash management (Pazar), staff app,
 * i warehouse management (Magacin) u jedinstven sistem.
 * 
 * Glavni ciljevi:
 *   - Centralizovana operativna kontrolna tabla
 *   - Multi-location analytics
 *   - Staff management i scheduling
 *   - Cash flow management (Pazar modul)
 *   - Warehouse management (Magacin modul)
 *   - Real-time order tracking
 */

/*
 * 1.2. TECH STACK
 * ----------------
 * 
 * Frontend:
 *   - React 19.2.0 (UI framework)
 *   - React Router 6.30.3 (routing)
 *   - Vite 7.2.4 (build tool)
 *   - Tailwind CSS 3.4.14 (styling)
 *   - Zustand 5.0.10 (state management)
 *   - Recharts 3.6.0 (charts)
 *   - Lucide React 0.294.0 (icons)
 * 
 * Backend:
 *   - Supabase (PostgreSQL database, Auth, Realtime)
 *   - Supabase Edge Functions (PIN authentication)
 * 
 * Deployment:
 *   - Vercel (hosting, CI/CD)
 *   - Environment variables via Vercel Dashboard
 * 
 * External APIs:
 *   - Magacin API (https://magacin.collina.co.rs/api/trebovanje)
 *   - eMeni webhook (orders ingestion)
 */

/*
 * 1.3. GLAVNI MODULI
 * --------------------
 * 
 * 1. ANALYTICS
 *    - Revenue tracking, KPIs, trends
 *    - Location performance comparison
 *    - Channel mix analysis
 *    - Hourly/daily/weekly projections
 * 
 * 2. ORDERS (Live Porudžbine)
 *    - Real-time order tracking
 *    - Status management (new, production, ready, paid, canceled)
 *    - Filter by location, channel, table, discount
 *    - Order lifecycle tracking
 * 
 * 3. PAZAR (Cash Management)
 *    - Shift management (start, handover, end)
 *    - Cash reconciliation
 *    - Cash pickup flow (Vozač → Admin → Sef → Banka)
 *    - Bank deposit management
 *    - Denominations tracking
 * 
 * 4. STAFF APP
 *    - Mobile-first interface
 *    - PIN-based authentication
 *    - Shift management
 *    - Cash handover
 *    - Pickup management (vozač role)
 * 
 * 5. MAGACIN (Warehouse Management)
 *    - Trebovanje (requisitions) management
 *    - Stock tracking (CM, Radnja)
 *    - Transfers (prenosi)
 *    - Missing articles (nedostaje)
 *    - External API integration
 * 
 * 6. KUHINJA KDS (Kitchen Display System)
 *    - Status: Not yet implemented (placeholder in navigation)
 *    - Planned: Real-time order display for kitchen
 * 
 * 7. MENADŽMENT MENIJA (Menu Management)
 *    - Status: Not yet implemented (placeholder in navigation)
 *    - Planned: Menu items, categories, promotions management
 */

/* ============================================================================
 * 2. QUICK START
 * ============================================================================
 */

/*
 * 2.1. LOKALNO POKRETANJE PROJEKTA
 * ----------------------------------
 * 
 * Prerequisites:
 *   - Node.js 18+ installed
 *   - npm ili yarn
 *   - Git
 * 
 * Setup Steps:
 *   1. Clone repository:
 *      git clone <repository-url>
 *      cd Collina_Project
 * 
 *   2. Install dependencies:
 *      npm install
 * 
 *   3. Create .env.local file:
 *      VITE_SUPABASE_URL=https://your-project.supabase.co
 *      VITE_SUPABASE_ANON_KEY=your-anon-key
 * 
 *   4. Start development server:
 *      npm run dev
 * 
 *   5. Open browser:
 *      http://localhost:5173
 * 
 * NAPOMENA: Projekat koristi Vite - development server se pokreće na portu 5173.
 */

/*
 * 2.2. ENVIRONMENT VARIJABLE
 * ----------------------------
 * 
 * Required Variables (.env.local):
 *   - VITE_SUPABASE_URL: Supabase project URL
 *     Example: https://bbnbbbpofelbkyuffslj.supabase.co
 * 
 *   - VITE_SUPABASE_ANON_KEY: Supabase anonymous key (public)
 *     Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 * 
 * Optional Variables:
 *   - N/A (sve ostalo je hardcoded ili se koristi Supabase Auth)
 * 
 * Production (Vercel):
 *   - Environment variables se postavljaju u Vercel Dashboard
 *   - Settings → Environment Variables
 *   - Scope: Production, Preview, Development
 * 
 * NAPOMENA: Environment variables se čuvaju van koda - .env fajlovi su gitignored.
 */

/*
 * 2.3. TEST KREDENCIJALI
 * ------------------------
 * 
 * NAPOMENA: Test kredencijali se ne čuvaju u kodu iz bezbednosnih razloga.
 *           Kreiraju se ručno u Supabase Dashboard-u.
 * 
 * Email+Password Login (Admin Shell):
 *   - Route: /login
 *   - Email: [kreirati u Supabase Auth]
 *   - Password: [kreirati u Supabase Auth]
 *   - Role: admin, menadzer, finansije (u pazar_users.role)
 * 
 * PIN Login (Staff App):
 *   - Route: /pazar/login ili /staff/login
 *   - Name: [pretraga po imenu iz pazar_users]
 *   - PIN: [5-digit PIN iz pazar_users.pin_code]
 *   - Role: konobar, vozac (u pazar_users.role)
 * 
 * Test Accounts Setup:
 *   1. Create user u Supabase Auth (email+password)
 *   2. Create record u pazar_users table:
 *      - email: matches Auth email
 *      - role: 'admin', 'menadzer', 'finansije', 'konobar', 'vozac'
 *      - pin_code: 5-digit PIN (za PIN login)
 *      - default_location_id: UUID lokacije
 *   3. Grant permissions u module_permissions table:
 *      INSERT INTO module_permissions (role, module, can_view, can_edit)
 *      VALUES ('admin', 'analytics', true, true),
 *             ('admin', 'orders', true, true),
 *             ('admin', 'pazar', true, true),
 *             ('admin', 'magacin', true, true);
 * 
 * NAPOMENA: Test accounts se kreiraju ručno - nema automatskog seed-a.
 */

/* ============================================================================
 * 3. FILE INDEX - Kompletna lista dokumentacionih fajlova
 * ============================================================================
 */

/*
 * 3.1. DATABASE & SCHEMA
 * -----------------------
 * 
 * PROJECT_STRUCTURE.md
 *   - Kompletna struktura projekta (folders, files)
 *   - Module organization
 *   - File naming conventions
 *   - Location: Root directory
 * 
 * PAZAR_TABLES_INVENTORY.md
 *   - Inventory svih Pazar tabela
 *   - Kolone, tipovi, constraints
 *   - Foreign key relationships
 *   - Location: Root directory
 * 
 * PAZAR_FINANCE_RECORDS_FOREIGN_KEYS.md
 *   - Foreign key relationships za pazar_finance_records
 *   - JOIN patterns
 *   - Fallback mechanisms
 *   - Location: Root directory
 */

/*
 * 3.2. SUPABASE QUERIES
 * -----------------------
 * 
 * PAZAR_SUPABASE_QUERIES.md
 *   - Svi Supabase queries u Pazar modulu
 *   - Function names, tables, operations
 *   - JOINs, RPC functions
 *   - Location: Root directory
 * 
 * STAFF_SUPABASE_QUERIES.md
 *   - Svi Supabase queries u Staff modulu
 *   - Pickup service queries
 *   - Auth queries
 *   - Location: Root directory
 * 
 * AUTH_SUPABASE_QUERIES.md
 *   - Authentication system queries
 *   - Permission loading
 *   - Employee loading
 *   - Supabase Auth methods
 *   - Location: Root directory
 * 
 * ANALYTICS_ORDERS_SUPABASE_QUERIES.md
 *   - Analytics module queries
 *   - Orders module queries
 *   - Realtime subscriptions
 *   - Date range filtering
 *   - Location: Root directory
 * 
 * MAGACIN_API_QUERIES.md
 *   - External API calls (Magacin API)
 *   - Endpoints, methods, parameters
 *   - NO Supabase queries (external API only)
 *   - Location: Root directory
 * 
 * KDS_MENU_SUPABASE_QUERIES.md
 *   - KDS i Menu Management queries
 *   - Status: Not implemented (proposed queries)
 *   - Location: Root directory
 */

/*
 * 3.3. BUSINESS LOGIC
 * ---------------------
 * 
 * ANALYTICS_BUSINESS_LOGIC.md
 *   - Kompletna biznis logika Analytics modula
 *   - Data flow, calculations, KPIs
 *   - Status codes, normalization
 *   - Filtering logic, component interaction
 *   - Format: SQL comments
 *   - Location: Root directory
 * 
 * ORDERS_BUSINESS_LOGIC.md
 *   - Kompletna biznis logika Orders modula
 *   - Realtime subscriptions
 *   - Status flow, lifecycle events
 *   - Filters, table discounts
 *   - Format: SQL comments
 *   - Location: Root directory
 * 
 * PAZAR_BUSINESS_LOGIC.md
 *   - Kompletna biznis logika Pazar modula
 *   - Shift flow (state machine)
 *   - Cash pickup flow
 *   - Formulas, denominations
 *   - Edge cases
 *   - Format: SQL comments
 *   - Location: Root directory
 * 
 * AUTH_BUSINESS_LOGIC.md
 *   - Kompletna biznis logika Authentication sistema
 *   - Dva login puta (Email+Password vs Name+PIN)
 *   - Auth flow, session management
 *   - Permission system, route protection
 *   - Role-based access, logout
 *   - Format: SQL comments
 *   - Location: Root directory
 * 
 * COLLINA_BUSINESS_RULES.md
 *   - Poslovna pravila specifična za Collina
 *   - Location mapping, shift rules
 *   - Cash rules, pickup rules
 *   - Bank deposit rules, role hierarchy
 *   - Notification rules, audit trail
 *   - Format: SQL comments
 *   - Location: Root directory
 */

/*
 * 3.4. APPLICATION STRUCTURE
 * ----------------------------
 * 
 * APP_ROUTING_STRUCTURE.md
 *   - Kompletna struktura aplikacije i routing
 *   - Route hierarchy, layouts
 *   - Protected routes, nested routes
 *   - Redirects, module structure
 *   - Format: SQL comments
 *   - Location: Root directory
 */

/*
 * 3.5. UI/UX & DATA FORMATS
 * ---------------------------
 * 
 * UI_UX_PATTERNS.md
 *   - UI/UX patterni i reusable komponente
 *   - Design system (colors, fonts, spacing)
 *   - Loading states, empty states
 *   - Toast/notifications, responsive
 *   - Serbian locale
 *   - Format: SQL comments
 *   - Location: Root directory
 * 
 * DATA_FORMATS_CONVENTIONS.md
 *   - Data formati i konvencije
 *   - Date formats, currency (RSD)
 *   - Time zones, naming conventions
 *   - ID formats, apoeni, status enums
 *   - Nullable fields
 *   - Format: SQL comments
 *   - Location: Root directory
 */

/*
 * 3.6. STATE MANAGEMENT & PERFORMANCE
 * -------------------------------------
 * 
 * STATE_MANAGEMENT_PATTERNS.md
 *   - State management patterni
 *   - Zustand stores, Context providers
 *   - Local vs global state
 *   - Persistence, state reset
 *   - Derived state
 *   - Format: SQL comments
 *   - Location: Root directory
 * 
 * PERFORMANCE_OPTIMIZATIONS.md
 *   - Performance optimizacije
 *   - Pagination (1000, 10000, 50000 limits)
 *   - Lazy loading, caching
 *   - Debounce/throttle
 *   - Query optimization, bundle size
 *   - Realtime limits
 *   - Format: SQL comments
 *   - Location: Root directory
 */

/*
 * 3.7. INTEGRATIONS & SECURITY
 * ------------------------------
 * 
 * EXTERNAL_INTEGRATIONS.md
 *   - Eksterne integracije
 *   - eMeni webhook, Magacin API
 *   - Wolt/Glovo, Supabase Edge Functions
 *   - Vercel, error monitoring
 *   - Format: SQL comments
 *   - Location: Root directory
 * 
 * SECURITY_MEASURES.md
 *   - Security mere
 *   - RLS policies, API keys
 *   - Input sanitization, XSS protection
 *   - CORS, sensitive data
 *   - PIN security
 *   - Format: SQL comments
 *   - Location: Root directory
 */

/*
 * 3.8. ERROR HANDLING & TESTING
 * -------------------------------
 * 
 * ERROR_HANDLING_PATTERNS.md
 *   - Error handling patterni i edge cases
 *   - Supabase errors, validation
 *   - Optimistic updates, retry logic
 *   - Offline handling, conflict resolution
 *   - Common errors
 *   - Format: SQL comments
 *   - Location: Root directory
 * 
 * TESTING_DEBUGGING_STRATEGIES.md
 *   - Testing i debugging strategije
 *   - Test data, test accounts
 *   - Console logging, Supabase Dashboard
 *   - Common debug queries, browser DevTools
 *   - Known bugs
 *   - Format: SQL comments
 *   - Location: Root directory
 */

/*
 * 3.9. DEPLOYMENT
 * -----------------
 * 
 * DEPLOYMENT_ENVIRONMENT_CONFIG.md
 *   - Deployment proces i environment konfiguracija
 *   - Env variables, Supabase config
 *   - Build process, deploy commands
 *   - Branches, database migrations
 *   - Rollback procedures
 *   - Format: SQL comments
 *   - Location: Root directory
 */

/*
 * 3.10. ADDITIONAL DOCUMENTATION
 * --------------------------------
 * 
 * SEF_BANK_DEPOSIT_DATA_SOURCES.md
 *   - Data sources za Sef Bank Deposit modul
 *   - Location: Root directory
 * 
 * LOCATION_ID_MAPPING_ISSUE.md
 *   - Location ID mapping issues
 *   - eMeni company_id vs pazar_locations UUID
 *   - Location: Root directory
 * 
 * MAGACIN_MODULE_PERMISSIONS.sql
 *   - SQL script za Magacin module permissions
 *   - Location: Root directory
 */

/* ============================================================================
 * 4. CRITICAL WARNINGS - Najčešće greške i šta NIKADA ne raditi
 * ============================================================================
 */

/*
 * 4.1. UUID vs eMeni ID TYPE MISMATCH
 * -------------------------------------
 * 
 * ⚠️ KRITIČNO: Location ID type mismatch
 * 
 * Problem:
 *   - eMeni orders koriste company_id (INTEGER)
 *   - Pazar locations koriste location_id (UUID)
 *   - Mapping između njih je implicit (nema eksplicitne tabele)
 * 
 * Šta NE raditi:
 *   - ❌ Ne pokušavaj direktno da porediš company_id sa location_id
 *   - ❌ Ne pretpostavljaj da su isti tip
 *   - ❌ Ne koristi company_id kao UUID
 * 
 * Šta raditi:
 *   - ✅ Koristi LOCATION_NAMES mapping constant
 *   - ✅ Konvertuj company_id u string/number pre poredjenja
 *   - ✅ Koristi fallback logiku za unmapped locations
 * 
 * Example:
 *   const locationName = LOCATION_NAMES[companyId] || 
 *                        LOCATION_NAMES[String(companyId)] || 
 *                        LOCATION_NAMES[Number(companyId)] || 
 *                        `Location ${companyId}`;
 * 
 * NAPOMENA: Location ID type mismatch je čest problem - uvek koristi mapping.
 */

/*
 * 4.2. FOREIGN KEY REDOSLED BRISANJA
 * ------------------------------------
 * 
 * ⚠️ KRITIČNO: Foreign key constraint violations
 * 
 * Problem:
 *   - Brisanje parent record-a pre child record-a dovodi do FK violation
 *   - Supabase automatski blokira brisanje ako postoje child records
 * 
 * Šta NE raditi:
 *   - ❌ Ne briši pazar_shifts pre pazar_daily_specifications
 *   - ❌ Ne briši pazar_finance_records pre pazar_bank_deposits
 *   - ❌ Ne briši pazar_users pre pazar_shifts
 * 
 * Šta raditi:
 *   - ✅ Uvek briši child records pre parent records
 *   - ✅ Koristi CASCADE DELETE gde je moguće (database level)
 *   - ✅ Proveri dependencies pre brisanja
 * 
 * Redosled brisanja (Pazar modul):
 *   1. pazar_specification_denominations
 *   2. pazar_daily_specifications
 *   3. pazar_bank_deposits
 *   4. pazar_finance_records
 *   5. pazar_cash_pickups
 *   6. pazar_shifts
 *   7. pazar_users (samo ako nema references)
 * 
 * NAPOMENA: Foreign key redosled je kritičan - uvek proveri dependencies.
 */

/*
 * 4.3. SUPABASE PAGINATION LIMIT
 * --------------------------------
 * 
 * ⚠️ VAŽNO: Supabase default limit je 1000 redova
 * 
 * Problem:
 *   - Supabase queries vraćaju max 1000 redova po default-u
 *   - Queries sa >1000 redova će vratiti samo prvi 1000
 * 
 * Šta NE raditi:
 *   - ❌ Ne pretpostavljaj da će query vratiti sve redove
 *   - ❌ Ne koristi .select('*') bez pagination za velike dataset-ove
 * 
 * Šta raditi:
 *   - ✅ Koristi fetchAllPaginated helper za queries sa >1000 redova
 *   - ✅ Koristi manual pagination sa .range(offset, offset + limit - 1)
 *   - ✅ Postavi maxRows limit (50000) za safety
 * 
 * Example:
 *   const allData = await fetchAllPaginated(baseQuery, {
 *     limit: 1000,
 *     maxRows: 50000,
 *     logPrefix: 'fetchOrders',
 *   });
 * 
 * NAPOMENA: Pagination je obavezan za queries sa >1000 redova.
 */

/*
 * 4.4. SERVICE KEY EXPOSURE
 * ---------------------------
 * 
 * ⚠️ KRITIČNO: Service key se NIKADA ne koristi u frontend-u
 * 
 * Problem:
 *   - Service key bypass-uje RLS policies
 *   - Full database access
 *   - Ako se expose-uje, security breach
 * 
 * Šta NE raditi:
 *   - ❌ NIKADA ne koristi SUPABASE_SERVICE_KEY u frontend kodu
 *   - ❌ NIKADA ne commit-uj service key u .env fajl
 *   - ❌ NIKADA ne loguj service key
 * 
 * Šta raditi:
 *   - ✅ Koristi samo VITE_SUPABASE_ANON_KEY u frontend-u
 *   - ✅ Service key se koristi samo u Edge Functions (backend)
 *   - ✅ Service key se čuva u Vercel environment variables (backend only)
 * 
 * NAPOMENA: Service key exposure je kritičan security issue - NIKADA u frontend-u.
 */

/*
 * 4.5. SENSITIVE DATA LOGGING
 * -----------------------------
 * 
 * ⚠️ VAŽNO: Sensitive data se NIKADA ne loguje
 * 
 * Problem:
 *   - PINs, passwords, tokens u console.log mogu biti exposed
 *   - Browser DevTools prikazuje sve console.log-ove
 * 
 * Šta NE raditi:
 *   - ❌ NIKADA ne loguj PIN: console.log('PIN:', pin)
 *   - ❌ NIKADA ne loguj password: console.log('Password:', password)
 *   - ❌ NIKADA ne loguj tokens: console.log('Token:', token)
 *   - ❌ NIKADA ne loguj session: console.log('Session:', session)
 * 
 * Šta raditi:
 *   - ✅ Loguj samo IDs, counts, names (safe data)
 *   - ✅ Koristi generic error messages
 *   - ✅ Mask sensitive data ako moraš logovati
 * 
 * NAPOMENA: Sensitive data logging je security risk - NIKADA ne loguj credentials.
 */

/*
 * 4.6. REALTIME SUBSCRIPTION CLEANUP
 * ------------------------------------
 * 
 * ⚠️ VAŽNO: Uvek cleanup-uj realtime subscriptions
 * 
 * Problem:
 *   - Subscriptions se ne cleanup-uju automatski
 *   - Memory leaks, duplicate subscriptions
 *   - Excessive network requests
 * 
 * Šta NE raditi:
 *   - ❌ Ne zaboravi cleanup u useEffect return
 *   - ❌ Ne kreiraj multiple subscriptions za isti channel
 * 
 * Šta raditi:
 *   - ✅ Uvek cleanup subscription u useEffect return
 *   - ✅ Koristi supabase.removeChannel(channel) za cleanup
 * 
 * Example:
 *   useEffect(() => {
 *     const channel = supabase.channel('orders-changes')
 *       .on('postgres_changes', ...)
 *       .subscribe();
 *     return () => {
 *       supabase.removeChannel(channel);
 *     };
 *   }, []);
 * 
 * NAPOMENA: Subscription cleanup je obavezan - uvek cleanup u useEffect return.
 */

/*
 * 4.7. DATE TIMEZONE HANDLING
 * -----------------------------
 * 
 * ⚠️ VAŽNO: Belgrade timezone (UTC+1) handling
 * 
 * Problem:
 *   - Dates se čuvaju u UTC u bazi
 *   - Belgrade je UTC+1 (winter) ili UTC+2 (summer)
 *   - Date range filtering mora da konvertuje Belgrade time u UTC
 * 
 * Šta NE raditi:
 *   - ❌ Ne koristi direktno new Date() bez timezone conversion
 *   - ❌ Ne pretpostavljaj da je date u local timezone
 * 
 * Šta raditi:
 *   - ✅ Koristi getDateRangeFilter utility za date range filtering
 *   - ✅ Konvertuj Belgrade dates u UTC pre query-ja
 *   - ✅ Koristi toLocaleString('sr-RS') za display
 * 
 * Example:
 *   const { start, end } = getDateRangeFilter(startDate, endDate);
 *   // start i end su UTC ISO strings
 * 
 * NAPOMENA: Date timezone handling je kritičan - uvek koristi getDateRangeFilter.
 */

/*
 * 4.8. CORS ERRORS (MAGACIN API)
 * -------------------------------
 * 
 * ⚠️ VAŽNO: Magacin API može imati CORS probleme
 * 
 * Problem:
 *   - External API (https://magacin.collina.co.rs/api/trebovanje)
 *   - Može blokirati requests sa frontend-a
 *   - CORS error se detektuje i prikazuje korisniku
 * 
 * Šta NE raditi:
 *   - ❌ Ne ignorisi CORS errors
 *   - ❌ Ne pokušavaj workaround bez backend proxy
 * 
 * Šta raditi:
 *   - ✅ Koristi proxy server (Vercel Edge Function)
 *   - ✅ Ili server-side API calls (backend endpoint)
 *   - ✅ CORS error se detektuje u magacinService.js
 * 
 * NAPOMENA: CORS errors za Magacin API - koristi proxy ili server-side calls.
 */

/* ============================================================================
 * 5. CONTACTS - Ko održava projekat, gde prijaviti bug
 * ============================================================================
 */

/*
 * 5.1. PROJECT MAINTAINER
 * -------------------------
 * 
 * Status: [To be filled by project owner]
 * 
 * Maintainer: [Name/Team]
 * Email: [Email]
 * GitHub: [GitHub username/organization]
 * 
 * NAPOMENA: Contact information se mora popuniti od strane project owner-a.
 */

/*
 * 5.2. BUG REPORTING
 * --------------------
 * 
 * Bug Reports:
 *   - GitHub Issues: [Repository URL]/issues
 *   - Email: [Support email]
 *   - Internal: [Internal ticketing system]
 * 
 * Bug Report Template:
 *   1. Description: Šta se dešava
 *   2. Steps to Reproduce: Kako reprodukovati
 *   3. Expected Behavior: Šta bi trebalo da se desi
 *   4. Actual Behavior: Šta se stvarno dešava
 *   5. Environment: Browser, OS, user role
 *   6. Screenshots: Ako je relevantno
 *   7. Console Errors: Browser console errors
 *   8. Network Errors: Network tab errors
 * 
 * NAPOMENA: Bug reporting process se mora definisati od strane project owner-a.
 */

/*
 * 5.3. FEATURE REQUESTS
 * -----------------------
 * 
 * Feature Requests:
 *   - GitHub Issues: [Repository URL]/issues (label: enhancement)
 *   - Email: [Product email]
 *   - Internal: [Product management system]
 * 
 * NAPOMENA: Feature request process se mora definisati od strane project owner-a.
 */

/* ============================================================================
 * 6. CHANGELOG - Istorija verzija dokumentacije
 * ============================================================================
 */

/*
 * 6.1. VERZIJA 1.0 - Initial Documentation
 * ------------------------------------------
 * 
 * Datum: 2026-01-17
 * 
 * Kreirana dokumentacija:
 *   - Database schema i queries (Pazar, Staff, Auth, Analytics, Orders, Magacin)
 *   - Business logic (Analytics, Orders, Pazar, Auth)
 *   - Application structure (Routing, UI/UX, Data formats)
 *   - State management patterns
 *   - Performance optimizations
 *   - Security measures
 *   - Error handling patterns
 *   - Testing & debugging strategies
 *   - Deployment & environment config
 *   - Business rules (Collina-specific)
 *   - External integrations
 *   - Master Index (ovaj fajl)
 * 
 * Format:
 *   - Sve dokumentacije su u Markdown formatu
 *   - Business logic dokumentacije su u SQL comment formatu (/* */)
 *   - Query dokumentacije su u Markdown tabelama
 * 
 * NAPOMENA: Verzija 1.0 je initial comprehensive documentation.
 */

/* ============================================================================
 * 7. VALIDATION CODE
 * ============================================================================
 */

/*
 * VALIDATION:
 * 
 * Ako si pročitao ovaj fajl, na početku svog odgovora napiši:
 * 
 * ✓ COLLINA-2026-PAZAR
 * 
 * Ovo potvrđuje da si pročitao master index i razumeš strukturu dokumentacije.
 */

/* ============================================================================
 * KRAJ MASTER INDEX-A
 * ============================================================================
 */
