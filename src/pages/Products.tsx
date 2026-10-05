import { useState, useEffect } from 'react';
import {
  Plus,
  Pencil,
  Trash2,
  Search,
  Package,
  AlertTriangle,
} from 'lucide-react';

import { supabase } from '@/lib/supabase';
import { formatCurrency } from '@/lib/utils';
import type { Product } from '@/types';

import {
  Card,
  Button,
  Input,
  Textarea,
  EmptyState,
  ConfirmDialog,
} from '@/components/ui';

import Modal from '@/components/Modal';
import Loading from '@/components/Loading';

const emptyForm = {
  name: '',
  sku: '',
  category: 'Général',
  description: '',
  unit: 'pièce',
  cost_price: '0',
  sale_price: '0',
  stock_quantity: '0',
  min_stock: '0',
};

export default function Products() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  const [modalOpen, setModalOpen] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);

  const [form, setForm] = useState(emptyForm);

  const [deleteId, setDeleteId] = useState<string | null>(null);

  const [saving, setSaving] = useState(false);
  const [generatingSku, setGeneratingSku] = useState(false);
  const [currencySymbol, setCurrencySymbol] = useState('DA');


 useEffect(() => {
  loadProducts();
  loadCurrencySettings();
}, []);

    async function loadCurrencySettings() {
      const { data, error } = await supabase
        .from('app_settings')
        .select('currency_symbol')
        .eq('id', 1)
        .single();

      if (error) {
        console.error(
          'Erreur chargement symbole monétaire:',
          error
        );
        return;
      }

      if (data?.currency_symbol) {
        setCurrencySymbol(data.currency_symbol);
      }
}
  async function loadProducts() {
    setLoading(true);

    const { data, error } = await supabase
      .from('products')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Erreur chargement produits:', error);
    }

    setProducts(data || []);
    setLoading(false);
  }

  /**
   * Génère la prochaine référence :
   *
   * PRD-0001
   * PRD-0002
   * PRD-0003
   * ...
   */
  async function generateNextSku(): Promise<string> {
    const { data, error } = await supabase
      .from('products')
      .select('sku')
      .like('sku', 'PRD-%');

    if (error) {
      console.error('Erreur génération SKU:', error);

      return `PRD-${Date.now().toString().slice(-6)}`;
    }

    let maxNumber = 0;

    for (const product of data || []) {
      if (!product.sku) {
        continue;
      }

      const match = product.sku.match(/^PRD-(\d+)$/);

      if (match) {
        const number = parseInt(match[1], 10);

        if (!isNaN(number) && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    const nextNumber = maxNumber + 1;

    return `PRD-${String(nextNumber).padStart(4, '0')}`;
  }

  /**
   * Vérifie si une référence existe déjà.
   */
  async function skuExists(sku: string): Promise<boolean> {
    const { data, error } = await supabase
      .from('products')
      .select('id')
      .eq('sku', sku)
      .limit(1);

    if (error) {
      console.error('Erreur vérification SKU:', error);
      return false;
    }

    return (data || []).length > 0;
  }

  /**
   * Génère une référence disponible.
   */
  async function generateAvailableSku(): Promise<string> {
    let sku = await generateNextSku();

    let exists = await skuExists(sku);

    while (exists) {
      const match = sku.match(/^PRD-(\d+)$/);

      if (match) {
        const number = parseInt(match[1], 10) + 1;

        sku = `PRD-${String(number).padStart(4, '0')}`;
      } else {
        sku = `PRD-${Date.now().toString().slice(-6)}`;
      }

      exists = await skuExists(sku);
    }

    return sku;
  }

  const filtered = products.filter((p) => {
    const searchValue = search.toLowerCase();

    return (
      p.name.toLowerCase().includes(searchValue) ||
      (p.sku || '').toLowerCase().includes(searchValue) ||
      p.category.toLowerCase().includes(searchValue)
    );
  });

  /**
   * Nouveau produit.
   */
  async function openAdd() {
    setGeneratingSku(true);

    try {
      const sku = await generateAvailableSku();

      setForm({
        ...emptyForm,
        sku,
      });

      setEditId(null);
      setModalOpen(true);
    } catch (error) {
      console.error('Erreur génération référence:', error);
    } finally {
      setGeneratingSku(false);
    }
  }

  /**
   * Modification d'un produit.
   *
   * La référence existante reste inchangée.
   */
  function openEdit(product: Product) {
    setForm({
      name: product.name,
      sku: product.sku || '',
      category: product.category,
      description: product.description,
      unit: product.unit,
      cost_price: String(product.cost_price),
      sale_price: String(product.sale_price),
      stock_quantity: String(product.stock_quantity),
      min_stock: String(product.min_stock),
    });

    setEditId(product.id);
    setModalOpen(true);
  }

  /**
   * Enregistrement du produit.
   */
  async function handleSave() {
    if (!form.name.trim()) {
      return;
    }

    setSaving(true);

    try {
      if (editId) {
        /*
         * MODIFICATION
         *
         * On ne change pas le SKU.
         */
        const payload = {
          name: form.name.trim(),
          category: form.category.trim(),
          description: form.description.trim(),
          unit: form.unit.trim(),
          cost_price: parseFloat(form.cost_price) || 0,
          sale_price: parseFloat(form.sale_price) || 0,
          stock_quantity: parseFloat(form.stock_quantity) || 0,
          min_stock: parseFloat(form.min_stock) || 0,
          updated_at: new Date().toISOString(),
        };

        const { error } = await supabase
          .from('products')
          .update(payload)
          .eq('id', editId);

        if (error) {
          console.error('Erreur modification produit:', error);

          alert(
            `Erreur lors de la modification du produit : ${error.message}`
          );

          return;
        }
      } else {
        /*
         * NOUVEAU PRODUIT
         *
         * Le SKU est généré automatiquement.
         */
        let sku = form.sku.trim();

        if (!sku) {
          sku = await generateAvailableSku();
        }

        /*
         * Vérification supplémentaire avant insertion.
         */
        const alreadyExists = await skuExists(sku);

        if (alreadyExists) {
          sku = await generateAvailableSku();
        }

        const payload = {
          name: form.name.trim(),
          sku,
          category: form.category.trim(),
          description: form.description.trim(),
          unit: form.unit.trim(),
          cost_price: parseFloat(form.cost_price) || 0,
          sale_price: parseFloat(form.sale_price) || 0,
          stock_quantity: parseFloat(form.stock_quantity) || 0,
          min_stock: parseFloat(form.min_stock) || 0,
          updated_at: new Date().toISOString(),
        };

        const { error } = await supabase
          .from('products')
          .insert(payload);

        if (error) {
          console.error('Erreur ajout produit:', error);

          /*
           * Si le SKU existe déjà, on génère une nouvelle référence
           * et on essaie une deuxième fois.
           */
          if (
            error.code === '23505' ||
            error.message.toLowerCase().includes('duplicate')
          ) {
            const newSku = await generateAvailableSku();

            const retryPayload = {
              ...payload,
              sku: newSku,
            };

            const { error: retryError } = await supabase
              .from('products')
              .insert(retryPayload);

            if (retryError) {
              console.error(
                'Erreur deuxième tentative:',
                retryError
              );

              alert(
                `Impossible d'ajouter le produit : ${retryError.message}`
              );

              return;
            }
          } else {
            alert(
              `Impossible d'ajouter le produit : ${error.message}`
            );

            return;
          }
        }
      }

      setModalOpen(false);
      setEditId(null);
      setForm(emptyForm);

      await loadProducts();
    } finally {
      setSaving(false);
    }
  }

  /**
   * Suppression d'un produit.
   */
  async function handleDelete() {
    if (!deleteId) {
      return;
    }

    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', deleteId);

    if (error) {
      console.error('Erreur suppression produit:', error);

      alert(
        `Impossible de supprimer le produit : ${error.message}`
      );

      return;
    }

    setDeleteId(null);

    await loadProducts();
  }

  if (loading) {
    return <Loading />;
  }

  return (
    <div className="space-y-6 animate-fade-in-up">
      {/* EN-TÊTE */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">
            Produits
          </h1>

          <p className="text-sm text-slate-500 mt-1">
            {products.length} produit(s) au total
          </p>
        </div>

        <Button
          onClick={openAdd}
          disabled={generatingSku}
        >
          <Plus className="w-4 h-4" />

          {generatingSku
            ? 'Génération...'
            : 'Nouveau produit'}
        </Button>
      </div>

      {/* RECHERCHE */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />

        <input
          type="text"
          placeholder="Rechercher un produit..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-10 pr-4 py-2.5 rounded-lg border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
      </div>

      {/* LISTE */}
      {filtered.length === 0 ? (
        <Card>
          <EmptyState
            icon={Package}
            title="Aucun produit"
            description="Commencez par ajouter votre premier produit à l'inventaire."
            action={
              <Button onClick={openAdd}>
                <Plus className="w-4 h-4" />
                Ajouter un produit
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
                    Produit
                  </th>

                  <th className="text-left font-semibold text-slate-600 px-4 py-3 hidden md:table-cell">
                    Catégorie
                  </th>

                  <th className="text-right font-semibold text-slate-600 px-4 py-3">
                    Prix achat
                  </th>

                  <th className="text-right font-semibold text-slate-600 px-4 py-3">
                    Prix vente
                  </th>

                  <th className="text-center font-semibold text-slate-600 px-4 py-3">
                    Stock
                  </th>

                  <th className="text-right font-semibold text-slate-600 px-4 py-3">
                    Actions
                  </th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {filtered.map((p) => {
                  const low =
                    p.stock_quantity <= p.min_stock;

                  return (
                    <tr
                      key={p.id}
                      className="hover:bg-slate-50 transition-colors"
                    >
                      <td className="px-4 py-3">
                        <div className="font-medium text-slate-800">
                          {p.name}
                        </div>

                        <div className="text-xs text-slate-400">
                          {p.sku || '—'}
                        </div>
                      </td>

                      <td className="px-4 py-3 hidden md:table-cell text-slate-600">
                        {p.category}
                      </td>

                      <td className="px-4 py-3 text-right text-slate-600">
                        {formatCurrency(p.cost_price)}
                      </td>

                      <td className="px-4 py-3 text-right font-medium text-slate-800">
                        {formatCurrency(p.sale_price)}
                      </td>

                      <td className="px-4 py-3 text-center">
                        <span
                          className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${
                            low
                              ? 'bg-amber-100 text-amber-700'
                              : 'bg-emerald-100 text-emerald-700'
                          }`}
                        >
                          {low && (
                            <AlertTriangle className="w-3 h-3" />
                          )}

                          {p.stock_quantity} {p.unit}
                        </span>
                      </td>

                      <td className="px-4 py-3">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            onClick={() => openEdit(p)}
                            className="p-2 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                            title="Modifier"
                          >
                            <Pencil className="w-4 h-4" />
                          </button>

                          <button
                            onClick={() => setDeleteId(p.id)}
                            className="p-2 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                            title="Supprimer"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* MODAL */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={
          editId
            ? 'Modifier le produit'
            : 'Nouveau produit'
        }
        size="lg"
      >
        <div className="space-y-4">
          {/* NOM + SKU */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="Nom du produit"
              value={form.name}
              onChange={(v) =>
                setForm({
                  ...form,
                  name: v,
                })
              }
              required
            />

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1.5">
                SKU / Référence
              </label>

              <input
                type="text"
                value={form.sku}
                readOnly
                className="w-full px-3 py-2.5 rounded-lg border border-slate-300 bg-slate-100 text-slate-700 font-semibold cursor-not-allowed focus:outline-none"
              />

              {!editId && (
                <p className="text-xs text-slate-400 mt-1">
                  Générée automatiquement
                </p>
              )}
            </div>
          </div>

          {/* CATÉGORIE + UNITÉ + STOCK MIN */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Input
              label="Catégorie"
              value={form.category}
              onChange={(v) =>
                setForm({
                  ...form,
                  category: v,
                })
              }
            />

            <Input
              label="Unité"
              value={form.unit}
              onChange={(v) =>
                setForm({
                  ...form,
                  unit: v,
                })
              }
            />

            <Input
              label="Stock minimum"
              type="number"
              step="0.01"
              value={form.min_stock}
              onChange={(v) =>
                setForm({
                  ...form,
                  min_stock: v,
                })
              }
            />
          </div>

          {/* PRIX + STOCK */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Input
              label={`Prix d'achat (${currencySymbol})`}
              type="number"
              step="0.01"
              value={form.cost_price}
              onChange={(v) =>
                setForm({
                  ...form,
                  cost_price: v,
                })
              }
            />

            <Input
              label={`Prix de vente (${currencySymbol})`}
              type="number"
              step="0.01"
              value={form.sale_price}
              onChange={(v) =>
                setForm({
                  ...form,
                  sale_price: v,
                })
              }
            />

            <Input
              label="Quantité en stock"
              type="number"
              step="0.01"
              value={form.stock_quantity}
              onChange={(v) =>
                setForm({
                  ...form,
                  stock_quantity: v,
                })
              }
            />
          </div>

          {/* DESCRIPTION */}
          <Textarea
            label="Description"
            value={form.description}
            onChange={(v) =>
              setForm({
                ...form,
                description: v,
              })
            }
          />

          {/* BOUTONS */}
          <div className="flex gap-3 pt-2">
            <Button
              variant="secondary"
              onClick={() => setModalOpen(false)}
              className="flex-1"
              disabled={saving}
            >
              Annuler
            </Button>

            <Button
              onClick={handleSave}
              disabled={
                saving ||
                !form.name.trim() ||
                !form.sku.trim()
              }
              className="flex-1"
            >
              {saving
                ? 'Enregistrement...'
                : editId
                  ? 'Mettre à jour'
                  : 'Ajouter'}
            </Button>
          </div>
        </div>
      </Modal>

      {/* SUPPRESSION */}
      <ConfirmDialog
        open={!!deleteId}
        onClose={() => setDeleteId(null)}
        onConfirm={handleDelete}
        title="Supprimer le produit"
        message="Êtes-vous sûr de vouloir supprimer ce produit ? Cette action est irréversible."
      />
    </div>
  );
}