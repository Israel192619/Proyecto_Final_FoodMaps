<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;

class Restaurante extends Model
{
    protected $fillable = [
        'nombre_restaurante',
        'ubicacion',
        'celular',
        'imagen',
        'estado',
        'tematica',
        'contador_vistas',
        'user_id',
    ];
    public function user()
    {
        return $this->belongsTo(User::class);
    }
    public function menu()
    {
        return $this->hasOne(Menu::class);
    }
    protected $casts = [
        'estado' => 'integer',
    ];
    protected static function booted()
    {
        static::updated(function ($restaurante) {
            // Verificamos si el campo "estado" realmente cambió
            if ($restaurante->wasChanged('estado')) {
                try {
                    // Registro inicial de cambio de estado
                    Log::info('Cambio de estado detectado en restaurante', [
                        'id_restaurante' => $restaurante->id,
                        'nombre_restaurante' => $restaurante->nombre_restaurante,
                        'estado_anterior' => $restaurante->getOriginal('estado'),
                        'estado_nuevo' => $restaurante->estado,
                        'fecha' => now()
                    ]);

                    // Verificamos el driver de broadcasting configurado
                    $driverBroadcast = config('broadcasting.default');
                    Log::info('Driver de broadcasting configurado: ' . $driverBroadcast);

                    // Si el broadcasting está configurado para WebSockets reales
                    if (in_array($driverBroadcast, ['reverb', 'pusher'])) {
                        if (class_exists(\App\Events\ActualizacionEstadoRestaurante::class)) {
                            try {
                                Log::info('Enviando evento ActualizacionEstadoRestaurante vía WebSocket...');

                                // Emisión del evento en tiempo real
                                broadcast(new \App\Events\ActualizacionEstadoRestaurante($restaurante));

                                Log::info('Evento emitido correctamente', [
                                    'id_restaurante' => $restaurante->id,
                                    'evento' => 'ActualizacionEstadoRestaurante',
                                    'driver' => $driverBroadcast,
                                    'canal' => 'restaurante'
                                ]);
                            } catch (\Exception $eBroadcast) {
                                Log::error('Error al emitir el evento vía WebSocket', [
                                    'id_restaurante' => $restaurante->id,
                                    'error' => $eBroadcast->getMessage(),
                                    'traza' => $eBroadcast->getTraceAsString()
                                ]);
                            }
                        } else {
                            Log::error('La clase ActualizacionEstadoRestaurante no existe');
                        }
                    } else {
                        // Modo "solo log" si no se usa WebSocket real
                        Log::info('Modo LOG - Evento ActualizacionEstadoRestaurante', [
                            'id_restaurante' => $restaurante->id,
                            'nombre_restaurante' => $restaurante->nombre_restaurante,
                            'estado' => $restaurante->estado,
                            'estado_texto' => $restaurante->estado ? 'ABIERTO' : 'CERRADO'
                        ]);
                    }

                    // Información del evento para almacenar en cache
                    $evento = [
                        'id' => $restaurante->id,
                        'nombre_restaurante' => $restaurante->nombre_restaurante,
                        'estado' => $restaurante->estado,
                        'fecha' => now()->toISOString()
                    ];

                    // Clave para lista de eventos recientes
                    $claveCacheLista = 'restaurant_status_events';
                    $eventos = cache($claveCacheLista, []);

                    // Insertamos el nuevo evento al inicio
                    array_unshift($eventos, $evento);

                    // Mantener solo los últimos 10 eventos
                    $eventos = array_slice($eventos, 0, 10);

                    // Guardamos lista de eventos y estado individual del restaurante
                    cache([$claveCacheLista => $eventos], now()->addMinutes(60));
                    cache(["restaurant_status_{$restaurante->id}" => $evento], now()->addMinutes(60));

                } catch (\Exception $e) {
                    Log::error('Error fatal en la actualización de estado del restaurante', [
                        'id_restaurante' => $restaurante->id,
                        'error' => $e->getMessage(),
                        'traza' => $e->getTraceAsString()
                    ]);
                }
            } else {
                // Caso en que se actualiza el restaurante pero no cambia el estado
                Log::info('Restaurante actualizado sin cambio de estado', [
                    'id_restaurante' => $restaurante->id,
                    'campos_modificados' => array_keys($restaurante->getDirty())
                ]);
            }
        });
    }

}
