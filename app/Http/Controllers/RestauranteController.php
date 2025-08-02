<?php

namespace App\Http\Controllers;

use App\Models\Restaurante;
use Illuminate\Http\Request;
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
            return response()->json(['message' => 'Unauthorized'], 401);
        }
        $restaurantes = Restaurante::where('user_id', $user->id)->get();
        $data = [
            'mensaje' => 'Lista de restaurantes',
            'restaurantes' => $restaurantes,
        ];
        return response()->json($data, 200);
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
            'imagen' => 'nullable',
            'estado' => 'required',
            'tematica' => 'required|string|max:255',
            'contador_vistas' => 'nullable|integer',
            'user_id' => 'required|exists:users,id',
        ]);
        if($validate->fails()) {
            $data = [
                "message" => "Error de validación",
                "errors" => $validate->errors()
            ];
            return response()->json($data, 422);
        }

        $restaurante = Restaurante::create($request->all());
        if(!$restaurante) {
            $data = [
                "message" => "Error al crear el restaurante",
            ];
            return response()->json($data, 500);
        }
        $data = [
            "message" => "Restaurante creado exitosamente",
            "restaurante" => $restaurante
        ];
        return response()->json($data, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $restaurante = Restaurante::find($id);
        if (!$restaurante) {
            $data = [
                "message" => "Restaurante no encontrado",
                "status" => 404
            ];
            return response()->json($data,404);
        }
        $data = [
            'mensaje' => 'Detalles del restaurante',
            'restaurante' => $restaurante,
        ];
        return response()->json($data, 200);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $restaurante = Restaurante::find($id);
        if(!$restaurante){
            $data = [
                "message" => "Estudiante no encontrado",
                "status" => 404
            ];
            return response()->json($data,404);
        }
        $validate = Validator::make($request->all(), [
            'nombre_restaurante' => 'required|string|max:255',
            'ubicacion' => 'required|string|max:255',
            'celular' => 'required|string|max:15',
            'imagen' => 'nullable',
            'estado' => 'required',
            'tematica' => 'required|string|max:255',
            'contador_vistas' => 'nullable|integer',
            'user_id' => 'required|exists:users,id',
        ]);
        if($validate->fails()) {
            $data = [
                "message" => "Error de validación",
                "errors" => $validate->errors()
            ];
            return response()->json($data, 422);
        }
        $restaurante->update($request->all());

        $data = [
            "message" => "Restaurante editado correctamente",
            "restaurante" => $restaurante,
            "status" => 200
        ];
        return response()->json($data,200);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $restaurante = Restaurante::find($id);
        if(!$restaurante) {
            $data = [
                "message" => "Restaurante no encontrado",
            ];
            return response()->json($data, 404);
        }

        $restaurante->delete();

        $data = [
            "message" => "Restaurante eliminado"
        ];
        return response()->json($data, 200);
    }
}
