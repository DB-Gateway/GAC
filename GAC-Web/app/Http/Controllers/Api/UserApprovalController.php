<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserApprovalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->ensureCanApproveUsers($request);

        $users = User::query()
            ->where('account_status', 'pending')
            ->orderBy('created_at')
            ->get(['id', 'name', 'email', 'branch', 'user_type', 'pic_assignment_type', 'account_status', 'created_at']);

        return response()->json(['users' => $users]);
    }

    public function approve(Request $request, User $user): JsonResponse
    {
        $this->ensureCanApproveUsers($request);

        $user->update(['account_status' => 'active']);

        return response()->json([
            'message' => 'User account approved.',
            'user' => $user->only([
                'id',
                'name',
                'email',
                'branch',
                'user_type',
                'pic_assignment_type',
                'account_status',
            ]),
        ]);
    }

    public function reject(Request $request, User $user): JsonResponse
    {
        $this->ensureCanApproveUsers($request);

        $user->tokens()->delete();
        $user->update(['account_status' => 'rejected']);

        return response()->json([
            'message' => 'User account rejected.',
            'user' => $user->only([
                'id',
                'name',
                'email',
                'branch',
                'user_type',
                'pic_assignment_type',
                'account_status',
            ]),
        ]);
    }

    private function ensureCanApproveUsers(Request $request): void
    {
        abort_unless(
            $request->user()?->hasAdministrativeAccess() === true,
            403,
            'Only the system administrator can approve account requests.'
        );
    }
}
