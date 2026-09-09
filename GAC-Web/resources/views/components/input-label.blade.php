@props(['value'])

<label {{ $attributes->merge(['class' => 'gac-field-label']) }}>
    {{ $value ?? $slot }}
</label>
