<?php

namespace App\Http\Controllers;

use App\Models\Menu;
use App\Models\Restaurante;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class RestauranteController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $user = auth()->user();
        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'No está autorizado'
            ], 401);
        }
        $restaurantes = Restaurante::where('user_id', operator: $user->id)->with('menu')->get();
        $data = $restaurantes->map(function ($restaurante) {
            return [
                'id' => $restaurante->id,
                'nombre_restaurante' => $restaurante->nombre_restaurante,
                'ubicacion' => $restaurante->ubicacion,
                'celular' => $restaurante->celular,
                'imagen' => $restaurante->imagen ? $restaurante->imagen : null,
                'estado' => $restaurante->estado,
                'tematica' => $restaurante->tematica,
                'contador_vistas' => $restaurante->contador_vistas ?? 0,
                'user_id' => $restaurante->user_id,
                "created_at" => $restaurante->created_at->format("Y-m-d H:i:s"),
                "menu_id" => $restaurante->menu ? $restaurante->menu->id : null
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Lista de restaurantes propios',
            'data' => $data,
            'total' => $restaurantes->count()
        ], 200);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validate = Validator::make($request->all(), [
            'nombre_restaurante' => 'required|string|max:255',
            'ubicacion' => 'required|string|max:255',
            'celular' => 'required|string|max:15',
            'imagen' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'estado' => 'required',
            'tematica' => 'required|string|max:255',
            //'contador_vistas' => 'nullable|integer',
        ]);

        if ($validate->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validate->errors()
            ], 422);
        }

        $path = null;
        if ($request->hasFile('imagen')) {
            $path = Storage::disk('public')->putFile('restaurantes', $request->file('imagen'));
        }

        DB::beginTransaction();

        try {
            $restaurante = new Restaurante();
            $restaurante->nombre_restaurante = $request->nombre_restaurante;
            $restaurante->ubicacion = $request->ubicacion;
            $restaurante->celular = $request->celular;
            $restaurante->imagen = $path;
            $restaurante->estado = $request->estado;
            $restaurante->tematica = $request->tematica;
            //$restaurante->contador_vistas = $request->contador_vistas ?? 0;
            $restaurante->user_id = auth()->id();
            $restaurante->save();

            $menu = new Menu();
            $menu->restaurante_id = $restaurante->id;
            $menu->save();

            DB::commit();

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al crear el restaurante o el menú',
                'error' => $e->getMessage()
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Restaurante creado exitosamente',
            'data' => [
                'id' => $restaurante->id,
                'nombre_restaurante' => $restaurante->nombre_restaurante,
                'ubicacion' => $restaurante->ubicacion,
                'celular' => $restaurante->celular,
                'imagen' => $restaurante->imagen ? $restaurante->imagen : null,
                'estado' => $restaurante->estado,
                'tematica' => $restaurante->tematica,
                'contador_vistas' => $restaurante->contador_vistas ?? 0,
                'user_id' => $restaurante->user_id,
                "created_at" => $restaurante->created_at->format("Y-m-d H:i:s"),
                "menu_id" => $menu->id
            ],
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $user = auth()->user();
        $restaurante = Restaurante::with('menu')->find($id);

        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurante no encontrado'
            ], 404);
        }

        if ($restaurante->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado. Este restaurante no te pertenece.'
            ], 403);
        }

        $data = [
            'id' => $restaurante->id,
            'nombre_restaurante' => $restaurante->nombre_restaurante,
            'ubicacion' => $restaurante->ubicacion,
            'celular' => $restaurante->celular,
            'imagen' => $restaurante->imagen ? $restaurante->imagen : null,
            'estado' => $restaurante->estado,
            'tematica' => $restaurante->tematica,
            'contador_vistas' => $restaurante->contador_vistas ?? 0,
            'user_id' => $restaurante->user_id,
            'created_at' => $restaurante->created_at->format("Y-m-d H:i:s"),
            'menu_id' => $restaurante->menu ? $restaurante->menu->id : null,
        ];

        return response()->json([
            'success' => true,
            'message' => 'Detalles del restaurante',
            'data' => $data
        ], 200);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $user = auth()->user();
        $restaurante = Restaurante::with('menu')->find($id);

        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurante no encontrado'
            ], 404);
        }

        if ($restaurante->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado. Este restaurante no te pertenece.'
            ], 403);
        }

        $validate = Validator::make($request->all(), [
            'nombre_restaurante' => 'sometimes|required|string|max:255',
            'ubicacion' => 'sometimes|required|string|max:255',
            'celular' => 'sometimes|required|string|max:15',
            'imagen' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'estado' => 'sometimes|required',
            'tematica' => 'sometimes|required|string|max:255',
            //'contador_vistas' => 'nullable|integer',
        ]);

        if ($validate->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validate->errors()
            ], 422);
        }

        $atributosAEditar = [];

        if ($request->hasFile('imagen')) {
            if ($restaurante->imagen) {
                Storage::delete($restaurante->imagen);
            }
            $path = Storage::disk('public')->putFile('restaurantes', $request->file('imagen'));
            $atributosAEditar['imagen'] = $path;
        }

        $campos = [
            'nombre_restaurante',
            'ubicacion',
            'celular',
            'estado',
            'tematica',
            'contador_vistas'
        ];

        foreach ($campos as $campo) {
            if ($request->has($campo)) {
                $atributosAEditar[$campo] = $request->input($campo);
            }
        }

        if (empty($atributosAEditar)) {
            return response()->json([
                'success' => false,
                'message' => 'No se proporcionaron datos para actualizar'
            ], 400);
        }

        if (!$restaurante->update($atributosAEditar)) {
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar el restaurante'
            ], 500);
        }
        $data = [
                'id' => $restaurante->id,
                'nombre_restaurante' => $restaurante->nombre_restaurante,
                'ubicacion' => $restaurante->ubicacion,
                'celular' => $restaurante->celular,
                'imagen' => $restaurante->imagen ? $restaurante->imagen : null,
                'estado' => $restaurante->estado,
                'tematica' => $restaurante->tematica,
                'contador_vistas' => $restaurante->contador_vistas ?? 0,
                'user_id' => $restaurante->user_id,
                "created_at" => $restaurante->created_at->format("Y-m-d H:i:s"),
                'menu_id' => $restaurante->menu ? $restaurante->menu->id : null,
        ];

        return response()->json([
            'success' => true,
            'message' => 'Restaurante editado correctamente',
            'data' => $data
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $user = auth()->user();
        $restaurante = Restaurante::find($id);
        if(!$restaurante) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurante no encontrado'
            ], 404);
        }
        if ($restaurante->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado. Este restaurante no te pertenece.'
            ], 403);
        }

        $restaurante->delete();

        return response()->json([
            'success' => true,
            'message' => 'Restaurante eliminado exitosamente'
        ], 200);
    }

    public function publicIndex()
    {
        $restaurantes = Restaurante::with('menu')->get();
        if ($restaurantes->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'No hay restaurantes disponibles'
            ], 404);
        }
        $data = $restaurantes->map(function ($restaurante) {
            return [
                'id' => $restaurante->id,
                'nombre_restaurante' => $restaurante->nombre_restaurante,
                'ubicacion' => $restaurante->ubicacion,
                'celular' => $restaurante->celular,
                'imagen' => $restaurante->imagen ? $restaurante->imagen : null,
                'estado' => $restaurante->estado,
                'tematica' => $restaurante->tematica,
                'contador_vistas' => $restaurante->contador_vistas ?? 0,
                'user_id' => $restaurante->user_id,
                "created_at" => $restaurante->created_at->format("Y-m-d H:i:s"),
                "menu_id" => $restaurante->menu ? $restaurante->menu->id : null
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Lista de todos los restaurantes',
            'data' => $data,
            'total' => $restaurantes->count()
        ], 200);
    }

    public function showPublic($id, Request $request)
    {
        try {
            $restaurante = Restaurante::with('menu')->findOrFail($id);

            if ($request->has('public') && $request->public == 'true') {
                if ($restaurante->estado !== 1) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Restaurante no está abierto'
                    ], 404);
                }
                $restaurante->increment('contador_vistas');
            }

            $data = [
                    'id' => $restaurante->id,
                    'nombre_restaurante' => $restaurante->nombre_restaurante,
                    'ubicacion' => $restaurante->ubicacion,
                    'celular' => $restaurante->celular,
                    'imagen' => $restaurante->imagen ? $restaurante->imagen : null,
                    'tematica' => $restaurante->tematica,
                    'estado' => $restaurante->estado,
                    'estado_text' => $restaurante->estado ? 'ABIERTO' : 'CERRADO',
                    'contador_vistas' => $restaurante->contador_vistas,
                    'updated_at' => $restaurante->updated_at,
                    'menu_id' => $restaurante->menu ? $restaurante->menu->id : null,
            ];

            return response()->json([
                'success' => true,
                'message' => 'Detalles del restaurante',
                'data' => $data
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }

    public function changeStatus(Request $request, $id)
    {
        try {
            $user = auth()->user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'No está autorizado. Token requerido'
                ], 401);
            }
            $validate = Validator::make($request->all(), [
                'estado_actual' => 'required|integer|in:0,1'
            ]);

            if ($validate->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Error de validación',
                    'errors' => $validate->errors()
                ], 422);
            }
            $restaurante = Restaurante::find($id);
            if (!$restaurante) {
                return response()->json([
                    'success' => false,
                    'message' => 'Restaurante no encontrado'
                ], 404);
            }
            if ($restaurante->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'No autorizado. Solo el propietario puede cambiar el estado de este restaurante'
                ], 403);
            }
            if ($restaurante->estado != $request->estado_actual) {
                return response()->json([
                    'success' => false,
                    'message' => 'El estado actual proporcionado no coincide con el estado real del restaurante',
                    'data' => [
                        'estado_real' => $restaurante->estado,
                        'estado_enviado' => $request->estado_actual
                    ]
                ], 400);
            }

            $nuevoEstado = $restaurante->estado == 1 ? 0 : 1;
            $estadoAnterior = $restaurante->estado;

            $restaurante->estado = $nuevoEstado;
            $restaurante->save();

            return response()->json([
                'success' => true,
                'message' => 'Estado cambiado exitosamente',
                'data' => [
                    'estado' => $nuevoEstado,
                    'estado_text' => $nuevoEstado ? 'ABIERTO' : 'CERRADO'
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error interno del servidor: ' . $e->getMessage()
            ], 500);
        }
    }
    public function obtenerEstadoRestaurante($id)
    {
        try {
            $restaurant = Restaurante::findOrFail($id);
            return response()->json([
                'success' => true,
                'message' => 'Estado del restaurante',
                'data' => [
                    'id' => $restaurant->id,
                    'nombre_restaurante' => $restaurant->nombre_restaurante,
                    'estado' => $restaurant->estado,
                    'estado_text' => $restaurant->estado ? 'ABIERTO' : 'CERRADO',
                    'updated_at' => $restaurant->updated_at
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }
}
