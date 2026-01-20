# Collina Project - Struktura Projekta

## 📁 src/ Direktorijum

```
src/
├── App.jsx                    # Glavna React komponenta sa rutama
├── App.css                    # Globalni CSS stilovi
├── main.jsx                   # React entry point
├── index.css                  # Bazni CSS stilovi
│
├── assets/                    # Statički resursi
│   └── react.svg
│
├── components/                # Globalne komponente
│   └── index.js               # Export za globalne komponente
│
├── core/                      # Core funkcionalnosti aplikacije
│   ├── auth/                  # Autentifikacija i autorizacija
│   │   ├── AuthContext.jsx   # React Context za auth state
│   │   ├── AuthGuard.jsx     # Guard komponenta za zaštićene rute
│   │   ├── LoginPage.jsx     # Login stranica
│   │   ├── PermissionGuard.jsx # Guard za permisije
│   │   ├── ProtectedRoute.jsx # Route wrapper sa permisijama
│   │   ├── useAuth.js        # Custom hook za auth
│   │   └── index.js
│   │
│   ├── layouts/               # Layout komponente
│   │   ├── AdminLayout.jsx   # Admin panel layout
│   │   ├── Sidebar.jsx       # Sidebar navigacija
│   │   └── BottomNav.jsx     # Bottom navigacija (mobile)
│   │
│   └── index.js
│
├── lib/                       # Biblioteke i utility funkcije
│   └── supabase.js           # Supabase client konfiguracija
│
├── modules/                   # ⭐ GLAVNI MODULI APLIKACIJE
│   │
│   ├── analytics/            # 📊 Smart Analitika modul
│   │   ├── components/       # Komponente za grafikone i kartice
│   │   │   ├── CategoryMix.jsx
│   │   │   ├── ChannelCards.jsx
│   │   │   ├── ChannelMix.jsx
│   │   │   ├── ComparisonGrid.jsx
│   │   │   ├── DateRangePicker.jsx
│   │   │   ├── Heatmap.jsx
│   │   │   ├── HourlyChart.jsx
│   │   │   ├── KPICard.jsx
│   │   │   ├── LocationList.jsx
│   │   │   ├── LocationPerformance.jsx
│   │   │   ├── PerformanceCard.jsx
│   │   │   ├── ProductsTable.jsx
│   │   │   ├── ProjectionChart.jsx
│   │   │   └── TrendChart.jsx
│   │   ├── hooks/
│   │   │   └── useAnalyticsData.js
│   │   ├── pages/
│   │   │   ├── AnalyticsDashboard.jsx
│   │   │   └── DashboardPage.jsx
│   │   ├── services/
│   │   │   └── analyticsService.js
│   │   ├── utils/
│   │   │   ├── dateFilters.js
│   │   │   ├── formatCurrency.js
│   │   │   └── supabasePagination.js
│   │   └── module.config.js
│   │
│   ├── magacin/               # 📦 Magacin modul (upravljanje zalihama)
│   │   ├── components/       # UI komponente
│   │   │   ├── ArtikalRow.jsx
│   │   │   ├── CartModal.jsx
│   │   │   ├── CartSummary.jsx
│   │   │   ├── CategoryChips.jsx
│   │   │   ├── PrenosDetailModal.jsx
│   │   │   ├── StatusBadge.jsx
│   │   │   ├── StockCard.jsx
│   │   │   ├── SuggestionsModal.jsx
│   │   │   └── TrebovanjeDetailModal.jsx
│   │   ├── config/
│   │   │   └── magacinConfig.js
│   │   ├── hooks/
│   │   │   ├── useArtikli.js
│   │   │   └── useCart.js
│   │   ├── pages/
│   │   │   ├── MagacinLayout.jsx
│   │   │   ├── MagacinTestPage.jsx
│   │   │   ├── NedostajePage.jsx
│   │   │   ├── PrenosiPage.jsx
│   │   │   ├── TrebovanjaListPage.jsx
│   │   │   └── TrebovanjePage.jsx
│   │   └── services/
│   │       └── magacinService.js
│   │
│   ├── orders/                # 🛒 Live Porudžbine modul
│   │   ├── components/
│   │   │   ├── OrderCard.jsx
│   │   │   ├── OrderDetailModal.jsx
│   │   │   ├── OrdersFilterSidebar.jsx
│   │   │   ├── OrdersTable.jsx
│   │   │   └── StatusTabs.jsx
│   │   ├── pages/
│   │   │   └── LiveOrdersPage.jsx
│   │   └── services/
│   │       └── ordersService.js
│   │
│   ├── pazar/                 # 💰 Pazar modul (cash management)
│   │   ├── components/
│   │   │   ├── auth/          # Autentifikacija (PIN login)
│   │   │   │   ├── PinInput.jsx
│   │   │   │   ├── PinNumpad.jsx
│   │   │   │   ├── UserList.jsx
│   │   │   │   └── UserSearch.jsx
│   │   │   ├── cards/         # Kartice
│   │   │   │   ├── DemoCard.jsx
│   │   │   │   ├── QuickActionCard.jsx
│   │   │   │   └── ShiftCard.jsx
│   │   │   ├── layout/        # Layout komponente
│   │   │   │   ├── AppHeader.jsx
│   │   │   │   └── BottomNav.jsx
│   │   │   └── shift/         # Shift management
│   │   │       ├── EndShiftFlow.jsx
│   │   │       ├── StartFirstShiftModal.jsx
│   │   │       ├── TakeoverShiftModal.jsx
│   │   │       └── steps/     # Multi-step flow komponente
│   │   │           ├── CountConfirmStep.jsx
│   │   │           ├── CountingStep.jsx
│   │   │           ├── DepositCheckStep.jsx
│   │   │           ├── DoneStep.jsx
│   │   │           ├── EbarDataStep.jsx
│   │   │           ├── EbarWarningStep.jsx
│   │   │           ├── EndChoiceStep.jsx
│   │   │           ├── FinalConfirmStep.jsx
│   │   │           └── ReconciliationStep.jsx
│   │   ├── pages/
│   │   │   ├── DashboardPage.jsx
│   │   │   ├── FinanceDashboardPage.jsx
│   │   │   ├── PinLoginPage.jsx
│   │   │   ├── SefDashboardPage.jsx
│   │   │   └── VozacDashboardPage.jsx
│   │   ├── services/
│   │   │   └── pazarService.js
│   │   ├── stores/            # Zustand stores
│   │   │   ├── pazarAuthStore.js
│   │   │   └── shiftFlowStore.js
│   │   ├── utils/
│   │   │   ├── constants.js
│   │   │   └── formatters.js
│   │   ├── IMPLEMENTATION_STATUS.md
│   │   └── README.md
│   │
│   ├── staff/                 # 👥 Staff App modul
│   │   ├── components/
│   │   │   ├── dashboard/
│   │   │   │   └── ModuleCard.jsx
│   │   │   ├── layout/
│   │   │   │   ├── StaffBottomNav.jsx
│   │   │   │   ├── StaffHeader.jsx
│   │   │   │   └── StaffLayout.jsx
│   │   │   └── pickup/        # Pickup funkcionalnosti
│   │   │       ├── DateSelector.jsx
│   │   │       ├── DeliverAllModal.jsx
│   │   │       ├── LocationCard.jsx
│   │   │       ├── LocationDetail.jsx
│   │   │       ├── PhotoPickupModal.jsx
│   │   │       ├── StatsCards.jsx
│   │   │       └── Timeline.jsx
│   │   ├── config/
│   │   │   └── staffCards.config.js
│   │   ├── hooks/
│   │   │   └── useStaffCards.js
│   │   ├── pages/
│   │   │   ├── PickupPage.jsx
│   │   │   ├── StaffDashboardPage.jsx
│   │   │   ├── StaffHomePage.jsx
│   │   │   └── StaffLoginPage.jsx
│   │   └── services/
│   │       └── pickupService.js
│   │
│   ├── staff-app/             # 📱 Staff App (legacy/placeholder)
│   │   ├── components/
│   │   │   └── ShiftCard.jsx
│   │   ├── pages/
│   │   │   └── HomePage.jsx
│   │   └── module.config.js
│   │
│   └── index.js
│
└── pages/                     # Admin stranice (legacy struktura)
    └── admin/
        └── pazar/             # Admin Pazar stranice
            ├── AdminPickupsPage.jsx
            ├── AdminShiftsPage.jsx
            ├── BankSettingsPage.jsx
            ├── FinanceBankPage.jsx
            ├── FinanceReceivePage.jsx
            ├── FinanceSafePage.jsx
            ├── PazarOverviewPage.jsx
            ├── components/   # Admin Pazar komponente
            │   ├── BankActionBar.jsx
            │   ├── BankDepositModal.jsx
            │   ├── BankDepositModalNew.jsx
            │   ├── CashFlowCards.jsx
            │   ├── CashFlowDetailModal.jsx
            │   ├── CountModal.jsx
            │   ├── LocationDayCard.jsx
            │   ├── PazarFilters.jsx
            │   ├── PazarStatsCards.jsx
            │   ├── ReceiveModal.jsx
            │   ├── ShiftDetailModal.jsx
            │   ├── ShiftsTable.jsx
            │   └── TakeFromSafeModal.jsx
            ├── services/
            │   └── pazarFinanceService.js
            ├── BANK_DEPOSIT_MIGRATIONS.md
            └── PAZAR_FINANCE_RECORDS_MIGRATION.md
```

---

## 📋 Detaljni Opis Modula

### 1. **analytics/** - Smart Analitika
**Opis:** Modul za analizu prodaje, performansi lokacija, grafikone i KPI metrike.

**Funkcionalnosti:**
- Dashboard sa KPI kartama
- Grafikoni (hourly, trend, projection, heatmap)
- Poređenje lokacija
- Analiza kanala prodaje
- Tabela proizvoda
- Filteri po datumu i lokaciji

**Ključne komponente:**
- `DashboardPage.jsx` - Glavna analitička stranica
- `HourlyChart.jsx` - Grafik po satima
- `ComparisonGrid.jsx` - Poređenje lokacija
- `KPICard.jsx` - KPI kartice

---

### 2. **magacin/** - Magacin & Zaliha
**Opis:** Modul za upravljanje zalihama, trebovanje artikala, prenose i praćenje nedostajućih artikala.

**Funkcionalnosti:**
- Kreiranje trebovanja (artikli + korpa)
- Lista trebovanja sa statusima (NOVO, NA PUTU, ZAVRŠENO)
- Prenosi iz Pantheona
- Nedostajući artikli
- Prikaz stanja (CM i Radnja)
- Filteri po kategorijama

**Ključne komponente:**
- `TrebovanjePage.jsx` - Kreiranje trebovanja
- `TrebovanjaListPage.jsx` - Lista trebovanja
- `ArtikalRow.jsx` - Red artikla sa stanjem
- `StockCard.jsx` - Mini kartica za stanje
- `CartModal.jsx` - Korpa modal

**API:** `https://magacin.collina.co.rs/api/trebovanje`

---

### 3. **orders/** - Live Porudžbine
**Opis:** Modul za praćenje live porudžbina u realnom vremenu.

**Funkcionalnosti:**
- Live lista porudžbina
- Filteri po statusu
- Detalji porudžbine
- Tabela porudžbina

**Ključne komponente:**
- `LiveOrdersPage.jsx` - Glavna stranica
- `OrderCard.jsx` - Kartica porudžbine
- `OrdersTable.jsx` - Tabela porudžbina
- `StatusTabs.jsx` - Tabovi po statusu

---

### 4. **pazar/** - Pazar (Cash Management)
**Opis:** Modul za upravljanje gotovinom, smenama, prikupljanjem i depozitima u banku.

**Funkcionalnosti:**
- PIN login za zaposlene
- Start/End shift flow
- Preuzimanje smene
- Prijem keša
- Prebrojavanje i verifikacija
- Sef (safe) management
- Bank depoziti
- Dashboard za različite uloge (Sef, Vozac, Finansije)

**Ključne komponente:**
- `DashboardPage.jsx` - Glavni dashboard
- `PinLoginPage.jsx` - PIN login
- `EndShiftFlow.jsx` - Multi-step flow za zatvaranje smene
- `TakeoverShiftModal.jsx` - Preuzimanje smene

**Stores:**
- `pazarAuthStore.js` - Auth state (Zustand)
- `shiftFlowStore.js` - Shift flow state

---

### 5. **staff/** - Staff App
**Opis:** Mobilna aplikacija za zaposlene - pickup funkcionalnosti.

**Funkcionalnosti:**
- Staff login
- Dashboard sa modulima
- Pickup page (prikupljanje robe)
- Timeline prikaz
- Photo pickup
- Stats kartice

**Ključne komponente:**
- `StaffHomePage.jsx` - Glavna stranica
- `PickupPage.jsx` - Pickup funkcionalnosti
- `LocationCard.jsx` - Kartica lokacije
- `Timeline.jsx` - Timeline prikaz

---

### 6. **staff-app/** - Staff App (Legacy)
**Opis:** Placeholder/legacy modul za staff aplikaciju.

---

## 📂 Ostali Direktorijumi

### **core/** - Core funkcionalnosti
- **auth/** - Autentifikacija i autorizacija sistema
  - `AuthContext.jsx` - React Context za globalni auth state
  - `useAuth.js` - Custom hook za pristup auth podacima
  - `ProtectedRoute.jsx` - Route wrapper sa permisijama
  - `PermissionGuard.jsx` - Guard za proveru permisija

- **layouts/** - Layout komponente
  - `AdminLayout.jsx` - Admin panel layout sa sidebar-om
  - `Sidebar.jsx` - Sidebar navigacija sa modulima
  - `BottomNav.jsx` - Bottom navigacija za mobile

### **lib/** - Biblioteke
- `supabase.js` - Supabase client konfiguracija i inicijalizacija

### **pages/** - Admin stranice (legacy struktura)
- **admin/pazar/** - Admin Pazar stranice
  - `PazarOverviewPage.jsx` - Glavni pregled
  - `AdminShiftsPage.jsx` - Sve smene
  - `AdminPickupsPage.jsx` - Prikupljanje
  - `FinanceReceivePage.jsx` - Prijem keša
  - `FinanceSafePage.jsx` - Sef
  - `FinanceBankPage.jsx` - Banka
  - `BankSettingsPage.jsx` - Podešavanja banke

---

## 🔑 Ključne Konvencije

### Struktura Modula
Svaki modul obično ima:
```
module-name/
├── components/     # UI komponente
├── pages/         # Stranice
├── services/      # API servisi
├── hooks/         # Custom React hooks
├── stores/        # State management (Zustand)
├── utils/         # Utility funkcije
├── config/        # Konfiguracija
└── module.config.js
```

### Servisi
- Servisi su u `modules/{module}/services/`
- Nema globalnog `src/services/` direktorijuma
- Svaki modul ima svoj service fajl

### Konteksti
- Konteksti su u `core/auth/`
- `AuthContext.jsx` je glavni auth context
- Nema globalnog `src/contexts/` direktorijuma

### State Management
- **Zustand** se koristi za kompleksniji state (npr. `pazar/stores/`)
- **React Context** za globalni auth state
- **useState** za lokalni component state

---

## 📊 Statistika

- **Moduli:** 6 (analytics, magacin, orders, pazar, staff, staff-app)
- **Admin stranice:** 7 (u `pages/admin/pazar/`)
- **Core komponente:** Auth system + Layouts
- **Servisi:** Po modulu (nema globalnih)
- **Konteksti:** 1 (AuthContext u `core/auth/`)

---

## 🎯 Preporuke za Razvoj

1. **Nove funkcionalnosti** - dodaj u odgovarajući modul
2. **Globalne komponente** - u `src/components/` ili `core/`
3. **API servisi** - u `modules/{module}/services/`
4. **Custom hooks** - u `modules/{module}/hooks/`
5. **Admin stranice** - razmotri da li treba u `pages/admin/` ili u modulu
