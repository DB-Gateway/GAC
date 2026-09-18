@if (data_get($followUpData, 'event') === 'escalation_follow_up_submitted')
    <div class="notification-meta">
        @foreach (data_get($followUpData, 'photos', []) as $photo)
            <a href="{{ \Illuminate\Support\Facades\Storage::disk('public')->url($photo['path']) }}" target="_blank" rel="noopener noreferrer">
                <i class="fas fa-camera" aria-hidden="true"></i> View photo {{ $loop->iteration }}
            </a>
        @endforeach
    </div>
@endif
