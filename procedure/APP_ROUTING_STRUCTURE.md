/*
 * ============================================================================
 * APLIKACIJA - KOMPLETNA STRUKTURA I ROUTING
 * ============================================================================
 * 
 * Ovaj dokument opisuje kompletnu strukturu aplikacije, routing hijerarhiju,
 * layout sistem, protected routes, nested routes, redirect logiku i
 * organizaciju modula.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. ROUTE HIERARCHY - Sve rute i njihova hijerarhija
 * ============================================================================
 */

/*
 * 1.1. GLAVNA ROUTE STRUKTURA
 * ----------------------------
 * 
 * Root Router: App.jsx
 * Wrapper: AuthProvider (React Context)
 * Router: BrowserRouter (u main.jsx)
 * 
 * Route Hijerarhija:
 * 
 * / (root)
 * ├── /login (PUBLIC)
 * ├── /pazar/login (PUBLIC)
 * ├── /pazar/app (REDIRECT → /staff/waiter)
 * ├── /pazar/finance (PROTECTED - AdminLayout)
 * ├── /pazar/vozac (PROTECTED - AdminLayout)
 * ├── /pazar/sef (PROTECTED - AdminLayout)
 * ├── /staff/login (PUBLIC)
 * ├── /staff/* (PROTECTED - StaffLayout)
 * │   ├── /staff (index - StaffHomePage)
 * │   ├── /staff/waiter (REDIRECT → /staff)
 * │   ├── /staff/shift (PazarDashboardPage)
 * │   ├── /staff/pickup (PickupPage)
 * │   ├── /staff/notifications (PLACEHOLDER)
 * │   ├── /staff/profile (PLACEHOLDER)
 * │   └── /staff/* (catch-all → /staff)
 * ├── /admin/* (PROTECTED - AdminLayout)
 * │   ├── /admin (index - AdminDashboard)
 * │   ├── /admin/analytics (DashboardPage - ProtectedRoute)
 * │   ├── /admin/orders (LiveOrdersPage - ProtectedRoute)
 * │   ├── /admin/pazar (nested routes)
 * │   │   ├── /admin/pazar (index - PazarOverviewPage)
 * │   │   ├── /admin/pazar/shifts (AdminShiftsPage)
 * │   │   ├── /admin/pazar/pickups (AdminPickupsPage)
 * │   │   ├── /admin/pazar/receive (FinanceReceivePage)
 * │   │   ├── /admin/pazar/safe (FinanceSafePage)
 * │   │   ├── /admin/pazar/bank (FinanceBankPage)
 * │   │   └── /admin/pazar/bank/settings (BankSettingsPage)
 * │   ├── /admin/magacin (nested routes - MagacinLayout)
 * │   │   ├── /admin/magacin (index → /admin/magacin/trebovanje)
 * │   │   ├── /admin/magacin/trebovanje (TrebovanjePage)
 * │   │   ├── /admin/magacin/lista (TrebovanjaListPage)
 * │   │   ├── /admin/magacin/prenosi (PrenosiPage)
 * │   │   └── /admin/magacin/nedostaje (NedostajePage)
 * │   └── /admin/* (catch-all → /admin/analytics)
 * ├── /analytics (PROTECTED - AnalyticsDashboard standalone)
 * ├── / (root redirect → /admin/analytics)
 * └── /* (catch-all → /admin/analytics)
 */

/*
 * 1.2. PUBLIC ROUTES (Ne zahtevaju authentication)
 * -------------------------------------------------
 * 
 * /login
 *   - Komponenta: LoginPage
 *   - Layout: Nema (fullscreen)
 *   - Auth: Nema
 *   - Opis: Email+Password login za Admin Shell
 * 
 * /pazar/login
 *   - Komponenta: PinLoginPage
 *   - Layout: Nema (fullscreen)
 *   - Auth: Nema
 *   - Opis: Name+PIN login za Staff App
 * 
 * /staff/login
 *   - Komponenta: StaffLoginPage
 *   - Layout: Nema (fullscreen)
 *   - Auth: Nema
 *   - Opis: Name+PIN login za Staff App (alternativni entry point)
 * 
 * NAPOMENA: Sve ostale rute su PROTECTED i zahtevaju authentication.
 */

/*
 * 1.3. PROTECTED ROUTES (Zahtevaju authentication)
 * -------------------------------------------------
 * 
 * Admin Shell Routes (/admin/*):
 *   - Wrapper: AuthGuard
 *   - Layout: AdminLayout
 *   - Auth: AuthContext (email+password)
 *   - Permissions: ProtectedRoute sa module check
 * 
 * Staff App Routes (/staff/*):
 *   - Wrapper: StaffLayout (ima built-in auth check)
 *   - Layout: StaffLayout
 *   - Auth: pazarAuthStore (name+pin)
 *   - Permissions: Nema (hardcoded rute)
 * 
 * Pazar Admin Routes (/pazar/finance, /pazar/vozac, /pazar/sef):
 *   - Wrapper: AuthGuard
 *   - Layout: AdminLayout
 *   - Auth: AuthContext (email+password)
 *   - Permissions: Nema (direktno u AdminLayout)
 * 
 * Analytics Standalone (/analytics):
 *   - Wrapper: AuthGuard
 *   - Layout: Nema (AnalyticsDashboard ima svoj layout)
 *   - Auth: AuthContext (email+password)
 *   - Permissions: Nema (direktno u AuthGuard)
 */

/*
 * 1.4. NESTED ROUTES
 * -------------------
 * 
 * /admin/pazar/* (Nested u /admin/*):
 *   - Parent: /admin/* (AdminLayout)
 *   - Child routes: /admin/pazar, /admin/pazar/shifts, itd.
 *   - Svi child routes koriste ProtectedRoute sa module="pazar"
 *   - Svi child routes su unutar AdminLayout-a
 * 
 * /admin/magacin/* (Nested u /admin/*):
 *   - Parent: /admin/* (AdminLayout)
 *   - Layout wrapper: MagacinLayout (unutrašnji layout sa tabovima)
 *   - Child routes: /admin/magacin/trebovanje, /admin/magacin/lista, itd.
 *   - Parent route koristi ProtectedRoute sa module="magacin"
 *   - Child routes su unutar MagacinLayout-a (Outlet)
 * 
 * /staff/* (Nested u StaffLayout):
 *   - Parent: /staff/* (StaffLayout)
 *   - Child routes: /staff, /staff/shift, /staff/pickup, itd.
 *   - Svi child routes su unutar StaffLayout-a (Outlet)
 *   - StaffLayout proverava authentication pre renderovanja
 */

/* ============================================================================
 * 2. LAYOUTS - Koji layout se koristi za koju rutu
 * ============================================================================
 */

/*
 * 2.1. ADMINLAYOUT
 * -----------------
 * 
 * Lokacija: src/core/layouts/AdminLayout.jsx
 * 
 * Komponente:
 *   - Sidebar (leva navigacija)
 *   - Header (top bar sa breadcrumbs)
 *   - Main content area (children)
 *   - BottomNav (mobile only)
 * 
 * Koristi se za:
 *   - /admin/* (sve admin rute)
 *   - /pazar/finance
 *   - /pazar/vozac
 *   - /pazar/sef
 * 
 * Features:
 *   - Responsive sidebar (mobile: overlay, desktop: fixed)
 *   - Breadcrumb navigation (generiše se iz pathname)
 *   - User menu sa logout
 *   - Search i notifications ikone (header)
 *   - Bottom navigation (samo mobile)
 * 
 * Auth:
 *   - Koristi useAuth() hook
 *   - Prikazuje employee info u header-u
 *   - Sidebar filtrira stavke na osnovu canView() permissions
 * 
 * NAPOMENA: AdminLayout je wrapper za sve admin funkcionalnosti.
 */

/*
 * 2.2. STAFFLAYOUT
 * -----------------
 * 
 * Lokacija: src/modules/staff/components/layout/StaffLayout.jsx
 * 
 * Komponente:
 *   - StaffHeader (top bar)
 *   - Main content area (Outlet za child routes)
 *   - StaffBottomNav (bottom navigation)
 * 
 * Koristi se za:
 *   - /staff/* (sve staff app rute)
 * 
 * Features:
 *   - Mobile-first design (max-width: 430px)
 *   - Centriran layout
 *   - Bottom navigation sa quick actions
 *   - Header sa user info i logout
 * 
 * Auth:
 *   - Proverava pazarAuthStore.isAuthenticated
 *   - Ako !isAuthenticated: redirect na /staff/login
 *   - Koristi Outlet za renderovanje child routes
 * 
 * NAPOMENA: StaffLayout je mobile-first app za staff korisnike.
 */

/*
 * 2.3. MAGACINLAYOUT
 * -------------------
 * 
 * Lokacija: src/modules/magacin/pages/MagacinLayout.jsx
 * 
 * Komponente:
 *   - Header (naslov i opis)
 *   - Tabs navigation (NavLink)
 *   - Content area (Outlet za child routes)
 * 
 * Koristi se za:
 *   - /admin/magacin/* (sve magacin rute)
 * 
 * Features:
 *   - Tab-based navigation (Trebovanje, Trebovanja, Prenosi, Nedostaje)
 *   - Active tab highlighting
 *   - Nested unutar AdminLayout-a
 * 
 * Auth:
 *   - Parent route (/admin/magacin) koristi ProtectedRoute
 *   - Child routes ne zahtevaju dodatnu auth proveru
 * 
 * NAPOMENA: MagacinLayout je unutrašnji layout za Magacin modul,
 *           unutar AdminLayout-a.
 */

/*
 * 2.4. NO LAYOUT (Fullscreen)
 * -----------------------------
 * 
 * Komponente bez layout-a:
 *   - LoginPage (/login)
 *   - PinLoginPage (/pazar/login)
 *   - StaffLoginPage (/staff/login)
 *   - AnalyticsDashboard (/analytics) - ima svoj layout
 * 
 * NAPOMENA: Login stranice su fullscreen bez layout-a.
 *           AnalyticsDashboard ima svoj custom layout.
 */

/* ============================================================================
 * 3. PROTECTED ROUTES - Koje rute zahtevaju auth, koje su public
 * ============================================================================
 */

/*
 * 3.1. AUTHGUARD KOMPONENTA
 * --------------------------
 * 
 * Lokacija: src/core/auth/AuthGuard.jsx
 * 
 * Logika:
 *   1. Proverava useAuth().isAuthenticated
 *   2. Ako loading: prikazuje loading spinner
 *   3. Ako !isAuthenticated: redirect na /login
 *   4. Ako isAuthenticated: renderuje children
 * 
 * Koristi se za:
 *   - /admin/* (wrapper za AdminLayout)
 *   - /pazar/finance, /pazar/vozac, /pazar/sef
 *   - /analytics
 * 
 * NAPOMENA: AuthGuard proverava samo authentication, ne permissions.
 */

/*
 * 3.2. PROTECTEDROUTE KOMPONENTA
 * --------------------------------
 * 
 * Lokacija: src/core/auth/ProtectedRoute.jsx
 * 
 * Logika:
 *   1. Proverava useAuth().loading
 *   2. Proverava useAuth().isAuthenticated (fallback)
 *   3. Proverava useAuth().canView(module)
 *   4. Ako !canView: redirect na fallbackPath (default: /admin/analytics)
 *   5. Ako canView: renderuje children
 * 
 * Koristi se za:
 *   - /admin/analytics (module="analytics")
 *   - /admin/orders (module="orders")
 *   - /admin/pazar/* (module="pazar")
 *   - /admin/magacin (module="magacin")
 * 
 * NAPOMENA: ProtectedRoute proverava i authentication i module permissions.
 */

/*
 * 3.3. STAFFLAYOUT AUTH CHECK
 * -----------------------------
 * 
 * Lokacija: src/modules/staff/components/layout/StaffLayout.jsx
 * 
 * Logika:
 *   1. Proverava pazarAuthStore.isAuthenticated
 *   2. Ako !isAuthenticated: redirect na /staff/login
 *   3. Ako isAuthenticated: renderuje StaffLayout sa Outlet
 * 
 * Koristi se za:
 *   - /staff/* (sve staff app rute)
 * 
 * NAPOMENA: StaffLayout ima built-in auth check, ne koristi AuthGuard.
 */

/*
 * 3.4. PUBLIC ROUTES
 * -------------------
 * 
 * Rute koje NE zahtevaju authentication:
 *   - /login (LoginPage)
 *   - /pazar/login (PinLoginPage)
 *   - /staff/login (StaffLoginPage)
 * 
 * NAPOMENA: Sve ostale rute su PROTECTED.
 */

/* ============================================================================
 * 4. NESTED ROUTES - Kako su ugnježdene rute
 * ============================================================================
 */

/*
 * 4.1. /admin/* NESTED STRUCTURE
 * --------------------------------
 * 
 * Parent Route:
 *   <Route path="/admin/*" element={<AuthGuard><AdminLayout><Routes>...</Routes></AdminLayout></AuthGuard>}>
 * 
 * Child Routes (unutar <Routes>):
 *   - <Route index element={<AdminDashboard />} />
 *   - <Route path="analytics" element={<ProtectedRoute module="analytics">...</ProtectedRoute>} />
 *   - <Route path="orders" element={<ProtectedRoute module="orders">...</ProtectedRoute>} />
 *   - <Route path="pazar">...</Route> (nested)
 *   - <Route path="magacin">...</Route> (nested)
 * 
 * NAPOMENA: React Router v6 koristi <Routes> unutar parent route element-a
 *           za nested routing. Outlet se ne koristi jer je children direktno
 *           renderovan u AdminLayout.
 */

/*
 * 4.2. /admin/pazar/* NESTED STRUCTURE
 * --------------------------------------
 * 
 * Parent Route:
 *   <Route path="pazar">
 *     <Route index element={<ProtectedRoute module="pazar"><PazarOverviewPage /></ProtectedRoute>} />
 *     <Route path="shifts" element={<ProtectedRoute module="pazar"><AdminShiftsPage /></ProtectedRoute>} />
 *     ...
 *   </Route>
 * 
 * Child Routes:
 *   - /admin/pazar (index)
 *   - /admin/pazar/shifts
 *   - /admin/pazar/pickups
 *   - /admin/pazar/receive
 *   - /admin/pazar/safe
 *   - /admin/pazar/bank
 *   - /admin/pazar/bank/settings
 * 
 * NAPOMENA: Sve child routes koriste ProtectedRoute sa module="pazar".
 *           Nema dodatnog layout-a, samo AdminLayout.
 */

/*
 * 4.3. /admin/magacin/* NESTED STRUCTURE
 * ----------------------------------------
 * 
 * Parent Route:
 *   <Route path="magacin" element={<ProtectedRoute module="magacin"><MagacinLayout /></ProtectedRoute>}>
 *     <Route index element={<Navigate to="trebovanje" replace />} />
 *     <Route path="trebovanje" element={<TrebovanjePage />} />
 *     <Route path="lista" element={<TrebovanjaListPage />} />
 *     <Route path="prenosi" element={<PrenosiPage />} />
 *     <Route path="nedostaje" element={<NedostajePage />} />
 *   </Route>
 * 
 * Child Routes:
 *   - /admin/magacin (index → redirect na /admin/magacin/trebovanje)
 *   - /admin/magacin/trebovanje
 *   - /admin/magacin/lista
 *   - /admin/magacin/prenosi
 *   - /admin/magacin/nedostaje
 * 
 * Layout Hierarchy:
 *   AdminLayout (outer)
 *     └── MagacinLayout (inner, sa tabovima)
 *         └── Child Page (TrebovanjePage, itd.)
 * 
 * NAPOMENA: MagacinLayout koristi <Outlet /> za renderovanje child routes.
 *           Parent route koristi ProtectedRoute, child routes ne.
 */

/*
 * 4.4. /staff/* NESTED STRUCTURE
 * -------------------------------
 * 
 * Parent Route:
 *   <Route path="/staff/*" element={<StaffLayout />}>
 *     <Route index element={<StaffHomePage />} />
 *     <Route path="waiter" element={<Navigate to="/staff" replace />} />
 *     <Route path="shift" element={<PazarDashboardPage />} />
 *     <Route path="pickup" element={<PickupPage />} />
 *     <Route path="notifications" element={<div>...</div>} />
 *     <Route path="profile" element={<div>...</div>} />
 *     <Route path="*" element={<Navigate to="/staff" replace />} />
 *   </Route>
 * 
 * Child Routes:
 *   - /staff (index - StaffHomePage)
 *   - /staff/waiter (redirect → /staff)
 *   - /staff/shift (PazarDashboardPage)
 *   - /staff/pickup (PickupPage)
 *   - /staff/notifications (placeholder)
 *   - /staff/profile (placeholder)
 *   - /staff/* (catch-all → /staff)
 * 
 * Layout Hierarchy:
 *   StaffLayout (sa auth check)
 *     └── StaffHeader (top)
 *     └── <Outlet /> (child routes)
 *     └── StaffBottomNav (bottom)
 * 
 * NAPOMENA: StaffLayout koristi <Outlet /> za renderovanje child routes.
 *           Auth check je u StaffLayout, ne u AuthGuard.
 */

/* ============================================================================
 * 5. REDIRECTS - Default redirecti po roli posle logina
 * ============================================================================
 */

/*
 * 5.1. EMAIL+PASSWORD LOGIN REDIRECT
 * ------------------------------------
 * 
 * Komponenta: LoginPage.jsx
 * 
 * Logika:
 *   1. User se prijavljuje sa email+password
 *   2. AuthContext.login() uspešan
 *   3. navigate('/admin/analytics', { replace: true })
 * 
 * Redirect:
 *   /login → /admin/analytics
 * 
 * NAPOMENA: Svi email+password korisnici se redirect-uju na /admin/analytics,
 *           bez obzira na rolu. Role-based filtering se dešava kroz
 *           ProtectedRoute i Sidebar filtering.
 */

/*
 * 5.2. NAME+PIN LOGIN REDIRECT
 * ------------------------------
 * 
 * Komponenta: PinLoginPage.jsx
 * 
 * Logika:
 *   1. User se prijavljuje sa name+PIN
 *   2. pazarAuthStore.login() uspešan
 *   3. useEffect proverava user.role
 *   4. Role-based redirect:
 *      - role === 'vozac' → navigate('/staff/pickup')
 *      - role === 'konobar' → navigate('/staff/waiter')
 *      - default → navigate('/staff/waiter')
 * 
 * Redirect:
 *   /pazar/login → /staff/pickup (vozac) ili /staff/waiter (konobar)
 *   /staff/login → /staff/pickup (vozac) ili /staff/waiter (konobar)
 * 
 * NAPOMENA: Name+PIN login ima role-based redirect u Staff App.
 */

/*
 * 5.3. DEFAULT ROUTE REDIRECTS
 * ------------------------------
 * 
 * Root Redirect (/):
 *   <Route path="/" element={<Navigate to="/admin/analytics" replace />} />
 * 
 * Catch-all Redirect (/*):
 *   <Route path="*" element={<Navigate to="/admin/analytics" replace />} />
 * 
 * Admin Catch-all (/admin/*):
 *   <Route path="*" element={<Navigate to="/admin/analytics" replace />} />
 * 
 * Staff Catch-all (/staff/*):
 *   <Route path="*" element={<Navigate to="/staff" replace />} />
 * 
 * Magacin Index (/admin/magacin):
 *   <Route index element={<Navigate to="trebovanje" replace />} />
 * 
 * Staff Waiter (/staff/waiter):
 *   <Route path="waiter" element={<Navigate to="/staff" replace />} />
 * 
 * Pazar App (/pazar/app):
 *   <Route path="/pazar/app" element={<Navigate to="/staff/waiter" replace />} />
 * 
 * NAPOMENA: Svi nepoznati ili root route-ovi se redirect-uju na default stranice.
 */

/*
 * 5.4. PROTECTED ROUTE REDIRECTS
 * --------------------------------
 * 
 * AuthGuard Redirect:
 *   Ako !isAuthenticated → /login
 * 
 * ProtectedRoute Redirect:
 *   Ako !isAuthenticated → /login
 *   Ako !canView(module) → /admin/analytics (fallbackPath)
 * 
 * StaffLayout Redirect:
 *   Ako !isAuthenticated → /staff/login
 * 
 * NAPOMENA: Redirect logika zavisi od auth sistema (AuthContext vs pazarAuthStore).
 */

/* ============================================================================
 * 6. MODULE STRUCTURE - Kako su organizovani moduli
 * ============================================================================
 */

/*
 * 6.1. MODULE ORGANIZACIJA
 * -------------------------
 * 
 * Struktura:
 *   src/modules/
 *     ├── analytics/
 *     │   ├── components/
 *     │   ├── hooks/
 *     │   ├── pages/
 *     │   ├── services/
 *     │   ├── utils/
 *     │   └── module.config.js
 *     ├── magacin/
 *     │   ├── components/
 *     │   ├── config/
 *     │   ├── hooks/
 *     │   ├── pages/
 *     │   └── services/
 *     ├── orders/
 *     │   ├── components/
 *     │   ├── pages/
 *     │   └── services/
 *     ├── pazar/
 *     │   ├── components/
 *     │   ├── pages/
 *     │   ├── services/
 *     │   ├── stores/
 *     │   └── utils/
 *     ├── staff/
 *     │   ├── components/
 *     │   ├── config/
 *     │   ├── hooks/
 *     │   ├── pages/
 *     │   └── services/
 *     └── staff-app/
 *         ├── components/
 *         ├── pages/
 *         └── module.config.js
 * 
 * NAPOMENA: Svaki modul je self-contained sa svojim komponentama, servisima,
 *           hooks-ovima i pages-ima.
 */

/*
 * 6.2. ANALYTICS MODUL
 * ----------------------
 * 
 * Route: /admin/analytics
 * Layout: AdminLayout
 * Protection: ProtectedRoute (module="analytics")
 * 
 * Komponente:
 *   - DashboardPage (glavna stranica)
 *   - AnalyticsDashboard (standalone, /analytics)
 * 
 * Struktura:
 *   - components/: KPICard, HourlyChart, TrendChart, itd.
 *   - hooks/: useAnalyticsData
 *   - services/: analyticsService
 *   - utils/: dateFilters, formatCurrency, supabasePagination
 * 
 * NAPOMENA: Analytics modul je kompletan sa svim potrebnim komponentama.
 */

/*
 * 6.3. ORDERS MODUL
 * -------------------
 * 
 * Route: /admin/orders
 * Layout: AdminLayout
 * Protection: ProtectedRoute (module="orders")
 * 
 * Komponente:
 *   - LiveOrdersPage (glavna stranica)
 * 
 * Struktura:
 *   - components/: OrderCard, OrderDetailModal, OrdersTable, itd.
 *   - services/: ordersService
 * 
 * NAPOMENA: Orders modul prikazuje live porudžbine sa real-time updates.
 */

/*
 * 6.4. PAZAR MODUL
 * ------------------
 * 
 * Routes:
 *   - /admin/pazar/* (admin routes)
 *   - /pazar/finance, /pazar/vozac, /pazar/sef (admin dashboard routes)
 *   - /staff/shift (staff app route)
 * 
 * Layout: AdminLayout (admin) ili StaffLayout (staff)
 * Protection: ProtectedRoute (admin) ili StaffLayout auth (staff)
 * 
 * Komponente:
 *   - DashboardPage (staff app)
 *   - FinanceDashboardPage, VozacDashboardPage, SefDashboardPage (admin)
 *   - PazarOverviewPage, AdminShiftsPage, itd. (admin)
 * 
 * Struktura:
 *   - components/: shift/, auth/, cards/, layout/
 *   - pages/: DashboardPage, PinLoginPage, itd.
 *   - services/: pazarService
 *   - stores/: pazarAuthStore, shiftFlowStore
 *   - utils/: constants, formatters
 * 
 * NAPOMENA: Pazar modul ima i admin i staff funkcionalnosti.
 */

/*
 * 6.5. MAGACIN MODUL
 * --------------------
 * 
 * Route: /admin/magacin/*
 * Layout: AdminLayout (outer) + MagacinLayout (inner)
 * Protection: ProtectedRoute (module="magacin")
 * 
 * Komponente:
 *   - MagacinLayout (sa tabovima)
 *   - TrebovanjePage, TrebovanjaListPage, PrenosiPage, NedostajePage
 * 
 * Struktura:
 *   - components/: ArtikalRow, CartModal, StockCard, itd.
 *   - config/: magacinConfig
 *   - hooks/: useArtikli, useCart
 *   - pages/: MagacinLayout, TrebovanjePage, itd.
 *   - services/: magacinService (eksterni API)
 * 
 * NAPOMENA: Magacin modul koristi eksterni API (https://magacin.collina.co.rs/api/*).
 */

/*
 * 6.6. STAFF MODUL
 * -----------------
 * 
 * Route: /staff/*
 * Layout: StaffLayout
 * Protection: StaffLayout auth check
 * 
 * Komponente:
 *   - StaffHomePage (index)
 *   - PickupPage (pickup)
 *   - PazarDashboardPage (shift)
 * 
 * Struktura:
 *   - components/: layout/, dashboard/, pickup/
 *   - config/: staffCards.config
 *   - hooks/: useStaffCards
 *   - pages/: StaffHomePage, PickupPage, StaffLoginPage
 *   - services/: pickupService
 * 
 * NAPOMENA: Staff modul je mobile-first app za staff korisnike.
 */

/*
 * 6.7. MODULE CONFIG FILES
 * --------------------------
 * 
 * Lokacija: src/modules/[module-name]/module.config.js
 * 
 * Struktura:
 *   {
 *     id: 'module-name',
 *     name: 'Display Name',
 *     icon: 'IconName',
 *     navigation: {
 *       section: 'SECTION_NAME',
 *       order: 1,
 *       parent: null
 *     },
 *     permissions: {
 *       view: ['admin', 'owner', 'manager'],
 *       edit: ['admin', 'owner'],
 *       delete: ['admin']
 *     },
 *     routes: [
 *       { path: '/route', component: 'ComponentName', name: 'Page Name' }
 *     ],
 *     status: 'active',
 *     requires: []
 *   }
 * 
 * NAPOMENA: Module config fajlovi postoje za analytics i staff-app,
 *           ali se trenutno ne koriste u routing-u (hardcoded u App.jsx).
 */

/* ============================================================================
 * 7. ROUTING PATTERNS I BEST PRACTICES
 * ============================================================================
 */

/*
 * 7.1. ROUTE DEFINITION PATTERN
 * ------------------------------
 * 
 * Public Route:
 *   <Route path="/login" element={<LoginPage />} />
 * 
 * Protected Route (sa AuthGuard):
 *   <Route path="/admin/*" element={<AuthGuard><AdminLayout><Routes>...</Routes></AdminLayout></AuthGuard>}>
 * 
 * Protected Route (sa ProtectedRoute):
 *   <Route path="analytics" element={<ProtectedRoute module="analytics"><DashboardPage /></ProtectedRoute>} />
 * 
 * Nested Route:
 *   <Route path="pazar">
 *     <Route index element={...} />
 *     <Route path="shifts" element={...} />
 *   </Route>
 * 
 * Redirect:
 *   <Route path="/" element={<Navigate to="/admin/analytics" replace />} />
 * 
 * Catch-all:
 *   <Route path="*" element={<Navigate to="/admin/analytics" replace />} />
 */

/*
 * 7.2. LAYOUT PATTERN
 * --------------------
 * 
 * Single Layout:
 *   <Route path="/admin/*" element={<AdminLayout><Routes>...</Routes></AdminLayout>}>
 * 
 * Nested Layouts:
 *   <Route path="magacin" element={<MagacinLayout />}>
 *     <Route path="trebovanje" element={<TrebovanjePage />} />
 *   </Route>
 *   (MagacinLayout koristi <Outlet />)
 * 
 * Layout sa Outlet:
 *   <Route path="/staff/*" element={<StaffLayout />}>
 *     <Route index element={<StaffHomePage />} />
 *   </Route>
 *   (StaffLayout koristi <Outlet />)
 */

/*
 * 7.3. AUTH PATTERN
 * ------------------
 * 
 * AuthGuard Pattern:
 *   <Route path="/admin/*" element={<AuthGuard><AdminLayout>...</AdminLayout></AuthGuard>}>
 * 
 * ProtectedRoute Pattern:
 *   <Route path="analytics" element={<ProtectedRoute module="analytics"><Page /></ProtectedRoute>} />
 * 
 * Layout Auth Check Pattern:
 *   <Route path="/staff/*" element={<StaffLayout />}>
 *     (StaffLayout proverava auth unutar sebe)
 * 
 * NAPOMENA: AuthGuard proverava authentication, ProtectedRoute proverava
 *           i authentication i permissions, Layout auth check je za custom logiku.
 */

/*
 * 7.4. MODULE ORGANIZATION PATTERN
 * ----------------------------------
 * 
 * Standardna struktura:
 *   modules/[module-name]/
 *     ├── components/     # UI komponente
 *     ├── pages/          # Page komponente
 *     ├── services/       # API/services
 *     ├── hooks/          # Custom hooks
 *     ├── stores/         # State management (Zustand)
 *     ├── utils/          # Utility funkcije
 *     ├── config/         # Konfiguracija
 *     └── module.config.js # Module metadata
 * 
 * NAPOMENA: Svaki modul je self-contained i može biti nezavisan.
 */

/* ============================================================================
 * 8. DODATNE NAPOMENE
 * ============================================================================
 */

/*
 * 8.1. ROUTE PRIORITY
 * ---------------------
 * 
 * React Router proverava rute po redosledu definisanja:
 *   1. Specifične rute (npr. /admin/pazar/shifts)
 *   2. Nested rute (npr. /admin/pazar)
 *   3. Index rute (npr. /admin)
 *   4. Catch-all rute (npr. /*)
 * 
 * NAPOMENA: Redosled definisanja ruta je važan za ispravno routing.
 */

/*
 * 8.2. NAVIGATION
 * ----------------
 * 
 * Programmatic Navigation:
 *   - useNavigate() hook
 *   - navigate('/path', { replace: true })
 * 
 * Link Navigation:
 *   - <Link to="/path">...</Link>
 *   - <NavLink to="/path" className={({ isActive }) => ...}>...</NavLink>
 * 
 * Redirect Navigation:
 *   - <Navigate to="/path" replace />
 * 
 * NAPOMENA: Koristi se React Router v6 API za navigation.
 */

/*
 * 8.3. ROUTE PARAMETERS
 * -----------------------
 * 
 * Trenutno se ne koriste route parameters (npr. /admin/orders/:id).
 * Umesto toga se koriste query parameters ili state.
 * 
 * Primer za budućnost:
 *   <Route path="orders/:id" element={<OrderDetailPage />} />
 *   const { id } = useParams();
 * 
 * NAPOMENA: Route parameters nisu implementirani, ali mogu se dodati.
 */

/*
 * 8.4. LAZY LOADING
 * -------------------
 * 
 * Trenutno se ne koristi lazy loading za komponente.
 * Sve komponente se import-uju direktno u App.jsx.
 * 
 * Primer za optimizaciju:
 *   const DashboardPage = lazy(() => import('./modules/analytics/pages/DashboardPage'));
 *   <Suspense fallback={<Loading />}><DashboardPage /></Suspense>
 * 
 * NAPOMENA: Lazy loading može poboljšati performance za velike aplikacije.
 */

/*
 * 8.5. ROUTE GUARDS
 * -------------------
 * 
 * Trenutno se koriste:
 *   - AuthGuard (authentication)
 *   - ProtectedRoute (authentication + permissions)
 *   - StaffLayout (custom auth check)
 * 
 * NAPOMENA: Route guards su implementirani i rade kako treba.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
