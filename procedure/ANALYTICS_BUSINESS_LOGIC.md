/*
 * ============================================================================
 * ANALYTICS MODUL - KOMPLETNA BIZNIS LOGIKA
 * ============================================================================
 * 
 * Ovaj dokument opisuje kompletnu biznis logiku Analytics modula u Collina
 * platformi, uključujući data flow, kalkulacije, status kodove, normalizaciju
 * podataka, filtriranje i arhitekturu komponenti.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. DATA FLOW - Kako se podaci učitavaju i transformišu
 * ============================================================================
 */

/*
 * 1.1. INICIJALNI DATA FLOW
 * -------------------------
 * 
 * Hook: useAnalyticsData (src/modules/analytics/hooks/useAnalyticsData.js)
 * 
 * Tok podataka:
 * 
 * 1. DashboardPage.jsx poziva useAnalyticsData(dateRange, filters, trendPeriod)
 *    - dateRange: { startDate, endDate } - Date objekti ili YYYY-MM-DD stringovi
 *    - filters: { locations: [], channels: [] } - nizovi ID-jeva
 *    - trendPeriod: '7d' | '14d' | '30d' | '60d' | '90d'
 * 
 * 2. useAnalyticsData.loadData() se izvršava:
 *    a) Formatira datume u YYYY-MM-DD format
 *    b) Paralelno učitava (Promise.all):
 *       - fetchLocations() -> emeni_locations (company_id, location_name)
 *       - fetchOrders(startDate, endDate) -> emeni_orders sa paginacijom
 *       - fetchMargins() -> product_margins (product_name, margin_pct, cost_per_unit)
 * 
 * 3. Nakon što se orders učitaju:
 *    a) Ekstraktuje order_id vrednosti iz orders
 *    b) Poziva fetchOrderLifecycle(orderIds) -> emeni_order_lifecycle
 *    c) Mapira lifecycle events na orders:
 *       - Kreira lifecycleMap: { order_id: [{ status, timestamp }, ...] }
 *       - Dodaje order.lifecycle = lifecycleMap[order.order_id] || []
 * 
 * 4. Poziva processOrders(orders, locations, margins, filters):
 *    a) Filtrira otkazane porudžbine (status 8, 9, 11)
 *    b) Aplicira location filter (ako nisu sve lokacije izabrane)
 *    c) Aplicira channel filter (ako nisu svi kanali izabrani)
 *    d) Kalkuliše agregate (revenue, orders, avgBasket, profit)
 *    e) Procesira stavke po kategorijama
 *    f) Kalkuliše hourly data (8h-22h)
 *    g) Kalkuliše location stats
 *    h) Kalkuliše heatmap data (location × hour)
 * 
 * 5. Paralelno učitava dodatne podatke:
 *    - fetchProjectionData(endDate, filteredOrders) -> wolt_orders za projekciju
 *    - fetchTrendOrders(trendStartStr, trendEndStr) -> emeni_orders za trend
 *    - fetchLocationPerformance(startDate, endDate) -> emeni_orders za location perf
 *    - calculateChannelMix(orders) -> procesira orders za channel mix
 * 
 * 6. State se ažurira sa svim podacima
 * 
 * 7. Komponente primaju podatke preko props i renderuju
 */

/*
 * 1.2. DATE RANGE FILTERING
 * -------------------------
 * 
 * Utility: getDateRangeFilter (src/modules/analytics/utils/dateFilters.js)
 * 
 * Logika:
 * - Prima startDate i endDate (Date objekat ili YYYY-MM-DD string)
 * - Konvertuje u Belgrade timezone (UTC+1):
 *   - start: `${startDate}T00:00:00+01:00` -> UTC ISO string
 *   - end: `${endDate}T23:59:59+01:00` -> UTC ISO string
 * - Vraća { start, end } UTC ISO stringove za Supabase .gte() i .lte()
 * 
 * Primer:
 *   Input: startDate='2026-01-17', endDate='2026-01-17'
 *   Output: {
 *     start: '2026-01-16T23:00:00.000Z',  // 00:00 Belgrade = 23:00 UTC prethodnog dana
 *     end: '2026-01-17T22:59:59.000Z'      // 23:59 Belgrade = 22:59 UTC istog dana
 *   }
 */

/*
 * 1.3. PAGINATION
 * --------------
 * 
 * Utility: fetchAllPaginated (src/modules/analytics/utils/supabasePagination.js)
 * 
 * Problem: Supabase ima default limit od 1000 redova
 * Rešenje: Automatska paginacija sa .range(offset, offset + limit - 1)
 * 
 * Logika:
 * - Počinje sa offset=0, limit=1000
 * - Dok ima podataka:
 *   a) Poziva queryBuilder.range(offset, offset + limit - 1)
 *   b) Dodaje rezultate u allData
 *   c) Ako data.length < limit, završava
 *   d) Ako allData.length >= maxRows (default 50000), završava
 *   e) Inkrementira offset += limit
 * 
 * Koristi se u:
 * - fetchOrders() -> maxRows: 50000
 * - fetchTrendOrders() -> maxRows: 10000 (safety limit)
 * - fetchLocationPerformance() -> maxRows: 10000
 */

/*
 * 1.4. ORDER LIFECYCLE ATTACHMENT
 * --------------------------------
 * 
 * Problem: emeni_orders i emeni_order_lifecycle su odvojene tabele
 * Rešenje: JOIN u memoriji nakon fetch-a
 * 
 * Logika:
 * 1. fetchOrderLifecycle(orderIds) vraća:
 *    [{ order_id, status, timestamp }, ...]
 * 
 * 2. Kreira se lifecycleMap:
 *    const lifecycleMap = {};
 *    lifecycleData.forEach(lc => {
 *      if (!lifecycleMap[lc.order_id]) lifecycleMap[lc.order_id] = [];
 *      lifecycleMap[lc.order_id].push({ status: lc.status, timestamp: lc.timestamp });
 *    });
 * 
 * 3. Svaki order dobija lifecycle array:
 *    orders.forEach(order => {
 *      order.lifecycle = lifecycleMap[order.order_id] || [];
 *    });
 * 
 * 4. Status kodovi u lifecycle:
 *    - 3 = Accepted (prihvaćeno)
 *    - 5 = Ready (spremno)
 *    - 7 = Delivered (isporučeno)
 */

/* ============================================================================
 * 2. KALKULACIJE - Formule za KPI, projekcije, vreme pripreme/dostave
 * ============================================================================
 */

/*
 * 2.1. ORDER TOTAL KALKULACIJA
 * -----------------------------
 * 
 * Funkcija: getOrderTotal(order) (analyticsService.js)
 * 
 * Prioritet izvora:
 * 1. order.total (direktno polje)
 * 2. order.order_total (alternativno polje)
 * 3. order.amount (alternativno polje)
 * 4. order.raw_payload.total
 * 5. order.raw_payload.orderTotal
 * 6. order.raw_payload.amount
 * 7. Kalkulacija iz order.items:
 *    - Za svaki item: (item.price * item.quantity)
 *    - Dodaje modifiers: item.modifiers.forEach(mod => {
 *        itemTotal += (mod.price * mod.quantity * item.quantity)
 *      })
 * 
 * Formula:
 *   orderTotal = sum(item.price * item.quantity + sum(mod.price * mod.quantity * item.quantity))
 */

/*
 * 2.2. KPI KALKULACIJE
 * ---------------------
 * 
 * Funkcija: processOrders() -> stats objekt
 * 
 * REVENUE (Prihod):
 *   totalRevenue = sum(getOrderTotal(order)) za sve validne orders
 *   Validni orders = status NOT IN (8, 9, 11) + location filter + channel filter
 * 
 * ORDERS (Porudžbine):
 *   totalOrders = count(validOrders)
 * 
 * AVG BASKET (Prosečna Korpa):
 *   avgBasket = totalRevenue / totalOrders
 *   Ako totalOrders === 0, avgBasket = 0
 * 
 * PROFIT (Profit):
 *   Za svaki proizvod u productCounts:
 *     - Ako postoji marginData iz product_margins:
 *       profit = revenue * (margin_pct / 100)
 *     - Ako ne postoji marginData:
 *       profit = revenue * 0.7  // Default 70% margin
 *   totalProfit = sum(profit) za sve proizvode
 * 
 * PREP TIME (Vreme Pripreme):
 *   Za svaki order sa lifecycle:
 *     - acceptedTime = lifecycle event sa status=3 (Accepted)
 *     - readyTime = lifecycle event sa status=5 (Ready)
 *     - prepTime = (readyTime - acceptedTime) / 60000  // u minutama
 *     - Validno ako: prepTime > 0 && prepTime < 120
 *   avgPrepTime = sum(prepTimes) / count(prepTimes)
 * 
 * DELIVERY TIME (Vreme Dostave):
 *   Za svaki order sa lifecycle:
 *     - readyTime = lifecycle event sa status=5 (Ready)
 *     - deliveredTime = lifecycle event sa status=7 (Delivered)
 *     - deliveryTime = (deliveredTime - readyTime) / 60000  // u minutama
 *     - Validno ako: deliveryTime > 0 && deliveryTime < 180
 *   avgDeliveryTime = sum(deliveryTimes) / count(deliveryTimes)
 */

/*
 * 2.3. HOURLY DATA KALKULACIJA
 * -----------------------------
 * 
 * Funkcija: processOrders() -> hourlyData array
 * 
 * Struktura:
 *   hourlyMap = {
 *     8: { hour: 8, orders: 0, prepTimes: [], deliveryTimes: [], burger: 0, pancake: 0, ... },
 *     9: { ... },
 *     ...
 *     22: { ... }
 *   }
 * 
 * Za svaki order:
 * 1. orderDate = new Date(order.created_at)
 * 2. hour = orderDate.getHours()  // 8-22
 * 3. hourlyMap[hour].orders += 1
 * 
 * 4. Za svaki item u order:
 *    - category = classifyItem(item.name)
 *    - hourlyMap[hour][category] += item.quantity
 * 
 * 5. Ako order ima lifecycle:
 *    - prepTime = (readyTime - acceptedTime) / 60000
 *    - Ako prepTime validno: hourlyMap[hour].prepTimes.push(prepTime)
 *    - deliveryTime = (deliveredTime - readyTime) / 60000
 *    - Ako deliveryTime validno: hourlyMap[hour].deliveryTimes.push(deliveryTime)
 * 
 * Finalna transformacija:
 *   hourlyData = Object.values(hourlyMap).map(h => ({
 *     hour: h.hour,
 *     orders: h.orders,
 *     avgPrepTime: h.prepTimes.length > 0 
 *       ? Math.round((sum(h.prepTimes) / h.prepTimes.length) * 10) / 10
 *       : 0,
 *     avgDeliveryTime: h.deliveryTimes.length > 0
 *       ? Math.round((sum(h.deliveryTimes) / h.deliveryTimes.length) * 10) / 10
 *       : 0,
 *     burger: h.burger,
 *     pancake: h.pancake,
 *     ...
 *   }))
 */

/*
 * 2.4. PROJECTION KALKULACIJA
 * ----------------------------
 * 
 * Funkcija: fetchProjectionData(selectedDate, todayOrders)
 * 
 * Cilj: Projekcija današnjeg prihoda na osnovu istorijskih podataka istog dana u nedelji
 * 
 * Logika:
 * 1. Određuje dan u nedelji za selectedDate (0=Nedelja, 1=Ponedeljak, ...)
 * 2. Pronalazi sve datume istog dana u nedelji između 2025-10-01 i 2025-12-05
 * 3. Učitava wolt_orders za te datume
 * 4. Za svaki istorijski dan:
 *    - Grupiše po satu (Belgrade timezone UTC+1)
 *    - Kalkuliše cumulative revenue od 10:00 do svakog sata
 * 
 * 5. Kalkuliše BEST, WORST, AVERAGE:
 *    - bestDate = dan sa najvećim total.revenue
 *    - worstDate = dan sa najmanjim total.revenue
 *    - avgHourly[h] = prosek cumulative revenue za sat h preko svih dana
 * 
 * 6. Za današnji dan (ako je selectedDate === today):
 *    - todayHourly[h] = cumulative revenue do sata h
 *    - currentHour = trenutni sat (Belgrade time)
 *    - todayCumRev = cumulative revenue do currentHour
 * 
 * 7. PROJEKCIJA FORMULA:
 *    - baselineHour = currentHour >= 10 ? currentHour : 10
 *    - avgAtCurrentHour = avgHourly[baselineHour].revenue
 *    - avgTotal = avgHourly[23].revenue  // Total za ceo dan (10:00-23:59)
 *    - percentComplete = avgTotal > 0 ? avgAtCurrentHour / avgTotal : 0
 *    - projectedRev = percentComplete > 0 ? todayCumRev / percentComplete : todayCumRev
 * 
 * Primer:
 *   - avgTotal = 100,000 RSD (prosek za ceo dan)
 *   - avgAtCurrentHour (14h) = 40,000 RSD (prosek do 14h)
 *   - percentComplete = 40,000 / 100,000 = 0.4 (40%)
 *   - todayCumRev (do 14h) = 45,000 RSD
 *   - projectedRev = 45,000 / 0.4 = 112,500 RSD
 * 
 * 8. Chart data struktura:
 *    - best: cumulative revenue za bestDate
 *    - worst: cumulative revenue za worstDate
 *    - average: avgHourly[h].revenue
 *    - today: todayCumulative (samo za sate <= currentHour)
 *    - projection: projekcija linija (samo za today, od baselineHour)
 */

/*
 * 2.5. CATEGORY CLASSIFICATION
 * -----------------------------
 * 
 * Funkcija: classifyItem(itemName)
 * 
 * Kategorije:
 * - burger: BURGER_KEYWORDS = ['burger', 'smash', 'collina', 'chicken', 'wrap', ...]
 * - pancake: PANCAKE_KEYWORDS = ['palačink', 'palacink', 'nutella', ...]
 * - cooked: COOKED_KEYWORDS = ['porcija', 'musaka', 'kupus', 'cufte', ...]
 * - sides: SIDES_KEYWORDS = ['pomfrit', 'salata', 'pire', ...]
 * - bakery: BAKERY_KEYWORDS = ['kiflice', 'kiflica', 'pita sir', ...]
 * - drinks: DRINKS_KEYWORDS = ['pepsi', 'coca', 'cola', 'sok', ...]
 * - other: ako nijedan keyword ne odgovara
 * 
 * Logika:
 *   const n = (itemName || '').toLowerCase();
 *   for (const kw of CATEGORY_KEYWORDS) {
 *     if (n.includes(kw)) return 'category';
 *   }
 *   return 'other';
 */

/*
 * 2.6. CHANNEL MIX KALKULACIJA
 * -----------------------------
 * 
 * Funkcija: calculateChannelMix(orders)
 * 
 * Kanali:
 * - wolt: provider === 'wolt'
 * - ebar: provider === 'ebar' || provider === '' || provider.includes('emeni')
 * - gloriafood: provider === 'gloriafood'
 * - emeniwaiter: provider === 'emeniwaiter'
 * 
 * Za svaki kanal:
 *   - revenue = sum(getOrderTotal(order)) za orders sa tim provider-om
 *   - orders = count(orders) sa tim provider-om
 *   - avgBasket = revenue / orders
 * 
 * Fee percentages:
 *   - wolt: 11.8% fee
 *   - ebar: 0% fee
 *   - gloriafood: 15% fee
 *   - emeniwaiter: 0% fee
 * 
 * Net revenue:
 *   netRevenue = revenue * (1 - feePercent / 100)
 */

/* ============================================================================
 * 3. STATUS KODOVI - Šta znače status kodovi u emeni_orders
 * ============================================================================
 */

/*
 * 3.1. STATUS KODOVI U EMENI_ORDERS
 * ----------------------------------
 * 
 * Tabela: emeni_orders.status (INTEGER)
 * 
 * Validni statusi (ne otkazani):
 * - 1: NEW / PENDING (Nova porudžbina, čeka prihvatanje)
 * - 3: PRODUCTION / ACCEPTED (Prihvaćena, u pripremi)
 * - 5: READY (Spremna za preuzimanje/dostavu)
 * - 7: PAID / DELIVERED (Isporučena/Završena)
 * 
 * Otkazani statusi (filtrirani iz kalkulacija):
 * - 8: CANCELED (Otkazana)
 * - 9: REJECTED (Odbijena)
 * - 11: REJECTED (Alternativni kod za odbijenu)
 * 
 * Filter logika:
 *   validOrders = orders.filter(o => ![8, 9, 11].includes(o.status))
 */

/*
 * 3.2. STATUS KODOVI U EMENI_ORDER_LIFECYCLE
 * -------------------------------------------
 * 
 * Tabela: emeni_order_lifecycle.status (INTEGER)
 * 
 * Statusi:
 * - 3: ACCEPTED (Prihvaćena - timestamp kada je porudžbina prihvaćena)
 * - 5: READY (Spremna - timestamp kada je porudžbina spremna)
 * - 7: DELIVERED (Isporučena - timestamp kada je porudžbina isporučena)
 * 
 * Upotreba:
 * - Prep time = readyTime (status=5) - acceptedTime (status=3)
 * - Delivery time = deliveredTime (status=7) - readyTime (status=5)
 */

/* ============================================================================
 * 4. NORMALIZACIJA - Kako se wolt_orders (2025) mapira na emeni_orders (2026+)
 * ============================================================================
 */

/*
 * 4.1. WOLT_ORDERS STRUKTURA (2025 i ranije)
 * -------------------------------------------
 * 
 * Tabela: wolt_orders
 * 
 * Polja:
 * - amount: INTEGER (cena u centima/parama, treba podeliti sa 100)
 * - venue_name: TEXT (naziv lokacije)
 * - order_status: TEXT ('rejected', 'cancelled', ili drugi)
 * - created_at: TIMESTAMP
 * 
 * Primer:
 *   {
 *     amount: 85000,        // 850.00 RSD
 *     venue_name: "Sweet Collina",
 *     order_status: "delivered",
 *     created_at: "2025-10-15T12:30:00Z"
 *   }
 */

/*
 * 4.2. EMENI_ORDERS STRUKTURA (2026+)
 * ------------------------------------
 * 
 * Tabela: emeni_orders
 * 
 * Polja:
 * - total: DECIMAL (cena u RSD)
 * - order_total: DECIMAL (alternativno polje za cenu)
 * - company_id: INTEGER (ID lokacije)
 * - provider: TEXT ('wolt', 'ebar', 'gloriafood', 'emeniwaiter')
 * - status: INTEGER (1, 3, 5, 7, 8, 9, 11)
 * - created_at: TIMESTAMP
 * - raw_payload: JSONB (kompletan payload sa items, customer, itd.)
 * 
 * Primer:
 *   {
 *     total: 850.00,
 *     company_id: 128,
 *     provider: "wolt",
 *     status: 7,
 *     created_at: "2026-01-17T12:30:00Z",
 *     raw_payload: { items: [...], customer: {...} }
 *   }
 */

/*
 * 4.3. NORMALIZACIJA FUNKCIJA
 * ----------------------------
 * 
 * Funkcija: fetchComparisonOrders() -> normalizacija wolt_orders
 * 
 * Logika:
 * 1. Proverava godinu: startYear = new Date(startDate).getFullYear()
 * 2. Ako startYear < 2026: koristi wolt_orders
 * 3. Ako startYear >= 2026: koristi emeni_orders
 * 
 * 4. Normalizacija wolt_orders -> emeni_orders format:
 *    allData = allData.map(o => ({
 *      ...o,
 *      // Konverzija cene iz centi u RSD
 *      total: (o.amount || 0) / 100,
 *      order_total: (o.amount || 0) / 100,
 *      // Mapiranje venue_name na company_id (za sada ostaje kao string)
 *      company_id: o.venue_name,
 *      // Mapiranje order_status na status kod
 *      status: (o.order_status === 'rejected' || o.order_status === 'cancelled') ? 8 : 1,
 *      // Provider je uvek 'wolt' za wolt_orders
 *      provider: 'wolt',
 *      // Ostaje created_at
 *      created_at: o.created_at,
 *    }));
 * 
 * 5. Rezultat: wolt_orders ima isti format kao emeni_orders, može se koristiti
 *    u processTrend() i drugim funkcijama bez dodatnih izmena
 */

/* ============================================================================
 * 5. FILTRIRANJE - Logika za lokacije i kanale
 * ============================================================================
 */

/*
 * 5.1. LOCATION FILTERING
 * ------------------------
 * 
 * Funkcija: processOrders() -> location filter
 * 
 * Logika:
 * 1. Učitava sve lokacije iz emeni_locations:
 *    locations = { company_id: location_name, ... }
 * 
 * 2. Ako filters.locations.length === 0 ILI filters.locations.length === allLocationIds.length:
 *    - NE FILTRIRA (prikazuje sve lokacije)
 * 
 * 3. Ako filters.locations.length > 0 && filters.locations.length < allLocationIds.length:
 *    - FILTRIRA: validOrders = validOrders.filter(o => {
 *        const companyId = String(o.company_id);
 *        return locationIds.map(String).includes(companyId);
 *      })
 * 
 * 4. Location mapping:
 *    - company_id može biti INTEGER ili STRING
 *    - Normalizuje se na STRING za poređenje
 *    - locations map se čuva sa oba ključa (number i string) za lookup
 */

/*
 * 5.2. CHANNEL FILTERING
 * ----------------------
 * 
 * Funkcija: processOrders() -> channel filter
 * 
 * Logika:
 * 1. Ako filters.channels.length === 0 ILI filters.channels.length === allChannelIds.length:
 *    - NE FILTRIRA (prikazuje sve kanale)
 * 
 * 2. Ako filters.channels.length > 0 && filters.channels.length < allChannelIds.length:
 *    - FILTRIRA: validOrders = validOrders.filter(o => {
 *        const provider = (o.provider || '').toLowerCase();
 *        return filters.channels.some(ch => {
 *          if (ch === 'wolt') return provider.indexOf('wolt') >= 0;
 *          if (ch === 'ebar') return provider.indexOf('ebar') >= 0 || provider.indexOf('emeni') >= 0;
 *          if (ch === 'gloria') return provider.indexOf('gloria') >= 0;
 *          if (ch === 'foodtruck') return provider === 'foodtruck' || provider === 'food truck';
 *          return false;
 *        });
 *      })
 * 
 * 3. Channel mapping:
 *    - 'wolt' -> provider.includes('wolt')
 *    - 'ebar' -> provider.includes('ebar') || provider.includes('emeni') || provider === ''
 *    - 'gloria' -> provider.includes('gloria')
 *    - 'foodtruck' -> provider === 'foodtruck' || provider === 'food truck'
 */

/*
 * 5.3. TREND DATA FILTERING
 * --------------------------
 * 
 * VAŽNO: Trend data NIKADA ne filtrira po location/channel!
 * 
 * Funkcija: processTrend(orders, locations, filters, startDate, endDate)
 * 
 * Logika:
 * 1. Filtrira SAMO otkazane porudžbine: status NOT IN (8, 9, 11)
 * 2. IGNORIŠE filters.locations i filters.channels
 * 3. Razlog: Trend chart treba da prikaže SVE podatke za period da bi dao kontekst
 * 
 * Primer:
 *   - Ako je filter: locations=[128], channels=['wolt']
 *   - Main dashboard prikazuje samo Sweet Collina + Wolt
 *   - Trend chart prikazuje SVE lokacije i SVE kanale za period
 */

/* ============================================================================
 * 6. KOMPONENTE - Kako komponente međusobno sarađuju
 * ============================================================================
 */

/*
 * 6.1. KOMPONENTA ARHITEKTURA
 * ----------------------------
 * 
 * DashboardPage.jsx (Container)
 *   ├── useAnalyticsData() hook
 *   │   ├── fetchLocations()
 *   │   ├── fetchOrders()
 *   │   ├── fetchOrderLifecycle()
 *   │   ├── fetchMargins()
 *   │   ├── processOrders()
 *   │   ├── fetchProjectionData()
 *   │   ├── fetchTrendOrders()
 *   │   ├── fetchLocationPerformance()
 *   │   └── calculateChannelMix()
 *   │
 *   ├── DateRangePicker
 *   │   └── onChange -> setDateRange -> useAnalyticsData refetch
 *   │
 *   ├── Location/Channel Dropdowns
 *   │   └── onChange -> setFilters -> useAnalyticsData refetch
 *   │
 *   └── Child Components (prima podatke preko props):
 *       ├── KPICard (stats.revenue, stats.orders, ...)
 *       ├── ProjectionChart (projectionData)
 *       ├── HourlyChart (hourlyData)
 *       ├── TrendChart (trendData, comparisonData)
 *       ├── CategoryMix (categoryData)
 *       ├── ProductsTable (topProducts)
 *       ├── PerformanceCard (placeholder)
 *       ├── Heatmap (stats.heatmapData)
 *       ├── LocationPerformance (locationPerformance)
 *       └── ChannelMix (channelMix)
 */

/*
 * 6.2. DATA PROPAGATION
 * ---------------------
 * 
 * 1. DashboardPage.jsx:
 *    const { stats, hourlyData, ... } = useAnalyticsData(dateRange, filters, trendPeriod);
 * 
 * 2. Props se prosleđuju direktno:
 *    <KPICard value={stats.revenue} />
 *    <HourlyChart data={hourlyData} />
 *    <TrendChart data={trendData} />
 * 
 * 3. Komponente su "dumb" - samo renderuju podatke, ne učitavaju
 * 
 * 4. Ako komponenta treba dodatne podatke:
 *    - Dodaje se fetch u useAnalyticsData
 *    - Dodaje se state u useAnalyticsData
 *    - Prosleđuje se preko props
 */

/*
 * 6.3. INTERACTIVE COMPONENTS
 * ----------------------------
 * 
 * TrendChart:
 *   - Ima compareMode state (week, month, quarter, year, custom)
 *   - Poziva onCompareChange(mode, customDates)
 *   - useAnalyticsData.handleCompareChange() ažurira compareMode
 *   - useAnalyticsData refetch-uje sa novim compareMode
 *   - comparisonData se prosleđuje nazad u TrendChart
 * 
 * ProjectionChart:
 *   - Prima projectionData objekt
 *   - Prikazuje best/worst/average/today/projection linije
 *   - Ne menja state, samo renderuje
 * 
 * HourlyChart:
 *   - Ima showCategories toggle
 *   - Menja prikaz između orders count i category breakdown
 *   - Ne utiče na data fetching
 */

/*
 * 6.4. AUTO-REFRESH
 * ------------------
 * 
 * Hook: useAnalyticsData -> useEffect za auto-refresh
 * 
 * Logika:
 * 1. Initial load: loadData(false) - prikazuje loading spinner
 * 2. Nakon initial load: setIsInitialLoad(false)
 * 3. Auto-refresh interval:
 *    - Pokreće se samo ako isInitialLoad === false
 *    - Poziva loadData(true) svakih 10 sekundi
 *    - Silent refresh: ne prikazuje loading spinner, samo setIsRefreshing(true)
 * 
 * useEffect(() => {
 *   if (isInitialLoad) return;
 *   const interval = setInterval(() => {
 *     loadData(true); // Silent refresh
 *   }, 10000);
 *   return () => clearInterval(interval);
 * }, [dateRange, isInitialLoad, loadData]);
 */

/* ============================================================================
 * 7. DODATNE NAPOMENE
 * ============================================================================
 */

/*
 * 7.1. TIMEZONE HANDLING
 * -----------------------
 * 
 * Problem: Supabase čuva timestamps u UTC, ali biznis logika koristi Belgrade time (UTC+1)
 * 
 * Rešenje:
 * - Date range filtering: getDateRangeFilter() konvertuje Belgrade time u UTC
 * - Order grouping: new Date(order.created_at).getHours() daje lokalni sat
 * - Trend data: belgradeDate = new Date(utcDate.getTime() + (1 * 60 * 60 * 1000))
 * 
 * Primer:
 *   Order created_at: "2026-01-17T12:00:00Z" (UTC)
 *   Belgrade time: 13:00 (UTC+1)
 *   Hour za grouping: 13
 */

/*
 * 7.2. PERFORMANCE OPTIMIZATIONS
 * --------------------------------
 * 
 * 1. Pagination: Automatska paginacija za >1000 redova
 * 2. Parallel fetching: Promise.all() za nezavisne fetch-ove
 * 3. Silent refresh: Ne blokira UI tokom auto-refresh-a
 * 4. Memoization: useCallback za loadData funkciju
 * 5. Safety limits: maxRows limit (50000 za orders, 10000 za trend)
 */

/*
 * 7.3. ERROR HANDLING
 * --------------------
 * 
 * 1. Try-catch blokovi u svim fetch funkcijama
 * 2. Fallback vrednosti: ako fetch fail-uje, vraća se prazan array ili {}
 * 3. Console logging za debugging
 * 4. Error state u useAnalyticsData: setError(err.message)
 * 5. UI prikazuje error poruku ako postoji
 */

/*
 * 7.4. DATA VALIDATION
 * ---------------------
 * 
 * 1. Prep time validation: 0 < prepTime < 120 minuta
 * 2. Delivery time validation: 0 < deliveryTime < 180 minuta
 * 3. Order total fallback: više izvora za order total
 * 4. Location mapping fallback: LOCATION_NAMES hardcoded map ako DB fetch fail-uje
 * 5. Category classification: default 'other' ako nijedan keyword ne odgovara
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
