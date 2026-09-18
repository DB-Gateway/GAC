<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChecklistCatalogController;
use App\Http\Controllers\Api\EscalationFollowUpController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\UserApprovalController;
use App\Http\Controllers\ChecklistController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'Gateway Audit Compliance API',
    ]);
});

Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:10,1');

Route::post('/register', [AuthController::class, 'register'])
    ->middleware('throttle:5,1');

Route::middleware([\App\Http\Middleware\AuthenticateNotificationDevice::class, 'throttle:120,1'])->group(function () {
    Route::get('/device-notifications', [NotificationController::class, 'index']);
    Route::patch('/device-notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::patch('/device-notifications/{notification}/read', [NotificationController::class, 'markRead']);
});

Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureInteractiveApiToken::class])->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/notifications', [NotificationController::class, 'index'])
        ->name('api.notifications.index');
    Route::post('/notifications/{notification}/follow-ups', [EscalationFollowUpController::class, 'store'])
        ->middleware('throttle:10,1')
        ->name('api.notifications.follow-ups.store');
    Route::patch('/notifications/read-all', [NotificationController::class, 'markAllRead'])
        ->name('api.notifications.read-all');
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markRead'])
        ->name('api.notifications.read');

    Route::get('/profile', [ProfileController::class, 'show'])
        ->name('api.profile.show');
    Route::patch('/profile', [ProfileController::class, 'update'])
        ->name('api.profile.update');
    Route::put('/profile/password', [ProfileController::class, 'updatePassword'])
        ->middleware('throttle:6,1')
        ->name('api.profile.password.update');
    Route::post('/profile/avatar', [ProfileController::class, 'updateAvatar'])
        ->name('api.profile.avatar.update');
    Route::delete('/profile/avatar', [ProfileController::class, 'destroyAvatar'])
        ->name('api.profile.avatar.destroy');

    Route::get('/checklists', [ChecklistCatalogController::class, 'index'])
        ->name('api.checklists.index');
    Route::get('/checklists/{template}', [ChecklistController::class, 'load'])
        ->name('api.checklists.show');
    Route::post('/checklists/{template}/draft', [ChecklistController::class, 'saveDraft'])
        ->name('api.checklists.save-draft');
    Route::post('/checklists/{template}/submit', [ChecklistController::class, 'submit'])
        ->name('api.checklists.submit');
    Route::post('/checklists/{template}/attachments', [ChecklistController::class, 'uploadAttachment'])
        ->name('api.checklists.attachments.upload');
    Route::delete('/checklists/{template}/draft', [ChecklistController::class, 'reset'])
        ->name('api.checklists.reset');
    Route::put('/checklists/{template}', [ChecklistController::class, 'updateTemplate'])
        ->name('api.checklists.update');
    Route::post('/checklists/templates', [ChecklistController::class, 'storeTemplate'])
        ->name('api.checklists.template.store');
    Route::post('/checklists/{template}/toggle-item', [ChecklistController::class, 'toggleItem'])
        ->name('api.checklists.item.toggle');

    Route::get('/users/pending', [UserApprovalController::class, 'index']);
    Route::patch('/users/{user}/approve', [UserApprovalController::class, 'approve']);
    Route::patch('/users/{user}/reject', [UserApprovalController::class, 'reject']);
});
