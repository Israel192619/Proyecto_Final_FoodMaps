<?php

namespace App\Http\Controllers;

use App\Models\Menu;
use App\Models\Restaurante;
use Illuminate\Http\Request;

class MenuController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index($restaurante_id)
    {
        $restaurante = Restaurante::find($restaurante_id);

        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'mensaje' => 'Restaurante no encontrado',
            ], 404);
        }

        $menus = Menu::where('restaurante_id', $restaurante_id)->get();

        return response()->json([
            'success' => true,
            'mensaje' => 'Lista de menús del restaurante',
            'data' => $menus,
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request, $restaurante_id)
    {
        $restaurante = Restaurante::find($restaurante_id);
        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'mensaje' => 'Restaurante no encontrado',
            ], 404);
        }
        $tieneMenu = $restaurante->menu;
        if($tieneMenu){
            return response()->json([
                'success' => false,
                'mensaje' => 'Este restaurante ya tiene un menú asignado',
            ],400);
        }
        $menu = new Menu();
        $menu->restaurante_id = $restaurante_id;
        $menu->save();

        return response()->json([
            'success' => true,
            'mensaje' => 'Menú creado automáticamente',
            'data' => $menu,
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show($restaurante_id, $id)
    {
        $menu = Menu::where('id', $id)
                    ->where('restaurante_id', $restaurante_id)
                    ->first();

        if (!$menu) {
            return response()->json([
                'success' => false,
                'mensaje' => 'Menú no encontrado para este restaurante',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'mensaje' => 'Menú encontrado',
            'data' => $menu,
        ], 200);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        return response()->json([
            'success' => false,
            'mensaje' => 'Aun no puede actualizar un menu',
        ], 400);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        return response()->json([
            'success' => false,
            'mensaje' => 'Aun no puede eliminar un menu',
        ], 400);
    }
}
