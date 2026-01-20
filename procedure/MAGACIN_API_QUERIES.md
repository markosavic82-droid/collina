# MAGACIN Modul - Kompletan Spisak API Poziva

Dokumentacija svih eksternih API poziva u MAGACIN modulu. **NAPOMENA:** Magacin modul koristi samo eksterni API, nema Supabase upita.

**Base URL:** `https://magacin.collina.co.rs/api/trebovanje`

---

## 📁 src/modules/magacin/services/magacinService.js

### FUNKCIJA: getRadnje
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/radnje`  
**METODA:** GET  
**PARAMETRI:** nema  
**BODY:** nema  
**RETURN:** Array radnji (objekti sa `sifra`, `naziv`)

---

### FUNKCIJA: getArtikli
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/artikli`  
**METODA:** GET  
**PARAMETRI:** nema  
**BODY:** nema  
**RETURN:** Array artikala (objekti sa `acIdent`, `acName`, `acUM`, itd.)

---

### FUNKCIJA: getStanje
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/stanje`  
**METODA:** GET  
**PARAMETRI:** nema  
**BODY:** nema  
**RETURN:** Objekat sa strukturom:
```javascript
{
  "Centralni magacin": {
    "A2023": { "stock": 79, "reserved": 0 },
    "1159": { "stock": 100, "reserved": 5 },
    ...
  },
  "MP-P47": {
    "A2023": { "stock": 1, "reserved": 0 },
    ...
  },
  ...
}
```

---

### FUNKCIJA: getTrebovanja
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/lista`  
**METODA:** GET  
**PARAMETRI:** nema  
**BODY:** nema  
**RETURN:** Array trebovanja (objekti sa `acKey`, `id`, `status`, `radnja`, `datum`, `brojStavki`, itd.)

---

### FUNKCIJA: createTrebovanje
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/submit`  
**METODA:** POST  
**PARAMETRI:** nema  
**BODY:** 
```json
{
  "radnja": "radnjaSifra",
  "stavke": [
    {
      "sifra": "A2023",
      "naziv": "Alu folija 300 mm",
      "jm": "KOM",
      "kolicina": 10
    },
    ...
  ]
}
```
**RETURN:** 
```json
{
  "success": true,
  "trebovanjeKey": "TREB-2026-001",
  "id": "..."
}
```

---

### FUNKCIJA: getArtikliRadnja
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/artikli-radnja/{radnjaSifra}`  
**METODA:** GET  
**PARAMETRI:** `radnjaSifra` (URL parameter)  
**BODY:** nema  
**RETURN:** Array artikala sa stanjem:
```javascript
[
  {
    "acIdent": "A2023",
    "acName": "Alu folija 300 mm",
    "acUM": "KOM",
    "anStockCM": 79,        // Stanje u CM
    "anReservedCM": 0,      // Rezervisano u CM
    "anStockMP": 1,         // Stanje u radnji
    "anReservedMP": 0,      // Rezervisano u radnji
    "anMinStock": 36        // Minimum za tu radnju
  },
  ...
]
```

---

### FUNKCIJA: getArtikliOstalo
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/artikli-ostalo/{radnjaSifra}?search={searchTerm}`  
**METODA:** GET  
**PARAMETRI:** 
- `radnjaSifra` (URL parameter)
- `search` (query parameter)  
**BODY:** nema  
**RETURN:** Array artikala koje radnja NE koristi (rezultati pretrage)

---

### FUNKCIJA: getTrebovanjeDetalji
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/detalji/{key}`  
**METODA:** GET  
**PARAMETRI:** `key` (URL parameter - trebovanje key ili ID)  
**BODY:** nema  
**FALLBACK:** Ako prvi endpoint ne radi, pokušava `https://magacin.collina.co.rs/api/trebovanje/{key}`  
**RETURN:** Objekat sa detaljima trebovanja (uključujući `stavke` array)

---

### FUNKCIJA: posaljiRobu
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/posalji/{key}`  
**METODA:** POST  
**PARAMETRI:** `key` (URL parameter - trebovanje key)  
**BODY:** 
```json
{
  "userId": 5,
  "izmene": [
    {
      "sifra": "A2023",
      "kolicina": 8,
      "razlog": "NEMA_NA_STANJU"
    },
    ...
  ]
}
```
**RETURN:** Objekat sa rezultatom slanja

---

### FUNKCIJA: primiRobu
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/primi/{key}`  
**METODA:** POST  
**PARAMETRI:** `key` (URL parameter - trebovanje key)  
**BODY:** 
```json
{
  "userId": 5
}
```
**RETURN:** Objekat sa rezultatom prijema

---

### FUNKCIJA: getPrenosi
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/prenosi`  
**METODA:** GET  
**PARAMETRI:** nema  
**BODY:** nema  
**RETURN:** Array prenosa (objekti sa `acKey`, `id`, `datum`, `primalac`, `vrednost`, `brojStavki`, itd.)

---

### FUNKCIJA: getPrenosDetalji
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/prenos/{key}`  
**METODA:** GET  
**PARAMETRI:** `key` (URL parameter - prenos key ili ID)  
**BODY:** nema  
**RETURN:** Objekat sa detaljima prenosa (uključujući `stavke` array sa `sifra`, `naziv`, `kolicina`, `cena`)

---

### FUNKCIJA: getNedostaje
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/nedostaje`  
**METODA:** GET  
**PARAMETRI:** nema  
**BODY:** nema  
**RETURN:** Array nedostajućih artikala:
```javascript
[
  {
    "id": 123,
    "sifra": "A2023",
    "naziv": "Alu folija 300 mm",
    "radnja": "MP-P47",
    "trazeno": 10,
    "poslato": 5,
    "nedostaje": 5,
    "cmStanje": 50,
    "rezervisano": 0,
    "datum": "2026-01-17"
  },
  ...
]
```

---

### FUNKCIJA: resiNedostaje
**ENDPOINT:** `https://magacin.collina.co.rs/api/trebovanje/nedostaje/resi/{id}`  
**METODA:** POST  
**PARAMETRI:** `id` (URL parameter - ID nedostajućeg artikla)  
**BODY:** nema  
**RETURN:** Objekat sa rezultatom

---

## 📁 src/modules/magacin/hooks/useArtikli.js

**NAPOMENA:** Ne koristi direktne API pozive. Koristi funkcije iz `magacinService.js`:
- `getArtikliRadnja(radnjaSifra)` - poziva se u `loadArtikli()`
- `getStanje()` - poziva se u `loadArtikli()` (fallback)
- `getArtikliOstalo(radnjaSifra, searchTerm)` - poziva se u `searchArtikli()`

---

## 📁 src/modules/magacin/hooks/useCart.js

**NAPOMENA:** Ne koristi API pozive. Samo lokalni state management (useState).

---

## 📁 src/modules/magacin/pages/TrebovanjePage.jsx

**NAPOMENA:** Ne koristi direktne API pozive. Koristi funkcije iz `magacinService.js`:
- `getRadnje()` - poziva se u `useEffect` pri mount-u
- `createTrebovanje(selectedRadnja, cart)` - poziva se u `handleSubmit()`

---

## 📁 src/modules/magacin/pages/TrebovanjaListPage.jsx

**NAPOMENA:** Ne koristi direktne API pozive. Koristi funkcije iz `magacinService.js`:
- `getTrebovanja()` - poziva se u `loadTrebovanja()`
- `getTrebovanjeDetalji(key)` - poziva se u `handleViewDetails()`

---

## 📁 src/modules/magacin/pages/PrenosiPage.jsx

**NAPOMENA:** Ne koristi direktne API pozive. Koristi funkcije iz `magacinService.js`:
- `getPrenosi()` - poziva se u `loadPrenosi()`
- `getPrenosDetalji(key)` - poziva se u `handleViewDetails()`

---

## 📁 src/modules/magacin/pages/NedostajePage.jsx

**NAPOMENA:** Ne koristi direktne API pozive. Koristi funkcije iz `magacinService.js`:
- `getNedostaje()` - poziva se u `loadData()`
- `getRadnje()` - poziva se u `loadData()`
- `resiNedostaje(id)` - poziva se u `handleSend()` i `handleIgnore()`

---

## 📁 src/modules/magacin/components/TrebovanjeDetailModal.jsx

**NAPOMENA:** Ne koristi direktne API pozive. Koristi funkcije iz `magacinService.js`:
- `posaljiRobu(key, userId, izmene)` - poziva se u `handleSend()`
- `primiRobu(key, userId)` - poziva se u `handleReceive()`

---

## 📊 Statistika API Poziva

### Po Operacijama:
- **GET:** 8 poziva
- **POST:** 4 poziva
- **Supabase:** 0 upita

### Po Endpoint-ima:
1. `/radnje` - GET (lista radnji)
2. `/artikli` - GET (svi artikli)
3. `/stanje` - GET (stanje po skladištima)
4. `/lista` - GET (lista trebovanja)
5. `/submit` - POST (kreiraj trebovanje)
6. `/artikli-radnja/{radnjaSifra}` - GET (artikli za radnju)
7. `/artikli-ostalo/{radnjaSifra}?search={term}` - GET (pretraga artikala)
8. `/detalji/{key}` - GET (detalji trebovanja, sa fallback na `/{key}`)
9. `/posalji/{key}` - POST (pošalji robu)
10. `/primi/{key}` - POST (primi robu)
11. `/prenosi` - GET (lista prenosa)
12. `/prenos/{key}` - GET (detalji prenosa)
13. `/nedostaje` - GET (nedostajući artikli)
14. `/nedostaje/resi/{id}` - POST (reši nedostaje)

---

## 🔑 Ključne Napomene

### 1. Eksterni API
- **Base URL:** `https://magacin.collina.co.rs/api/trebovanje`
- **Nema Supabase upita** - sve funkcionalnosti koriste eksterni API
- **CORS:** Postoji fallback error handling za CORS greške

### 2. API Helper Function
- `apiCall(endpoint, options)` - centralna funkcija za sve API pozive
- Automatski dodaje `Content-Type: application/json` header
- Error handling sa CORS detekcijom
- Vraća `res.json()` automatski

### 3. Kreiranje Trebovanja
- **Endpoint:** `/submit`
- **Metoda:** POST
- **Body format:**
  ```json
  {
    "radnja": "radnjaSifra",
    "stavke": [
      {
        "sifra": "A2023",
        "naziv": "Alu folija 300 mm",
        "jm": "KOM",
        "kolicina": 10
      }
    ]
  }
  ```
- **Response:** `{ success: true, trebovanjeKey: "...", id: "..." }`

### 4. Artikli sa Stanjem
- `getArtikliRadnja()` vraća artikle sa poljima:
  - `anStockCM` - stanje u CM
  - `anReservedCM` - rezervisano u CM
  - `anStockMP` - stanje u radnji
  - `anReservedMP` - rezervisano u radnji
  - `anMinStock` - minimum za radnju
- Ova polja se mapiraju u `useArtikli` hook-u na normalizovane nazive

### 5. Stanje po Skladištima
- `getStanje()` vraća objekat sa strukturom:
  ```javascript
  {
    "Centralni magacin": {
      "A2023": { "stock": 79, "reserved": 0 },
      ...
    },
    "MP-P47": {
      "A2023": { "stock": 1, "reserved": 0 },
      ...
    }
  }
  ```

### 6. Status Trebovanja
- Status kodovi: `'N'` = NOVO, `'T'` = NA PUTU, `'Z'` = ZAVRŠENO
- Definisani u `magacinConfig.js`

### 7. Izmene pri Slanju
- `posaljiRobu()` prihvata `izmene` array sa formatom:
  ```javascript
  [
    {
      "sifra": "A2023",
      "kolicina": 8,  // Izmenjena količina
      "razlog": "NEMA_NA_STANJU"
    }
  ]
  ```
- Razlozi definisani u `magacinConfig.js` (`RAZLOZI_IZMENE`)

### 8. Fallback Endpoints
- `getTrebovanjeDetalji()` ima fallback: ako `/detalji/{key}` ne radi, pokušava `/{key}`

### 9. Error Handling
- Svi API pozivi koriste `apiCall()` helper koji:
  - Proverava `res.ok`
  - Čita error text iz response-a
  - Detektuje CORS greške
  - Baca Error sa porukom

---

## 📋 Kompletna Lista Funkcija

### magacinService.js
1. `getRadnje()` - GET `/radnje`
2. `getArtikli()` - GET `/artikli`
3. `getStanje()` - GET `/stanje`
4. `getTrebovanja()` - GET `/lista`
5. `createTrebovanje(radnja, stavke)` - POST `/submit`
6. `getArtikliRadnja(radnjaSifra)` - GET `/artikli-radnja/{radnjaSifra}`
7. `getArtikliOstalo(radnjaSifra, search)` - GET `/artikli-ostalo/{radnjaSifra}?search={search}`
8. `getTrebovanjeDetalji(key)` - GET `/detalji/{key}` (fallback: `/{key}`)
9. `posaljiRobu(key, userId, izmene)` - POST `/posalji/{key}`
10. `primiRobu(key, userId)` - POST `/primi/{key}`
11. `getPrenosi()` - GET `/prenosi`
12. `getPrenosDetalji(key)` - GET `/prenos/{key}`
13. `getNedostaje()` - GET `/nedostaje`
14. `resiNedostaje(id)` - POST `/nedostaje/resi/{id}`

---

## 🔄 Data Flow

### Kreiranje Trebovanja:
1. User izabere radnju u `TrebovanjePage`
2. `useArtikli` hook poziva `getArtikliRadnja(radnjaSifra)`
3. Artikli se prikazuju sa stanjem (CM i Radnja)
4. User dodaje artikle u korpu (lokalni state)
5. User klikne "Pošalji trebovanje"
6. `handleSubmit()` poziva `createTrebovanje(selectedRadnja, cart)`
7. API vraća `{ success: true, trebovanjeKey: "..." }`
8. Korpa se briše, prikazuje se success poruka

### Prikaz Trebovanja:
1. `TrebovanjaListPage` poziva `getTrebovanja()`
2. Prikazuje listu sa status filterima
3. User klikne "Detalji"
4. Poziva se `getTrebovanjeDetalji(key)`
5. Otvara se `TrebovanjeDetailModal` sa detaljima

### Slanje/Prijem Robe:
1. User otvori detalje trebovanja
2. Ako status = 'N', može da pošalje (`posaljiRobu()`)
3. Ako status = 'T', može da primi (`primiRobu()`)
4. Pri slanju, može da unese izmene (razlike u količini + razlog)

---

## ⚠️ Važne Napomene

1. **Nema Supabase upita** - Magacin modul koristi samo eksterni API
2. **CORS potencijalni problem** - API može imati CORS restrikcije
3. **Error handling** - Svi pozivi imaju try/catch i error logging
4. **Fallback mehanizmi** - `getTrebovanjeDetalji` ima fallback endpoint
5. **State management** - Korpa se čuva u lokalnom React state-u (useCart hook)
6. **Data normalization** - `useArtikli` hook normalizuje API response u konzistentan format

---

## 📝 API Response Formati

### Radnje:
```javascript
[
  { "sifra": "MP-P47", "naziv": "Banovo Brdo" },
  ...
]
```

### Artikli (getArtikliRadnja):
```javascript
[
  {
    "acIdent": "A2023",
    "acName": "Alu folija 300 mm",
    "acUM": "KOM",
    "anStockCM": 79,
    "anReservedCM": 0,
    "anStockMP": 1,
    "anReservedMP": 0,
    "anMinStock": 36
  },
  ...
]
```

### Trebovanja:
```javascript
[
  {
    "acKey": "TREB-2026-001",
    "id": "...",
    "status": "N",
    "radnja": "MP-P47",
    "datum": "2026-01-17",
    "brojStavki": 5
  },
  ...
]
```

### Trebovanje Detalji:
```javascript
{
  "acKey": "TREB-2026-001",
  "status": "N",
  "radnja": "MP-P47",
  "datum": "2026-01-17",
  "stavke": [
    {
      "sifra": "A2023",
      "naziv": "Alu folija 300 mm",
      "jm": "KOM",
      "kolicina": 10,
      "primenjenaKolicina": 10
    },
    ...
  ]
}
```
