<?php

namespace App\Http\Controllers;

use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $users = User::all();
        $data = [
            'mensaje' => 'Lista de usuarios',
            'users' => $users,
        ];
        return response()->json($data, 200);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {

    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $user = User::find($id);
        if (!$user) {
            $data = [
                "message" => "Usuario no encontrado",
                "status" => 404
            ];
            return response()->json($data,404);
        }
        $data = [
            'mensaje' => 'Detalles del usuario',
            'user' => $user,
        ];
        return response()->json($data, 200);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $user = User::find($id);
        if(!$user){
            $data = [
                "message" => "Estudiante no encontrado",
                "status" => 404
            ];
            return response()->json($data,404);
        }
        $validate = Validator::make($request->all(), [
            'email' => 'sometimes|required|email|unique:users,email,' . $id,
            'username' => 'sometimes|required|unique:users,username,' . $id,
            'celular' => 'sometimes|required|digits_between:8,15',
            'password' => 'sometimes|required|confirmed|min:8',
            'rol' => 'sometimes|required',
        ]);
        if($validate->fails()) {
            $data = [
                "message" => "Error de validación",
                "errors" => $validate->errors()
            ];
            return response()->json($data, 422);
        }

        $dataActualizar = [];

        if ($request->has('email')) {
            $dataActualizar['email'] = $request->email;
        }
        if ($request->has('username')) {
            $dataActualizar['username'] = $request->username;
        }
        if ($request->has('celular')) {
            $dataActualizar['celular'] = $request->celular;
        }
        if ($request->has('password')) {
            $dataActualizar['password'] = bcrypt($request->password);
        }
        if ($request->has('rol')) {
            $role = Role::where('nombre_rol', $request->rol)->first();
            if (!$role) {
                return response()->json(['mensaje' => 'Rol no encontrado'], 404);
            }
            $dataActualizar['role_id'] = $role->id;
        }

        $user->update($dataActualizar);

        /* $user->update([
            'email' => $request->email,
            'username' => $request->username,
            'celular' => $request->celular,
            'password' => bcrypt($request->password),
            'role_id' => $role->id,
        ]); */

        $data = [
            "message" => "Usuario editado",
            "user" => $user,
            "status" => 200
        ];
        return response()->json($data,200);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $user = User::find($id);
        if(!$user) {
            $data = [
                "message" => "Usuario no encontrado",
            ];
            return response()->json($data, 404);
        }

        $user->delete();

        $data = [
            "message" => "Usuario eliminado"
        ];
        return response()->json($data, 200);
    }
}
