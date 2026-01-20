/*
 * ============================================================================
 * PAZAR MODUL - KOMPLETNA BIZNIS LOGIKA (Cash Management)
 * ============================================================================
 * 
 * Ovaj dokument opisuje kompletnu biznis logiku PAZAR modula u Collina
 * platformi, uključujući shift flow, cash pickup flow, kalkulacije, status
 * mašine, apoeni i edge cases.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. SHIFT FLOW - Kompletna state mašina (Start → Handover → End)
 * ============================================================================
 */

/*
 * 1.1. SHIFT STATUS MAŠINA
 * ------------------------
 * 
 * Tabela: pazar_shifts.status (TEXT)
 * 
 * Statusi i tranzicije:
 * 
 * 1. 'active' - Smena je aktivna (započeta)
 *    - Kreira se sa startFirstShift() ili startShift()
 *    - Može se završiti sa endShiftHandover() ili endShiftEndOfDay()
 * 
 * 2. 'handed_over' - Smena je predata kolegi (privremeni status)
 *    - Postavlja se sa endShiftHandover()
 *    - Automatski se menja u 'closed' kada kolega preuzme smenu (takeoverShift())
 *    - ending_amount = countedAmount (izbrojano u kasi)
 *    - is_last_shift = false
 * 
 * 3. 'closed' - Smena je zatvorena (završena)
 *    - Postavlja se sa:
 *      a) endShiftEndOfDay() - ako je poslednja smena u danu
 *      b) takeoverShift() - kada kolega preuzme smenu (menja 'handed_over' → 'closed')
 *    - ending_amount = countedAmount (izbrojano u kasi)
 *    - is_last_shift = true (samo za endShiftEndOfDay)
 * 
 * Tranzicije:
 *   'active' → 'handed_over' (endShiftHandover)
 *   'active' → 'closed' (endShiftEndOfDay)
 *   'handed_over' → 'closed' (takeoverShift)
 * 
 * NAPOMENA: 'handed_over' je privremeni status - ne može ostati u ovom statusu
 *           dugo. Kada kolega preuzme smenu, automatski se menja u 'closed'.
 */

/*
 * 1.2. START FIRST SHIFT (Prva smena u danu)
 * -------------------------------------------
 * 
 * Funkcija: startFirstShift(locationId, userId, startingAmount)
 * 
 * Logika:
 * 1. Određuje shift_order:
 *    - Query: SELECT shift_order FROM pazar_shifts 
 *             WHERE location_id = X AND date = today 
 *             ORDER BY shift_order DESC LIMIT 1
 *    - Ako postoji: shift_order = max(shift_order) + 1
 *    - Ako ne postoji: shift_order = 1
 * 
 * 2. Kreira pazar_shifts zapis:
 *    - location_id, user_id, date (today), shift_order
 *    - status = 'active'
 *    - started_at = now()
 *    - starting_amount = startingAmount (depozit)
 *    - is_first_shift = true (ako shift_order === 1)
 *    - is_last_shift = false
 * 
 * 3. Kreira pazar_shift_handovers zapis:
 *    - handover_type = 'deposit' (prva smena dobija depozit)
 *    - to_shift_id = novi shift.id
 *    - to_user_id = userId
 *    - reported_amount = startingAmount
 *    - received_amount = startingAmount
 *    - confirmed_at = now()
 * 
 * Primer:
 *   - Lokacija: Sweet Collina (128)
 *   - User: Marko (ID: 5)
 *   - Starting amount: 10,000 RSD (depozit)
 *   - Rezultat: shift_order=1, status='active', is_first_shift=true
 */

/*
 * 1.3. START SHIFT (Naredne smene)
 * ----------------------------------
 * 
 * Funkcija: startShift(shiftData)
 * 
 * Logika:
 * 1. Prima shiftData:
 *    - locationId, date, shiftOrder, userId
 *    - isFirstShift (false za naredne smene)
 *    - startingAmount (izbrojano od prethodne smene)
 * 
 * 2. Kreira pazar_shifts zapis:
 *    - status = 'active'
 *    - started_at = now()
 *    - starting_amount = startingAmount
 *    - is_first_shift = false
 *    - is_last_shift = false
 * 
 * NAPOMENA: Ova funkcija se retko koristi direktno. Obično se koristi
 *           takeoverShift() koji automatski kreira novu smenu.
 */

/*
 * 1.4. END SHIFT HANDOVER (Predaja kolegi)
 * -----------------------------------------
 * 
 * Funkcija: endShiftHandover(data)
 * 
 * Input data:
 *   - shiftId, locationId, userId
 *   - ebarData: { cash, card, transfer, date, time }
 *   - countedAmount (izbrojano u kasi)
 *   - deposit (depozit koji ostaje u kasi)
 *   - denominations (objekat: { 5000: 5, 2000: 3, ... })
 *   - difference (razlika između counted i expected)
 *   - topupAmount, topupSource, topupComment (ako je manjak)
 *   - surplusSource, surplusComment (ako je višak)
 * 
 * Logika:
 * 1. Update pazar_shifts:
 *    - status = 'handed_over'
 *    - ended_at = now()
 *    - ending_amount = countedAmount
 *    - is_last_shift = false
 * 
 * 2. Kreira pazar_daily_specifications:
 *    - location_id, date, shift_id, user_id
 *    - ebar_total = ebarData.cash
 *    - ebar_transfer = ebarData.transfer || 0
 *    - terminal_amount = ebarData.card || 0
 *    - deposit_amount = deposit
 *    - counted_amount = countedAmount
 *    - topup_amount = topupAmount || 0
 *    - topup_source = topupSource
 *    - topup_comment = topupComment
 *    - shortage_reason = surplusSource (napomena: field name je shortage_reason ali se koristi i za surplus)
 *    - shortage_comment = surplusComment
 *    - ebar_printed_at = `${ebarData.date}T${ebarData.time}:00`
 *    - confirmed_at = now()
 * 
 * 3. Kreira pazar_specification_denominations:
 *    - Za svaki apoen sa quantity > 0:
 *      { specification_id, denomination, quantity }
 * 
 * NAPOMENA: Handover record se NE kreira ovde - kreira se u takeoverShift()
 *           kada kolega preuzme smenu.
 */

/*
 * 1.5. END SHIFT END OF DAY (Završetak dana - poslednja smena)
 * -------------------------------------------------------------
 * 
 * Funkcija: endShiftEndOfDay(data)
 * 
 * Input data: Isto kao endShiftHandover()
 * 
 * Logika:
 * 1. Poziva endShiftHandover() da kreira specification
 * 
 * 2. Update pazar_shifts:
 *    - status = 'closed'
 *    - is_last_shift = true
 * 
 * 3. Kreira pazar_cash_collections:
 *    - specification_id = spec.id
 *    - location_id, date
 *    - amount = countedAmount + topupAmount (ukupan keš za preuzimanje)
 *    - status = 'pending' (čeka vozača)
 *    - created_at = now()
 * 
 * 4. Kreira pazar_bank_deposits (auto-create):
 *    - location_id, date
 *    - amount = countedAmount + topupAmount
 *    - status = 'in_safe' (novac je u sefu, čeka verifikaciju)
 *    - denomination_counts = JSONB objekat sa apoenima
 * 
 * NAPOMENA: Bank deposit se kreira automatski sa status 'in_safe' jer
 *           novac još nije verifikovan od strane admina.
 */

/*
 * 1.6. TAKEOVER SHIFT (Preuzimanje smene od kolege)
 * ---------------------------------------------------
 * 
 * Funkcija: takeoverShift(previousShiftId, locationId, userId, countedCash, countedDeposit)
 * 
 * Logika:
 * 1. Učitava prethodnu smenu (previousShiftId):
 *    - Mora biti status = 'handed_over'
 * 
 * 2. Kalkuliše newStartingAmount:
 *    newStartingAmount = countedCash + countedDeposit
 *    - countedCash = izbrojano u kasi (bez depozita)
 *    - countedDeposit = izbrojani depozit
 * 
 * 3. Zatvara prethodnu smenu:
 *    - Update pazar_shifts: status = 'closed', ended_at = prevShift.ended_at || now()
 *    - NAPOMENA: ended_at se ne menja ako već postoji (zadržava originalno vreme)
 * 
 * 4. Kalkuliše shift_order za novu smenu:
 *    - Query: SELECT shift_order FROM pazar_shifts 
 *             WHERE location_id = X AND date = today 
 *             ORDER BY shift_order DESC LIMIT 1
 *    - newShiftOrder = max(shift_order) + 1
 *    - Fallback: prevShift.shift_order + 1
 * 
 * 5. Kreira novu smenu:
 *    - status = 'active'
 *    - started_at = now()
 *    - starting_amount = newStartingAmount
 *    - is_first_shift = false
 *    - is_last_shift = false
 * 
 * 6. Kreira pazar_shift_handovers:
 *    - from_shift_id = previousShiftId
 *    - to_shift_id = newShift.id
 *    - from_user_id = prevShift.user_id
 *    - to_user_id = userId
 *    - reported_amount = prevShift.ending_amount (šta je prethodna smena prijavila)
 *    - received_amount = newStartingAmount (šta je nova smena izbrojala)
 *    - handover_type = 'colleague'
 *    - confirmed_at = now()
 * 
 * Primer:
 *   - Prethodna smena: ending_amount = 15,000 RSD (prijavljeno)
 *   - Nova smena broji: countedCash = 14,500, countedDeposit = 10,000
 *   - newStartingAmount = 24,500 RSD
 *   - Handover record: reported=15,000, received=24,500 (razlika = 9,500)
 *   - NAPOMENA: Razlika može biti zbog dopune ili greške u brojanju
 */

/*
 * 1.7. END SHIFT FLOW - Step-by-step proces
 * ------------------------------------------
 * 
 * Komponenta: EndShiftFlow.jsx
 * 
 * Flow Type: 'endday' (Završetak dana) - 8 koraka
 * Flow Type: 'handover' (Predaja kolegi) - 7 koraka
 * 
 * ENDDAY FLOW (8 koraka):
 * 
 * Step 0: EndChoiceStep
 *   - User bira: "Završi dan" ili "Predaj kolegi"
 *   - Ako "Završi dan": flowType = 'endday'
 *   - Ako "Predaj kolegi": flowType = 'handover'
 * 
 * Step 1: EbarWarningStep (samo za endday)
 *   - Upozorenje: "Obavezno štampaj E-Bar presek pre završetka!"
 *   - Potvrda checkbox
 * 
 * Step 2: DepositCheckStep
 *   - Prikazuje: deposit amount (default 10,000 RSD)
 *   - Upozorenje: "Ako fali novac u depozitu, dopuni iz kase!"
 *   - Potvrda checkbox: "Depozit je kompletan"
 * 
 * Step 3: CountingStep
 *   - Brojanje novca po apoenima
 *   - Denominations: [5000, 2000, 1000, 500, 200, 100, 50, 20, 10]
 *   - countedAmount = sum(denomination * quantity)
 *   - Upozorenje: "Obavezno brojati novac ispred kamere!"
 * 
 * Step 4: CountConfirmStep
 *   - Prikazuje: countedAmount
 *   - Potvrda: "Da, to je tačan iznos"
 *   - Lock count: isCountLocked = true
 * 
 * Step 5: EbarDataStep
 *   - Unos E-Bar podataka:
 *     * date (datum priznanice)
 *     * time (vreme priznanice)
 *     * cash (gotovina - ukupan promet)
 *     * card (kartice - terminal)
 *     * transfer (prenos na račun - opciono)
 *   - Validacija: cash > 0 && time !== ''
 * 
 * Step 6: ReconciliationStep
 *   - Kalkuliše expectedCash i difference
 *   - Prikazuje sravnjenje
 *   - Ako manjak: unos topupAmount, topupSource, topupComment
 *   - Ako višak: unos surplusSource, surplusComment
 * 
 * Step 7: FinalConfirmStep
 *   - Prikazuje: finalCashAmount (countedAmount + topupAmount)
 *   - Prikazuje: deposit
 *   - Potvrde: cashConfirmed, depositConfirmed
 *   - Submit: poziva endShiftEndOfDay() ili endShiftHandover()
 * 
 * Step 8: DoneStep
 *   - Potvrda završetka
 *   - Zatvara flow
 * 
 * HANDOVER FLOW (7 koraka):
 * 
 * Step 0: EndChoiceStep (isti kao endday)
 * Step 1: DepositCheckStep (preskače EbarWarningStep)
 * Step 2: CountingStep
 * Step 3: CountConfirmStep
 * Step 4: EbarDataStep
 * Step 5: ReconciliationStep
 * Step 6: FinalConfirmStep (poziva endShiftHandover())
 * Step 7: DoneStep
 */

/* ============================================================================
 * 2. CASH PICKUP FLOW - Vozač → Admin → Sef → Banka
 * ============================================================================
 */

/*
 * 2.1. CASH PICKUP STATUS MAŠINA
 * -------------------------------
 * 
 * Tabela: pazar_cash_pickups.status (TEXT)
 * 
 * Statusi:
 * - 'pending' - Čeka vozača (kreira se automatski sa endShiftEndOfDay)
 * - 'picked' - Vozač je preuzeo (picked_at se postavlja)
 * - 'delivered' - Vozač je dostavio (delivered_at se postavlja)
 * 
 * Tabela: pazar_finance_records.status (implicitno kroz timestamp polja)
 * 
 * Statusi (determinisani kroz timestamp polja):
 * - 'pending' - Nema zapisa (još nije primljeno)
 * - 'received' - received_at !== null (primljeno od vozača)
 * - 'verified' - verified_at !== null (prebrojano i verifikovano)
 * - 'in_transit' - taken_from_safe_at !== null (preuzeto iz sefa, na putu u banku)
 * - 'deposited' - banked_at !== null (deponovano u banku)
 * 
 * Flow:
 *   1. End of day → pazar_cash_collections (status='pending')
 *   2. Vozač preuzima → pazar_cash_pickups (picked_at)
 *   3. Vozač dostavlja → pazar_cash_pickups (delivered_at)
 *   4. Admin prima → pazar_finance_records (received_at)
 *   5. Admin broji → pazar_finance_records (verified_at, counted_amount)
 *   6. Admin preuzima iz sefa → pazar_finance_records (taken_from_safe_at)
 *   7. Admin deponuje → pazar_finance_records (banked_at)
 */

/*
 * 2.2. VOZAČ PICKUP (Preuzimanje novca od lokacije)
 * ---------------------------------------------------
 * 
 * Tabela: pazar_cash_pickups
 * 
 * Kreiranje:
 * - Automatski se kreira sa endShiftEndOfDay() → pazar_cash_collections
 * - Vozač vidi listu pending pickups
 * 
 * Update kada vozač preuzima:
 * - picked_at = now()
 * - driver_id = vozač.user_id
 * 
 * Update kada vozač dostavlja:
 * - delivered_at = now()
 * - status = 'delivered' (ili se koristi delivered_at za proveru)
 * 
 * NAPOMENA: Vozač pickup se ne implementira u trenutnom kodu - pretpostavlja
 *           se da se dešava van sistema ili kroz drugi modul.
 */

/*
 * 2.3. ADMIN RECEIVE (Prijem novca od vozača)
 * ---------------------------------------------
 * 
 * Komponenta: ReceiveModal.jsx
 * 
 * Logika:
 * 1. Admin vidi listu pickups sa delivered_at !== null
 * 2. Klikne "Primi" na pickup
 * 3. Kreira pazar_finance_records:
 *    - pickup_id = pickup.id
 *    - location_id = pickup.location_id
 *    - date = pickup.date
 *    - received_by = employee.id (admin koji prima)
 *    - received_at = now()
 * 
 * Status posle receive:
 * - Finance record postoji sa received_at
 * - Novac je primljen ali još nije prebrojan
 * - UI prikazuje "Primi" dugme → "Prebroj" dugme
 */

/*
 * 2.4. ADMIN COUNT/VERIFY (Brojanje i verifikacija)
 * --------------------------------------------------
 * 
 * Komponenta: CountModal.jsx
 * 
 * Logika:
 * 1. Učitava original denominations iz pazar_specification_denominations:
 *    - Query: SELECT * FROM pazar_specification_denominations 
 *             WHERE specification_id = lastShift.spec.id
 *    - Mapira u objekat: { 5000: 5, 2000: 3, ... }
 * 
 * 2. Kalkuliše originalTotal:
 *    originalTotal = sum(denomination * quantity) iz specifikacije
 * 
 * 3. Admin može:
 *    a) Potvrditi (mode='confirm'):
 *       - countedAmount = originalTotal
 *       - Ne menja denominations
 *    b) Izmeniti (mode='edit'):
 *       - Menja denominations po apoenima
 *       - editTotal = sum(denomination * editQuantity)
 *       - countedAmount = editTotal
 * 
 * 4. Kalkuliše expectedCash:
 *    expectedCash = (lastShift.spec.ebar_total || 0) - (lastShift.spec.terminal_amount || 0)
 *    - ebar_total = ukupan promet (gotovina + kartice)
 *    - terminal_amount = kartice
 *    - expectedCash = gotovina koja bi trebalo da bude u kasi
 * 
 * 5. Validacija razlike:
 *    - Ako |countedAmount - expectedCash| > 100 RSD:
 *      - Zahteva discrepancyReason (obavezno)
 *      - Opciono: discrepancyComment
 * 
 * 6. Update pazar_finance_records:
 *    - verified_at = now()
 *    - verified_by = employee.id
 *    - counted_amount = countedAmount
 *    - original_amount = originalTotal
 *    - original_denominations = originalDenoms (JSONB)
 *    - modified_denominations = mode === 'edit' ? editDenoms : null
 *    - spec_modified = mode === 'edit'
 *    - modification_reason = mode === 'edit' ? discrepancyReason : null
 *    - modification_comment = discrepancyComment || null
 * 
 * 7. Kreira ili update-uje pazar_bank_deposits:
 *    - Proverava da li postoji za location_id + date
 *    - Ako ne postoji: INSERT sa status='in_safe'
 *    - Ako postoji i status='in_safe' ili 'in_transit': UPDATE amount i denominations
 *    - Ako postoji i status='deposited': NE UPDATE (već je deponovano)
 * 
 * Status posle verify:
 * - Finance record ima verified_at
 * - Bank deposit postoji sa status='in_safe'
 * - UI prikazuje "Preuzmi iz sefa" dugme
 */

/*
 * 2.5. TAKE FROM SAFE (Preuzimanje iz sefa)
 * -------------------------------------------
 * 
 * Komponenta: TakeFromSafeModal.jsx
 * 
 * Logika:
 * 1. Admin vidi listu verified finance records (verified_at !== null, banked_at === null)
 * 2. Klikne "Preuzmi iz sefa"
 * 3. Modal prikazuje:
 *    - Denominations iz bank deposit
 *    - Uplatnica forma:
 *      * Uplatilac (companies dropdown)
 *      * Primalac (companies dropdown)
 *      * Svrha uplate (payment_purposes dropdown)
 *      * Banka / Račun (bank_accounts dropdown)
 *      * Iznos (read-only, iz deposit.amount)
 * 
 * 4. Admin štampa uplatnicu (print button)
 * 
 * 5. Update pazar_finance_records:
 *    - taken_from_safe_at = now()
 *    - taken_by = employee.id
 *    - payer_company_id = payerId (opciono, ako polje postoji)
 *    - recipient_company_id = recipientId (opciono)
 *    - bank_account_id = bankAccountId (opciono)
 *    - purpose_id = purposeId (opciono)
 * 
 * 6. Update pazar_bank_deposits (ako postoji):
 *    - status = 'in_transit' (na putu u banku)
 * 
 * Status posle take from safe:
 * - Finance record ima taken_from_safe_at
 * - Bank deposit ima status='in_transit'
 * - UI prikazuje "Deponovano" dugme
 */

/*
 * 2.6. BANK DEPOSIT (Deponovanje u banku)
 * -----------------------------------------
 * 
 * Komponenta: BankDepositModalNew.jsx
 * 
 * Logika:
 * 1. Učitava finance records:
 *    - verified_at !== null (verifikovano)
 *    - banked_at === null (još nije deponovano)
 * 
 * 2. Grupiše po statusu:
 *    - 'in_safe': verified_at !== null && taken_from_safe_at === null
 *    - 'in_transit': taken_from_safe_at !== null && banked_at === null
 *    - 'deposited': banked_at !== null
 * 
 * 3. Admin klikne "Deponovano" na deposit sa status='in_transit'
 * 
 * 4. Update pazar_finance_records:
 *    - banked_at = now()
 *    - banked_by = employee.id
 * 
 * Status posle deposit:
 * - Finance record ima banked_at
 * - Bank deposit ostaje sa status='in_transit' (ili se može update-ovati na 'deposited')
 * - UI prikazuje deposit kao "Deponovano"
 */

/* ============================================================================
 * 3. FORMULE - Sravnjenje kalkulacija (expected_cash, difference)
 * ============================================================================
 */

/*
 * 3.1. EXPECTED CASH KALKULACIJA
 * --------------------------------
 * 
 * Funkcija: calculateReconciliation() (shiftFlowStore.js)
 * 
 * Formula:
 *   expectedCash = ebarData.cash - ebarData.card
 * 
 * Objašnjenje:
 * - ebarData.cash = Ukupan promet u gotovini (uključuje i prodaju i povrat)
 * - ebarData.card = Ukupan promet na karticama (terminal)
 * - ebarData.transfer = Prenos na račun (NE računa se u expected cash)
 * 
 * Primer:
 *   E-Bar presek:
 *     - Gotovina: 50,000 RSD
 *     - Kartice: 30,000 RSD
 *     - Prenos: 5,000 RSD
 *   
 *   expectedCash = 50,000 - 30,000 = 20,000 RSD
 *   
 *   NAPOMENA: Prenos se NE oduzima jer nije relevantan za keš u kasi.
 *             Prenos je direktan transfer na račun, ne ide kroz kasu.
 */

/*
 * 3.2. DIFFERENCE KALKULACIJA
 * -----------------------------
 * 
 * Funkcija: calculateReconciliation() (shiftFlowStore.js)
 * 
 * Formula:
 *   difference = countedAmount - expectedCash
 * 
 * Objašnjenje:
 * - countedAmount = sum(denomination * quantity) - izbrojano u kasi
 * - expectedCash = ebarData.cash - ebarData.card
 * 
 * Rezultat:
 * - difference = 0: Sve se slaže ✓
 * - difference < 0: Manjak (nema dovoljno novca u kasi)
 * - difference > 0: Višak (ima više novca nego što bi trebalo)
 * 
 * Primer:
 *   expectedCash = 20,000 RSD
 *   countedAmount = 18,500 RSD
 *   difference = 18,500 - 20,000 = -1,500 RSD (manjak)
 * 
 * Primer:
 *   expectedCash = 20,000 RSD
 *   countedAmount = 21,200 RSD
 *   difference = 21,200 - 20,000 = +1,200 RSD (višak)
 */

/*
 * 3.3. FINAL CASH AMOUNT (Za sef/banku)
 * ---------------------------------------
 * 
 * Formula:
 *   finalCashAmount = countedAmount + topupAmount
 * 
 * Objašnjenje:
 * - countedAmount = izbrojano u kasi (bez dopune)
 * - topupAmount = dopuna ako je bio manjak
 * - finalCashAmount = ukupan keš koji ide u sef/banku
 * 
 * Primer:
 *   countedAmount = 18,500 RSD
 *   topupAmount = 1,500 RSD (dopunjeno iz džepa)
 *   finalCashAmount = 18,500 + 1,500 = 20,000 RSD
 * 
 * Upotreba:
 * - endShiftEndOfDay: amount = finalCashAmount (za cash collection i bank deposit)
 * - FinalConfirmStep: prikazuje finalCashAmount kao "Keš za SEF"
 */

/*
 * 3.4. STARTING AMOUNT KALKULACIJA (Za novu smenu)
 * --------------------------------------------------
 * 
 * Funkcija: takeoverShift()
 * 
 * Formula:
 *   newStartingAmount = countedCash + countedDeposit
 * 
 * Objašnjenje:
 * - countedCash = izbrojano u kasi (bez depozita)
 * - countedDeposit = izbrojani depozit (odvojen)
 * - newStartingAmount = ukupan početni iznos za novu smenu
 * 
 * Primer:
 *   Prethodna smena je završila sa:
 *     - countedAmount = 25,000 RSD (ukupno u kasi)
 *     - deposit = 10,000 RSD (depozit)
 *   
 *   Nova smena broji:
 *     - countedCash = 15,000 RSD (ostalo u kasi posle odvajanja depozita)
 *     - countedDeposit = 10,000 RSD (depozit)
 *   
 *   newStartingAmount = 15,000 + 10,000 = 25,000 RSD
 * 
 * NAPOMENA: Depozit se uvek vraća u kasu za novu smenu. Novi radnik
 *           počinje sa depozitom + ostatkom keša od prethodne smene.
 */

/* ============================================================================
 * 4. STATUS MAŠINA - Za pazar_shifts i pazar_finance_records
 * ============================================================================
 */

/*
 * 4.1. PAZAR_SHIFTS STATUS MAŠINA
 * ---------------------------------
 * 
 * Tabela: pazar_shifts
 * 
 * Polja:
 * - status: TEXT ('active' | 'handed_over' | 'closed')
 * - is_first_shift: BOOLEAN
 * - is_last_shift: BOOLEAN
 * - started_at: TIMESTAMP
 * - ended_at: TIMESTAMP
 * - starting_amount: DECIMAL
 * - ending_amount: DECIMAL
 * 
 * State Diagram:
 * 
 *   [Nema smene]
 *        |
 *        | startFirstShift() ili startShift()
 *        v
 *   [active, is_first_shift=true/false, is_last_shift=false]
 *        |
 *        | endShiftHandover()
 *        v
 *   [handed_over, ending_amount=X, is_last_shift=false]
 *        |
 *        | takeoverShift()
 *        v
 *   [closed, ended_at=Y]  +  [active (nova smena), starting_amount=Z]
 *        |
 *        | endShiftEndOfDay()
 *        v
 *   [closed, is_last_shift=true, ending_amount=X]
 * 
 * Validne kombinacije:
 * - active + is_first_shift=true + is_last_shift=false (prva smena)
 * - active + is_first_shift=false + is_last_shift=false (srednja smena)
 * - handed_over + is_last_shift=false (predata kolegi)
 * - closed + is_last_shift=false (zatvorena, ali nije poslednja)
 * - closed + is_last_shift=true (poslednja smena u danu)
 */

/*
 * 4.2. PAZAR_FINANCE_RECORDS STATUS MAŠINA
 * ------------------------------------------
 * 
 * Tabela: pazar_finance_records
 * 
 * Status se određuje kroz timestamp polja (nema eksplicitno status polje):
 * 
 * Status logika:
 * 
 * 1. 'pending' (nema zapisa):
 *    - Finance record ne postoji
 *    - UI prikazuje "Primi" dugme
 * 
 * 2. 'received' (received_at !== null):
 *    - received_by = user_id
 *    - received_at = timestamp
 *    - UI prikazuje "Prebroj" dugme
 * 
 * 3. 'verified' (verified_at !== null):
 *    - verified_by = user_id
 *    - verified_at = timestamp
 *    - counted_amount = izbrojani iznos
 *    - original_denominations = JSONB
 *    - modified_denominations = JSONB (ili null)
 *    - UI prikazuje "Preuzmi iz sefa" dugme
 * 
 * 4. 'in_transit' (taken_from_safe_at !== null):
 *    - taken_by = user_id
 *    - taken_from_safe_at = timestamp
 *    - payer_company_id, recipient_company_id, bank_account_id, purpose_id (opciono)
 *    - UI prikazuje "Deponovano" dugme
 * 
 * 5. 'deposited' (banked_at !== null):
 *    - banked_by = user_id
 *    - banked_at = timestamp
 *    - UI prikazuje "Deponovano" status (read-only)
 * 
 * State Diagram:
 * 
 *   [pending]
 *        |
 *        | ReceiveModal → INSERT
 *        v
 *   [received: received_at]
 *        |
 *        | CountModal → UPDATE verified_at
 *        v
 *   [verified: verified_at, counted_amount]
 *        |
 *        | TakeFromSafeModal → UPDATE taken_from_safe_at
 *        v
 *   [in_transit: taken_from_safe_at]
 *        |
 *        | BankDepositModalNew → UPDATE banked_at
 *        v
 *   [deposited: banked_at]
 */

/*
 * 4.3. PAZAR_BANK_DEPOSITS STATUS MAŠINA
 * ----------------------------------------
 * 
 * Tabela: pazar_bank_deposits
 * 
 * Statusi:
 * - 'in_safe': Novac je u sefu, čeka verifikaciju
 * - 'in_transit': Novac je preuzet iz sefa, na putu u banku
 * - 'deposited': Novac je deponovan u banku
 * 
 * Kreiranje:
 * - Automatski se kreira sa endShiftEndOfDay() sa status='in_safe'
 * - Ili se kreira sa CountModal kada se verifikuje sa status='in_safe'
 * 
 * Update:
 * - TakeFromSafeModal: status = 'in_transit'
 * - BankDepositModalNew: status može ostati 'in_transit' ili se može update-ovati na 'deposited'
 * 
 * NAPOMENA: Status se ne koristi direktno u trenutnom kodu - umesto toga
 *           se koriste timestamp polja iz pazar_finance_records.
 */

/* ============================================================================
 * 5. APOENI - Kako se broje i čuvaju denominacije
 * ============================================================================
 */

/*
 * 5.1. DENOMINATIONS LIST
 * ------------------------
 * 
 * Konstanta: DENOMINATIONS = [5000, 2000, 1000, 500, 200, 100, 50, 20, 10]
 * 
 * Format: Niz apoeni u RSD, sortirani od najvećeg ka najmanjem
 * 
 * Upotreba:
 * - CountingStep: prikazuje input za svaki apoen
 * - Denominations se čuvaju kao objekat: { 5000: 5, 2000: 3, 1000: 10, ... }
 */

/*
 * 5.2. COUNTED AMOUNT KALKULACIJA
 * ---------------------------------
 * 
 * Formula:
 *   countedAmount = sum(denomination * quantity) za sve apoeni
 * 
 * Implementacija:
 *   const total = DENOMINATIONS.reduce((sum, d) => {
 *     return sum + (denominations[d] * d);
 *   }, 0);
 * 
 * Primer:
 *   denominations = {
 *     5000: 5,   // 5 × 5,000 = 25,000
 *     2000: 3,   // 3 × 2,000 = 6,000
 *     1000: 10,  // 10 × 1,000 = 10,000
 *     500: 8,    // 8 × 500 = 4,000
 *     200: 5,    // 5 × 200 = 1,000
 *     100: 10,   // 10 × 100 = 1,000
 *     50: 0,
 *     20: 0,
 *     10: 0
 *   }
 *   
 *   countedAmount = 25,000 + 6,000 + 10,000 + 4,000 + 1,000 + 1,000 = 47,000 RSD
 */

/*
 * 5.3. ČUVANJE DENOMINATIONS U BAZI
 * -----------------------------------
 * 
 * Tabela: pazar_specification_denominations
 * 
 * Struktura:
 * - specification_id: UUID (FK → pazar_daily_specifications.id)
 * - denomination: INTEGER (5000, 2000, 1000, ...)
 * - quantity: INTEGER (broj komada)
 * 
 * Insert logika:
 * 1. Filtrira apoeni sa quantity > 0:
 *    Object.entries(denominations)
 *      .filter(([_, qty]) => qty > 0)
 * 
 * 2. Mapira u rows:
 *    .map(([denom, qty]) => ({
 *      specification_id: spec.id,
 *      denomination: parseInt(denom),
 *      quantity: qty
 *    }))
 * 
 * 3. Bulk insert:
 *    INSERT INTO pazar_specification_denominations (specification_id, denomination, quantity)
 *    VALUES (...), (...), ...
 * 
 * Primer:
 *   denominations = { 5000: 5, 2000: 3, 1000: 10, 500: 8, ... }
 *   
 *   Insert:
 *     (spec_id, 5000, 5)
 *     (spec_id, 2000, 3)
 *     (spec_id, 1000, 10)
 *     (spec_id, 500, 8)
 *     ...
 */

/*
 * 5.4. DENOMINATIONS U BANK DEPOSITS
 * ------------------------------------
 * 
 * Tabela: pazar_bank_deposits.denomination_counts (JSONB)
 * 
 * Format:
 *   {
 *     "5000": 5,
 *     "2000": 3,
 *     "1000": 10,
 *     "500": 8,
 *     ...
 *   }
 * 
 * Kreiranje:
 * 1. Uzima denominations iz pazar_specification_denominations:
 *    SELECT denomination, quantity 
 *    FROM pazar_specification_denominations 
 *    WHERE specification_id = spec.id
 * 
 * 2. Mapira u objekat:
 *    const denominationCounts = {};
 *    denomsData.forEach(d => {
 *      denominationCounts[d.denomination] = d.quantity;
 *    });
 * 
 * 3. Čuva u pazar_bank_deposits:
 *    INSERT INTO pazar_bank_deposits (..., denomination_counts)
 *    VALUES (..., denominationCounts)
 * 
 * NAPOMENA: denomination_counts se koristi za prikaz u TakeFromSafeModal
 *           i za audit trail.
 */

/*
 * 5.5. ORIGINAL vs MODIFIED DENOMINATIONS
 * -----------------------------------------
 * 
 * Tabela: pazar_finance_records
 * 
 * Polja:
 * - original_denominations: JSONB (iz specifikacije)
 * - modified_denominations: JSONB (ako je admin izmenio) ili NULL
 * 
 * Logika:
 * 1. Original se učitava iz pazar_specification_denominations
 * 2. Ako admin potvrdi (mode='confirm'):
 *    - modified_denominations = NULL
 *    - counted_amount = originalTotal
 * 3. Ako admin izmeni (mode='edit'):
 *    - modified_denominations = editDenoms (JSONB)
 *    - counted_amount = editTotal
 *    - spec_modified = true
 *    - modification_reason = discrepancyReason
 *    - modification_comment = discrepancyComment
 * 
 * Primer:
 *   Original: { 5000: 5, 2000: 3 } → total = 31,000
 *   Modified: { 5000: 4, 2000: 4 } → total = 28,000
 *   Razlika: -3,000 RSD
 *   Reason: "counting_error" ili "missing_cash"
 */

/* ============================================================================
 * 6. EDGE CASES - Šta ako fali novac, dopuna, etc.
 * ============================================================================
 */

/*
 * 6.1. MANJAK U KASI (Shortage)
 * ------------------------------
 * 
 * Scenario: countedAmount < expectedCash
 * 
 * Primer:
 *   expectedCash = 20,000 RSD
 *   countedAmount = 18,500 RSD
 *   difference = -1,500 RSD
 * 
 * Rešenje:
 * 1. ReconciliationStep prikazuje upozorenje: "⚠️ Manjak u kasi - dopuni razliku!"
 * 
 * 2. Admin unosi:
 *    - topupAmount: 1,500 RSD (koliko je dopunio)
 *    - topupSource: 'own_pocket' | 'tip_jar' | 'colleague' | 'other'
 *    - topupComment: "Dopunjeno iz džepa" (opciono)
 * 
 * 3. Validacija:
 *    - Ako |difference| > 1000: zahteva topupSource (obavezno)
 *    - topupAmount može biti manji ili jednak razlici
 * 
 * 4. Čuvanje:
 *    - pazar_daily_specifications.topup_amount = topupAmount
 *    - pazar_daily_specifications.topup_source = topupSource
 *    - pazar_daily_specifications.topup_comment = topupComment
 * 
 * 5. Final cash amount:
 *    finalCashAmount = countedAmount + topupAmount
 *    - Ovaj iznos ide u sef/banku
 * 
 * NAPOMENA: Ako topupAmount < |difference|, razlika se ne pokriva potpuno.
 *           Sistem ne sprečava ovo - admin je odgovoran za tačnost.
 */

/*
 * 6.2. VIŠAK U KASI (Surplus)
 * -----------------------------
 * 
 * Scenario: countedAmount > expectedCash
 * 
 * Primer:
 *   expectedCash = 20,000 RSD
 *   countedAmount = 21,200 RSD
 *   difference = +1,200 RSD
 * 
 * Rešenje:
 * 1. ReconciliationStep prikazuje: "💰 Višak u kasi"
 * 
 * 2. Admin unosi:
 *    - surplusSource: 'tips' | 'rounding' | 'unknown'
 *    - surplusComment: "Napojnice" (opciono)
 * 
 * 3. Validacija:
 *    - Ako |difference| > 1000: zahteva surplusSource (obavezno)
 * 
 * 4. Čuvanje:
 *    - pazar_daily_specifications.shortage_reason = surplusSource
 *      (NAPOMENA: field name je "shortage_reason" ali se koristi i za surplus)
 *    - pazar_daily_specifications.shortage_comment = surplusComment
 * 
 * 5. Final cash amount:
 *    finalCashAmount = countedAmount (bez topupAmount jer nema manjka)
 *    - Ovaj iznos ide u sef/banku
 * 
 * NAPOMENA: Višak se ne "vraća" - ostaje u kasi i ide u sef/banku.
 */

/*
 * 6.3. NEDOSTAJE NOVAC U DEPOZITU
 * ---------------------------------
 * 
 * Scenario: Depozit nije kompletan (fali novac)
 * 
 * Rešenje:
 * 1. DepositCheckStep prikazuje:
 *    - Deposit treba da bude: 10,000 RSD (default)
 *    - Upozorenje: "⚠️ Ako fali novac u depozitu, dopuni iz kase do punog iznosa!"
 * 
 * 2. Admin mora:
 *    - Dopuniti depozit iz countedAmount do punog iznosa
 *    - Potvrditi checkbox: "Depozit je kompletan"
 * 
 * 3. Logika:
 *    - deposit se ne menja (ostaje 10,000 RSD)
 *    - countedAmount se smanjuje za iznos koji je otišao u depozit
 *    - Final cash amount = countedAmount - (deposit - originalDeposit)
 * 
 * Primer:
 *   Original deposit: 10,000 RSD
 *   Trenutni deposit: 8,000 RSD (fali 2,000)
 *   countedAmount: 25,000 RSD
 *   
 *   Admin dopunjava: countedAmount = 25,000 - 2,000 = 23,000 RSD
 *   Deposit: 8,000 + 2,000 = 10,000 RSD ✓
 *   Final cash: 23,000 RSD (za sef)
 * 
 * NAPOMENA: Sistem ne automatski ne proverava da li je depozit kompletan.
 *           Admin je odgovoran za proveru pre potvrde.
 */

/*
 * 6.4. RAZLIKA PRI PREDAJI SMENE (Handover Discrepancy)
 * -------------------------------------------------------
 * 
 * Scenario: Kolega broji drugačiji iznos nego što je prethodna smena prijavila
 * 
 * Primer:
 *   Prethodna smena (Marko):
 *     - ending_amount = 15,000 RSD (prijavljeno)
 *     - countedAmount = 15,000 RSD
 *   
 *   Nova smena (Ana):
 *     - countedCash = 14,500 RSD
 *     - countedDeposit = 10,000 RSD
 *     - newStartingAmount = 24,500 RSD
 *   
 *   Razlika: 24,500 - 15,000 = 9,500 RSD
 * 
 * Rešenje:
 * 1. Handover record čuva oba iznosa:
 *    - reported_amount = 15,000 (šta je Marko prijavio)
 *    - received_amount = 24,500 (šta je Ana izbrojala)
 * 
 * 2. Razlika se ne "ispravlja" automatski:
 *    - Ana počinje sa newStartingAmount = 24,500
 *    - Razlika ostaje u handover record-u za audit
 * 
 * 3. Mogući razlozi razlike:
 *    - Greška u brojanju (Marko ili Ana)
 *    - Dopuna između smena (neko je dodao novac)
 *    - Krađa/gubitak (retko, ali moguće)
 * 
 * NAPOMENA: Sistem ne sprečava razlike - samo ih dokumentuje.
 *           Admin može kasnije pregledati handover records za audit.
 */

/*
 * 6.5. DISCREPANCY PRI VERIFIKACIJI (Count Modal)
 * -------------------------------------------------
 * 
 * Scenario: Admin broji drugačiji iznos nego što je u specifikaciji
 * 
 * Primer:
 *   Specifikacija (iz objekta):
 *     - originalTotal = 20,000 RSD
 *     - Denominations: { 5000: 3, 2000: 2, 1000: 5 }
 *   
 *   Admin broji:
 *     - editTotal = 18,500 RSD
 *     - Denominations: { 5000: 2, 2000: 3, 1000: 5 }
 *   
 *   Razlika: -1,500 RSD
 * 
 * Rešenje:
 * 1. Admin može:
 *    a) Potvrditi (mode='confirm'):
 *       - counted_amount = originalTotal
 *       - Ne menja denominations
 *    b) Izmeniti (mode='edit'):
 *       - counted_amount = editTotal
 *       - Čuva original_denominations i modified_denominations
 * 
 * 2. Validacija:
 *    - Ako |editTotal - expectedCash| > 100 RSD:
 *      - Zahteva modification_reason (obavezno)
 *      - Opciono: modification_comment
 * 
 * 3. Razlozi (modification_reason):
 *    - 'counting_error': Greška pri brojanju
 *    - 'missing_cash': Nedostaje novac
 *    - 'extra_cash': Višak novca
 *    - 'denomination_error': Pogrešni apoeni
 *    - 'change_error': Greška u kusuru
 *    - 'other': Ostalo
 * 
 * 4. Čuvanje:
 *    - original_amount = originalTotal
 *    - original_denominations = originalDenoms (JSONB)
 *    - modified_denominations = editDenoms (JSONB)
 *    - spec_modified = true
 *    - modification_reason = discrepancyReason
 *    - modification_comment = discrepancyComment
 * 
 * NAPOMENA: Original se uvek čuva za audit. Modified se koristi za
 *           kalkulacije i bank deposit.
 */

/*
 * 6.6. MULTIPLE SHIFTS PER DAY
 * ------------------------------
 * 
 * Scenario: Više smena u jednom danu na istoj lokaciji
 * 
 * Primer:
 *   Shift 1 (Marko, 08:00-16:00):
 *     - shift_order = 1
 *     - is_first_shift = true
 *     - is_last_shift = false
 *     - status = 'handed_over'
 *   
 *   Shift 2 (Ana, 16:00-00:00):
 *     - shift_order = 2
 *     - is_first_shift = false
 *     - is_last_shift = true
 *     - status = 'closed'
 * 
 * Logika:
 * 1. shift_order se automatski kalkuliše:
 *    - Query za max(shift_order) + 1
 *    - Fallback: previousShift.shift_order + 1
 * 
 * 2. is_first_shift:
 *    - true ako shift_order === 1
 *    - false inače
 * 
 * 3. is_last_shift:
 *    - true samo za endShiftEndOfDay()
 *    - false za endShiftHandover()
 * 
 * 4. Cash collection se kreira samo za is_last_shift = true
 * 
 * 5. Bank deposit se kreira samo za is_last_shift = true
 * 
 * NAPOMENA: Svaka smena kreira svoju specifikaciju, ali samo poslednja
 *           smena kreira cash collection i bank deposit.
 */

/*
 * 6.7. MISSING E-BAR DATA
 * -------------------------
 * 
 * Scenario: E-Bar presek nije štampan ili je izgubljen
 * 
 * Rešenje:
 * 1. EbarWarningStep prikazuje upozorenje:
 *    "Obavezno štampaj E-Bar presek pre završetka!"
 * 
 * 2. Admin mora potvrditi checkbox pre nastavka
 * 
 * 3. EbarDataStep dozvoljava unos:
 *    - cash, card, transfer (ručno unos)
 *    - date, time (datum i vreme priznanice)
 * 
 * 4. Ako nema priznanice:
 *    - Admin može uneti podatke iz memorije ili procene
 *    - Sistem ne validira da li su podaci tačni
 * 
 * NAPOMENA: Sistem ne sprečava završetak smene bez E-Bar podataka.
 *           Admin je odgovoran za tačnost podataka.
 */

/*
 * 6.8. BANK DEPOSIT ALREADY EXISTS
 * ----------------------------------
 * 
 * Scenario: Bank deposit već postoji kada se verifikuje novac
 * 
 * Rešenje (CountModal.jsx):
 * 1. Proverava da li postoji pazar_bank_deposits za location_id + date
 * 
 * 2. Ako postoji:
 *    - Ako status = 'in_safe' ili 'in_transit':
 *      → UPDATE amount i denomination_counts
 *    - Ako status = 'deposited':
 *      → NE UPDATE (već je deponovano, ne menjati)
 * 
 * 3. Ako ne postoji:
 *    → INSERT sa status = 'in_safe'
 * 
 * NAPOMENA: Bank deposit se kreira automatski sa endShiftEndOfDay(),
 *           ali se može update-ovati kada admin verifikuje novac.
 */

/*
 * 6.9. FINANCE RECORD ALREADY EXISTS
 * ------------------------------------
 * 
 * Scenario: Finance record već postoji kada admin pokušava da primi novac
 * 
 * Rešenje (ReceiveModal.jsx):
 * 1. Proverava da li postoji pazar_finance_records za pickup_id
 * 
 * 2. Ako postoji:
 *    - UI ne prikazuje "Primi" dugme
 *    - UI prikazuje "Prebroj" dugme (ako received_at postoji)
 * 
 * 3. Ako ne postoji:
 *    → INSERT sa received_at
 * 
 * NAPOMENA: Duplicate key error se sprečava proverom pre insert-a.
 *           UI ne dozvoljava dupli prijem.
 */

/* ============================================================================
 * 7. DODATNE NAPOMENE
 * ============================================================================
 */

/*
 * 7.1. DEPOSIT DEFAULT VALUE
 * ---------------------------
 * 
 * Default deposit: 10,000 RSD
 * 
 * Učitavanje:
 * - getLocationDeposit(locationId) → pazar_locations.current_deposit
 * - Fallback: 10,000 RSD ako ne postoji u bazi
 * 
 * Upotreba:
 * - DepositCheckStep: prikazuje deposit amount
 * - FinalConfirmStep: prikazuje deposit koji ostaje u kasi
 * - takeoverShift: countedDeposit se koristi za newStartingAmount
 */

/*
 * 7.2. DENOMINATIONS LOCK
 * ------------------------
 * 
 * State: isCountLocked (shiftFlowStore)
 * 
 * Logika:
 * - Počinje sa false (može se menjati)
 * - Postavlja se na true u CountConfirmStep kada admin potvrdi iznos
 * - Kada je locked, denominations se ne mogu menjati
 * 
 * Svrha:
 * - Sprečava slučajne izmene nakon potvrde
 * - Osigurava audit trail
 */

/*
 * 7.3. HANDOVER TYPE
 * -------------------
 * 
 * Tabela: pazar_shift_handovers.handover_type (TEXT)
 * 
 * Tipovi:
 * - 'deposit': Prva smena dobija depozit (startFirstShift)
 * - 'colleague': Predaja između kolega (takeoverShift)
 * 
 * Upotreba:
 * - Audit trail: razlikuje prvu smenu od predaje kolegi
 * - Reporting: može se koristiti za analizu handover patterns
 */

/*
 * 7.4. DATE NORMALIZATION
 * ------------------------
 * 
 * Problem: Datumi mogu biti u različitim formatima (TIMESTAMP vs DATE)
 * 
 * Rešenje:
 * - normalizeDate() funkcija u pazarFinanceService.js
 * - Konvertuje TIMESTAMP u YYYY-MM-DD format
 * - Koristi se za grouping i matching
 * 
 * Primer:
 *   Input: "2026-01-17T12:30:00Z"
 *   Output: "2026-01-17"
 */

/*
 * 7.5. FOREIGN KEY RELATIONSHIPS
 * --------------------------------
 * 
 * pazar_shifts:
 * - user_id → pazar_users.id
 * - location_id → pazar_locations.id
 * 
 * pazar_daily_specifications:
 * - shift_id → pazar_shifts.id
 * - user_id → pazar_users.id
 * - location_id → pazar_locations.id
 * 
 * pazar_specification_denominations:
 * - specification_id → pazar_daily_specifications.id
 * 
 * pazar_shift_handovers:
 * - from_shift_id → pazar_shifts.id
 * - to_shift_id → pazar_shifts.id
 * - from_user_id → pazar_users.id
 * - to_user_id → pazar_users.id
 * - location_id → pazar_locations.id
 * 
 * pazar_cash_collections:
 * - specification_id → pazar_daily_specifications.id
 * - location_id → pazar_locations.id
 * 
 * pazar_cash_pickups:
 * - driver_id → pazar_users.id
 * - location_id → pazar_locations.id
 * 
 * pazar_finance_records:
 * - pickup_id → pazar_cash_pickups.id
 * - location_id → pazar_locations.id
 * - received_by → pazar_users.id (fk_received_by)
 * - verified_by → pazar_users.id (fk_verified_by)
 * - banked_by → pazar_users.id (fk_banked_by)
 * - taken_by → pazar_users.id (opciono)
 * 
 * pazar_bank_deposits:
 * - location_id → pazar_locations.id
 * - deposited_by → pazar_users.id (opciono)
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
