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

class ActualizacionEstadoRestaurante implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
     * Create a new event instance.
     */
    public $restaurante;

    public function __construct($restaurante)
    {
        $this->restaurante = $restaurante;
        Log::info('Evento ActualizacionEstadoRestaurante disparado', [
            'restaurante_id' => $restaurante->id,
            'restaurant_name' => $restaurante->nombre_restaurante,
            'estado' => $restaurante->estado,
        ]);
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        Log::info('broadcastOn ejecutado - canal establecido: restaurantes');
        return [new Channel('restaurantes')];
    }

    public function broadcastWith()
    {
        $data = [
            'id' => $this->restaurante->id,
            'nombre_restaurante' => $this->restaurante->nombre_restaurante,
            'estado' => $this->restaurante->estado,
            'estado_text' => $this->restaurante->estado ? 'ABIERTO' : 'CERRADO',
            'updated_at' => $this->restaurante->updated_at->toISOString()
        ];

        Log::info('broadcastWith ejecutado - datos enviados:', $data);
        return $data;
    }

    public function broadcastAs()
    {
        Log::info('broadcastAs ejecutado - nombre del evento: status.updated');
        return 'status.updated';
    }
}
