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
                'email' => 'maria.lopez@gmail.com',
                'username' => 'MariaLopez',
                'celular' => '72015846',
                'role_id' => 1,
                'password' => bcrypt('Maria2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'carlos.mendez@hotmail.com',
                'username' => 'CarlosM',
                'celular' => '76589021',
                'role_id' => 2,
                'password' => bcrypt('Carlos2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'andrea.garcia@yahoo.com',
                'username' => 'AndreaG',
                'celular' => '73124589',
                'role_id' => 1,
                'password' => bcrypt('Andrea2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'jorge.fernandez@gmail.com',
                'username' => 'JorgeF',
                'celular' => '74985632',
                'role_id' => 2,
                'password' => bcrypt('Jorge2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'laura.mamani@gmail.com',
                'username' => 'LauraM',
                'celular' => '72233456',
                'role_id' => 1,
                'password' => bcrypt('Laura2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'fernando.perez@hotmail.com',
                'username' => 'FerPerez',
                'celular' => '79014567',
                'role_id' => 2,
                'password' => bcrypt('Fernando2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'valeria.castro@gmail.com',
                'username' => 'ValeC',
                'celular' => '73580914',
                'role_id' => 1,
                'password' => bcrypt('Valeria2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'diego.alarcon@gmail.com',
                'username' => 'DiegoA',
                'celular' => '77891245',
                'role_id' => 2,
                'password' => bcrypt('Diego2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'karla.sanchez@gmail.com',
                'username' => 'KarlaS',
                'celular' => '72122334',
                'role_id' => 1,
                'password' => bcrypt('Karla2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
            [
                'email' => 'ricardo.rios@gmail.com',
                'username' => 'RicardoR',
                'celular' => '77654321',
                'role_id' => 2,
                'password' => bcrypt('Ricardo2025*'),
                'created_at' => now(),
                'updated_at' => now()
            ],
        ]);
    }
}
