/*
 * ============================================================================
 * STATE MANAGEMENT PATTERNI - KOMPLETNA DOKUMENTACIJA
 * ============================================================================
 * 
 * Ovaj dokument opisuje sve state management pattern-e u Collina platformi,
 * uključujući Zustand stores, Context providers, local vs global state,
 * persistence, state reset i derived state.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. ZUSTAND STORES - Koji postoje, šta čuvaju, kako se koriste
 * ============================================================================
 */

/*
 * 1.1. ZUSTAND OVERVIEW
 * -----------------------
 * 
 * Library: zustand (v5.0.10)
 * Location: src/modules/pazar/stores/*.js
 * 
 * Stores:
 *   1. pazarAuthStore - Authentication state (PIN login)
 *   2. shiftFlowStore - Shift ending flow state
 * 
 * NAPOMENA: Zustand se koristi samo za Pazar modul - ostali moduli koriste
 *           Context API ili local state.
 */

/*
 * 1.2. PAZAR AUTH STORE
 * -----------------------
 * 
 * File: src/modules/pazar/stores/pazarAuthStore.js
 * Hook: usePazarAuthStore()
 * Persistence: Yes (localStorage, key: 'pazar-auth-storage')
 * 
 * State:
 *   - user: Object | null (pazar_users record)
 *   - session: Object | null (Supabase session)
 *   - isAuthenticated: boolean
 *   - isLoading: boolean
 *   - error: string | null
 *   - searchResults: Array (user search results)
 *   - selectedUser: Object | null (user selected for PIN entry)
 *   - failedAttempts: number (PIN login attempts)
 *   - lockedUntil: number | null (timestamp when lock expires)
 *   - selectedLocationId: UUID | null (currently selected location)
 * 
 * Actions:
 *   - searchUsers(term): Search users by name (min 2 chars)
 *   - selectUser(user): Select user for PIN entry
 *   - clearSelectedUser(): Clear selected user
 *   - login(userId, pin): Login with PIN (calls Edge Function)
 *   - logout(): Clear all state, sign out from Supabase
 *   - isLocked(): Check if account is locked
 *   - getRemainingLockTime(): Get remaining lock time in minutes
 *   - setSelectedLocationId(locationId): Set selected location
 * 
 * Persistence:
 *   - Only persists: user, session, isAuthenticated
 *   - Does NOT persist: searchResults, selectedUser, error, failedAttempts, lockedUntil
 *   - Storage: localStorage (key: 'pazar-auth-storage')
 * 
 * Usage:
 *   const { user, isAuthenticated, login, logout, selectedLocationId, setSelectedLocationId } = usePazarAuthStore();
 * 
 * NAPOMENA: pazarAuthStore je glavni store za PIN-based authentication u Pazar modulu.
 */

/*
 * 1.3. SHIFT FLOW STORE
 * ----------------------
 * 
 * File: src/modules/pazar/stores/shiftFlowStore.js
 * Hook: useShiftFlowStore()
 * Persistence: No (ephemeral state)
 * 
 * State:
 *   - isOpen: boolean (is flow modal open)
 *   - flowType: 'handover' | 'endday' | null
 *   - currentStep: number (0-8)
 *   - isCountLocked: boolean (prevent denomination changes)
 *   - shiftId: UUID | null
 *   - locationId: UUID | null
 *   - userId: UUID | null
 *   - deposit: number (default: 10000)
 *   - denominations: Object ({ 5000: 0, 2000: 0, ... })
 *   - countedAmount: number (calculated from denominations)
 *   - ebarData: Object ({ date, time, cash, card, transfer })
 *   - expectedCash: number (calculated: cash - card)
 *   - difference: number (calculated: countedAmount - expectedCash)
 *   - topupAmount: number
 *   - topupSource: string | null ('own_pocket' | 'tip_jar' | 'colleague' | 'other')
 *   - topupComment: string
 *   - surplusSource: string | null ('tips' | 'rounding' | 'unknown')
 *   - surplusComment: string
 *   - differenceReason: string | null
 *   - differenceComment: string
 * 
 * Actions:
 *   - openFlow(shiftId, locationId, userId, deposit): Initialize flow
 *   - closeFlow(): Reset to initialState
 *   - setFlowType(type): Set 'handover' or 'endday'
 *   - nextStep(): Increment currentStep
 *   - prevStep(): Decrement currentStep (min: 0)
 *   - setDenomination(value, quantity): Set denomination quantity
 *   - incrementDenom(value): Increment denomination by 1
 *   - decrementDenom(value): Decrement denomination by 1 (min: 0)
 *   - lockCount(): Lock denominations (prevent changes)
 *   - setEbarData(data): Update E-Bar data
 *   - calculateReconciliation(): Calculate expectedCash and difference
 *   - setTopup(amount, source, comment): Set topup data (for shortage)
 *   - setSurplus(source, comment): Set surplus data (for surplus)
 *   - setDifferenceReason(reason, comment): Set reason for large difference
 * 
 * Derived State:
 *   - countedAmount: Calculated from denominations (DENOMINATIONS.reduce)
 *   - expectedCash: Calculated from ebarData (cash - card)
 *   - difference: Calculated (countedAmount - expectedCash)
 * 
 * Usage:
 *   const { isOpen, currentStep, denominations, countedAmount, nextStep, setDenomination } = useShiftFlowStore();
 * 
 * NAPOMENA: shiftFlowStore je ephemeral - resetuje se na closeFlow() ili unmount.
 */

/*
 * 1.4. ZUSTAND STORE PATTERNS
 * -----------------------------
 * 
 * Pattern 1: With Persistence
 *   export const useStore = create(
 *     persist(
 *       (set, get) => ({
 *         state: value,
 *         action: () => set({ state: newValue })
 *       }),
 *       {
 *         name: 'storage-key',
 *         partialize: (state) => ({ state: state.state }) // Only persist specific fields
 *       }
 *     )
 *   );
 * 
 * Pattern 2: Without Persistence
 *   export const useStore = create((set, get) => ({
 *     state: value,
 *     action: () => set({ state: newValue })
 *   }));
 * 
 * Pattern 3: Derived State
 *   const countedAmount = DENOMINATIONS.reduce((sum, d) => sum + (denoms[d] * d), 0);
 *   set({ denominations: newDenoms, countedAmount: total });
 * 
 * NAPOMENA: Zustand stores koriste standardne pattern-e - persist za auth, ephemeral za flow.
 */

/* ============================================================================
 * 2. CONTEXT PROVIDERS - AuthContext i drugi - hijerarhija
 * ============================================================================
 */

/*
 * 2.1. CONTEXT PROVIDER OVERVIEW
 * --------------------------------
 * 
 * Context Providers:
 *   1. AuthContext - Authentication state (email+password login)
 * 
 * NAPOMENA: Samo AuthContext postoji - nema drugih Context providers.
 */

/*
 * 2.2. AUTH CONTEXT
 * -------------------
 * 
 * File: src/core/auth/AuthContext.jsx
 * Provider: AuthProvider
 * Hook: useAuth()
 * Persistence: Yes (Supabase Auth - localStorage)
 * 
 * State:
 *   - user: Object | null (Supabase auth user)
 *   - session: Object | null (Supabase session)
 *   - employee: Object | null (pazar_users record)
 *   - permissions: Array (module_permissions records)
 *   - loading: boolean (initial auth check)
 * 
 * Methods:
 *   - login(email, password): Login with email+password
 *   - logout(): Sign out and clear state
 *   - canView(module): Check if user can view module
 *   - canEdit(module): Check if user can edit module
 *   - getViewableModules(): Get all viewable modules
 * 
 * Computed:
 *   - isAuthenticated: boolean (!!user)
 *   - role: string | null (employee?.role)
 * 
 * Initialization:
 *   - useEffect: supabase.auth.getSession() on mount
 *   - useEffect: supabase.auth.onAuthStateChange() listener
 *   - fetchEmployeeData(): Load employee and permissions from database
 * 
 * Route Awareness:
 *   - Skips fetchEmployeeData on /pazar and /staff routes
 *   - These routes use pazarAuthStore instead
 * 
 * NAPOMENA: AuthContext je glavni auth provider za email+password login (Admin Shell).
 */

/*
 * 2.3. CONTEXT HIERARCHY
 * ------------------------
 * 
 * App Structure:
 *   <BrowserRouter>
 *     <AuthProvider>
 *       <Routes>
 *         <Route ... />
 *       </Routes>
 *     </AuthProvider>
 *   </BrowserRouter>
 * 
 * Provider Scope:
 *   - AuthProvider wraps entire app (App.jsx)
 *   - Available to all routes
 *   - useAuth() hook provides access
 * 
 * NAPOMENA: AuthProvider je top-level provider - omotava celu aplikaciju.
 */

/*
 * 2.4. USE AUTH HOOK
 * --------------------
 * 
 * File: src/core/auth/useAuth.js
 * 
 * Implementation:
 *   export function useAuth() {
 *     const context = useContext(AuthContext);
 *     if (!context) {
 *       throw new Error('useAuth must be used within an AuthProvider');
 *     }
 *     return context;
 *   }
 * 
 * Usage:
 *   const { user, employee, role, isAuthenticated, canView, logout } = useAuth();
 * 
 * NAPOMENA: useAuth hook omogućava lako pristupanje AuthContext-u sa error handling-om.
 */

/* ============================================================================
 * 3. LOCAL STATE vs GLOBAL STATE - Kada se koristi šta
 * ============================================================================
 */

/*
 * 3.1. LOCAL STATE (useState)
 * -----------------------------
 * 
 * Usage: Component-specific state, UI state, form state
 * 
 * Examples:
 *   - LiveOrdersPage: orders, filteredOrders, selectedDate, statusFilter, viewMode
 *   - DashboardPage: showMobileFilters, showLocationDropdown, dateRange, filters
 *   - TrebovanjePage: radnje, selectedRadnja, searchTerm, selectedCategory, showCartModal
 *   - Sidebar: expandedMenus, userMenuOpen
 * 
 * When to Use:
 *   - State je specifičan za jedan component
 *   - State se ne deli između komponenti
 *   - UI state (modals, dropdowns, filters)
 *   - Form state (input values, validation)
 * 
 * NAPOMENA: Local state se koristi za component-specific state koji se ne deli.
 */

/*
 * 3.2. GLOBAL STATE (Zustand/Context)
 * -------------------------------------
 * 
 * Usage: Shared state across multiple components, authentication, flow state
 * 
 * Examples:
 *   - pazarAuthStore: Authentication state (shared across Pazar routes)
 *   - shiftFlowStore: Shift flow state (shared across flow steps)
 *   - AuthContext: Authentication state (shared across Admin routes)
 * 
 * When to Use:
 *   - State se deli između više komponenti
 *   - Authentication state
 *   - Multi-step flow state
 *   - User preferences
 * 
 * NAPOMENA: Global state se koristi za shared state koji se deli između komponenti.
 */

/*
 * 3.3. CUSTOM HOOKS (Local State Management)
 * --------------------------------------------
 * 
 * useCart Hook:
 *   - File: src/modules/magacin/hooks/useCart.js
 *   - State: cart (array)
 *   - Actions: addToCart, updateQuantity, removeFromCart, clearCart
 *   - Computed: totalItems, totalQuantity
 *   - Scope: Component-level (each component has its own cart)
 * 
 * useArtikli Hook:
 *   - File: src/modules/magacin/hooks/useArtikli.js
 *   - State: artikli, loading, error, stanje
 *   - Actions: loadArtikli, searchArtikli
 *   - Scope: Component-level (fetches data for selected radnja)
 * 
 * useAnalyticsData Hook:
 *   - File: src/modules/analytics/hooks/useAnalyticsData.js
 *   - State: loading, stats, hourlyData, locationData, etc.
 *   - Actions: loadData, refresh
 *   - Scope: Component-level (fetches analytics data)
 * 
 * NAPOMENA: Custom hooks encapsulate local state logic - reusable ali component-scoped.
 */

/*
 * 3.4. STATE SCOPE DECISION TREE
 * --------------------------------
 * 
 * Question 1: Da li se state deli između komponenti?
 *   - NO → Local state (useState)
 *   - YES → Continue
 * 
 * Question 2: Da li je state authentication-related?
 *   - YES → Context (AuthContext) ili Zustand (pazarAuthStore)
 *   - NO → Continue
 * 
 * Question 3: Da li je state multi-step flow?
 *   - YES → Zustand store (shiftFlowStore)
 *   - NO → Continue
 * 
 * Question 4: Da li je state user preferences?
 *   - YES → Zustand sa persist
 *   - NO → Local state ili Context
 * 
 * NAPOMENA: Decision tree olakšava odluku između local i global state.
 */

/* ============================================================================
 * 4. PERSISTENCE - Da li se nešto čuva u localStorage/sessionStorage
 * ============================================================================
 */

/*
 * 4.1. PERSISTENCE OVERVIEW
 * ---------------------------
 * 
 * Storage Types:
 *   1. localStorage: Persistent across browser sessions
 *   2. sessionStorage: Cleared on browser close
 *   3. Supabase Auth: localStorage (auto-managed)
 * 
 * NAPOMENA: Persistence se koristi za auth state i user preferences.
 */

/*
 * 4.2. ZUSTAND PERSIST (pazarAuthStore)
 * ---------------------------------------
 * 
 * Store: pazarAuthStore
 * Middleware: persist from 'zustand/middleware'
 * Storage: localStorage
 * Key: 'pazar-auth-storage'
 * 
 * Persisted Fields:
 *   - user: Object (pazar_users record)
 *   - session: Object (Supabase session)
 *   - isAuthenticated: boolean
 * 
 * Non-Persisted Fields:
 *   - searchResults: Array (ephemeral)
 *   - selectedUser: Object | null (ephemeral)
 *   - error: string | null (ephemeral)
 *   - failedAttempts: number (ephemeral)
 *   - lockedUntil: number | null (ephemeral)
 *   - selectedLocationId: UUID | null (ephemeral)
 * 
 * Partialize Function:
 *   partialize: (state) => ({
 *     user: state.user,
 *     session: state.session,
 *     isAuthenticated: state.isAuthenticated
 *   })
 * 
 * NAPOMENA: pazarAuthStore persisti samo auth state - ne persisti UI state.
 */

/*
 * 4.3. SUPABASE AUTH PERSISTENCE
 * --------------------------------
 * 
 * Configuration: src/lib/supabase.js
 *   persistSession: true
 *   autoRefreshToken: true
 *   detectSessionInUrl: true
 * 
 * Storage: localStorage
 * Key: 'supabase.auth.token'
 * 
 * Persisted Data:
 *   - access_token: JWT token
 *   - refresh_token: JWT token
 *   - expires_at: Timestamp
 *   - user: User object
 * 
 * Auto-Refresh:
 *   - Supabase automatski refresh-uje expired tokens
 *   - Session se automatski obnavlja
 * 
 * NAPOMENA: Supabase Auth automatski persisti session u localStorage.
 */

/*
 * 4.4. NO PERSISTENCE
 * ---------------------
 * 
 * Stores/State WITHOUT Persistence:
 *   - shiftFlowStore: Ephemeral (resetuje se na closeFlow)
 *   - useCart: Ephemeral (resetuje se na unmount)
 *   - useArtikli: Ephemeral (resetuje se na unmount)
 *   - useAnalyticsData: Ephemeral (resetuje se na unmount)
 *   - Local component state: Ephemeral (resetuje se na unmount)
 * 
 * NAPOMENA: Većina state-a je ephemeral - ne persisti se između sesija.
 */

/*
 * 4.5. PERSISTENCE STRATEGY
 * ---------------------------
 * 
 * What to Persist:
 *   - Authentication state (user, session)
 *   - User preferences (selected location, theme, etc.)
 * 
 * What NOT to Persist:
 *   - UI state (modals, dropdowns, filters)
 *   - Form state (input values, validation)
 *   - Flow state (multi-step flows)
 *   - Data fetching state (loading, error, data)
 * 
 * NAPOMENA: Persistence strategija - samo auth i preferences, ne UI/data state.
 */

/* ============================================================================
 * 5. STATE RESET - Kada i kako se resetuje state (logout, promena lokacije)
 * ============================================================================
 */

/*
 * 5.1. LOGOUT STATE RESET
 * ------------------------
 * 
 * AuthContext.logout():
 *   - supabase.auth.signOut()
 *   - setUser(null)
 *   - setSession(null)
 *   - setEmployee(null)
 *   - setPermissions([])
 *   - setLoading(false)
 * 
 * pazarAuthStore.logout():
 *   - supabase.auth.signOut()
 *   - set({ user: null, session: null, isAuthenticated: false, ... })
 *   - Clears: selectedUser, searchResults, error, failedAttempts, lockedUntil
 *   - Persisted state se automatski briše iz localStorage
 * 
 * NAPOMENA: Logout resetuje sve auth state - Context i Zustand stores.
 */

/*
 * 5.2. LOCATION CHANGE STATE RESET
 * -----------------------------------
 * 
 * pazarAuthStore.setSelectedLocationId():
 *   - set({ selectedLocationId: locationId })
 *   - Ne resetuje drugi state
 * 
 * DashboardPage (location change):
 *   - useEffect dependency: [selectedLocationId]
 *   - Resetuje: isDayClosed, currentShift, todayShifts, waitingHandover
 *   - Reload-uje: deposit, shifts data
 * 
 * NAPOMENA: Location change resetuje location-specific state ali ne auth state.
 */

/*
 * 5.3. FLOW STATE RESET
 * -----------------------
 * 
 * shiftFlowStore.closeFlow():
 *   - set(initialState)
 *   - Resetuje: isOpen, flowType, currentStep, denominations, ebarData, etc.
 * 
 * shiftFlowStore.openFlow():
 *   - Resetuje state pre inicijalizacije
 *   - Set-uje: shiftId, locationId, userId, deposit
 * 
 * NAPOMENA: Flow state se resetuje eksplicitno - closeFlow() ili openFlow().
 */

/*
 * 5.4. COMPONENT UNMOUNT STATE RESET
 * ------------------------------------
 * 
 * Automatic Reset:
 *   - Local state (useState) se automatski resetuje na unmount
 *   - Custom hooks (useCart, useArtikli) se resetuju na unmount
 *   - useEffect cleanup functions se izvršavaju na unmount
 * 
 * Manual Reset:
 *   - clearCart() u useCart hook
 *   - closeFlow() u shiftFlowStore
 *   - logout() u auth stores
 * 
 * NAPOMENA: Component unmount automatski resetuje local state - manual reset za global state.
 */

/*
 * 5.5. STATE RESET PATTERNS
 * ---------------------------
 * 
 * Pattern 1: Explicit Reset Function
 *   const resetState = () => {
 *     setState(initialState);
 *   };
 * 
 * Pattern 2: Reset on Action
 *   const handleAction = () => {
 *     // ... action logic ...
 *     setState(initialState); // Reset after action
 *   };
 * 
 * Pattern 3: Reset on Dependency Change
 *   useEffect(() => {
 *     setState(initialState);
 *     // ... load new data ...
 *   }, [dependency]);
 * 
 * NAPOMENA: State reset pattern-i zavise od use case-a - explicit, on action, ili on dependency.
 */

/* ============================================================================
 * 6. DERIVED STATE - Computed values, selektori
 * ============================================================================
 */

/*
 * 6.1. DERIVED STATE OVERVIEW
 * -----------------------------
 * 
 * Techniques:
 *   1. useMemo: Memoized computed values
 *   2. useCallback: Memoized functions
 *   3. Inline calculations: Direct computation in render
 *   4. Store actions: Computed values in Zustand stores
 * 
 * NAPOMENA: Derived state se koristi za computed values koji zavise od drugih state-a.
 */

/*
 * 6.2. USE MEMO PATTERNS
 * ------------------------
 * 
 * Example 1: Filtered Data (TrebovanjePage.jsx)
 *   const filteredArtikli = useMemo(() => {
 *     return artikli.filter(a => {
 *       // ... filter logic ...
 *     });
 *   }, [artikli, searchTerm, selectedCategory]);
 * 
 * Example 2: Low Stock Articles (TrebovanjePage.jsx)
 *   const lowStockArtikli = useMemo(() => {
 *     return artikli.filter(a => {
 *       const min = a.minStock ?? 0;
 *       return (cmAvailable < min && cmAvailable > 0) || (radnjaAvailable < min && radnjaAvailable > 0);
 *     });
 *   }, [artikli]);
 * 
 * Example 3: Status Counts (TrebovanjaListPage.jsx)
 *   const statusCounts = useMemo(() => {
 *     return trebovanja.reduce((acc, t) => {
 *       acc[t.status] = (acc[t.status] || 0) + 1;
 *       return acc;
 *     }, {});
 *   }, [trebovanja]);
 * 
 * NAPOMENA: useMemo se koristi za expensive computations koji zavise od dependencies.
 */

/*
 * 6.3. USE CALLBACK PATTERNS
 * ----------------------------
 * 
 * Example 1: Data Fetching (useArtikli.js)
 *   const loadArtikli = useCallback(async () => {
 *     // ... fetch logic ...
 *   }, [radnjaSifra]);
 * 
 * Example 2: Cart Actions (useCart.js)
 *   const addToCart = useCallback((artikal) => {
 *     setCart(prev => {
 *       // ... update logic ...
 *     });
 *   }, []);
 * 
 * Example 3: Orders Fetching (LiveOrdersPage.jsx)
 *   const fetchOrders = useCallback(async () => {
 *     // ... fetch logic ...
 *   }, [selectedDate]);
 * 
 * NAPOMENA: useCallback se koristi za memoized functions koji se prosleđuju kao props.
 */

/*
 * 6.4. INLINE CALCULATIONS
 * --------------------------
 * 
 * Example 1: Cart Totals (useCart.js)
 *   const totalItems = cart.length;
 *   const totalQuantity = cart.reduce((sum, item) => sum + item.kolicina, 0);
 * 
 * Example 2: Reconciliation (shiftFlowStore.js)
 *   const expectedCash = state.ebarData.cash - (state.ebarData.card || 0);
 *   const difference = state.countedAmount - expectedCash;
 * 
 * Example 3: Counted Amount (shiftFlowStore.js)
 *   const total = DENOMINATIONS.reduce((sum, d) => sum + (newDenoms[d] * d), 0);
 * 
 * NAPOMENA: Inline calculations se koriste za simple computations koji nisu expensive.
 */

/*
 * 6.5. STORE COMPUTED VALUES
 * ----------------------------
 * 
 * shiftFlowStore (Derived State):
 *   - countedAmount: Calculated in setDenomination, incrementDenom, decrementDenom
 *   - expectedCash: Calculated in calculateReconciliation
 *   - difference: Calculated in calculateReconciliation
 * 
 * Pattern:
 *   set((state) => {
 *     const computed = calculate(state);
 *     return { ...state, computed };
 *   });
 * 
 * NAPOMENA: Store computed values se računaju u store actions - automatski se update-uju.
 */

/*
 * 6.6. SELECTOR PATTERNS
 * ------------------------
 * 
 * Zustand Selectors:
 *   const user = usePazarAuthStore(state => state.user);
 *   const isAuthenticated = usePazarAuthStore(state => state.isAuthenticated);
 *   const { user, isAuthenticated } = usePazarAuthStore();
 * 
 * Context Selectors:
 *   const { user, employee, role } = useAuth();
 *   const canView = useAuth().canView('analytics');
 * 
 * NAPOMENA: Selectors omogućavaju selective subscription - samo potrebni state se subscribe-uje.
 */

/*
 * 6.7. DERIVED STATE BEST PRACTICES
 * -----------------------------------
 * 
 * DO:
 *   - Koristi useMemo za expensive computations
 *   - Koristi useCallback za functions koji se prosleđuju kao props
 *   - Računaj derived state u store actions (Zustand)
 *   - Koristi selectors za selective subscription
 * 
 * DON'T:
 *   - Ne koristi useMemo za simple calculations
 *   - Ne koristi useCallback za functions koji se ne prosleđuju
 *   - Ne dupliraj state (store both original i derived)
 * 
 * NAPOMENA: Derived state best practices osiguravaju optimal performance.
 */

/* ============================================================================
 * 7. STATE MANAGEMENT ARCHITECTURE
 * ============================================================================
 */

/*
 * 7.1. STATE MANAGEMENT LAYERS
 * ------------------------------
 * 
 * Layer 1: Global State (Zustand/Context)
 *   - Authentication (pazarAuthStore, AuthContext)
 *   - Flow state (shiftFlowStore)
 *   - Shared preferences
 * 
 * Layer 2: Custom Hooks (Local State)
 *   - useCart, useArtikli, useAnalyticsData
 *   - Component-scoped state management
 *   - Reusable logic
 * 
 * Layer 3: Component State (useState)
 *   - UI state (modals, dropdowns)
 *   - Form state (inputs, validation)
 *   - Component-specific data
 * 
 * NAPOMENA: State management layers organizuju state po scope-u i reusability.
 */

/*
 * 7.2. STATE FLOW DIAGRAM
 * -------------------------
 * 
 * Authentication Flow:
 *   User Login → AuthContext/pazarAuthStore → Supabase Auth → localStorage
 *   User Logout → Clear state → Clear localStorage
 * 
 * Data Flow:
 *   Component → Custom Hook → Service → Supabase → State Update → Component Re-render
 * 
 * Flow State:
 *   User Action → shiftFlowStore Action → State Update → Step Component Re-render
 *   Flow Complete → closeFlow() → Reset to initialState
 * 
 * NAPOMENA: State flow diagram prikazuje kako se state propagira kroz aplikaciju.
 */

/*
 * 7.3. STATE SYNCHRONIZATION
 * ----------------------------
 * 
 * Supabase Realtime:
 *   - LiveOrdersPage: supabase.channel().on('postgres_changes') → fetchOrders()
 *   - State se automatski update-uje na database changes
 * 
 * Auth State Sync:
 *   - AuthContext: supabase.auth.onAuthStateChange() → update state
 *   - pazarAuthStore: Manual sync via login/logout actions
 * 
 * NAPOMENA: State synchronization osigurava da state odgovara database state-u.
 */

/* ============================================================================
 * 8. STATE MANAGEMENT BEST PRACTICES
 * ============================================================================
 */

/*
 * 8.1. WHEN TO USE ZUSTAND
 * --------------------------
 * 
 * Use Zustand When:
 *   - State se deli između više komponenti
 *   - Potrebna je persistence
 *   - Multi-step flow state
 *   - Complex state logic
 * 
 * Don't Use Zustand When:
 *   - State je component-specific
 *   - Simple UI state
 *   - Form state
 * 
 * NAPOMENA: Zustand se koristi za complex shared state - ne za simple local state.
 */

/*
 * 8.2. WHEN TO USE CONTEXT
 * --------------------------
 * 
 * Use Context When:
 *   - Authentication state (global)
 *   - Theme preferences (global)
 *   - User preferences (global)
 * 
 * Don't Use Context When:
 *   - Frequently updating state (performance issues)
 *   - Complex state logic (use Zustand instead)
 *   - Component-specific state
 * 
 * NAPOMENA: Context se koristi za global state koji se retko menja - ne za frequently updating state.
 */

/*
 * 8.3. STATE OPTIMIZATION
 * -------------------------
 * 
 * Memoization:
 *   - useMemo za expensive computations
 *   - useCallback za functions koji se prosleđuju
 *   - React.memo za components (ako je potrebno)
 * 
 * Selective Subscription:
 *   - Zustand selectors za selective updates
 *   - Context value memoization (useMemo)
 * 
 * NAPOMENA: State optimization osigurava optimal performance - memoization i selective subscription.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
