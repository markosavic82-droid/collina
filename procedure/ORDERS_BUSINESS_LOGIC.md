/*
 * ============================================================================
 * ORDERS MODUL (Live Orders) - KOMPLETNA BIZNIS LOGIKA
 * ============================================================================
 * 
 * Ovaj dokument opisuje kompletnu biznis logiku ORDERS modula u Collina
 * platformi, uključujući real-time subscriptions, status flow, filtere,
 * lifecycle events i table discounts.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. REALTIME - Kako radi Supabase subscription za nove porudžbine
 * ============================================================================
 */

/*
 * 1.1. SUPABASE REALTIME SUBSCRIPTION
 * ------------------------------------
 * 
 * Komponenta: LiveOrdersPage.jsx
 * 
 * Setup:
 *   useEffect(() => {
 *     fetchOrders(); // Initial fetch
 *     
 *     const channel = supabase
 *       .channel('orders-changes')
 *       .on('postgres_changes', 
 *         { event: '*', schema: 'public', table: 'emeni_orders' },
 *         () => fetchOrders()
 *       )
 *       .subscribe();
 *     
 *     return () => {
 *       supabase.removeChannel(channel);
 *     };
 *   }, [fetchOrders]);
 * 
 * Event Types:
 *   - event: '*' (svi eventi: INSERT, UPDATE, DELETE)
 *   - schema: 'public'
 *   - table: 'emeni_orders'
 * 
 * Behavior:
 *   - Na svaku promenu u emeni_orders tabeli (INSERT, UPDATE, DELETE):
 *     → Poziva se fetchOrders() callback
 *     → fetchOrders() ponovo učitava sve porudžbine za izabrani datum
 *     → State se ažurira sa novim podacima
 *     → UI se re-renderuje sa novim podacima
 * 
 * Subscription Lifecycle:
 *   1. Component mount: subscription se kreira
 *   2. Na promenu: fetchOrders() se poziva
 *   3. Component unmount: subscription se uklanja (cleanup)
 * 
 * NAPOMENA: Subscription se re-kreira svaki put kada se fetchOrders promeni
 *           (npr. kada se promeni selectedDate). Ovo je dependency u useEffect.
 */

/*
 * 1.2. REALTIME UPDATE FLOW
 * --------------------------
 * 
 * Step 1: Nova porudžbina se kreira u emeni_orders
 *   - eMeni sistem ili eksterni servis INSERT-uje novi red
 *   - Supabase Realtime detektuje INSERT event
 * 
 * Step 2: Supabase Realtime emituje event
 *   - Event tip: 'INSERT'
 *   - Tabela: 'emeni_orders'
 *   - Payload: novi red podataka
 * 
 * Step 3: Subscription callback se aktivira
 *   - Callback: () => fetchOrders()
 *   - fetchOrders() se poziva
 * 
 * Step 4: fetchOrders() učitava podatke
 *   - Query: SELECT * FROM emeni_orders 
 *            WHERE created_at >= startUTC AND created_at < endUTC
 *            ORDER BY created_at DESC
 *   - Query lifecycle: SELECT * FROM emeni_order_lifecycle 
 *                      WHERE order_id IN (...)
 *   - Attach lifecycle events na orders
 * 
 * Step 5: State update
 *   - setOrders(data)
 *   - setLastUpdated(new Date())
 *   - setLoading(false)
 * 
 * Step 6: UI re-render
 *   - filteredOrders se recalculate-uje (useEffect sa filters)
 *   - Komponente se re-renderuju sa novim podacima
 *   - Live indicator prikazuje novo vreme ažuriranja
 * 
 * NAPOMENA: Realtime subscription je pasivan - samo osluškuje promene.
 *           Ne šalje komande nazad u bazu. Sve promene dolaze iz eMeni sistema.
 */

/*
 * 1.3. REALTIME PERFORMANCE
 * ---------------------------
 * 
 * Optimizacije:
 *   - Subscription se kreira samo jednom po component mount
 *   - fetchOrders() se poziva samo kada je potrebno (na promenu)
 *   - Date filtering ograničava broj učitavanih porudžbina
 *   - Lifecycle query koristi .in() za batch fetching
 * 
 * Potencijalni problemi:
 *   - Na svaku promenu se učitavaju SVE porudžbine za dan (nije incremental)
 *   - Ako ima puno porudžbina, fetchOrders() može biti spor
 *   - Multiple rapid changes mogu trigger-ovati multiple fetchOrders() calls
 * 
 * NAPOMENA: Trenutna implementacija je simple ali može biti optimizovana
 *           sa incremental updates ili debouncing.
 */

/* ============================================================================
 * 2. STATUS FLOW - Lifecycle porudžbine (od primanja do dostave)
 * ============================================================================
 */

/*
 * 2.1. STATUS KODOVI U EMENI_ORDERS
 * -----------------------------------
 * 
 * Status Mapping (STATUS_MAP):
 *   1  → 'new'        (Novo/Pending)
 *   3  → 'production' (Accepted/In Production)
 *   5  → 'ready'      (Ready for pickup/delivery)
 *   7  → 'paid'      (Delivered/Completed)
 *   8  → 'canceled'  (Canceled)
 *   9  → 'canceled'  (Rejected)
 *   11 → 'canceled'  (Rejected)
 * 
 * Status Labels (STATUS_LABELS):
 *   'new'        → 'Novo'
 *   'production' → 'Priprema'
 *   'ready'      → 'Spremno'
 *   'paid'       → 'Završeno'
 *   'canceled'   → 'Otkazano'
 * 
 * Status Colors (STATUS_STYLES):
 *   'new'        → bg: rgba(245,158,11,0.15), border: #F59E0B, text: #FBBF24
 *   'production' → bg: rgba(59,130,246,0.15), border: #3B82F6, text: #60A5FA
 *   'ready'      → bg: rgba(34,197,94,0.15), border: #22C55E, text: #4ADE80
 *   'paid'       → bg: rgba(16,185,129,0.15), border: #10B981, text: #34D399
 *   'canceled'   → bg: rgba(239,68,68,0.15), border: #EF4444, text: #F87171
 */

/*
 * 2.2. STATUS LIFECYCLE FLOW
 * ----------------------------
 * 
 * Normal Flow:
 *   1 (New) → 3 (Production) → 5 (Ready) → 7 (Paid)
 * 
 * Canceled Flow:
 *   1 (New) → 8/9/11 (Canceled)
 *   3 (Production) → 8/9/11 (Canceled)
 *   5 (Ready) → 8/9/11 (Canceled)
 * 
 * Step Details:
 * 
 * 1. NEW (status = 1):
 *    - Porudžbina je kreirana
 *    - Čeka prihvatanje
 *    - Može biti otkazana (→ 8/9/11)
 *    - Može biti prihvaćena (→ 3)
 * 
 * 2. PRODUCTION (status = 3):
 *    - Porudžbina je prihvaćena
 *    - U pripremi (kuhinja radi)
 *    - Može biti otkazana (→ 8/9/11)
 *    - Može biti spremna (→ 5)
 * 
 * 3. READY (status = 5):
 *    - Porudžbina je spremna
 *    - Čeka preuzimanje/dostavu
 *    - Može biti otkazana (→ 8/9/11)
 *    - Može biti isporučena (→ 7)
 * 
 * 4. PAID (status = 7):
 *    - Porudžbina je isporučena i plaćena
 *    - Finalni status (nema daljih promena)
 * 
 * 5. CANCELED (status = 8/9/11):
 *    - Porudžbina je otkazana
 *    - Finalni status (nema daljih promena)
 * 
 * NAPOMENA: Status promene se dešavaju u eMeni sistemu, ne u frontend-u.
 *           Frontend samo prikazuje trenutni status.
 */

/*
 * 2.3. STATUS TRANSITIONS
 * ------------------------
 * 
 * Valid Transitions:
 *   - 1 → 3 (New → Production)
 *   - 1 → 8/9/11 (New → Canceled)
 *   - 3 → 5 (Production → Ready)
 *   - 3 → 8/9/11 (Production → Canceled)
 *   - 5 → 7 (Ready → Paid)
 *   - 5 → 8/9/11 (Ready → Canceled)
 * 
 * Invalid Transitions:
 *   - 7 → bilo šta (Paid je finalni status)
 *   - 8/9/11 → bilo šta (Canceled je finalni status)
 *   - 5 → 3 (Ready → Production - nema nazad)
 *   - 3 → 1 (Production → New - nema nazad)
 * 
 * NAPOMENA: Status transitions se kontrolišu u eMeni sistemu, ne u frontend-u.
 *           Frontend samo prikazuje trenutni status bez validacije.
 */

/* ============================================================================
 * 3. FILTERI - Logika za tabove i filtere
 * ============================================================================
 */

/*
 * 3.1. STATUS FILTER (StatusTabs)
 * --------------------------------
 * 
 * Komponenta: StatusTabs.jsx
 * 
 * Filter Options:
 *   - 'all': Sve porudžbine (bez filtera)
 *   - 'new': Status = 1
 *   - 'production': Status = 3
 *   - 'ready': Status = 5
 *   - 'paid': Status = 7
 *   - 'canceled': Status = 8, 9, ili 11
 * 
 * Filter Logic:
 *   if (statusFilter !== 'all') {
 *     filtered = filtered.filter(o => STATUS_MAP[o.status] === statusFilter);
 *   }
 * 
 * Status Counts:
 *   - Računaju se iz SVIH porudžbina (ne iz filteredOrders)
 *   - Prikazuju se u tabovima kao badge
 *   - Ažuriraju se na svaku promenu orders state-a
 * 
 * NAPOMENA: Status filter je primarni filter - koristi se za brzo filtriranje
 *           po statusu porudžbine.
 */

/*
 * 3.2. LOCATION FILTER
 * ---------------------
 * 
 * Komponenta: OrdersFilterSidebar.jsx
 * 
 * Filter Options:
 *   - Checkbox za svaku lokaciju
 *   - Lokacije: Sweet Collina (128), Banovo Brdo (310), Pekarica (1513), itd.
 * 
 * Filter Logic:
 *   if (selectedLocations.size > 0) {
 *     filtered = filtered.filter(o => selectedLocations.has(String(o.company_id)));
 *   }
 * 
 * Default:
 *   - selectedLocations = new Set() (prazan set = sve lokacije)
 *   - Ako je prazan set, filter se ne primenjuje
 * 
 * NAPOMENA: Location filter je multi-select - može se selektovati više lokacija.
 */

/*
 * 3.3. CHANNEL FILTER
 * --------------------
 * 
 * Komponenta: OrdersFilterSidebar.jsx
 * 
 * Filter Options:
 *   - 'wolt': Wolt delivery
 *   - 'ebar': eBar (default)
 *   - 'gloriafood': Gloria Food
 *   - 'emeniwaiter': eMeni Waiter (dine-in)
 * 
 * Filter Logic:
 *   if (selectedChannels.size > 0 && selectedChannels.size < 4) {
 *     filtered = filtered.filter(o => {
 *       const provider = (o.provider || '').toLowerCase();
 *       if (provider === 'wolt') return selectedChannels.has('wolt');
 *       if (provider === 'ebar' || !provider) return selectedChannels.has('ebar');
 *       if (provider === 'gloriafood') return selectedChannels.has('gloriafood');
 *       if (provider === 'emeniwaiter') return selectedChannels.has('emeniwaiter');
 *       return true;
 *     });
 *   }
 * 
 * Default:
 *   - selectedChannels = new Set(['wolt', 'ebar', 'gloriafood', 'emeniwaiter'])
 *   - Ako su svi kanali selektovani, filter se ne primenjuje
 * 
 * NAPOMENA: Channel filter je multi-select - može se selektovati više kanala.
 */

/*
 * 3.4. TABLE FILTER
 * ------------------
 * 
 * Komponenta: LiveOrdersPage.jsx (dropdown u header-u)
 * 
 * Filter Options:
 *   - 'all': Svi stolovi
 *   - 'unknown': Nepoznati stolovi (nema table_id u tableDiscounts)
 *   - table_id (npr. 3086, 3087, itd.): Specifičan sto
 * 
 * Filter Logic:
 *   if (selectedTable !== 'all') {
 *     if (selectedTable === 'unknown') {
 *       // Show orders with unknown/no table
 *       filtered = filtered.filter(o => {
 *         const tableId = getTableId(o);
 *         if (!tableId) return true;
 *         const isKnownTable = tableOptions.some(t => t.id === tableId && t.id !== 'all' && t.id !== 'unknown');
 *         return !isKnownTable;
 *       });
 *     } else {
 *       filtered = filtered.filter(o => {
 *         const tableId = getTableId(o);
 *         return tableId === parseInt(selectedTable);
 *       });
 *     }
 *   }
 * 
 * Table Options:
 *   - Generišu se iz tableDiscounts (iz table_discounts tabele)
 *   - Sortiraju se po imenu (osim 'all' i 'unknown' koji su na vrhu)
 * 
 * NAPOMENA: Table filter omogućava filtriranje porudžbina po stolu.
 */

/*
 * 3.5. DISCOUNT FILTER
 * ----------------------
 * 
 * Komponenta: LiveOrdersPage.jsx (toggle button u header-u)
 * 
 * Filter Options:
 *   - showDiscountedOnly: true/false
 * 
 * Filter Logic:
 *   if (showDiscountedOnly) {
 *     filtered = filtered.filter(o => {
 *       const discountPercent = getOrderDiscountPercent(o, tableDiscounts);
 *       return discountPercent > 0;
 *     });
 *   }
 * 
 * Discount Count:
 *   - Računa se broj porudžbina sa popustom (> 0%)
 *   - Prikazuje se kao badge na toggle button-u
 * 
 * NAPOMENA: Discount filter omogućava prikaz samo porudžbina sa popustom.
 */

/*
 * 3.6. DATE FILTER
 * -----------------
 * 
 * Komponenta: LiveOrdersPage.jsx (date picker u header-u)
 * 
 * Filter Logic:
 *   - selectedDate: ISO date string (npr. '2026-01-17')
 *   - Date range: selectedDate 00:00:00+01:00 do selectedDate+1 00:00:00+01:00
 *   - Belgrade timezone: UTC+1
 * 
 * Query:
 *   const dateObj = new Date(selectedDate + 'T00:00:00+01:00');
 *   const startUTC = dateObj.toISOString();
 *   dateObj.setDate(dateObj.getDate() + 1);
 *   const endUTC = dateObj.toISOString();
 *   
 *   SELECT * FROM emeni_orders 
 *   WHERE created_at >= startUTC AND created_at < endUTC
 *   ORDER BY created_at DESC
 * 
 * Date Navigation:
 *   - Previous day: changeDate(-1)
 *   - Next day: changeDate(1)
 *   - Date picker: direktan unos datuma
 * 
 * NAPOMENA: Date filter je primarni filter - određuje koje porudžbine se učitavaju.
 */

/*
 * 3.7. FILTER COMBINATION
 * -------------------------
 * 
 * Filter Order (primena redosledom):
 *   1. Date filter (determiniše koje porudžbine se učitavaju)
 *   2. Location filter
 *   3. Channel filter
 *   4. Status filter
 *   5. Table filter
 *   6. Discount filter
 * 
 * Filter Logic (useEffect):
 *   let filtered = [...orders]; // Start sa svim porudžbinama za dan
 *   
 *   // Apply filters in order
 *   if (selectedLocations.size > 0) { ... }
 *   if (selectedChannels.size > 0 && selectedChannels.size < 4) { ... }
 *   if (statusFilter !== 'all') { ... }
 *   if (selectedTable !== 'all') { ... }
 *   if (showDiscountedOnly) { ... }
 *   
 *   setFilteredOrders(filtered);
 * 
 * NAPOMENA: Svi filteri se kombinuju sa AND logikom - porudžbina mora
 *           zadovoljiti SVE aktivne filtere.
 */

/* ============================================================================
 * 4. LIFECYCLE EVENTS - Kako se koristi emeni_order_lifecycle tabela
 * ============================================================================
 */

/*
 * 4.1. EMENI_ORDER_LIFECYCLE TABELA
 * -----------------------------------
 * 
 * Struktura:
 *   - order_id: TEXT (FK → emeni_orders.order_id)
 *   - status: INTEGER (3 = Accepted, 5 = Ready, 7 = Delivered)
 *   - timestamp: TIMESTAMP (kada je status promenjen)
 * 
 * Status Codes:
 *   3 = Accepted (Prihvaćeno - porudžbina je u pripremi)
 *   5 = Ready (Spremno - porudžbina je spremna za preuzimanje)
 *   7 = Delivered (Isporučeno - porudžbina je isporučena)
 * 
 * NAPOMENA: emeni_order_lifecycle čuva timeline promena statusa porudžbine.
 *           Svaka promena statusa (3, 5, 7) se loguje sa timestamp-om.
 */

/*
 * 4.2. LIFECYCLE DATA FETCHING
 * ------------------------------
 * 
 * Komponenta: LiveOrdersPage.jsx (fetchOrders function)
 * 
 * Step 1: Fetch orders
 *   SELECT * FROM emeni_orders 
 *   WHERE created_at >= startUTC AND created_at < endUTC
 *   ORDER BY created_at DESC
 * 
 * Step 2: Extract order IDs
 *   const orderIds = data.map(o => o.order_id).filter(Boolean);
 * 
 * Step 3: Fetch lifecycle data
 *   SELECT order_id, status, timestamp 
 *   FROM emeni_order_lifecycle 
 *   WHERE order_id IN (orderIds)
 * 
 * Step 4: Attach lifecycle to orders
 *   const lifecycleMap = {};
 *   lifecycle.forEach(l => {
 *     if (!lifecycleMap[l.order_id]) lifecycleMap[l.order_id] = [];
 *     lifecycleMap[l.order_id].push(l);
 *   });
 *   
 *   data.forEach(o => {
 *     o.lifecycle = lifecycleMap[o.order_id] || [];
 *   });
 * 
 * NAPOMENA: Lifecycle data se učitava batch-om za sve porudžbine odjednom.
 */

/*
 * 4.3. LIFECYCLE USAGE
 * ---------------------
 * 
 * Prep Time Calculation (OrdersTable.jsx):
 *   const calculatePrepTime = (order) => {
 *     if (!order.lifecycle || order.lifecycle.length === 0) return null;
 *     
 *     const accepted = order.lifecycle.find(e => e.status === 3);
 *     const ready = order.lifecycle.find(e => e.status === 5);
 *     
 *     if (accepted && ready) {
 *       const diff = (new Date(ready.timestamp) - new Date(accepted.timestamp)) / 60000;
 *       return Math.round(diff); // minutes
 *     }
 *     
 *     // If still in production, calculate from accepted to now
 *     if (accepted && !ready && order.status === 3) {
 *       const diff = (new Date() - new Date(accepted.timestamp)) / 60000;
 *       return Math.round(diff);
 *     }
 *     
 *     return null;
 *   };
 * 
 * Prep Time Display:
 *   - <= 5 min: zelena (rgba(34,197,94,0.15))
 *   - <= 10 min: žuta (rgba(245,158,11,0.15))
 *   - > 10 min: crvena (rgba(239,68,68,0.15))
 * 
 * Timeline Display (OrderDetailModal.jsx):
 *   - Prikazuje sve lifecycle events sortirane po timestamp-u
 *   - Format: timestamp + status label
 *   - Koristi se za debugging i tracking
 * 
 * NAPOMENA: Lifecycle events se koriste za izračunavanje prep time-a i
 *           prikaz timeline-a porudžbine.
 */

/*
 * 4.4. LIFECYCLE STATUS MAPPING
 * --------------------------------
 * 
 * emeni_orders.status → emeni_order_lifecycle.status:
 *   - emeni_orders.status = 1 → Nema lifecycle eventa (još nije prihvaćeno)
 *   - emeni_orders.status = 3 → emeni_order_lifecycle.status = 3 (Accepted)
 *   - emeni_orders.status = 5 → emeni_order_lifecycle.status = 5 (Ready)
 *   - emeni_orders.status = 7 → emeni_order_lifecycle.status = 7 (Delivered)
 *   - emeni_orders.status = 8/9/11 → Nema lifecycle eventa (otkazano)
 * 
 * NAPOMENA: Lifecycle events se kreiraju samo za status promene 3, 5, 7.
 *           Status 1 (New) i 8/9/11 (Canceled) nemaju lifecycle events.
 */

/* ============================================================================
 * 5. TABLE DISCOUNTS - Kako rade popusti po stolovima
 * ============================================================================
 */

/*
 * 5.1. TABLE_DISCOUNTS TABELA
 * ------------------------------
 * 
 * Struktura:
 *   - table_id: INTEGER (primary key)
 *   - filter_name: TEXT (ime stola, npr. 'Hotel Zaposleni')
 *   - discount_percent: INTEGER (procenat popusta, npr. 40)
 *   - is_active: BOOLEAN (da li je popust aktivan)
 * 
 * Query:
 *   SELECT table_id, filter_name, discount_percent 
 *   FROM table_discounts 
 *   WHERE is_active = true
 * 
 * NAPOMENA: table_discounts tabela čuva popuste po stolovima.
 */

/*
 * 5.2. FETCH TABLE DISCOUNTS
 * ---------------------------
 * 
 * Funkcija: fetchTableDiscounts() (ordersService.js)
 * 
 * Flow:
 *   1. Query Supabase: SELECT * FROM table_discounts WHERE is_active = true
 *   2. Convert to lookup object: { tableId: { name, percent } }
 *   3. Merge sa fallback discounts (TABLE_DISCOUNTS)
 *   4. Return merged discounts
 * 
 * Fallback:
 *   - Ako query fail-uje, koristi se hardcoded TABLE_DISCOUNTS
 *   - TABLE_DISCOUNTS ima default popuste za poznate stolove
 * 
 * Fallback Discounts (TABLE_DISCOUNTS):
 *   3086: { name: 'Hotel Gosti', percent: 0 }
 *   3087: { name: 'Hotel Zaposleni', percent: 40 }
 *   3088: { name: 'EPS', percent: 10 }
 *   3090: { name: 'TO Kuhinja', percent: 99 }
 *   3092: { name: 'TO Šank 1', percent: 50 }
 *   3093: { name: 'Nataša', percent: 99 }
 *   3094: { name: 'Ana', percent: 99 }
 *   3095: { name: 'Marko', percent: 99 }
 *   3097: { name: 'TO Magazin', percent: 50 }
 *   3098: { name: 'TO Vozači', percent: 50 }
 *   3100: { name: 'TO Kancelarija', percent: 70 }
 *   3105: { name: 'Cervesia Poli', percent: 30 }
 * 
 * NAPOMENA: Fallback discounts osiguravaju da aplikacija radi čak i ako
 *           query fail-uje ili tabela je prazna.
 */

/*
 * 5.3. GET TABLE ID FROM ORDER
 * -----------------------------
 * 
 * Funkcija: getTableId(order) (ordersService.js)
 * 
 * Logic (redosled provere):
 *   1. order.table_id (direktno polje)
 *   2. order.raw_payload.waiter.tableReferenceID
 *   3. order.raw_payload.table.id
 *   4. order.table_number (ako je numeric)
 * 
 * Return:
 *   - table_id (INTEGER) ili null (ako nije pronađen)
 * 
 * NAPOMENA: getTableId() pokušava da pronađe table_id iz različitih izvora
 *           jer različiti sistemi (eBar, Wolt, itd.) čuvaju table_id na različite načine.
 */

/*
 * 5.4. GET ORDER DISCOUNT
 * -------------------------
 * 
 * Funkcija: getOrderDiscount(order, tableDiscounts) (ordersService.js)
 * 
 * Logic:
 *   1. tableId = getTableId(order)
 *   2. Ako !tableId ili !tableDiscounts: return { percent: 0, name: null }
 *   3. discount = tableDiscounts[tableId]
 *   4. return discount || { percent: 0, name: null }
 * 
 * Return:
 *   { percent: INTEGER, name: TEXT }
 * 
 * NAPOMENA: getOrderDiscount() vraća popust za porudžbinu na osnovu stola.
 */

/*
 * 5.5. DISCOUNT CALCULATION
 * --------------------------
 * 
 * Komponenta: OrdersTable.jsx
 * 
 * Calculation:
 *   const tableDiscount = getOrderDiscount(order, tableDiscounts);
 *   const discountPercent = tableDiscount.percent || 0;
 *   const discountAmount = total * (discountPercent / 100);
 *   const finalPrice = total - discountAmount;
 * 
 * Display:
 *   - Total: originalna cena (formatCurrency(total))
 *   - Discount: procenat popusta (npr. "40%")
 *   - Final Price: finalna cena posle popusta (formatCurrency(finalPrice))
 *   - Discount Amount: iznos popusta (npr. "-400 RSD")
 * 
 * Discount Styling:
 *   - discountPercent >= 50: crvena (rgba(239,68,68,0.2))
 *   - discountPercent < 50: žuta (rgba(245,158,11,0.2))
 * 
 * NAPOMENA: Discount se primenjuje na total cenu porudžbine.
 */

/*
 * 5.6. TABLE OPTIONS GENERATION
 * --------------------------------
 * 
 * Komponenta: LiveOrdersPage.jsx (useEffect za loadTableData)
 * 
 * Flow:
 *   1. Fetch table discounts
 *   2. Build table options array:
 *      - { id: 'all', name: 'Svi stolovi', icon: '✓' }
 *      - { id: 'unknown', name: 'Ostalo (nepoznati)', icon: '⚠️' }
 *      - { id: tableId, name: discount.name, discount: discount.percent }
 *   3. Sort by name (osim 'all' i 'unknown' koji su na vrhu)
 *   4. setTableOptions(options)
 * 
 * Table Options Usage:
 *   - Koristi se u dropdown filter-u
 *   - Prikazuje sve dostupne stolove sa popustima
 *   - Omogućava filtriranje po stolu
 * 
 * NAPOMENA: Table options se generišu iz table discounts.
 */

/* ============================================================================
 * 6. DODATNE NAPOMENE
 * ============================================================================
 */

/*
 * 6.1. ORDER TOTAL CALCULATION
 * ------------------------------
 * 
 * Funkcija: getOrderTotal(order) (LiveOrdersPage.jsx, OrdersTable.jsx)
 * 
 * Logic (redosled provere):
 *   1. order.total (direktno polje)
 *   2. order.order_total
 *   3. order.amount
 *   4. order.raw_payload.total
 *   5. Calculate from order.items (sum of price * quantity)
 *   6. Calculate from order.raw_payload.items
 * 
 * Return:
 *   - total (FLOAT) ili 0
 * 
 * NAPOMENA: getOrderTotal() pokušava da pronađe total iz različitih izvora
 *           jer različiti sistemi čuvaju total na različite načine.
 */

/*
 * 6.2. VIEW MODES
 * -----------------
 * 
 * View Modes:
 *   - 'cards': Grid layout sa OrderCard komponentama
 *   - 'table': Table layout sa OrdersTable komponentom
 * 
 * Toggle:
 *   - View toggle buttons u header-u
 *   - setViewMode('cards') ili setViewMode('table')
 * 
 * NAPOMENA: View modes omogućavaju različite načine prikaza porudžbina.
 */

/*
 * 6.3. ORDER DETAIL MODAL
 * -------------------------
 * 
 * Komponenta: OrderDetailModal.jsx
 * 
 * Features:
 *   - Prikazuje kompletnu informaciju o porudžbini
 *   - Order note (ako postoji)
 *   - Order information (status, vreme, lokacija, kanal)
 *   - Staff & Table (konobar, sto)
 *   - Customer information
 *   - Items sa modifiers
 *   - Total
 *   - Timestamps (created, accepted, ready, delivered, completed)
 *   - Order lifecycle timeline
 *   - Raw payload JSON (collapsible)
 * 
 * NAPOMENA: OrderDetailModal omogućava detaljan pregled porudžbine.
 */

/*
 * 6.4. LOCATION MAPPING
 * ----------------------
 * 
 * Hardcoded Mapping (LOCATION_NAMES):
 *   128: 'Sweet Collina'
 *   310: 'Banovo Brdo'
 *   1513: 'Pekarica'
 *   1514: 'Novi Beograd'
 *   2120: 'Vračar'
 *   2165: 'Greška'
 *   2166: 'Food Truck'
 *   2209: 'Kuhinjica'
 * 
 * Usage:
 *   - Prikazuje se u OrderCard, OrdersTable, OrderDetailModal
 *   - locationName = LOCATION_NAMES[order.company_id]
 * 
 * NAPOMENA: Location mapping je hardcoded - trebalo bi biti u bazi.
 */

/*
 * 6.5. PROVIDER/CHANNEL MAPPING
 * -------------------------------
 * 
 * Provider Values:
 *   - 'wolt': Wolt delivery
 *   - 'ebar': eBar (default ako nema provider)
 *   - 'gloriafood': Gloria Food
 *   - 'emeniwaiter': eMeni Waiter (dine-in)
 * 
 * Provider Styling:
 *   - wolt: bg: #3B82F6, text: #fff
 *   - ebar: bg: #8B5CF6, text: #fff
 *   - gloriafood: bg: #F59E0B, text: #000
 *   - emeniwaiter: bg: #EC4899, text: #fff
 * 
 * NAPOMENA: Provider određuje kanal porudžbine i stil prikaza.
 */

/*
 * 6.6. STATS DISPLAY
 * -------------------
 * 
 * Stats (u header-u):
 *   - Porudžbine: filteredOrders.length
 *   - Ukupno: sum of getOrderTotal(order) za sve filteredOrders
 * 
 * Format:
 *   - Porudžbine: {count}
 *   - Ukupno: {total} RSD (formatCurrency)
 * 
 * NAPOMENA: Stats se računaju iz filteredOrders, ne iz orders.
 */

/*
 * 6.7. LIVE INDICATOR
 * ---------------------
 * 
 * Display:
 *   - Zeleni pulsirajući dot (animate-pulse)
 *   - "Live" label
 *   - Last updated time (toLocaleTimeString)
 * 
 * Update:
 *   - setLastUpdated(new Date()) nakon fetchOrders()
 * 
 * NAPOMENA: Live indicator pokazuje da je aplikacija povezana sa real-time updates.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
