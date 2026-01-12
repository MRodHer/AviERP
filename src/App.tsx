import { useEffect, useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAuthStore } from './stores/authStore';
import { Login } from './modules/auth/Login';
import { Sidebar } from './components/layout/Sidebar';
import { Dashboard } from './modules/dashboard/Dashboard';
import { FlockList } from './modules/production/FlockList';
import { InventoryList } from './modules/inventory/InventoryList';
import { ChartOfAccounts } from './modules/accounting/ChartOfAccounts';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,
      refetchOnWindowFocus: false,
    },
  },
});

function AppContent() {
  const { user, loading, initialize } = useAuthStore();
  const [currentModule, setCurrentModule] = useState('dashboard');

  useEffect(() => {
    initialize();
  }, [initialize]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-green-600"></div>
      </div>
    );
  }

  if (!user) {
    return <Login />;
  }

  const renderModule = () => {
    switch (currentModule) {
      case 'dashboard':
        return <Dashboard />;
      case 'production':
        return <FlockList />;
      case 'inventory':
        return <InventoryList />;
      case 'accounting':
        return <ChartOfAccounts />;
      case 'settings':
        return (
          <div className="p-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-4">Configuración</h1>
            <p className="text-gray-600">Módulo en desarrollo...</p>
          </div>
        );
      default:
        return (
          <div className="p-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-4">
              {currentModule.charAt(0).toUpperCase() + currentModule.slice(1)}
            </h1>
            <p className="text-gray-600">Este módulo estará disponible próximamente.</p>
          </div>
        );
    }
  };

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar currentModule={currentModule} onModuleChange={setCurrentModule} />
      <main className="flex-1 overflow-y-auto">{renderModule()}</main>
    </div>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AppContent />
    </QueryClientProvider>
  );
}
