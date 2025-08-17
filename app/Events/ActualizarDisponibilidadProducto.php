<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ActualizarDisponibilidadProducto implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    public $producto;
    /**
     * Create a new event instance.
     */
    public function __construct($producto)
    {
        $this->producto = $producto;

        Log::info('Evento ActualizarDisponibilidadProducto disparado', [
            'producto_id' => $producto->id,
            'menu_id' => $producto->pivot->menu_id ?? null,
            'nombre_producto' => $producto->nombre_producto,
            'disponible' => $producto->pivot->disponible ?? null,
        ]);
    }

    public function broadcastOn(): array
    {
        Log::info('broadcastOn ejecutado - canal establecido: restaurantes');
        return [new Channel('restaurantes')];
    }

    public function broadcastWith()
    {
        $data = [
            'producto_id' => $this->producto->id,
            'menu_id' => $this->producto->pivot->menu_id ?? null,
            'nombre_producto' => $this->producto->nombre_producto,
            'disponible' => $this->producto->pivot->disponible ?? null,
            'disponible_text' => ($this->producto->pivot->disponible ?? false) ? 'DISPONIBLE' : 'NO DISPONIBLE',
            'descripcion' => $this->producto->pivot->descripcion ?? null,
            'tipo' => $this->producto->pivot->tipo ?? null,
            'precio' => $this->producto->pivot->precio ?? null,
            'imagen' => $this->producto->pivot->imagen ?? null,
            'updated_at' => $this->producto->updated_at->toISOString(),
        ];

        Log::info('broadcastWith ejecutado - datos enviados:', $data);
        return $data;
    }

    public function broadcastAs()
    {
        Log::info('broadcastAs ejecutado - nombre del evento: producto.disponibilidad.updated');
        return 'producto.disponibilidad.updated';
    }
}
