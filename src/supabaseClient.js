import { createClient } from '@supabase/supabase-js';

const getEnvOrGlobal = (key, globalProp) => {
  if (typeof window !== 'undefined') {
    if (window[globalProp]) return window[globalProp];
    const stored = localStorage.getItem(key);
    if (stored && !stored.includes('demo') && !stored.includes('your-project')) return stored;
  }
  return import.meta.env?.[key] || '';
};

export const SUPABASE_URL = getEnvOrGlobal('VITE_SUPABASE_URL', 'SUPABASE_URL') || "https://uzdkiwvzluznucjcynqg.supabase.co";
export const SUPABASE_KEY = getEnvOrGlobal('VITE_SUPABASE_ANON_KEY', 'SUPABASE_ANON_KEY') || "sb_publishable_RBKD0CnOT2A1_YWS1hJokg_IFcCaETV";

export const supabase = (SUPABASE_URL && SUPABASE_KEY)
  ? createClient(SUPABASE_URL, SUPABASE_KEY)
  : null;
