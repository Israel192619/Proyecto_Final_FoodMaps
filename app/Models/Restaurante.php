<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Restaurante extends Model
{
    protected $fillable = [
        'nombre_restaurante',
        'ubicacion',
        'latitud',
        'longitud',
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
}
