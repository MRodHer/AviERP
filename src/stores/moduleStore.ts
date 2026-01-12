import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { Database } from '../types/database';

type SystemModule = Database['public']['Tables']['system_modules']['Row'];

interface ModuleState {
  modules: SystemModule[];
  enabledModules: SystemModule[];
  loading: boolean;
  fetchModules: () => Promise<void>;
  toggleModule: (moduleKey: string, enabled: boolean) => Promise<void>;
  isModuleEnabled: (moduleKey: string) => boolean;
}

export const useModuleStore = create<ModuleState>((set, get) => ({
  modules: [],
  enabledModules: [],
  loading: true,

  fetchModules: async () => {
    set({ loading: true });
    const { data, error } = await supabase
      .from('system_modules')
      .select('*')
      .order('sort_order', { ascending: true });

    if (!error && data) {
      set({
        modules: data,
        enabledModules: data.filter((m) => m.is_enabled),
        loading: false,
      });
    } else {
      set({ loading: false });
    }
  },

  toggleModule: async (moduleKey: string, enabled: boolean) => {
    const { error } = await supabase
      .from('system_modules')
      .update({ is_enabled: enabled })
      .eq('module_key', moduleKey);

    if (!error) {
      await get().fetchModules();
    }
  },

  isModuleEnabled: (moduleKey: string) => {
    return get().enabledModules.some((m) => m.module_key === moduleKey);
  },
}));
