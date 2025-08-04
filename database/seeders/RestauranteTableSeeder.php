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
                'nombre_restaurante'=> 'Restaurante America’s',
                'ubicacion' => 'Calle Bolívar, San Pedro, Cochabamba',
                'latitud' => -17.391440,
                'longitud' => -66.149140,
                'celular' => '71777777',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Comida típica',
                'contador_vistas' => 0,
                'user_id' => 1,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Restaurant Tunari Prado',
                'ubicacion' => 'Av. José Ballivián 676, Cochabamba',
                'latitud' => -17.386600,
                'longitud' => -66.157100,
                'celular' => '72888888',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Internacional',
                'contador_vistas' => 0,
                'user_id' => 2,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'DKFE Restaurante',
                'ubicacion' => 'Av. Pando 1143, Cochabamba',
                'latitud' => -17.400980,
                'longitud' => -66.042290,
                'celular' => '73456789',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Latinoamericana',
                'contador_vistas' => 0,
                'user_id' => 3,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Pampaku Wasi',
                'ubicacion' => 'Quillacollo, Cochabamba',
                'latitud' => -17.347450,
                'longitud' => -66.179230,
                'celular' => '78901234',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Carnes a la brasa',
                'contador_vistas' => 0,
                'user_id' => 4,
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'nombre_restaurante'=> 'Llajtaymanta Restaurante',
                'ubicacion' => 'Quillacollo, Cochabamba',
                'latitud' => -17.376960,
                'longitud' => -66.301290,
                'celular' => '76543210',
                'imagen' => null,
                'estado' => 0,
                'tematica' => 'Comida boliviana',
                'contador_vistas' => 0,
                'user_id' => 5,
                'created_at' => now(),
                'updated_at' => now()
            ]
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
