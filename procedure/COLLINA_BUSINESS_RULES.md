/*
 * ============================================================================
 * POSLOVNA PRAVILA SPECIFIČNA ZA COLLINA RESTORAN - KOMPLETNA DOKUMENTACIJA
 * ============================================================================
 * 
 * Ovaj dokument opisuje sva implicitna poslovna pravila specifična za Collina
 * restoran, izvučena iz koda i logike aplikacije. Ova pravila nisu eksplicitno
 * dokumentovana ali su implementirana u kodu.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. LOCATION MAPPING - eMeni company_id vs pazar_locations UUID vs code
 * ============================================================================
 */

/*
 * 1.1. LOCATION IDENTIFIER TYPES
 * --------------------------------
 * 
 * eMeni System:
 *   - company_id: INTEGER (npr. 1, 2, 128)
 *   - Tabela: emeni_locations (company_id, location_name)
 *   - Usage: emeni_orders.company_id, analytics filtering
 * 
 * Pazar System:
 *   - location_id: UUID (npr. 'a1b2c3d4-...')
 *   - Tabela: pazar_locations (id UUID, code TEXT, name TEXT)
 *   - Usage: pazar_shifts.location_id, pazar_finance_records.location_id
 * 
 * Location Code:
 *   - code: TEXT (npr. 'MP-P47', 'SWEET-128')
 *   - Tabela: pazar_locations.code
 *   - Usage: Display, identification
 * 
 * NAPOMENA: Nema eksplicitne tabele mapiranja - mapping se radi u kodu.
 */

/*
 * 1.2. LOCATION MAPPING LOGIC
 * -----------------------------
 * 
 * Analytics Module (emeni_orders → location_name):
 *   - Fetch: SELECT company_id, location_name FROM emeni_locations
 *   - Create map: { company_id: location_name }
 *   - Handle type mismatch: Store as both number and string keys
 *     locMap[companyId] = locationName;
 *     if (typeof companyId === 'number') locMap[String(companyId)] = locationName;
 *     if (typeof companyId === 'string') locMap[Number(companyId)] = locationName;
 * 
 * Pazar Module (pazar_locations):
 *   - Direct UUID lookup: pazar_shifts.location_id → pazar_locations.id
 *   - Display: location.code + location.name (npr. "MP-P47 - Sweet Collina")
 * 
 * NAPOMENA: Location mapping je implicitno - nema centralizovane tabele mapiranja.
 */

/*
 * 1.3. LOCATION IDENTIFIER USAGE
 * --------------------------------
 * 
 * eMeni Orders:
 *   - emeni_orders.company_id (INTEGER) → emeni_locations.company_id
 *   - Used for: Analytics filtering, location performance
 * 
 * Pazar Shifts:
 *   - pazar_shifts.location_id (UUID) → pazar_locations.id
 *   - Used for: Shift management, cash flow tracking
 * 
 * Finance Records:
 *   - pazar_finance_records.location_id (UUID) → pazar_locations.id
 *   - Used for: Cash pickup, bank deposits
 * 
 * NAPOMENA: eMeni i Pazar koriste različite ID sisteme - nema direktnog mapping-a.
 */

/*
 * 1.4. LOCATION NAME RESOLUTION
 * -------------------------------
 * 
 * Analytics (from emeni_locations):
 *   - Primary: emeni_locations.location_name
 *   - Fallback: LOCATION_NAMES constant (hardcoded)
 *   - Logic: locations[companyId] || LOCATION_NAMES[companyId] || 'Unknown'
 * 
 * Pazar (from pazar_locations):
 *   - Format: `${location.code} - ${location.name}`
 *   - Example: "MP-P47 - Sweet Collina"
 * 
 * NAPOMENA: Location name resolution ima fallback mehanizme za edge cases.
 */

/* ============================================================================
 * 2. SHIFT RULES - Max trajanje smene, kada se može zatvoriti dan, ko može zatvoriti
 * ============================================================================
 */

/*
 * 2.1. SHIFT DURATION RULES
 * ---------------------------
 * 
 * Trenutno stanje:
 *   - NEMA eksplicitnog max trajanja smene u kodu
 *   - Smena može trajati koliko god je potrebno
 *   - Shift order se određuje automatski (1, 2, 3, ...)
 * 
 * Implicit Rules:
 *   - Prva smena: is_first_shift = true (shift_order = 1)
 *   - Poslednja smena: is_last_shift = true (samo za endShiftEndOfDay)
 *   - Srednje smene: is_first_shift = false, is_last_shift = false
 * 
 * NAPOMENA: Nema hard limit-a za trajanje smene - fleksibilno za različite lokacije.
 */

/*
 * 2.2. SHIFT CLOSING RULES
 * --------------------------
 * 
 * End of Day (Završetak dana):
 *   - Može se zatvoriti samo poslednja smena u danu
 *   - Flow: endShiftEndOfDay() → status = 'closed', is_last_shift = true
 *   - Kreira: pazar_cash_collections, pazar_bank_deposits (status: 'in_safe')
 *   - Ko može: User koji je započeo smenu (user_id u shift-u)
 * 
 * Handover (Predaja kolegi):
 *   - Može se zatvoriti bilo koja smena (osim poslednje)
 *   - Flow: endShiftHandover() → status = 'handed_over'
 *   - Kolega mora preuzeti: takeoverShift() → status = 'closed'
 *   - Ko može: User koji je započeo smenu
 * 
 * NAPOMENA: End of day može zatvoriti samo poslednja smena - sistem automatski
 *           određuje koja je poslednja na osnovu shift_order.
 */

/*
 * 2.3. SHIFT ORDER RULES
 * ------------------------
 * 
 * Calculation:
 *   - Query: SELECT shift_order FROM pazar_shifts 
 *            WHERE location_id = X AND date = today 
 *            ORDER BY shift_order DESC LIMIT 1
 *   - New shift_order = max(shift_order) + 1
 *   - First shift: shift_order = 1 (ako nema postojećih)
 * 
 * Rules:
 *   - shift_order se automatski određuje pri kreiranju smene
 *   - Ne može se ručno set-ovati
 *   - Sequential ordering (1, 2, 3, ...)
 * 
 * NAPOMENA: Shift order osigurava da se smene pravilno numerišu u danu.
 */

/*
 * 2.4. SHIFT STATUS TRANSITIONS
 * -------------------------------
 * 
 * Allowed Transitions:
 *   - 'active' → 'handed_over' (endShiftHandover)
 *   - 'active' → 'closed' (endShiftEndOfDay)
 *   - 'handed_over' → 'closed' (takeoverShift)
 * 
 * Restrictions:
 *   - Ne može se zatvoriti smena koja nije aktivna
 *   - 'handed_over' smena mora biti preuzeta (takeoverShift)
 *   - Ne može se kreirati nova smena dok prethodna nije zatvorena
 * 
 * NAPOMENA: Shift status transitions su striktno kontrolisane - nema skip-ovanja.
 */

/* ============================================================================
 * 3. CASH RULES - Koliki je dozvoljen manjak, kada se aktivira alert, depozit limiti
 * ============================================================================
 */

/*
 * 3.1. SHORTAGE THRESHOLD
 * -------------------------
 * 
 * Constant: SHORTAGE_THRESHOLD = 1000 RSD
 * Location: src/modules/pazar/utils/constants.js
 * 
 * Rule:
 *   - Ako |difference| > 1000 RSD → zahteva se razlog (differenceReason)
 *   - Ako |difference| <= 1000 RSD → nije potreban razlog
 * 
 * Implementation:
 *   const needsReason = Math.abs(difference) > 1000;
 *   if (needsReason && !discrepancyReason) {
 *     alert('Molimo izaberite razlog razlike');
 *   }
 * 
 * NAPOMENA: Shortage threshold je 1000 RSD - razlike veće od ovoga zahtevaju objašnjenje.
 */

/*
 * 3.2. DISCREPANCY ALERT THRESHOLD
 * -----------------------------------
 * 
 * Count Modal (Admin verification):
 *   - Threshold: 100 RSD
 *   - Rule: Ako |countedAmount - expectedCash| > 100 → prikazuje se discrepancy reason field
 *   - Implementation: Math.abs(countedAmount - expectedCash) > 100
 * 
 * Reconciliation Step (Shift end):
 *   - Threshold: 1000 RSD (SHORTAGE_THRESHOLD)
 *   - Rule: Ako |difference| > 1000 → zahteva se razlog
 * 
 * NAPOMENA: Dva različita threshold-a - 100 RSD za admin verification, 1000 RSD za shift end.
 */

/*
 * 3.3. DEPOSIT LIMITS
 * ---------------------
 * 
 * Default Deposit:
 *   - Constant: DEFAULT_DEPOSIT = 10000 RSD
 *   - Location: src/modules/pazar/utils/constants.js
 *   - Usage: Initial deposit za prvu smenu
 * 
 * Deposit Rules:
 *   - Deposit se čuva u pazar_locations.current_deposit
 *   - Default: 10000 RSD (ako nije set-ovano)
 *   - Deposit ostaje u kasi (ne ide u sef)
 *   - Deposit se proverava pre brojanja (DepositCheckStep)
 * 
 * Deposit Check:
 *   - Pre brojanja: Proverava se da li je deposit kompletan
 *   - Ako fali: Korisnik mora dopuniti do punog iznosa
 *   - Confirmation: Checkbox "Depozit je kompletan"
 * 
 * NAPOMENA: Deposit je fiksni iznos (10,000 RSD) koji ostaje u kasi - ne ide u sef.
 */

/*
 * 3.4. CASH RECONCILIATION FORMULA
 * ----------------------------------
 * 
 * Expected Cash Calculation:
 *   expectedCash = ebarData.cash - ebarData.card
 *   - Prenos se NE računa (nije relevantan za keš u kasi)
 *   - Formula: Gotovina - Kartice
 * 
 * Difference Calculation:
 *   difference = countedAmount - expectedCash
 *   - Pozitivno = višak (surplus)
 *   - Negativno = manjak (shortage)
 *   - Nula = tačno
 * 
 * Final Cash Amount:
 *   finalCashAmount = countedAmount + topupAmount
 *   - Ako je manjak: topupAmount > 0 (dopuna)
 *   - Ako je višak: topupAmount = 0
 * 
 * NAPOMENA: Reconciliation formula je: expectedCash = cash - card (prenos se ignoriše).
 */

/*
 * 3.5. SHORTAGE HANDLING
 * -----------------------
 * 
 * Topup Sources (ako je manjak):
 *   - 'own_pocket': Iz svog džepa
 *   - 'tip_jar': Iz tegle za napojnice
 *   - 'colleague': Od kolege
 *   - 'other': Drugo
 * 
 * Rules:
 *   - Ako je manjak: MORA se uneti topupAmount i topupSource
 *   - Ako je |difference| > 1000: MORA se uneti razlog (differenceReason)
 *   - topupAmount se dodaje na countedAmount za finalCashAmount
 * 
 * NAPOMENA: Shortage handling zahteva objašnjenje izvora dopune.
 */

/*
 * 3.6. SURPLUS HANDLING
 * -----------------------
 * 
 * Surplus Sources (ako je višak):
 *   - 'tips': Napojnice / bakšiš
 *   - 'rounding': Zaokruživanje kusura
 *   - 'unknown': Ne znam
 * 
 * Rules:
 *   - Ako je višak: MORA se uneti surplusSource
 *   - Ako je |difference| > 1000: MORA se uneti razlog
 *   - Višak se ne skida - ide u finalCashAmount
 * 
 * NAPOMENA: Surplus handling zahteva objašnjenje izvora viška.
 */

/* ============================================================================
 * 4. PICKUP RULES - Ko može pokupiti pazar, vremenski rok za pickup
 * ============================================================================
 */

/*
 * 4.1. PICKUP ELIGIBILITY
 * -------------------------
 * 
 * Who Can Pickup:
 *   - Role: 'vozac' (driver)
 *   - Tabela: pazar_cash_pickups.driver_id → pazar_users.id
 *   - Verification: User mora imati role = 'vozac'
 * 
 * Pickup Creation:
 *   - Automatski: endShiftEndOfDay() kreira pazar_cash_collections
 *   - Manual: Admin može kreirati pickup u AdminPickupsPage
 *   - Status: 'pending' (čeka vozača)
 * 
 * NAPOMENA: Pickup može kreirati admin, ali može pokupiti samo vozač (vozac role).
 */

/*
 * 4.2. PICKUP FLOW
 * ------------------
 * 
 * Step 1: Driver Picks Up (Vozač pokupi):
 *   - Driver: Vozač sa role = 'vozac'
 *   - Action: Markira pickup kao picked (picked_at timestamp)
 *   - Status: 'picked' (u pazar_cash_pickups)
 * 
 * Step 2: Driver Delivers (Vozač dostavi):
 *   - Driver: Isti vozač
 *   - Action: Markira pickup kao delivered (delivered_at timestamp)
 *   - Status: 'delivered' (u pazar_cash_pickups)
 * 
 * Step 3: Admin Receives (Admin primi):
 *   - Admin: User sa role = 'admin' ili 'finansije'
 *   - Action: ReceiveModal → pazar_finance_records.received_at
 *   - Status: 'received' (u pazar_finance_records)
 * 
 * NAPOMENA: Pickup flow ima 3 koraka - vozač pokupi, vozač dostavi, admin primi.
 */

/*
 * 4.3. PICKUP TIME RULES
 * ------------------------
 * 
 * Trenutno stanje:
 *   - NEMA eksplicitnog vremenskog roka za pickup u kodu
 *   - Pickup može biti pokupljen bilo kada
 *   - Nema alert-a za kasne pickups
 * 
 * Implicit Rules:
 *   - Pickup se kreira na endShiftEndOfDay (poslednja smena)
 *   - Pickup treba biti pokupljen pre bank deposit
 *   - Pickup može biti pending neograničeno
 * 
 * NAPOMENA: Nema hard deadline-a za pickup - fleksibilno za različite lokacije.
 */

/*
 * 4.4. PICKUP AMOUNT
 * --------------------
 * 
 * Calculation:
 *   amount = countedAmount + topupAmount
 *   - countedAmount: Izbrojano u kasi
 *   - topupAmount: Dopuna (ako je bilo manjka)
 *   - Deposit se NE uključuje (ostaje u kasi)
 * 
 * Storage:
 *   - pazar_cash_pickups.amount
 *   - pazar_cash_collections.amount
 * 
 * NAPOMENA: Pickup amount = countedAmount + topupAmount (deposit ostaje u kasi).
 */

/* ============================================================================
 * 5. BANK DEPOSIT RULES - Kada se mora deponovati, ko može deponovati
 * ============================================================================
 */

/*
 * 5.1. BANK DEPOSIT STATUS MACHINE
 * ----------------------------------
 * 
 * Status Flow:
 *   1. 'in_safe' → Novac je u sefu (verifikovan od admina)
 *   2. 'in_transit' → Novac je preuzet iz sefa (na putu u banku)
 *   3. 'deposited' → Novac je deponovan u banku
 * 
 * Transitions:
 *   - Auto-create: endShiftEndOfDay() → status = 'in_safe'
 *   - Take from safe: TakeFromSafeModal → status = 'in_transit'
 *   - Mark deposited: BankDepositModalNew → status = 'deposited'
 * 
 * NAPOMENA: Bank deposit status mašina ima 3 statusa - in_safe → in_transit → deposited.
 */

/*
 * 5.2. BANK DEPOSIT ELIGIBILITY
 * -------------------------------
 * 
 * Who Can Take from Safe:
 *   - Role: 'admin' ili 'finansije'
 *   - Action: TakeFromSafeModal → pazar_finance_records.taken_from_safe_at
 *   - Verification: employee?.role === 'admin' || employee?.role === 'finansije'
 * 
 * Who Can Mark as Deposited:
 *   - Role: 'admin' ili 'finansije'
 *   - Action: BankDepositModalNew → pazar_finance_records.banked_at
 *   - Verification: employee?.role === 'admin' || employee?.role === 'finansije'
 * 
 * NAPOMENA: Bank deposit operacije mogu samo admin i finansije role.
 */

/*
 * 5.3. BANK DEPOSIT TIMING
 * --------------------------
 * 
 * When to Deposit:
 *   - NEMA eksplicitnog deadline-a u kodu
 *   - Deposit se može deponovati bilo kada posle verifikacije
 *   - Nema alert-a za kasne deposits
 * 
 * Implicit Rules:
 *   - Deposit se kreira na endShiftEndOfDay (status: 'in_safe')
 *   - Deposit treba biti verifikovan pre uzimanja iz sefa
 *   - Deposit može biti u sefu neograničeno
 * 
 * NAPOMENA: Nema hard deadline-a za bank deposit - fleksibilno za različite lokacije.
 */

/*
 * 5.4. BANK DEPOSIT AMOUNT
 * --------------------------
 * 
 * Calculation:
 *   amount = countedAmount + topupAmount
 *   - countedAmount: Izbrojano u kasi (verifikovano od admina)
 *   - topupAmount: Dopuna (ako je bilo manjka)
 *   - Deposit se NE uključuje (ostaje u kasi)
 * 
 * Storage:
 *   - pazar_bank_deposits.amount
 *   - pazar_finance_records.counted_amount
 * 
 * NAPOMENA: Bank deposit amount = countedAmount + topupAmount (deposit ostaje u kasi).
 */

/*
 * 5.5. PAYMENT SLIP GENERATION
 * ------------------------------
 * 
 * When: TakeFromSafeModal → Print button
 * 
 * Required Data:
 *   - payer_company_id: Company koja plaća (default company)
 *   - recipient_company_id: Company koja prima (default company)
 *   - bank_account_id: Bank account (primary account)
 *   - payment_purpose_id: Payment purpose (default purpose)
 * 
 * Rules:
 *   - Sva polja moraju biti popunjena
 *   - Default values se učitavaju iz companies, bank_accounts, payment_purposes
 *   - Print generiše HTML uplatnicu
 * 
 * NAPOMENA: Payment slip se generiše pre uzimanja novca iz sefa - za bank deposit.
 */

/* ============================================================================
 * 6. ROLE HIERARCHY - Ko može šta override-ovati, approval flow
 * ============================================================================
 */

/*
 * 6.1. ROLE DEFINITIONS
 * -----------------------
 * 
 * Roles (from pazar_users.role):
 *   - 'admin': Puna pristupa svim modulima
 *   - 'menadzer': Pristup analytics, orders, magacin
 *   - 'finansije': Pristup pazar/finance modulu
 *   - 'konobar': Pristup staff modulu (waiter)
 *   - 'vozac': Pristup staff/pickup modulu (driver)
 * 
 * NAPOMENA: Role se čuvaju u pazar_users.role (TEXT field).
 */

/*
 * 6.2. ROLE PERMISSIONS
 * -----------------------
 * 
 * Admin:
 *   - Pristup: Svi moduli (analytics, orders, magacin, pazar/finance)
 *   - Override: Može verifikovati, brojati, deponovati novac
 *   - Approval: Ne zahteva approval za svoje akcije
 * 
 * Finansije:
 *   - Pristup: Pazar/finance modul (receive, count, safe, bank)
 *   - Override: Može verifikovati, brojati, deponovati novac
 *   - Approval: Ne zahteva approval za svoje akcije
 * 
 * Menadzer:
 *   - Pristup: Analytics, orders, magacin
 *   - Override: Ne može override-ovati cash operations
 *   - Approval: N/A (nema pristup cash operations)
 * 
 * Konobar/Vozac:
 *   - Pristup: Staff modul (shift management, pickup)
 *   - Override: Ne može override-ovati admin operations
 *   - Approval: N/A (nema pristup admin operations)
 * 
 * NAPOMENA: Role permissions su kontrolisane kroz module_permissions tabelu.
 */

/*
 * 6.3. OVERRIDE RULES
 * --------------------
 * 
 * Cash Counting Override:
 *   - Ko može: 'admin' ili 'finansije'
 *   - Action: CountModal → mode = 'edit'
 *   - Rule: Ako |difference| > 100 RSD → zahteva se discrepancyReason
 *   - Storage: modification_reason, modification_comment u pazar_finance_records
 * 
 * Bank Deposit Override:
 *   - Ko može: 'admin' ili 'finansije'
 *   - Action: BankDepositModalNew → Mark as deposited
 *   - Rule: Može mark-ovati bilo koji deposit kao deposited
 *   - Storage: banked_at, banked_by u pazar_finance_records
 * 
 * NAPOMENA: Override operacije mogu samo admin i finansije role.
 */

/*
 * 6.4. APPROVAL FLOW
 * -------------------
 * 
 * Trenutno stanje:
 *   - NEMA eksplicitnog approval flow-a u kodu
 *   - Admin i finansije mogu direktno verifikovati i deponovati
 *   - Nema multi-step approval process
 * 
 * Implicit Rules:
 *   - Cash verification: Admin verifikuje → verified_at timestamp
 *   - Bank deposit: Admin mark-uje → banked_at timestamp
 *   - Nema approval chain (npr. manager → admin → sef)
 * 
 * NAPOMENA: Approval flow je jednostavan - admin/finansije direktno verifikuju.
 */

/*
 * 6.5. AUDIT TRAIL FOR OVERRIDES
 * --------------------------------
 * 
 * Cash Counting Override:
 *   - original_denominations: Originalni apoeni iz smene
 *   - modified_denominations: Izmenjeni apoeni (ako je edit mode)
 *   - modification_reason: Razlog izmene
 *   - modification_comment: Komentar izmene
 *   - verified_by: Admin koji je verifikovao
 *   - verified_at: Timestamp verifikacije
 * 
 * Bank Deposit Override:
 *   - banked_by: Admin koji je mark-ovao kao deposited
 *   - banked_at: Timestamp depozita
 * 
 * NAPOMENA: Override operacije se log-uju sa user ID i timestamp-om.
 */

/* ============================================================================
 * 7. NOTIFICATION RULES - Kada se šalju notifikacije i kome
 * ============================================================================
 */

/*
 * 7.1. NOTIFICATION SYSTEM OVERVIEW
 * -----------------------------------
 * 
 * Tabela: notifications
 *   - id: UUID
 *   - user_id: UUID (pazar_users.id)
 *   - title: TEXT
 *   - message: TEXT
 *   - type: TEXT ('schedule', 'menu', 'message', 'alert')
 *   - is_read: BOOLEAN
 *   - created_at: TIMESTAMP
 * 
 * NAPOMENA: Notification tabela postoji ali nema eksplicitnih pravila u kodu.
 */

/*
 * 7.2. NOTIFICATION TYPES
 * -------------------------
 * 
 * Schedule Notifications:
 *   - Type: 'schedule'
 *   - When: Schedule update (pretpostavljeno)
 *   - To: User koji ima scheduled shift
 *   - Example: "Your shift on Friday has been changed to 14:00 - 22:00"
 * 
 * Menu Notifications:
 *   - Type: 'menu'
 *   - When: Menu item added/changed (pretpostavljeno)
 *   - To: All staff (pretpostavljeno)
 *   - Example: "BBQ Bacon Smash has been added to the menu"
 * 
 * Message Notifications:
 *   - Type: 'message'
 *   - When: Manager sends message (pretpostavljeno)
 *   - To: Specific user ili all staff (pretpostavljeno)
 *   - Example: "Great job on yesterday's shift!"
 * 
 * Alert Notifications:
 *   - Type: 'alert'
 *   - When: Critical alerts (pretpostavljeno)
 *   - To: Admin/Manager (pretpostavljeno)
 *   - Example: "Cash shortage detected"
 * 
 * NAPOMENA: Notification types su definisani ali nema eksplicitnih trigger pravila.
 */

/*
 * 7.3. NOTIFICATION TRIGGERS (Implicit)
 * ---------------------------------------
 * 
 * Potential Triggers (nije implementirano):
 *   - Cash shortage > 1000 RSD → Alert admin
 *   - Shift not closed after X hours → Alert manager
 *   - Pickup pending > 24 hours → Alert admin
 *   - Bank deposit not deposited > 48 hours → Alert admin
 * 
 * NAPOMENA: Notification triggers nisu implementirani - samo UI placeholder postoji.
 */

/* ============================================================================
 * 8. AUDIT TRAIL - Šta se sve loguje, gde se čuva istorija
 * ============================================================================
 */

/*
 * 8.1. AUDIT TRAIL OVERVIEW
 * ---------------------------
 * 
 * Audit trail se čuva kroz timestamp polja u tabelama:
 *   - created_at: Kreiranje zapisa
 *   - updated_at: Ažuriranje zapisa (ako postoji)
 *   - Specific timestamps: verified_at, banked_at, received_at, etc.
 * 
 * NAPOMENA: Audit trail je implicitno kroz timestamp polja - nema eksplicitne audit tabele.
 */

/*
 * 8.2. SHIFT AUDIT TRAIL
 * ------------------------
 * 
 * pazar_shifts:
 *   - created_at: Kada je smena kreirana
 *   - started_at: Kada je smena započeta
 *   - ended_at: Kada je smena završena
 *   - user_id: Ko je započeo smenu
 * 
 * pazar_daily_specifications:
 *   - created_at: Kada je specification kreirana
 *   - confirmed_at: Kada je specification potvrđena
 *   - user_id: Ko je završio smenu
 * 
 * NAPOMENA: Shift audit trail prati ko je započeo i završio smenu.
 */

/*
 * 8.3. CASH FLOW AUDIT TRAIL
 * ----------------------------
 * 
 * pazar_finance_records:
 *   - created_at: Kada je record kreiran
 *   - received_at: Kada je novac primljen (od vozača)
 *   - received_by: Ko je primio novac (admin ID)
 *   - verified_at: Kada je novac verifikovan (brojanje)
 *   - verified_by: Ko je verifikovao novac (admin ID)
 *   - counted_amount: Koliko je izbrojano
 *   - original_denominations: Originalni apoeni
 *   - modified_denominations: Izmenjeni apoeni (ako je edit)
 *   - modification_reason: Razlog izmene
 *   - modification_comment: Komentar izmene
 *   - taken_from_safe_at: Kada je preuzet iz sefa
 *   - taken_by: Ko je preuzeo iz sefa (admin ID)
 *   - banked_at: Kada je deponovan u banku
 *   - banked_by: Ko je deponovao u banku (admin ID)
 * 
 * NAPOMENA: Cash flow audit trail prati kompletan flow od prijema do depozita.
 */

/*
 * 8.4. PICKUP AUDIT TRAIL
 * ------------------------
 * 
 * pazar_cash_pickups:
 *   - created_at: Kada je pickup kreiran
 *   - picked_at: Kada je vozač pokupio
 *   - delivered_at: Kada je vozač dostavio
 *   - driver_id: Ko je vozač
 * 
 * NAPOMENA: Pickup audit trail prati vozača i vreme pickup-a.
 */

/*
 * 8.5. BANK DEPOSIT AUDIT TRAIL
 * -------------------------------
 * 
 * pazar_bank_deposits:
 *   - created_at: Kada je deposit kreiran (auto na endShiftEndOfDay)
 *   - deposited_at: Kada je deposit deponovan (ako postoji)
 *   - deposited_by: Ko je deponovao (ako postoji)
 *   - denomination_counts: JSONB sa apoenima
 * 
 * NAPOMENA: Bank deposit audit trail prati kreiranje i depozit.
 */

/*
 * 8.6. USER ACTION AUDIT TRAIL
 * ------------------------------
 * 
 * All Actions Log User ID:
 *   - received_by: Ko je primio novac
 *   - verified_by: Ko je verifikovao novac
 *   - taken_by: Ko je preuzeo iz sefa
 *   - banked_by: Ko je deponovao u banku
 *   - user_id: Ko je započeo/završio smenu
 * 
 * All Actions Log Timestamp:
 *   - received_at: Vreme prijema
 *   - verified_at: Vreme verifikacije
 *   - taken_from_safe_at: Vreme uzimanja iz sefa
 *   - banked_at: Vreme depozita
 *   - started_at: Vreme početka smene
 *   - ended_at: Vreme završetka smene
 * 
 * NAPOMENA: User action audit trail prati ko je šta uradio i kada.
 */

/*
 * 8.7. DATA MODIFICATION AUDIT TRAIL
 * ------------------------------------
 * 
 * Original vs Modified:
 *   - original_amount: Originalni iznos iz smene
 *   - original_denominations: Originalni apoeni iz smene
 *   - modified_denominations: Izmenjeni apoeni (ako je edit)
 *   - modification_reason: Razlog izmene
 *   - modification_comment: Komentar izmene
 *   - spec_modified: Boolean (da li je specification izmenjena)
 * 
 * NAPOMENA: Data modification audit trail prati sve izmene originalnih podataka.
 */

/* ============================================================================
 * 9. ADDITIONAL BUSINESS RULES
 * ============================================================================
 */

/*
 * 9.1. DENOMINATION RULES
 * ------------------------
 * 
 * Valid Denominations:
 *   - Array: [5000, 2000, 1000, 500, 200, 100, 50, 20, 10]
 *   - Unit: RSD (Serbian Dinar)
 *   - Storage: JSONB objekat { "5000": 5, "2000": 3, ... }
 * 
 * Calculation:
 *   total = denominations.reduce((sum, d) => sum + (denoms[d] * d), 0)
 * 
 * NAPOMENA: Denominations su fiksne - nema custom apoeni.
 */

/*
 * 9.2. E-BAR DATA RULES
 * ----------------------
 * 
 * Required Fields:
 *   - date: YYYY-MM-DD format
 *   - time: HH:MM format
 *   - cash: Gotovina (ukupan promet)
 *   - card: Kartice (ukupan promet)
 *   - transfer: Prenos (opciono, ne računa se u expected cash)
 * 
 * Expected Cash Formula:
 *   expectedCash = cash - card
 *   - Prenos se NE računa (nije relevantan za keš u kasi)
 * 
 * NAPOMENA: E-Bar data se unosi ručno - nema automatskog import-a.
 */

/*
 * 9.3. LOCATION DEPOSIT RULES
 * -----------------------------
 * 
 * Default Deposit:
 *   - pazar_locations.current_deposit: Default 10000 RSD
 *   - Fallback: 10000 RSD (ako nije set-ovano)
 * 
 * Deposit Usage:
 *   - Deposit ostaje u kasi (ne ide u sef)
 *   - Deposit se proverava pre brojanja
 *   - Deposit se ne uključuje u pickup amount
 *   - Deposit se ne uključuje u bank deposit amount
 * 
 * NAPOMENA: Deposit je fiksni iznos po lokaciji - default 10,000 RSD.
 */

/*
 * 9.4. SHIFT HANDOVER RULES
 * ---------------------------
 * 
 * Handover Types:
 *   - 'deposit': Prva smena dobija depozit
 *   - 'colleague': Predaja kolegi
 * 
 * Handover Amount:
 *   - reported_amount: Šta je prethodna smena izjavila
 *   - received_amount: Šta je nova smena izbrojala
 *   - Discrepancy: received_amount - reported_amount
 * 
 * NAPOMENA: Handover prati razliku između izjavljenog i izbrojanog.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
