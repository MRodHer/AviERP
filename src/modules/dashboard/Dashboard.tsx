import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { Egg, Package, Users, TrendingUp, AlertCircle } from 'lucide-react';

export function Dashboard() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const [flocksData, inventoryData, productionData] = await Promise.all([
        supabase
          .from('flocks')
          .select('*', { count: 'exact' })
          .eq('status', 'active'),
        supabase
          .from('inventory_items')
          .select('current_stock, min_stock', { count: 'exact' }),
        supabase
          .from('daily_production')
          .select('total_eggs, laying_percentage')
          .order('production_date', { ascending: false })
          .limit(7),
      ]);

      const activeFlocks = flocksData.count || 0;
      const lowStockItems =
        inventoryData.data?.filter((item) => item.current_stock <= item.min_stock)
          .length || 0;

      const avgProduction =
        productionData.data?.reduce((sum, p) => sum + p.total_eggs, 0) /
          (productionData.data?.length || 1) || 0;

      const avgLayingPercentage =
        productionData.data?.reduce((sum, p) => sum + p.laying_percentage, 0) /
          (productionData.data?.length || 1) || 0;

      return {
        activeFlocks,
        lowStockItems,
        avgProduction: Math.round(avgProduction),
        avgLayingPercentage: avgLayingPercentage.toFixed(1),
      };
    },
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
      </div>
    );
  }

  const cards = [
    {
      title: 'Parvadas Activas',
      value: stats?.activeFlocks || 0,
      icon: Egg,
      color: 'bg-blue-500',
      textColor: 'text-blue-600',
      bgColor: 'bg-blue-50',
    },
    {
      title: 'Alertas de Stock',
      value: stats?.lowStockItems || 0,
      icon: AlertCircle,
      color: 'bg-red-500',
      textColor: 'text-red-600',
      bgColor: 'bg-red-50',
    },
    {
      title: 'Producción Promedio',
      value: `${stats?.avgProduction || 0} huevos`,
      icon: Package,
      color: 'bg-green-500',
      textColor: 'text-green-600',
      bgColor: 'bg-green-50',
    },
    {
      title: 'Porcentaje de Postura',
      value: `${stats?.avgLayingPercentage || 0}%`,
      icon: TrendingUp,
      color: 'bg-purple-500',
      textColor: 'text-purple-600',
      bgColor: 'bg-purple-50',
    },
  ];

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600 mt-2">Vista general de la operación</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {cards.map((card) => {
          const Icon = card.icon;
          return (
            <div
              key={card.title}
              className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex items-center justify-between mb-4">
                <div className={`p-3 rounded-lg ${card.bgColor}`}>
                  <Icon className={`w-6 h-6 ${card.textColor}`} />
                </div>
              </div>
              <h3 className="text-gray-600 text-sm font-medium mb-1">
                {card.title}
              </h3>
              <p className="text-2xl font-bold text-gray-900">{card.value}</p>
            </div>
          );
        })}
      </div>

      <div className="mt-8 grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">
            Producción Reciente
          </h2>
          <p className="text-gray-600">
            Gráficas de producción próximamente...
          </p>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">
            Indicadores Financieros
          </h2>
          <p className="text-gray-600">KPIs financieros próximamente...</p>
        </div>
      </div>
    </div>
  );
}
