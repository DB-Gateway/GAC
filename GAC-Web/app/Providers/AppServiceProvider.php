<?php

namespace App\Providers;

use App\Services\NotificationService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(NotificationService $notificationService): void
    {
        View::composer([
            'partials.app-topbar',
            'partials.notifications-modal',
            'checklists.*',
            'reports.*',
            'users.*',
            'profile.*',
        ], function ($view) use ($notificationService): void {
            if ($view->offsetExists('taskNotifications') && $view->offsetExists('notificationBadgeCount')) {
                return;
            }

            $user = Auth::user();
            if (! $user) {
                return;
            }

            $data = $notificationService->getNotificationData($user);
            foreach ($data as $key => $value) {
                if (! $view->offsetExists($key)) {
                    $view->with($key, $value);
                }
            }
        });
    }
}
