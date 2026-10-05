BEGIN;

-- ============================================================
-- 1. TABLE DELIVERIES = TOURNÉE DE LIVRAISON
-- ============================================================

-- La livraison représente maintenant une tournée.
-- Une tournée peut contenir plusieurs bons de livraison.

ALTER TABLE deliveries
DROP CONSTRAINT IF EXISTS deliveries_sale_id_fkey;

ALTER TABLE deliveries
DROP COLUMN IF EXISTS sale_id;

ALTER TABLE deliveries
ADD COLUMN IF NOT EXISTS driver_name text NOT NULL DEFAULT '';

ALTER TABLE deliveries
ADD COLUMN IF NOT EXISTS driver_phone text NOT NULL DEFAULT '';


-- ============================================================
-- 2. TABLE DELIVERY_NOTES = BON DE LIVRAISON
-- ============================================================

-- Un BL appartient à une tournée
ALTER TABLE delivery_notes
ADD COLUMN IF NOT EXISTS delivery_id uuid;

-- Un BL correspond à une seule vente
ALTER TABLE delivery_notes
ADD COLUMN IF NOT EXISTS sale_id uuid;


-- ============================================================
-- 3. RELATION LIVRAISON -> BL
-- ============================================================

ALTER TABLE delivery_notes
DROP CONSTRAINT IF EXISTS delivery_notes_delivery_id_fkey;

ALTER TABLE delivery_notes
ADD CONSTRAINT delivery_notes_delivery_id_fkey
FOREIGN KEY (delivery_id)
REFERENCES deliveries(id)
ON DELETE CASCADE;


-- ============================================================
-- 4. RELATION BL -> VENTE
-- ============================================================

ALTER TABLE delivery_notes
DROP CONSTRAINT IF EXISTS delivery_notes_sale_id_fkey;

ALTER TABLE delivery_notes
ADD CONSTRAINT delivery_notes_sale_id_fkey
FOREIGN KEY (sale_id)
REFERENCES sales(id)
ON DELETE RESTRICT;


-- ============================================================
-- 5. UN SEUL BL PAR VENTE
-- ============================================================

CREATE UNIQUE INDEX IF NOT EXISTS uq_delivery_notes_sale_id
ON delivery_notes(sale_id)
WHERE sale_id IS NOT NULL;


-- ============================================================
-- 6. REFERENCES UNIQUES
-- ============================================================

CREATE UNIQUE INDEX IF NOT EXISTS uq_deliveries_reference
ON deliveries(reference);

CREATE UNIQUE INDEX IF NOT EXISTS uq_delivery_notes_reference
ON delivery_notes(reference);


-- ============================================================
-- 7. INDEX DES RELATIONS
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_delivery_notes_delivery_id
ON delivery_notes(delivery_id);

CREATE INDEX IF NOT EXISTS idx_delivery_notes_sale_id
ON delivery_notes(sale_id);

CREATE INDEX IF NOT EXISTS idx_delivery_notes_customer_id
ON delivery_notes(customer_id);

CREATE INDEX IF NOT EXISTS idx_deliveries_date
ON deliveries(delivery_date);

CREATE INDEX IF NOT EXISTS idx_deliveries_status
ON deliveries(status);


-- ============================================================
-- 8. RLS DELIVERIES
-- ============================================================

ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS anon_select_deliveries
ON deliveries;

DROP POLICY IF EXISTS anon_insert_deliveries
ON deliveries;

DROP POLICY IF EXISTS anon_update_deliveries
ON deliveries;

DROP POLICY IF EXISTS anon_delete_deliveries
ON deliveries;

DROP POLICY IF EXISTS authenticated_select_deliveries
ON deliveries;

DROP POLICY IF EXISTS authenticated_insert_deliveries
ON deliveries;

DROP POLICY IF EXISTS authenticated_update_deliveries
ON deliveries;

DROP POLICY IF EXISTS authenticated_delete_deliveries
ON deliveries;


CREATE POLICY authenticated_select_deliveries
ON deliveries
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY authenticated_insert_deliveries
ON deliveries
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY authenticated_update_deliveries
ON deliveries
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY authenticated_delete_deliveries
ON deliveries
FOR DELETE
TO authenticated
USING (true);


-- ============================================================
-- 9. RLS DELIVERY_NOTES
-- ============================================================

ALTER TABLE delivery_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS anon_select_delivery_notes
ON delivery_notes;

DROP POLICY IF EXISTS anon_insert_delivery_notes
ON delivery_notes;

DROP POLICY IF EXISTS anon_update_delivery_notes
ON delivery_notes;

DROP POLICY IF EXISTS anon_delete_delivery_notes
ON delivery_notes;

DROP POLICY IF EXISTS authenticated_select_delivery_notes
ON delivery_notes;

DROP POLICY IF EXISTS authenticated_insert_delivery_notes
ON delivery_notes;

DROP POLICY IF EXISTS authenticated_update_delivery_notes
ON delivery_notes;

DROP POLICY IF EXISTS authenticated_delete_delivery_notes
ON delivery_notes;


CREATE POLICY authenticated_select_delivery_notes
ON delivery_notes
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY authenticated_insert_delivery_notes
ON delivery_notes
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY authenticated_update_delivery_notes
ON delivery_notes
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY authenticated_delete_delivery_notes
ON delivery_notes
FOR DELETE
TO authenticated
USING (true);


-- ============================================================
-- 10. RLS DELIVERY_NOTE_ITEMS
-- ============================================================

ALTER TABLE delivery_note_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS anon_select_delivery_note_items
ON delivery_note_items;

DROP POLICY IF EXISTS anon_insert_delivery_note_items
ON delivery_note_items;

DROP POLICY IF EXISTS anon_update_delivery_note_items
ON delivery_note_items;

DROP POLICY IF EXISTS anon_delete_delivery_note_items
ON delivery_note_items;

DROP POLICY IF EXISTS authenticated_select_delivery_note_items
ON delivery_note_items;

DROP POLICY IF EXISTS authenticated_insert_delivery_note_items
ON delivery_note_items;

DROP POLICY IF EXISTS authenticated_update_delivery_note_items
ON delivery_note_items;

DROP POLICY IF EXISTS authenticated_delete_delivery_note_items
ON delivery_note_items;


CREATE POLICY authenticated_select_delivery_note_items
ON delivery_note_items
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY authenticated_insert_delivery_note_items
ON delivery_note_items
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY authenticated_update_delivery_note_items
ON delivery_note_items
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY authenticated_delete_delivery_note_items
ON delivery_note_items
FOR DELETE
TO authenticated
USING (true);


COMMIT;