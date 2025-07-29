<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Producto extends Model
{
    protected $fillable = [
        'nombre_producto',
    ];

    public function menuBebidas()
    {
        return $this->hasMany(MenuBebida::class);
    }

    public function menuPlatillos()
    {
        return $this->hasMany(MenuPlatillo::class);
    }
}
