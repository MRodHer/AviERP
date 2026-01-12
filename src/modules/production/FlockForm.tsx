import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { X } from 'lucide-react';

const flockSchema = z.object({
  flock_number: z.string().min(1, 'Requerido'),
  flock_type: z.enum(['layers', 'broilers']),
  breed: z.string().min(1, 'Requerido'),
  entry_date: z.string().min(1, 'Requerido'),
  initial_quantity: z.coerce.number().min(1, 'Debe ser mayor a 0'),
  birth_date: z.string().optional(),
  expected_end_date: z.string().optional(),
  notes: z.string().optional(),
});

type FlockFormData = z.infer<typeof flockSchema>;

interface FlockFormProps {
  flock?: any;
  onClose: () => void;
}

export function FlockForm({ flock, onClose }: FlockFormProps) {
  const queryClient = useQueryClient();
  const isEdit = !!flock;

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FlockFormData>({
    resolver: zodResolver(flockSchema),
    defaultValues: flock || {
      breed: 'Ross 308',
      flock_type: 'layers',
    },
  });

  const mutation = useMutation({
    mutationFn: async (data: FlockFormData) => {
      const payload = {
        ...data,
        current_quantity: isEdit ? flock.current_quantity : data.initial_quantity,
      };

      if (isEdit) {
        const { error } = await supabase
          .from('flocks')
          .update(payload)
          .eq('id', flock.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('flocks').insert(payload);
        if (error) throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['flocks'] });
      onClose();
    },
  });

  const onSubmit = (data: FlockFormData) => {
    mutation.mutate(data);
  };

  return (
    <div className="p-8">
      <div className="max-w-2xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              {isEdit ? 'Editar Parvada' : 'Nueva Parvada'}
            </h1>
            <p className="text-gray-600 mt-2">
              {isEdit ? 'Actualiza los datos de la parvada' : 'Registra una nueva parvada'}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Número de Parvada *
                </label>
                <input
                  {...register('flock_number')}
                  type="text"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
                  placeholder="PAR-2024-001"
                />
                {errors.flock_number && (
                  <p className="mt-1 text-sm text-red-600">{errors.flock_number.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Tipo *
                </label>
                <select
                  {...register('flock_type')}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
                >
                  <option value="layers">Postura</option>
                  <option value="broilers">Engorda</option>
                </select>
                {errors.flock_type && (
                  <p className="mt-1 text-sm text-red-600">{errors.flock_type.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Raza/Línea Genética *
                </label>
                <input
                  {...register('breed')}
                  type="text"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
                  placeholder="Ross 308"
                />
                {errors.breed && (
                  <p className="mt-1 text-sm text-red-600">{errors.breed.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Fecha de Ingreso *
                </label>
                <input
                  {...register('entry_date')}
                  type="date"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
                />
                {errors.entry_date && (
                  <p className="mt-1 text-sm text-red-600">{errors.entry_date.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Cantidad Inicial *
                </label>
                <input
                  {...register('initial_quantity')}
                  type="number"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
                  placeholder="1000"
                />
                {errors.initial_quantity && (
                  <p className="mt-1 text-sm text-red-600">{errors.initial_quantity.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Fecha de Nacimiento
                </label>
                <input
                  {...register('birth_date')}
                  type="date"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Fecha Esperada de Finalización
                </label>
                <input
                  {...register('expected_end_date')}
                  type="date"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Notas
                </label>
                <textarea
                  {...register('notes')}
                  rows={3}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-600 focus:border-transparent"
                  placeholder="Observaciones adicionales..."
                />
              </div>
            </div>

            <div className="flex gap-4 pt-6 border-t border-gray-200">
              <button
                type="button"
                onClick={onClose}
                className="flex-1 px-6 py-3 border border-gray-300 rounded-lg text-gray-700 font-semibold hover:bg-gray-50 transition-colors"
              >
                Cancelar
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg font-semibold hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSubmitting ? 'Guardando...' : isEdit ? 'Actualizar' : 'Crear Parvada'}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
