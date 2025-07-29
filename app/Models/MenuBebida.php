<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MenuBebida extends Model
{
    protected $fillable = [
        'menu_id',
        'producto_id',
        'descripcion',
        'precio',
        'imagen',
        'disponible',
    ];

    public function menu()
    {
        return $this->belongsTo(Menu::class);
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class);
    }
}
