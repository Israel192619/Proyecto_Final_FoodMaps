<?php

use App\Http\Controllers\ProductoMenuController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MenuController;
use App\Http\Controllers\RestauranteController;
use App\Http\Controllers\UserController;
use App\Http\Middleware\IsOwnerMiddleware;

Route::group([
    'middleware' => 'api',
    'prefix' => 'auth'
], function ($router) {
    Route::post('/register', [AuthController::class, 'register'])->name('register');
    Route::post('/login', [AuthController::class, 'login'])->name('login');
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:api')->name('logout');
    Route::post('/refresh', [AuthController::class, 'refresh'])->middleware('auth:api')->name('refresh');
    Route::post('/me', [AuthController::class, 'me'])->middleware('auth:api')->name('me');
});

Route::group([
    'middleware' => ['api'],
], function () {

    // Restaurantes rutas publicas (dueños y clientes)
    Route::prefix('clientes')->middleware('auth:api')->group(function () {
        Route::get('/restaurantes', [RestauranteController::class, 'publicIndex']);
        Route::get('/restaurantes/{id}', [RestauranteController::class, 'showPublic']);
        Route::apiResource('restaurantes.menus.productos', ProductoMenuController::class)
            ->except(['store', 'update', 'destroy']);
        Route::apiResource('restaurantes.menus.productos', ProductoMenuController::class)
            ->only(['store', 'update', 'destroy'])
            ->middleware(IsOwnerMiddleware::class);
        Route::post('restaurantes/{restaurante_id}/menus/{menu_id}/productos/{producto_id}',[ProductoMenuController::class, 'update']);
        Route::apiResource('restaurantes.menus', MenuController::class);
    });

    // Restaurantes rutas privadas (Dueños)
    Route::group(['middleware' => ['auth:api', IsOwnerMiddleware::class]], function () {
        Route::apiResource('restaurantes',RestauranteController::class);
        Route::post('restaurantes/{id}',[RestauranteController::class, 'update']);
        Route::post('/restaurantes/{id}/change-status', [RestauranteController::class, 'changeStatus']);
        Route::get('/restaurantes/{id}/status', [RestauranteController::class, 'obtenerEstadoRestaurante']);
    });

    //Rutas para los usuarios
    Route::apiResource('users', UserController::class)->except(['store']);
});
