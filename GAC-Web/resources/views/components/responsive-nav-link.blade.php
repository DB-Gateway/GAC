@props(['active'])

@php
$classes = ($active ?? false)
            ? 'gac-responsive-nav-link gac-responsive-nav-link-active'
            : 'gac-responsive-nav-link';
@endphp

<a {{ $attributes->merge(['class' => $classes]) }}>
    {{ $slot }}
</a>
