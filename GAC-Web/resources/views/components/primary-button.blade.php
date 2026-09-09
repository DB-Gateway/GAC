<button {{ $attributes->merge(['type' => 'submit', 'class' => 'gac-button gac-button-primary']) }}>
    {{ $slot }}
</button>
