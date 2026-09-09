<button {{ $attributes->merge(['type' => 'submit', 'class' => 'gac-button gac-button-danger']) }}>
    {{ $slot }}
</button>
