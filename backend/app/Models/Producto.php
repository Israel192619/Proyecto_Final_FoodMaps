<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Producto extends Model
{
    protected $fillable = [
        'nombre_producto',
    ];

    public function menus()
    {
        return $this->belongsToMany(Menu::class, 'menu_productos')
            ->withPivot('descripcion', 'tipo', 'precio', 'imagen', 'disponible')
            ->withTimestamps();
    }
}
