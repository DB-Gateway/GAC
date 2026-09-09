@props(['active'])

@php
$classes = ($active ?? false)
            ? 'gac-nav-link gac-nav-link-active'
            : 'gac-nav-link';
@endphp

<a {{ $attributes->merge(['class' => $classes]) }}>
    {{ $slot }}
</a>
