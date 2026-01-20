# COLLINA PLATFORM - Master Documentation Index
## Version 3.0 | January 20, 2026

---

## 🎯 Quick Start for AI

**Before ANY database work, ALWAYS read:**
```
COLLINA_REFERENCE.sql
```

This is the **single source of truth** for:
- All table schemas and columns
- All Supabase queries by module
- JOIN patterns and FK relationships
- Delete order (FK dependencies)
- Common errors and solutions
- Diagnostic queries

**Validation Code:** `COLLINA-2026-PAZAR-V3`

---

## 📚 Documentation Structure

### 🗄️ DATABASE & QUERIES (Primary Source)

| File | Contents |
|------|----------|
| **COLLINA_REFERENCE.sql** | Complete database reference - schemas, queries, patterns, errors |

**SQL Sections:**
- Section 1-7: All table definitions
- Section 8: JOIN patterns (multi-FK)
- Section 9: Delete order (FK dependencies)
- Section 10: Common errors & solutions
- Section 11: Views
- Section 12: Test credentials
- Section 13-18: All queries by module
- Section 19: Diagnostic queries
- Section 20: Magacin API

---

### 📋 BUSINESS LOGIC (How things work)

| File | Contents |
|------|----------|
| AUTH_BUSINESS_LOGIC.md | Login flows, session management, permission system |
| PAZAR_BUSINESS_LOGIC.md | Shift flow, cash pickup, reconciliation, bank deposits |
| ANALYTICS_BUSINESS_LOGIC.md | KPI calculations, data flow, projections |
| ORDERS_BUSINESS_LOGIC.md | Realtime subscriptions, status flow, table discounts |
| COLLINA_BUSINESS_RULES.md | Location mapping, shift rules, margin calculations |

---

### 🏗️ APPLICATION STRUCTURE (Where things are)

| File | Contents |
|------|----------|
| PROJECT_STRUCTURE.md | Directory structure, module organization, file locations |
| APP_ROUTING_STRUCTURE.md | Routes, layouts, protected routes, redirects |

---

### 🎨 UI/UX & PATTERNS (How things look)

| File | Contents |
|------|----------|
| UI_UX_PATTERNS.md | Design system, components, Serbian locale, currency format |
| STATE_MANAGEMENT_PATTERNS.md | Zustand stores, AuthContext, persistence |
| DATA_FORMATS_CONVENTIONS.md | Date formats, naming conventions, ID formats |

---

### 🔧 TECHNICAL (How to build & deploy)

| File | Contents |
|------|----------|
| EXTERNAL_INTEGRATIONS.md | eMeni webhook, Magacin API, Edge Functions |
| SECURITY_MEASURES.md | RLS concepts, API keys, input sanitization |
| PERFORMANCE_OPTIMIZATIONS.md | Pagination, caching, query optimization |
| DEPLOYMENT_ENVIRONMENT_CONFIG.md | Env variables, Vercel, build process |
| TESTING_DEBUGGING_STRATEGIES.md | Test data, debug queries, common issues |

---

### 📦 MODULE-SPECIFIC (Future reference)

| File | Contents |
|------|----------|
| KDS_MENU_SUPABASE_QUERIES.md | Placeholder for KDS & Menu modules |
| MAGACIN_API_QUERIES.md | Detailed Magacin API documentation |

---

## 🚀 AI Instructions

### For Database/Query Questions
```
1. Open COLLINA_REFERENCE.sql
2. Find relevant section (1-20)
3. Use exact column names and patterns shown
4. Follow JOIN patterns from Section 8
5. Follow delete order from Section 9
```

### For Business Logic Questions
```
1. Check relevant _BUSINESS_LOGIC.md file
2. Understand the flow/rules
3. Cross-reference with SQL for implementation
```

### For UI/Code Questions
```
1. Check PROJECT_STRUCTURE.md for file locations
2. Check APP_ROUTING_STRUCTURE.md for routes
3. Check UI_UX_PATTERNS.md for component patterns
```

---

## 📍 Key Reference Points

### Test Accounts (from SQL Section 12)
| Role | Name | PIN | Email |
|------|------|-----|-------|
| admin | Admin Test | 99999 | markosavic82@gmail.com |
| finansije | Marko Mišić | - | markomisic@collina.rs |
| konobar | Jelena Popovic | 05002 | - |
| vozac | Petar Dostavljač | 22222 | - |
| menadzer | Stefan Djordjevic | 03001 | - |

### Production Locations (from SQL Section 2)
| Code | Name | UUID |
|------|------|------|
| MP-PAL | Palacinkarnica Collina | a1000000-...-000001 |
| MP-P47 | Collina Pozeska 47 | a1000000-...-000002 |
| MP-P96 | Collina Pozeska 96 | a1000000-...-000003 |
| MP-NBG | Collina Novi Beograd | a1000000-...-000004 |
| MP-DRV | Collina Dravska | a1000000-...-000005 |
| PRO-PEK | Pekarica Collina | a1000000-...-000006 |
| FT | Food Truck | a1000000-...-000007 |

### Status Flows (from SQL & Business Logic)

**Shift Status:**
```
active → handed_over → closed
```

**Finance Record Status (by columns):**
```
received_at → counted_amount → verified_at → taken_from_safe_at → banked_at
(PRIMLJENO)   (PREBROJANO)    (U SEFU)      (NA PUTU)           (DEPONOVANO)
```

**Bank Deposit Status:**
```
in_safe → in_transit → deposited → confirmed
```

---

## ⚠️ Critical Reminders

### Location ID Types
```
pazar_locations.id = UUID (a1000000-0000-0000-0000-000000000001)
eMeni company_id = INTEGER (310, 1513, 1514)

⚠️ NEVER mix these! Frontend must send UUID, not eMeni ID.
```

### Multi-FK JOIN Pattern
```javascript
// ❌ WRONG - Supabase doesn't know which FK
.select('*, user:pazar_users(first_name)')

// ✅ CORRECT - Explicit FK name
.select('*, user:pazar_users!user_id(first_name)')
.select('*, driver:pazar_users!driver_id(first_name)')
```

### Delete Order (FK Dependencies)
```
1. pazar_bank_deposits
2. pazar_finance_records
3. pazar_cash_pickups
4. pazar_cash_collections
5. pazar_specification_denominations
6. pazar_daily_specifications
7. pazar_shift_handovers
8. pazar_shifts (LAST!)
9. pazar_safe_transactions
```

---

## 🔄 Maintenance

### When adding new columns:
1. Update COLLINA_REFERENCE.sql
2. Push to Gist
3. No need to update .md files

### When adding new business rules:
1. Update relevant _BUSINESS_LOGIC.md file
2. Update SQL if queries are affected

### When adding new routes/components:
1. Update PROJECT_STRUCTURE.md
2. Update APP_ROUTING_STRUCTURE.md

---

## 📞 Contact

**Maintainer:** Marko Savić  
**Email:** markosavic82@gmail.com  
**Gist:** https://gist.github.com/markosavic82-droid/632f3e59823fc26ae18f985e8dd40c4f

---

*Last Updated: January 20, 2026*
*Documentation Version: 3.0*
