/*
 * ============================================================================
 * AUTHENTICATION SISTEM - KOMPLETNA BIZNIS LOGIKA
 * ============================================================================
 * 
 * Ovaj dokument opisuje kompletnu biznis logiku AUTHENTICATION sistema u
 * Collina platformi, uključujući dva login puta, auth flow, session management,
 * permission sisteme, route protection, role-based access i logout.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. DVA LOGIN PUTA - Email+Password vs Name+PIN
 * ============================================================================
 */

/*
 * 1.1. EMAIL + PASSWORD LOGIN (Admin Shell)
 * -------------------------------------------
 * 
 * Komponenta: LoginPage.jsx (src/core/auth/LoginPage.jsx)
 * Route: /login
 * Target: Admin Shell (/admin/*)
 * 
 * Flow:
 * 1. User unosi email i password
 * 2. Poziva AuthContext.login(email, password)
 * 3. AuthContext poziva supabase.auth.signInWithPassword({ email, password })
 * 4. Supabase Auth proverava kredencijale
 * 5. Ako uspešno:
 *    - Supabase vraća session sa access_token i refresh_token
 *    - Session se čuva u localStorage (automatski od Supabase)
 *    - AuthContext učitava employee data iz pazar_users
 *    - Redirect na /admin/analytics
 * 6. Ako neuspešno:
 *    - Prikazuje error poruku
 *    - User ostaje na login stranici
 * 
 * Validacija:
 * - Email: mora biti validan email format
 * - Password: mora biti unet (nema minimum length zahtev)
 * 
 * Supabase Auth:
 * - Koristi Supabase Auth service
 * - Email mora biti registrovan u Supabase Auth users
 * - Password se hash-uje i čuva u Supabase Auth
 * 
 * NAPOMENA: Email login je za admin korisnike koji imaju Supabase Auth account.
 */

/*
 * 1.2. NAME + PIN LOGIN (Staff App)
 * -----------------------------------
 * 
 * Komponenta: PinLoginPage.jsx (src/modules/pazar/pages/PinLoginPage.jsx)
 * Route: /pazar/login ili /staff/login
 * Target: Staff App (/staff/*)
 * 
 * Flow:
 * 1. User pretražuje korisnike po imenu (min 2 karaktera)
 * 2. Poziva pazarAuthStore.searchUsers(term)
 * 3. Supabase RPC: search_pazar_users(search_term)
 * 4. Prikazuje listu rezultata
 * 5. User bira korisnika
 * 6. User unosi 5-cifreni PIN kod
 * 7. Auto-submit na 5. cifri
 * 8. Poziva pazarAuthStore.login(userId, pin)
 * 9. Edge Function: POST /functions/v1/pin-auth
 *    Body: { user_id, pin }
 * 10. Edge Function proverava:
 *     - Da li user postoji u pazar_users
 *     - Da li PIN odgovara (pazar_users.pin_code)
 *     - Da li je account zaključan (failed_attempts >= 3)
 * 11. Ako uspešno:
 *     - Edge Function vraća { success: true, user, session }
 *     - Session se postavlja: supabase.auth.setSession(session)
 *     - pazarAuthStore čuva user i session u Zustand store
 *     - Redirect na /staff/waiter ili /staff/pickup (zavisi od role)
 * 12. Ako neuspešno:
 *     - failedAttempts++
 *     - Ako failedAttempts >= 3: account se zaključava
 *     - Prikazuje error poruku
 *     - PIN se resetuje
 * 
 * PIN Format:
 * - 5 cifara (npr. "12345")
 * - Numpad input (0-9)
 * - Auto-submit na 5. cifri
 * 
 * Account Lock:
 * - Ako 3 neuspešna pokušaja: account se zaključava
 * - lockedUntil = now() + 15 minuta (ili custom vreme)
 * - User ne može da se prijavi dok se ne otključa
 * 
 * NAPOMENA: PIN login je za staff korisnike (konobar, vozač, itd.) koji
 *           nemaju Supabase Auth account, već samo PIN kod u pazar_users.
 */

/*
 * 1.3. RAZLIKE IZMEĐU DVA LOGIN PUTA
 * ------------------------------------
 * 
 * Email+Password:
 * - Koristi Supabase Auth (standardni auth sistem)
 * - Session se čuva u localStorage (Supabase automatski)
 * - Employee data se učitava iz pazar_users po email ili auth_user_id
 * - Permissions se učitavaju iz module_permissions po role stringu
 * - Target: Admin Shell (/admin/*)
 * 
 * Name+PIN:
 * - Koristi Edge Function za PIN verifikaciju
 * - Session se kreira programski (Edge Function vraća session)
 * - User data se čuva u Zustand store (pazarAuthStore)
 * - Nema permissions check (staff app ima ograničen pristup)
 * - Target: Staff App (/staff/*)
 * 
 * Session Storage:
 * - Email+Password: Supabase Auth localStorage
 * - Name+PIN: Zustand store sa persist middleware (localStorage)
 */

/* ============================================================================
 * 2. AUTH FLOW - Kompletan flow od login forme do authenticated stanja
 * ============================================================================
 */

/*
 * 2.1. EMAIL+PASSWORD AUTH FLOW
 * ------------------------------
 * 
 * Step 1: User otvara /login
 *   - LoginPage.jsx se renderuje
 *   - AuthContext proverava postojeću sesiju (getSession)
 *   - Ako postoji sesija: redirect na /admin/analytics
 * 
 * Step 2: User unosi email i password
 *   - Form submit → handleSubmit()
 *   - Poziva AuthContext.login(email, password)
 * 
 * Step 3: Supabase Auth proverava kredencijale
 *   - supabase.auth.signInWithPassword({ email, password })
 *   - Supabase proverava email/password u auth.users tabeli
 *   - Ako validno: vraća { user, session }
 *   - Ako invalidno: vraća error
 * 
 * Step 4: Session se čuva
 *   - Supabase automatski čuva session u localStorage
 *   - Session sadrži: access_token, refresh_token, expires_at
 * 
 * Step 5: AuthContext učitava employee data
 *   - fetchEmployeeData(session.user) se poziva
 *   - Query: SELECT * FROM pazar_users 
 *            WHERE email = user.email OR auth_user_id = user.id
 *   - Ako employee postoji:
 *     a) setEmployee(employeeData)
 *     b) Query: SELECT * FROM module_permissions WHERE role = employee.role
 *     c) setPermissions(permData)
 * 
 * Step 6: Redirect
 *   - navigate('/admin/analytics')
 *   - AuthGuard proverava isAuthenticated
 *   - ProtectedRoute proverava canView('analytics')
 *   - Ako sve OK: renderuje DashboardPage
 * 
 * Step 7: Auth State Change Listener
 *   - supabase.auth.onAuthStateChange() se aktivira
 *   - Ako session postoji: fetchEmployeeData()
 *   - Ako session ne postoji: clear employee i permissions
 */

/*
 * 2.2. NAME+PIN AUTH FLOW
 * ------------------------
 * 
 * Step 1: User otvara /pazar/login ili /staff/login
 *   - PinLoginPage.jsx se renderuje
 *   - pazarAuthStore proverava postojeću sesiju (isAuthenticated)
 *   - Ako postoji sesija: redirect na /staff/waiter ili /staff/pickup
 * 
 * Step 2: User pretražuje korisnike
 *   - Unosi ime (min 2 karaktera)
 *   - Poziva pazarAuthStore.searchUsers(term)
 *   - Supabase RPC: search_pazar_users(search_term)
 *   - Prikazuje rezultate
 * 
 * Step 3: User bira korisnika
 *   - Klikne na korisnika iz liste
 *   - Poziva pazarAuthStore.selectUser(user)
 *   - Prikazuje PIN input
 * 
 * Step 4: User unosi PIN
 *   - Numpad input (0-9)
 *   - Auto-submit na 5. cifri
 *   - Poziva pazarAuthStore.login(userId, pin)
 * 
 * Step 5: Edge Function verifikacija
 *   - POST /functions/v1/pin-auth
 *   - Body: { user_id, pin }
 *   - Edge Function:
 *     a) Query: SELECT * FROM pazar_users WHERE id = user_id
 *     b) Proverava: user.pin_code === pin
 *     c) Proverava: failed_attempts < 3 (ili locked_until < now())
 *     d) Ako validno:
 *        - Kreira Supabase session programski
 *        - Vraća { success: true, user, session }
 *     e) Ako invalidno:
 *        - failed_attempts++
 *        - Ako failed_attempts >= 3: locked_until = now() + 15min
 *        - Vraća { success: false, error, remaining_attempts }
 * 
 * Step 6: Session se postavlja
 *   - supabase.auth.setSession({ access_token, refresh_token })
 *   - pazarAuthStore čuva user i session u Zustand store
 *   - Zustand persist middleware čuva u localStorage
 * 
 * Step 7: Redirect
 *   - useEffect proverava isAuthenticated i user.role
 *   - Ako role === 'vozac': navigate('/staff/pickup')
 *   - Ako role === 'konobar': navigate('/staff/waiter')
 *   - Default: navigate('/staff/waiter')
 * 
 * Step 8: Staff App Layout
 *   - StaffLayout proverava isAuthenticated
 *   - Ako nije authenticated: redirect na /staff/login
 *   - Ako jeste: renderuje Staff App
 */

/*
 * 2.3. AUTH STATE INITIALIZATION
 * --------------------------------
 * 
 * Komponenta: AuthContext.jsx (AuthProvider)
 * 
 * Initialization Flow:
 * 1. Component mount:
 *    - setLoading(true)
 *    - Proverava da li je pathname /pazar/* ili /staff/*
 * 
 * 2. Get initial session:
 *    - supabase.auth.getSession()
 *    - Ako postoji session:
 *      a) setSession(session)
 *      b) setUser(session.user)
 *      c) Ako NIJE pazar/staff route: fetchEmployeeData(session.user)
 *    - Ako ne postoji: setLoading(false)
 * 
 * 3. Setup auth state change listener:
 *    - supabase.auth.onAuthStateChange((event, session) => { ... })
 *    - Event types: 'SIGNED_IN', 'SIGNED_OUT', 'TOKEN_REFRESHED', 'USER_UPDATED'
 *    - Na svaku promenu:
 *      a) setSession(session)
 *      b) setUser(session?.user ?? null)
 *      c) Ako session postoji i NIJE pazar/staff: fetchEmployeeData()
 *      d) Ako session ne postoji: clear employee i permissions
 * 
 * 4. Cleanup:
 *    - Unsubscribe od auth state change listener
 *    - mounted = false
 * 
 * NAPOMENA: AuthContext se ne aktivira na /pazar/* i /staff/* rutama jer
 *           te rute koriste pazarAuthStore umesto AuthContext.
 */

/* ============================================================================
 * 3. SESSION MANAGEMENT - Kako se čuva sesija, refresh tokeni
 * ============================================================================
 */

/*
 * 3.1. SUPABASE AUTH SESSION
 * ----------------------------
 * 
 * Storage: localStorage (Supabase automatski)
 * 
 * Session struktura:
 * {
 *   access_token: "eyJhbGc...",  // JWT token za API pozive
 *   refresh_token: "eyJhbGc...", // Token za refresh
 *   expires_at: 1234567890,      // Unix timestamp
 *   expires_in: 3600,            // Sekunde do isteka
 *   token_type: "bearer",
 *   user: {
 *     id: "uuid",
 *     email: "user@example.com",
 *     ...
 *   }
 * }
 * 
 * Access Token:
 * - JWT token koji se koristi za API pozive
 * - Sadrži user info i permissions
 * - Expires za 1 sat (default)
 * - Automatski se refresh-uje kada istekne
 * 
 * Refresh Token:
 * - Token za dobijanje novog access tokena
 * - Expires za 30 dana (default)
 * - Koristi se automatski od Supabase client-a
 * 
 * Auto-refresh:
 * - Supabase client automatski refresh-uje access token kada istekne
 * - Koristi refresh_token iz localStorage
 * - Transparentno za aplikaciju (nema potrebe za manual refresh)
 */

/*
 * 3.2. PAZAR AUTH STORE SESSION
 * -------------------------------
 * 
 * Storage: Zustand store sa persist middleware (localStorage)
 * 
 * Session struktura:
 * {
 *   user: {
 *     id: "uuid",
 *     first_name: "Marko",
 *     last_name: "Savić",
 *     role: "konobar",
 *     pin_code: "12345",
 *     ...
 *   },
 *   session: {
 *     access_token: "eyJhbGc...",
 *     refresh_token: "eyJhbGc...",
 *     ...
 *   },
 *   isAuthenticated: true
 * }
 * 
 * Persist Middleware:
 * - Čuva samo: user, session, isAuthenticated
 * - Ne čuva: searchResults, selectedUser, error, failedAttempts, lockedUntil
 * - Storage key: 'pazar-auth-storage'
 * 
 * Hydration:
 * - Pri mount-u, Zustand automatski učitava iz localStorage
 * - Ako postoji session: isAuthenticated = true
 * - Ako ne postoji: isAuthenticated = false
 * 
 * NAPOMENA: pazarAuthStore session je kreiran programski od Edge Function,
 *           ne od Supabase Auth direktno. Edge Function kreira Supabase
 *           session i vraća ga aplikaciji.
 */

/*
 * 3.3. SESSION VALIDATION
 * ------------------------
 * 
 * Email+Password (AuthContext):
 * - Supabase automatski validira access_token pri svakom API pozivu
 * - Ako token istekne: automatski refresh sa refresh_token
 * - Ako refresh_token istekne: user mora da se ponovo prijavi
 * 
 * Name+PIN (pazarAuthStore):
 * - Session se validira kroz supabase.auth.setSession()
 * - Supabase proverava da li je token validan
 * - Ako token istekne: može se refresh-ovati (ako refresh_token postoji)
 * - Ako refresh_token istekne: user mora da se ponovo prijavi
 * 
 * Session Expiry:
 * - Access token: 1 sat (3600 sekundi)
 * - Refresh token: 30 dana (2,592,000 sekundi)
 * - Auto-refresh: 5 minuta pre isteka access tokena
 */

/*
 * 3.4. SESSION PERSISTENCE
 * -------------------------
 * 
 * Email+Password:
 * - Supabase Auth čuva session u localStorage
 * - Key: `sb-<project-ref>-auth-token`
 * - Persistira kroz browser refresh
 * - Persistira kroz tab close/reopen
 * - NE persistira kroz browser clear data
 * 
 * Name+PIN:
 * - Zustand persist middleware čuva u localStorage
 * - Key: 'pazar-auth-storage'
 * - Persistira kroz browser refresh
 * - Persistira kroz tab close/reopen
 * - NE persistira kroz browser clear data
 * 
 * Session Recovery:
 * - Pri app start: getSession() ili pazarAuthStore hydration
 * - Ako session postoji i validan: user je authenticated
 * - Ako session ne postoji ili invalidan: user mora da se prijavi
 */

/* ============================================================================
 * 4. PERMISSION SYSTEM - Dva sistema (module_permissions vs role_module_permissions)
 * ============================================================================
 */

/*
 * 4.1. MODULE_PERMISSIONS TABELA
 * --------------------------------
 * 
 * Tabela: module_permissions
 * 
 * Struktura:
 * - role: TEXT (primary key) - 'admin', 'menadzer', 'konobar', 'vozac', itd.
 * - module: TEXT (primary key) - 'analytics', 'orders', 'pazar', 'magacin', itd.
 * - can_view: BOOLEAN
 * - can_edit: BOOLEAN
 * - can_delete: BOOLEAN
 * 
 * Upotreba:
 * - Koristi se u AuthContext.jsx za email+password login
 * - Query: SELECT * FROM module_permissions WHERE role = employee.role
 * - Permissions se učitavaju po role stringu direktno
 * 
 * Primer:
 *   role = 'admin'
 *   Query: SELECT * FROM module_permissions WHERE role = 'admin'
 *   Rezultat:
 *     { role: 'admin', module: 'analytics', can_view: true, can_edit: true, can_delete: true }
 *     { role: 'admin', module: 'orders', can_view: true, can_edit: true, can_delete: true }
 *     ...
 * 
 * Prednosti:
 * - Jednostavno: direktno mapiranje role → permissions
 * - Brzo: jedan query za sve permissions
 * - Lako za održavanje: jedna tabela
 * 
 * Mane:
 * - Nema fleksibilnosti: role je string, ne može se menjati
 * - Nema multi-role support: user može imati samo jednu rolu
 * - Nema location/brand filtering
 */

/*
 * 4.2. ROLE_MODULE_PERMISSIONS TABELA
 * -------------------------------------
 * 
 * Tabela: role_module_permissions
 * 
 * Struktura:
 * - role_id: UUID (FK → roles.id) - primary key
 * - module_id: TEXT - primary key
 * - can_view: BOOLEAN
 * - can_edit: BOOLEAN
 * - can_delete: BOOLEAN
 * 
 * Upotreba:
 * - Koristi se u PermissionGuard.jsx (ali trenutno nije aktivno korišćen)
 * - Query: SELECT * FROM role_module_permissions 
 *          WHERE role_id IN (user.role_ids) AND module_id = 'analytics'
 * - Permissions se učitavaju po role_id (UUID)
 * 
 * Primer:
 *   user.roles = [{ id: 'uuid-1', name: 'admin' }, { id: 'uuid-2', name: 'manager' }]
 *   Query: SELECT * FROM role_module_permissions 
 *          WHERE role_id IN ('uuid-1', 'uuid-2') AND module_id = 'analytics'
 *   Rezultat:
 *     { role_id: 'uuid-1', module_id: 'analytics', can_view: true, can_edit: true, can_delete: true }
 * 
 * Prednosti:
 * - Fleksibilno: role je UUID, može se menjati
 * - Multi-role support: user može imati više rola
 * - Normalizovano: role info u roles tabeli
 * 
 * Mane:
 * - Kompleksnije: zahteva JOIN sa roles tabelom
 * - Sporije: više query-ja ili JOIN-ova
 * - Nije implementirano u trenutnom kodu (PermissionGuard postoji ali se ne koristi)
 */

/*
 * 4.3. KOJI SISTEM SE KORISTI GDE
 * ---------------------------------
 * 
 * Email+Password Login (AuthContext):
 * - Koristi: module_permissions
 * - Query: SELECT * FROM module_permissions WHERE role = employee.role
 * - Rezultat: permissions array sa { module, can_view, can_edit, can_delete }
 * - Funkcije: canView(module), canEdit(module)
 * 
 * Name+PIN Login (pazarAuthStore):
 * - NEMA permissions check
 * - Staff app ima ograničen pristup (hardcoded u rutama)
 * - Role određuje redirect (vozac → /staff/pickup, konobar → /staff/waiter)
 * 
 * PermissionGuard (neaktivno):
 * - Koristi: role_module_permissions
 * - Query: SELECT * FROM role_module_permissions 
 *          WHERE role_id IN (user.role_ids) AND module_id = moduleId
 * - NAPOMENA: PermissionGuard postoji ali se NE koristi u trenutnom kodu.
 *             Umesto toga se koristi ProtectedRoute sa AuthContext.canView().
 * 
 * ProtectedRoute (aktivno):
 * - Koristi: AuthContext.canView() → module_permissions
 * - Proverava: canView(module) iz permissions array
 * - Ako nema permission: redirect na fallbackPath
 */

/*
 * 4.4. PERMISSION CHECK FUNKCIJE
 * --------------------------------
 * 
 * AuthContext.canView(module):
 *   return permissions.some((p) => p.module === module && p.can_view);
 * 
 * AuthContext.canEdit(module):
 *   return permissions.some((p) => p.module === module && p.can_edit);
 * 
 * Primer:
 *   permissions = [
 *     { module: 'analytics', can_view: true, can_edit: true, can_delete: false },
 *     { module: 'orders', can_view: true, can_edit: false, can_delete: false }
 *   ]
 *   
 *   canView('analytics') → true
 *   canView('orders') → true
 *   canView('pazar') → false
 *   canEdit('analytics') → true
 *   canEdit('orders') → false
 */

/* ============================================================================
 * 5. ROUTE PROTECTION - Kako se štite rute, redirect logika
 * ============================================================================
 */

/*
 * 5.1. AUTHGUARD KOMPONENTA
 * --------------------------
 * 
 * Komponenta: AuthGuard.jsx (src/core/auth/AuthGuard.jsx)
 * 
 * Svrha: Proverava da li je user authenticated
 * 
 * Logika:
 * 1. Proverava: useAuth().isAuthenticated
 * 2. Ako loading: prikazuje loading spinner
 * 3. Ako !isAuthenticated: redirect na /login
 * 4. Ako isAuthenticated: renderuje children
 * 
 * Upotreba:
 *   <Route path="/admin/*" element={
 *     <AuthGuard>
 *       <AdminLayout>
 *         <Routes>...</Routes>
 *       </AdminLayout>
 *     </AuthGuard>
 *   } />
 * 
 * NAPOMENA: AuthGuard se koristi za sve /admin/* rute. Ne proverava
 *           permissions, samo authentication.
 */

/*
 * 5.2. PROTECTEDROUTE KOMPONENTA
 * --------------------------------
 * 
 * Komponenta: ProtectedRoute.jsx (src/core/auth/ProtectedRoute.jsx)
 * 
 * Svrha: Proverava da li user ima permission za modul
 * 
 * Logika:
 * 1. Proverava: useAuth().loading
 *    - Ako loading: prikazuje loading spinner
 * 
 * 2. Proverava: useAuth().isAuthenticated
 *    - Ako !isAuthenticated: redirect na /login
 *    - (AuthGuard bi trebalo da ovo spreči, ali je fallback)
 * 
 * 3. Proverava: useAuth().canView(module)
 *    - Ako !canView: redirect na fallbackPath (default: /admin/analytics)
 *    - Ako canView: renderuje children
 * 
 * Upotreba:
 *   <Route path="analytics" element={
 *     <ProtectedRoute module="analytics">
 *       <DashboardPage />
 *     </ProtectedRoute>
 *   } />
 * 
 * NAPOMENA: ProtectedRoute se koristi za specifične module unutar /admin/*.
 *           Zahteva i authentication i module permission.
 */

/*
 * 5.3. PERMISSIONGUARD KOMPONENTA (Neaktivno)
 * ---------------------------------------------
 * 
 * Komponenta: PermissionGuard.jsx (src/core/auth/PermissionGuard.jsx)
 * 
 * Svrha: Proverava permissions kroz role_module_permissions
 * 
 * Logika:
 * 1. Proverava: useAuth().roles (array role objekata)
 * 2. Query: SELECT * FROM role_module_permissions 
 *           WHERE role_id IN (roleIds) AND module_id = moduleId
 * 3. Proverava: da li bilo koja rola ima required permission
 * 4. Ako nema: prikazuje "Access Denied" ili fallback
 * 5. Ako ima: renderuje children
 * 
 * NAPOMENA: PermissionGuard postoji ali se NE koristi u trenutnom kodu.
 *           Umesto toga se koristi ProtectedRoute sa AuthContext.canView().
 *           PermissionGuard bi bio koristan za multi-role support u budućnosti.
 */

/*
 * 5.4. STAFF APP ROUTE PROTECTION
 * ----------------------------------
 * 
 * Komponenta: StaffLayout.jsx (pretpostavljeno)
 * 
 * Logika:
 * 1. Proverava: pazarAuthStore.isAuthenticated
 * 2. Ako !isAuthenticated: redirect na /staff/login
 * 3. Ako isAuthenticated: renderuje Staff App
 * 
 * NAPOMENA: Staff App nema module-based permissions. Pristup se kontroliše
 *           kroz hardcoded rute i role-based redirect.
 */

/*
 * 5.5. REDIRECT LOGIKA
 * ----------------------
 * 
 * Email+Password Login:
 * - Uspešan login → /admin/analytics
 * - Neuspešan login → ostaje na /login
 * - Logout → /login
 * - Neauthenticated access → /login
 * - No permission → /admin/analytics (fallback)
 * 
 * Name+PIN Login:
 * - Uspešan login → /staff/waiter ili /staff/pickup (zavisi od role)
 * - Neuspešan login → ostaje na /pazar/login ili /staff/login
 * - Logout → /pazar/login ili /staff/login
 * - Neauthenticated access → /pazar/login ili /staff/login
 * 
 * Role-based Redirect:
 * - vozac → /staff/pickup
 * - konobar → /staff/waiter
 * - default → /staff/waiter
 */

/* ============================================================================
 * 6. ROLE-BASED ACCESS - Šta svaka rola vidi (admin, finansije, menadzer, konobar, vozac)
 * ============================================================================
 */

/*
 * 6.1. ROLE DEFINICIJE
 * ----------------------
 * 
 * Role u pazar_users.role:
 * - 'admin': Administrator (puni pristup)
 * - 'menadzer': Menadžer (ograničen pristup)
 * - 'finansije': Finansijski menadžer (finansijski moduli)
 * - 'konobar': Konobar (staff app)
 * - 'vozac': Vozač (staff app, pickup modul)
 * 
 * NAPOMENA: Role su stringovi u pazar_users tabeli. Nisu UUID-ovi iz roles
 *           tabele (ako postoji).
 */

/*
 * 6.2. ADMIN ROLE
 * ----------------
 * 
 * Login: Email+Password
 * Target: /admin/analytics
 * 
 * Permissions (iz module_permissions):
 * - analytics: can_view=true, can_edit=true, can_delete=true
 * - orders: can_view=true, can_edit=true, can_delete=true
 * - pazar: can_view=true, can_edit=true, can_delete=true
 * - magacin: can_view=true, can_edit=true, can_delete=true
 * - (svi moduli: full access)
 * 
 * Access:
 * - Svi /admin/* rute
 * - Svi moduli u sidebar-u
 * - Sve funkcionalnosti
 * 
 * NAPOMENA: Admin ima puni pristup svim modulima.
 */

/*
 * 6.3. MENADZER ROLE
 * --------------------
 * 
 * Login: Email+Password
 * Target: /admin/analytics
 * 
 * Permissions (iz module_permissions):
 * - analytics: can_view=true, can_edit=true, can_delete=false
 * - orders: can_view=true, can_edit=true, can_delete=false
 * - pazar: can_view=true, can_edit=true, can_delete=false
 * - magacin: can_view=true, can_edit=true, can_delete=false
 * - (većina modula: view+edit, bez delete)
 * 
 * Access:
 * - Svi /admin/* rute (osim admin-only funkcionalnosti)
 * - Većina modula u sidebar-u
 * - Edit funkcionalnosti (bez delete)
 * 
 * NAPOMENA: Menadžer ima pristup operacijama ali ne može da briše podatke.
 */

/*
 * 6.4. FINANSIJE ROLE
 * ---------------------
 * 
 * Login: Email+Password
 * Target: /admin/analytics (ili /admin/pazar)
 * 
 * Permissions (iz module_permissions):
 * - pazar: can_view=true, can_edit=true, can_delete=false
 * - analytics: can_view=true, can_edit=false, can_delete=false
 * - orders: can_view=false, can_edit=false, can_delete=false
 * - magacin: can_view=false, can_edit=false, can_delete=false
 * 
 * Access:
 * - /admin/pazar/* rute
 * - /admin/analytics (read-only)
 * - Finansijski moduli
 * 
 * NAPOMENA: Finansije role ima pristup samo finansijskim modulima.
 */

/*
 * 6.5. KONOBAR ROLE
 * ------------------
 * 
 * Login: Name+PIN
 * Target: /staff/waiter
 * 
 * Permissions:
 * - NEMA module-based permissions
 * - Pristup kroz hardcoded rute
 * 
 * Access:
 * - /staff/waiter (home)
 * - /staff/shift (pazar dashboard)
 * - /staff/notifications (placeholder)
 * - /staff/profile (placeholder)
 * 
 * Funkcionalnosti:
 * - Započinjanje smene
 * - Završetak smene
 * - Predaja kolegi
 * - Brojanje novca
 * - E-Bar unos
 * 
 * NAPOMENA: Konobar koristi Staff App, ne Admin Shell.
 */

/*
 * 6.6. VOZAC ROLE
 * ----------------
 * 
 * Login: Name+PIN
 * Target: /staff/pickup
 * 
 * Permissions:
 * - NEMA module-based permissions
 * - Pristup kroz hardcoded rute
 * 
 * Access:
 * - /staff/pickup (pickup dashboard)
 * - /staff/home (opciono)
 * 
 * Funkcionalnosti:
 * - Pregled pending pickups
 * - Preuzimanje novca od lokacija
 * - Dostava novca u sef
 * - Foto dokumentacija
 * 
 * NAPOMENA: Vozač koristi Staff App, fokus na pickup funkcionalnosti.
 */

/*
 * 6.7. SIDEBAR FILTERING
 * -----------------------
 * 
 * Komponenta: Sidebar.jsx (src/core/layouts/Sidebar.jsx)
 * 
 * Logika:
 * 1. Za svaki menu item:
 *    - Ako item ima module property:
 *      → Proverava useAuth().canView(item.module)
 *      → Ako canView: prikazuje item
 *      → Ako !canView: sakriva item
 *    - Ako item nema module property:
 *      → Uvek prikazuje (npr. "Pregled" sekcija)
 * 
 * Primer:
 *   { icon: BarChart3, label: 'Smart Analitika', path: '/admin/analytics', module: 'analytics' }
 *   → Prikazuje se samo ako canView('analytics') === true
 * 
 *   { icon: Utensils, label: 'Menadžment Menija', path: '/admin/menu', module: 'operations' }
 *   → Prikazuje se samo ako canView('operations') === true
 * 
 * NAPOMENA: Sidebar automatski filtrira stavke na osnovu permissions.
 */

/* ============================================================================
 * 7. LOGOUT - Kako radi logout za oba tipa korisnika
 * ============================================================================
 */

/*
 * 7.1. EMAIL+PASSWORD LOGOUT
 * ----------------------------
 * 
 * Funkcija: AuthContext.logout()
 * 
 * Logika:
 * 1. Poziva supabase.auth.signOut()
 * 2. Supabase:
 *    a) Briše session iz localStorage
 *    b) Invalidira access_token i refresh_token
 *    c) Emituje 'SIGNED_OUT' event
 * 3. AuthContext:
 *    a) setUser(null)
 *    b) setSession(null)
 *    c) setEmployee(null)
 *    d) setPermissions([])
 * 4. onAuthStateChange listener:
 *    a) Prima 'SIGNED_OUT' event
 *    b) setSession(null)
 *    c) setUser(null)
 *    d) clear employee i permissions
 * 5. Redirect:
 *    - AuthGuard detektuje !isAuthenticated
 *    - Redirect na /login
 * 
 * NAPOMENA: Logout je potpuno - briše sve auth state i session.
 */

/*
 * 7.2. NAME+PIN LOGOUT
 * ---------------------
 * 
 * Funkcija: pazarAuthStore.logout()
 * 
 * Logika:
 * 1. Poziva supabase.auth.signOut()
 * 2. Supabase:
 *    a) Briše session iz localStorage
 *    b) Invalidira access_token i refresh_token
 * 3. pazarAuthStore:
 *    a) setUser(null)
 *    b) setSession(null)
 *    c) setSelectedUser(null)
 *    d) setSearchResults([])
 *    e) setError(null)
 *    f) setFailedAttempts(0)
 *    g) setLockedUntil(null)
 *    h) setSelectedLocationId(null)
 * 4. Zustand persist:
 *    a) Briše 'pazar-auth-storage' iz localStorage
 * 5. Redirect:
 *    - StaffLayout detektuje !isAuthenticated
 *    - Redirect na /pazar/login ili /staff/login
 * 
 * NAPOMENA: Logout briše i Zustand store state i Supabase session.
 */

/*
 * 7.3. LOGOUT UI
 * ---------------
 * 
 * Admin Shell:
 * - Logout dugme u Sidebar (user menu)
 * - Poziva AuthContext.logout()
 * - Redirect na /login
 * 
 * Staff App:
 * - Logout dugme u StaffHeader ili StaffBottomNav
 * - Poziva pazarAuthStore.logout()
 * - Redirect na /pazar/login ili /staff/login
 * 
 * NAPOMENA: Logout je eksplicitna akcija - nema auto-logout na session expiry.
 *           Session expiry samo zahteva re-login pri sledećem pristupu.
 */

/* ============================================================================
 * 8. DODATNE NAPOMENE
 * ============================================================================
 */

/*
 * 8.1. ROUTE SEPARATION
 * ----------------------
 * 
 * Admin Shell Routes (/admin/*):
 * - Koriste AuthContext (email+password)
 * - Zahtevaju Supabase Auth session
 * - Zahtevaju module permissions
 * - Zaštićene sa AuthGuard + ProtectedRoute
 * 
 * Staff App Routes (/staff/*, /pazar/*):
 * - Koriste pazarAuthStore (name+pin)
 * - Zahtevaju pazarAuthStore session
 * - NEMA module permissions
 * - Zaštićene sa StaffLayout auth check
 * 
 * NAPOMENA: Dva sistema su potpuno odvojena. Admin Shell ne koristi PIN login,
 *           Staff App ne koristi email+password login.
 */

/*
 * 8.2. EMPLOYEE DATA LOADING
 * ----------------------------
 * 
 * Email+Password:
 * - Query: SELECT * FROM pazar_users 
 *          WHERE email = user.email OR auth_user_id = user.id
 * - Ako employee postoji:
 *   a) setEmployee(employeeData)
 *   b) Query: SELECT * FROM module_permissions WHERE role = employee.role
 *   c) setPermissions(permData)
 * - Ako employee ne postoji:
 *   a) employee = null
 *   b) permissions = []
 * 
 * Name+PIN:
 * - Employee data se vraća direktno iz Edge Function
 * - Edge Function query: SELECT * FROM pazar_users WHERE id = user_id
 * - User data se čuva u pazarAuthStore.user
 * - NEMA permissions loading
 * 
 * NAPOMENA: Email+password zahteva dva query-ja (employee + permissions).
 *           Name+PIN vraća user data direktno iz Edge Function.
 */

/*
 * 8.3. AUTH STATE SKIP LOGIKA
 * -----------------------------
 * 
 * AuthContext.skip na /pazar/* i /staff/* rutama:
 * 
 * Logika:
 * - Ako location.pathname.startsWith('/pazar') ili startsWith('/staff'):
 *   → NE poziva fetchEmployeeData()
 *   → NE učitava employee i permissions
 *   → Ostavlja employee=null, permissions=[]
 * 
 * Razlog:
 * - /pazar/* i /staff/* rute koriste pazarAuthStore
 * - AuthContext bi pokušao da učita employee data za Supabase Auth user
 * - Ali staff korisnici nemaju Supabase Auth account
 * - Skip logika sprečava nepotrebne query-je i greške
 * 
 * NAPOMENA: Ovo je optimizacija - sprečava konflikt između dva auth sistema.
 */

/*
 * 8.4. PIN AUTH EDGE FUNCTION
 * -----------------------------
 * 
 * Endpoint: /functions/v1/pin-auth
 * Method: POST
 * 
 * Input:
 * {
 *   user_id: "uuid",
 *   pin: "12345"
 * }
 * 
 * Logic (pretpostavljeno):
 * 1. Query: SELECT * FROM pazar_users WHERE id = user_id
 * 2. Proverava: user.pin_code === pin
 * 3. Proverava: user.failed_attempts < 3 (ili locked_until < now())
 * 4. Ako validno:
 *    a) Reset failed_attempts = 0
 *    b) Kreira Supabase session programski
 *    c) Vraća { success: true, user, session }
 * 5. Ako invalidno:
 *    a) UPDATE pazar_users SET failed_attempts = failed_attempts + 1
 *    b) Ako failed_attempts >= 3: locked_until = now() + 15min
 *    c) Vraća { success: false, error, remaining_attempts, locked }
 * 
 * NAPOMENA: Edge Function nije u kodu - pretpostavlja se implementacija
 *           na osnovu pazarAuthStore.login() logike.
 */

/*
 * 8.5. MULTI-LOCATION SUPPORT
 * -----------------------------
 * 
 * pazarAuthStore.selectedLocationId:
 * - Staff korisnik može imati default_location_id
 * - Može selektovati drugu lokaciju tokom sesije
 * - selectedLocationId se čuva u Zustand store
 * - Koristi se za shift operations i pickup operations
 * 
 * NAPOMENA: Email+password login nema location selection - pretpostavlja
 *           se da admin/menadžer vidi sve lokacije.
 */

/*
 * 8.6. SESSION REFRESH
 * ----------------------
 * 
 * Supabase Auto-refresh:
 * - Access token expires za 1 sat
 * - Supabase client automatski refresh-uje token 5 minuta pre isteka
 * - Koristi refresh_token iz localStorage
 * - Transparentno za aplikaciju
 * 
 * Manual Refresh:
 * - supabase.auth.refreshSession() - može se pozvati manualno
 * - Koristi se retko (samo ako auto-refresh fail-uje)
 * 
 * Refresh Token Expiry:
 * - Refresh token expires za 30 dana
 * - Ako refresh token istekne: user mora da se ponovo prijavi
 * - Nema auto-renewal za refresh token
 */

/*
 * 8.7. ERROR HANDLING
 * --------------------
 * 
 * Login Errors:
 * - Email+Password: Prikazuje error.message iz Supabase
 * - Name+PIN: Prikazuje error iz Edge Function response
 * 
 * Session Errors:
 * - Ako getSession() fail-uje: setLoading(false), user=null
 * - Ako fetchEmployeeData() fail-uje: employee=null, permissions=[]
 * - Ako permission check fail-uje: redirect na fallbackPath
 * 
 * Network Errors:
 * - Supabase client automatski retry-uje failed requests
 * - Ako network fail: prikazuje error poruku
 * - User može da pokuša ponovo
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
