<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
//use Validator;
use Illuminate\Support\Facades\Validator;


class AuthController extends Controller
{

    /**
     * Register a User.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function register() {
        //dd(request()->all());
        $validator = Validator::make(request()->all(), [
            //'name' => 'required',
            'email' => 'required|email|unique:users',
            'username' => 'required|unique:users',
            'celular' => 'required|digits_between:8,15',
            'password' => 'required|confirmed|min:8',
            'role_id' => 'required',
        ]);

        if($validator->fails()){
            return response()->json($validator->errors()->toJson(), 400);
        }

        $user = new User;
        //$user->name = request()->name;
        $user->email = request()->email;
        $user->username = request()->username;
        $user->celular = request()->celular;
        $user->password = bcrypt(request()->password);
        $user->role_id = request()->role_id;
        $user->save();

        return response()->json($user, 201);
    }


    /**
     * Get a JWT via given credentials.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function login()
    {
        $credentials = request(['username', 'password']);

        if (! $token = auth()->attempt($credentials)) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        return $this->respondWithToken($token);
    }

    /**
     * Get the authenticated User.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function me()
    {
        return response()->json(auth()->user());
    }

    /**
     * Log the user out (Invalidate the token).
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout()
    {
        auth()->logout();

        return response()->json(['message' => 'Successfully logged out']);
    }

    /**
     * Refresh a token.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function refresh()
    {
        return $this->respondWithToken(auth()->refresh());
    }

    /**
     * Get the token array structure.
     *
     * @param  string $token
     *
     * @return \Illuminate\Http\JsonResponse
     */
    protected function respondWithToken($token)
    {
        $user = auth()->user();
        if($user->role_id === 2){
            $restaurante = $this->tieneRestaurantes($user);
            if($restaurante->isEmpty()){
                return response()->json([
                    'access_token' => $token,
                    'token_type' => 'bearer',
                    'expires_in' => auth()->factory()->getTTL() * 60,
                    'user' => auth()->user()
                ], 201);
            }else{
                return response()->json([
                    'access_token' => $token,
                    'token_type' => 'bearer',
                    'expires_in' => auth()->factory()->getTTL() * 60,
                    'user' => auth()->user(),
                    'restaurante' => $restaurante
                ],202);
            }

        }elseif($user->role_id === 1){
            return response()->json([
                'access_token' => $token,
                'token_type' => 'bearer',
                'expires_in' => auth()->factory()->getTTL() * 60,
                'user' => auth()->user()
            ],200);
        }
        return response()->json([
            'error' => 'Rol no reconocido',
            'user' => $user
        ], 400);
        /* return response()->json([
            'access_token' => $token,
            'token_type' => 'bearer',
            'expires_in' => auth()->factory()->getTTL() * 60,
            'user' => auth()->user(),
            'restaurante' => $restaurante
        ]); */
    }

    protected function tieneRestaurantes($user){
        $restaurante = $user->restaurantes()->get();
        if(!$restaurante){
            return null;
        }else{
            return $restaurante;
        }
    }
}
