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
                'nombre_restaurante'=> 'La Trattoria Bella',
                'ubicacion' => 'Av. Italia 45',
                'celular' => '71234567',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Italiana',
                'contador_vistas' => 0,
                'user_id' => 1,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Sabor Oriental',
                'ubicacion' => 'Calle Japón 88',
                'celular' => '76543210',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'China',
                'contador_vistas' => 0,
                'user_id' => 1,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Tierra Gaucha',
                'ubicacion' => 'Av. Libertador 1010',
                'celular' => '74321109',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Parrillada',
                'contador_vistas' => 0,
                'user_id' => 3,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'El Mexicano Loco',
                'ubicacion' => 'Calle Tacos 12',
                'celular' => '78945612',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Mexicana',
                'contador_vistas' => 0,
                'user_id' => 3,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Sabores del Mar',
                'ubicacion' => 'Zona Costanera',
                'celular' => '70123456',
                'imagen' => null,
                'estado' => 1,
                'tematica' => 'Mariscos',
                'contador_vistas' => 0,
                'user_id' => 3,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Veggie Life',
                'ubicacion' => 'Calle Salud 321',
                'celular' => '73216548',
                'imagen' => null,
                'estado' => 1,
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
                'estado' => 1,
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
                'estado' => 1,
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
                'estado' => 1,
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
                'estado' => 1,
                'tematica' => 'Boliviana',
                'contador_vistas' => 0,
                'user_id' => 5,
                'created_at' => now(),
                'updated_at' => now()
            ],
        ]);
    }
}
