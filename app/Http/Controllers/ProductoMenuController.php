<?php

namespace App\Http\Controllers;

use App\Models\Menu;
use App\Models\Producto;
use App\Models\Restaurante;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProductoMenuController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request, $restaurante_id, $menu_id)
    {
        $restaurante = Restaurante::where('id', $restaurante_id)
            ->first();

        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurante no encontrado'
            ], 404);
        }

        $menu = Menu::where('id', $menu_id)
            ->where('restaurante_id', $restaurante_id)
            ->first();

        if (!$menu) {
            return response()->json([
                'success' => false,
                'message' => 'Menú no encontrado para este restaurante'
            ], 404);
        }

        $productos = $menu->productos()->get()->map(function ($producto) use ($menu, $restaurante_id) {
            return [
                'producto_id' => $producto->id,
                'menu_id' => $menu->id,
                'nombre_producto' => $producto->nombre_producto,
                 'precio' => isset($producto->pivot->precio) ? (float) $producto->pivot->precio : null,
                'imagen' => $producto->pivot->imagen ? url('storage/' . $producto->pivot->imagen) : null,
                'descripcion' => $producto->pivot->descripcion,
                'tipo' => isset($producto->pivot->tipo) ? (int) $producto->pivot->tipo : null,
                'disponible' => $producto->pivot->disponible,
                'restaurante_id' => (int) $restaurante_id,
                'created_at' => $producto->created_at->format("Y-m-d H:i:s"),
            ];
        });
        if($productos->isEmpty()){
            return response()->json([
                'success' => false,
                'message' => 'No existen productos en el menu',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Productos del menú encontrados',
            'data' => $productos
        ], 200);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request, $restaurante_id, $menu_id)
    {
        $validate = Validator::make($request->all(), [
            'nombre' => 'required|string|max:255',
            'precio' => 'required|numeric|min:0',
            'imagen' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'descripcion' => 'nullable|string',
            'tipo' => 'required|integer|in:0,1',
            'disponible' => 'boolean',
        ]);

        if ($validate->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validate->errors()
            ], 422);
        }

        $restaurante = Restaurante::find($restaurante_id);
        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurante no encontrado'
            ], 404);
        }

        $menu = Menu::where('id', $menu_id)
                    ->where('restaurante_id', $restaurante_id)
                    ->first();

        if (!$menu) {
            return response()->json([
                'success' => false,
                'message' => 'Menú no encontrado para este restaurante'
            ], 404);
        }

        DB::beginTransaction();

        try {
            $producto = Producto::where('nombre_producto', $request->nombre)->first();

            if (!$producto) {
                $producto = new Producto();
                $producto->nombre_producto = $request->nombre;
                $producto->save();
            }
            $productoYaAsociado = $menu->productos()->where('producto_id', $producto->id)->exists();
            if ($productoYaAsociado) {
                return response()->json([
                    'success' => false,
                    'message' => 'El producto ya está asociado a este menú',
                ], 409);
            }

            $path = null;
            if ($request->hasFile('imagen')) {
                $path = Storage::disk('public')->putFile('productos', $request->file('imagen'));
            }

            $menu->productos()->attach($producto->id, [
                'precio' => $request->precio,
                'imagen' => $path,
                'descripcion' => $request->descripcion ?? null,
                'tipo' => $request->tipo,
                'disponible' => $request->disponible ?? 1,
            ]);

            DB::commit();

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al crear o asociar el producto',
                'error' => $e->getMessage()
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Producto asociado al menú exitosamente',
            'data' => [
                'id' => $producto->id,
                'nombre_producto' => $producto->nombre_producto,
                'precio' => $request->precio,
                'imagen' => $path ? url('storage/' . $path) : null,
                'descripcion' => $request->descripcion,
                'tipo' => $request->tipo,
                'disponible' => $request->disponible ?? 1,
                'menu_id' => $menu->id,
                'restaurante_id' => $restaurante_id,
                "created_at" => $producto->created_at->format("Y-m-d H:i:s"),
            ],
        ], 201);
    }


    /**
     * Display the specified resource.
     */
    public function show($restaurante_id, $menu_id, $producto_id)
    {
        $restaurante = Restaurante::find($restaurante_id);
        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurante no encontrado'
            ], 404);
        }

        $menu = Menu::where('id', $menu_id)
                    ->where('restaurante_id', $restaurante_id)
                    ->first();

        if (!$menu) {
            return response()->json([
                'success' => false,
                'message' => 'Menú no encontrado para este restaurante'
            ], 404);
        }

        $producto = $menu->productos()
                        ->where('producto_id', $producto_id)
                        ->first();

        if (!$producto) {
            return response()->json([
                'success' => false,
                'message' => 'Producto no encontrado en este menú'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Producto encontrado en el menú',
            'data' => [
                'producto_id' => $producto->id,
                'nombre_producto' => $producto->nombre_producto,
                'descripcion' => $producto->pivot->descripcion ?? null,
                'precio' => (float) ($producto->pivot->precio ?? 0),
                'imagen' => $producto->pivot->imagen ? url('storage/' . $producto->pivot->imagen) : null,
                'tipo' => (int) ($producto->pivot->tipo ?? 0),
                'disponible' => (bool) ($producto->pivot->disponible ?? true),
                'menu_id' => (int) $menu->id,
                'restaurante_id' => (int) $restaurante_id,
                'created_at' => $producto->created_at->format('Y-m-d H:i:s'),
            ],
        ], 200);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $restaurante_id, $menu_id, $producto_id)
    {
        $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:255',
            'precio' => 'required|numeric|min:0',
            'imagen' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'descripcion' => 'nullable|string',
            'disponible' => 'boolean',
            'tipo' => 'nullable|integer|in:0,1',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $restaurante = Restaurante::find($restaurante_id);
        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurante no encontrado'
            ],  404);
        }

        $menu = Menu::where('id', $menu_id)->where('restaurante_id', $restaurante_id)->first();
        if (!$menu) {
            return response()->json([
                'success' => false,
                'message' => 'Menú no encontrado para este restaurante'
            ], 404);
        }

        $productoActual = $menu->productos()->where('producto_id', $producto_id)->first();
        if (!$productoActual) {
            return response()->json([
                'success' => false,
                'message' => 'Producto no asociado a este menú'
            ], 404);
        }
        $nuevoNombre = $request->input('nombre');
        $path = $productoActual->pivot->imagen ?? null;

        $productoDuplicado = $menu->productos()
            ->where('nombre_producto', $nuevoNombre)
            ->where('producto_id', '!=', $producto_id)
            ->exists();

        if ($productoDuplicado) {
            return response()->json([
                'success' => false,
                'message' => 'El restaurante ya tiene un producto con ese nombre en este menú'
            ], 422);
        }

        if ($nuevoNombre !== $productoActual->nombre_producto) {
            $productoExistente = Producto::where('nombre_producto', $nuevoNombre)->first();

            if ($productoExistente) {
                $menu->productos()->detach($producto_id);

                if ($request->hasFile('imagen')) {
                    if ($path) {
                        Storage::disk('public')->delete($path);
                    }
                    $path = Storage::disk('public')->putFile('productos', $request->file('imagen'));
                }

                $menu->productos()->attach($productoExistente->id, [
                    'precio' => $request->precio,
                    'imagen' => $path,
                    'descripcion' => $request->descripcion,
                    'disponible' => $request->disponible ?? true,
                    'tipo' => $request->tipo,
                ]);

                $productoParaRespuesta = $productoExistente;
            } else {
                $nuevoProducto = Producto::create(['nombre_producto' => $nuevoNombre]);

                $menu->productos()->detach($producto_id);

                if ($request->hasFile('imagen')) {
                    if ($path) {
                        Storage::disk('public')->delete($path);
                    }
                    $path = Storage::disk('public')->putFile('productos', $request->file('imagen'));
                }

                $menu->productos()->attach($nuevoProducto->id, [
                    'precio' => $request->precio,
                    'imagen' => $path,
                    'descripcion' => $request->descripcion,
                    'disponible' => $request->disponible ?? true,
                    'tipo' => $request->tipo,
                ]);

                $productoParaRespuesta = $nuevoProducto;
            }
        } else {
            if ($request->hasFile('imagen')) {
                if ($path) {
                    Storage::disk('public')->delete($path);
                }
                $path = Storage::disk('public')->putFile('productos', $request->file('imagen'));
            }

            $menu->productos()->updateExistingPivot($producto_id, [
                'precio' => $request->input('precio'),
                'imagen' => $path,
                'descripcion' => $request->input('descripcion'),
                'disponible' => $request->input('disponible', true),
                'tipo' => $request->input('tipo'),
            ]);

            $productoParaRespuesta = $productoActual;
        }

        return response()->json([
            'success' => true,
            'message' => 'Producto actualizado correctamente',
            'data' => [
                'id' => (int) $productoParaRespuesta->id,
                'menu_id' => (int) $menu->id,
                'nombre_producto' => (string) $productoParaRespuesta->nombre_producto,
                'precio' => (float) $request->input('precio'),
                'imagen' => $path ? url('storage/' . $path) : null,
                'descripcion' => $request->input('descripcion') !== null ? (string) $request->input('descripcion') : null,
                'tipo' => (int) $request->input('tipo'),
                'disponible' => (bool) $request->input('disponible', true),
                'restaurante_id' => (int) $restaurante_id,
                'updated_at' => now()->format('Y-m-d H:i:s'),
            ],
        ], 200);
    }



    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, $restaurante_id, $menu_id, $producto_id)
    {
        $restaurante = Restaurante::find($restaurante_id);
        if (!$restaurante) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurante no encontrado'
            ], 404);
        }

        $menu = Menu::where('id', $menu_id)
                    ->where('restaurante_id', $restaurante_id)
                    ->first();
        if (!$menu) {
            return response()->json([
                'success' => false,
                'message' => 'Menú no encontrado para este restaurante'
            ], 404);
        }

        $productoAsociado = $menu->productos()->where('producto_id', $producto_id)->exists();
        if (!$productoAsociado) {
            return response()->json([
                'success' => false,
                'message' => 'Producto no asociado a este menú'
            ], 404);
        }

        $menu->productos()->detach($producto_id);

        return response()->json([
            'success' => true,
            'message' => 'Producto eliminado del menú'
        ], 200);
    }
}

