/*
 * ============================================================================
 * UI/UX PATTERNS I REUSABLE KOMPONENTE - KOMPLETNA DOKUMENTACIJA
 * ============================================================================
 * 
 * Ovaj dokument opisuje sve UI/UX pattern-e i reusable komponente u Collina
 * platformi, uključujući design system, komponente, loading states, empty
 * states, toast/notifications, responsive design i Serbian locale.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. DESIGN SYSTEM - Boje, fontovi, spacing (iz Tailwind config)
 * ============================================================================
 */

/*
 * 1.1. COLOR SYSTEM
 * ------------------
 * 
 * Background Colors:
 *   - bg-darkest: #08070b (najtamnija pozadina)
 *   - bg-dark: #0f0e14 (tamna pozadina)
 *   - bg-card: #16141f (kartica pozadina)
 *   - bg-card-hover: #1e1b2a (kartica hover)
 *   - bg-elevated: #1f1d2b (elevated pozadina)
 * 
 * Border Colors:
 *   - border: rgba(255, 255, 255, 0.06) (standardni border)
 *   - border-light: rgba(255, 255, 255, 0.12) (svetliji border)
 * 
 * Text Colors:
 *   - text-primary: #ffffff (glavni tekst)
 *   - text-secondary: #a09bb0 (sekundarni tekst)
 *   - text-muted: #6b6780 (muted tekst)
 * 
 * Accent Colors:
 *   - accent: #8B5CF6 (purple - glavna akcent boja)
 *   - accent-glow: rgba(139, 92, 246, 0.3) (glow efekat)
 *   - accent-soft: rgba(139, 92, 246, 0.15) (soft pozadina)
 * 
 * Status Colors:
 *   - success: #22c55e (zeleno)
 *   - success-soft: rgba(34, 197, 94, 0.12)
 *   - warning: #f59e0b (narandžasto)
 *   - warning-soft: rgba(245, 158, 11, 0.12)
 *   - error: #ef4444 (crveno)
 *   - error-soft: rgba(239, 68, 68, 0.12)
 *   - blue: #3b82f6 (plavo)
 *   - blue-soft: rgba(59, 130, 246, 0.12)
 * 
 * NAPOMENA: Color system koristi dark theme sa purple accent bojom.
 */

/*
 * 1.2. TYPOGRAPHY
 * ----------------
 * 
 * Font Families:
 *   - sans: 'DM Sans', sans-serif (default body font)
 *   - heading: 'Instrument Sans', sans-serif (headings)
 *   - mono: 'DM Mono', monospace (code/monospace)
 * 
 * Font Weights:
 *   - 400: Regular
 *   - 500: Medium
 *   - 600: Semibold
 *   - 700: Bold
 * 
 * Font Sizes (Tailwind defaults):
 *   - text-xs: 12px
 *   - text-sm: 14px
 *   - text-base: 16px
 *   - text-lg: 18px
 *   - text-xl: 20px
 *   - text-2xl: 24px
 *   - text-3xl: 30px
 * 
 * Custom Font Sizes (inline styles):
 *   - 32px: KPI card values (fontSize: '32px', fontWeight: 700)
 *   - 22px: Sidebar logo (fontSize: '22px')
 *   - 28px: Page headings (fontSize: '28px')
 * 
 * NAPOMENA: Typography koristi Google Fonts (DM Sans, Instrument Sans, DM Mono).
 */

/*
 * 1.3. SPACING SYSTEM
 * --------------------
 * 
 * Tailwind Spacing Scale:
 *   - 1: 4px
 *   - 2: 8px
 *   - 3: 12px
 *   - 4: 16px
 *   - 5: 20px
 *   - 6: 24px
 *   - 8: 32px
 *   - 10: 40px
 *   - 12: 48px
 * 
 * Common Spacing Patterns:
 *   - p-4: 16px padding (standardni padding)
 *   - p-6: 24px padding (veći padding)
 *   - p-8: 32px padding (veliki padding)
 *   - gap-2: 8px gap (mali gap)
 *   - gap-4: 16px gap (standardni gap)
 *   - gap-6: 24px gap (veći gap)
 *   - mb-4: 16px margin bottom
 *   - mb-6: 24px margin bottom
 *   - mb-8: 32px margin bottom
 * 
 * NAPOMENA: Spacing koristi Tailwind default scale (4px base unit).
 */

/*
 * 1.4. BORDER RADIUS
 * --------------------
 * 
 * Border Radius Values:
 *   - rounded: 4px
 *   - rounded-lg: 8px
 *   - rounded-xl: 12px
 *   - rounded-2xl: 16px
 *   - rounded-[10px]: 10px (custom)
 *   - rounded-full: 50% (circle)
 * 
 * Common Patterns:
 *   - Cards: rounded-2xl (16px)
 *   - Buttons: rounded-xl (12px)
 *   - Inputs: rounded-xl (12px)
 *   - Badges: rounded-lg (8px)
 *   - Icons: rounded-[10px] (10px)
 * 
 * NAPOMENA: Border radius koristi Tailwind default scale sa custom vrednostima.
 */

/*
 * 1.5. SHADOWS & EFFECTS
 * ------------------------
 * 
 * Glassmorphism:
 *   - bg-[rgba(255,255,255,0.03)]: Glassmorphism pozadina
 *   - backdrop-blur-sm: Blur efekat
 *   - border border-[rgba(255,255,255,0.06)]: Glassmorphism border
 * 
 * Gradients:
 *   - bg-gradient-to-br from-[#8B5CF6] to-[#6366F1]: Purple gradient
 *   - bg-gradient-to-r from-orange-500 to-red-500: Orange-red gradient
 * 
 * Glow Effects:
 *   - shadow-lg shadow-orange-500/25: Glow shadow
 *   - accent-glow: rgba(139, 92, 246, 0.3)
 * 
 * NAPOMENA: Glassmorphism i gradient efekti se koriste za modern look.
 */

/* ============================================================================
 * 2. REUSABLE COMPONENTS - Modal, Button, Card, Input - kako se koriste
 * ============================================================================
 */

/*
 * 2.1. MODAL COMPONENT PATTERN
 * ------------------------------
 * 
 * Standardni Modal Pattern:
 *   <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4" onClick={onClose}>
 *     <div 
 *       className="bg-[#1a1a1a] border border-[rgba(255,255,255,0.1)] rounded-2xl w-full max-w-3xl max-h-[90vh] overflow-y-auto"
 *       onClick={(e) => e.stopPropagation()}
 *     >
 *       {/* Header */}
 *       <div className="flex justify-between items-center p-6 border-b border-[rgba(255,255,255,0.1)]">
 *         <h2 className="text-xl font-bold">Title</h2>
 *         <button onClick={onClose}>
 *           <X size={20} />
 *         </button>
 *       </div>
 *       
 *       {/* Content */}
 *       <div className="p-6 space-y-6">
 *         {/* Modal content */}
 *       </div>
 *     </div>
 *   </div>
 * 
 * Modal Features:
 *   - Fixed overlay (bg-black/70)
 *   - Centered content (flex items-center justify-center)
 *   - Max width constraint (max-w-3xl)
 *   - Max height constraint (max-h-[90vh])
 *   - Scrollable content (overflow-y-auto)
 *   - Close on overlay click (onClick={onClose})
 *   - Stop propagation on content click (e.stopPropagation())
 * 
 * Examples:
 *   - OrderDetailModal.jsx
 *   - TrebovanjeDetailModal.jsx
 *   - ReceiveModal.jsx
 *   - CountModal.jsx
 * 
 * NAPOMENA: Modal pattern je konzistentan kroz aplikaciju.
 */

/*
 * 2.2. BUTTON COMPONENT PATTERNS
 * --------------------------------
 * 
 * Primary Button:
 *   <button className="w-full py-3.5 bg-accent text-white rounded-xl font-semibold hover:opacity-90 transition-all disabled:opacity-50 disabled:cursor-not-allowed">
 *     Button Text
 *   </button>
 * 
 * Secondary Button:
 *   <button className="px-4 py-2 bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.1)] rounded-lg hover:bg-[rgba(255,255,255,0.1)]">
 *     Button Text
 *   </button>
 * 
 * Gradient Button:
 *   <button className="px-4 py-2 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 rounded-lg text-white font-medium">
 *     Button Text
 *   </button>
 * 
 * Icon Button:
 *   <button className="p-2 bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.1)] rounded-lg hover:bg-[rgba(255,255,255,0.1)]">
 *     <Icon size={16} />
 *   </button>
 * 
 * Button States:
 *   - Default: Normal styling
 *   - Hover: hover:opacity-90 ili hover:bg-[...]
 *   - Disabled: disabled:opacity-50 disabled:cursor-not-allowed
 *   - Loading: Spinner icon + disabled state
 * 
 * NAPOMENA: Button patterns variraju po kontekstu ali su konzistentni.
 */

/*
 * 2.3. CARD COMPONENT PATTERNS
 * ------------------------------
 * 
 * Standard Card:
 *   <div className="bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.06)] rounded-2xl p-6">
 *     {/* Card content */}
 *   </div>
 * 
 * KPI Card (KPICard.jsx):
 *   <div className="rounded-2xl relative overflow-hidden bg-[rgba(255,255,255,0.03)] border border-[rgba(255,255,255,0.06)]">
 *     {/* Glassmorphism top border */}
 *     <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r(transparent, rgba(255,255,255,0.1), transparent)" />
 *     {/* Icon + Trend */}
 *     {/* Value */}
 *     {/* Label */}
 *   </div>
 * 
 * Order Card (OrderCard.jsx):
 *   <div className="bg-[rgba(255,255,255,0.03)] border-l-4 rounded-xl p-4 cursor-pointer hover:bg-[rgba(255,255,255,0.05)]">
 *     {/* Location tag */}
 *     {/* Header */}
 *     {/* Items */}
 *     {/* Footer */}
 *     {/* Status badge */}
 *   </div>
 * 
 * Card Features:
 *   - Glassmorphism background
 *   - Border (standard ili left border za status)
 *   - Rounded corners (rounded-2xl)
 *   - Padding (p-4, p-6)
 *   - Hover effects (hover:bg-[...])
 * 
 * NAPOMENA: Card patterns su konzistentni sa glassmorphism stilom.
 */

/*
 * 2.4. INPUT COMPONENT PATTERNS
 * -------------------------------
 * 
 * Standard Input:
 *   <input
 *     type="text"
 *     className="w-full px-4 py-3 bg-bg-dark border border-border rounded-xl text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-accent focus:border-transparent transition-all"
 *     placeholder="Placeholder text"
 *   />
 * 
 * Input Features:
 *   - Full width (w-full)
 *   - Padding (px-4 py-3)
 *   - Dark background (bg-bg-dark)
 *   - Border (border border-border)
 *   - Rounded (rounded-xl)
 *   - Text color (text-text-primary)
 *   - Placeholder color (placeholder:text-text-muted)
 *   - Focus ring (focus:ring-2 focus:ring-accent)
 *   - Transition (transition-all)
 * 
 * Select Input:
 *   <select className="w-full p-2 bg-slate-900/50 border border-slate-700 rounded-lg text-white focus:border-orange-500 focus:ring-1 focus:ring-orange-500/50">
 *     <option>Option 1</option>
 *   </select>
 * 
 * Date Input:
 *   <input
 *     type="date"
 *     className="px-3 py-2 bg-[rgba(255,255,255,0.05)] border border-[rgba(255,255,255,0.1)] rounded-lg text-sm"
 *   />
 * 
 * NAPOMENA: Input patterns su konzistentni sa dark theme stilom.
 */

/*
 * 2.5. BADGE COMPONENT PATTERNS
 * -------------------------------
 * 
 * Status Badge:
 *   <span className="px-2 py-1 rounded text-xs font-semibold" style={{ background: bg, color: text }}>
 *     Label
 *   </span>
 * 
 * Count Badge:
 *   <span className="px-1.5 py-0.5 rounded text-[10px] font-semibold bg-[#8B5CF6]">
 *     {count}
 *   </span>
 * 
 * Badge Colors:
 *   - Success: bg-[rgba(34,197,94,0.15)] text-[#22C55E]
 *   - Warning: bg-[rgba(245,158,11,0.15)] text-[#FBBF24]
 *   - Error: bg-[rgba(239,68,68,0.15)] text-[#EF4444]
 *   - Info: bg-[rgba(59,130,246,0.15)] text-[#60A5FA]
 * 
 * NAPOMENA: Badge patterns koriste soft background sa bright text color.
 */

/* ============================================================================
 * 3. LOADING STATES - Kako se prikazuje loading
 * ============================================================================
 */

/*
 * 3.1. LOADING SPINNER PATTERNS
 * -------------------------------
 * 
 * Full Page Loading:
 *   <div className="min-h-screen bg-bg-darkest flex items-center justify-center">
 *     <div className="text-center">
 *       <div className="w-12 h-12 border-4 border-accent border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
 *       <p className="text-text-secondary">Loading...</p>
 *     </div>
 *   </div>
 * 
 * Inline Loading:
 *   <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
 * 
 * Button Loading:
 *   {loading ? (
 *     <span className="flex items-center justify-center gap-2">
 *       <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
 *       Loading...
 *     </span>
 *   ) : (
 *     'Button Text'
 *   )}
 * 
 * Spinner Styles:
 *   - Border spinner: border-4 border-accent border-t-transparent
 *   - Animate: animate-spin
 *   - Size: w-12 h-12 (large), w-5 h-5 (small)
 * 
 * NAPOMENA: Loading spinner koristi Tailwind animate-spin utility.
 */

/*
 * 3.2. LOADING STATE PATTERNS
 * -----------------------------
 * 
 * Pattern 1: Loading Flag
 *   const [loading, setLoading] = useState(false);
 *   if (loading) return <LoadingSpinner />;
 * 
 * Pattern 2: Conditional Rendering
 *   {loading ? (
 *     <div className="text-center text-gray-400 py-12">Učitavanje...</div>
 *   ) : (
 *     <Content />
 *   )}
 * 
 * Pattern 3: Disabled State
 *   <button disabled={loading}>
 *     {loading ? 'Učitavanje...' : 'Submit'}
 *   </button>
 * 
 * Pattern 4: Skeleton Loading (N/A)
 *   - Skeleton loading nije implementiran
 *   - Mogao bi se koristiti za bolji UX
 * 
 * NAPOMENA: Loading states se prikazuju kroz spinner ili text message.
 */

/*
 * 3.3. LOADING EXAMPLES
 * ----------------------
 * 
 * Example 1: LoginPage.jsx
 *   if (authLoading) {
 *     return <LoadingSpinner />;
 *   }
 * 
 * Example 2: TrebovanjePage.jsx
 *   {artikliLoading ? (
 *     <div className="text-center text-gray-400 py-12">Učitavanje...</div>
 *   ) : (
 *     <ArtikliList />
 *   )}
 * 
 * Example 3: LiveOrdersPage.jsx
 *   {loading && (
 *     <div className="text-center py-12 text-[rgba(255,255,255,0.5)]">
 *       Učitavanje porudžbina...
 *     </div>
 *   )}
 * 
 * NAPOMENA: Loading examples variraju po kontekstu.
 */

/* ============================================================================
 * 4. EMPTY STATES - Šta se prikazuje kad nema podataka
 * ============================================================================
 */

/*
 * 4.1. EMPTY STATE PATTERNS
 * ---------------------------
 * 
 * Standard Empty State:
 *   <div className="text-center text-gray-400 py-12">
 *     Nema podataka
 *   </div>
 * 
 * Empty State sa Ikonom:
 *   <div className="text-center py-12">
 *     <Icon size={48} className="text-gray-400 mx-auto mb-4" />
 *     <p className="text-gray-400">Nema podataka</p>
 *   </div>
 * 
 * Empty State sa Akcijom:
 *   <div className="text-center py-12">
 *     <p className="text-gray-400 mb-4">Nema podataka</p>
 *     <button onClick={handleAction}>Dodaj</button>
 *   </div>
 * 
 * NAPOMENA: Empty states su jednostavni - samo text message.
 */

/*
 * 4.2. EMPTY STATE EXAMPLES
 * ---------------------------
 * 
 * Example 1: TrebovanjePage.jsx
 *   {filteredArtikli.length === 0 ? (
 *     <div className="text-center text-gray-400 py-12">Nema artikala</div>
 *   ) : (
 *     <ArtikliList />
 *   )}
 * 
 * Example 2: LiveOrdersPage.jsx
 *   {!loading && filteredOrders.length === 0 && (
 *     <div className="text-center py-12 text-[rgba(255,255,255,0.4)]">
 *       Nema porudžbina za izabrani dan i filtere
 *     </div>
 *   )}
 * 
 * Example 3: OrdersTable.jsx
 *   {orders.length === 0 && (
 *     <div className="text-center py-12 text-[rgba(255,255,255,0.4)]">
 *       Nema porudžbina
 *     </div>
 *   )}
 * 
 * Example 4: NedostajePage.jsx
 *   {nedostaje.length === 0 && (
 *     <div className="text-center text-gray-400 py-12">
 *       Nema nedostajućih artikala
 *     </div>
 *   )}
 * 
 * NAPOMENA: Empty states su konzistentni - text-center sa gray-400 text.
 */

/*
 * 4.3. EMPTY STATE VARIATIONS
 * ----------------------------
 * 
 * Variation 1: Simple Text
 *   "Nema podataka"
 * 
 * Variation 2: Contextual Message
 *   "Nema porudžbina za izabrani dan i filtere"
 *   "Nema nedostajućih artikala"
 *   "Nema trebovanja"
 * 
 * Variation 3: With Icon (Rare)
 *   - Icons se retko koriste u empty states
 *   - Većina je samo text
 * 
 * NAPOMENA: Empty states su minimalistički - fokus na jasnu poruku.
 */

/* ============================================================================
 * 5. TOAST/NOTIFICATIONS - Kako se prikazuju poruke korisniku
 * ============================================================================
 */

/*
 * 5.1. TOAST SYSTEM STATUS
 * --------------------------
 * 
 * Trenutno stanje:
 *   - NEMA toast notification sistema
 *   - Koristi se alert() za kritične greške
 *   - Koristi se inline error/success messages
 * 
 * NAPOMENA: Toast sistem nije implementiran - koristi se alert() i inline messages.
 */

/*
 * 5.2. ALERT PATTERN
 * -------------------
 * 
 * Usage:
 *   alert('Greška pri prijemu');
 *   alert('Trebovanje kreirano!');
 *   alert('Unesi validan iznos');
 * 
 * Pros:
 *   - Jednostavno
 *   - Ugrađeno u browser
 *   - Blokira UI dok se ne zatvori
 * 
 * Cons:
 *   - Ne prilagođava se dizajnu
 *   - Blokira UI
 *   - Nema auto-dismiss
 *   - Nema stacking
 * 
 * NAPOMENA: alert() se koristi za kritične greške i success messages.
 */

/*
 * 5.3. INLINE MESSAGES
 * ---------------------
 * 
 * Error Message:
 *   {error && (
 *     <div className="p-4 bg-red-500/20 border border-red-500/50 rounded-lg text-red-400">
 *       {error}
 *     </div>
 *   )}
 * 
 * Success Message:
 *   {success && (
 *     <div className="p-4 bg-green-500/20 border border-green-500/50 rounded-lg text-green-400">
 *       {success}
 *     </div>
 *   )}
 * 
 * Warning Message:
 *   <div className="p-4 bg-yellow-500/20 border border-yellow-500/50 rounded-xl">
 *     <span className="text-yellow-400">Warning message</span>
 *   </div>
 * 
 * Message Features:
 *   - Colored background (bg-{color}-500/20)
 *   - Colored border (border-{color}-500/50)
 *   - Colored text (text-{color}-400)
 *   - Padding (p-4)
 *   - Rounded (rounded-lg ili rounded-xl)
 * 
 * NAPOMENA: Inline messages se koriste za form errors i success feedback.
 */

/*
 * 5.4. POTENTIAL TOAST IMPLEMENTATION
 * ------------------------------------
 * 
 * Toast Component Structure:
 *   <div className="fixed top-4 right-4 z-50 space-y-2">
 *     {toasts.map(toast => (
 *       <div className="bg-[#1a1a1a] border border-[rgba(255,255,255,0.1)] rounded-xl p-4 shadow-lg">
 *         <div className="flex items-center gap-3">
 *           <Icon />
 *           <p>{toast.message}</p>
 *           <button onClick={() => dismiss(toast.id)}>X</button>
 *         </div>
 *       </div>
 *     ))}
 *   </div>
 * 
 * Toast Types:
 *   - success: Green background
 *   - error: Red background
 *   - warning: Yellow background
 *   - info: Blue background
 * 
 * Toast Features:
 *   - Auto-dismiss (3-5 seconds)
 *   - Manual dismiss (X button)
 *   - Stacking (multiple toasts)
 *   - Animation (slide in/out)
 * 
 * NAPOMENA: Toast sistem bi poboljšao UX ali zahteva implementaciju.
 */

/* ============================================================================
 * 6. RESPONSIVE - Mobile vs Desktop breakpoints
 * ============================================================================
 */

/*
 * 6.1. TAILWIND BREAKPOINTS
 * --------------------------
 * 
 * Default Breakpoints:
 *   - sm: 640px (small devices)
 *   - md: 768px (tablets)
 *   - lg: 1024px (desktops)
 *   - xl: 1280px (large desktops)
 *   - 2xl: 1536px (extra large desktops)
 * 
 * NAPOMENA: Tailwind koristi mobile-first approach (default styles su za mobile).
 */

/*
 * 6.2. RESPONSIVE PATTERNS
 * --------------------------
 * 
 * Pattern 1: Hide on Mobile
 *   <div className="hidden md:block">
 *     Desktop only content
 *   </div>
 * 
 * Pattern 2: Show on Mobile Only
 *   <div className="md:hidden">
 *     Mobile only content
 *   </div>
 * 
 * Pattern 3: Responsive Grid
 *   <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
 *     {/* Cards */}
 *   </div>
 * 
 * Pattern 4: Responsive Text
 *   <span className="text-sm sm:text-base lg:text-lg">
 *     Responsive text
 *   </span>
 * 
 * Pattern 5: Responsive Padding
 *   <div className="p-4 md:p-6 lg:p-8">
 *     Responsive padding
 *   </div>
 * 
 * NAPOMENA: Responsive patterns koriste Tailwind breakpoint prefixes.
 */

/*
 * 6.3. RESPONSIVE EXAMPLES
 * -------------------------
 * 
 * Example 1: Sidebar (Sidebar.jsx)
 *   - Mobile: Overlay (fixed, z-50, md:hidden)
 *   - Desktop: Fixed sidebar (md:translate-x-0)
 *   - Toggle: Hamburger menu (md:hidden)
 * 
 * Example 2: Orders Grid (LiveOrdersPage.jsx)
 *   <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
 *     {filteredOrders.map(order => <OrderCard />)}
 *   </div>
 * 
 * Example 3: Header Icons (AdminLayout.jsx)
 *   - Mobile: Hidden
 *   - Desktop: Visible (md:block)
 * 
 * Example 4: Bottom Navigation (BottomNav.jsx)
 *   - Mobile: Fixed bottom (md:hidden)
 *   - Desktop: Hidden
 * 
 * Example 5: Staff App (StaffLayout.jsx)
 *   - Mobile-first: max-w-[430px] mx-auto
 *   - Centered layout
 * 
 * NAPOMENA: Responsive design je mobile-first sa desktop enhancements.
 */

/*
 * 6.4. MOBILE-FIRST DESIGN
 * -------------------------
 * 
 * Staff App:
 *   - Mobile-first design
 *   - Max width: 430px
 *   - Centered layout
 *   - Bottom navigation
 *   - Touch-friendly buttons
 * 
 * Admin Shell:
 *   - Desktop-first design
 *   - Full width
 *   - Sidebar navigation
 *   - Top header
 *   - Responsive grid layouts
 * 
 * NAPOMENA: Staff App je mobile-first, Admin Shell je desktop-first.
 */

/* ============================================================================
 * 7. SERBIAN LOCALE - Formatiranje datuma, valute (RSD), prevodi
 * ============================================================================
 */

/*
 * 7.1. DATE FORMATTING
 * ---------------------
 * 
 * Locale: 'sr-RS' (Serbian - Serbia)
 * 
 * Date Formatting:
 *   new Date(date).toLocaleDateString('sr-RS')
 *   // Output: "17.1.2026." (DD.MM.YYYY.)
 * 
 * Date with Options:
 *   new Date(date).toLocaleDateString('sr-RS', {
 *     day: 'numeric',
 *     month: 'numeric',
 *     year: 'numeric'
 *   })
 *   // Output: "17.1.2026."
 * 
 * Time Formatting:
 *   new Date(date).toLocaleTimeString('sr-RS', {
 *     hour: '2-digit',
 *     minute: '2-digit'
 *   })
 *   // Output: "14:30"
 * 
 * DateTime Formatting:
 *   new Date(date).toLocaleString('sr-RS')
 *   // Output: "17.1.2026. 14:30:00"
 * 
 * NAPOMENA: Date formatting koristi sr-RS locale za srpski format.
 */

/*
 * 7.2. CURRENCY FORMATTING
 * -------------------------
 * 
 * Locale: 'sr-RS' (Serbian - Serbia)
 * Currency: RSD (Serbian Dinar)
 * 
 * Format Number:
 *   formatNumber(num)
 *   // Uses: num.toLocaleString('sr-RS', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
 *   // Output: "1.234" (dot for thousands separator)
 * 
 * Format Currency:
 *   formatCurrency(amount)
 *   // Output: "1.234 RSD"
 * 
 * Format Currency with Decimals:
 *   formatCurrencyWithDecimals(amount)
 *   // Uses: amount.toLocaleString('sr-RS', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
 *   // Output: "1.234,56 RSD" (comma for decimals)
 * 
 * Format Currency Compact:
 *   formatCurrencyCompact(amount)
 *   // Output: "1.234 RSD" (no decimals for large amounts)
 * 
 * Serbian Format Rules:
 *   - Thousands separator: dot (.)
 *   - Decimal separator: comma (,)
 *   - Currency code: RSD
 *   - Currency position: after amount
 * 
 * NAPOMENA: Currency formatting koristi sr-RS locale sa RSD currency code.
 */

/*
 * 7.3. CURRENCY FORMATTING EXAMPLES
 * -----------------------------------
 * 
 * Example 1: formatCurrency.js
 *   export function formatCurrency(amount) {
 *     if (typeof amount !== 'number') amount = parseFloat(amount) || 0;
 *     return `${formatNumber(amount)} RSD`;
 *   }
 * 
 * Example 2: Usage in Components
 *   import { formatCurrency } from '../utils/formatCurrency';
 *   <span>{formatCurrency(total)}</span>
 *   // Output: "1.234 RSD"
 * 
 * Example 3: Inline Formatting
 *   {amount.toLocaleString('sr-RS')} RSD
 *   // Output: "1.234 RSD"
 * 
 * Example 4: With Decimals
 *   {amount.toLocaleString('sr-RS', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} RSD
 *   // Output: "1.234,56 RSD"
 * 
 * NAPOMENA: Currency formatting je konzistentan kroz aplikaciju.
 */

/*
 * 7.4. SERBIAN TRANSLATIONS
 * --------------------------
 * 
 * UI Labels (Hardcoded):
 *   - "Pregled" (Overview)
 *   - "Smart Analitika" (Smart Analytics)
 *   - "Live Porudžbine" (Live Orders)
 *   - "Operacije" (Operations)
 *   - "Magacin" (Warehouse)
 *   - "Pazar" (Cash Management)
 *   - "Tim" (Team)
 *   - "Poslovanje" (Business)
 *   - "Podešavanja" (Settings)
 * 
 * Status Labels:
 *   - "Novo" (New)
 *   - "Priprema" (Production)
 *   - "Spremno" (Ready)
 *   - "Završeno" (Paid/Completed)
 *   - "Otkazano" (Canceled)
 * 
 * Common Phrases:
 *   - "Učitavanje..." (Loading...)
 *   - "Nema podataka" (No data)
 *   - "Greška pri..." (Error while...)
 *   - "Potvrdi" (Confirm)
 *   - "Otkaži" (Cancel)
 *   - "Sačuvaj" (Save)
 *   - "Obriši" (Delete)
 * 
 * NAPOMENA: Serbian translations su hardcoded u komponentama - nema i18n sistema.
 */

/*
 * 7.5. LOCALE USAGE EXAMPLES
 * ----------------------------
 * 
 * Example 1: Date Formatting
 *   new Date(order.created_at).toLocaleDateString('sr-RS')
 *   // Output: "17.1.2026."
 * 
 * Example 2: Time Formatting
 *   orderTime.toLocaleTimeString('sr-RS', { hour: '2-digit', minute: '2-digit' })
 *   // Output: "14:30"
 * 
 * Example 3: Number Formatting
 *   amount.toLocaleString('sr-RS')
 *   // Output: "1.234"
 * 
 * Example 4: Currency Formatting
 *   formatCurrency(amount)
 *   // Output: "1.234 RSD"
 * 
 * NAPOMENA: Locale usage je konzistentan - svi formati koriste 'sr-RS'.
 */

/* ============================================================================
 * 8. DODATNE NAPOMENE
 * ============================================================================
 */

/*
 * 8.1. GLASSMORPHISM DESIGN
 * ---------------------------
 * 
 * Glassmorphism Pattern:
 *   - Semi-transparent background: bg-[rgba(255,255,255,0.03)]
 *   - Border: border border-[rgba(255,255,255,0.06)]
 *   - Backdrop blur: backdrop-blur-sm (retko)
 *   - Gradient borders: linear-gradient za top border
 * 
 * Usage:
 *   - Cards
 *   - Modals
 *   - Sidebar
 *   - Header
 * 
 * NAPOMENA: Glassmorphism je glavni design pattern u aplikaciji.
 */

/*
 * 8.2. ICON SYSTEM
 * -----------------
 * 
 * Icon Library: Lucide React
 * 
 * Common Icons:
 *   - BarChart3: Analytics
 *   - ShoppingBag: Orders
 *   - Package: Warehouse
 *   - Wallet: Finance
 *   - Users: Team
 *   - Settings: Settings
 *   - X: Close
 *   - ChevronDown/Up: Expand/Collapse
 *   - RefreshCw: Refresh
 *   - Filter: Filters
 * 
 * Icon Sizes:
 *   - Small: size={16}
 *   - Medium: size={20}
 *   - Large: size={24}
 *   - Extra Large: size={48}
 * 
 * NAPOMENA: Lucide React je glavna icon library.
 */

/*
 * 8.3. ANIMATION PATTERNS
 * -------------------------
 * 
 * Transitions:
 *   - transition-all: Svi properties
 *   - transition-colors: Boje
 *   - transition-transform: Transform
 *   - duration-300: 300ms duration
 * 
 * Animations:
 *   - animate-spin: Spinner rotation
 *   - animate-pulse: Pulsing effect
 * 
 * Hover Effects:
 *   - hover:opacity-90: Opacity change
 *   - hover:bg-[...]: Background change
 *   - hover:text-white: Text color change
 * 
 * NAPOMENA: Animations su minimalne - fokus na performance.
 */

/*
 * 8.4. Z-INDEX LAYERING
 * ----------------------
 * 
 * Z-Index Values:
 *   - z-10: Dropdown menus
 *   - z-40: Overlays
 *   - z-50: Modals
 *   - z-[99]: Mobile sidebar overlay
 *   - z-[100]: Mobile sidebar
 * 
 * NAPOMENA: Z-index layering je konzistentan kroz aplikaciju.
 */

/*
 * 8.5. ACCESSIBILITY
 * -------------------
 * 
 * Current State:
 *   - NEMA eksplicitne accessibility features
 *   - Nema ARIA labels
 *   - Nema keyboard navigation
 *   - Nema screen reader support
 * 
 * Potential Improvements:
 *   - ARIA labels za ikone
 *   - Keyboard navigation
 *   - Focus management
 *   - Screen reader support
 * 
 * NAPOMENA: Accessibility nije eksplicitno implementirana.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
