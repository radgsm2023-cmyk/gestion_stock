import { supabase } from '@/lib/supabase';

/* ============================================================
   DEVISE
   ============================================================ */

let currencySymbol = '€';
let currencyCode = 'EUR';

export function setCurrencySettings(
  symbol: string,
  code: string
): void {
  currencySymbol = symbol || '€';
  currencyCode = code || 'EUR';
}

export function formatCurrency(amount: number): string {
  const formatted = new Intl.NumberFormat('fr-FR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount || 0);

  return `${formatted} ${currencySymbol}`;
}

/* ============================================================
   DATES
   ============================================================ */

/**
 * Retourne la date locale au format YYYY-MM-DD.
 *
 * Exemple :
 * 05/10/2026 -> 2026-10-05
 *
 * On évite volontairement toISOString() ici afin d'éviter
 * les décalages de date liés à UTC.
 */
export function getLocalDateString(date: Date = new Date()): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

/**
 * Transforme une date YYYY-MM-DD en DDMMYYYY.
 *
 * Exemple :
 * 2026-10-05 -> 05102026
 */
export function dateStamp(date?: string): string {
  if (date) {
    const parts = date.split('-');

    if (parts.length === 3) {
      const [year, month, day] = parts;

      return `${day.padStart(2, '0')}${month.padStart(
        2,
        '0'
      )}${year}`;
    }
  }

  const d = new Date();

  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const yyyy = d.getFullYear();

  return `${dd}${mm}${yyyy}`;
}

export function formatDate(date: string | null): string {
  if (!date) return '—';

  const dateOnly = date.includes('T')
    ? date.split('T')[0]
    : date;

  const parts = dateOnly.split('-');

  if (parts.length === 3) {
    const [year, month, day] = parts;

    return `${day}/${month}/${year}`;
  }

  return new Date(date).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

/* ============================================================
   RÉFÉRENCES
   ============================================================ */

function seqNum(n: number): string {
  return String(n).padStart(3, '0');
}

/**
 * Référence générique.
 *
 * Exemple :
 * ACH-2026-X7K9P
 */
export function generateReference(prefix: string): string {
  const date = new Date();
  const year = date.getFullYear();

  const rand = Math.random()
    .toString(36)
    .substring(2, 7)
    .toUpperCase();

  return `${prefix}-${year}-${rand}`;
}

/* ============================================================
   VENTES
   ============================================================ */

/**
 * Exemple :
 * VENT-001-05102026
 */
export function generateSalesRef(seq: number): string {
  return `VENT-${seqNum(seq)}-${dateStamp()}`;
}

/* ============================================================
   ACHATS
   ============================================================ */

/**
 * Exemple :
 * ACH-001-05102026
 */
export function generatePurchaseRef(seq: number): string {
  return `ACH-${seqNum(seq)}-${dateStamp()}`;
}

/* ============================================================
   BON DE COMMANDE
   ============================================================ */

/**
 * Exemple :
 * BC-001-05102026
 */
export function generateBCRef(seq: number): string {
  return `BC-${seqNum(seq)}-${dateStamp()}`;
}

/* ============================================================
   LIVRAISON / TOURNÉE
   ============================================================ */

/**
 * Référence d'une tournée de livraison.
 *
 * IMPORTANT :
 * La date utilisée est la DATE DE LIVRAISON PLANIFIÉE,
 * et non obligatoirement la date du jour.
 *
 * Exemple :
 * Aujourd'hui : 05/10/2026
 * Livraison prévue : 08/10/2026
 *
 * LIV-001-08102026
 */
export function generateLIVRef(
  seq: number,
  deliveryDate?: string
): string {
  return `LIV-${seqNum(seq)}-${dateStamp(deliveryDate)}`;
}

/* ============================================================
   BON DE LIVRAISON
   ============================================================ */

/**
 * Référence d'un bon de livraison.
 *
 * IMPORTANT :
 * La date utilisée est la DATE DE CRÉATION DU BL.
 *
 * Exemple :
 * Aujourd'hui : 05/10/2026
 *
 * BL-001-05102026
 * BL-002-05102026
 * BL-003-05102026
 *
 * Si aucun deuxième paramètre n'est fourni,
 * la date du jour est utilisée automatiquement.
 */
export function generateBLRef(
  seq: number,
  creationDate?: string
): string {
  return `BL-${seqNum(seq)}-${dateStamp(creationDate)}`;
}

/* ============================================================
   FACTURES
   ============================================================ */

/**
 * Exemple :
 * FACT-001-05102026
 */
export function generateFTRef(seq: number): string {
  return `FACT-${seqNum(seq)}-${dateStamp()}`;
}

/* ============================================================
   SÉQUENCES SUPABASE
   ============================================================ */

/**
 * Retourne le prochain numéro séquentiel d'une table.
 *
 * Exemple :
 * 14 lignes existantes -> 15
 *
 * ATTENTION :
 * Cette méthode fonctionne pour une utilisation simple,
 * mais elle n'est pas totalement sûre contre deux créations
 * simultanées.
 */
export async function getNextSeq(
  table: string
): Promise<number> {
  const { count, error } = await supabase
    .from(table)
    .select('*', {
      count: 'exact',
      head: true,
    });

  if (error) {
    console.error(
      'Erreur comptage',
      table,
      error
    );

    return 1;
  }

  return (count || 0) + 1;
}

/* ============================================================
   CLASSNAMES
   ============================================================ */

export function cn(
  ...classes: (string | false | undefined)[]
): string {
  return classes.filter(Boolean).join(' ');
}

/* ============================================================
   VALIDATION PATTERNS
   ============================================================ */

export const patterns = {
  nif: {
    regex: /^\d{15,20}$/,
    label: 'NIF',
    format: '15 à 20 chiffres',
    example: '123456789012345',
  },

  ai: {
    regex: /^\d{11}$/,
    label: 'AI',
    format: '11 chiffres',
    example: '12345678901',
  },

  rc: {
    regex: /^\d{2}[A-Z]\d{7}$/,
    label: 'RC',
    format: '2 chiffres + 1 lettre + 7 chiffres',
    example: '99A9999999',
  },

  phone: {
    regex: /^[\d\s+().-]{8,20}$/,
    label: 'Téléphone',
    format: '8 à 20 caractères',
    example: '+213 5 55 55 55 55',
  },

  email: {
    regex: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    label: 'Email',
    format: 'adresse@email.com',
    example: 'contact@exemple.com',
  },
} as const;

/* ============================================================
   ERREURS DE VALIDATION
   ============================================================ */

export type FieldErrors = Record<
  string,
  string | undefined
>;

/* ============================================================
   VALIDATION D'UN CHAMP
   ============================================================ */

export function validateField(
  field: string,
  value: string
): string | undefined {
  const v = value.trim();

  /*
   * Champ vide :
   * La fonction vérifie uniquement le format.
   * Le caractère obligatoire doit être géré par le formulaire.
   */
  if (!v) return undefined;

  switch (field) {
    case 'nif':
      if (!patterns.nif.regex.test(v)) {
        return `Le NIF doit contenir ${patterns.nif.format} (ex: ${patterns.nif.example})`;
      }
      break;

    case 'ai':
      if (!patterns.ai.regex.test(v)) {
        return `L'AI doit contenir ${patterns.ai.format} (ex: ${patterns.ai.example})`;
      }
      break;

    case 'rc':
      if (!patterns.rc.regex.test(v)) {
        return `Le RC doit respecter le format : ${patterns.rc.format} (ex: ${patterns.rc.example})`;
      }
      break;

    case 'phone':
      if (!patterns.phone.regex.test(v)) {
        return `Numéro de téléphone invalide (ex: ${patterns.phone.example})`;
      }
      break;

    case 'email':
      if (!patterns.email.regex.test(v)) {
        return `Adresse email invalide (ex: ${patterns.email.example})`;
      }
      break;
  }

  return undefined;
}

/* ============================================================
   VALIDATION DE PLUSIEURS CHAMPS
   ============================================================ */

export function validateFields(
  fields: Record<string, string>
): FieldErrors {
  const errors: FieldErrors = {};

  for (const [field, value] of Object.entries(fields)) {
    const err = validateField(field, value);

    if (err) {
      errors[field] = err;
    }
  }

  return errors;
}

/* ============================================================
   VÉRIFICATION DES ERREURS
   ============================================================ */

export function hasErrors(
  errors: FieldErrors
): boolean {
  return Object.values(errors).some(
    (value) => !!value
  );
}