/*
 * ============================================================================
 * EKSTERNE INTEGRACIJE - KOMPLETNA DOKUMENTACIJA
 * ============================================================================
 * 
 * Ovaj dokument opisuje sve eksterne integracije u Collina platformi,
 * uključujući eMeni webhooks, Magacin API, Wolt/Glovo integracije,
 * Supabase Edge Functions, Vercel deploy i error monitoring.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. EMENI WEBHOOK - Kako stižu porudžbine, format payloada
 * ============================================================================
 */

/*
 * 1.1. EMENI WEBHOOK OVERVIEW
 * -----------------------------
 * 
 * Trenutno stanje:
 *   - NEMA eksplicitnog webhook handler-a u frontend kodu
 *   - Porudžbine se čitaju direktno iz Supabase tabele (emeni_orders)
 *   - Pretpostavlja se da eMeni sistem šalje webhooks u Supabase
 * 
 * NAPOMENA: Webhook handling se dešava na Supabase nivou (database triggers
 *           ili Edge Functions), ne u frontend aplikaciji.
 */

/*
 * 1.2. EMENI_ORDERS TABELA
 * --------------------------
 * 
 * Tabela: emeni_orders
 * 
 * Struktura:
 *   - id: UUID (primary key)
 *   - order_id: TEXT (external order ID)
 *   - company_id: INTEGER (location ID)
 *   - status: INTEGER (1, 3, 5, 7, 8, 9, 11)
 *   - provider: TEXT ('wolt', 'ebar', 'gloriafood', 'emeniwaiter')
 *   - total: DECIMAL (order total)
 *   - order_total: DECIMAL (alternative total field)
 *   - created_at: TIMESTAMP (order creation time)
 *   - raw_payload: JSONB (complete order data from eMeni)
 *   - items: JSONB (parsed items array)
 *   - note: TEXT (order note)
 *   - waiter_name: TEXT (waiter name)
 *   - table_number: TEXT (table number)
 * 
 * NAPOMENA: emeni_orders tabela čuva sve porudžbine iz eMeni sistema.
 */

/*
 * 1.3. RAW_PAYLOAD STRUKTURA
 * ----------------------------
 * 
 * raw_payload (JSONB) sadrži kompletan order data iz eMeni sistema:
 * 
 * Structure:
 *   {
 *     items: [
 *       {
 *         name: string,
 *         quantity: number,
 *         price: number,
 *         modifiers: [...]
 *       }
 *     ],
 *     waiter: {
 *       name: string,
 *       tableReferenceID: number
 *     },
 *     table: {
 *       id: number,
 *       name: string
 *     },
 *     deliveryDetail: {
 *       name: string,
 *       address: string,
 *       phone: string
 *     },
 *     acceptedAt: timestamp,
 *     readyAt: timestamp,
 *     deliveredAt: timestamp,
 *     completedAt: timestamp,
 *     status: number,
 *     total: number,
 *     note: string
 *   }
 * 
 * NAPOMENA: raw_payload čuva kompletan originalni payload iz eMeni sistema.
 */

/*
 * 1.4. WEBHOOK FLOW (Pretpostavljeno)
 * -------------------------------------
 * 
 * Step 1: eMeni sistem kreira porudžbinu
 *   - eMeni POS ili delivery platform kreira order
 *   - eMeni sistem šalje webhook u Supabase
 * 
 * Step 2: Supabase prima webhook
 *   - Database trigger ili Edge Function prima webhook
 *   - Parsira payload i insert-uje u emeni_orders
 *   - Kreira lifecycle events u emeni_order_lifecycle
 * 
 * Step 3: Frontend detektuje promenu
 *   - Supabase Realtime subscription detektuje INSERT
 *   - fetchOrders() se poziva automatski
 *   - UI se ažurira sa novom porudžbinom
 * 
 * NAPOMENA: Webhook flow nije eksplicitno dokumentovan u frontend kodu.
 */

/*
 * 1.5. REALTIME SUBSCRIPTION
 * ----------------------------
 * 
 * Komponenta: LiveOrdersPage.jsx
 * 
 * Subscription:
 *   const channel = supabase
 *     .channel('orders-changes')
 *     .on('postgres_changes', 
 *       { event: '*', schema: 'public', table: 'emeni_orders' },
 *       () => fetchOrders()
 *     )
 *     .subscribe();
 * 
 * Behavior:
 *   - Na svaku promenu u emeni_orders (INSERT, UPDATE, DELETE):
 *     → fetchOrders() se poziva
 *     → Sve porudžbine za dan se ponovo učitavaju
 *     → UI se ažurira
 * 
 * NAPOMENA: Realtime subscription omogućava live updates bez webhook handling-a
 *           u frontend-u.
 */

/* ============================================================================
 * 2. MAGACIN API - Endpoints, auth, request/response format
 * ============================================================================
 */

/*
 * 2.1. MAGACIN API OVERVIEW
 * ---------------------------
 * 
 * Base URL: https://magacin.collina.co.rs/api/trebovanje
 * 
 * Authentication:
 *   - NEMA eksplicitne autentifikacije u kodu
 *   - API pozivi se šalju direktno (bez API key ili token)
 *   - CORS može biti problem (detektuje se u apiCall helper-u)
 * 
 * NAPOMENA: Magacin API je eksterni REST API bez eksplicitne autentifikacije.
 */

/*
 * 2.2. API CALL HELPER
 * ----------------------
 * 
 * Funkcija: apiCall() (magacinService.js)
 * 
 * Implementation:
 *   async function apiCall(endpoint, options = {}) {
 *     try {
 *       const res = await fetch(`${API_BASE}${endpoint}`, {
 *         ...options,
 *         headers: {
 *           'Content-Type': 'application/json',
 *           ...options.headers,
 *         },
 *       });
 *       
 *       if (!res.ok) {
 *         const errorText = await res.text().catch(() => res.statusText);
 *         throw new Error(`HTTP ${res.status}: ${errorText}`);
 *       }
 *       
 *       return res.json();
 *     } catch (err) {
 *       // Check for CORS or network errors
 *       if (err.message?.includes('Failed to fetch') || err.message?.includes('CORS')) {
 *         throw new Error('CORS greška: API ne dozvoljava pristup sa ovog domena.');
 *       }
 *       throw err;
 *     }
 *   }
 * 
 * Features:
 *   - CORS error detection
 *   - Network error handling
 *   - HTTP status error handling
 *   - JSON response parsing
 * 
 * NAPOMENA: apiCall helper centralizuje error handling za sve Magacin API pozive.
 */

/*
 * 2.3. MAGACIN API ENDPOINTS
 * ----------------------------
 * 
 * GET /radnje
 *   - Lista svih radnji
 *   - Response: Array<{ sifra, naziv }>
 * 
 * GET /artikli
 *   - Svi artikli
 *   - Response: Array<{ acIdent, acName, acUM, ... }>
 * 
 * GET /stanje
 *   - Stanje po skladištima
 *   - Response: { [skladiste]: { [artikal]: { stock, reserved } } }
 * 
 * GET /lista
 *   - Lista trebovanja
 *   - Response: Array<{ acKey, id, status, radnja, datum, ... }>
 * 
 * POST /submit
 *   - Kreiraj trebovanje
 *   - Body: { radnja, stavke: [...] }
 *   - Response: { success, trebovanjeKey, id }
 * 
 * GET /artikli-radnja/{radnjaSifra}
 *   - Artikli za specifičnu radnju sa stanjem
 *   - Response: Array<{ acIdent, acName, anStockCM, anReservedCM, anStockMP, anReservedMP, anMinStock, ... }>
 * 
 * GET /artikli-ostalo/{radnjaSifra}?search={term}
 *   - Pretraga artikala koje radnja NE koristi
 *   - Response: Array<{ acIdent, acName, ... }>
 * 
 * GET /detalji/{key} (ili GET /{key} fallback)
 *   - Detalji trebovanja
 *   - Response: { acKey, status, radnja, datum, stavke: [...], ... }
 * 
 * POST /posalji/{key}
 *   - Pošalji robu (CM → Radnja)
 *   - Body: { userId, izmene: [...] }
 *   - Response: { success, ... }
 * 
 * POST /primi/{key}
 *   - Primi robu
 *   - Body: { userId }
 *   - Response: { success, ... }
 * 
 * GET /prenosi
 *   - Lista prenosa
 *   - Response: Array<{ acKey, id, datum, vrednost, ... }>
 * 
 * GET /prenos/{key}
 *   - Detalji prenosa
 *   - Response: { acKey, datum, stavke: [...], ... }
 * 
 * GET /nedostaje
 *   - Nedostajući artikli
 *   - Response: Array<{ id, artikal, radnja, datum, ... }>
 * 
 * POST /nedostaje/resi/{id}
 *   - Reši nedostaje
 *   - Response: { success, ... }
 * 
 * NAPOMENA: Svi endpoints koriste apiCall helper za error handling.
 */

/*
 * 2.4. REQUEST/RESPONSE FORMATS
 * -------------------------------
 * 
 * Request Format:
 *   - Method: GET ili POST
 *   - Headers: Content-Type: application/json
 *   - Body (POST): JSON stringified
 * 
 * Response Format:
 *   - Content-Type: application/json
 *   - Success: JSON object ili array
 *   - Error: HTTP status code + error text
 * 
 * Example Request (createTrebovanje):
 *   POST /submit
 *   Body: {
 *     "radnja": "MP-P47",
 *     "stavke": [
 *       {
 *         "sifra": "A2023",
 *         "naziv": "Alu folija 300 mm",
 *         "jm": "KOM",
 *         "kolicina": 10
 *       }
 *     ]
 *   }
 * 
 * Example Response:
 *   {
 *     "success": true,
 *     "trebovanjeKey": "TREB-2026-001",
 *     "id": "..."
 *   }
 * 
 * NAPOMENA: Request/response format je standardni JSON REST API.
 */

/*
 * 2.5. CORS HANDLING
 * --------------------
 * 
 * Problem:
 *   - Magacin API može imati CORS restrictions
 *   - Browser blokira cross-origin requests
 * 
 * Detection:
 *   if (err.message?.includes('Failed to fetch') || err.message?.includes('CORS')) {
 *     throw new Error('CORS greška: API ne dozvoljava pristup sa ovog domena.');
 *   }
 * 
 * Solution:
 *   - Koristiti proxy ili server-side poziv
 *   - Edge Function kao proxy
 *   - Backend API kao middleware
 * 
 * NAPOMENA: CORS se detektuje ali nije rešen - zahteva proxy ili server-side poziv.
 */

/* ============================================================================
 * 3. WOLT/GLOVO - Da li ima direktne integracije
 * ============================================================================
 */

/*
 * 3.1. WOLT INTEGRATION STATUS
 * ------------------------------
 * 
 * Trenutno stanje:
 *   - NEMA direktne Wolt API integracije
 *   - Wolt porudžbine se čitaju iz Supabase tabele (wolt_orders)
 *   - Pretpostavlja se da Wolt šalje webhooks u Supabase
 * 
 * NAPOMENA: Wolt integracija nije direktna - koristi se wolt_orders tabela.
 */

/*
 * 3.2. WOLT_ORDERS TABELA
 * -------------------------
 * 
 * Tabela: wolt_orders
 * 
 * Struktura:
 *   - id: UUID (primary key)
 *   - venue_id: INTEGER (location ID)
 *   - venue_name: TEXT (location name)
 *   - amount: INTEGER (price in cents, divide by 100)
 *   - created_at: TIMESTAMP (order creation time)
 *   - order_status: TEXT ('delivered', 'rejected', 'cancelled')
 *   - (ostala polja)
 * 
 * Usage:
 *   - Koristi se za historijske podatke (2025 i ranije)
 *   - Normalizuje se u emeni_orders format za comparison
 * 
 * NAPOMENA: wolt_orders je legacy tabela za historijske Wolt podatke.
 */

/*
 * 3.3. WOLT DATA NORMALIZATION
 * ------------------------------
 * 
 * Function: fetchComparisonOrders() (analyticsService.js)
 * 
 * Normalization Logic:
 *   if (tableName === 'wolt_orders') {
 *     allData = allData.map(o => ({
 *       ...o,
 *       // wolt_orders uses 'amount' in cents, convert to RSD
 *       total: (o.amount || 0) / 100,
 *       order_total: (o.amount || 0) / 100,
 *       // Map venue_name to company_id for location filtering
 *       company_id: o.venue_name,
 *       // Map order_status text to numeric
 *       status: (o.order_status === 'rejected' || o.order_status === 'cancelled') ? 8 : 1,
 *       // Provider for channel filtering
 *       provider: 'wolt',
 *     }));
 *   }
 * 
 * Mapping:
 *   - amount (cents) → total (RSD) = amount / 100
 *   - venue_name → company_id
 *   - order_status ('rejected'/'cancelled') → status (8)
 *   - order_status ('delivered') → status (1)
 *   - provider → 'wolt'
 * 
 * NAPOMENA: Wolt data se normalizuje u emeni_orders format za unified processing.
 */

/*
 * 3.4. GLOVO INTEGRATION
 * ------------------------
 * 
 * Trenutno stanje:
 *   - NEMA Glovo integracije
 *   - Glovo nije pomenut u kodu
 * 
 * NAPOMENA: Glovo integracija ne postoji.
 */

/*
 * 3.5. GLORIA FOOD INTEGRATION
 * ------------------------------
 * 
 * Status:
 *   - Gloria Food porudžbine se čitaju iz emeni_orders
 *   - Provider: 'gloriafood'
 *   - NEMA direktne Gloria Food API integracije
 * 
 * Usage:
 *   - Filter: selectedChannels.has('gloriafood')
 *   - Display: Provider badge sa 'gloriafood' label
 * 
 * NAPOMENA: Gloria Food integracija nije direktna - koristi se emeni_orders tabela.
 */

/* ============================================================================
 * 4. SUPABASE EDGE FUNCTIONS - Koje postoje, šta rade
 * ============================================================================
 */

/*
 * 4.1. PIN-AUTH EDGE FUNCTION
 * -----------------------------
 * 
 * Endpoint: /functions/v1/pin-auth
 * Method: POST
 * 
 * Usage: pazarAuthStore.js (login function)
 * 
 * Request:
 *   POST ${SUPABASE_URL}/functions/v1/pin-auth
 *   Headers: {
 *     'Content-Type': 'application/json',
 *     'Authorization': `Bearer ${VITE_SUPABASE_ANON_KEY}`
 *   }
 *   Body: {
 *     user_id: UUID,
 *     pin: "12345"
 *   }
 * 
 * Response (Success):
 *   {
 *     success: true,
 *     user: { id, first_name, last_name, role, ... },
 *     session: { access_token, refresh_token }
 *   }
 * 
 * Response (Error):
 *   {
 *     success: false,
 *     error: "Pogrešan PIN",
 *     remaining_attempts: 2
 *   }
 * 
 * Response (Locked):
 *   {
 *     success: false,
 *     locked: true,
 *     error: "Nalog je zaključan",
 *     remaining_minutes: 15
 *   }
 * 
 * Logic (Pretpostavljeno):
 *   1. Query: SELECT * FROM pazar_users WHERE id = user_id
 *   2. Proverava: user.pin_code === pin
 *   3. Proverava: user.failed_attempts < 3 (ili locked_until < now())
 *   4. Ako validno:
 *      a) Reset failed_attempts = 0
 *      b) Kreira Supabase session programski
 *      c) Vraća { success: true, user, session }
 *   5. Ako invalidno:
 *      a) UPDATE pazar_users SET failed_attempts = failed_attempts + 1
 *      b) Ako failed_attempts >= 3: locked_until = now() + 15min
 *      c) Vraća { success: false, error, remaining_attempts, locked }
 * 
 * NAPOMENA: pin-auth Edge Function nije u frontend kodu - pretpostavlja se
 *           implementacija na Supabase nivou.
 */

/*
 * 4.2. EDGE FUNCTION URL CONSTRUCTION
 * -------------------------------------
 * 
 * Pattern:
 *   const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
 *   const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/pin-auth`;
 * 
 * Example:
 *   SUPABASE_URL = "https://xxxxx.supabase.co"
 *   EDGE_FUNCTION_URL = "https://xxxxx.supabase.co/functions/v1/pin-auth"
 * 
 * NAPOMENA: Edge Function URL se konstruiše od Supabase URL-a.
 */

/*
 * 4.3. EDGE FUNCTION AUTHENTICATION
 * ----------------------------------
 * 
 * Headers:
 *   'Authorization': `Bearer ${VITE_SUPABASE_ANON_KEY}`
 *   'Content-Type': 'application/json'
 * 
 * NAPOMENA: Edge Function koristi Supabase anon key za autentifikaciju.
 */

/*
 * 4.4. OTHER EDGE FUNCTIONS
 * ---------------------------
 * 
 * Trenutno stanje:
 *   - NEMA drugih Edge Functions u kodu
 *   - Samo pin-auth je dokumentovan
 * 
 * Potential Edge Functions:
 *   - Webhook handler za eMeni orders
 *   - Webhook handler za Wolt orders
 *   - Data normalization service
 *   - Report generation service
 * 
 * NAPOMENA: Drugi Edge Functions nisu implementirani ili dokumentovani.
 */

/* ============================================================================
 * 5. VERCEL - Deploy process, env variables
 * ============================================================================
 */

/*
 * 5.1. VERCEL CONFIGURATION
 * ---------------------------
 * 
 * File: vercel.json
 * 
 * Content:
 *   {
 *     "rewrites": [
 *       { "source": "/(.*)", "destination": "/" }
 *     ]
 *   }
 * 
 * Purpose:
 *   - SPA routing support (React Router)
 *   - Sve rute se rewrite-uju na index.html
 *   - Omogućava client-side routing
 * 
 * NAPOMENA: Vercel config je minimalan - samo SPA routing rewrite.
 */

/*
 * 5.2. ENVIRONMENT VARIABLES
 * ----------------------------
 * 
 * Required Variables:
 *   - VITE_SUPABASE_URL: Supabase project URL
 *   - VITE_SUPABASE_ANON_KEY: Supabase anonymous key
 * 
 * Usage:
 *   const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
 *   const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
 * 
 * Validation:
 *   if (!supabaseUrl || !supabaseAnonKey) {
 *     throw new Error('Missing Supabase environment variables...');
 *   }
 * 
 * NAPOMENA: Environment variables se koriste za Supabase konfiguraciju.
 */

/*
 * 5.3. VERCEL DEPLOY PROCESS
 * ----------------------------
 * 
 * Trenutno stanje:
 *   - NEMA eksplicitnog deploy dokumenta
 *   - Pretpostavlja se standardni Vercel deploy
 * 
 * Standard Vercel Deploy:
 *   1. Connect repository to Vercel
 *   2. Set environment variables in Vercel dashboard
 *   3. Deploy automatically on git push
 *   4. Build command: npm run build (ili vite build)
 *   5. Output directory: dist (ili build)
 * 
 * NAPOMENA: Deploy process nije eksplicitno dokumentovan.
 */

/*
 * 5.4. BUILD CONFIGURATION
 * --------------------------
 * 
 * Framework: Vite (React)
 * 
 * Build Command:
 *   npm run build
 *   vite build
 * 
 * Output Directory:
 *   dist/
 * 
 * NAPOMENA: Build configuration je standardni Vite setup.
 */

/* ============================================================================
 * 6. ERROR MONITORING - Da li postoji Sentry ili slično
 * ============================================================================
 */

/*
 * 6.1. ERROR MONITORING STATUS
 * ------------------------------
 * 
 * Trenutno stanje:
 *   - NEMA error monitoring servisa (Sentry, LogRocket, itd.)
 *   - Errors se loguju samo u console (console.error, console.warn)
 *   - Nema automatskog error reporting-a
 * 
 * NAPOMENA: Error monitoring nije implementiran.
 */

/*
 * 6.2. CURRENT ERROR LOGGING
 * ----------------------------
 * 
 * Pattern: console.error()
 *   console.error('Error fetching X:', error);
 *   console.error('Error details:', { code, message, details, hint });
 * 
 * Pattern: console.warn()
 *   console.warn('Warning message');
 * 
 * Pattern: console.log()
 *   console.log('[DEBUG] Query details:', { ... });
 * 
 * NAPOMENA: Error logging je samo u browser console - nema external service.
 */

/*
 * 6.3. POTENTIAL ERROR MONITORING
 * ---------------------------------
 * 
 * Option 1: Sentry
 *   - Integracija sa @sentry/react
 *   - Automatsko error tracking
 *   - Performance monitoring
 *   - User feedback
 * 
 * Option 2: LogRocket
 *   - Session replay
 *   - Error tracking
 *   - Performance monitoring
 * 
 * Option 3: Custom Error Service
 *   - Edge Function za error logging
 *   - Supabase tabela za error logs
 *   - Custom dashboard
 * 
 * NAPOMENA: Error monitoring bi poboljšao debugging ali zahteva implementaciju.
 */

/* ============================================================================
 * 7. DODATNE NAPOMENE
 * ============================================================================
 */

/*
 * 7.1. SUPABASE REST API USAGE
 * ------------------------------
 * 
 * Direct REST API Calls:
 *   - fetchOrderLifecycle() koristi direktni REST API poziv
 *   - URL: ${SUPABASE_URL}/rest/v1/emeni_order_lifecycle
 *   - Headers: apikey, Authorization, Content-Type, Prefer
 *   - Query params: select, order_id=in.(...), status=in.(...)
 * 
 * Reason:
 *   - Fallback ako Supabase JS client fail-uje
 *   - Batch query sa order_id=in.(id1,id2,id3) format
 * 
 * Example:
 *   const url = `${SUPABASE_URL}/rest/v1/emeni_order_lifecycle?select=order_id,status,timestamp&order_id=in.(${orderIdsStr})&status=in.(3,5,7)`;
 *   const response = await fetch(url, {
 *     headers: {
 *       'apikey': SUPABASE_KEY,
 *       'Authorization': `Bearer ${SUPABASE_KEY}`,
 *       'Content-Type': 'application/json',
 *       'Prefer': 'return=representation'
 *     }
 *   });
 * 
 * NAPOMENA: Supabase REST API se koristi kao fallback za batch queries.
 */

/*
 * 7.2. EXTERNAL API AUTHENTICATION
 * ----------------------------------
 * 
 * Magacin API:
 *   - NEMA autentifikacije u kodu
 *   - CORS može biti problem
 * 
 * Supabase API:
 *   - Anon key u Authorization header
 *   - Service key za admin operacije (nije u frontend-u)
 * 
 * Edge Functions:
 *   - Anon key u Authorization header
 *   - Edge Function proverava autentifikaciju interno
 * 
 * NAPOMENA: Authentication zavisi od API-ja - Magacin nema, Supabase koristi anon key.
 */

/*
 * 7.3. API ERROR HANDLING
 * -------------------------
 * 
 * Magacin API:
 *   - CORS error detection
 *   - HTTP status error handling
 *   - Network error handling
 * 
 * Supabase API:
 *   - Error object sa code, message, details, hint
 *   - Fallback na REST API ako JS client fail-uje
 * 
 * Edge Functions:
 *   - Response.ok check
 *   - data.error check
 *   - Try-catch za network errors
 * 
 * NAPOMENA: API error handling je konzistentan - svi API-ji imaju error handling.
 */

/*
 * 7.4. DATA SOURCES SUMMARY
 * ---------------------------
 * 
 * Internal (Supabase):
 *   - emeni_orders: Live orders iz eMeni sistema
 *   - wolt_orders: Historical Wolt orders (2025)
 *   - emeni_order_lifecycle: Order lifecycle events
 *   - pazar_*: Pazar module tables
 *   - pazar_users: Staff users
 *   - table_discounts: Table discounts
 * 
 * External (REST API):
 *   - Magacin API: Warehouse management
 * 
 * Edge Functions:
 *   - pin-auth: PIN authentication
 * 
 * NAPOMENA: Data sources su mešavina Supabase tables i external REST APIs.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
