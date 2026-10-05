import { useEffect, useMemo, useState } from 'react';
import {
  Plus,
  Truck,
  Eye,
  Search,
  Filter,
  Package,
  X,
  User,
  Phone,
  Car,
  FileText,
} from 'lucide-react';

import { supabase } from '@/lib/supabase';

import {
  formatCurrency,
  formatDate,
  generateLIVRef,
  getNextSeq,
} from '@/lib/utils';

import type {
  Sale,
  Customer,
  Delivery,
  DeliveryNote,
} from '@/types';

import {
  Card,
  Button,
  Input,
  Select,
  Textarea,
  Badge,
  EmptyState,
} from '@/components/ui';

import Modal from '@/components/Modal';
import Loading from '@/components/Loading';

const deliveryStatusMap: Record<string, string> = {
  pending: 'warning',
  in_transit: 'info',
  delivered: 'success',
  cancelled: 'error',
};

const deliveryStatusLabel: Record<string, string> = {
  pending: 'En attente',
  in_transit: 'En cours',
  delivered: 'Livré',
  cancelled: 'Annulé',
};

type DeliveryForm = {
  reference: string;
  method: 'interne' | 'externe';
  vehicle: string;
  driver_name: string;
  driver_phone: string;
  transport_cost: string;
  delivery_date: string;
  status: string;
  notes: string;
};

/**
 * Retourne la date locale au format YYYY-MM-DD.
 *
 * On évite toISOString() afin d'éviter les problèmes
 * de changement de date liés à UTC.
 */
function getLocalDateString(date = new Date()): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

export default function Deliveries() {
  const [deliveries, setDeliveries] = useState<Delivery[]>([]);
  const [sales, setSales] = useState<Sale[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);

  /**
   * Tous les BL existants.
   *
   * IMPORTANT :
   * Les BL sont maintenant créés depuis Sales.tsx.
   * Deliveries.tsx se contente de les affecter à une tournée.
   */
  const [deliveryNotes, setDeliveryNotes] = useState<
    DeliveryNote[]
  >([]);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [modalOpen, setModalOpen] = useState(false);

  const [detailDelivery, setDetailDelivery] =
    useState<Delivery | null>(null);

  const [filterMethod, setFilterMethod] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [filterDateFrom, setFilterDateFrom] = useState('');
  const [filterDateTo, setFilterDateTo] = useState('');
  const [search, setSearch] = useState('');

  /**
   * Numéro séquentiel réservé pour la LIV en cours de création.
   *
   * Exemple :
   *
   * LIV-015-08102026
   *
   * Si la date passe au 10/10/2026 :
   *
   * LIV-015-10102026
   *
   * Le numéro 015 reste identique.
   */
  const [deliverySeq, setDeliverySeq] =
    useState<number | null>(null);

  /**
   * Ventes / BL sélectionnés pour la tournée.
   */
  const [selectedSaleIds, setSelectedSaleIds] =
    useState<string[]>([]);

  const [form, setForm] = useState<DeliveryForm>({
    reference: '',
    method: 'interne',
    vehicle: '',
    driver_name: '',
    driver_phone: '',
    transport_cost: '0',
    delivery_date: getLocalDateString(),
    status: 'pending',
    notes: '',
  });

  useEffect(() => {
    load();
  }, []);

  /* ============================================================
     CHARGEMENT
     ============================================================ */

  async function load(): Promise<Delivery[] | undefined> {
    setLoading(true);

    try {
      const [
        deliveriesRes,
        notesRes,
        salesRes,
        customersRes,
      ] = await Promise.all([
        supabase
          .from('deliveries')
          .select('*')
          .order('created_at', {
            ascending: false,
          }),

        /**
         * Tous les BL.
         *
         * Certains peuvent avoir :
         *
         * delivery_id = null
         *
         * car ils existent déjà mais ne sont pas encore
         * affectés à une tournée.
         */
        supabase
          .from('delivery_notes')
          .select('*')
          .order('created_at', {
            ascending: true,
          }),

        supabase
          .from('sales')
          .select('*')
          .order('created_at', {
            ascending: false,
          }),

        supabase
          .from('customers')
          .select('*')
          .order('name'),
      ]);

      if (deliveriesRes.error) {
        console.error(
          'Erreur chargement livraisons:',
          deliveriesRes.error
        );
      }

      if (notesRes.error) {
        console.error(
          'Erreur chargement BL:',
          notesRes.error
        );
      }

      if (salesRes.error) {
        console.error(
          'Erreur chargement ventes:',
          salesRes.error
        );
      }

      if (customersRes.error) {
        console.error(
          'Erreur chargement clients:',
          customersRes.error
        );
      }

      const deliveryRows =
        deliveriesRes.data || [];

      const noteRows =
        notesRes.data || [];

      const saleRows =
        salesRes.data || [];

      const customerRows =
        customersRes.data || [];

      /* --------------------------------------------------------
         CLIENTS
         -------------------------------------------------------- */

      const customerMap =
        new Map<string, Customer>();

      customerRows.forEach(
        (customer: Customer) => {
          customerMap.set(
            customer.id,
            customer
          );
        }
      );

      /* --------------------------------------------------------
         VENTES
         -------------------------------------------------------- */

      const saleList: Sale[] =
        saleRows.map((sale: any) => ({
          ...sale,
          customer: sale.customer_id
            ? customerMap.get(
                sale.customer_id
              ) || null
            : null,
        }));

      const saleMap =
        new Map<string, Sale>();

      saleList.forEach((sale) => {
        saleMap.set(
          sale.id,
          sale
        );
      });

      /* --------------------------------------------------------
         BL
         -------------------------------------------------------- */

      const notes: DeliveryNote[] =
        noteRows.map((note: any) => ({
          ...note,

          customer: note.customer_id
            ? customerMap.get(
                note.customer_id
              ) || null
            : null,

          sale: note.sale_id
            ? saleMap.get(
                note.sale_id
              ) || null
            : null,
        }));

      /* --------------------------------------------------------
         BL PAR LIVRAISON
         -------------------------------------------------------- */

      const notesByDelivery =
        new Map<
          string,
          DeliveryNote[]
        >();

      notes.forEach((note) => {
        if (!note.delivery_id) {
          return;
        }

        const existing =
          notesByDelivery.get(
            note.delivery_id
          ) || [];

        existing.push(note);

        notesByDelivery.set(
          note.delivery_id,
          existing
        );
      });

      /* --------------------------------------------------------
         LIVRAISONS ENRICHIES
         -------------------------------------------------------- */

      const enrichedDeliveries: Delivery[] =
        deliveryRows.map(
          (delivery: any) => ({
            ...delivery,

            delivery_notes:
              notesByDelivery.get(
                delivery.id
              ) || [],
          })
        );

      setDeliveries(
        enrichedDeliveries
      );

      setSales(saleList);

      setCustomers(
        customerRows
      );

      /**
       * IMPORTANT :
       * On conserve tous les BL, y compris ceux qui
       * ne sont pas encore affectés à une livraison.
       */
      setDeliveryNotes(notes);

      return enrichedDeliveries;
    } finally {
      setLoading(false);
    }
  }

  /* ============================================================
     BL DISPONIBLES
     ============================================================ */

  /**
   * Retourne le BL actif d'une vente.
   *
   * Une vente doit avoir son BL créé depuis Sales.tsx
   * avant de pouvoir être programmée.
   */
  function getActiveBLForSale(
    saleId: string
  ): DeliveryNote | null {
    return (
      deliveryNotes.find(
        (note) =>
          note.sale_id === saleId &&
          note.status !== 'cancelled'
      ) || null
    );
  }

  /**
   * Ventes déjà affectées à une tournée active.
   */
  const assignedSaleIds = useMemo(() => {
    const ids =
      new Set<string>();

    deliveryNotes.forEach(
      (note) => {
        if (
          !note.sale_id ||
          !note.delivery_id
        ) {
          return;
        }

        if (
          note.status ===
          'cancelled'
        ) {
          return;
        }

        ids.add(note.sale_id);
      }
    );

    return ids;
  }, [deliveryNotes]);

  /**
   * Ventes disponibles.
   *
   * Conditions :
   *
   * 1. La vente possède un BL.
   * 2. Le BL n'est pas annulé.
   * 3. Le BL n'est pas déjà affecté à une LIV.
   */
  const availableSales =
    useMemo(() => {
      return sales.filter(
        (sale) => {
          if (
            assignedSaleIds.has(
              sale.id
            )
          ) {
            return false;
          }

          const note =
            getActiveBLForSale(
              sale.id
            );

          return !!note;
        }
      );
    }, [
      sales,
      deliveryNotes,
      assignedSaleIds,
    ]);

  /* ============================================================
     CRÉATION LIV
     ============================================================ */

  async function openAdd() {
    try {
      const deliveryDate =
        getLocalDateString();

      /**
       * On réserve le numéro de LIV une seule fois.
       */
      const seq =
        await getNextSeq(
          'deliveries'
        );

      setDeliverySeq(seq);

      setForm({
        reference:
          generateLIVRef(
            seq,
            deliveryDate
          ),

        method: 'interne',

        vehicle: '',

        driver_name: '',

        driver_phone: '',

        transport_cost: '0',

        delivery_date:
          deliveryDate,

        status: 'pending',

        notes: '',
      });

      setSelectedSaleIds([]);

      setModalOpen(true);
    } catch (error) {
      console.error(
        'Erreur génération référence livraison:',
        error
      );

      alert(
        'Impossible de générer la référence de la livraison.'
      );
    }
  }

  /**
   * Modification de la date prévue.
   *
   * Exemple :
   *
   * LIV-015-08102026
   *
   * devient :
   *
   * LIV-015-10102026
   */
  function handleDeliveryDateChange(
    value: string
  ) {
    setForm((current) => ({
      ...current,

      delivery_date:
        value,

      reference:
        deliverySeq !== null
          ? generateLIVRef(
              deliverySeq,
              value
            )
          : current.reference,
    }));
  }

  /* ============================================================
     SÉLECTION DES VENTES / BL
     ============================================================ */

  function toggleSale(
    saleId: string
  ) {
    /**
     * Sécurité supplémentaire :
     * on vérifie que le BL existe encore
     * et qu'il n'est pas déjà affecté.
     */
    const sale =
      sales.find(
        (item) =>
          item.id === saleId
      );

    if (!sale) {
      return;
    }

    const note =
      getActiveBLForSale(
        saleId
      );

    if (!note) {
      alert(
        'Cette vente ne possède pas de bon de livraison actif.'
      );
      return;
    }

    if (
      note.delivery_id
    ) {
      alert(
        'Ce bon de livraison est déjà affecté à une tournée.'
      );
      return;
    }

    setSelectedSaleIds(
      (current) => {
        if (
          current.includes(
            saleId
          )
        ) {
          return current.filter(
            (id) =>
              id !== saleId
          );
        }

        return [
          ...current,
          saleId,
        ];
      }
    );
  }

  function removeSale(
    saleId: string
  ) {
    setSelectedSaleIds(
      (current) =>
        current.filter(
          (id) =>
            id !== saleId
        )
    );
  }

  /* ============================================================
     CRÉATION DE LA TOURNÉE
     ============================================================ */

  async function handleSave() {
    if (
      !form.reference.trim()
    ) {
      alert(
        'La référence de la livraison est obligatoire.'
      );
      return;
    }

    if (
      selectedSaleIds.length ===
      0
    ) {
      alert(
        'Sélectionnez au moins une vente avec un bon de livraison.'
      );
      return;
    }

    if (
      !form.vehicle.trim()
    ) {
      alert(
        'Le véhicule est obligatoire.'
      );
      return;
    }

    if (
      !form.delivery_date
    ) {
      alert(
        'La date de livraison est obligatoire.'
      );
      return;
    }

    /**
     * ----------------------------------------------------------
     * VÉRIFICATION DES BL
     * ----------------------------------------------------------
     *
     * Aucun BL n'est créé ici.
     *
     * On vérifie uniquement que chaque vente possède
     * déjà son BL créé depuis Sales.tsx.
     */
    const selectedNotes =
      selectedSaleIds
        .map((saleId) =>
          getActiveBLForSale(
            saleId
          )
        )
        .filter(
          (
            note
          ): note is DeliveryNote =>
            !!note
        );

    if (
      selectedNotes.length !==
      selectedSaleIds.length
    ) {
      const missingSales =
        selectedSaleIds
          .filter(
            (saleId) =>
              !getActiveBLForSale(
                saleId
              )
          )
          .map(
            (saleId) => {
              const sale =
                sales.find(
                  (item) =>
                    item.id ===
                    saleId
                );

              return (
                sale?.reference ||
                saleId
              );
            }
          );

      alert(
        `Les ventes suivantes ne possèdent pas de BL actif :\n\n${missingSales.join(
          '\n'
        )}\n\nCréez d'abord les BL depuis la section Ventes.`
      );

      return;
    }

    /**
     * Sécurité :
     * aucun BL ne doit déjà être affecté.
     */
    const alreadyAssigned =
      selectedNotes.filter(
        (note) =>
          !!note.delivery_id
      );

    if (
      alreadyAssigned.length >
      0
    ) {
      alert(
        'Un ou plusieurs BL sélectionnés sont déjà affectés à une autre tournée. Actualisez la page et recommencez.'
      );

      await load();

      return;
    }

    setSaving(true);

    let createdDeliveryId:
      | string
      | null = null;

    try {
      /* --------------------------------------------------------
         1. CRÉATION DE LA TOURNÉE LIV
         -------------------------------------------------------- */

      const {
        data: delivery,
        error: deliveryError,
      } = await supabase
        .from('deliveries')
        .insert({
          reference:
            form.reference.trim(),

          method:
            form.method,

          vehicle:
            form.vehicle.trim(),

          driver_name:
            form.driver_name.trim(),

          driver_phone:
            form.driver_phone.trim(),

          transport_cost:
            parseFloat(
              form.transport_cost
            ) || 0,

          delivery_date:
            form.delivery_date,

          status:
            form.status,

          notes:
            form.notes.trim(),
        })
        .select()
        .single();

      if (
        deliveryError ||
        !delivery
      ) {
        console.error(
          'Erreur création livraison:',
          deliveryError
        );

        alert(
          deliveryError?.message ||
            'Impossible de créer la livraison.'
        );

        return;
      }

      createdDeliveryId =
        delivery.id;

      /* --------------------------------------------------------
         2. AFFECTATION DES BL EXISTANTS
         -------------------------------------------------------- */

      /**
       * IMPORTANT :
       *
       * Aucun delivery_note n'est créé ici.
       *
       * On affecte simplement les BL existants
       * à la nouvelle tournée.
       *
       * delivery_id :
       *
       * avant :
       * NULL
       *
       * après :
       * ID de la LIV
       *
       * delivery_date :
       * devient la date prévue de la tournée.
       *
       * La référence du BL ne change PAS.
       */
      const {
        error: assignError,
      } = await supabase
        .from('delivery_notes')
        .update({
          delivery_id:
            delivery.id,

          delivery_date:
            form.delivery_date,
        })
        .in(
          'id',
          selectedNotes.map(
            (note) =>
              note.id
          )
        );

      if (assignError) {
        console.error(
          'Erreur affectation BL:',
          assignError
        );

        /**
         * Rollback de la LIV.
         */
        await supabase
          .from('deliveries')
          .delete()
          .eq(
            'id',
            delivery.id
          );

        alert(
          assignError.message ||
            'Impossible d’affecter les bons de livraison à cette tournée.'
        );

        return;
      }

      /* --------------------------------------------------------
         3. SUCCÈS
         -------------------------------------------------------- */

      setModalOpen(false);

      setSelectedSaleIds(
        []
      );

      setDeliverySeq(
        null
      );

      await load();
    } catch (error) {
      console.error(
        'Erreur inattendue création livraison:',
        error
      );

      /**
       * Rollback si la LIV a été créée
       * mais qu'une erreur inattendue est survenue.
       */
      if (
        createdDeliveryId
      ) {
        await supabase
          .from('deliveries')
          .delete()
          .eq(
            'id',
            createdDeliveryId
          );
      }

      alert(
        'Une erreur est survenue lors de la création de la livraison.'
      );
    } finally {
      setSaving(false);
    }
  }

  /* ============================================================
     STATUT
     ============================================================ */

  async function updateStatus(
    delivery: Delivery,
    newStatus: string
  ) {
    const {
      error,
    } = await supabase
      .from('deliveries')
      .update({
        status:
          newStatus,
      })
      .eq(
        'id',
        delivery.id
      );

    if (error) {
      console.error(
        'Erreur mise à jour statut:',
        error
      );

      alert(
        'Impossible de modifier le statut de la livraison.'
      );

      return;
    }

    /**
     * Quand toute la tournée est livrée,
     * les BL passent également à delivered.
     */
    if (
      newStatus ===
      'delivered'
    ) {
      const {
        error:
          notesError,
      } = await supabase
        .from('delivery_notes')
        .update({
          status:
            'delivered',
        })
        .eq(
          'delivery_id',
          delivery.id
        );

      if (notesError) {
        console.error(
          'Erreur mise à jour statut BL:',
          notesError
        );
      }
    }

    /**
     * Si la tournée est annulée,
     * les BL sont annulés.
     */
    if (
      newStatus ===
      'cancelled'
    ) {
      const {
        error:
          notesError,
      } = await supabase
        .from('delivery_notes')
        .update({
          status:
            'cancelled',
        })
        .eq(
          'delivery_id',
          delivery.id
        );

      if (notesError) {
        console.error(
          'Erreur annulation BL:',
          notesError
        );
      }
    }

    /**
     * Rechargement complet.
     */
    const refreshed =
      await load();

    if (
      detailDelivery?.id ===
      delivery.id
    ) {
      const refreshedDelivery =
        refreshed?.find(
          (item) =>
            item.id ===
            delivery.id
        );

      if (
        refreshedDelivery
      ) {
        setDetailDelivery(
          refreshedDelivery
        );
      } else {
        setDetailDelivery(
          null
        );
      }
    }
  }

  /* ============================================================
     DÉTAIL
     ============================================================ */

  function openDetail(
    delivery: Delivery
  ) {
    setDetailDelivery(
      delivery
    );
  }

  /* ============================================================
     FILTRES
     ============================================================ */

  const filteredDeliveries =
    deliveries.filter(
      (delivery) => {
        if (
          filterMethod &&
          delivery.method !==
            filterMethod
        ) {
          return false;
        }

        if (
          filterStatus &&
          delivery.status !==
            filterStatus
        ) {
          return false;
        }

        if (
          filterDateFrom &&
          delivery.delivery_date <
            filterDateFrom
        ) {
          return false;
        }

        if (
          filterDateTo &&
          delivery.delivery_date >
            filterDateTo
        ) {
          return false;
        }

        if (search) {
          const q =
            search.toLowerCase();

          const matchReference =
            delivery.reference
              ?.toLowerCase()
              .includes(q);

          const matchVehicle =
            delivery.vehicle
              ?.toLowerCase()
              .includes(q);

          const matchDriver =
            delivery.driver_name
              ?.toLowerCase()
              .includes(q);

          const matchPhone =
            delivery.driver_phone
              ?.toLowerCase()
              .includes(q);

          const matchBL =
            delivery.delivery_notes?.some(
              (note) =>
                note.reference
                  ?.toLowerCase()
                  .includes(q)
            );

          const matchSale =
            delivery.delivery_notes?.some(
              (note) =>
                note.sale?.reference
                  ?.toLowerCase()
                  .includes(q)
            );

          const matchCustomer =
            delivery.delivery_notes?.some(
              (note) =>
                note.customer?.name
                  ?.toLowerCase()
                  .includes(q) ||
                note.sale?.customer?.name
                  ?.toLowerCase()
                  .includes(q) ||
                note.sale?.customer_name
                  ?.toLowerCase()
                  .includes(q)
            );

          if (
            !matchReference &&
            !matchVehicle &&
            !matchDriver &&
            !matchPhone &&
            !matchBL &&
            !matchSale &&
            !matchCustomer
          ) {
            return false;
          }
        }

        return true;
      }
    );

  /* ============================================================
     LOADING
     ============================================================ */

  if (loading) {
    return <Loading />;
  }

  /* ============================================================
     RENDER
     ============================================================ */

  return (
    <div className="space-y-6 animate-fade-in-up">

      {/* ======================================================
          EN-TÊTE
          ====================================================== */}

      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">
            Livraisons
          </h1>

          <p className="text-sm text-slate-500 mt-1">
            {filteredDeliveries.length}{' '}
            tournée(s)
          </p>
        </div>

        <Button
          onClick={openAdd}
        >
          <Plus className="w-4 h-4" />
          Programmer une livraison
        </Button>
      </div>

      {/* ======================================================
          FILTRES
          ====================================================== */}

      <div className="flex flex-col sm:flex-row gap-3 flex-wrap">

        <div className="flex items-center gap-2 flex-1 min-w-[220px]">
          <Search className="w-4 h-4 text-slate-400 shrink-0" />

          <input
            type="text"
            placeholder="Rechercher LIV, BL, vente, client, chauffeur..."
            value={search}
            onChange={(e) =>
              setSearch(
                e.target.value
              )
            }
            className="w-full px-3 py-2.5 rounded-lg border border-slate-300 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        <div className="flex items-center gap-2">
          <Filter className="w-4 h-4 text-slate-400 shrink-0" />

          <select
            value={filterMethod}
            onChange={(e) =>
              setFilterMethod(
                e.target.value
              )
            }
            className="px-3 py-2.5 rounded-lg border border-slate-300 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
          >
            <option value="">
              Tous les moyens
            </option>

            <option value="interne">
              Personnel
            </option>

            <option value="externe">
              Livreur externe
            </option>
          </select>
        </div>

        <div className="flex items-center gap-2">
          <select
            value={filterStatus}
            onChange={(e) =>
              setFilterStatus(
                e.target.value
              )
            }
            className="px-3 py-2.5 rounded-lg border border-slate-300 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
          >
            <option value="">
              Tous les statuts
            </option>

            <option value="pending">
              En attente
            </option>

            <option value="in_transit">
              En cours
            </option>

            <option value="delivered">
              Livré
            </option>

            <option value="cancelled">
              Annulé
            </option>
          </select>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-sm text-slate-400 shrink-0">
            Du
          </span>

          <input
            type="date"
            value={filterDateFrom}
            onChange={(e) =>
              setFilterDateFrom(
                e.target.value
              )
            }
            className="px-3 py-2.5 rounded-lg border border-slate-300 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        <div className="flex items-center gap-2">
          <span className="text-sm text-slate-400 shrink-0">
            Au
          </span>

          <input
            type="date"
            value={filterDateTo}
            onChange={(e) =>
              setFilterDateTo(
                e.target.value
              )
            }
            className="px-3 py-2.5 rounded-lg border border-slate-300 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        {(
          filterMethod ||
          filterStatus ||
          filterDateFrom ||
          filterDateTo ||
          search
        ) && (
          <button
            onClick={() => {
              setFilterMethod('');
              setFilterStatus('');
              setFilterDateFrom('');
              setFilterDateTo('');
              setSearch('');
            }}
            className="px-3 py-2.5 rounded-lg text-sm text-slate-500 hover:text-slate-700 hover:bg-slate-100 transition-colors"
          >
            Réinitialiser
          </button>
        )}
      </div>

      {/* ======================================================
          LISTE DES LIVRAISONS
          ====================================================== */}

      {filteredDeliveries.length ===
      0 ? (
        <Card>
          <EmptyState
            icon={Truck}
            title="Aucune livraison"
            description="Programmez une tournée à partir de vos bons de livraison."
            action={
              <Button
                onClick={
                  openAdd
                }
              >
                <Plus className="w-4 h-4" />
                Programmer une livraison
              </Button>
            }
          />
        </Card>
      ) : (
        <Card className="overflow-hidden">

          <div className="overflow-x-auto">

            <table className="w-full text-sm">

              <thead className="bg-slate-50 border-b border-slate-200">

                <tr>

                  <th className="text-left font-semibold text-slate-600 px-4 py-3">
                    Livraison
                  </th>

                  <th className="text-center font-semibold text-slate-600 px-4 py-3">
                    BL
                  </th>

                  <th className="text-left font-semibold text-slate-600 px-4 py-3 hidden md:table-cell">
                    Chauffeur
                  </th>

                  <th className="text-left font-semibold text-slate-600 px-4 py-3">
                    Moyen
                  </th>

                  <th className="text-left font-semibold text-slate-600 px-4 py-3 hidden lg:table-cell">
                    Véhicule
                  </th>

                  <th className="text-right font-semibold text-slate-600 px-4 py-3 hidden lg:table-cell">
                    Frais livraison
                  </th>

                  <th className="text-left font-semibold text-slate-600 px-4 py-3 hidden md:table-cell">
                    Date
                  </th>

                  <th className="text-center font-semibold text-slate-600 px-4 py-3">
                    Statut
                  </th>

                  <th className="text-right font-semibold text-slate-600 px-4 py-3">
                    Actions
                  </th>

                </tr>

              </thead>

              <tbody className="divide-y divide-slate-100">

                {filteredDeliveries.map(
                  (delivery) => {
                    const notes =
                      delivery.delivery_notes ||
                      [];

                    return (
                      <tr
                        key={
                          delivery.id
                        }
                        className="hover:bg-slate-50 transition-colors"
                      >

                        <td className="px-4 py-3">

                          <div className="font-semibold text-slate-800">
                            {
                              delivery.reference
                            }
                          </div>

                          <div className="text-xs text-slate-400 mt-0.5">
                            {formatDate(
                              delivery.delivery_date
                            )}
                          </div>

                        </td>

                        <td className="px-4 py-3 text-center">

                          <span className="inline-flex items-center justify-center min-w-8 px-2 py-1 rounded-full bg-blue-50 text-blue-700 font-semibold">
                            {
                              notes.length
                            }
                          </span>

                        </td>

                        <td className="px-4 py-3 hidden md:table-cell">

                          <div className="text-slate-700">
                            {
                              delivery.driver_name ||
                              '—'
                            }
                          </div>

                          {delivery.driver_phone && (
                            <div className="text-xs text-slate-400">
                              {
                                delivery.driver_phone
                              }
                            </div>
                          )}

                        </td>

                        <td className="px-4 py-3 text-slate-600">

                          <span className="inline-flex items-center gap-1.5">

                            <Truck className="w-3.5 h-3.5 text-slate-400" />

                            {delivery.method ===
                            'interne'
                              ? 'Personnel'
                              : 'Externe'}

                          </span>

                        </td>

                        <td className="px-4 py-3 hidden lg:table-cell text-slate-600">
                          {
                            delivery.vehicle ||
                            '—'
                          }
                        </td>

                        <td className="px-4 py-3 text-right hidden lg:table-cell text-slate-600">

                          {delivery.transport_cost >
                          0
                            ? formatCurrency(
                                delivery.transport_cost
                              )
                            : '—'}

                        </td>

                        <td className="px-4 py-3 hidden md:table-cell text-slate-600">
                          {formatDate(
                            delivery.delivery_date
                          )}
                        </td>

                        <td className="px-4 py-3 text-center">

                          <Badge
                            status={
                              delivery.status
                            }
                            variant={
                              deliveryStatusMap[
                                delivery.status
                              ] ||
                              'default'
                            }
                          />

                        </td>

                        <td className="px-4 py-3">

                          <div className="flex items-center justify-end gap-1">

                            <button
                              onClick={() =>
                                openDetail(
                                  delivery
                                )
                              }
                              className="p-2 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                              title="Détails"
                            >
                              <Eye className="w-4 h-4" />
                            </button>

                            {delivery.status ===
                              'pending' && (
                              <button
                                onClick={() =>
                                  updateStatus(
                                    delivery,
                                    'in_transit'
                                  )
                                }
                                className="px-2.5 py-1.5 text-xs font-medium text-blue-700 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors"
                              >
                                Démarrer
                              </button>
                            )}

                            {delivery.status ===
                              'in_transit' && (
                              <button
                                onClick={() =>
                                  updateStatus(
                                    delivery,
                                    'delivered'
                                  )
                                }
                                className="px-2.5 py-1.5 text-xs font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg transition-colors"
                              >
                                Livrer
                              </button>
                            )}

                            {(
                              delivery.status ===
                                'pending' ||
                              delivery.status ===
                                'in_transit'
                            ) && (
                              <button
                                onClick={() =>
                                  updateStatus(
                                    delivery,
                                    'cancelled'
                                  )
                                }
                                className="px-2.5 py-1.5 text-xs font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-lg transition-colors"
                              >
                                Annuler
                              </button>
                            )}

                          </div>

                        </td>

                      </tr>
                    );
                  }
                )}

              </tbody>

            </table>

          </div>

        </Card>
      )}

      {/* ======================================================
          MODAL NOUVELLE LIVRAISON
          ====================================================== */}

      <Modal
        open={modalOpen}
        onClose={() => {
          setModalOpen(false);
          setDeliverySeq(null);
          setSelectedSaleIds([]);
        }}
        title="Programmer une livraison"
        size="lg"
      >

        <div className="space-y-5">

          {/* Référence / Date */}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">

            <Input
              label="Référence livraison"
              value={
                form.reference
              }
              onChange={() => {}}
              required
              disabled
            />

            <Input
              label="Date de livraison prévue"
              type="date"
              value={
                form.delivery_date
              }
              onChange={
                handleDeliveryDateChange
              }
              required
            />

          </div>

          {/* Information référence */}

          <div className="rounded-lg border border-blue-200 bg-blue-50 p-3 text-sm text-blue-800">

            <div className="font-medium">
              Référence automatique
            </div>

            <div className="mt-1">
              La référence de la
              tournée utilise la
              date prévue de
              livraison.
            </div>

            <div className="font-semibold mt-1">
              {
                form.reference
              }
            </div>

          </div>

          {/* Moyen */}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">

            <Select
              label="Moyen de livraison"
              value={
                form.method
              }
              onChange={(
                value
              ) =>
                setForm({
                  ...form,
                  method:
                    value as
                      | 'interne'
                      | 'externe',
                })
              }
              options={[
                {
                  value:
                    'interne',
                  label:
                    'Personnel de l’entreprise',
                },
                {
                  value:
                    'externe',
                  label:
                    'Livreur externe',
                },
              ]}
              required
            />

            <Input
              label="Véhicule / Immatriculation"
              value={
                form.vehicle
              }
              onChange={(
                value
              ) =>
                setForm({
                  ...form,
                  vehicle:
                    value,
                })
              }
              placeholder="Ex : 123456-16-00"
              required
            />

          </div>

          {/* Chauffeur */}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">

            <Input
              label={
                form.method ===
                'interne'
                  ? 'Nom du chauffeur'
                  : 'Nom du livreur'
              }
              value={
                form.driver_name
              }
              onChange={(
                value
              ) =>
                setForm({
                  ...form,
                  driver_name:
                    value,
                })
              }
              placeholder="Nom et prénom"
            />

            <Input
              label="Téléphone"
              value={
                form.driver_phone
              }
              onChange={(
                value
              ) =>
                setForm({
                  ...form,
                  driver_phone:
                    value,
                })
              }
              placeholder="05 XX XX XX XX"
            />

          </div>

          {/* Frais */}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">

            <Input
              label="Frais de livraison"
              type="number"
              step="0.01"
              min="0"
              value={
                form.transport_cost
              }
              onChange={(
                value
              ) =>
                setForm({
                  ...form,
                  transport_cost:
                    value,
                })
              }
              required
            />

            <Select
              label="Statut"
              value={
                form.status
              }
              onChange={(
                value
              ) =>
                setForm({
                  ...form,
                  status:
                    value,
                })
              }
              options={[
                {
                  value:
                    'pending',
                  label:
                    'En attente',
                },
                {
                  value:
                    'in_transit',
                  label:
                    'En cours',
                },
                {
                  value:
                    'delivered',
                  label:
                    'Livré',
                },
                {
                  value:
                    'cancelled',
                  label:
                    'Annulé',
                },
              ]}
              required
            />

          </div>

          {/* Information frais */}

          <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">

            Les frais de livraison
            sont à la charge de
            l’entreprise et sont
            enregistrés une seule
            fois pour toute la
            tournée.

          </div>

          {/* ==================================================
              BL EXISTANTS
              ================================================== */}

          <div className="border border-slate-200 rounded-xl overflow-hidden">

            <div className="bg-slate-50 border-b border-slate-200 px-4 py-3">

              <div className="flex items-center justify-between">

                <div>
                  <h3 className="font-semibold text-slate-800">
                    Bons de livraison à programmer
                  </h3>

                  <p className="text-xs text-slate-500 mt-0.5">
                    Sélectionnez plusieurs BL
                    existants. Aucun BL ne sera créé
                    ici.
                  </p>
                </div>

                <span className="px-2.5 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-semibold">
                  {
                    selectedSaleIds.length
                  }{' '}
                  sélectionné(s)
                </span>

              </div>

            </div>

            <div className="max-h-72 overflow-y-auto">

              {availableSales.length ===
              0 ? (

                <div className="p-6 text-center">

                  <Package className="w-8 h-8 mx-auto text-slate-300 mb-2" />

                  <p className="text-sm font-medium text-slate-600">
                    Aucun BL disponible
                  </p>

                  <p className="text-xs text-slate-400 mt-1">
                    Créez d'abord les bons de
                    livraison depuis la section
                    Ventes, puis revenez ici pour
                    programmer leur livraison.
                  </p>

                </div>

              ) : (

                <div className="divide-y divide-slate-100">

                  {availableSales.map(
                    (sale) => {
                      const selected =
                        selectedSaleIds.includes(
                          sale.id
                        );

                      const note =
                        getActiveBLForSale(
                          sale.id
                        );

                      if (!note) {
                        return null;
                      }

                      const customerName =
                        sale.customer?.name ||
                        sale.customer_name ||
                        'Client non renseigné';

                      return (
                        <button
                          type="button"
                          key={
                            sale.id
                          }
                          onClick={() =>
                            toggleSale(
                              sale.id
                            )
                          }
                          className={`w-full text-left px-4 py-3 transition-colors ${
                            selected
                              ? 'bg-blue-50'
                              : 'hover:bg-slate-50'
                          }`}
                        >

                          <div className="flex items-start gap-3">

                            <div
                              className={`mt-0.5 w-5 h-5 rounded border flex items-center justify-center shrink-0 ${
                                selected
                                  ? 'bg-blue-600 border-blue-600 text-white'
                                  : 'border-slate-300 bg-white'
                              }`}
                            >
                              {selected && (
                                <span className="text-xs font-bold">
                                  ✓
                                </span>
                              )}
                            </div>

                            <div className="flex-1 min-w-0">

                              <div className="flex items-center justify-between gap-3">

                                <div className="flex flex-wrap items-center gap-2">

                                  <span className="font-semibold text-slate-800">
                                    {
                                      note.reference
                                    }
                                  </span>

                                  <span className="text-xs text-slate-400">
                                    {
                                      sale.reference
                                    }
                                  </span>

                                </div>

                                <span className="font-semibold text-slate-700 whitespace-nowrap">
                                  {formatCurrency(
                                    sale.total_amount
                                  )}
                                </span>

                              </div>

                              <div className="flex flex-wrap gap-x-4 gap-y-1 mt-1 text-xs text-slate-500">

                                <span>
                                  Client :{' '}
                                  <strong className="text-slate-600">
                                    {
                                      customerName
                                    }
                                  </strong>
                                </span>

                                <span>
                                  Vente :{' '}
                                  {
                                    sale.reference
                                  }
                                </span>

                                <span>
                                  BL créé le :{' '}
                                  {note.created_at
                                    ? formatDate(
                                        note.created_at
                                      )
                                    : '—'}
                                </span>

                              </div>

                            </div>

                          </div>

                        </button>
                      );
                    }
                  )}

                </div>
              )}

            </div>

          </div>

          {/* ==================================================
              BL SÉLECTIONNÉS
              ================================================== */}

          {selectedSaleIds.length >
            0 && (

            <div className="space-y-2">

              <div className="flex items-center justify-between">

                <h3 className="text-sm font-semibold text-slate-700">
                  BL affectés à la tournée
                </h3>

                <span className="text-xs text-slate-400">
                  1 BL par vente
                </span>

              </div>

              <div className="space-y-2">

                {selectedSaleIds.map(
                  (
                    saleId,
                    index
                  ) => {
                    const sale =
                      sales.find(
                        (s) =>
                          s.id ===
                          saleId
                      );

                    const note =
                      getActiveBLForSale(
                        saleId
                      );

                    if (
                      !sale ||
                      !note
                    ) {
                      return null;
                    }

                    return (
                      <div
                        key={
                          sale.id
                        }
                        className="flex items-center gap-3 p-3 bg-slate-50 border border-slate-200 rounded-lg"
                      >

                        <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center font-semibold text-sm">
                          {
                            index +
                            1
                          }
                        </div>

                        <div className="flex-1">

                          <div className="flex flex-wrap items-center gap-2">

                            <span className="font-semibold text-blue-700">
                              {
                                note.reference
                              }
                            </span>

                            <span className="text-xs text-slate-400">
                              →
                            </span>

                            <span className="font-medium text-slate-700">
                              {
                                sale.reference
                              }
                            </span>

                            <span className="text-xs text-slate-400">
                              →
                            </span>

                            <span className="text-sm text-slate-600">
                              {
                                sale.customer?.name ||
                                sale.customer_name ||
                                'Client'
                              }
                            </span>

                          </div>

                          <div className="text-xs text-slate-400 mt-1">
                            BL existant · sera affecté
                            à la tournée{' '}
                            {
                              form.reference
                            }
                          </div>

                        </div>

                        <button
                          type="button"
                          onClick={() =>
                            removeSale(
                              sale.id
                            )
                          }
                          className="p-2 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50"
                          title="Retirer"
                        >
                          <X className="w-4 h-4" />
                        </button>

                      </div>
                    );
                  }
                )}

              </div>

            </div>
          )}

          {/* Notes */}

          <Textarea
            label="Notes"
            value={
              form.notes
            }
            onChange={(
              value
            ) =>
              setForm({
                ...form,
                notes: value,
              })
            }
            placeholder="Instructions de livraison..."
          />

          {/* Boutons */}

          <div className="flex gap-3 pt-2 border-t border-slate-200">

            <Button
              variant="secondary"
              onClick={() => {
                setModalOpen(
                  false
                );
                setDeliverySeq(
                  null
                );
                setSelectedSaleIds(
                  []
                );
              }}
              className="flex-1"
            >
              Annuler
            </Button>

            <Button
              onClick={
                handleSave
              }
              disabled={
                saving ||
                selectedSaleIds.length ===
                  0
              }
              className="flex-1"
            >
              {saving
                ? 'Création...'
                : `Créer la livraison${
                    selectedSaleIds.length >
                    0
                      ? ` (${selectedSaleIds.length} BL)`
                      : ''
                  }`}
            </Button>

          </div>

        </div>

      </Modal>

      {/* ======================================================
          MODAL DÉTAIL LIVRAISON
          ====================================================== */}

      <Modal
        open={
          !!detailDelivery
        }
        onClose={() =>
          setDetailDelivery(
            null
          )
        }
        title="Détails de la livraison"
        subtitle={
          detailDelivery?.reference
        }
        size="lg"
      >

        {detailDelivery && (

          <div className="space-y-5">

            {/* Informations tournée */}

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">

              <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">

                <div className="flex items-center gap-2 mb-2">
                  <Truck className="w-4 h-4 text-slate-400" />

                  <p className="text-xs text-slate-400">
                    Livraison
                  </p>
                </div>

                <p className="text-lg font-bold text-slate-800">
                  {
                    detailDelivery.reference
                  }
                </p>

                <p className="text-sm text-slate-500 mt-1">
                  Date prévue :{' '}
                  {formatDate(
                    detailDelivery.delivery_date
                  )}
                </p>

              </div>

              <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">

                <p className="text-xs text-slate-400 mb-2">
                  Statut
                </p>

                <Badge
                  status={
                    detailDelivery.status
                  }
                  variant={
                    deliveryStatusMap[
                      detailDelivery.status
                    ] ||
                    'default'
                  }
                />

                <p className="text-xs text-slate-400 mt-2">
                  {
                    deliveryStatusLabel[
                      detailDelivery.status
                    ]
                  }
                </p>

              </div>

            </div>

            {/* Transport */}

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">

              <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">

                <Truck className="w-4 h-4 text-slate-400 mb-2" />

                <p className="text-xs text-slate-400">
                  Moyen
                </p>

                <p className="text-sm font-semibold text-slate-700 mt-1">
                  {detailDelivery.method ===
                  'interne'
                    ? 'Personnel'
                    : 'Livreur externe'}
                </p>

              </div>

              <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">

                <Car className="w-4 h-4 text-slate-400 mb-2" />

                <p className="text-xs text-slate-400">
                  Véhicule
                </p>

                <p className="text-sm font-semibold text-slate-700 mt-1">
                  {
                    detailDelivery.vehicle ||
                    '—'
                  }
                </p>

              </div>

              <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">

                <User className="w-4 h-4 text-slate-400 mb-2" />

                <p className="text-xs text-slate-400">
                  Chauffeur / Livreur
                </p>

                <p className="text-sm font-semibold text-slate-700 mt-1">
                  {
                    detailDelivery.driver_name ||
                    '—'
                  }
                </p>

              </div>

              <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">

                <Phone className="w-4 h-4 text-slate-400 mb-2" />

                <p className="text-xs text-slate-400">
                  Téléphone
                </p>

                <p className="text-sm font-semibold text-slate-700 mt-1">
                  {
                    detailDelivery.driver_phone ||
                    '—'
                  }
                </p>

              </div>

            </div>

            {/* Frais */}

            <div className="bg-amber-50 border border-amber-200 rounded-lg p-4">

              <div className="flex items-center justify-between">

                <div>

                  <p className="text-xs text-amber-600">
                    Frais de livraison
                  </p>

                  <p className="text-lg font-bold text-amber-800 mt-1">
                    {formatCurrency(
                      detailDelivery.transport_cost
                    )}
                  </p>

                </div>

                <span className="text-xs font-medium text-amber-700 bg-amber-100 px-3 py-1.5 rounded-full">
                  À la charge de
                  l’entreprise
                </span>

              </div>

            </div>

            {/* =================================================
                BONS DE LIVRAISON
                ================================================= */}

            <div>

              <div className="flex items-center justify-between mb-3">

                <div>

                  <h3 className="font-semibold text-slate-800">
                    Bons de livraison
                  </h3>

                  <p className="text-xs text-slate-500 mt-1">
                    {
                      detailDelivery
                        .delivery_notes
                        ?.length ||
                      0
                    }{' '}
                    BL dans cette
                    tournée
                  </p>

                </div>

              </div>

              {!detailDelivery.delivery_notes ||
              detailDelivery
                .delivery_notes
                .length ===
                0 ? (

                <div className="border border-dashed border-slate-300 rounded-lg p-6 text-center">

                  <FileText className="w-8 h-8 mx-auto text-slate-300 mb-2" />

                  <p className="text-sm text-slate-500">
                    Aucun bon de livraison
                  </p>

                </div>

              ) : (

                <div className="space-y-2">

                  {detailDelivery.delivery_notes.map(
                    (
                      note
                    ) => {
                      const customerName =
                        note.customer
                          ?.name ||
                        note.sale
                          ?.customer
                          ?.name ||
                        note.sale
                          ?.customer_name ||
                        'Client';

                      return (
                        <div
                          key={
                            note.id
                          }
                          className="border border-slate-200 rounded-lg p-4 bg-white"
                        >

                          <div className="flex items-start justify-between gap-4">

                            <div className="flex items-start gap-3">

                              <div className="w-9 h-9 rounded-lg bg-blue-50 text-blue-700 flex items-center justify-center shrink-0">
                                <FileText className="w-4 h-4" />
                              </div>

                              <div>

                                <div className="flex flex-wrap items-center gap-2">

                                  <span className="font-semibold text-slate-800">
                                    {
                                      note.reference
                                    }
                                  </span>

                                  <span className="text-xs text-slate-400">
                                    {
                                      note.sale
                                        ?.reference ||
                                      'Vente'
                                    }
                                  </span>

                                </div>

                                <p className="text-sm text-slate-600 mt-1">
                                  {
                                    customerName
                                  }
                                </p>

                                <p className="text-xs text-slate-400 mt-1">
                                  Date prévue de livraison :{' '}
                                  {formatDate(
                                    note.delivery_date
                                  )}
                                </p>

                              </div>

                            </div>

                            <div className="text-right">

                              <p className="font-semibold text-slate-700">
                                {formatCurrency(
                                  note.total_amount
                                )}
                              </p>

                              <span className="text-xs text-slate-400">
                                BL créé le{' '}
                                {note.created_at
                                  ? formatDate(
                                      note.created_at
                                    )
                                  : '—'}
                              </span>

                            </div>

                          </div>

                        </div>
                      );
                    }
                  )}

                </div>

              )}

            </div>

            {/* Notes */}

            {detailDelivery.notes && (

              <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">

                <p className="text-xs text-slate-400 mb-1">
                  Notes
                </p>

                <p className="text-sm text-slate-600 whitespace-pre-wrap">
                  {
                    detailDelivery.notes
                  }
                </p>

              </div>

            )}

            {/* Actions */}

            <div className="flex flex-wrap gap-2 pt-2 border-t border-slate-200">

              {detailDelivery.status ===
                'pending' && (

                <Button
                  variant="secondary"
                  size="sm"
                  onClick={async () => {
                    await updateStatus(
                      detailDelivery,
                      'in_transit'
                    );

                    setDetailDelivery(
                      null
                    );
                  }}
                >
                  Démarrer la livraison
                </Button>

              )}

              {detailDelivery.status ===
                'in_transit' && (

                <Button
                  size="sm"
                  onClick={async () => {
                    await updateStatus(
                      detailDelivery,
                      'delivered'
                    );

                    setDetailDelivery(
                      null
                    );
                  }}
                >
                  Marquer comme livré
                </Button>

              )}

              {(
                detailDelivery.status ===
                  'pending' ||
                detailDelivery.status ===
                  'in_transit'
              ) && (

                <Button
                  variant="danger"
                  size="sm"
                  onClick={async () => {
                    await updateStatus(
                      detailDelivery,
                      'cancelled'
                    );

                    setDetailDelivery(
                      null
                    );
                  }}
                >
                  Annuler la livraison
                </Button>

              )}

              <Button
                variant="secondary"
                size="sm"
                onClick={() =>
                  setDetailDelivery(
                    null
                  )
                }
                className="ml-auto"
              >
                Fermer
              </Button>

            </div>

          </div>

        )}

      </Modal>

    </div>
  );
}