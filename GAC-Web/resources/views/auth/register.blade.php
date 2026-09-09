<x-guest-layout>
    <form method="POST" action="{{ route('register') }}">
        @csrf

        <!-- Name -->
        <div>
            <x-input-label for="name" :value="__('Name')" />
            <x-text-input id="name" class="block mt-1 w-full" type="text" name="name" :value="old('name')" required autofocus autocomplete="name" />
            <x-input-error :messages="$errors->get('name')" class="mt-2" />
        </div>

        <!-- Email Address -->
        <div class="mt-4">
            <x-input-label for="email" :value="__('Email')" />
            <x-text-input id="email" class="block mt-1 w-full" type="email" name="email" :value="old('email')" required autocomplete="username" />
            <x-input-error :messages="$errors->get('email')" class="mt-2" />
        </div>

        <!-- Branch -->
        <div class="mt-4">
            <x-input-label for="branch" :value="__('Branch')" />
            <select id="branch" name="branch" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required>
                <option value="" disabled @selected(old('branch') === null)>{{ __('Select your branch') }}</option>
                @foreach ($branches as $branch)
                    <option value="{{ $branch }}" @selected(old('branch') === $branch)>{{ $branch }}</option>
                @endforeach
            </select>
            <x-input-error :messages="$errors->get('branch')" class="mt-2" />
        </div>

        <!-- Role -->
        <div class="mt-4">
            <x-input-label for="user_type" :value="__('Role / Position')" />
            <select id="user_type" name="user_type" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" required>
                <option value="" disabled @selected(old('user_type') === null)>{{ __('Select your role') }}</option>
                @foreach ($registrationRoles as $role)
                    <option value="{{ $role }}" @selected(old('user_type') === $role)>{{ $role }}</option>
                @endforeach
            </select>
            <x-input-error :messages="$errors->get('user_type')" class="mt-2" />
        </div>

        <!-- PIC Assignment -->
        <div class="mt-4" id="picAssignmentField">
            <x-input-label for="pic_assignment_type" :value="__('PIC Assignment')" />
            <select id="pic_assignment_type" name="pic_assignment_type" class="block mt-1 w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                <option value="">{{ __('Select the assigned checklist group') }}</option>
                @foreach ($picAssignmentOptions as $value => $label)
                    <option value="{{ $value }}" @selected(old('pic_assignment_type') === $value)>{{ $label }}</option>
                @endforeach
            </select>
            <x-input-error :messages="$errors->get('pic_assignment_type')" class="mt-2" />
        </div>

        <!-- Password -->
        <div class="mt-4">
            <x-input-label for="password" :value="__('Password')" />

            <x-text-input id="password" class="block mt-1 w-full"
                            type="password"
                            name="password"
                            required autocomplete="new-password" />

            <x-input-error :messages="$errors->get('password')" class="mt-2" />
        </div>

        <!-- Confirm Password -->
        <div class="mt-4">
            <x-input-label for="password_confirmation" :value="__('Confirm Password')" />

            <x-text-input id="password_confirmation" class="block mt-1 w-full"
                            type="password"
                            name="password_confirmation" required autocomplete="new-password" />

            <x-input-error :messages="$errors->get('password_confirmation')" class="mt-2" />
        </div>

        <div class="flex items-center justify-end mt-4">
            <a class="gac-auth-link text-sm" href="{{ route('login') }}">
                {{ __('Already registered?') }}
            </a>

            <x-primary-button class="ms-4">
                {{ __('Register') }}
            </x-primary-button>
        </div>
    </form>

    <script>
        const roleSelect = document.getElementById('user_type');
        const assignmentField = document.getElementById('picAssignmentField');
        const assignmentSelect = document.getElementById('pic_assignment_type');
        const syncAssignmentField = () => {
            const isPic = roleSelect.value === 'Person In Charge';
            assignmentField.hidden = !isPic;
            assignmentSelect.required = isPic;
            if (!isPic) assignmentSelect.value = '';
        };
        roleSelect.addEventListener('change', syncAssignmentField);
        syncAssignmentField();
    </script>
</x-guest-layout>
