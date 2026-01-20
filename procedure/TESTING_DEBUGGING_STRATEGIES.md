/*
 * ============================================================================
 * TESTING I DEBUGGING STRATEGIJE - KOMPLETNA DOKUMENTACIJA
 * ============================================================================
 * 
 * Ovaj dokument opisuje sve testing i debugging strategije u Collina platformi,
 * uključujući test data kreiranje, test accounts, console logging, Supabase
 * dashboard usage, common debug queries, Browser DevTools tips i known bugs.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. TEST DATA - Kako se kreira test data, reset funkcije
 * ============================================================================
 */

/*
 * 1.1. TEST DATA OVERVIEW
 * -------------------------
 * 
 * Trenutno stanje:
 *   - NEMA eksplicitnih test fajlova (*.test.js, *.spec.js)
 *   - NEMA automatizovanih testova (unit, integration, e2e)
 *   - Postoji MagacinTestPage za manual testing Magacin API-ja
 *   - Test data se kreira direktno u Supabase bazi
 * 
 * NAPOMENA: Test data se kreira manualno u Supabase dashboard-u ili kroz UI.
 */

/*
 * 1.2. MAGACIN TEST PAGE
 * ------------------------
 * 
 * Komponenta: src/modules/magacin/pages/MagacinTestPage.jsx
 * Route: /admin/magacin (test modul)
 * 
 * Funkcionalnosti:
 *   1. Test Radnje - testConnection('Radnje', magacinService.getRadnje, setRadnje)
 *   2. Test Artikli - testConnection('Artikli', magacinService.getArtikli, setArtikli)
 *   3. Test Stanje - testConnection('Stanje', magacinService.getStanje, setStanje)
 *   4. Test Trebovanja - testConnection('Trebovanja', magacinService.getTrebovanja, setTrebovanja)
 *   5. Test Kreiranje Trebovanja - testSubmit() sa formom
 * 
 * Test Pattern:
 *   const testConnection = async (name, fetchFn, setFn) => {
 *     try {
 *       setLoading(true);
 *       const data = await fetchFn();
 *       setFn(data);
 *       setSuccess(`${name}: Učitano ${Array.isArray(data) ? data.length : Object.keys(data).length} stavki`);
 *       console.log(`[Magacin Test] ${name}:`, data);
 *     } catch (err) {
 *       setError(`${name}: ${err.message}`);
 *       console.error(`[Magacin Test] ${name} error:`, err);
 *     } finally {
 *       setLoading(false);
 *     }
 *   };
 * 
 * Usage:
 *   - Otvori /admin/magacin
 *   - Klikni na test dugmad za svaki endpoint
 *   - Proveri console.log za response data
 *   - Proveri error/success poruke u UI
 * 
 * NAPOMENA: MagacinTestPage je manual testing tool za Magacin API integraciju.
 */

/*
 * 1.3. RESET FUNKCIJE
 * --------------------
 * 
 * Trenutno stanje:
 *   - NEMA eksplicitnih reset funkcija u kodu
 *   - clearCart() u useCart hook-u (Magacin modul)
 *   - Logout funkcije reset-uju auth state
 * 
 * clearCart() Pattern:
 *   const clearCart = useCallback(() => {
 *     setCart([]);
 *   }, []);
 * 
 * Logout Reset Pattern:
 *   const logout = async () => {
 *     await supabase.auth.signOut();
 *     setUser(null);
 *     setSession(null);
 *     setEmployee(null);
 *     setPermissions([]);
 *   };
 * 
 * NAPOMENA: Reset funkcije su ograničene na local state - nema database cleanup funkcija.
 */

/*
 * 1.4. TEST DATA KREIRANJE
 * --------------------------
 * 
 * Manual Test Data Creation:
 *   1. Otvori Supabase Dashboard
 *   2. Idi na Table Editor
 *   3. Insert test redove direktno u tabelu
 *   4. Ili koristi SQL Editor za bulk insert
 * 
 * Example SQL za test orders:
 *   INSERT INTO emeni_orders (order_id, company_id, status, provider, total, created_at)
 *   VALUES 
 *     ('TEST-001', 1, 1, 'wolt', 1500.00, NOW()),
 *     ('TEST-002', 2, 3, 'ebar', 2500.00, NOW() - INTERVAL '1 day');
 * 
 * Example SQL za test shifts:
 *   INSERT INTO pazar_shifts (user_id, location_id, status, started_at)
 *   VALUES 
 *     ('user-uuid', 1, 'active', NOW());
 * 
 * NAPOMENA: Test data se kreira manualno - nema seed scripts ili fixtures.
 */

/* ============================================================================
 * 2. TEST ACCOUNTS - Svi test kredencijali po roli
 * ============================================================================
 */

/*
 * 2.1. TEST ACCOUNTS OVERVIEW
 * -----------------------------
 * 
 * Trenutno stanje:
 *   - NEMA eksplicitnih test accounts dokumentovanih u kodu
 *   - Test accounts se kreiraju u Supabase Auth i pazar_users tabeli
 *   - Svaka rola zahteva različite permissions u module_permissions tabeli
 * 
 * NAPOMENA: Test accounts se kreiraju manualno u Supabase dashboard-u.
 */

/*
 * 2.2. EMAIL+PASSWORD ACCOUNTS (Admin Shell)
 * -------------------------------------------
 * 
 * Login Path: /login (LoginPage.jsx)
 * Auth Method: supabase.auth.signInWithPassword()
 * 
 * Test Accounts Structure:
 *   - Email: test@collina.co.rs (ili bilo koji valid email)
 *   - Password: (kreiran u Supabase Auth)
 *   - Employee Record: pazar_users tabela (email ili auth_user_id match)
 *   - Permissions: module_permissions tabela (role-based)
 * 
 * Role-Based Test Accounts:
 *   - admin: Puna pristupa svim modulima
 *   - menadzer: Pristup analytics, orders, magacin
 *   - finansije: Pristup pazar/finance modulu
 *   - konobar: Pristup staff modulu
 *   - vozac: Pristup staff/pickup modulu
 * 
 * SQL za kreiranje test account-a:
 *   -- 1. Kreiraj Auth user (u Supabase Auth dashboard)
 *   -- 2. Insert u pazar_users:
 *   INSERT INTO pazar_users (email, first_name, last_name, role, auth_user_id)
 *   VALUES ('test@collina.co.rs', 'Test', 'User', 'admin', 'auth-user-uuid');
 *   
 *   -- 3. Insert permissions:
 *   INSERT INTO module_permissions (role, module, can_view, can_edit)
 *   VALUES ('admin', 'analytics', true, true),
 *          ('admin', 'orders', true, true),
 *          ('admin', 'magacin', true, true);
 * 
 * NAPOMENA: Email+Password accounts koriste Supabase Auth sa pazar_users mapping.
 */

/*
 * 2.3. NAME+PIN ACCOUNTS (Staff App)
 * ------------------------------------
 * 
 * Login Path: /pazar/login (PinLoginPage.jsx)
 * Auth Method: pin-auth Edge Function
 * 
 * Test Accounts Structure:
 *   - Name: Search u pazar_users (first_name + last_name)
 *   - PIN: pin_code u pazar_users tabeli
 *   - Location: default_location_id u pazar_users
 * 
 * SQL za kreiranje PIN account-a:
 *   INSERT INTO pazar_users (first_name, last_name, pin_code, role, default_location_id)
 *   VALUES ('Test', 'Staff', '12345', 'konobar', 1);
 * 
 * PIN Rules:
 *   - PIN se čuva u pazar_users.pin_code
 *   - 3 failed attempts → account locked for 15 minutes
 *   - locked_until timestamp u pazar_users
 * 
 * Test PIN Accounts:
 *   - Name: "Test Staff"
 *   - PIN: "12345"
 *   - Role: konobar, vozac, menadzer
 * 
 * NAPOMENA: PIN accounts koriste pin-auth Edge Function za autentifikaciju.
 */

/*
 * 2.4. TEST ACCOUNT CHECKLIST
 * -----------------------------
 * 
 * Za svaku rolu, kreiraj:
 *   1. Supabase Auth user (email+password) ILI pazar_users (name+pin)
 *   2. pazar_users record sa role
 *   3. module_permissions records za svaki modul
 *   4. Testiraj login i pristup modulima
 * 
 * Roles:
 *   - admin: analytics, orders, magacin, pazar/finance
 *   - menadzer: analytics, orders, magacin
 *   - finansije: pazar/finance
 *   - konobar: staff/waiter
 *   - vozac: staff/pickup
 * 
 * NAPOMENA: Test accounts zahteva kreiranje u Supabase Auth i pazar_users tabeli.
 */

/* ============================================================================
 * 3. CONSOLE LOGGING - Gde su bitni console.log-ovi za debug
 * ============================================================================
 */

/*
 * 3.1. CONSOLE LOGGING OVERVIEW
 * ------------------------------
 * 
 * Pattern:
 *   - console.log() za general debugging
 *   - console.error() za errors
 *   - console.warn() za warnings
 *   - console.log sa prefiksima za module identification
 *   - JSON.stringify() za complex objects
 * 
 * NAPOMENA: Console logging je primary debugging tool - nema external logging service.
 */

/*
 * 3.2. DEBUG PREFIXES
 * ---------------------
 * 
 * Module-Specific Prefixes:
 *   - [Magacin Test]: MagacinTestPage.jsx
 *   - [useArtikli]: useArtikli.js hook
 *   - [PAZAR FINANCE]: pazarFinanceService.js
 *   - [BANK DEPOSIT]: BankDepositModalNew.jsx
 *   - [TAKE FROM SAFE]: TakeFromSafeModal.jsx
 *   - [LocationDayCard]: LocationDayCard.jsx
 *   - [CASH FLOW]: CashFlowCards.jsx
 *   - [PazarOverviewPage]: PazarOverviewPage.jsx
 * 
 * Analytics Prefixes:
 *   - === DATABASE ORDER FIELDS DEBUG ===
 *   - === LIFECYCLE DEBUG ===
 *   - === ORDER FIELDS DEBUG ===
 *   - === ORDER LIFECYCLE CALCULATION DEBUG ===
 *   - === HOURLY DATA DEBUG ===
 *   - === LIFECYCLE ORDER IDS DEBUG ===
 *   - === LIFECYCLE ATTACHMENT DEBUG ===
 * 
 * NAPOMENA: Prefixes olakšavaju filtering u browser console.
 */

/*
 * 3.3. CRITICAL CONSOLE LOG LOCATIONS
 * -------------------------------------
 * 
 * 1. Analytics Service (analyticsService.js):
 *   - Line 122: DATABASE ORDER FIELDS DEBUG (sample order structure)
 *   - Line 216: LIFECYCLE DEBUG (lifecycle events)
 *   - Line 277-299: processOrders debug (company_id matching)
 *   - Line 398: ORDER FIELDS DEBUG (field availability)
 *   - Line 456: ORDER LIFECYCLE CALCULATION DEBUG
 *   - Line 545: HOURLY DATA DEBUG
 *   - Line 969: fetchTrendOrders debug
 *   - Line 1019: fetchComparisonOrders debug
 * 
 * 2. Analytics Hook (useAnalyticsData.js):
 *   - Line 123-124: Date range logging
 *   - Line 133: Filters changed logging
 *   - Line 141: LIFECYCLE ORDER IDS DEBUG
 *   - Line 185-192: LIFECYCLE ATTACHMENT DEBUG
 * 
 * 3. Pazar Finance Service (pazarFinanceService.js):
 *   - Line 27: Error loading shifts
 *   - Line 40: Error loading specs
 *   - Line 69-73: Pickup loading details
 *   - Line 105-106: Finance records error details (JSON.stringify)
 *   - Line 129-144: Finance records details (mapped data)
 *   - Line 224-368: Group attachment debug logging
 * 
 * 4. Pazar Components:
 *   - LocationDayCard.jsx: Props, group data, modal state
 *   - CashFlowCards.jsx: Finance record state, pickup data
 *   - BankDepositModalNew.jsx: Error details (JSON.stringify), update data
 * 
 * 5. Magacin Module:
 *   - MagacinTestPage.jsx: Test API responses
 *   - useArtikli.js: Artikli loading, search errors
 * 
 * NAPOMENA: Critical console logs su u data fetching i error handling funkcijama.
 */

/*
 * 3.4. JSON.STRINGIFY PATTERNS
 * ------------------------------
 * 
 * Pattern 1: Error Details
 *   console.error('Error details:', JSON.stringify(error, null, 2));
 * 
 * Pattern 2: Sample Data
 *   console.log('Sample order:', JSON.stringify(order, null, 2));
 * 
 * Pattern 3: Complex Objects
 *   console.log('Finance record:', JSON.stringify(fr, null, 2));
 * 
 * Locations:
 *   - pazarFinanceService.js: Line 106 (financeError)
 *   - BankDepositModalNew.jsx: Line 115, 125 (error, exception)
 *   - TakeFromSafeModal.jsx: Line 157, 174, 190 (error details)
 *   - analyticsService.js: Line 124, 218, 400, 443, 465, 546 (sample data)
 *   - useAnalyticsData.js: Line 188, 192 (lifecycle data)
 * 
 * NAPOMENA: JSON.stringify sa null, 2 za pretty-print complex objects.
 */

/*
 * 3.5. CONSOLE LOGGING BEST PRACTICES
 * --------------------------------------
 * 
 * DO:
 *   - Koristi prefikse za module identification
 *   - Koristi JSON.stringify za complex objects
 *   - Log-uj error details (code, message, details, hint)
 *   - Log-uj sample data za debugging
 *   - Log-uj state changes u kritičnim funkcijama
 * 
 * DON'T:
 *   - Ne log-uj sensitive data (passwords, tokens)
 *   - Ne log-uj previše u production (performance)
 *   - Ne koristi console.log za user notifications (koristi alert ili UI)
 * 
 * NAPOMENA: Console logging je primary debugging tool - koristi ga konzistentno.
 */

/* ============================================================================
 * 4. SUPABASE DASHBOARD - Kako proveriti podatke direktno u bazi
 * ============================================================================
 */

/*
 * 4.1. SUPABASE DASHBOARD ACCESS
 * --------------------------------
 * 
 * URL: https://app.supabase.com/project/{project-id}
 * 
 * Sections:
 *   1. Table Editor - Browse i edit data
 *   2. SQL Editor - Run custom queries
 *   3. Auth - Manage users
 *   4. Storage - File storage
 *   5. Logs - API logs, database logs
 *   6. Settings - Project settings
 * 
 * NAPOMENA: Supabase Dashboard je primary tool za database inspection.
 */

/*
 * 4.2. TABLE EDITOR USAGE
 * -------------------------
 * 
 * Common Tasks:
 *   1. Browse data: Select table → View rows
 *   2. Filter: Use filter button (status = 'active', date >= '2026-01-01')
 *   3. Sort: Click column header
 *   4. Edit: Click row → Edit fields → Save
 *   5. Insert: Click "Insert row" → Fill fields → Save
 *   6. Delete: Click row → Delete button
 * 
 * Useful Tables:
 *   - emeni_orders: Live orders
 *   - emeni_order_lifecycle: Order lifecycle events
 *   - pazar_shifts: Active shifts
 *   - pazar_finance_records: Cash flow records
 *   - pazar_users: Staff users
 *   - module_permissions: Role permissions
 * 
 * NAPOMENA: Table Editor je najlakši način za quick data inspection.
 */

/*
 * 4.3. SQL EDITOR USAGE
 * -----------------------
 * 
 * Common Queries:
 *   -- Check recent orders
 *   SELECT * FROM emeni_orders 
 *   WHERE created_at >= NOW() - INTERVAL '1 day'
 *   ORDER BY created_at DESC
 *   LIMIT 100;
 * 
 *   -- Check active shifts
 *   SELECT * FROM pazar_shifts 
 *   WHERE status = 'active';
 * 
 *   -- Check finance records for today
 *   SELECT * FROM pazar_finance_records 
 *   WHERE date = CURRENT_DATE;
 * 
 *   -- Check user permissions
 *   SELECT mp.*, u.email, u.role 
 *   FROM module_permissions mp
 *   JOIN pazar_users u ON mp.role = u.role
 *   WHERE u.email = 'test@collina.co.rs';
 * 
 * NAPOMENA: SQL Editor omogućava complex queries i data manipulation.
 */

/*
 * 4.4. AUTH DASHBOARD USAGE
 * ---------------------------
 * 
 * Common Tasks:
 *   1. View users: Auth → Users → List all users
 *   2. Create user: Auth → Users → Add user
 *   3. Reset password: Click user → Reset password
 *   4. Delete user: Click user → Delete
 *   5. View sessions: Click user → View sessions
 * 
 * User Management:
 *   - Email: User email address
 *   - Created: Account creation date
 *   - Last Sign In: Last login timestamp
 *   - Confirmed: Email confirmation status
 * 
 * NAPOMENA: Auth Dashboard je za Supabase Auth user management.
 */

/*
 * 4.5. LOGS DASHBOARD USAGE
 * --------------------------
 * 
 * Log Types:
 *   1. API Logs: REST API requests/responses
 *   2. Database Logs: SQL queries and errors
 *   3. Auth Logs: Authentication events
 *   4. Realtime Logs: Realtime subscription events
 * 
 * Useful Filters:
 *   - Filter by table: emeni_orders, pazar_shifts
 *   - Filter by method: GET, POST, UPDATE, DELETE
 *   - Filter by status: 200, 400, 500
 *   - Filter by time: Last hour, last day
 * 
 * NAPOMENA: Logs Dashboard je za debugging API calls i database queries.
 */

/* ============================================================================
 * 5. COMMON DEBUG QUERIES - SQL upiti za dijagnostiku
 * ============================================================================
 */

/*
 * 5.1. ORDERS DEBUG QUERIES
 * --------------------------
 * 
 * Check recent orders:
 *   SELECT 
 *     id, order_id, company_id, status, provider, total, created_at
 *   FROM emeni_orders 
 *   WHERE created_at >= NOW() - INTERVAL '1 day'
 *   ORDER BY created_at DESC
 *   LIMIT 50;
 * 
 * Check orders without lifecycle:
 *   SELECT o.* 
 *   FROM emeni_orders o
 *   LEFT JOIN emeni_order_lifecycle l ON o.order_id = l.order_id
 *   WHERE l.order_id IS NULL
 *     AND o.created_at >= NOW() - INTERVAL '7 days';
 * 
 * Check order status distribution:
 *   SELECT status, COUNT(*) as count
 *   FROM emeni_orders
 *   WHERE created_at >= NOW() - INTERVAL '7 days'
 *   GROUP BY status
 *   ORDER BY status;
 * 
 * Check orders by provider:
 *   SELECT provider, COUNT(*) as count, SUM(total) as revenue
 *   FROM emeni_orders
 *   WHERE created_at >= NOW() - INTERVAL '7 days'
 *     AND status NOT IN (8, 9, 11)  -- Exclude canceled
 *   GROUP BY provider
 *   ORDER BY count DESC;
 * 
 * NAPOMENA: Orders debug queries su za troubleshooting order data issues.
 */

/*
 * 5.2. PAZAR DEBUG QUERIES
 * --------------------------
 * 
 * Check active shifts:
 *   SELECT s.*, u.first_name, u.last_name, l.location_name
 *   FROM pazar_shifts s
 *   LEFT JOIN pazar_users u ON s.user_id = u.id
 *   LEFT JOIN emeni_locations l ON s.location_id = l.company_id
 *   WHERE s.status = 'active';
 * 
 * Check finance records for today:
 *   SELECT fr.*, u.first_name, u.last_name, l.location_name
 *   FROM pazar_finance_records fr
 *   LEFT JOIN pazar_users u ON fr.received_by = u.id
 *   LEFT JOIN emeni_locations l ON fr.location_id = l.company_id
 *   WHERE fr.date = CURRENT_DATE
 *   ORDER BY fr.created_at DESC;
 * 
 * Check incomplete finance records:
 *   SELECT fr.*, 
 *     CASE 
 *       WHEN fr.received_at IS NULL THEN 'Not received'
 *       WHEN fr.verified_at IS NULL THEN 'Not verified'
 *       WHEN fr.banked_at IS NULL THEN 'Not banked'
 *       ELSE 'Complete'
 *     END as status
 *   FROM pazar_finance_records fr
 *   WHERE fr.date >= CURRENT_DATE - INTERVAL '7 days'
 *   ORDER BY fr.date DESC, fr.created_at DESC;
 * 
 * Check cash pickups:
 *   SELECT cp.*, u.first_name, u.last_name, l.location_name
 *   FROM pazar_cash_pickups cp
 *   LEFT JOIN pazar_users u ON cp.driver_id = u.id
 *   LEFT JOIN emeni_locations l ON cp.location_id = l.company_id
 *   WHERE cp.date >= CURRENT_DATE - INTERVAL '7 days'
 *   ORDER BY cp.date DESC, cp.created_at DESC;
 * 
 * NAPOMENA: Pazar debug queries su za troubleshooting cash flow issues.
 */

/*
 * 5.3. USER & PERMISSIONS DEBUG QUERIES
 * --------------------------------------
 * 
 * Check user permissions:
 *   SELECT u.*, mp.module, mp.can_view, mp.can_edit
 *   FROM pazar_users u
 *   LEFT JOIN module_permissions mp ON u.role = mp.role
 *   WHERE u.email = 'test@collina.co.rs';
 * 
 * Check all users with roles:
 *   SELECT u.id, u.email, u.first_name, u.last_name, u.role, 
 *          COUNT(mp.module) as module_count
 *   FROM pazar_users u
 *   LEFT JOIN module_permissions mp ON u.role = mp.role
 *   GROUP BY u.id, u.email, u.first_name, u.last_name, u.role
 *   ORDER BY u.role, u.email;
 * 
 * Check users without permissions:
 *   SELECT u.*
 *   FROM pazar_users u
 *   LEFT JOIN module_permissions mp ON u.role = mp.role
 *   WHERE mp.role IS NULL;
 * 
 * Check PIN users:
 *   SELECT id, first_name, last_name, pin_code, role, default_location_id
 *   FROM pazar_users
 *   WHERE pin_code IS NOT NULL
 *   ORDER BY role, first_name;
 * 
 * NAPOMENA: User & permissions queries su za troubleshooting auth issues.
 */

/*
 * 5.4. DATA INTEGRITY QUERIES
 * -----------------------------
 * 
 * Check orders without company_id:
 *   SELECT COUNT(*) as count
 *   FROM emeni_orders
 *   WHERE company_id IS NULL
 *     AND created_at >= NOW() - INTERVAL '7 days';
 * 
 * Check finance records without pickup:
 *   SELECT fr.*
 *   FROM pazar_finance_records fr
 *   LEFT JOIN pazar_cash_pickups cp ON fr.pickup_id = cp.id
 *   WHERE fr.pickup_id IS NOT NULL
 *     AND cp.id IS NULL;
 * 
 * Check shifts without user:
 *   SELECT s.*
 *   FROM pazar_shifts s
 *   LEFT JOIN pazar_users u ON s.user_id = u.id
 *   WHERE u.id IS NULL;
 * 
 * Check duplicate orders:
 *   SELECT order_id, COUNT(*) as count
 *   FROM emeni_orders
 *   WHERE created_at >= NOW() - INTERVAL '7 days'
 *   GROUP BY order_id
 *   HAVING COUNT(*) > 1;
 * 
 * NAPOMENA: Data integrity queries su za finding data inconsistencies.
 */

/* ============================================================================
 * 6. BROWSER DEVTOOLS - Šta gledati u Network/Console tab
 * ============================================================================
 */

/*
 * 6.1. CONSOLE TAB
 * ------------------
 * 
 * What to Look For:
 *   1. Error Messages: Red errors sa stack traces
 *   2. Warning Messages: Yellow warnings
 *   3. Debug Logs: Prefixed logs ([PAZAR FINANCE], [Magacin Test], etc.)
 *   4. Network Errors: Failed fetch requests
 *   5. Supabase Errors: Error objects sa code, message, details
 * 
 * Filtering:
 *   - Filter by text: Type "PAZAR" u filter box
 *   - Filter by level: Errors, Warnings, Info
 *   - Clear console: Cmd+K (Mac) ili Ctrl+L (Windows)
 * 
 * Useful Commands:
 *   - console.table(data): Display data as table
 *   - console.group('Label'): Group related logs
 *   - console.time('label'): Start timer
 *   - console.timeEnd('label'): End timer
 * 
 * NAPOMENA: Console tab je primary debugging tool za frontend issues.
 */

/*
 * 6.2. NETWORK TAB
 * ------------------
 * 
 * What to Look For:
 *   1. Failed Requests: Red status codes (400, 500)
 *   2. Slow Requests: Long duration (>1s)
 *   3. CORS Errors: Failed requests sa CORS error message
 *   4. Supabase Requests: Requests to supabase.co
 *   - URL pattern: /rest/v1/{table}?select=...
 *   - Headers: apikey, Authorization, Content-Type
 *   5. Magacin API Requests: Requests to magacin.collina.co.rs
 *   - URL pattern: /api/trebovanje/{endpoint}
 *   6. Edge Function Requests: Requests to /functions/v1/{function-name}
 * 
 * Request Details:
 *   - Headers: Request/Response headers
 *   - Payload: Request body (POST/PUT)
 *   - Response: Response body (JSON)
 *   - Timing: Request timing breakdown
 * 
 * Filtering:
 *   - Filter by type: XHR, Fetch, WS (WebSocket)
 *   - Filter by domain: supabase.co, magacin.collina.co.rs
 *   - Filter by status: 200, 400, 500
 * 
 * NAPOMENA: Network tab je za debugging API calls i network issues.
 */

/*
 * 6.3. APPLICATION TAB (Local Storage)
 * --------------------------------------
 * 
 * What to Look For:
 *   1. Supabase Auth: supabase.auth.token (session data)
 *   2. Zustand Stores: pazar-auth-store (PIN auth state)
 *   3. Other Local Storage: Custom app data
 * 
 * Supabase Auth Token:
 *   Key: supabase.auth.token
 *   Value: { access_token, refresh_token, expires_at, ... }
 * 
 * Zustand Store:
 *   Key: pazar-auth-store
 *   Value: { user, session, isAuthenticated, ... }
 * 
 * NAPOMENA: Application tab je za inspecting local storage i session data.
 */

/*
 * 6.4. REACT DEVTOOLS (Extension)
 * ----------------------------------
 * 
 * What to Look For:
 *   1. Component Tree: Component hierarchy
 *   2. Props: Component props
 *   3. State: Component state (useState)
 *   4. Hooks: Custom hooks state
 *   5. Context: Context values
 * 
 * Useful Features:
 *   - Inspect element: Right-click → Inspect
 *   - Highlight updates: Components that re-render
 *   - Profiler: Performance profiling
 * 
 * NAPOMENA: React DevTools je za debugging React component issues.
 */

/*
 * 6.5. COMMON DEVTOOLS WORKFLOWS
 * --------------------------------
 * 
 * Workflow 1: Debug API Call
 *   1. Open Network tab
 *   2. Filter by XHR/Fetch
 *   3. Trigger action (npr. submit form)
 *   4. Find request in Network tab
 *   5. Check Request/Response tabs
 *   6. Check Console tab for errors
 * 
 * Workflow 2: Debug State Issue
 *   1. Open React DevTools
 *   2. Find component in tree
 *   3. Check Props/State tabs
 *   4. Check Console tab for state logs
 * 
 * Workflow 3: Debug Auth Issue
 *   1. Open Application tab → Local Storage
 *   2. Check supabase.auth.token
 *   3. Check pazar-auth-store (if PIN auth)
 *   4. Open Console tab for auth errors
 *   5. Open Network tab for auth requests
 * 
 * NAPOMENA: DevTools workflows su za systematic debugging approach.
 */

/* ============================================================================
 * 7. KNOWN BUGS - Lista poznatih bug-ova i workaround-ova
 * ============================================================================
 */

/*
 * 7.1. PAZAR FINANCE RECORDS JOIN ERROR
 * ---------------------------------------
 * 
 * Bug:
 *   Error: "Could not find a relationship between 'pazar_finance_records' and 'pazar_users'"
 * 
 * Location:
 *   src/pages/admin/pazar/services/pazarFinanceService.js (Line 101-127)
 * 
 * Cause:
 *   Foreign key names u Supabase možda nisu ispravno konfigurisani
 *   (fk_received_by, fk_verified_by, fk_banked_by)
 * 
 * Workaround:
 *   - Fallback query bez JOINs (simple SELECT *)
 *   - User names se ne prikazuju, ali data se učitava
 * 
 * Fix:
 *   - Proveri foreign key names u Supabase dashboard
 *   - Ili koristi explicit foreign key names u query:
 *     received_by_user:pazar_users!fk_received_by
 * 
 * Status: Workaround implementiran, fix pending
 * 
 * NAPOMENA: Pazar finance records JOIN error ima fallback mehanizam.
 */

/*
 * 7.2. MAGACIN API CORS ERROR
 * -----------------------------
 * 
 * Bug:
 *   Error: "CORS greška: API ne dozvoljava pristup sa ovog domena"
 * 
 * Location:
 *   src/modules/magacin/services/magacinService.js (Line 22-24)
 * 
 * Cause:
 *   Magacin API (magacin.collina.co.rs) ne dozvoljava cross-origin requests
 *   sa frontend domena
 * 
 * Workaround:
 *   - Nema trenutnog workaround-a
 *   - API pozivi fail-uju sa CORS error
 * 
 * Fix:
 *   - Koristiti proxy (Edge Function ili backend API)
 *   - Ili konfigurisati CORS na Magacin API serveru
 * 
 * Status: Known issue, fix pending
 * 
 * NAPOMENA: Magacin API CORS error zahteva proxy ili server-side poziv.
 */

/*
 * 7.3. COMPANY_ID TYPE MISMATCH
 * -------------------------------
 * 
 * Bug:
 *   Location filtering ne radi zbog type mismatch (string vs number)
 * 
 * Location:
 *   src/modules/analytics/services/analyticsService.js (Line 277-299)
 * 
 * Cause:
 *   - emeni_orders.company_id može biti INTEGER ili TEXT
 *   - emeni_locations.company_id je INTEGER
 *   - Filtering ne match-uje zbog type mismatch
 * 
 * Workaround:
 *   - Explicit type conversion u filter logic:
 *     locationIds.map(String).includes(String(o.company_id))
 * 
 * Fix:
 *   - Normalizovati company_id tip u bazi (svi INTEGER)
 *   - Ili koristi consistent type conversion u kodu
 * 
 * Status: Workaround implementiran, fix pending
 * 
 * NAPOMENA: Company_id type mismatch ima workaround u filter logic.
 */

/*
 * 7.4. SUPABASE PAGINATION LIMIT
 * --------------------------------
 * 
 * Bug:
 *   Supabase vraća max 1000 rows po query
 * 
 * Location:
 *   src/modules/analytics/services/analyticsService.js (fetchOrders, fetchTrendOrders)
 *   src/modules/analytics/utils/supabasePagination.js
 * 
 * Cause:
 *   Supabase default limit je 1000 rows
 * 
 * Workaround:
 *   - fetchAllPaginated helper za manual pagination
 *   - .range(offset, offset + limit - 1) za batch fetching
 * 
 * Fix:
 *   - fetchAllPaginated helper je implementiran
 *   - Svi fetch functions koriste pagination
 * 
 * Status: Fixed (pagination helper implementiran)
 * 
 * NAPOMENA: Supabase pagination limit je rešen sa fetchAllPaginated helper-om.
 */

/*
 * 7.5. LIFECYCLE DATA MISSING
 * -----------------------------
 * 
 * Bug:
 *   Order lifecycle data se ne učitava za neke orders
 * 
 * Location:
 *   src/modules/analytics/services/analyticsService.js (fetchOrderLifecycle)
 * 
 * Cause:
 *   - Batch query sa order_id=in.(id1,id2,...) može fail-ovati za velike liste
 *   - REST API fallback možda ne radi uvek
 * 
 * Workaround:
 *   - REST API fallback sa explicit query string
 *   - Manual lifecycle attachment u useAnalyticsData hook
 * 
 * Fix:
 *   - Proveri da li REST API query format radi
 *   - Ili koristi Supabase JS client sa batch queries
 * 
 * Status: Workaround implementiran, monitoring
 * 
 * NAPOMENA: Lifecycle data missing ima REST API fallback mehanizam.
 */

/*
 * 7.6. DATE TIMEZONE ISSUES
 * ---------------------------
 * 
 * Bug:
 *   Date filtering ne radi ispravno zbog timezone razlika
 * 
 * Location:
 *   src/modules/analytics/utils/dateFilters.js
 * 
 * Cause:
 *   - Belgrade timezone (UTC+1)
 *   - Supabase čuva dates u UTC
 *   - Date range filtering mora da konvertuje u UTC
 * 
 * Workaround:
 *   - getDateRangeFilter utility za timezone-aware conversion
 *   - Explicit UTC conversion za date ranges
 * 
 * Fix:
 *   - getDateRangeFilter helper je implementiran
 *   - Svi fetch functions koriste getDateRangeFilter
 * 
 * Status: Fixed (date filter helper implementiran)
 * 
 * NAPOMENA: Date timezone issues su rešeni sa getDateRangeFilter helper-om.
 */

/*
 * 7.7. PIN AUTH LOCKED ACCOUNT
 * ------------------------------
 * 
 * Bug:
 *   Account se zaključava posle 3 failed PIN attempts
 * 
 * Location:
 *   src/modules/pazar/stores/pazarAuthStore.js (Line 82-88)
 * 
 * Cause:
 *   Security feature - account locking za brute force protection
 * 
 * Workaround:
 *   - Čekaj 15 minuta za unlock
 *   - Ili reset locked_until u Supabase dashboard
 * 
 * Fix:
 *   - Nije bug - security feature
 *   - Admin može reset-ovati locked_until u bazi
 * 
 * Status: By design (security feature)
 * 
 * NAPOMENA: PIN auth locked account je security feature, ne bug.
 */

/*
 * 7.8. COMMON BUGS SUMMARY
 * -------------------------
 * 
 * Critical Bugs (Need Fix):
 *   1. Pazar Finance Records JOIN Error (workaround exists)
 *   2. Magacin API CORS Error (no workaround)
 *   3. Company_ID Type Mismatch (workaround exists)
 * 
 * Fixed Bugs:
 *   1. Supabase Pagination Limit (fixed with helper)
 *   2. Date Timezone Issues (fixed with helper)
 * 
 * Monitoring:
 *   1. Lifecycle Data Missing (workaround exists)
 * 
 * By Design:
 *   1. PIN Auth Locked Account (security feature)
 * 
 * NAPOMENA: Known bugs su dokumentovani sa workaround-ima gde postoje.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
