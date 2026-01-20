/*
 * ============================================================================
 * DATA FORMATI I KONVENCIJE - KOMPLETNA DOKUMENTACIJA
 * ============================================================================
 * 
 * Ovaj dokument opisuje sve data formate i konvencije u Collina platformi,
 * uključujući date formats, currency formatting, time zones, naming conventions,
 * ID formats, apoeni strukture, status enums i nullable fields.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. DATE FORMATS - Kako se formatiraju datumi (Serbian locale)
 * ============================================================================
 */

/*
 * 1.1. DATE FORMATTING FUNCTIONS
 * --------------------------------
 * 
 * Locale: 'sr-RS' (Serbian - Serbia)
 * 
 * toLocaleDateString('sr-RS'):
 *   new Date(date).toLocaleDateString('sr-RS')
 *   // Output: "17.1.2026." (DD.MM.YYYY. format)
 * 
 * toLocaleDateString sa opcijama:
 *   new Date(date).toLocaleDateString('sr-RS', {
 *     day: 'numeric',
 *     month: 'numeric',
 *     year: 'numeric'
 *   })
 *   // Output: "17.1.2026."
 * 
 * toLocaleTimeString('sr-RS'):
 *   new Date(date).toLocaleTimeString('sr-RS', {
 *     hour: '2-digit',
 *     minute: '2-digit'
 *   })
 *   // Output: "14:30" (HH:MM format)
 * 
 * toLocaleString('sr-RS'):
 *   new Date(date).toLocaleString('sr-RS')
 *   // Output: "17.1.2026. 14:30:00" (DD.MM.YYYY. HH:MM:SS format)
 * 
 * NAPOMENA: Serbian locale koristi tačku (.) za separator datuma i dve tačke (..) na kraju.
 */

/*
 * 1.2. DATE INPUT FORMAT
 * ------------------------
 * 
 * HTML Date Input:
 *   <input type="date" value={selectedDate} />
 *   // Value format: "YYYY-MM-DD" (ISO date string)
 *   // Example: "2026-01-17"
 * 
 * Date State:
 *   const [selectedDate, setSelectedDate] = useState(
 *     new Date().toISOString().split('T')[0]
 *   );
 *   // Format: "YYYY-MM-DD"
 * 
 * Date Navigation:
 *   const changeDate = (delta) => {
 *     const date = new Date(selectedDate);
 *     date.setDate(date.getDate() + delta);
 *     setSelectedDate(date.toISOString().split('T')[0]);
 *   };
 * 
 * NAPOMENA: Date input koristi ISO format (YYYY-MM-DD) za value, ali prikazuje
 *           srpski format u UI-u.
 */

/*
 * 1.3. DATE STORAGE FORMAT
 * --------------------------
 * 
 * Database Storage:
 *   - Supabase TIMESTAMP: ISO 8601 format
 *   - Example: "2026-01-17T14:30:00.000Z"
 * 
 * Date Field Storage:
 *   - pazar_shifts.date: DATE type (YYYY-MM-DD)
 *   - pazar_cash_pickups.date: DATE type (YYYY-MM-DD)
 *   - emeni_orders.created_at: TIMESTAMP type (ISO 8601)
 * 
 * Date Conversion:
 *   const dateStr = date.toISOString().split('T')[0];
 *   // Converts Date object to "YYYY-MM-DD" string
 * 
 * NAPOMENA: Database čuva datume u ISO formatu, frontend formatira za prikaz.
 */

/*
 * 1.4. DATE RANGE FILTERING
 * ---------------------------
 * 
 * Utility: getDateRangeFilter() (dateFilters.js)
 * 
 * Function:
 *   export const getDateRangeFilter = (startDate, endDate) => {
 *     const start = formatDate(startDate); // "YYYY-MM-DD"
 *     const end = formatDate(endDate);     // "YYYY-MM-DD"
 *     
 *     // Convert to Belgrade timezone (UTC+1)
 *     const dayStart = new Date(`${start}T00:00:00+01:00`);
 *     const dayEnd = new Date(`${end}T23:59:59+01:00`);
 *     
 *     return {
 *       start: dayStart.toISOString(), // UTC ISO string
 *       end: dayEnd.toISOString(),     // UTC ISO string
 *     };
 *   };
 * 
 * Usage:
 *   const { start, end } = getDateRangeFilter(startDate, endDate);
 *   supabase.from('table')
 *     .gte('created_at', start)
 *     .lte('created_at', end);
 * 
 * NAPOMENA: Date range filtering koristi Belgrade timezone (UTC+1) za tačne
 *           granice dana, zatim konvertuje u UTC za Supabase queries.
 */

/*
 * 1.5. DATE FORMATTING EXAMPLES
 * ------------------------------
 * 
 * Example 1: Display Date
 *   {item.datum ? new Date(item.datum).toLocaleDateString('sr-RS') : '-'}
 *   // Output: "17.1.2026." ili "-" ako nema datuma
 * 
 * Example 2: Display Time
 *   orderTime.toLocaleTimeString('sr-RS', { hour: '2-digit', minute: '2-digit' })
 *   // Output: "14:30"
 * 
 * Example 3: Display DateTime
 *   new Date(timestamp).toLocaleString('sr-RS')
 *   // Output: "17.1.2026. 14:30:00"
 * 
 * Example 4: Custom Date Format
 *   const months = ['januar', 'februar', 'mart', ...];
 *   return `${date.getDate()}. ${months[date.getMonth()]} ${date.getFullYear()}.`;
 *   // Output: "17. januar 2026."
 * 
 * NAPOMENA: Date formatting je konzistentan - svi datumi koriste sr-RS locale.
 */

/* ============================================================================
 * 2. CURRENCY - RSD formatiranje (1.234.567 RSD)
 * ============================================================================
 */

/*
 * 2.1. CURRENCY FORMATTING FUNCTIONS
 * ------------------------------------
 * 
 * formatNumber(num):
 *   export function formatNumber(num) {
 *     if (typeof num !== 'number') num = parseFloat(num) || 0;
 *     return num.toLocaleString('sr-RS', {
 *       minimumFractionDigits: 0,
 *       maximumFractionDigits: 0,
 *       useGrouping: true,
 *     });
 *   }
 *   // Output: "1.234" (dot for thousands separator)
 * 
 * formatCurrency(amount):
 *   export function formatCurrency(amount) {
 *     if (typeof amount !== 'number') amount = parseFloat(amount) || 0;
 *     return `${formatNumber(amount)} RSD`;
 *   }
 *   // Output: "1.234 RSD"
 * 
 * formatCurrencyWithDecimals(amount):
 *   export function formatCurrencyWithDecimals(amount) {
 *     if (typeof amount !== 'number') amount = parseFloat(amount) || 0;
 *     return `${amount.toLocaleString('sr-RS', {
 *       minimumFractionDigits: 2,
 *       maximumFractionDigits: 2,
 *     })} RSD`;
 *   }
 *   // Output: "1.234,56 RSD" (comma for decimals)
 * 
 * NAPOMENA: Currency formatting koristi sr-RS locale sa RSD currency code.
 */

/*
 * 2.2. SERBIAN CURRENCY FORMAT RULES
 * ------------------------------------
 * 
 * Thousands Separator: dot (.)
 *   - 1000 → "1.000"
 *   - 1234567 → "1.234.567"
 * 
 * Decimal Separator: comma (,)
 *   - 1234.56 → "1.234,56"
 * 
 * Currency Code: RSD (Serbian Dinar)
 *   - Position: after amount
 *   - Format: "{amount} RSD"
 * 
 * Examples:
 *   - 1000 → "1.000 RSD"
 *   - 1234567 → "1.234.567 RSD"
 *   - 1234.56 → "1.234,56 RSD"
 * 
 * NAPOMENA: Serbian format koristi dot za hiljade i comma za decimale.
 */

/*
 * 2.3. INLINE CURRENCY FORMATTING
 * ---------------------------------
 * 
 * Pattern 1: Using formatCurrency()
 *   import { formatCurrency } from '../utils/formatCurrency';
 *   <span>{formatCurrency(amount)}</span>
 *   // Output: "1.234 RSD"
 * 
 * Pattern 2: Using toLocaleString()
 *   {amount.toLocaleString('sr-RS')} RSD
 *   // Output: "1.234 RSD"
 * 
 * Pattern 3: With Number() conversion
 *   {Number(amount).toLocaleString('sr-RS')} RSD
 *   // Output: "1.234 RSD"
 * 
 * Pattern 4: With decimals
 *   {amount.toLocaleString('sr-RS', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} RSD
 *   // Output: "1.234,56 RSD"
 * 
 * NAPOMENA: Inline formatting koristi toLocaleString('sr-RS') direktno.
 */

/*
 * 2.4. CURRENCY FORMATTING EXAMPLES
 * -----------------------------------
 * 
 * Example 1: Order Total
 *   <span className="text-lg font-bold text-[#22C55E]">
 *     {formatCurrency(total)}
 *   </span>
 *   // Output: "1.234 RSD"
 * 
 * Example 2: Safe Balance
 *   <p className="text-2xl font-bold">
 *     {safeBalance.toLocaleString()} RSD
 *   </p>
 *   // Output: "1.234.567 RSD"
 * 
 * Example 3: Discount Amount
 *   <span className="text-[10px] text-[rgba(34,197,94,0.6)] mt-0.5">
 *     -{formatCurrency(discountAmount)}
 *   </span>
 *   // Output: "-400 RSD"
 * 
 * Example 4: Average Basket (with decimals)
 *   {formatCurrencyWithDecimals(avgBasket)}
 *   // Output: "1.234,56 RSD"
 * 
 * NAPOMENA: Currency formatting je konzistentan kroz aplikaciju.
 */

/* ============================================================================
 * 3. TIME ZONES - Belgrade timezone handling
 * ============================================================================
 */

/*
 * 3.1. BELGRADE TIMEZONE
 * ------------------------
 * 
 * Timezone: UTC+1 (Central European Time - CET)
 * 
 * Timezone Offset:
 *   - Belgrade: UTC+1
 *   - Daylight Saving: UTC+2 (CEST) - ali se ne koristi eksplicitno
 * 
 * NAPOMENA: Belgrade timezone je UTC+1, ali aplikacija ne koristi DST handling.
 */

/*
 * 3.2. TIMEZONE CONVERSION
 * --------------------------
 * 
 * Pattern: Belgrade → UTC
 *   const dayStart = new Date(`${start}T00:00:00+01:00`);
 *   const dayEnd = new Date(`${end}T23:59:59+01:00`);
 *   return {
 *     start: dayStart.toISOString(), // UTC ISO string
 *     end: dayEnd.toISOString(),     // UTC ISO string
 *   };
 * 
 * Example:
 *   Input: startDate = "2026-01-17"
 *   Belgrade: "2026-01-17T00:00:00+01:00"
 *   UTC: "2026-01-16T23:00:00.000Z"
 * 
 * NAPOMENA: Date range filtering konvertuje Belgrade timezone u UTC za Supabase.
 */

/*
 * 3.3. DATE RANGE FILTERING WITH TIMEZONE
 * -----------------------------------------
 * 
 * Utility: getDateRangeFilter() (dateFilters.js)
 * 
 * Logic:
 *   1. Input: startDate = "2026-01-17", endDate = "2026-01-17"
 *   2. Belgrade start: "2026-01-17T00:00:00+01:00"
 *   3. Belgrade end: "2026-01-17T23:59:59+01:00"
 *   4. UTC start: "2026-01-16T23:00:00.000Z"
 *   5. UTC end: "2026-01-17T22:59:59.000Z"
 *   6. Return: { start: UTC start, end: UTC end }
 * 
 * Usage:
 *   const { start, end } = getDateRangeFilter(startDate, endDate);
 *   supabase.from('emeni_orders')
 *     .gte('created_at', start)
 *     .lte('created_at', end);
 * 
 * NAPOMENA: Timezone conversion osigurava da se učitaju sve porudžbine za
 *           izabrani dan u Belgrade timezone-u, ne u UTC.
 */

/*
 * 3.4. TIMESTAMP STORAGE
 * ------------------------
 * 
 * Database Storage:
 *   - Supabase TIMESTAMP: UTC (ISO 8601)
 *   - Example: "2026-01-17T14:30:00.000Z"
 * 
 * Display:
 *   - Prikazuje se u Belgrade timezone-u (UTC+1)
 *   - toLocaleString('sr-RS') automatski koristi browser timezone
 * 
 * NAPOMENA: Database čuva timestamps u UTC, prikaz se formatira u Belgrade timezone.
 */

/* ============================================================================
 * 4. NAMING CONVENTIONS - camelCase vs snake_case (JS vs SQL)
 * ============================================================================
 */

/*
 * 4.1. JAVASCRIPT NAMING (camelCase)
 * ------------------------------------
 * 
 * Variables:
 *   - camelCase: selectedRadnja, totalAmount, isAuthenticated
 *   - Boolean prefix: is, has, can (isLoading, hasError, canView)
 * 
 * Functions:
 *   - camelCase: fetchOrders, calculateTotal, handleSubmit
 *   - Verb prefix: get, set, fetch, create, update, delete
 * 
 * Components:
 *   - PascalCase: OrderCard, KPICard, StatusBadge
 * 
 * Constants:
 *   - UPPER_SNAKE_CASE: DENOMINATIONS, MAX_LOGIN_ATTEMPTS
 *   - camelCase: STATUS_MAP, LOCATION_NAMES (object constants)
 * 
 * NAPOMENA: JavaScript koristi camelCase za variables/functions, PascalCase za components.
 */

/*
 * 4.2. DATABASE NAMING (snake_case)
 * -----------------------------------
 * 
 * Tables:
 *   - snake_case: emeni_orders, pazar_shifts, pazar_finance_records
 * 
 * Columns:
 *   - snake_case: user_id, location_id, created_at, is_active
 *   - Timestamp suffix: _at (created_at, updated_at, verified_at)
 *   - Boolean prefix: is_ (is_active, is_first_shift, is_last_shift)
 *   - Foreign key suffix: _id (user_id, location_id, shift_id)
 * 
 * NAPOMENA: Database koristi snake_case za sve nazive (tables, columns).
 */

/*
 * 4.3. FIELD MAPPING (JS ↔ SQL)
 * -------------------------------
 * 
 * Database → JavaScript:
 *   - user_id → userId (ili user_id ako se koristi direktno)
 *   - created_at → created_at (ili createdAt ako se mapira)
 *   - is_active → isActive (ili is_active ako se koristi direktno)
 * 
 * JavaScript → Database:
 *   - userId → user_id
 *   - locationId → location_id
 *   - createdAt → created_at
 * 
 * NAPOMENA: Mapping zavisi od konteksta - neki fajlovi koriste snake_case direktno,
 *           neki mapiraju u camelCase.
 */

/*
 * 4.4. API RESPONSE MAPPING
 * ---------------------------
 * 
 * External API (Magacin):
 *   - API vraća: acName, acIdent, anStockCM, anReservedCM
 *   - JavaScript mapira: cmStock, cmReserved, cmAvailable
 * 
 * Supabase API:
 *   - Supabase vraća: user_id, created_at, is_active
 *   - JavaScript koristi: user_id direktno ili mapira u userId
 * 
 * NAPOMENA: API response mapping zavisi od API-ja - external API koristi camelCase,
 *           Supabase koristi snake_case.
 */

/* ============================================================================
 * 5. ID FORMATS - UUID vs integer vs string - gde se šta koristi
 * ============================================================================
 */

/*
 * 5.1. UUID FORMAT
 * -----------------
 * 
 * Format: "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
 * Example: "550e8400-e29b-41d4-a716-446655440000"
 * 
 * Usage:
 *   - Supabase primary keys (id UUID PRIMARY KEY DEFAULT gen_random_uuid())
 *   - pazar_shifts.id
 *   - pazar_users.id
 *   - pazar_finance_records.id
 *   - pazar_cash_pickups.id
 *   - pazar_bank_deposits.id
 * 
 * Generation:
 *   - Database: DEFAULT gen_random_uuid()
 *   - JavaScript: Nema manual generation (koristi database)
 * 
 * NAPOMENA: UUID se koristi za Supabase tabele (primary keys).
 */

/*
 * 5.2. INTEGER FORMAT
 * --------------------
 * 
 * Format: Integer number
 * Example: 128, 310, 1513, 3086, 3087
 * 
 * Usage:
 *   - Location IDs (company_id): 128, 310, 1513, 1514, 2120, 2165, 2166, 2209
 *   - Table IDs (table_id): 3086, 3087, 3088, 3090, 3092, 3093, 3094, 3095, 3097, 3098, 3100, 3105
 *   - Order status codes: 1, 3, 5, 7, 8, 9, 11
 *   - Lifecycle status codes: 3, 5, 7
 *   - Denomination values: 5000, 2000, 1000, 500, 200, 100, 50, 20, 10
 * 
 * NAPOMENA: Integer se koristi za legacy IDs (locations, tables) i status codes.
 */

/*
 * 5.3. STRING FORMAT
 * -------------------
 * 
 * Format: Alphanumeric string
 * Example: "ABC123", "trebovanje-key-2026-01-17"
 * 
 * Usage:
 *   - External API keys (Magacin): acKey, trebovanjeKey
 *   - Order numbers: order_number (može biti string ili integer)
 *   - Table numbers: table_number (može biti string ili integer)
 *   - Search terms: search_term (string)
 * 
 * NAPOMENA: String se koristi za external API keys i user-generated identifiers.
 */

/*
 * 5.4. ID USAGE PATTERNS
 * ------------------------
 * 
 * Pattern 1: UUID Primary Key
 *   - Supabase tabele: id UUID PRIMARY KEY
 *   - Usage: shift.id, user.id, record.id
 * 
 * Pattern 2: Integer Foreign Key
 *   - Legacy systems: company_id INTEGER
 *   - Usage: order.company_id, location.company_id
 * 
 * Pattern 3: String External Key
 *   - External APIs: acKey TEXT
 *   - Usage: trebovanje.acKey, prenos.acKey
 * 
 * Pattern 4: Fallback ID
 *   - Multiple sources: trebovanje.acKey || trebovanje.id
 *   - Usage: key={trebovanje.acKey || trebovanje.id}
 * 
 * NAPOMENA: ID usage zavisi od izvora - Supabase koristi UUID, legacy koristi integer,
 *           external API koristi string.
 */

/* ============================================================================
 * 6. APOENI - Struktura za novčanice {"5000": 2, "2000": 5}
 * ============================================================================
 */

/*
 * 6.1. DENOMINATIONS ARRAY
 * -------------------------
 * 
 * Constant: DENOMINATIONS (pazar/utils/constants.js, shiftFlowStore.js)
 * 
 * Values:
 *   export const DENOMINATIONS = [5000, 2000, 1000, 500, 200, 100, 50, 20, 10];
 * 
 * Order:
 *   - Descending order (highest to lowest)
 *   - RSD (Serbian Dinar) denominations
 * 
 * NAPOMENA: Denominations su u descending order za lakše brojanje.
 */

/*
 * 6.2. DENOMINATIONS OBJECT STRUCTURE
 * -------------------------------------
 * 
 * Pattern: { [denomination]: count }
 * 
 * Example:
 *   {
 *     5000: 2,  // 2 × 5000 = 10.000 RSD
 *     2000: 5,  // 5 × 2000 = 10.000 RSD
 *     1000: 3,  // 3 × 1000 = 3.000 RSD
 *     500: 0,
 *     200: 0,
 *     100: 0,
 *     50: 0,
 *     20: 0,
 *     10: 0
 *   }
 * 
 * Initialization:
 *   const denominations = DENOMINATIONS.reduce((acc, d) => ({ ...acc, [d]: 0 }), {});
 *   // Result: { 5000: 0, 2000: 0, 1000: 0, ..., 10: 0 }
 * 
 * NAPOMENA: Denominations object koristi integer keys (denomination value) i integer values (count).
 */

/*
 * 6.3. DENOMINATIONS CALCULATION
 * --------------------------------
 * 
 * Total Amount Calculation:
 *   const total = DENOMINATIONS.reduce((sum, d) => {
 *     return sum + (denominations[d] * d);
 *   }, 0);
 * 
 * Example:
 *   denominations = { 5000: 2, 2000: 5, 1000: 3, ... }
 *   total = (2 × 5000) + (5 × 2000) + (3 × 1000) + ...
 *   total = 10.000 + 10.000 + 3.000 = 23.000 RSD
 * 
 * NAPOMENA: Total se računa kao suma (count × denomination) za sve denominacije.
 */

/*
 * 6.4. DENOMINATIONS STORAGE
 * ----------------------------
 * 
 * Database Storage:
 *   - pazar_specification_denominations: JSONB column
 *   - pazar_bank_deposits.denomination_counts: JSONB column
 *   - pazar_finance_records.original_denominations: JSONB column
 *   - pazar_finance_records.modified_denominations: JSONB column
 * 
 * Format:
 *   {
 *     "5000": 2,
 *     "2000": 5,
 *     "1000": 3,
 *     "500": 0,
 *     "200": 0,
 *     "100": 0,
 *     "50": 0,
 *     "20": 0,
 *     "10": 0
 *   }
 * 
 * NAPOMENA: Denominations se čuvaju kao JSONB u Supabase (keys su stringovi u JSON-u).
 */

/*
 * 6.5. DENOMINATIONS DISPLAY
 * -----------------------------
 * 
 * Display Pattern:
 *   {DENOMINATIONS.map(d => (
 *     <div key={d}>
 *       <span>{d.toLocaleString('sr-RS')} × {denominations[d]}</span>
 *       <span>{formatAmount(d * denominations[d])}</span>
 *     </div>
 *   ))}
 * 
 * Example Output:
 *   "5.000 × 2" → "10.000 RSD"
 *   "2.000 × 5" → "10.000 RSD"
 *   "1.000 × 3" → "3.000 RSD"
 * 
 * NAPOMENA: Denominations se prikazuju sa formatiranim vrednostima (toLocaleString).
 */

/* ============================================================================
 * 7. STATUS ENUMS - Sve moguće vrednosti za status polja
 * ============================================================================
 */

/*
 * 7.1. EMENI_ORDERS STATUS
 * --------------------------
 * 
 * Status Codes (Integer):
 *   1  → 'new'        (Novo/Pending)
 *   3  → 'production' (Accepted/In Production)
 *   5  → 'ready'      (Ready for pickup/delivery)
 *   7  → 'paid'       (Delivered/Completed)
 *   8  → 'canceled'   (Canceled)
 *   9  → 'canceled'   (Rejected)
 *   11 → 'canceled'   (Rejected)
 * 
 * Status Labels (Serbian):
 *   'new'        → 'Novo'
 *   'production' → 'Priprema'
 *   'ready'      → 'Spremno'
 *   'paid'       → 'Završeno'
 *   'canceled'   → 'Otkazano'
 * 
 * NAPOMENA: emeni_orders.status koristi integer codes koji se mapiraju na string labels.
 */

/*
 * 7.2. EMENI_ORDER_LIFECYCLE STATUS
 * ------------------------------------
 * 
 * Status Codes (Integer):
 *   3 → 'Accepted' (Prihvaćeno - porudžbina je u pripremi)
 *   5 → 'Ready' (Spremno - porudžbina je spremna za preuzimanje)
 *   7 → 'Delivered' (Isporučeno - porudžbina je isporučena)
 * 
 * NAPOMENA: emeni_order_lifecycle.status koristi samo 3, 5, 7 (ne koristi 1, 8, 9, 11).
 */

/*
 * 7.3. PAZAR_SHIFTS STATUS
 * --------------------------
 * 
 * Status Values (String):
 *   'active'      → Aktivna smena (u toku)
 *   'handed_over' → Predata kolegi (smena je predata ali još nije zatvorena)
 *   'closed'      → Zatvorena smena (finalni status)
 * 
 * Constant: SHIFT_STATUS (pazar/utils/constants.js)
 *   export const SHIFT_STATUS = {
 *     ACTIVE: 'active',
 *     HANDED_OVER: 'handed_over',
 *     CLOSED: 'closed'
 *   };
 * 
 * NAPOMENA: pazar_shifts.status koristi string vrednosti (snake_case).
 */

/*
 * 7.4. PAZAR_FINANCE_RECORDS STATUS (Implicit)
 * ----------------------------------------------
 * 
 * Status Flow (Implicit - nema status polje, određuje se po timestamp-ima):
 *   'pending'     → received_at IS NULL (još nije primljeno)
 *   'received'    → received_at IS NOT NULL, verified_at IS NULL (primljeno ali ne verifikovano)
 *   'verified'    → verified_at IS NOT NULL, banked_at IS NULL (verifikovano ali ne deponovano)
 *   'in_transit'  → taken_from_safe_at IS NOT NULL, banked_at IS NULL (uzeto iz sefa ali ne deponovano)
 *   'deposited'   → banked_at IS NOT NULL (deponovano u banci)
 * 
 * NAPOMENA: pazar_finance_records nema status polje - status se određuje po timestamp-ima.
 */

/*
 * 7.5. PAZAR_CASH_PICKUPS STATUS (Implicit)
 * -------------------------------------------
 * 
 * Status Flow (Implicit - određuje se po timestamp-ima):
 *   'pending'    → picked_at IS NULL (još nije preuzeto)
 *   'picked'     → picked_at IS NOT NULL, delivered_at IS NULL (preuzeto ali ne dostavljeno)
 *   'delivered'  → delivered_at IS NOT NULL (dostavljeno u kancelariju)
 * 
 * NAPOMENA: pazar_cash_pickups nema status polje - status se određuje po timestamp-ima.
 */

/*
 * 7.6. PAZAR_BANK_DEPOSITS STATUS
 * --------------------------------
 * 
 * Status Values (String):
 *   'in_safe'    → U sefu (čekanje na uzimanje)
 *   'in_transit' → Na putu (uzeto iz sefa ali ne deponovano)
 *   'deposited'  → Deponovano (deponovano u banci)
 * 
 * NAPOMENA: pazar_bank_deposits.status koristi string vrednosti (snake_case).
 */

/*
 * 7.7. MAGACIN TREBOVANJE STATUS
 * --------------------------------
 * 
 * Status Values (String - Single Character):
 *   'N' → 'NOVO' (Novo trebovanje)
 *   'T' → 'NA PUTU' (Na putu - poslato ali ne primljeno)
 *   'Z' → 'ZAVRŠENO' (Završeno - primljeno)
 * 
 * Constant: STATUS_CONFIG (magacin/config/magacinConfig.js)
 *   export const STATUS_CONFIG = {
 *     'N': { label: 'NOVO', color: 'bg-yellow-500/20 text-yellow-400', icon: Clock },
 *     'T': { label: 'NA PUTU', color: 'bg-blue-500/20 text-blue-400', icon: Truck },
 *     'Z': { label: 'ZAVRŠENO', color: 'bg-green-500/20 text-green-400', icon: CheckCircle },
 *   };
 * 
 * NAPOMENA: Magacin trebovanje status koristi single character codes ('N', 'T', 'Z').
 */

/*
 * 7.8. HANDOVER TYPE
 * --------------------
 * 
 * Type Values (String):
 *   'deposit'   → Deposit (prva smena dana - preuzima deposit)
 *   'colleague' → Colleague (predaja kolegi)
 * 
 * Constant: HANDOVER_TYPE (pazar/utils/constants.js)
 *   export const HANDOVER_TYPE = {
 *     DEPOSIT: 'deposit',
 *     COLLEAGUE: 'colleague'
 *   };
 * 
 * NAPOMENA: Handover type određuje tip predaje (deposit za prvu smenu, colleague za ostale).
 */

/* ============================================================================
 * 8. NULLABLE FIELDS - Koja polja mogu biti null i šta to znači
 * ============================================================================
 */

/*
 * 8.1. TIMESTAMP NULLABLE FIELDS
 * --------------------------------
 * 
 * Pattern: _at suffix (created_at, updated_at, verified_at, etc.)
 * 
 * Nullable Timestamps:
 *   - received_at: NULL = još nije primljeno, NOT NULL = primljeno
 *   - verified_at: NULL = još nije verifikovano, NOT NULL = verifikovano
 *   - banked_at: NULL = još nije deponovano, NOT NULL = deponovano
 *   - taken_from_safe_at: NULL = još nije uzeto iz sefa, NOT NULL = uzeto
 *   - delivered_at: NULL = još nije dostavljeno, NOT NULL = dostavljeno
 *   - picked_at: NULL = još nije preuzeto, NOT NULL = preuzeto
 *   - ended_at: NULL = smena još nije završena, NOT NULL = završena
 *   - started_at: NULL = smena još nije započeta, NOT NULL = započeta
 * 
 * NAPOMENA: Timestamp nullable fields određuju status - NULL = nije izvršeno, NOT NULL = izvršeno.
 */

/*
 * 8.2. FOREIGN KEY NULLABLE FIELDS
 * ----------------------------------
 * 
 * Pattern: _id suffix (user_id, location_id, shift_id, etc.)
 * 
 * Nullable Foreign Keys:
 *   - received_by: NULL = nije primljeno, NOT NULL = primio korisnik
 *   - verified_by: NULL = nije verifikovano, NOT NULL = verifikovao korisnik
 *   - banked_by: NULL = nije deponovano, NOT NULL = deponovao korisnik
 *   - taken_by: NULL = nije uzeto, NOT NULL = uzeo korisnik
 *   - driver_id: NULL = nije dodeljen vozač, NOT NULL = dodeljen vozač
 *   - pickup_id: NULL = nije vezano za pickup, NOT NULL = vezano za pickup
 * 
 * NAPOMENA: Foreign key nullable fields određuju da li je akcija izvršena i ko ju je izvršio.
 */

/*
 * 8.3. AMOUNT NULLABLE FIELDS
 * -----------------------------
 * 
 * Nullable Amounts:
 *   - counted_amount: NULL = još nije izbrojano, NOT NULL = izbrojano
 *   - topup_amount: NULL = nema dopune, NOT NULL = iznos dopune
 *   - difference: NULL = nema razlike, NOT NULL = razlika
 *   - expected_cash: NULL = nije izračunato, NOT NULL = izračunato
 * 
 * NAPOMENA: Amount nullable fields određuju da li je vrednost izračunata ili uneta.
 */

/*
 * 8.4. TEXT NULLABLE FIELDS
 * ---------------------------
 * 
 * Nullable Text Fields:
 *   - note: NULL = nema napomene, NOT NULL = napomena
 *   - comment: NULL = nema komentara, NOT NULL = komentar
 *   - reason: NULL = nema razloga, NOT NULL = razlog
 *   - modification_reason: NULL = nema razloga izmene, NOT NULL = razlog izmene
 *   - modification_comment: NULL = nema komentara izmene, NOT NULL = komentar izmene
 * 
 * NAPOMENA: Text nullable fields su opcioni - NULL = nema vrednosti, NOT NULL = ima vrednost.
 */

/*
 * 8.5. JSONB NULLABLE FIELDS
 * ----------------------------
 * 
 * Nullable JSONB Fields:
 *   - original_denominations: NULL = nema originalnih apoena, NOT NULL = JSONB sa apoena
 *   - modified_denominations: NULL = nema izmenjenih apoena, NOT NULL = JSONB sa izmenjenim apoena
 *   - denomination_counts: NULL = nema apoena, NOT NULL = JSONB sa apoena
 *   - raw_payload: NULL = nema raw podataka, NOT NULL = JSONB sa raw podacima
 * 
 * NAPOMENA: JSONB nullable fields određuju da li postoje kompleksni podaci (denominations, raw data).
 */

/*
 * 8.6. NULLABLE FIELD HANDLING
 * ------------------------------
 * 
 * Pattern 1: Null Coalescing (??)
 *   const value = field ?? defaultValue;
 *   // Example: const cmStock = artikal.cmStock ?? 0;
 * 
 * Pattern 2: Optional Chaining (?.)
 *   const value = object?.property?.nested;
 *   // Example: const name = order.raw_payload?.waiter?.name;
 * 
 * Pattern 3: Conditional Rendering
 *   {field ? <Component /> : <Fallback />}
 *   // Example: {order.note ? <NoteDisplay /> : null}
 * 
 * Pattern 4: Default Value in Display
 *   {field || '-'}
 *   // Example: {waiter || '-'}
 * 
 * Pattern 5: Null Check Before Operation
 *   if (!field) return null;
 *   // Example: if (!order.lifecycle) return null;
 * 
 * NAPOMENA: Nullable field handling koristi nullish coalescing (??) i optional chaining (?.).
 */

/*
 * 8.7. NULLABLE FIELD EXAMPLES
 * ------------------------------
 * 
 * Example 1: Timestamp Check
 *   if (financeRecord.verified_at) {
 *     // Verifikovano
 *   } else {
 *     // Nije verifikovano
 *   }
 * 
 * Example 2: Amount with Default
 *   const amount = counted_amount ?? 0;
 * 
 * Example 3: Nested Property
 *   const waiter = order.raw_payload?.waiter?.name || '-';
 * 
 * Example 4: Conditional Display
 *   {order.note && (
 *     <div className="note">{order.note}</div>
 *   )}
 * 
 * Example 5: Date Formatting with Fallback
 *   {item.datum ? new Date(item.datum).toLocaleDateString('sr-RS') : '-'}
 * 
 * NAPOMENA: Nullable field examples pokazuju različite načine rukovanja null vrednostima.
 */

/* ============================================================================
 * 9. DODATNE NAPOMENE
 * ============================================================================
 */

/*
 * 9.1. NUMBER FORMATTING
 * ------------------------
 * 
 * Integer Formatting:
 *   num.toLocaleString('sr-RS')
 *   // Output: "1.234" (dot for thousands)
 * 
 * Decimal Formatting:
 *   num.toLocaleString('sr-RS', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
 *   // Output: "1.234,56" (comma for decimals)
 * 
 * NAPOMENA: Number formatting koristi sr-RS locale za Serbian format.
 */

/*
 * 9.2. BOOLEAN FORMATTING
 * -------------------------
 * 
 * Database Storage:
 *   - BOOLEAN type: true/false
 *   - NULL = nije postavljeno
 * 
 * JavaScript Usage:
 *   - Boolean values: true/false
 *   - Truthy/falsy: 0, '', null, undefined su falsy
 * 
 * Display:
 *   - "Da" / "Ne" (Serbian)
 *   - "✓ Da" / "✗ Ne" (with icon)
 * 
 * NAPOMENA: Boolean formatting koristi Serbian labels ("Da" / "Ne").
 */

/*
 * 9.3. ARRAY FORMATTING
 * -----------------------
 * 
 * Empty Array Handling:
 *   - array.length === 0 → "Nema podataka"
 *   - array || [] → fallback na prazan array
 * 
 * Array Display:
 *   - items.slice(0, 3).map(...) → prikaz prvih 3
 *   - items.length > 3 ? "+X more" : null → prikaz dodatnih
 * 
 * NAPOMENA: Array formatting koristi length check i slice za ograničen prikaz.
 */

/*
 * 9.4. OBJECT FORMATTING
 * ------------------------
 * 
 * Optional Chaining:
 *   object?.property?.nested
 *   // Safe access to nested properties
 * 
 * Nullish Coalescing:
 *   object.property ?? defaultValue
 *   // Fallback ako je null ili undefined
 * 
 * Object Spread:
 *   { ...object, newProperty: value }
 *   // Merge objects
 * 
 * NAPOMENA: Object formatting koristi optional chaining i nullish coalescing za safe access.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
