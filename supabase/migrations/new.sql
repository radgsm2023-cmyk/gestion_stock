BEGIN;

-- ============================================================
-- 1. LIVRAISONS / TOURNÉES
-- ============================================================

-- On conserve la table deliveries existante.
-- La colonne sale_id est conservée temporairement pour
-- éviter toute perte de données existantes.

ALTER TABLE deliveries
ADD COLUMN IF NOT EXISTS driver_name text DEFAULT '';

ALTER TABLE deliveries
ADD COLUMN IF NOT EXISTS driver_phone text DEFAULT '';

-- Méthode de livraison :
-- interne = personnel de l'entreprise
-- externe = livreur externe

-- ============================================================
-- 2. BON DE LIVRAISON
-- ============================================================

-- Une livraison/tournée peut contenir plusieurs BL.
ALTER TABLE delivery_notes
ADD COLUMN IF NOT EXISTS delivery_id uuid;

-- Chaque BL correspond à une vente.
ALTER TABLE delivery_notes
ADD COLUMN IF NOT EXISTS sale_id uuid;

-- ============================================================
-- 3. CONTRAINTES FOREIGN KEY
-- ============================================================

DO $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'delivery_notes_delivery_id_fkey'
    ) THEN

        ALTER TABLE delivery_notes
        ADD CONSTRAINT delivery_notes_delivery_id_fkey
        FOREIGN KEY (delivery_id)
        REFERENCES deliveries(id)
        ON DELETE SET NULL;

    END IF;

END $$;


DO $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'delivery_notes_sale_id_fkey'
    ) THEN

        ALTER TABLE delivery_notes
        ADD CONSTRAINT delivery_notes_sale_id_fkey
        FOREIGN KEY (sale_id)
        REFERENCES sales(id)
        ON DELETE SET NULL;

    END IF;

END $$;


-- ============================================================
-- 4. INDEX
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_deliveries_date
ON deliveries(delivery_date);

CREATE INDEX IF NOT EXISTS idx_deliveries_status
ON deliveries(status);

CREATE INDEX IF NOT EXISTS idx_delivery_notes_delivery_id
ON delivery_notes(delivery_id);

CREATE INDEX IF NOT EXISTS idx_delivery_notes_sale_id
ON delivery_notes(sale_id);

CREATE INDEX IF NOT EXISTS idx_delivery_notes_customer_id
ON delivery_notes(customer_id);


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
-- 7. RLS
-- ============================================================

ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_note_items ENABLE ROW LEVEL SECURITY;


-- Suppression des anciennes policies deliveries
DROP POLICY IF EXISTS anon_select_deliveries ON deliveries;
DROP POLICY IF EXISTS anon_insert_deliveries ON deliveries;
DROP POLICY IF EXISTS anon_update_deliveries ON deliveries;
DROP POLICY IF EXISTS anon_delete_deliveries ON deliveries;

DROP POLICY IF EXISTS authenticated_select_deliveries ON deliveries;
DROP POLICY IF EXISTS authenticated_insert_deliveries ON deliveries;
DROP POLICY IF EXISTS authenticated_update_deliveries ON deliveries;
DROP POLICY IF EXISTS authenticated_delete_deliveries ON deliveries;


-- ============================================================
-- 8. POLICIES DELIVERIES
-- ============================================================

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
-- 9. POLICIES DELIVERY NOTES
-- ============================================================

DROP POLICY IF EXISTS anon_select_delivery_notes ON delivery_notes;
DROP POLICY IF EXISTS anon_insert_delivery_notes ON delivery_notes;
DROP POLICY IF EXISTS anon_update_delivery_notes ON delivery_notes;
DROP POLICY IF EXISTS anon_delete_delivery_notes ON delivery_notes;

DROP POLICY IF EXISTS authenticated_select_delivery_notes ON delivery_notes;
DROP POLICY IF EXISTS authenticated_insert_delivery_notes ON delivery_notes;
DROP POLICY IF EXISTS authenticated_update_delivery_notes ON delivery_notes;
DROP POLICY IF EXISTS authenticated_delete_delivery_notes ON delivery_notes;


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
-- 10. POLICIES DELIVERY NOTE ITEMS
-- ============================================================

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