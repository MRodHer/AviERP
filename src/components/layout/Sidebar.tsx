import { useEffect } from 'react';
import { useModuleStore } from '../../stores/moduleStore';
import { useAuthStore } from '../../stores/authStore';
import * as LucideIcons from 'lucide-react';
import { LogOut, User } from 'lucide-react';

interface SidebarProps {
  currentModule: string;
  onModuleChange: (moduleKey: string) => void;
}

export function Sidebar({ currentModule, onModuleChange }: SidebarProps) {
  const { enabledModules, loading, fetchModules } = useModuleStore();
  const { profile, signOut } = useAuthStore();

  useEffect(() => {
    fetchModules();
  }, [fetchModules]);

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const getIcon = (iconName: string) => {
    const Icon = (LucideIcons as any)[iconName] || LucideIcons.Circle;
    return Icon;
  };

  if (loading) {
    return (
      <div className="w-64 bg-gray-900 text-white p-4 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
      </div>
    );
  }

  return (
    <div className="w-64 bg-gray-900 text-white flex flex-col h-screen">
      <div className="p-6 border-b border-gray-800">
        <h1 className="text-2xl font-bold">ERP Avícola</h1>
        <p className="text-sm text-gray-400 mt-1">Metepec, Edo. Méx.</p>
      </div>

      <nav className="flex-1 overflow-y-auto p-4">
        <ul className="space-y-1">
          {enabledModules.map((module) => {
            const Icon = getIcon(module.icon);
            const isActive = currentModule === module.module_key;

            return (
              <li key={module.module_key}>
                <button
                  onClick={() => onModuleChange(module.module_key)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                    isActive
                      ? 'bg-green-600 text-white'
                      : 'text-gray-300 hover:bg-gray-800'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span className="text-sm font-medium">{module.module_name}</span>
                </button>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="p-4 border-t border-gray-800">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-gray-700 rounded-full flex items-center justify-center">
            <User className="w-5 h-5" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium truncate">{profile?.full_name}</p>
            <p className="text-xs text-gray-400 capitalize">{profile?.role}</p>
          </div>
        </div>
        <button
          onClick={handleSignOut}
          className="w-full flex items-center gap-2 px-4 py-2 text-sm text-gray-300 hover:bg-gray-800 rounded-lg transition-colors"
        >
          <LogOut className="w-4 h-4" />
          Cerrar Sesión
        </button>
      </div>
    </div>
  );
}
