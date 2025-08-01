<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
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
    //Rutas para los restaurantes
    Route::apiResource('restaurantes', RestauranteController::class)
        ->middleware(['auth:api', IsOwnerMiddleware::class]);

    //Rutas para los usuarios
    Route::apiResource('users', UserController::class)->except(['store']);
});
