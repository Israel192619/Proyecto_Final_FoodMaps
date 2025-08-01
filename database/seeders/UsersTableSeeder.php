<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class UsersTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('users')->insert([
            [
                'email' => 'prueba1@gmail.com',
                'username' => 'prueba1',
                'celular' => '76543210',
                'role_id' => 1,
                'password' => bcrypt(   'prueba1*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'prueba2@gmail.com',
                'username' => 'prueba2',
                'celular' => '234544345',
                'role_id' => 2,
                'password' => bcrypt(   'prueba2*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
        ]);
    }
}
