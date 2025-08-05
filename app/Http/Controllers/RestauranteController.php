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
            return response()->json(['error' => 'No está autorizado'], 401);
        }
        $restaurantes = Restaurante::where('user_id', $user->id)->get();
        $data = [
            'mensaje' => 'Lista de restaurantes propios',
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
            'latitud' => 'nullable|numeric',
            'longitud' => 'nullable|numeric',
            'celular' => 'required|string|max:15',
            'imagen' => 'nullable',
            'estado' => 'required',
            'tematica' => 'required|string|max:255',
            'contador_vistas' => 'nullable|integer',
            //'user_id' => 'required|exists:users,id',
        ]);
        if($validate->fails()) {
            $data = [
                "message" => "Error de validación",
                "errors" => $validate->errors()
            ];
            return response()->json($data, 422);
        }

        //$restaurante = Restaurante::create($request->all());
        $restaurante = new Restaurante;
        $restaurante->nombre_restaurante = $request->nombre_restaurante;
        $restaurante->ubicacion = $request->ubicacion;
        $restaurante->latitud = $request->latitud;
        $restaurante->longitud = $request->longitud;
        $restaurante->celular = $request->celular;
        $restaurante->imagen = $request->imagen;
        $restaurante->estado = $request->estado;
        $restaurante->tematica = $request->tematica;
        $restaurante->contador_vistas = $request->contador_vistas;
        $restaurante->user_id = auth()->user()->id;
        $restaurante->save();

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
        $user = auth()->user();
        $restaurante = Restaurante::find($id);
        if (!$restaurante) {
            $data = [
                "message" => "Restaurante no encontrado",
                "status" => 404
            ];
            return response()->json($data,404);
        }
        if ($restaurante->user_id !== $user->id) {
            return response()->json(['error' => 'No autorizado. Este restaurante no te pertenece.'], 403);
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
        $user = auth()->user();
        $restaurante = Restaurante::find($id);
        if(!$restaurante){
            $data = [
                "message" => "Restaurante no encontrado",
                "status" => 404
            ];
            return response()->json($data,404);
        }
        if ($restaurante->user_id !== $user->id) {
            return response()->json(['error' => 'No autorizado. Este restaurante no te pertenece.'], 403);
        }
        $validate = Validator::make($request->all(), [
            'nombre_restaurante' => 'required|string|max:255',
            'ubicacion' => 'required|string|max:255',
            'celular' => 'required|string|max:15',
            'imagen' => 'nullable',
            'estado' => 'required',
            'tematica' => 'required|string|max:255',
            'contador_vistas' => 'nullable|integer',
            //'user_id' => 'required|exists:users,id',
        ]);
        if($validate->fails()) {
            $data = [
                "message" => "Error de validación",
                "errors" => $validate->errors()
            ];
            return response()->json($data, 422);
        }
        //$restaurante->update($request->all());
        $restaurante->update([
            'nombre_restaurante' => $request->nombre_restaurante,
            'ubicacion' => $request->ubicacion,
            'latitud' => $request->latitud,
            'longitud' => $request->longitud,
            'celular' => $request->celular,
            'imagen' => $request->imagen,
            'estado' => $request->estado,
            'tematica' => $request->tematica,
            'contador_vistas' => $request->contador_vistas ?? 0,
            'user_id' => auth()->user()->id,
        ]);

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
        $user = auth()->user();
        $restaurante = Restaurante::find($id);
        if(!$restaurante) {
            $data = [
                "message" => "Restaurante no encontrado",
            ];
            return response()->json($data, 404);
        }
        if ($restaurante->user_id !== $user->id) {
            return response()->json(['error' => 'No autorizado. Este restaurante no te pertenece.'], 403);
        }

        $restaurante->delete();

        $data = [
            "message" => "Restaurante eliminado"
        ];
        return response()->json($data, 200);
    }

    public function publicIndex(){
        $restaurantes = Restaurante::where('estado', 1)->get();
        if($restaurantes->isEmpty()) {
            return response()->json(['mensaje' => 'No hay restaurantes activos'], 404);
        }
        $data = [
            'mensaje' => 'Lista de restaurantes activos',
            'restaurantes' => $restaurantes,
        ];
        return response()->json($data, 200);
    }

    public function showPublic($id)
    {
        $restaurante = Restaurante::find($id);
        if (!$restaurante || $restaurante->estado !== 1) {
            return response()->json(['mensaje' => 'Restaurante no encontrado o no activo'], 404);
        }
        $data = [
            'mensaje' => 'Detalles del restaurante',
            'restaurante' => $restaurante,
        ];
        return response()->json($data, 200);
    }
}
