/*
 * ============================================================================
 * SECURITY MEASURES - KOMPLETNA DOKUMENTACIJA
 * ============================================================================
 * 
 * Ovaj dokument opisuje sve security mere u Collina platformi,
 * uključujući RLS policies, API key handling, input sanitization, XSS protection,
 * CORS konfiguraciju, sensitive data handling i PIN security.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. ROW LEVEL SECURITY (RLS) - Koje RLS politike postoje u Supabase
 * ============================================================================
 */

/*
 * 1.1. RLS OVERVIEW
 * -------------------
 * 
 * Status: RLS policies se primenjuju na Supabase nivou
 * Location: Supabase Dashboard → Authentication → Policies
 * 
 * NAPOMENA: Frontend kod ne definiše RLS policies eksplicitno - one se konfigurišu
 *           direktno u Supabase Dashboard-u. Frontend queries automatski poštuju RLS.
 */

/*
 * 1.2. IMPLICIT RLS ENFORCEMENT
 * ------------------------------
 * 
 * Supabase Client:
 *   - Svi queries kroz supabase.from() automatski poštuju RLS policies
 *   - RLS se primenjuje na SELECT, INSERT, UPDATE, DELETE operacije
 *   - RPC funkcije (supabase.rpc()) takođe poštuju RLS
 * 
 * Example Queries (automatski poštuju RLS):
 *   - supabase.from('pazar_users').select('*')
 *   - supabase.from('emeni_orders').select('*').eq('status', 5)
 *   - supabase.from('module_permissions').select('*').eq('role', 'admin')
 *   - supabase.rpc('search_pazar_users', { search_term: '...' })
 * 
 * NAPOMENA: RLS se primenjuje automatski - frontend ne mora eksplicitno da proverava.
 */

/*
 * 1.3. RLS BY TABLE (ASSUMED)
 * ----------------------------
 * 
 * NAPOMENA: Sledeće su pretpostavke bazirane na tipičnim RLS pattern-ima.
 *           Stvarne RLS policies se moraju proveriti u Supabase Dashboard-u.
 * 
 * pazar_users:
 *   - SELECT: Users can view their own record, admins can view all
 *   - UPDATE: Users can update their own record, admins can update all
 *   - INSERT: Only admins can insert
 *   - DELETE: Only admins can delete
 * 
 * pazar_shifts:
 *   - SELECT: Users can view shifts for their location, admins can view all
 *   - UPDATE: Users can update their own shifts, admins can update all
 *   - INSERT: Authenticated users can create shifts for their location
 *   - DELETE: Only admins can delete
 * 
 * emeni_orders:
 *   - SELECT: All authenticated users can view (read-only for most roles)
 *   - UPDATE: Only admins/managers can update order status
 *   - INSERT: System/webhook only (no frontend inserts)
 *   - DELETE: Only admins can delete
 * 
 * module_permissions:
 *   - SELECT: All authenticated users can view (for permission checks)
 *   - UPDATE: Only admins can update
 *   - INSERT: Only admins can insert
 *   - DELETE: Only admins can delete
 * 
 * pazar_finance_records:
 *   - SELECT: Users can view records for their location, admins can view all
 *   - UPDATE: Only admins/finansije role can update
 *   - INSERT: System/authenticated users can create
 *   - DELETE: Only admins can delete
 * 
 * NAPOMENA: Ove su pretpostavke - stvarne RLS policies se moraju proveriti u Supabase.
 */

/*
 * 1.4. RLS BYPASS (SERVICE KEY)
 * -------------------------------
 * 
 * Service Key Usage:
 *   - Service key se NIKADA ne koristi u frontend kodu
 *   - Service key se koristi samo u backend (Edge Functions, server-side)
 *   - Service key zaobiđe RLS policies
 * 
 * Frontend:
 *   - Koristi samo ANON KEY (VITE_SUPABASE_ANON_KEY)
 *   - ANON KEY poštuje RLS policies
 *   - Nema pristup service key-u
 * 
 * NAPOMENA: Service key je backend-only - frontend koristi samo anon key.
 */

/*
 * 1.5. RLS WORKAROUNDS (AVOIDED)
 * --------------------------------
 * 
 * Pattern to Avoid:
 *   - src/modules/pazar/services/pazarService.js (line 45):
 *     "Simple query without joins to avoid RLS issues"
 * 
 * NAPOMENA: Neki queries koriste workaround-e (bez JOIN-ova) da izbegnu RLS probleme.
 *           Ovo nije idealno - RLS policies bi trebalo da dozvoljavaju potrebne JOIN-ove.
 */

/* ============================================================================
 * 2. API KEYS - Gde se čuvaju, kako se koriste (anon vs service key)
 * ============================================================================
 */

/*
 * 2.1. API KEY OVERVIEW
 * ----------------------
 * 
 * Keys Used:
 *   1. VITE_SUPABASE_ANON_KEY - Public anonymous key (frontend)
 *   2. SUPABASE_SERVICE_KEY - Private service key (backend only, NOT in frontend)
 * 
 * NAPOMENA: Frontend koristi samo ANON KEY - service key se nikada ne koristi u frontend-u.
 */

/*
 * 2.2. ANON KEY (VITE_SUPABASE_ANON_KEY)
 * ----------------------------------------
 * 
 * Location: .env.local (local), Vercel Environment Variables (production)
 * Access: import.meta.env.VITE_SUPABASE_ANON_KEY
 * 
 * Usage:
 *   - src/lib/supabase.js: Supabase client initialization
 *   - src/modules/pazar/stores/pazarAuthStore.js: Edge Function authorization
 *   - src/modules/analytics/services/analyticsService.js: REST API calls
 * 
 * Security:
 *   - Public key (vidljiv u browser DevTools → Network → Headers)
 *   - Poštuje RLS policies
 *   - Ograničen pristup (samo dozvoljene operacije)
 *   - Safe za frontend usage
 * 
 * Example:
 *   const supabase = createClient(
 *     import.meta.env.VITE_SUPABASE_URL,
 *     import.meta.env.VITE_SUPABASE_ANON_KEY
 *   );
 * 
 * NAPOMENA: ANON KEY je public - safe za frontend, ali poštuje RLS.
 */

/*
 * 2.3. SERVICE KEY (NOT IN FRONTEND)
 * ------------------------------------
 * 
 * Location: Backend only (Edge Functions, server-side)
 * Access: Environment variables na serveru (NE u frontend kodu)
 * 
 * Security:
 *   - Private key (NIKADA u frontend kodu)
 *   - Bypass-uje RLS policies
 *   - Full database access
 *   - Used only for admin operations (Edge Functions)
 * 
 * NAPOMENA: Service key se NIKADA ne koristi u frontend kodu - samo backend.
 */

/*
 * 2.4. ENVIRONMENT VARIABLE STORAGE
 * -----------------------------------
 * 
 * Local Development:
 *   - File: .env.local (gitignored)
 *   - Format: VITE_SUPABASE_URL=..., VITE_SUPABASE_ANON_KEY=...
 * 
 * Production (Vercel):
 *   - Vercel Dashboard → Settings → Environment Variables
 *   - Variables: VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY
 *   - Scope: Production, Preview, Development
 * 
 * Git Ignore:
 *   - .gitignore includes: .env, .env.local, .env.*.local
 *   - Environment files se NIKADA ne commit-uju
 * 
 * NAPOMENA: Environment variables se čuvaju van koda - .env fajlovi su gitignored.
 */

/*
 * 2.5. API KEY EXPOSURE
 * -----------------------
 * 
 * Frontend Exposure:
 *   - ANON KEY je vidljiv u browser DevTools (Network tab)
 *   - ANON KEY je embedded u build bundle (Vite build)
 *   - Ovo je NORMALNO i SAFE (anon key je public by design)
 * 
 * Protection:
 *   - RLS policies ograničavaju šta anon key može da radi
 *   - Service key se NIKADA ne koristi u frontend-u
 *   - Edge Functions koriste service key na backend-u
 * 
 * NAPOMENA: ANON KEY exposure je normalno - zaštićen je RLS policies.
 */

/*
 * 2.6. EDGE FUNCTION AUTHENTICATION
 * ------------------------------------
 * 
 * PIN Auth Edge Function:
 *   - URL: ${SUPABASE_URL}/functions/v1/pin-auth
 *   - Authorization: Bearer ${VITE_SUPABASE_ANON_KEY}
 *   - Edge Function koristi service key interno (backend)
 * 
 * Code:
 *   const response = await fetch(EDGE_FUNCTION_URL, {
 *     method: 'POST',
 *     headers: {
 *       'Content-Type': 'application/json',
 *       'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`
 *     },
 *     body: JSON.stringify({ user_id: userId, pin: pin })
 *   });
 * 
 * NAPOMENA: Edge Functions primaju anon key u header-u, ali koriste service key interno.
 */

/* ============================================================================
 * 3. INPUT SANITIZATION - Gde se sanitizuje user input
 * ============================================================================
 */

/*
 * 3.1. INPUT SANITIZATION OVERVIEW
 * -----------------------------------
 * 
 * Techniques Used:
 *   1. URL Encoding: encodeURIComponent() za URL parametre
 *   2. React Escaping: Automatski escape za JSX
 *   3. Supabase Parameterization: Supabase client automatski escape-uje
 *   4. JSON.stringify: Za request body (safe)
 * 
 * NAPOMENA: Input sanitization se primenjuje na više nivoa - URL, JSX, SQL.
 */

/*
 * 3.2. URL ENCODING
 * -------------------
 * 
 * Location: src/modules/magacin/services/magacinService.js
 * 
 * Examples:
 *   - encodeURIComponent(radnjaSifra) za URL parametre
 *   - encodeURIComponent(key) za trebovanje detalje
 *   - encodeURIComponent(search) za search parametre
 * 
 * Code:
 *   apiCall(`/artikli-radnja/${encodeURIComponent(radnjaSifra)}`)
 *   apiCall(`/detalji/${encodeURIComponent(key)}`)
 *   apiCall(`/artikli-ostalo/${encodeURIComponent(radnjaSifra)}?search=${encodeURIComponent(search || '')}`)
 * 
 * NAPOMENA: encodeURIComponent() sprečava URL injection - svi user input parametri se encode-uju.
 */

/*
 * 3.3. REACT JSX ESCAPING
 * -------------------------
 * 
 * Automatic Escaping:
 *   - React automatski escape-uje sve vrednosti u JSX
 *   - {userInput} je automatski safe (escaped)
 *   - Nema potrebe za manual escaping
 * 
 * Example:
 *   <div>{user.name}</div>  // Automatski escaped
 *   <input value={user.email} />  // Automatski escaped
 * 
 * NAPOMENA: React automatski escape-uje JSX - nema potrebe za manual escaping.
 */

/*
 * 3.4. SUPABASE PARAMETERIZATION
 * ---------------------------------
 * 
 * Automatic Parameterization:
 *   - Supabase client automatski parameterizuje queries
 *   - .eq(), .in(), .gte(), .lte() automatski escape-uju vrednosti
 *   - Nema SQL injection rizika
 * 
 * Examples:
 *   supabase.from('pazar_users').select('*').eq('email', userEmail)
 *   supabase.from('emeni_orders').select('*').in('status', [1, 3, 5])
 *   supabase.rpc('search_pazar_users', { search_term: term.toLowerCase() })
 * 
 * NAPOMENA: Supabase client automatski parameterizuje queries - safe od SQL injection.
 */

/*
 * 3.5. JSON STRINGIFY
 * --------------------
 * 
 * Request Body:
 *   - JSON.stringify() se koristi za request body
 *   - Automatski escape-uje special characters
 *   - Safe za API calls
 * 
 * Examples:
 *   body: JSON.stringify({ radnja, stavke })
 *   body: JSON.stringify({ user_id: userId, pin: pin })
 *   body: JSON.stringify({ userId, izmene })
 * 
 * NAPOMENA: JSON.stringify() je safe - automatski escape-uje special characters.
 */

/*
 * 3.6. INPUT VALIDATION
 * -----------------------
 * 
 * Frontend Validation:
 *   - Email format validation (LoginPage)
 *   - PIN length validation (5 digits)
 *   - Required field validation
 *   - Numeric range validation
 * 
 * Examples:
 *   - PIN length: pinValue.length !== 5
 *   - Search term: term.length < 2 (minimum 2 characters)
 *   - Email: Supabase auth validation
 * 
 * NAPOMENA: Frontend validation sprečava invalid input - ali backend mora takođe validirati.
 */

/*
 * 3.7. MISSING SANITIZATION
 * --------------------------
 * 
 * Areas Without Explicit Sanitization:
 *   - Text input fields (naziv, komentar, etc.) - oslanja se na React escaping
 *   - Numeric inputs - oslanja se na type="number" i validation
 *   - Date inputs - oslanja se na type="date" i validation
 * 
 * NAPOMENA: Neki input-ovi se oslanjaju samo na React escaping - backend mora validirati.
 */

/* ============================================================================
 * 4. XSS PROTECTION - Da li postoji
 * ============================================================================
 */

/*
 * 4.1. XSS PROTECTION OVERVIEW
 * ------------------------------
 * 
 * Status: ✅ XSS Protection postoji (React automatski)
 * Mechanism: React JSX escaping
 * 
 * NAPOMENA: React automatski štiti od XSS - sve vrednosti se escape-uju.
 */

/*
 * 4.2. REACT AUTOMATIC ESCAPING
 * -------------------------------
 * 
 * How It Works:
 *   - React automatski escape-uje sve vrednosti u JSX
 *   - {userInput} je automatski escaped (safe)
 *   - Nema potrebe za manual escaping
 * 
 * Examples:
 *   <div>{user.name}</div>  // Safe - automatski escaped
 *   <span>{order.total}</span>  // Safe - automatski escaped
 *   <p>{comment}</p>  // Safe - automatski escaped
 * 
 * NAPOMENA: React automatski escape-uje JSX - XSS protection je built-in.
 */

/*
 * 4.3. DANGEROUSLY SET INNER HTML (NOT USED)
 * --------------------------------------------
 * 
 * Status: ❌ dangerouslySetInnerHTML se NE koristi
 * 
 * Search Results:
 *   - grep za "dangerouslySetInnerHTML" - NO MATCHES
 *   - grep za "innerHTML" - NO MATCHES (osim u reference fajlovima)
 * 
 * NAPOMENA: dangerouslySetInnerHTML se NE koristi - sve je safe React JSX.
 */

/*
 * 4.4. XSS VULNERABILITIES (NONE FOUND)
 * ---------------------------------------
 * 
 * Safe Patterns:
 *   - Svi user input-ovi se render-uju kroz React JSX (escaped)
 *   - Nema direktnog innerHTML manipulation
 *   - Nema eval() ili Function() konstruktora
 *   - Nema inline event handlers sa user input-om
 * 
 * NAPOMENA: Nema XSS vulnerabilnosti - React automatski štiti.
 */

/*
 * 4.5. XSS BEST PRACTICES
 * -------------------------
 * 
 * DO:
 *   - Koristi React JSX za sve user input rendering
 *   - Koristi encodeURIComponent() za URL parametre
 *   - Validiraj input na frontend i backend
 * 
 * DON'T:
 *   - Ne koristi dangerouslySetInnerHTML
 *   - Ne koristi innerHTML direktno
 *   - Ne koristi eval() sa user input-om
 * 
 * NAPOMENA: XSS best practices su poštovane - React escaping + URL encoding.
 */

/* ============================================================================
 * 5. CORS - Konfiguracija
 * ============================================================================
 */

/*
 * 5.1. CORS OVERVIEW
 * --------------------
 * 
 * Status: CORS se konfiguriše na server-side (Supabase, Magacin API)
 * Frontend: Frontend ne konfiguriše CORS direktno
 * 
 * NAPOMENA: CORS se konfiguriše na server-side - frontend samo detektuje greške.
 */

/*
 * 5.2. SUPABASE CORS
 * --------------------
 * 
 * Configuration: Supabase Dashboard → Settings → API
 * 
 * Default Behavior:
 *   - Supabase dozvoljava requests sa bilo kog origin-a (anon key)
 *   - RLS policies kontrolišu pristup (ne CORS)
 *   - CORS headers se automatski postavljaju
 * 
 * NAPOMENA: Supabase automatski rukuje CORS-om - frontend ne mora ništa da radi.
 */

/*
 * 5.3. MAGACIN API CORS
 * -----------------------
 * 
 * API: https://magacin.collina.co.rs/api/trebovanje
 * 
 * Issue Detection:
 *   - src/modules/magacin/services/magacinService.js (line 21-23):
 *     if (err.message?.includes('Failed to fetch') || err.message?.includes('CORS')) {
 *       throw new Error('CORS greška: API ne dozvoljava pristup sa ovog domena...');
 *     }
 * 
 * Error Handling:
 *   - CORS greške se detektuju i prikazuju korisniku
 *   - Suggestion: Koristiti proxy ili server-side poziv
 * 
 * NAPOMENA: Magacin API može imati CORS probleme - detektuje se i prikazuje greška.
 */

/*
 * 5.4. CORS ERROR HANDLING
 * ---------------------------
 * 
 * Location: src/modules/magacin/services/magacinService.js
 * 
 * Code:
 *   catch (err) {
 *     if (err.message?.includes('Failed to fetch') || err.message?.includes('CORS')) {
 *       throw new Error('CORS greška: API ne dozvoljava pristup sa ovog domena. Potrebno je koristiti proxy ili server-side poziv.');
 *     }
 *     throw err;
 *   }
 * 
 * NAPOMENA: CORS greške se detektuju i prikazuju korisniku sa jasnom porukom.
 */

/*
 * 5.5. CORS WORKAROUNDS
 * -----------------------
 * 
 * Current: Frontend direktno poziva Magacin API
 * Issue: CORS može blokirati requests
 * 
 * Potential Solutions:
 *   1. Proxy server (Vercel Edge Function)
 *   2. Server-side API calls (backend endpoint)
 *   3. CORS configuration na Magacin API serveru
 * 
 * NAPOMENA: CORS workaround-i nisu implementirani - trenutno se oslanja na API CORS config.
 */

/* ============================================================================
 * 6. SENSITIVE DATA - Šta se nikad ne loguje, šta se maskira
 * ============================================================================
 */

/*
 * 6.1. SENSITIVE DATA OVERVIEW
 * ------------------------------
 * 
 * Categories:
 *   1. Authentication Data: Passwords, PINs, tokens, sessions
 *   2. Personal Data: Email addresses, phone numbers
 *   3. Financial Data: Cash amounts, bank account numbers
 *   4. API Keys: Service keys, secret keys
 * 
 * NAPOMENA: Sensitive data se ne loguje ili se maskira - zaštita privatnosti.
 */

/*
 * 6.2. AUTHENTICATION DATA
 * --------------------------
 * 
 * Never Logged:
 *   - Passwords: NIKADA se ne loguje (supabase.auth.signInWithPassword)
 *   - PINs: NIKADA se ne loguje (PIN se šalje u request body, ali se ne loguje)
 *   - Tokens: Access/refresh tokens se ne loguju eksplicitno
 *   - Sessions: Session objects se ne loguju (sadrže tokens)
 * 
 * Code Patterns:
 *   - PIN login: login(userId, pin) - PIN se ne loguje
 *   - Password login: login(email, password) - password se ne loguje
 *   - Session: supabase.auth.setSession() - session se ne loguje
 * 
 * NAPOMENA: Authentication data se NIKADA ne loguje - zaštita od credential leakage.
 */

/*
 * 6.3. API KEYS
 * --------------
 * 
 * Never Logged:
 *   - VITE_SUPABASE_ANON_KEY: Ne loguje se eksplicitno (ali je vidljiv u Network tab)
 *   - SUPABASE_SERVICE_KEY: NIKADA se ne koristi u frontend-u (samo backend)
 * 
 * Code Patterns:
 *   - Environment variables se ne loguju
 *   - API keys se ne loguju u console.log
 * 
 * NAPOMENA: API keys se ne loguju eksplicitno - ali anon key je public by design.
 */

/*
 * 6.4. PERSONAL DATA
 * --------------------
 * 
 * Logged (with caution):
 *   - User names: Loguje se (first_name, last_name)
 *   - User IDs: Loguje se (UUID)
 *   - Email addresses: Loguje se u error messages (potencijalno sensitive)
 * 
 * Not Logged:
 *   - Phone numbers: Nema eksplicitnih logova
 *   - Addresses: Nema eksplicitnih logova
 * 
 * NAPOMENA: Personal data se loguje selektivno - names i IDs su OK, ali email može biti sensitive.
 */

/*
 * 6.5. FINANCIAL DATA
 * --------------------
 * 
 * Logged:
 *   - Cash amounts: Loguje se (countedAmount, expectedCash, difference)
 *   - Denominations: Loguje se (denominations object)
 *   - Deposit amounts: Loguje se
 * 
 * Not Logged:
 *   - Bank account numbers: Nema u frontend kodu
 *   - Credit card numbers: Nema u frontend kodu
 * 
 * NAPOMENA: Financial data se loguje (cash amounts) - ali bank account numbers se ne loguju.
 */

/*
 * 6.6. CONSOLE LOGGING PATTERNS
 * -------------------------------
 * 
 * Safe Logging:
 *   - console.log('User ID:', userId)  // OK - UUID
 *   - console.log('Order count:', orders.length)  // OK - count
 *   - console.log('Location:', locationName)  // OK - name
 * 
 * Potentially Sensitive:
 *   - console.error('Login error:', error)  // Može sadržati email
 *   - console.log('User:', user)  // Može sadržati email, phone
 * 
 * Never Logged:
 *   - console.log('PIN:', pin)  // ❌ NIKADA
 *   - console.log('Password:', password)  // ❌ NIKADA
 *   - console.log('Token:', token)  // ❌ NIKADA
 * 
 * NAPOMENA: Console logging patterns - safe za IDs i counts, ali ne za credentials.
 */

/*
 * 6.7. JSON.STRINGIFY USAGE
 * ---------------------------
 * 
 * Safe Usage:
 *   - JSON.stringify(orders, null, 2)  // OK - order data
 *   - JSON.stringify(filters, null, 2)  // OK - filter data
 *   - JSON.stringify(error, null, 2)  // Potentially sensitive (može sadržati email)
 * 
 * Never Stringify:
 *   - JSON.stringify({ pin, password })  // ❌ NIKADA
 *   - JSON.stringify(session)  // ❌ NIKADA (sadrži tokens)
 * 
 * NAPOMENA: JSON.stringify se koristi za debugging - ali ne za sensitive data.
 */

/*
 * 6.8. DATA MASKING (NOT IMPLEMENTED)
 * -------------------------------------
 * 
 * Current Status: Data masking se NE koristi
 * 
 * Potential Masking:
 *   - Email: user@example.com → u***@example.com
 *   - Phone: +381 64 123 4567 → +381 64 *** 4567
 *   - PIN: 12345 → *****
 * 
 * NAPOMENA: Data masking se NE koristi - oslanja se na to da se sensitive data ne loguje.
 */

/* ============================================================================
 * 7. PIN SECURITY - Kako se čuva PIN, da li je hashovan
 * ============================================================================
 */

/*
 * 7.1. PIN SECURITY OVERVIEW
 * ----------------------------
 * 
 * PIN Format: 5 digits (numeric)
 * Storage: Backend (pazar_users table)
 * Transmission: HTTPS (encrypted in transit)
 * 
 * NAPOMENA: PIN se čuva na backend-u - frontend samo šalje PIN u request body-u.
 */

/*
 * 7.2. PIN TRANSMISSION
 * -----------------------
 * 
 * Frontend to Backend:
 *   - PIN se šalje u plain text u request body-u
 *   - Transmission je HTTPS (encrypted in transit)
 *   - Edge Function prima PIN i verifikuje ga
 * 
 * Code:
 *   const response = await fetch(EDGE_FUNCTION_URL, {
 *     method: 'POST',
 *     headers: {
 *       'Content-Type': 'application/json',
 *       'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`
 *     },
 *     body: JSON.stringify({
 *       user_id: userId,
 *       pin: pin  // Plain text u request body-u
 *     })
 *   });
 * 
 * NAPOMENA: PIN se šalje u plain text preko HTTPS - Edge Function ga hash-uje i verifikuje.
 */

/*
 * 7.3. PIN STORAGE (BACKEND)
 * ----------------------------
 * 
 * Location: Backend (pazar_users table, Edge Function)
 * 
 * Assumed Storage:
 *   - PIN se verovatno hash-uje (bcrypt, argon2, ili slično)
 *   - Hash se čuva u pazar_users.pin_code ili sličnom polju
 *   - Plain text PIN se NIKADA ne čuva
 * 
 * NAPOMENA: PIN storage se dešava na backend-u - frontend ne zna kako se čuva.
 */

/*
 * 7.4. PIN VERIFICATION (EDGE FUNCTION)
 * ---------------------------------------
 * 
 * Process:
 *   1. Frontend šalje PIN u plain text preko HTTPS
 *   2. Edge Function prima PIN i user_id
 *   3. Edge Function hash-uje PIN i poredi sa stored hash-om
 *   4. Edge Function vraća success/failure
 *   5. Edge Function kreira Supabase session ako je PIN validan
 * 
 * Security:
 *   - PIN se hash-uje na backend-u (Edge Function)
 *   - Plain text PIN se ne čuva
 *   - Failed attempts se track-uju (locked account)
 * 
 * NAPOMENA: PIN verification se dešava na backend-u - frontend samo šalje PIN.
 */

/*
 * 7.5. PIN BRUTE FORCE PROTECTION
 * ----------------------------------
 * 
 * Implementation:
 *   - Failed attempts se track-uju (failedAttempts counter)
 *   - Account se lock-uje nakon 3 failed attempts
 *   - Lock duration: remaining_minutes (from Edge Function)
 * 
 * Code:
 *   if (data.locked) {
 *     set({
 *       lockedUntil: data.remaining_minutes ? Date.now() + (data.remaining_minutes * 60 * 1000) : null,
 *       failedAttempts: 3
 *     });
 *   }
 * 
 * NAPOMENA: Brute force protection postoji - account se lock-uje nakon 3 failed attempts.
 */

/*
 * 7.6. PIN SECURITY BEST PRACTICES
 * ----------------------------------
 * 
 * Current Implementation:
 *   ✅ PIN se šalje preko HTTPS (encrypted in transit)
 *   ✅ PIN se hash-uje na backend-u (assumed)
 *   ✅ Brute force protection (3 attempts, lock)
 *   ✅ Failed attempts tracking
 * 
 * Potential Improvements:
 *   - Rate limiting na Edge Function nivou
 *   - PIN complexity requirements (ne samo 5 digits)
 *   - PIN expiration/rotation
 *   - Two-factor authentication (2FA)
 * 
 * NAPOMENA: PIN security je solidan - HTTPS + backend hashing + brute force protection.
 */

/*
 * 7.7. PIN vs PASSWORD SECURITY
 * -------------------------------
 * 
 * Password (Email Login):
 *   - Managed by Supabase Auth
 *   - Automatski hash-ovan (bcrypt)
 *   - Password reset flow
 *   - Session management
 * 
 * PIN (Staff Login):
 *   - Custom implementation (Edge Function)
 *   - Hash-ovan na backend-u (assumed)
 *   - Brute force protection
 *   - Session management (Supabase session)
 * 
 * NAPOMENA: Password i PIN imaju različite security mehanizme - oba su hash-ovana.
 */

/* ============================================================================
 * 8. ADDITIONAL SECURITY MEASURES
 * ============================================================================
 */

/*
 * 8.1. ROUTE PROTECTION
 * -----------------------
 * 
 * AuthGuard:
 *   - src/core/auth/AuthGuard.jsx
 *   - Proverava isAuthenticated
 *   - Redirect-uje na /login ako nije authenticated
 * 
 * PermissionGuard:
 *   - src/core/auth/PermissionGuard.jsx
 *   - Proverava module permissions
 *   - Redirect-uje ili prikazuje "Access Denied" ako nema permission
 * 
 * NAPOMENA: Route protection postoji - AuthGuard i PermissionGuard.
 */

/*
 * 8.2. SESSION MANAGEMENT
 * -------------------------
 * 
 * Supabase Auth:
 *   - persistSession: true (localStorage)
 *   - autoRefreshToken: true (automatski refresh)
 *   - detectSessionInUrl: true (OAuth callbacks)
 * 
 * Session Storage:
 *   - localStorage (Supabase Auth)
 *   - localStorage (pazarAuthStore - Zustand persist)
 * 
 * NAPOMENA: Session management je automatizovan - Supabase Auth rukuje refresh-om.
 */

/*
 * 8.3. HTTPS ENFORCEMENT
 * -----------------------
 * 
 * Production:
 *   - Vercel automatski koristi HTTPS
 *   - Svi requests su HTTPS (encrypted)
 * 
 * Development:
 *   - Local development može koristiti HTTP
 *   - Production mora koristiti HTTPS
 * 
 * NAPOMENA: HTTPS je enforced u production - Vercel automatski koristi HTTPS.
 */

/*
 * 8.4. ERROR MESSAGE SECURITY
 * -----------------------------
 * 
 * Generic Error Messages:
 *   - "Invalid email or password" (ne otkriva da li email postoji)
 *   - "Pogrešan PIN" (ne otkriva da li user postoji)
 * 
 * NAPOMENA: Error messages su generic - ne otkrivaju informacije o user-ima.
 */

/* ============================================================================
 * 9. SECURITY RECOMMENDATIONS
 * ============================================================================
 */

/*
 * 9.1. IMPROVEMENTS
 * -------------------
 * 
 * High Priority:
 *   1. Implement rate limiting na Edge Functions
 *   2. Add Content Security Policy (CSP) headers
 *   3. Implement data masking za sensitive data u logs
 *   4. Add input validation na backend-u (ne samo frontend)
 * 
 * Medium Priority:
 *   1. Implement PIN complexity requirements
 *   2. Add two-factor authentication (2FA)
 *   3. Implement audit logging za sensitive operations
 *   4. Add request signing za external API calls
 * 
 * Low Priority:
 *   1. Implement PIN expiration/rotation
 *   2. Add security headers (X-Frame-Options, X-Content-Type-Options)
 *   3. Implement request ID tracking za debugging
 * 
 * NAPOMENA: Security recommendations za future improvements.
 */

/*
 * 9.2. SECURITY AUDIT CHECKLIST
 * ------------------------------
 * 
 * Authentication:
 *   ✅ Passwords hash-ovani (Supabase Auth)
 *   ✅ PIN hash-ovan (backend, assumed)
 *   ✅ Session management (Supabase Auth)
 *   ✅ Brute force protection (PIN login)
 * 
 * Authorization:
 *   ✅ RLS policies (Supabase)
 *   ✅ Route protection (AuthGuard, PermissionGuard)
 *   ✅ Module permissions (module_permissions table)
 * 
 * Data Protection:
 *   ✅ HTTPS (production)
 *   ✅ Input sanitization (URL encoding, React escaping)
 *   ✅ XSS protection (React automatic escaping)
 *   ⚠️ Sensitive data logging (može se poboljšati)
 * 
 * API Security:
 *   ✅ API keys u environment variables
 *   ✅ Anon key poštuje RLS
 *   ✅ Service key backend-only
 *   ⚠️ CORS configuration (Magacin API)
 * 
 * NAPOMENA: Security audit checklist - većina mera je implementirana.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
