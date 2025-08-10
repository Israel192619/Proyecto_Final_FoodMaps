<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Menu extends Model
{
    protected $fillable = [
        'restaurante_id',
    ];

    public function restaurante()
    {
        return $this->belongsTo(Restaurante::class);
    }
    public function productos()
    {
        return $this->belongsToMany(Producto::class, 'menu_productos')
            ->withPivot('descripcion', 'tipo', 'precio', 'imagen', 'disponible')
            ->withTimestamps();
    }
}
