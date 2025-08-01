<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

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
    'middleware' => 'api',
    'prefix' => 'auth'
], function ($router) {
    Route::apiResource('restaurantes', 'RestauranteController')
        ->middleware('auth:api')
        ->names([
            'index' => 'restaurantes.index',
            'store' => 'restaurantes.store',
            'show' => 'restaurantes.show',
            'update' => 'restaurantes.update',
            'destroy' => 'restaurantes.destroy'
        ]);
});
