<?php

namespace App\Http\Controllers;

use App\Models\Menu;
use App\Models\Producto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProductoMenuController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        if ($request->has('menu_id')) {
            $menu = Menu::find($request->menu_id);
            if (!$menu) {
                return response()->json([
                    'success' => false,
                    'message' => 'Menú no encontrado'
                ], 404);
            }
            return response()->json([
                'sucess' => true,
                'message' => 'Productos del menú encontrados',
                'productos' => $menu->productos()->get()
            ]);
        }

        if ($request->has('restaurante_id')) {
            $menus = Menu::where('restaurante_id', $request->restaurante_id)->get();
            $productos = collect();
            foreach ($menus as $menu) {
                $productos = $productos->merge($menu->productos()->get());
            }
            return response()->json([
                'success' => true,
                'message' => 'Productos del restaurante encontrados',
                'productos' => $productos->unique('id')->values()
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Todos los productos',
            'productos' => Producto::all()
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'restaurante_id' => 'required|exists:restaurantes,id',
            'nombre' => 'required|string|max:255',
            'precio' => 'required|numeric|min:0',
            'imagen' => 'nullable|string',
            'descripcion' => 'nullable|string',
            'tipo' => 'required|integer|in:0,1',
            'disponible' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $validator->validated();

        $path = null;
        if ($request->hasFile('imagen')) {
            $path = Storage::disk('public')->putFile('productos', $request->file('imagen'));
        }

        DB::beginTransaction();
        try {
            //Crear uno o mas menus
            /* $menu = Menu::create([
                'restaurante_id' => $data['restaurante_id'],
                'nombre' => $data['nombre_menu'],
            ]); */

            $menu = Menu::firstOrCreate(['restaurante_id' => $data['restaurante_id']]);

            $producto = Producto::firstOrCreate([
                'nombre_producto' =>   $data['nombre']
            ]);

            $menu->productos()->attach($producto->id, [
                'descripcion' => $data['descripcion'] ?? null,
                'tipo' => $data['tipo'],
                'precio' => $data['precio'],
                'imagen' => $path,
                'disponible' => $data['disponible'] ?? 1,
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Producto creado y asociado al menú correctamente',
                'producto' => $producto,
                'menu' => $menu,
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Error al crear producto: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show($menu_id, $producto_id)
    {
        $menu = Menu::find($menu_id);
        if (!$menu) {
            return response()->json(['message' => 'Menú no encontrado'], 404);
        }

        $producto = $menu->productos()
            ->where('producto_id', $producto_id)
            ->first();

        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado en este menú'], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Producto encontrado en el menú',
            'producto' => $producto
        ], 200);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $menu_id, $producto_id)
    {
        $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:255',
            'precio' => 'required|numeric|min:0',
            'imagen' => 'nullable|string',
            'descripcion' => 'nullable|string',
            'disponible' => 'boolean',
            'tipo' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $menu = Menu::find($menu_id);
        if (!$menu) {
            return response()->json([
                'success' => false,
                'message' => 'Menú no encontrado'
            ], 404);
        }

        $producto = Producto::find($producto_id);
        if (!$producto) {
            return response()->json([
                'success' => false,
                'message' => 'Producto no encontrado'
            ], 404);
        }

        $productoAsociado = $menu->productos()->where('producto_id', $producto_id)->exists();
        if (!$productoAsociado) {
            return response()->json([
                'success' => false,
                'message' => 'Producto no asociado a este menú'
            ], 404);
        }

        $producto->update([
            'nombre_producto' => $request->input('nombre'),
        ]);

        if ($request->hasFile('imagen')) {
            $imagenActual = $menu->productos()->where('producto_id', $producto_id)->first()->pivot->imagen ?? null;
            if ($imagenActual) {
                Storage::delete($imagenActual);
            }
            $path = Storage::disk('public')->putFile('restaurantes', $request->file('imagen'));
            $atributosAEditar['imagen'] = $path;
        }

        $menu->productos()->updateExistingPivot($producto_id, [
            'precio' => $request->input('precio'),
            'imagen' => $path,
            'descripcion' => $request->input('descripcion'),
            'disponible' => $request->input('disponible', true),
            'tipo' => $request->input('tipo'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Producto y datos en menú actualizados correctamente',
            'producto' => $producto,
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, $menu_id, $producto_id = null)
    {
        $menu = Menu::find($menu_id);
        if (!$menu) {
            return response()->json([
                'success' => false,
                'message' => 'Menú no encontrado'
            ], 404);
        }

        if ($producto_id) {
            $menu->productos()->detach($producto_id);
            return response()->json([
                'success' => true,
                'message' => 'Producto eliminado del menú'
            ], 200);
        }

        return response()->json([
            'success' => false,
            'message' => 'Debe especificar el producto para eliminar la asociación'
        ], 400);
    }
}
