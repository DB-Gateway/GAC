<?php

use App\Http\Controllers\ChecklistController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\DealerChecklistAccessController;
use App\Http\Controllers\DraftFollowUpController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\TaskNotificationController;
use App\Http\Controllers\UserManagementController;
use App\Http\Controllers\WebPushController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('dashboard');
});

Route::get('/notification-worker.js', fn () => response()->file(public_path('notification-worker.js'), [
    'Content-Type' => 'application/javascript',
    'Cache-Control' => 'no-cache',
]))->name('notifications.push.worker');
Route::get('/manifest.webmanifest', [WebPushController::class, 'manifest'])->name('notifications.push.manifest');

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
    Route::get('/checklists/dealer-operations-standards-subform', [ChecklistController::class, 'subform'])
        ->name('checklists.dealer-operations-standards-subform');
    Route::get('/checklists/subform', [ChecklistController::class, 'subform'])
        ->name('checklists.subform');
    Route::get('/checklists/dealer-operations-standards-documentation', [ChecklistController::class, 'documentation'])
        ->name('checklists.dealer-operations-standards-documentation');
    Route::get('/checklists/documentation', [ChecklistController::class, 'documentation'])
        ->name('checklists.documentation');
    Route::post('/checklists/templates', [ChecklistController::class, 'storeTemplate'])
        ->name('checklists.template.store');

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
    Route::delete('/checklists/{template}', [ChecklistController::class, 'destroyTemplate'])
        ->name('checklists.template.destroy');
    Route::post('/checklists/{template}/toggle-item', [ChecklistController::class, 'toggleItem'])
        ->name('checklists.item.toggle');

    Route::get('/reports/export/findings', [ReportController::class, 'exportFindingsCsv'])
        ->name('reports.export.findings');
    Route::get('/reports/export', [ReportController::class, 'export'])->name('reports.export');
    Route::patch('/reports/responses/{response}/override', [ReportController::class, 'overrideResponse'])
        ->name('reports.responses.override');
    Route::post('/reports/responses/{response}/follow-up', [ReportController::class, 'requestFindingFollowUp'])
        ->name('reports.responses.follow-up');
    Route::patch('/reports/responses/escalations', [ReportController::class, 'updateEscalations'])
        ->name('reports.responses.escalations');
    Route::get('/reports', [ReportController::class, 'index'])->name('reports.index');

});

Route::middleware(['auth', 'can.manage-users'])->group(function () {
    Route::get('/users', [UserManagementController::class, 'index'])->name('users.index');
    Route::post('/users', [UserManagementController::class, 'store'])->name('users.store');
    Route::patch('/users/{user}/password', [UserManagementController::class, 'updatePassword'])->name('users.password.update');
    Route::post('/users/{user}/reset-password', [UserManagementController::class, 'resetPassword'])->name('users.password.reset');
    Route::patch('/users/{user}', [UserManagementController::class, 'update'])->name('users.update');
    Route::patch('/users/{user}/status', [UserManagementController::class, 'updateStatus'])->name('users.status');
    Route::get('/admin/checklist-access', [DealerChecklistAccessController::class, 'index'])
        ->name('admin.checklist-access.index');
    Route::post('/admin/checklist-access/{dealer}/restrooms', [DealerChecklistAccessController::class, 'storeRestroom'])
        ->name('admin.checklist-access.restrooms.store');
    Route::patch('/admin/checklist-access/{dealer}/restrooms/{restroom}', [DealerChecklistAccessController::class, 'updateRestroom'])
        ->name('admin.checklist-access.restrooms.update');
    Route::delete('/admin/checklist-access/{dealer}/restrooms/{restroom}', [DealerChecklistAccessController::class, 'destroyRestroom'])
        ->name('admin.checklist-access.restrooms.destroy');
    Route::patch('/admin/checklist-access/{dealer}', [DealerChecklistAccessController::class, 'update'])
        ->where('dealer', '.*')
        ->name('admin.checklist-access.update');
});

Route::middleware('auth')->group(function () {
    Route::post('/notifications/push/subscription', [WebPushController::class, 'store'])
        ->middleware('throttle:30,1')->name('notifications.push.store');
    Route::delete('/notifications/push/subscription', [WebPushController::class, 'destroy'])
        ->middleware('throttle:30,1')->name('notifications.push.destroy');
    Route::get('/notifications/push/{notification}', [WebPushController::class, 'open'])
        ->whereUuid('notification')->name('notifications.push.open');

    Route::get('/notifications/status', [TaskNotificationController::class, 'status'])
        ->name('notifications.status');
    Route::get('/notifications/drafts', [DraftFollowUpController::class, 'index'])->name('notifications.drafts.index');
    Route::post('/notifications/drafts/{submission}/remind', [DraftFollowUpController::class, 'remind'])->name('notifications.drafts.remind');
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
