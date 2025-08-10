<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MenuProducto extends Model
{
    protected $table = 'menu_productos';

    protected $fillable = [
        'menu_id',
        'producto_id',
        'descripcion',
        'tipo',
        'precio',
        'imagen',
        'disponible'
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
