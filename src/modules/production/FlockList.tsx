import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { Plus, Edit, Trash2, Calendar } from 'lucide-react';
import { format } from 'date-fns';
import { FlockForm } from './FlockForm';

export function FlockList() {
  const [showForm, setShowForm] = useState(false);
  const [editingFlock, setEditingFlock] = useState<any>(null);
  const queryClient = useQueryClient();

  const { data: flocks, isLoading } = useQuery({
    queryKey: ['flocks'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('flocks')
        .select('*')
        .order('entry_date', { ascending: false });

      if (error) throw error;
      return data;
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from('flocks').delete().eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['flocks'] });
    },
  });

  const handleEdit = (flock: any) => {
    setEditingFlock(flock);
    setShowForm(true);
  };

  const handleCloseForm = () => {
    setShowForm(false);
    setEditingFlock(null);
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-green-100 text-green-800',
      completed: 'bg-blue-100 text-blue-800',
      closed: 'bg-gray-100 text-gray-800',
    };
    return styles[status as keyof typeof styles] || styles.active;
  };

  const getTypeBadge = (type: string) => {
    return type === 'layers'
      ? 'bg-purple-100 text-purple-800'
      : 'bg-orange-100 text-orange-800';
  };

  if (showForm) {
    return (
      <FlockForm flock={editingFlock} onClose={handleCloseForm} />
    );
  }

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Parvadas</h1>
          <p className="text-gray-600 mt-2">Gestión de lotes de aves</p>
        </div>
        <button
          onClick={() => setShowForm(true)}
          className="flex items-center gap-2 bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors font-semibold"
        >
          <Plus className="w-5 h-5" />
          Nueva Parvada
        </button>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {flocks?.map((flock) => (
            <div
              key={flock.id}
              className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-lg font-bold text-gray-900">
                    {flock.flock_number}
                  </h3>
                  <p className="text-sm text-gray-600">{flock.breed}</p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => handleEdit(flock)}
                    className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                  >
                    <Edit className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => {
                      if (confirm('¿Eliminar esta parvada?')) {
                        deleteMutation.mutate(flock.id);
                      }
                    }}
                    className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex gap-2">
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-medium ${getTypeBadge(
                      flock.flock_type
                    )}`}
                  >
                    {flock.flock_type === 'layers' ? 'Postura' : 'Engorda'}
                  </span>
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusBadge(
                      flock.status
                    )}`}
                  >
                    {flock.status === 'active'
                      ? 'Activa'
                      : flock.status === 'completed'
                      ? 'Completada'
                      : 'Cerrada'}
                  </span>
                </div>

                <div className="pt-3 border-t border-gray-200">
                  <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
                    <Calendar className="w-4 h-4" />
                    Ingreso: {format(new Date(flock.entry_date), 'dd/MM/yyyy')}
                  </div>
                  <div className="grid grid-cols-2 gap-4 mt-3">
                    <div>
                      <p className="text-xs text-gray-500">Inicial</p>
                      <p className="text-lg font-bold text-gray-900">
                        {flock.initial_quantity.toLocaleString()}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">Actual</p>
                      <p className="text-lg font-bold text-gray-900">
                        {flock.current_quantity.toLocaleString()}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {!isLoading && flocks?.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500">No hay parvadas registradas</p>
        </div>
      )}
    </div>
  );
}
