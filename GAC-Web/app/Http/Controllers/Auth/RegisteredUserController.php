<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class RegisteredUserController extends Controller
{
    /**
     * Display the registration view.
     */
    public function create(): View
    {
        return view('auth.register', [
            'branches' => config('gac.branches', []),
            'registrationRoles' => config('gac.registration_roles', []),
            'picAssignmentOptions' => User::picAssignmentOptions(),
        ]);
    }

    /**
     * Handle an incoming registration request.
     *
     * @throws ValidationException
     */
    public function store(Request $request): RedirectResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'lowercase', 'email', 'max:255', 'unique:'.User::class],
            'branch' => ['required', 'string', Rule::in(config('gac.branches', []))],
            'user_type' => ['required', 'string', Rule::in(config('gac.registration_roles', []))],
            'pic_assignment_type' => ['nullable', 'string', Rule::in(array_keys(User::picAssignmentOptions()))],
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ]);
        $validator->after(function ($validator) use ($request): void {
            $role = User::roleCodeFor($request->input('user_type'));
            $assignment = $request->input('pic_assignment_type');

            if ($role === User::ROLE_PERSON_IN_CHARGE && blank($assignment)) {
                $validator->errors()->add('pic_assignment_type', 'Select a PIC assignment type.');
            }

            if ($role !== User::ROLE_PERSON_IN_CHARGE && filled($assignment)) {
                $validator->errors()->add('pic_assignment_type', 'Only PIC accounts can have a PIC assignment type.');
            }
        });
        $validated = $validator->validate();
        $role = User::roleCodeFor($validated['user_type']);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'branch' => $validated['branch'],
            'user_type' => $role,
            'pic_assignment_type' => $role === User::ROLE_PERSON_IN_CHARGE
                ? $validated['pic_assignment_type']
                : null,
            'account_status' => 'pending',
            'password' => Hash::make($validated['password']),
        ]);

        event(new Registered($user));

        return redirect()
            ->route('login')
            ->with('status', 'Registration submitted. A compliance administrator must activate your account before you can sign in.');
    }
}
