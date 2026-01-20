/*
 * ============================================================================
 * DEPLOYMENT PROCES I ENVIRONMENT KONFIGURACIJA - KOMPLETNA DOKUMENTACIJA
 * ============================================================================
 * 
 * Ovaj dokument opisuje deployment proces i environment konfiguraciju za
 * Collina platformu, uključujući env variables, Supabase config, build process,
 * deploy commands, branch strategiju, database migrations i rollback proces.
 * 
 * Datum kreiranja: 2026-01-17
 * Verzija: 1.0
 */

/* ============================================================================
 * 1. ENV VARIABLES - Sve potrebne env varijable i šta rade
 * ============================================================================
 */

/*
 * 1.1. ENVIRONMENT VARIABLES OVERVIEW
 * -------------------------------------
 * 
 * Framework: Vite
 * Env File: .env (local), .env.local (gitignored)
 * Prefix: VITE_ (required za Vite)
 * Access: import.meta.env.VITE_*
 * 
 * NAPOMENA: Vite zahteva VITE_ prefix za environment variables koje se koriste u frontend-u.
 */

/*
 * 1.2. REQUIRED ENVIRONMENT VARIABLES
 * -------------------------------------
 * 
 * VITE_SUPABASE_URL
 *   - Type: String (URL)
 *   - Example: https://xxxxx.supabase.co
 *   - Description: Supabase project URL
 *   - Usage: src/lib/supabase.js, src/modules/pazar/stores/pazarAuthStore.js,
 *            src/modules/analytics/services/analyticsService.js
 *   - Required: Yes
 *   - Security: Public (safe to expose in frontend)
 * 
 * VITE_SUPABASE_ANON_KEY
 *   - Type: String (JWT token)
 *   - Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *   - Description: Supabase anonymous/public key
 *   - Usage: src/lib/supabase.js, src/modules/pazar/stores/pazarAuthStore.js,
 *            src/modules/analytics/services/analyticsService.js
 *   - Required: Yes
 *   - Security: Public (safe to expose in frontend, protected by RLS)
 * 
 * NAPOMENA: Oba env variable su REQUIRED - aplikacija će fail-ovati ako nisu set-ovani.
 */

/*
 * 1.3. ENVIRONMENT VARIABLES VALIDATION
 * ---------------------------------------
 * 
 * Location: src/lib/supabase.js (Line 10-14)
 * 
 * Validation Code:
 *   if (!supabaseUrl || !supabaseAnonKey) {
 *     throw new Error(
 *       'Missing Supabase environment variables. Please ensure VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY are set in your .env file.'
 *     );
 *   }
 * 
 * Behavior:
 *   - Aplikacija će throw-ovati error na startup ako env variables nisu set-ovani
 *   - Error se prikazuje u browser console
 *   - Build će proći, ali runtime će fail-ovati
 * 
 * NAPOMENA: Validation se dešava u runtime, ne u build time.
 */

/*
 * 1.4. ENV FILE STRUCTURE
 * ------------------------
 * 
 * Local Development (.env.local):
 *   VITE_SUPABASE_URL=https://xxxxx.supabase.co
 *   VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 * 
 * Production (Vercel):
 *   - Set u Vercel Dashboard → Settings → Environment Variables
 *   - Automatski se inject-uju u build process
 * 
 * .gitignore:
 *   .env
 *   .env.local
 *   .env.*.local
 * 
 * NAPOMENA: .env fajlovi su gitignored - ne commit-uj env variables u git.
 */

/*
 * 1.5. ENV VARIABLES USAGE PATTERNS
 * -----------------------------------
 * 
 * Pattern 1: Direct Import (src/lib/supabase.js)
 *   const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
 *   const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
 * 
 * Pattern 2: Inline Usage (src/modules/pazar/stores/pazarAuthStore.js)
 *   const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
 *   const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/pin-auth`;
 * 
 * Pattern 3: REST API Calls (src/modules/analytics/services/analyticsService.js)
 *   const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
 *   const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;
 *   const url = `${SUPABASE_URL}/rest/v1/emeni_order_lifecycle?...`;
 * 
 * NAPOMENA: Svi env variables se pristupaju preko import.meta.env (Vite standard).
 */

/* ============================================================================
 * 2. SUPABASE CONFIG - Project URL, anon key, service key - gde se koriste
 * ============================================================================
 */

/*
 * 2.1. SUPABASE CONFIGURATION OVERVIEW
 * --------------------------------------
 * 
 * Project URL: VITE_SUPABASE_URL
 *   - Format: https://{project-ref}.supabase.co
 *   - Example: https://abcdefghijklmnop.supabase.co
 *   - Usage: Base URL za sve Supabase API calls
 * 
 * Anon Key: VITE_SUPABASE_ANON_KEY
 *   - Format: JWT token (eyJhbGc...)
 *   - Usage: Public key za frontend API calls
 *   - Security: Protected by Row Level Security (RLS)
 * 
 * Service Key: N/A u frontend-u
 *   - Format: JWT token (eyJhbGc...)
 *   - Usage: Backend/Edge Functions only (bypasses RLS)
 *   - Security: NEVER expose u frontend - samo backend/Edge Functions
 * 
 * NAPOMENA: Service key se NIKADA ne koristi u frontend-u - samo anon key.
 */

/*
 * 2.2. SUPABASE CLIENT CONFIGURATION
 * ------------------------------------
 * 
 * Location: src/lib/supabase.js
 * 
 * Configuration:
 *   const supabase = createClient(supabaseUrl, supabaseAnonKey, {
 *     auth: {
 *       persistSession: true,        // Persist session u localStorage
 *       autoRefreshToken: true,      // Auto-refresh expired tokens
 *       detectSessionInUrl: true,    // Detect session u URL (OAuth callbacks)
 *     },
 *   });
 * 
 * Features:
 *   - Session persistence: Session se čuva u localStorage
 *   - Auto-refresh: Tokens se automatski refresh-uju
 *   - OAuth support: Detektuje OAuth callbacks u URL
 * 
 * NAPOMENA: Supabase client je konfigurisan za optimalan auth experience.
 */

/*
 * 2.3. SUPABASE URL USAGE LOCATIONS
 * -----------------------------------
 * 
 * 1. src/lib/supabase.js
 *   - Primary Supabase client creation
 *   - Used by: Svi moduli koji koriste Supabase
 * 
 * 2. src/modules/pazar/stores/pazarAuthStore.js
 *   - Edge Function URL construction:
 *     const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/pin-auth`;
 * 
 * 3. src/modules/analytics/services/analyticsService.js
 *   - REST API calls za batch queries:
 *     const url = `${SUPABASE_URL}/rest/v1/emeni_order_lifecycle?...`;
 * 
 * NAPOMENA: Supabase URL se koristi za client creation, Edge Functions i REST API calls.
 */

/*
 * 2.4. SUPABASE ANON KEY USAGE
 * ------------------------------
 * 
 * Usage Locations:
 *   1. src/lib/supabase.js: Client creation
 *   2. src/modules/pazar/stores/pazarAuthStore.js: Edge Function auth header
 *   3. src/modules/analytics/services/analyticsService.js: REST API auth header
 * 
 * Security:
 *   - Anon key je PUBLIC - safe za frontend exposure
 *   - Protected by Row Level Security (RLS) policies
 *   - RLS policies kontrolišu pristup podacima
 * 
 * Edge Function Auth:
 *   headers: {
 *     'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`
 *   }
 * 
 * REST API Auth:
 *   headers: {
 *     'apikey': SUPABASE_KEY,
 *     'Authorization': `Bearer ${SUPABASE_KEY}`
 *   }
 * 
 * NAPOMENA: Anon key se koristi za sve Supabase API calls iz frontend-a.
 */

/*
 * 2.5. SUPABASE SERVICE KEY (Backend Only)
 * -------------------------------------------
 * 
 * IMPORTANT: Service key se NIKADA ne koristi u frontend-u!
 * 
 * Usage:
 *   - Edge Functions (server-side)
 *   - Backend APIs (server-side)
 *   - Database migrations (server-side)
 *   - Admin operations (server-side)
 * 
 * Security:
 *   - Bypasses Row Level Security (RLS)
 *   - Full database access
 *   - NEVER commit u git
 *   - NEVER expose u frontend
 * 
 * NAPOMENA: Service key je samo za backend/Edge Functions - nikada frontend.
 */

/* ============================================================================
 * 3. BUILD PROCESS - npm run build, šta se dešava
 * ============================================================================
 */

/*
 * 3.1. BUILD COMMAND
 * --------------------
 * 
 * Command: npm run build
 * Script: vite build (from package.json)
 * Output: dist/ directory
 * 
 * Process:
 *   1. Vite čita vite.config.js
 *   2. Processes React components (JSX → JS)
 *   3. Bundles dependencies
 *   4. Minifies code (production)
 *   5. Outputs static files u dist/
 * 
 * NAPOMENA: Build proces je standardni Vite build za React aplikacije.
 */

/*
 * 3.2. BUILD CONFIGURATION
 * --------------------------
 * 
 * File: vite.config.js
 * 
 * Current Config:
 *   import { defineConfig } from 'vite'
 *   import react from '@vitejs/plugin-react'
 *   
 *   export default defineConfig({
 *     plugins: [react()],
 *   })
 * 
 * Plugins:
 *   - @vitejs/plugin-react: React support, Fast Refresh, JSX transformation
 * 
 * Default Behavior:
 *   - Entry: src/main.jsx (ili index.html)
 *   - Output: dist/
 *   - Minification: Enabled (production)
 *   - Source maps: Disabled (production)
 * 
 * NAPOMENA: Vite config je minimalan - standardni React setup.
 */

/*
 * 3.3. BUILD OUTPUT
 * ------------------
 * 
 * Directory: dist/
 * 
 * Structure:
 *   dist/
 *     index.html          # Entry HTML file
 *     assets/
 *       index-{hash}.js   # Bundled JavaScript
 *       index-{hash}.css  # Bundled CSS
 *       *.svg, *.png      # Static assets
 * 
 * File Naming:
 *   - Hash-based naming za cache busting
 *   - Example: index-a1b2c3d4.js
 *   - Hash se menja na svaki build sa promenama
 * 
 * Size:
 *   - JavaScript: ~500KB-1MB (minified)
 *   - CSS: ~50-100KB (minified)
 *   - Assets: Varies
 * 
 * NAPOMENA: Build output je static files - ready za deployment na bilo koji static host.
 */

/*
 * 3.4. BUILD ENVIRONMENT VARIABLES
 * ----------------------------------
 * 
 * Build Time:
 *   - Vite inject-uje env variables u build time
 *   - import.meta.env.VITE_* se replace-uje sa actual values
 *   - Values se embed-uju u bundled JavaScript
 * 
 * Important:
 *   - Env variables moraju biti set-ovani pre build-a
 *   - Vercel automatski inject-uje env variables u build process
 *   - Local build zahteva .env.local file
 * 
 * Example:
 *   // Source code:
 *   const url = import.meta.env.VITE_SUPABASE_URL;
 *   
 *   // Built code (production):
 *   const url = "https://xxxxx.supabase.co";
 * 
 * NAPOMENA: Env variables se embed-uju u build - moraju biti set-ovani pre build-a.
 */

/*
 * 3.5. PREVIEW BUILD
 * -------------------
 * 
 * Command: npm run preview
 * Script: vite preview
 * 
 * Purpose:
 *   - Preview production build lokalno
 *   - Test build output pre deployment-a
 *   - Serve dist/ directory
 * 
 * Usage:
 *   1. npm run build (build production)
 *   2. npm run preview (serve dist/)
 *   3. Open http://localhost:4173
 * 
 * NAPOMENA: Preview je za testing production build lokalno pre deployment-a.
 */

/* ============================================================================
 * 4. DEPLOY COMMANDS - Kako deploy-ovati na Vercel
 * ============================================================================
 */

/*
 * 4.1. VERCEL DEPLOYMENT OVERVIEW
 * ---------------------------------
 * 
 * Platform: Vercel
 * Framework: Vite (auto-detected)
 * Build Command: npm run build (auto-detected)
 * Output Directory: dist (auto-detected)
 * 
 * Deployment Methods:
 *   1. Git Integration (automatic)
 *   2. Vercel CLI (manual)
 *   3. GitHub Actions (CI/CD)
 * 
 * NAPOMENA: Vercel automatski detektuje Vite i konfiguriše build settings.
 */

/*
 * 4.2. GIT INTEGRATION (Automatic Deployment)
 * ---------------------------------------------
 * 
 * Setup:
 *   1. Connect repository u Vercel Dashboard
 *   2. Select branch (main, staging, etc.)
 *   3. Configure environment variables
 *   4. Deploy
 * 
 * Automatic Deployment:
 *   - Push to main → Production deployment
 *   - Push to other branches → Preview deployment
 *   - Pull requests → Preview deployment
 * 
 * Configuration:
 *   - Build Command: npm run build (auto-detected)
 *   - Output Directory: dist (auto-detected)
 *   - Install Command: npm install (auto-detected)
 * 
 * NAPOMENA: Git integration omogućava automatic deployment na svaki push.
 */

/*
 * 4.3. VERCEL CLI DEPLOYMENT
 * ---------------------------
 * 
 * Installation:
 *   npm i -g vercel
 * 
 * Login:
 *   vercel login
 * 
 * Deploy:
 *   vercel                    # Deploy to preview
 *   vercel --prod             # Deploy to production
 * 
 * Environment Variables:
 *   vercel env add VITE_SUPABASE_URL
 *   vercel env add VITE_SUPABASE_ANON_KEY
 * 
 * NAPOMENA: Vercel CLI omogućava manual deployment i environment management.
 */

/*
 * 4.4. VERCEL CONFIGURATION
 * ---------------------------
 * 
 * File: vercel.json
 * 
 * Current Config:
 *   {
 *     "rewrites": [
 *       { "source": "/(.*)", "destination": "/" }
 *     ]
 *   }
 * 
 * Purpose:
 *   - SPA routing support (React Router)
 *   - Sve rute se rewrite-uju na index.html
 *   - Omogućava client-side routing
 * 
 * NAPOMENA: vercel.json konfiguriše SPA routing za React Router.
 */

/*
 * 4.5. DEPLOYMENT CHECKLIST
 * --------------------------
 * 
 * Pre-Deployment:
 *   [ ] Environment variables set u Vercel Dashboard
 *   [ ] Build passes lokalno (npm run build)
 *   [ ] Preview works lokalno (npm run preview)
 *   [ ] Code reviewed i tested
 *   [ ] Database migrations applied (if any)
 * 
 * Deployment:
 *   [ ] Push to main branch (ili use Vercel CLI)
 *   [ ] Wait for build to complete
 *   [ ] Check deployment logs
 *   [ ] Test deployed application
 * 
 * Post-Deployment:
 *   [ ] Verify environment variables
 *   [ ] Test critical flows (login, data fetching)
 *   [ ] Monitor error logs
 *   [ ] Check performance metrics
 * 
 * NAPOMENA: Deployment checklist osigurava smooth deployment process.
 */

/* ============================================================================
 * 5. BRANCHES - Main vs staging vs feature branches strategija
 * ============================================================================
 */

/*
 * 5.1. BRANCH STRATEGY OVERVIEW
 * -------------------------------
 * 
 * Recommended Strategy: Git Flow (simplified)
 * 
 * Branches:
 *   - main: Production (stable, deployed)
 *   - staging: Staging environment (testing)
 *   - feature/*: Feature development
 *   - hotfix/*: Critical bug fixes
 * 
 * NAPOMENA: Branch strategija nije eksplicitno dokumentovana - ovo je preporuka.
 */

/*
 * 5.2. MAIN BRANCH
 * -----------------
 * 
 * Purpose: Production-ready code
 * Deployment: Automatic (Vercel production)
 * Protection: Should require PR review
 * 
 * Rules:
 *   - Only merge from staging (ili hotfix)
 *   - Always tested u staging pre merge
 *   - No direct commits (osim hotfixes)
 *   - Tag releases (v1.0.0, v1.1.0, etc.)
 * 
 * NAPOMENA: Main branch je production - samo stable, tested code.
 */

/*
 * 5.3. STAGING BRANCH
 * --------------------
 * 
 * Purpose: Pre-production testing
 * Deployment: Automatic (Vercel preview)
 * Protection: Optional PR review
 * 
 * Rules:
 *   - Merge from feature branches
 *   - Test kompletan flow pre merge u main
 *   - QA testing environment
 *   - Can have temporary debug code
 * 
 * NAPOMENA: Staging branch je za testing pre production deployment-a.
 */

/*
 * 5.4. FEATURE BRANCHES
 * ----------------------
 * 
 * Naming: feature/{feature-name}
 * Examples: feature/magacin-module, feature/analytics-improvements
 * 
 * Workflow:
 *   1. Create branch from staging (ili main)
 *   2. Develop feature
 *   3. Test locally
 *   4. Create PR to staging
 *   5. Review i merge
 * 
 * NAPOMENA: Feature branches su za isolated feature development.
 */

/*
 * 5.5. HOTFIX BRANCHES
 * ----------------------
 * 
 * Naming: hotfix/{bug-description}
 * Examples: hotfix/cors-error, hotfix/auth-bug
 * 
 * Workflow:
 *   1. Create branch from main
 *   2. Fix bug
 *   3. Test thoroughly
 *   4. Create PR to main (bypass staging)
 *   5. Merge to main i staging
 * 
 * NAPOMENA: Hotfix branches su za critical production bugs.
 */

/*
 * 5.6. BRANCH WORKFLOW EXAMPLE
 * ------------------------------
 * 
 * Feature Development:
 *   1. git checkout staging
 *   2. git pull origin staging
 *   3. git checkout -b feature/new-module
 *   4. ... develop feature ...
 *   5. git push origin feature/new-module
 *   6. Create PR: feature/new-module → staging
 *   7. Review, test, merge
 *   8. Deploy staging u Vercel preview
 *   9. Test u staging environment
 *   10. Create PR: staging → main
 *   11. Review, merge
 *   12. Deploy main u Vercel production
 * 
 * Hotfix:
 *   1. git checkout main
 *   2. git checkout -b hotfix/critical-bug
 *   3. ... fix bug ...
 *   4. git push origin hotfix/critical-bug
 *   5. Create PR: hotfix/critical-bug → main
 *   6. Review, merge
 *   7. Merge main → staging (sync)
 * 
 * NAPOMENA: Branch workflow osigurava organized development i safe deployments.
 */

/* ============================================================================
 * 6. DATABASE MIGRATIONS - Kako se rade schema promene
 * ============================================================================
 */

/*
 * 6.1. DATABASE MIGRATIONS OVERVIEW
 * ------------------------------------
 * 
 * Current State:
 *   - NEMA eksplicitnih migration fajlova u projektu
 *   - Schema promene se rade direktno u Supabase Dashboard
 *   - SQL Editor u Supabase Dashboard za schema changes
 * 
 * NAPOMENA: Database migrations se trenutno rade manualno u Supabase Dashboard.
 */

/*
 * 6.2. MANUAL MIGRATION PROCESS
 * -------------------------------
 * 
 * Step 1: Plan Migration
 *   - Document schema changes
 *   - Identify affected tables
 *   - Plan data migration (if needed)
 *   - Test u staging database
 * 
 * Step 2: Create Migration SQL
 *   - Write SQL u Supabase SQL Editor
 *   - Test u staging database
 *   - Document rollback plan
 * 
 * Step 3: Apply Migration
 *   - Run SQL u Supabase Dashboard → SQL Editor
 *   - Verify changes (Table Editor)
 *   - Test application
 * 
 * Step 4: Document Migration
 *   - Save SQL u migration file (migrations/{timestamp}_{description}.sql)
 *   - Document u changelog
 *   - Update documentation
 * 
 * NAPOMENA: Manual migration process zahteva careful planning i testing.
 */

/*
 * 6.3. MIGRATION FILE STRUCTURE (Recommended)
 * ---------------------------------------------
 * 
 * Directory: migrations/
 * 
 * Naming: {YYYYMMDD}_{description}.sql
 * Examples:
 *   - 20260117_add_magacin_permissions.sql
 *   - 20260118_create_pazar_tables.sql
 *   - 20260119_add_analytics_indexes.sql
 * 
 * Structure:
 *   -- Migration: Add Magacin Module Permissions
 *   -- Date: 2026-01-17
 *   -- Author: Developer Name
 *   -- Description: Add permissions for magacin module
 *   
 *   -- Up Migration
 *   INSERT INTO module_permissions (role, module, can_view, can_edit)
 *   VALUES ('admin', 'magacin', true, true),
 *          ('menadzer', 'magacin', true, true);
 *   
 *   -- Down Migration (Rollback)
 *   DELETE FROM module_permissions
 *   WHERE module = 'magacin';
 * 
 * NAPOMENA: Migration files omogućavaju version control za schema changes.
 */

/*
 * 6.4. COMMON MIGRATION TYPES
 * -----------------------------
 * 
 * 1. CREATE TABLE:
 *   CREATE TABLE new_table (
 *     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *     ...
 *   );
 * 
 * 2. ALTER TABLE (Add Column):
 *   ALTER TABLE existing_table
 *   ADD COLUMN new_column TEXT;
 * 
 * 3. CREATE INDEX:
 *   CREATE INDEX idx_table_column ON table(column);
 * 
 * 4. ADD FOREIGN KEY:
 *   ALTER TABLE child_table
 *   ADD CONSTRAINT fk_parent
 *   FOREIGN KEY (parent_id) REFERENCES parent_table(id);
 * 
 * 5. UPDATE DATA:
 *   UPDATE table SET column = value WHERE condition;
 * 
 * NAPOMENA: Common migration types pokrivaju većinu schema changes.
 */

/*
 * 6.5. MIGRATION BEST PRACTICES
 * -------------------------------
 * 
 * DO:
 *   - Test migrations u staging database first
 *   - Backup database pre migration
 *   - Write rollback SQL
 *   - Document migrations
 *   - Use transactions (BEGIN/COMMIT)
 *   - Add indexes za performance
 * 
 * DON'T:
 *   - Don't drop columns without data migration
 *   - Don't rename columns without migration script
 *   - Don't change data types without conversion
 *   - Don't run migrations u production bez testing
 * 
 * NAPOMENA: Migration best practices osiguravaju safe schema changes.
 */

/*
 * 6.6. AUTOMATED MIGRATIONS (Future)
 * ------------------------------------
 * 
 * Option 1: Supabase CLI
 *   - supabase db push (apply migrations)
 *   - supabase db pull (generate migrations from schema)
 *   - supabase migration new {name}
 * 
 * Option 2: Custom Migration Script
 *   - Node.js script za running migrations
 *   - Migration files u migrations/ directory
 *   - Version tracking u database
 * 
 * Option 3: Supabase Migrations (Supabase Dashboard)
 *   - Built-in migration system
 *   - Version control u Supabase
 *   - Rollback support
 * 
 * NAPOMENA: Automated migrations bi poboljšale migration process ali zahteva setup.
 */

/* ============================================================================
 * 7. ROLLBACK - Kako vratiti na prethodnu verziju ako nešto pukne
 * ============================================================================
 */

/*
 * 7.1. ROLLBACK OVERVIEW
 * ------------------------
 * 
 * Rollback Types:
 *   1. Code Rollback (Vercel)
 *   2. Database Rollback (Supabase)
 *   3. Environment Variables Rollback (Vercel)
 * 
 * NAPOMENA: Rollback process zavisi od tipa problema.
 */

/*
 * 7.2. CODE ROLLBACK (Vercel)
 * -----------------------------
 * 
 * Method 1: Vercel Dashboard
 *   1. Go to Vercel Dashboard → Deployments
 *   2. Find previous working deployment
 *   3. Click "..." → "Promote to Production"
 *   4. Confirm rollback
 * 
 * Method 2: Git Revert
 *   1. git revert {commit-hash}
 *   2. git push origin main
 *   3. Vercel automatski deploy-uje revert
 * 
 * Method 3: Git Reset (Dangerous)
 *   1. git reset --hard {previous-commit}
 *   2. git push --force origin main
 *   3. Vercel automatski deploy-uje reset
 * 
 * NAPOMENA: Code rollback je najlakši - Vercel čuva deployment history.
 */

/*
 * 7.3. DATABASE ROLLBACK
 * ------------------------
 * 
 * Method 1: Manual SQL Rollback
 *   1. Identify migration that caused issue
 *   2. Write reverse SQL (DOWN migration)
 *   3. Run u Supabase SQL Editor
 *   4. Verify data integrity
 * 
 * Method 2: Supabase Point-in-Time Recovery
 *   1. Go to Supabase Dashboard → Database → Backups
 *   2. Select restore point (pre migration)
 *   3. Restore database
 *   4. Verify application works
 * 
 * Method 3: Manual Data Fix
 *   1. Identify affected data
 *   2. Write SQL za data correction
 *   3. Run u Supabase SQL Editor
 *   4. Verify fix
 * 
 * NAPOMENA: Database rollback zahteva careful planning - backup je critical.
 */

/*
 * 7.4. ENVIRONMENT VARIABLES ROLLBACK
 * -------------------------------------
 * 
 * Method: Vercel Dashboard
 *   1. Go to Vercel Dashboard → Settings → Environment Variables
 *   2. Edit variable
 *   3. Set to previous value
 *   4. Redeploy (automatic ili manual)
 * 
 * NAPOMENA: Environment variables rollback je jednostavan - samo promeni value.
 */

/*
 * 7.5. ROLLBACK CHECKLIST
 * -------------------------
 * 
 * Pre-Rollback:
 *   [ ] Identify issue (code, database, env)
 *   [ ] Identify previous working state
 *   [ ] Backup current state (database)
 *   [ ] Document rollback plan
 *   [ ] Notify team
 * 
 * During Rollback:
 *   [ ] Execute rollback (code/database/env)
 *   [ ] Verify rollback success
 *   [ ] Test critical flows
 *   [ ] Monitor error logs
 * 
 * Post-Rollback:
 *   [ ] Document what went wrong
 *   [ ] Create issue/ticket za fix
 *   [ ] Plan proper fix
 *   [ ] Test fix u staging
 *   [ ] Deploy fix u production
 * 
 * NAPOMENA: Rollback checklist osigurava organized rollback process.
 */

/*
 * 7.6. PREVENTION STRATEGIES
 * ---------------------------
 * 
 * Code:
 *   - Code review pre merge
 *   - Automated testing (unit, integration)
 *   - Staging environment testing
 *   - Gradual rollout (feature flags)
 * 
 * Database:
 *   - Test migrations u staging first
 *   - Backup database pre migration
 *   - Write rollback SQL
 *   - Use transactions
 * 
 * Environment:
 *   - Validate env variables pre deployment
 *   - Use staging environment za testing
 *   - Document env variable changes
 * 
 * NAPOMENA: Prevention strategies smanjuju potrebu za rollback-om.
 */

/* ============================================================================
 * 8. DEPLOYMENT ENVIRONMENTS
 * ============================================================================
 */

/*
 * 8.1. ENVIRONMENT TYPES
 * -----------------------
 * 
 * Development (Local):
 *   - URL: http://localhost:5173 (Vite dev server)
 *   - Database: Supabase (shared ili local)
 *   - Env: .env.local
 *   - Purpose: Local development
 * 
 * Staging:
 *   - URL: https://collina-project-staging.vercel.app
 *   - Database: Supabase (staging database)
 *   - Env: Vercel staging environment
 *   - Purpose: Pre-production testing
 * 
 * Production:
 *   - URL: https://collina-project.vercel.app (ili custom domain)
 *   - Database: Supabase (production database)
 *   - Env: Vercel production environment
 *   - Purpose: Live application
 * 
 * NAPOMENA: Multiple environments omogućavaju safe development i testing.
 */

/*
 * 8.2. ENVIRONMENT VARIABLES PER ENVIRONMENT
 * --------------------------------------------
 * 
 * Development (.env.local):
 *   VITE_SUPABASE_URL=https://dev-project.supabase.co
 *   VITE_SUPABASE_ANON_KEY=dev-anon-key
 * 
 * Staging (Vercel):
 *   VITE_SUPABASE_URL=https://staging-project.supabase.co
 *   VITE_SUPABASE_ANON_KEY=staging-anon-key
 * 
 * Production (Vercel):
 *   VITE_SUPABASE_URL=https://prod-project.supabase.co
 *   VITE_SUPABASE_ANON_KEY=prod-anon-key
 * 
 * NAPOMENA: Svaki environment ima svoje Supabase project i env variables.
 */

/* ============================================================================
 * KRAJ DOKUMENTACIJE
 * ============================================================================
 */
