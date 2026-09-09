@props(['status'])

@if ($status)
    <div {{ $attributes->merge(['class' => 'gac-status-success']) }} role="status">
        {{ $status }}
    </div>
@endif
