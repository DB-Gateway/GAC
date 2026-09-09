<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class UserManagementController extends Controller
{
    public function index(Request $request): View
    {
        $this->ensureCanManageUsers($request);

        $query = User::query();

        if ($search = trim((string) $request->query('search'))) {
            $query->where(function ($builder) use ($search): void {
                $builder
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('branch', 'like', "%{$search}%")
                    ->orWhere('user_type', 'like', "%{$search}%");
            });
        }

        if ($role = $request->query('role')) {
            $roleCode = User::roleCodeFor((string) $role);
            $roleAliases = collect(User::acceptedRoleValues())
                ->filter(fn (string $value) => User::roleCodeFor($value) === $roleCode)
                ->values()
                ->all();

            $query->whereIn('user_type', $roleAliases);
        }

        if ($branch = $request->query('branch')) {
            $query->where('branch', $branch);
        }

        if ($status = $request->query('status')) {
            if ($status === 'active') {
                $query->where('account_status', 'active');
            } elseif ($status === 'inactive') {
                $query->where('account_status', '<>', 'active');
            }
        }

        $users = $query->orderBy('name')->paginate(20)->withQueryString();
        $allUsers = User::query()->get(['id', 'branch', 'user_type', 'account_status']);

        return view('users.index', [
            'users' => $users,
            'branches' => $this->availableBranches(),
            'stats' => [
                'total' => $allUsers->count(),
                'active' => $allUsers->where('account_status', 'active')->count(),
                'inactive' => $allUsers->where('account_status', '<>', 'active')->count(),
                'pic' => $allUsers->filter(fn (User $user) => in_array($user->roleCode(), [
                    User::ROLE_5S_UTILITIES,
                    User::ROLE_5S_SERVICE,
                    User::ROLE_5S_SALES,
                    User::ROLE_PERSON_IN_CHARGE,
                ], true))->count(),
                'bom' => $allUsers->filter(fn (User $user) => $user->roleCode() === User::ROLE_BRANCH_OPERATIONS_MANAGER)->count(),
                'admin' => $allUsers->filter(fn (User $user) => $user->hasAdministrativeAccess())->count(),
            ],
            'canManageUsers' => $request->user()?->hasAdministrativeAccess() === true,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->ensureCanManageUsers($request);

        $validated = $this->validatedAccountData($request);
        $validated['account_status'] = 'active';

        User::create($validated);

        return back()->with('status', 'User account created.');
    }

    public function update(Request $request, User $user): RedirectResponse
    {
        $this->ensureCanManageUsers($request);

        $validated = $this->validatedAccountData($request, $user);

        if (blank($validated['password'] ?? null)) {
            unset($validated['password']);
        }

        $this->preventSelfDeactivation($request, $user, $validated['account_status']);

        $previousStatus = $user->account_status;
        $user->update($validated);
        $this->revokeTokensAfterStatusChange($user, $previousStatus);

        return back()->with('status', 'User account updated.');
    }

    public function updatePassword(Request $request, User $user): RedirectResponse
    {
        $this->ensureCanManageUsers($request);

        $validated = $request->validate([
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        DB::transaction(function () use ($user, $validated): void {
            $user->forceFill(['password' => $validated['password']]);
            $user->setRememberToken(Str::random(60));
            $user->save();
            $user->tokens()->delete();
        });

        return back()->with('status', 'User password updated.');
    }

    public function updateStatus(Request $request, User $user): RedirectResponse
    {
        $this->ensureCanManageUsers($request);

        $validated = $request->validate([
            'account_status' => ['required', Rule::in(['active', 'pending', 'inactive', 'rejected'])],
        ]);

        $this->preventSelfDeactivation($request, $user, $validated['account_status']);

        $previousStatus = $user->account_status;
        $user->update($validated);
        $this->revokeTokensAfterStatusChange($user, $previousStatus);

        return back()->with('status', 'Account status updated.');
    }

    private function ensureCanManageUsers(Request $request): void
    {
        abort_unless(
            $request->user()?->hasAdministrativeAccess() === true,
            403,
            'Only a compliance administrator can manage user accounts.'
        );
    }

    private function validatedAccountData(Request $request, ?User $user = null): array
    {
        $input = $request->all();
        if ($user !== null && ! array_key_exists('pic_assignment_type', $input)) {
            $input['pic_assignment_type'] = $user->picAssignmentType();
        }

        $rules = [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'email',
                'max:255',
                $user === null
                    ? Rule::unique('users', 'email')
                    : Rule::unique('users', 'email')->ignore($user),
            ],
            'branch' => ['required', 'string', Rule::in($this->availableBranches()->all())],
            'user_type' => ['required', Rule::in(User::acceptedRoleValues())],
            'pic_assignment_type' => ['nullable', 'string', Rule::in(array_keys(User::picAssignmentOptions()))],
            'account_status' => [$user === null ? 'nullable' : 'required', Rule::in(['active', 'pending', 'inactive', 'rejected'])],
        ];

        if ($user === null) {
            $rules['password'] = ['required', 'string', 'min:8', 'confirmed'];
        } else {
            $rules['password'] = ['prohibited'];
            $rules['password_confirmation'] = ['prohibited'];
        }

        $validator = Validator::make($input, $rules, [
            'password.prohibited' => 'Use the Change Password section to update this password.',
            'password_confirmation.prohibited' => 'Use the Change Password section to confirm the new password.',
        ]);
        $validator->after(function ($validator) use ($input): void {
            $role = User::roleCodeFor($input['user_type'] ?? null);
            $assignment = $input['pic_assignment_type'] ?? null;

            if ($role === User::ROLE_PERSON_IN_CHARGE && blank($assignment)) {
                $validator->errors()->add('pic_assignment_type', 'Select a PIC assignment type.');
            }

            if ($role !== User::ROLE_PERSON_IN_CHARGE && filled($assignment)) {
                $validator->errors()->add('pic_assignment_type', 'Only PIC accounts can have a PIC assignment type.');
            }
        });

        $validated = $validator->validate();
        $validated['user_type'] = User::roleCodeFor($validated['user_type']);
        $validated['pic_assignment_type'] = $validated['user_type'] === User::ROLE_PERSON_IN_CHARGE
            ? $validated['pic_assignment_type']
            : null;

        return $validated;
    }

    private function availableBranches(): Collection
    {
        return User::query()
            ->whereNotNull('branch')
            ->where('branch', '<>', '')
            ->distinct()
            ->pluck('branch')
            ->merge(config('gac.branches', []))
            ->filter(fn ($branch): bool => filled($branch))
            ->unique(fn ($branch): string => strtolower(trim((string) $branch)))
            ->sort()
            ->values();
    }

    private function preventSelfDeactivation(Request $request, User $user, string $status): void
    {
        abort_if(
            $request->user()->is($user) && $status !== 'active',
            422,
            'You cannot deactivate your own account.'
        );
    }

    private function revokeTokensAfterStatusChange(User $user, ?string $previousStatus): void
    {
        if ($previousStatus !== $user->account_status) {
            $user->tokens()->delete();
        }
    }
}
