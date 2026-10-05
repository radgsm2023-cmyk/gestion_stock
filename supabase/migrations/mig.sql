/*
# Système de gestion de stock — Schéma complet

## Description
Crée toutes les tables nécessaires pour un système de gestion de stock :
produits, fournisseurs, clients, achats, ventes, retours, paiements partiels,
bons de commande, bons de livraison et factures.

## Tables créées

### Tables de référence
- `products` : produits (nom, SKU, catégorie, prix d'achat, prix de vente, stock, stock minimum)
- `suppliers` : fournisseurs (nom, contact, email, téléphone, adresse)
- `customers` : clients (nom, contact, email, téléphone, adresse)

### Achats
- `purchases` : achats (fournisseur, statut, total, montant payé, date)
- `purchase_items` : lignes d'achat (produit, quantité, prix unitaire, total)
- `purchase_payments` : paiements d'achat (montant, date, méthode)
- `purchase_returns` : retours d'achat (achat lié, total, date)
- `purchase_return_items` : lignes de retour d'achat

### Ventes
- `sales` : ventes (client, statut, total, montant payé, date)
- `sale_items` : lignes de vente
- `sale_payments` : paiements de vente
- `sales_returns` : retours de vente
- `sales_return_items` : lignes de retour de vente

### Documents
- `purchase_orders` : bons de commande (fournisseur, statut, total, dates)
- `purchase_order_items` : lignes de bon de commande
- `delivery_notes` : bons de livraison (client, statut, total, date)
- `delivery_note_items` : lignes de bon de livraison
- `invoices` : factures (vente liée, client, total, payé, statut, dates)

## Sécurité
- RLS activée sur toutes les tables.
- Application mono-utilisateur (pas d'auth) : politiques `TO anon, authenticated` avec `USING (true)`.
*/

-- ===== PRODUITS =====
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  sku text UNIQUE,
  category text DEFAULT 'Général',
  description text DEFAULT '',
  unit text DEFAULT 'pièce',
  cost_price numeric(12,2) NOT NULL DEFAULT 0,
  sale_price numeric(12,2) NOT NULL DEFAULT 0,
  stock_quantity numeric(12,2) NOT NULL DEFAULT 0,
  min_stock numeric(12,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_products" ON products;
CREATE POLICY "anon_select_products" ON products FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_products" ON products;
CREATE POLICY "anon_insert_products" ON products FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_products" ON products;
CREATE POLICY "anon_update_products" ON products FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_products" ON products;
CREATE POLICY "anon_delete_products" ON products FOR DELETE TO anon, authenticated USING (true);

-- ===== FOURNISSEURS =====
CREATE TABLE IF NOT EXISTS suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  contact_person text DEFAULT '',
  email text DEFAULT '',
  phone text DEFAULT '',
  address text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_suppliers" ON suppliers;
CREATE POLICY "anon_select_suppliers" ON suppliers FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_suppliers" ON suppliers;
CREATE POLICY "anon_insert_suppliers" ON suppliers FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_suppliers" ON suppliers;
CREATE POLICY "anon_update_suppliers" ON suppliers FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_suppliers" ON suppliers;
CREATE POLICY "anon_delete_suppliers" ON suppliers FOR DELETE TO anon, authenticated USING (true);

-- ===== CLIENTS =====
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  contact_person text DEFAULT '',
  email text DEFAULT '',
  phone text DEFAULT '',
  address text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_customers" ON customers;
CREATE POLICY "anon_select_customers" ON customers FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_customers" ON customers;
CREATE POLICY "anon_insert_customers" ON customers FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_customers" ON customers;
CREATE POLICY "anon_update_customers" ON customers FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_customers" ON customers;
CREATE POLICY "anon_delete_customers" ON customers FOR DELETE TO anon, authenticated USING (true);

-- ===== ACHATS =====
CREATE TABLE IF NOT EXISTS purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'pending', -- pending, received, cancelled
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  paid_amount numeric(12,2) NOT NULL DEFAULT 0,
  purchase_date date NOT NULL DEFAULT CURRENT_DATE,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_purchases" ON purchases;
CREATE POLICY "anon_select_purchases" ON purchases FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchases" ON purchases;
CREATE POLICY "anon_insert_purchases" ON purchases FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchases" ON purchases;
CREATE POLICY "anon_update_purchases" ON purchases FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchases" ON purchases;
CREATE POLICY "anon_delete_purchases" ON purchases FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS purchase_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id uuid NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  quantity numeric(12,2) NOT NULL DEFAULT 1,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(12,2) NOT NULL DEFAULT 0
);
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_purchase_items" ON purchase_items;
CREATE POLICY "anon_select_purchase_items" ON purchase_items FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_items" ON purchase_items;
CREATE POLICY "anon_insert_purchase_items" ON purchase_items FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_items" ON purchase_items;
CREATE POLICY "anon_update_purchase_items" ON purchase_items FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_items" ON purchase_items;
CREATE POLICY "anon_delete_purchase_items" ON purchase_items FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS purchase_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id uuid NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  amount numeric(12,2) NOT NULL DEFAULT 0,
  payment_date date NOT NULL DEFAULT CURRENT_DATE,
  method text DEFAULT 'espèces', -- espèces, chèque, virement, carte
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE purchase_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_purchase_payments" ON purchase_payments;
CREATE POLICY "anon_select_purchase_payments" ON purchase_payments FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_payments" ON purchase_payments;
CREATE POLICY "anon_insert_purchase_payments" ON purchase_payments FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_payments" ON purchase_payments;
CREATE POLICY "anon_update_purchase_payments" ON purchase_payments FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_payments" ON purchase_payments;
CREATE POLICY "anon_delete_purchase_payments" ON purchase_payments FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS purchase_returns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id uuid NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  reference text NOT NULL,
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  return_date date NOT NULL DEFAULT CURRENT_DATE,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE purchase_returns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_purchase_returns" ON purchase_returns;
CREATE POLICY "anon_select_purchase_returns" ON purchase_returns FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_returns" ON purchase_returns;
CREATE POLICY "anon_insert_purchase_returns" ON purchase_returns FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_returns" ON purchase_returns;
CREATE POLICY "anon_update_purchase_returns" ON purchase_returns FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_returns" ON purchase_returns;
CREATE POLICY "anon_delete_purchase_returns" ON purchase_returns FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS purchase_return_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  return_id uuid NOT NULL REFERENCES purchase_returns(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  quantity numeric(12,2) NOT NULL DEFAULT 1,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(12,2) NOT NULL DEFAULT 0
);
ALTER TABLE purchase_return_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_purchase_return_items" ON purchase_return_items;
CREATE POLICY "anon_select_purchase_return_items" ON purchase_return_items FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_return_items" ON purchase_return_items;
CREATE POLICY "anon_insert_purchase_return_items" ON purchase_return_items FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_return_items" ON purchase_return_items;
CREATE POLICY "anon_update_purchase_return_items" ON purchase_return_items FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_return_items" ON purchase_return_items;
CREATE POLICY "anon_delete_purchase_return_items" ON purchase_return_items FOR DELETE TO anon, authenticated USING (true);

-- ===== VENTES =====
CREATE TABLE IF NOT EXISTS sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'pending', -- pending, delivered, cancelled
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  paid_amount numeric(12,2) NOT NULL DEFAULT 0,
  sale_date date NOT NULL DEFAULT CURRENT_DATE,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_sales" ON sales;
CREATE POLICY "anon_select_sales" ON sales FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sales" ON sales;
CREATE POLICY "anon_insert_sales" ON sales FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sales" ON sales;
CREATE POLICY "anon_update_sales" ON sales FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sales" ON sales;
CREATE POLICY "anon_delete_sales" ON sales FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS sale_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  quantity numeric(12,2) NOT NULL DEFAULT 1,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(12,2) NOT NULL DEFAULT 0
);
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_sale_items" ON sale_items;
CREATE POLICY "anon_select_sale_items" ON sale_items FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sale_items" ON sale_items;
CREATE POLICY "anon_insert_sale_items" ON sale_items FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sale_items" ON sale_items;
CREATE POLICY "anon_update_sale_items" ON sale_items FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sale_items" ON sale_items;
CREATE POLICY "anon_delete_sale_items" ON sale_items FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS sale_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  amount numeric(12,2) NOT NULL DEFAULT 0,
  payment_date date NOT NULL DEFAULT CURRENT_DATE,
  method text DEFAULT 'espèces',
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE sale_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_sale_payments" ON sale_payments;
CREATE POLICY "anon_select_sale_payments" ON sale_payments FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sale_payments" ON sale_payments;
CREATE POLICY "anon_insert_sale_payments" ON sale_payments FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sale_payments" ON sale_payments;
CREATE POLICY "anon_update_sale_payments" ON sale_payments FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sale_payments" ON sale_payments;
CREATE POLICY "anon_delete_sale_payments" ON sale_payments FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS sales_returns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  reference text NOT NULL,
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  return_date date NOT NULL DEFAULT CURRENT_DATE,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE sales_returns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_sales_returns" ON sales_returns;
CREATE POLICY "anon_select_sales_returns" ON sales_returns FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sales_returns" ON sales_returns;
CREATE POLICY "anon_insert_sales_returns" ON sales_returns FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sales_returns" ON sales_returns;
CREATE POLICY "anon_update_sales_returns" ON sales_returns FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sales_returns" ON sales_returns;
CREATE POLICY "anon_delete_sales_returns" ON sales_returns FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS sales_return_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  return_id uuid NOT NULL REFERENCES sales_returns(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  quantity numeric(12,2) NOT NULL DEFAULT 1,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(12,2) NOT NULL DEFAULT 0
);
ALTER TABLE sales_return_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_sales_return_items" ON sales_return_items;
CREATE POLICY "anon_select_sales_return_items" ON sales_return_items FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sales_return_items" ON sales_return_items;
CREATE POLICY "anon_insert_sales_return_items" ON sales_return_items FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sales_return_items" ON sales_return_items;
CREATE POLICY "anon_update_sales_return_items" ON sales_return_items FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sales_return_items" ON sales_return_items;
CREATE POLICY "anon_delete_sales_return_items" ON sales_return_items FOR DELETE TO anon, authenticated USING (true);

-- ===== BONS DE COMMANDE =====
CREATE TABLE IF NOT EXISTS purchase_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'draft', -- draft, sent, received, cancelled
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  order_date date NOT NULL DEFAULT CURRENT_DATE,
  expected_date date,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_purchase_orders" ON purchase_orders;
CREATE POLICY "anon_select_purchase_orders" ON purchase_orders FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_orders" ON purchase_orders;
CREATE POLICY "anon_insert_purchase_orders" ON purchase_orders FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_orders" ON purchase_orders;
CREATE POLICY "anon_update_purchase_orders" ON purchase_orders FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_orders" ON purchase_orders;
CREATE POLICY "anon_delete_purchase_orders" ON purchase_orders FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS purchase_order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  quantity numeric(12,2) NOT NULL DEFAULT 1,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(12,2) NOT NULL DEFAULT 0
);
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_purchase_order_items" ON purchase_order_items;
CREATE POLICY "anon_select_purchase_order_items" ON purchase_order_items FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_order_items" ON purchase_order_items;
CREATE POLICY "anon_insert_purchase_order_items" ON purchase_order_items FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_order_items" ON purchase_order_items;
CREATE POLICY "anon_update_purchase_order_items" ON purchase_order_items FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_order_items" ON purchase_order_items;
CREATE POLICY "anon_delete_purchase_order_items" ON purchase_order_items FOR DELETE TO anon, authenticated USING (true);

-- ===== BONS DE LIVRAISON =====
CREATE TABLE IF NOT EXISTS delivery_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'draft', -- draft, delivered, cancelled
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  delivery_date date NOT NULL DEFAULT CURRENT_DATE,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE delivery_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_delivery_notes" ON delivery_notes;
CREATE POLICY "anon_select_delivery_notes" ON delivery_notes FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_delivery_notes" ON delivery_notes;
CREATE POLICY "anon_insert_delivery_notes" ON delivery_notes FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_delivery_notes" ON delivery_notes;
CREATE POLICY "anon_update_delivery_notes" ON delivery_notes FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_delivery_notes" ON delivery_notes;
CREATE POLICY "anon_delete_delivery_notes" ON delivery_notes FOR DELETE TO anon, authenticated USING (true);

CREATE TABLE IF NOT EXISTS delivery_note_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_note_id uuid NOT NULL REFERENCES delivery_notes(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  quantity numeric(12,2) NOT NULL DEFAULT 1,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(12,2) NOT NULL DEFAULT 0
);
ALTER TABLE delivery_note_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_delivery_note_items" ON delivery_note_items;
CREATE POLICY "anon_select_delivery_note_items" ON delivery_note_items FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_delivery_note_items" ON delivery_note_items;
CREATE POLICY "anon_insert_delivery_note_items" ON delivery_note_items FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_delivery_note_items" ON delivery_note_items;
CREATE POLICY "anon_update_delivery_note_items" ON delivery_note_items FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_delivery_note_items" ON delivery_note_items;
CREATE POLICY "anon_delete_delivery_note_items" ON delivery_note_items FOR DELETE TO anon, authenticated USING (true);

-- ===== FACTURES =====
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid REFERENCES sales(id) ON DELETE SET NULL,
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  reference text NOT NULL,
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  paid_amount numeric(12,2) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'unpaid', -- unpaid, partial, paid, cancelled
  issue_date date NOT NULL DEFAULT CURRENT_DATE,
  due_date date,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_invoices" ON invoices;
CREATE POLICY "anon_select_invoices" ON invoices FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_invoices" ON invoices;
CREATE POLICY "anon_insert_invoices" ON invoices FOR INSERT TO anon, authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_invoices" ON invoices;
CREATE POLICY "anon_update_invoices" ON invoices FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_invoices" ON invoices;
CREATE POLICY "anon_delete_invoices" ON invoices FOR DELETE TO anon, authenticated USING (true);

-- ===== INDEX =====
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier ON purchases(supplier_id);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON purchase_items(purchase_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);

/*
# Système d'authentification, rôles utilisateurs et paramètres

## Description
Ajoute le système de gestion des utilisateurs (administrateur, vendeur) avec authentification,
une table de paramètres de l'application (symbole monétaire, titre, registre, fiscal),
et modifie les ventes pour supporter les clients de passage (non enregistrés).

## Tables créées

### `profiles`
- Profils utilisateurs liés à auth.users
- `id` (uuid, PK, FK vers auth.users)
- `email` (text)
- `full_name` (text)
- `role` (text: 'admin' ou 'vendeur')
- `active` (boolean, défaut true)
- `created_at` (timestamptz)

### `app_settings`
- Paramètres globaux de l'application (ligne unique)
- `id` (int, PK, défaut 1)
- `app_title` (text, défaut 'StockFlow')
- `currency_symbol` (text, défaut '€')
- `currency_code` (text, défaut 'EUR')
- `company_name` (text)
- `company_address` (text)
- `company_phone` (text)
- `company_email` (text)
- `rc` (text — registre de commerce)
- `ice` (text — identifiant commun de l'entreprise)
- `nif` (text — numéro d'identification fiscale)
- `patente` (text)
- `cnss` (text)
- `updated_at` (timestamptz)

## Table modifiée

### `sales`
- Ajout colonne `customer_name` (text) pour les ventes à clients de passage
- Quand `customer_id` est NULL, `customer_name` contient le nom du client de passage

## Sécurité
- RLS activée sur `profiles` et `app_settings`
- `profiles` : SELECT pour tous les authentifiés, INSERT/UPDATE/DELETE pour admin uniquement
- `app_settings` : SELECT pour tous les authentifiés, UPDATE pour admin uniquement
- Trigger `on_auth_user_created` : crée automatiquement un profil à l'inscription
- Les tables existantes passent de `anon, authenticated` à `authenticated` uniquement

## Notes importantes
1. Les politiques des tables existantes sont mises à jour pour `authenticated` uniquement
2. Le premier utilisateur inscrit devient administrateur
3. L'email de confirmation reste désactivé
*/

-- ===== TABLE PROFILES =====
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL DEFAULT '',
  role text NOT NULL DEFAULT 'vendeur' CHECK (role IN ('admin', 'vendeur')),
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_all" ON profiles;
CREATE POLICY "profiles_select_all" ON profiles FOR SELECT
  TO authenticated USING (true);

DROP POLICY IF EXISTS "profiles_insert_admin" ON profiles;
CREATE POLICY "profiles_insert_admin" ON profiles FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "profiles_update_admin" ON profiles;
CREATE POLICY "profiles_update_admin" ON profiles FOR UPDATE
  TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "profiles_delete_admin" ON profiles;
CREATE POLICY "profiles_delete_admin" ON profiles FOR DELETE
  TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ===== TABLE APP_SETTINGS =====
CREATE TABLE IF NOT EXISTS app_settings (
  id int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  app_title text NOT NULL DEFAULT 'StockFlow',
  currency_symbol text NOT NULL DEFAULT '€',
  currency_code text NOT NULL DEFAULT 'EUR',
  company_name text NOT NULL DEFAULT '',
  company_address text NOT NULL DEFAULT '',
  company_phone text NOT NULL DEFAULT '',
  company_email text NOT NULL DEFAULT '',
  rc text NOT NULL DEFAULT '',
  ice text NOT NULL DEFAULT '',
  nif text NOT NULL DEFAULT '',
  patente text NOT NULL DEFAULT '',
  cnss text NOT NULL DEFAULT '',
  updated_at timestamptz DEFAULT now()
);

-- Insérer la ligne par défaut si elle n'existe pas
INSERT INTO app_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "settings_select_all" ON app_settings;
CREATE POLICY "settings_select_all" ON app_settings FOR SELECT
  TO authenticated USING (true);

DROP POLICY IF EXISTS "settings_update_admin" ON app_settings;
CREATE POLICY "settings_update_admin" ON app_settings FOR UPDATE
  TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ===== TRIGGER : auto-création de profil à l'inscription =====
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Le premier utilisateur devient admin, les autres vendeurs
  INSERT INTO profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    CASE WHEN (SELECT COUNT(*) FROM profiles) = 0 THEN 'admin' ELSE 'vendeur' END
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ===== COLONNE customer_name SUR SALES =====
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'customer_name') THEN
    ALTER TABLE sales ADD COLUMN customer_name text DEFAULT '';
  END IF;
END $$;

-- ===== MISE À JOUR DES POLITIQUES : passer de anon à authenticated =====
-- products
DROP POLICY IF EXISTS "anon_select_products" ON products;
CREATE POLICY "auth_select_products" ON products FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_products" ON products;
CREATE POLICY "auth_insert_products" ON products FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_products" ON products;
CREATE POLICY "auth_update_products" ON products FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_products" ON products;
CREATE POLICY "auth_delete_products" ON products FOR DELETE TO authenticated USING (true);

-- suppliers
DROP POLICY IF EXISTS "anon_select_suppliers" ON suppliers;
CREATE POLICY "auth_select_suppliers" ON suppliers FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_suppliers" ON suppliers;
CREATE POLICY "auth_insert_suppliers" ON suppliers FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_suppliers" ON suppliers;
CREATE POLICY "auth_update_suppliers" ON suppliers FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_suppliers" ON suppliers;
CREATE POLICY "auth_delete_suppliers" ON suppliers FOR DELETE TO authenticated USING (true);

-- customers
DROP POLICY IF EXISTS "anon_select_customers" ON customers;
CREATE POLICY "auth_select_customers" ON customers FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_customers" ON customers;
CREATE POLICY "auth_insert_customers" ON customers FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_customers" ON customers;
CREATE POLICY "auth_update_customers" ON customers FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_customers" ON customers;
CREATE POLICY "auth_delete_customers" ON customers FOR DELETE TO authenticated USING (true);

-- purchases
DROP POLICY IF EXISTS "anon_select_purchases" ON purchases;
CREATE POLICY "auth_select_purchases" ON purchases FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchases" ON purchases;
CREATE POLICY "auth_insert_purchases" ON purchases FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchases" ON purchases;
CREATE POLICY "auth_update_purchases" ON purchases FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchases" ON purchases;
CREATE POLICY "auth_delete_purchases" ON purchases FOR DELETE TO authenticated USING (true);

-- purchase_items
DROP POLICY IF EXISTS "anon_select_purchase_items" ON purchase_items;
CREATE POLICY "auth_select_purchase_items" ON purchase_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_items" ON purchase_items;
CREATE POLICY "auth_insert_purchase_items" ON purchase_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_items" ON purchase_items;
CREATE POLICY "auth_update_purchase_items" ON purchase_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_items" ON purchase_items;
CREATE POLICY "auth_delete_purchase_items" ON purchase_items FOR DELETE TO authenticated USING (true);

-- purchase_payments
DROP POLICY IF EXISTS "anon_select_purchase_payments" ON purchase_payments;
CREATE POLICY "auth_select_purchase_payments" ON purchase_payments FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_payments" ON purchase_payments;
CREATE POLICY "auth_insert_purchase_payments" ON purchase_payments FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_payments" ON purchase_payments;
CREATE POLICY "auth_update_purchase_payments" ON purchase_payments FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_payments" ON purchase_payments;
CREATE POLICY "auth_delete_purchase_payments" ON purchase_payments FOR DELETE TO authenticated USING (true);

-- purchase_returns
DROP POLICY IF EXISTS "anon_select_purchase_returns" ON purchase_returns;
CREATE POLICY "auth_select_purchase_returns" ON purchase_returns FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_returns" ON purchase_returns;
CREATE POLICY "auth_insert_purchase_returns" ON purchase_returns FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_returns" ON purchase_returns;
CREATE POLICY "auth_update_purchase_returns" ON purchase_returns FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_returns" ON purchase_returns;
CREATE POLICY "auth_delete_purchase_returns" ON purchase_returns FOR DELETE TO authenticated USING (true);

-- purchase_return_items
DROP POLICY IF EXISTS "anon_select_purchase_return_items" ON purchase_return_items;
CREATE POLICY "auth_select_purchase_return_items" ON purchase_return_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_return_items" ON purchase_return_items;
CREATE POLICY "auth_insert_purchase_return_items" ON purchase_return_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_return_items" ON purchase_return_items;
CREATE POLICY "auth_update_purchase_return_items" ON purchase_return_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_return_items" ON purchase_return_items;
CREATE POLICY "auth_delete_purchase_return_items" ON purchase_return_items FOR DELETE TO authenticated USING (true);

-- sales
DROP POLICY IF EXISTS "anon_select_sales" ON sales;
CREATE POLICY "auth_select_sales" ON sales FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sales" ON sales;
CREATE POLICY "auth_insert_sales" ON sales FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sales" ON sales;
CREATE POLICY "auth_update_sales" ON sales FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sales" ON sales;
CREATE POLICY "auth_delete_sales" ON sales FOR DELETE TO authenticated USING (true);

-- sale_items
DROP POLICY IF EXISTS "anon_select_sale_items" ON sale_items;
CREATE POLICY "auth_select_sale_items" ON sale_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sale_items" ON sale_items;
CREATE POLICY "auth_insert_sale_items" ON sale_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sale_items" ON sale_items;
CREATE POLICY "auth_update_sale_items" ON sale_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sale_items" ON sale_items;
CREATE POLICY "auth_delete_sale_items" ON sale_items FOR DELETE TO authenticated USING (true);

-- sale_payments
DROP POLICY IF EXISTS "anon_select_sale_payments" ON sale_payments;
CREATE POLICY "auth_select_sale_payments" ON sale_payments FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sale_payments" ON sale_payments;
CREATE POLICY "auth_insert_sale_payments" ON sale_payments FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sale_payments" ON sale_payments;
CREATE POLICY "auth_update_sale_payments" ON sale_payments FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sale_payments" ON sale_payments;
CREATE POLICY "auth_delete_sale_payments" ON sale_payments FOR DELETE TO authenticated USING (true);

-- sales_returns
DROP POLICY IF EXISTS "anon_select_sales_returns" ON sales_returns;
CREATE POLICY "auth_select_sales_returns" ON sales_returns FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sales_returns" ON sales_returns;
CREATE POLICY "auth_insert_sales_returns" ON sales_returns FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sales_returns" ON sales_returns;
CREATE POLICY "auth_update_sales_returns" ON sales_returns FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sales_returns" ON sales_returns;
CREATE POLICY "auth_delete_sales_returns" ON sales_returns FOR DELETE TO authenticated USING (true);

-- sales_return_items
DROP POLICY IF EXISTS "anon_select_sales_return_items" ON sales_return_items;
CREATE POLICY "auth_select_sales_return_items" ON sales_return_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_sales_return_items" ON sales_return_items;
CREATE POLICY "auth_insert_sales_return_items" ON sales_return_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_sales_return_items" ON sales_return_items;
CREATE POLICY "auth_update_sales_return_items" ON sales_return_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_sales_return_items" ON sales_return_items;
CREATE POLICY "auth_delete_sales_return_items" ON sales_return_items FOR DELETE TO authenticated USING (true);

-- purchase_orders
DROP POLICY IF EXISTS "anon_select_purchase_orders" ON purchase_orders;
CREATE POLICY "auth_select_purchase_orders" ON purchase_orders FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_orders" ON purchase_orders;
CREATE POLICY "auth_insert_purchase_orders" ON purchase_orders FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_orders" ON purchase_orders;
CREATE POLICY "auth_update_purchase_orders" ON purchase_orders FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_orders" ON purchase_orders;
CREATE POLICY "auth_delete_purchase_orders" ON purchase_orders FOR DELETE TO authenticated USING (true);

-- purchase_order_items
DROP POLICY IF EXISTS "anon_select_purchase_order_items" ON purchase_order_items;
CREATE POLICY "auth_select_purchase_order_items" ON purchase_order_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_purchase_order_items" ON purchase_order_items;
CREATE POLICY "auth_insert_purchase_order_items" ON purchase_order_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_purchase_order_items" ON purchase_order_items;
CREATE POLICY "auth_update_purchase_order_items" ON purchase_order_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_purchase_order_items" ON purchase_order_items;
CREATE POLICY "auth_delete_purchase_order_items" ON purchase_order_items FOR DELETE TO authenticated USING (true);

-- delivery_notes
DROP POLICY IF EXISTS "anon_select_delivery_notes" ON delivery_notes;
CREATE POLICY "auth_select_delivery_notes" ON delivery_notes FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_delivery_notes" ON delivery_notes;
CREATE POLICY "auth_insert_delivery_notes" ON delivery_notes FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_delivery_notes" ON delivery_notes;
CREATE POLICY "auth_update_delivery_notes" ON delivery_notes FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_delivery_notes" ON delivery_notes;
CREATE POLICY "auth_delete_delivery_notes" ON delivery_notes FOR DELETE TO authenticated USING (true);

-- delivery_note_items
DROP POLICY IF EXISTS "anon_select_delivery_note_items" ON delivery_note_items;
CREATE POLICY "auth_select_delivery_note_items" ON delivery_note_items FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_delivery_note_items" ON delivery_note_items;
CREATE POLICY "auth_insert_delivery_note_items" ON delivery_note_items FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_delivery_note_items" ON delivery_note_items;
CREATE POLICY "auth_update_delivery_note_items" ON delivery_note_items FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_delivery_note_items" ON delivery_note_items;
CREATE POLICY "auth_delete_delivery_note_items" ON delivery_note_items FOR DELETE TO authenticated USING (true);

-- invoices
DROP POLICY IF EXISTS "anon_select_invoices" ON invoices;
CREATE POLICY "auth_select_invoices" ON invoices FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "anon_insert_invoices" ON invoices;
CREATE POLICY "auth_insert_invoices" ON invoices FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "anon_update_invoices" ON invoices;
CREATE POLICY "auth_update_invoices" ON invoices FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_delete_invoices" ON invoices;
CREATE POLICY "auth_delete_invoices" ON invoices FOR DELETE TO authenticated USING (true);

/*
# Ajouter identifiants fiscaux aux clients

## Description
Ajoute les colonnes d'identifiants fiscaux à la table customers pour la facturation.

## Modifications
### Table `customers`
- `ice` (text) — Identifiant Commun de l'Entreprise
- `nif` (text) — Numéro d'Identification Fiscale
- `rc` (text) — Registre de Commerce
- `patente` (text) — Patente
- `cnss` (text) — CNSS
*/

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'ice') THEN
    ALTER TABLE customers ADD COLUMN ice text DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'nif') THEN
    ALTER TABLE customers ADD COLUMN nif text DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'rc') THEN
    ALTER TABLE customers ADD COLUMN rc text DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'patente') THEN
    ALTER TABLE customers ADD COLUMN patente text DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'cnss') THEN
    ALTER TABLE customers ADD COLUMN cnss text DEFAULT '';
  END IF;
END $$;

/*
# Simplifier les identifiants fiscaux : RC, NIF, AI uniquement

## Description
1. Ajoute la colonne `ai` (Article d'Imposition) à la table customers
2. Supprime les colonnes `patente` et `cnss` de app_settings (non utilisés)
3. Ajoute la colonne `ai` à app_settings
*/

-- ===== Ajouter AI aux clients =====
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'ai') THEN
    ALTER TABLE customers ADD COLUMN ai text DEFAULT '';
  END IF;
END $$;

-- ===== Nettoyer app_settings : ajouter AI, supprimer patente et cnss =====
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_settings' AND column_name = 'ai') THEN
    ALTER TABLE app_settings ADD COLUMN ai text NOT NULL DEFAULT '';
  END IF;
END $$;

-- Supprimer patente et cnss de app_settings
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_settings' AND column_name = 'patente') THEN
    ALTER TABLE app_settings DROP COLUMN patente;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_settings' AND column_name = 'cnss') THEN
    ALTER TABLE app_settings DROP COLUMN cnss;
  END IF;
END $$;

-- ===== Nettoyer customers : supprimer patente et cnss =====
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'patente') THEN
    ALTER TABLE customers DROP COLUMN patente;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customers' AND column_name = 'cnss') THEN
    ALTER TABLE customers DROP COLUMN cnss;
  END IF;
END $$;

-- Add RC, NIF, AI fields to suppliers (customers already have them)
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS rc text DEFAULT '';
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS nif text DEFAULT '';
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS ai text DEFAULT '';

ALTER TABLE purchases
ADD COLUMN IF NOT EXISTS handling_fee numeric NOT NULL DEFAULT 0;

/*
# Création de la table des livraisons

## Description
Ajoute une table `deliveries` pour gérer les livraisons liées aux ventes.
Chaque livraison est associée à une vente, avec un moyen de livraison
(interne ou externe/transporteur), une immatriculation, des frais de transport,
une date de livraison prévue, un statut et des notes.

## Tables créées
- `deliveries` :
  - `id` (uuid, PK)
  - `sale_id` (uuid, FK vers sales)
  - `reference` (text, non null)
  - `method` (text: 'interne' ou 'externe')
  - `vehicle` (text: immatriculation du véhicule)
  - `transport_cost` (numeric: frais de transport, single field)
  - `delivery_date` (date: date de livraison prévue)
  - `status` (text: 'pending', 'in_transit', 'delivered', 'cancelled')
  - `notes` (text)
  - `created_at` (timestamptz)

## Sécurité
- RLS activée sur `deliveries`.
- Application mono-utilisateur : politiques `TO anon, authenticated` avec `USING (true)`.
*/

CREATE TABLE IF NOT EXISTS deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid REFERENCES sales(id) ON DELETE SET NULL,
  reference text NOT NULL,
  method text NOT NULL DEFAULT 'interne',
  vehicle text DEFAULT '',
  transport_cost numeric(12,2) NOT NULL DEFAULT 0,
  delivery_date date NOT NULL DEFAULT CURRENT_DATE,
  status text NOT NULL DEFAULT 'pending',
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_deliveries" ON deliveries;
CREATE POLICY "anon_select_deliveries" ON deliveries FOR SELECT
TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_deliveries" ON deliveries;
CREATE POLICY "anon_insert_deliveries" ON deliveries FOR INSERT
TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_deliveries" ON deliveries;
CREATE POLICY "anon_update_deliveries" ON deliveries FOR UPDATE
TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_deliveries" ON deliveries;
CREATE POLICY "anon_delete_deliveries" ON deliveries FOR DELETE
TO anon, authenticated USING (true);

/*
# Ajout logo et second téléphone dans app_settings

## Description
Ajoute deux colonnes à la table `app_settings` :
- `company_logo` (text) : URL publique du logo de l'entreprise (stocké dans Supabase Storage)
- `company_phone2` (text) : deuxième numéro de téléphone

## Tables modifiées
- `app_settings` : ajout de `company_logo` et `company_phone2`

## Sécurité
- Aucun changement de politique. Les politiques existantes sur `app_settings` restent inchangées.
*/

ALTER TABLE app_settings ADD COLUMN IF NOT EXISTS company_logo text DEFAULT '';
ALTER TABLE app_settings ADD COLUMN IF NOT EXISTS company_phone2 text DEFAULT '';

/*
# Création du bucket de stockage pour les logos

## Description
Crée un bucket public `logos` dans Supabase Storage pour stocker les logos d'entreprise téléversés depuis la page Paramètres.

## Sécurité
- Bucket public en lecture (les logos doivent être visibles dans les documents imprimés).
- Upload limité aux utilisateurs authentifiés.
*/

INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "anon_read_logos" ON storage.objects;
CREATE POLICY "anon_read_logos"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'logos');

DROP POLICY IF EXISTS "authenticated_upload_logos" ON storage.objects;
CREATE POLICY "authenticated_upload_logos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'logos');

DROP POLICY IF EXISTS "authenticated_update_logos" ON storage.objects;
CREATE POLICY "authenticated_update_logos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'logos') WITH CHECK (bucket_id = 'logos');

DROP POLICY IF EXISTS "authenticated_delete_logos" ON storage.objects;
CREATE POLICY "authenticated_delete_logos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'logos');

