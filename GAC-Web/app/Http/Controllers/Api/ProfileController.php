<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UpdateAvatarRequest;
use App\Http\Requests\Api\UpdatePasswordRequest;
use App\Http\Requests\Api\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Throwable;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'user' => UserResource::make($request->user())->resolve($request),
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->fill($request->validated());

        if ($user->isDirty('email')) {
            $user->email_verified_at = null;
        }

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => UserResource::make($user->fresh())->resolve($request),
        ]);
    }

    public function updatePassword(UpdatePasswordRequest $request): JsonResponse
    {
        $request->user()->update([
            'password' => Hash::make($request->validated('password')),
        ]);

        return response()->json([
            'message' => 'Password updated successfully.',
        ]);
    }

    public function updateAvatar(UpdateAvatarRequest $request): JsonResponse
    {
        $user = $request->user();
        $previousPath = $user->avatar_path;
        $newPath = $request->file('avatar')?->store(
            'avatars/'.$user->getKey(),
            'public'
        );

        if (! is_string($newPath)) {
            throw new RuntimeException('The profile photo could not be stored.');
        }

        try {
            $user->avatar_path = $newPath;
            $user->save();
        } catch (Throwable $exception) {
            Storage::disk('public')->delete($newPath);

            throw $exception;
        }

        if (filled($previousPath) && $previousPath !== $newPath) {
            Storage::disk('public')->delete($previousPath);
        }

        return response()->json([
            'message' => 'Profile photo updated successfully.',
            'user' => UserResource::make($user->fresh())->resolve($request),
        ]);
    }

    public function destroyAvatar(Request $request): JsonResponse
    {
        $user = $request->user();
        $previousPath = $user->avatar_path;

        if (filled($previousPath)) {
            $user->avatar_path = null;
            $user->save();
            Storage::disk('public')->delete($previousPath);
        }

        return response()->json([
            'message' => 'Profile photo removed successfully.',
            'user' => UserResource::make($user->fresh())->resolve($request),
        ]);
    }
}
