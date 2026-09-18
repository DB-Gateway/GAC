<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'branch' => ['required', 'string', Rule::in(config('gac.branches'))],
            'position' => [
                'required',
                'string',
                Rule::in(config('gac.registration_roles')),
            ],
            'pic_assignment_type' => [
                'nullable',
                'string',
                Rule::in(array_keys(User::picAssignmentOptions())),
            ],
        ]);
        $validator->after(function ($validator) use ($request): void {
            $role = User::roleCodeFor($request->input('position'));
            $assignment = $request->input('pic_assignment_type');

            if ($role === User::ROLE_PERSON_IN_CHARGE && blank($assignment)) {
                $validator->errors()->add('pic_assignment_type', 'Select a PIC assignment type.');
            }

            if ($role !== User::ROLE_PERSON_IN_CHARGE && filled($assignment)) {
                $validator->errors()->add('pic_assignment_type', 'Only PIC accounts can have a PIC assignment type.');
            }
        });
        $data = $validator->validate();
        $role = User::roleCodeFor($data['position']);

        $user = User::create([
            'name' => trim($data['name']),
            'email' => strtolower(trim($data['email'])),
            'password' => $data['password'],
            'branch' => $data['branch'],
            'user_type' => $role,
            'pic_assignment_type' => $role === User::ROLE_PERSON_IN_CHARGE
                ? $data['pic_assignment_type']
                : null,
            'account_status' => 'pending',
        ]);

        return response()->json([
            'message' => 'Account request submitted. Wait for administrator approval before logging in.',
            'user' => $this->userPayload($user),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
            'notification_device_id' => ['nullable', 'uuid'],
        ]);

        $user = User::query()
            ->where('email', strtolower(trim($credentials['email'])))
            ->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The email or password is incorrect.'],
            ]);
        }

        if ($user->account_status !== 'active') {
            $message = $user->account_status === 'rejected'
                ? 'This account request was rejected. Contact your administrator.'
                : 'Your account is waiting for administrator approval.';

            return response()->json(['message' => $message], 403);
        }

        $token = $user->createToken(
            $credentials['device_name'] ?? 'gateway-expo-app'
        )->plainTextToken;

        $notificationToken = null;
        if (! empty($credentials['notification_device_id'])) {
            $deviceName = 'notifications:'.$credentials['notification_device_id'];
            // A successful login replaces this installation's previous recipient.
            PersonalAccessToken::where('name', $deviceName)->delete();
            $notificationToken = $user->createToken($deviceName, ['notifications:read'])->plainTextToken;
        }

        return response()->json([
            'message' => 'Login successful.',
            'token' => $token,
            'token_type' => 'Bearer',
            'notification_token' => $notificationToken,
            'user' => $this->userPayload($user),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $this->userPayload($request->user()),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Logged out successfully.',
        ]);
    }

    private function userPayload(User $user): array
    {
        return UserResource::make($user)->resolve();
    }
}
