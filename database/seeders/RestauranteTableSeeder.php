<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RestauranteTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('restaurantes')->insert([
            [
                'nombre_restaurante'=> 'Paprika',
                'ubicacion' => '-17.3846,-66.1566',
                'celular' => '78512345',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Internacional',
                'contador_vistas' => 0,
                'user_id' => 1, // Maria Lopez
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'La Cantonata',
                'ubicacion' => '-17.3895,-66.1568',
                'celular' => '78234567',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Italiana',
                'contador_vistas' => 0,
                'user_id' => 2, // Carlos Mendez
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Casa de Campo',
                'ubicacion' => '-17.3875,-66.1598',
                'celular' => '78345678',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Boliviana',
                'contador_vistas' => 0,
                'user_id' => 3, // Andrea Garcia
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Sushi Itto',
                'ubicacion' => '-17.3867,-66.1543',
                'celular' => '78789012',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Japonesa',
                'contador_vistas' => 0,
                'user_id' => 4, // Jorge Fernandez
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Tunupa Restaurant',
                'ubicacion' => '-17.3923,-66.1612',
                'celular' => '78901234',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Boliviana',
                'contador_vistas' => 0,
                'user_id' => 5, // Laura Mamani
                'created_at' => now(),
                'updated_at' => now()
            ],
            /* [
                'nombre_restaurante'=> 'Veggie Life',
                'ubicacion' => 'Calle Salud 321',
                'celular' => '73216548',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Vegetariana',
                'contador_vistas' => 0,
                'user_id' => 4,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Burger Planet',
                'ubicacion' => 'Av. Rápida 99',
                'celular' => '77777777',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Hamburguesas',
                'contador_vistas' => 0,
                'user_id' => 4,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Dulce Encanto',
                'ubicacion' => 'Calle Pastel 14',
                'celular' => '78889999',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Postres',
                'contador_vistas' => 0,
                'user_id' => 4,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Pizzeria Napoli',
                'ubicacion' => 'Av. Central 55',
                'celular' => '72121212',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Italiana',
                'contador_vistas' => 0,
                'user_id' => 5,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Café Andino',
                'ubicacion' => 'Plaza Central 8',
                'celular' => '79998888',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Boliviana',
                'contador_vistas' => 0,
                'user_id' => 5,
                'created_at' => now(),
                'updated_at' => now()
            ], */
        ]);
    }
}
