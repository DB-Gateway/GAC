<?php

use App\Http\Controllers\ChecklistController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\TaskNotificationController;
use App\Http\Controllers\UserManagementController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('dashboard');
});

Route::get('/dashboard', [DashboardController::class, 'index'])
    ->middleware(['auth', 'verified'])
    ->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::get('/checklists', [ChecklistController::class, 'index'])
        ->name('checklists.index');
    Route::get('/checklists/gateway-5s', [ChecklistController::class, 'fiveS'])
        ->name('checklists.gateway-5s');
    Route::get('/checklists/dealer-operations-standards', [ChecklistController::class, 'dealerOperations'])
        ->name('checklists.dealer-operations-standards');
    Route::get('/checklists/restroom', [ChecklistController::class, 'restroom'])
        ->name('checklists.restroom');

    Route::get('/checklists/{template}/record', [ChecklistController::class, 'load'])
        ->name('checklists.load');
    Route::post('/checklists/{template}/draft', [ChecklistController::class, 'saveDraft'])
        ->name('checklists.save-draft');
    Route::post('/checklists/{template}/submit', [ChecklistController::class, 'submit'])
        ->name('checklists.submit');
    Route::post('/checklists/{template}/attachments', [ChecklistController::class, 'uploadAttachment'])
        ->name('checklists.attachments.upload');
    Route::delete('/checklists/{template}/record', [ChecklistController::class, 'reset'])
        ->name('checklists.reset');
    Route::post('/debug/checklists/reset-answers', [ChecklistController::class, 'debugResetAnswers'])
        ->name('debug.checklists.reset-answers');
    Route::put('/checklists/{template}', [ChecklistController::class, 'updateTemplate'])
        ->name('checklists.template.update');

    Route::get('/reports/export/findings', [ReportController::class, 'exportFindingsCsv'])
        ->name('reports.export.findings');
    Route::get('/reports/export', [ReportController::class, 'export'])->name('reports.export');
    Route::patch('/reports/responses/{response}/override', [ReportController::class, 'overrideResponse'])
        ->name('reports.responses.override');
    Route::patch('/reports/responses/escalations', [ReportController::class, 'updateEscalations'])
        ->name('reports.responses.escalations');
    Route::get('/reports', [ReportController::class, 'index'])->name('reports.index');

});

Route::middleware(['auth', 'can.manage-users'])->group(function () {
    Route::get('/users', [UserManagementController::class, 'index'])->name('users.index');
    Route::post('/users', [UserManagementController::class, 'store'])->name('users.store');
    Route::patch('/users/{user}/password', [UserManagementController::class, 'updatePassword'])->name('users.password.update');
    Route::patch('/users/{user}', [UserManagementController::class, 'update'])->name('users.update');
    Route::patch('/users/{user}/status', [UserManagementController::class, 'updateStatus'])->name('users.status');
});

Route::middleware('auth')->group(function () {
    Route::get('/notifications/{notification}/task', [TaskNotificationController::class, 'viewTask'])
        ->name('notifications.view-task');
    Route::patch('/notifications/viewed', [TaskNotificationController::class, 'markAllViewed'])
        ->name('notifications.mark-all-viewed');
    Route::patch('/notifications/{notification}/viewed', [TaskNotificationController::class, 'markViewed'])
        ->name('notifications.mark-viewed');

    Route::get('/profile', [ProfileController::class, 'show'])->name('profile.show');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__.'/auth.php';
