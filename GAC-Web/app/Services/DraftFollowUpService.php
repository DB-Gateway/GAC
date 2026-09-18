<?php

namespace App\Services;

use App\Models\ChecklistSubmission;
use App\Models\User;
use App\Notifications\ChecklistDraftReminder;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

class DraftFollowUpService
{
    public function pendingQuery(User $manager): Builder
    {
        $query = ChecklistSubmission::query()->where('status', 'draft');

        if (! $manager->receivesTaskCompletionNotifications()) {
            return $query->whereRaw('0 = 1');
        }

        if (! $manager->hasAdministrativeAccess()) {
            $branch = mb_strtolower(trim((string) $manager->branch));
            if ($branch === '') {
                return $query->whereRaw('0 = 1');
            }
            $query->whereRaw('LOWER(TRIM(branch)) = ?', [$branch]);
        }

        return $query;
    }

    public function pendingDrafts(User $manager): Collection
    {
        $records = $this->pendingQuery($manager)
            ->with(['user', 'template.sections.items', 'responses'])
            ->latest('updated_at')
            ->latest('id')
            ->get();

        return $records->unique(function (ChecklistSubmission $draft): string {
            $userName = mb_strtolower(trim((string) ($draft->user?->name ?? $draft->submitted_by_name ?? '')));
            $userType = mb_strtolower(trim((string) User::roleCodeFor($draft->user?->user_type ?? $draft->submitted_by_user_type)));

            return ($userName !== '' || $userType !== '')
                ? "{$userName}|{$userType}"
                : "id:{$draft->id}";
        })->values();
    }

    public function details(ChecklistSubmission $draft): array
    {
        $draft->loadMissing(['user', 'template.sections.items', 'responses']);
        $owner = $draft->user;
        $slug = (string) (data_get($draft->template_snapshot, 'slug') ?: $draft->template?->slug);
        $name = (string) (data_get($draft->template_snapshot, 'name') ?: $draft->template?->name ?: 'Checklist');
        $sections = collect(data_get($draft->template_snapshot, 'sections', []));
        if ($sections->isEmpty()) {
            $sections = collect($draft->template?->sections?->toArray() ?? []);
        }

        $items = $sections->sortBy('sort_order')->flatMap(function (array $section): Collection {
            return collect($section['items'] ?? [])->sortBy('sort_order')->map(fn (array $item): array => [
                ...$item,
                'section_title' => $section['title'] ?? '',
            ]);
        })->filter(fn (array $item): bool => ($item['is_active'] ?? true)
            && (! $owner || $owner->canAccessChecklistItem($slug, data_get($item, 'metadata.checker'))));
        if ($slug === 'dealer-operations-standards-sales') {
            $items = $items->sortBy('sort_order');
        }
        $items = $items->values();
        $responses = $draft->responses->keyBy('item_key');
        $settings = data_get($draft->template_snapshot, 'settings', $draft->template?->settings ?? []);
        $mode = data_get($settings, 'validation_mode');
        $slots = collect(data_get($settings, 'time_slots', []))->map(fn ($slot) => is_array($slot) ? ($slot['key'] ?? null) : $slot)->filter()->values();
        $position = data_get($draft->context, 'draft_position', []);
        $slotKey = in_array(data_get($position, 'slot_key'), $slots->all(), true) ? data_get($position, 'slot_key') : null;
        $customerIndex = (int) data_get($position, 'customer_index', 1);

        $answered = $items->filter(function (array $item) use ($responses, $mode, $slots, $slotKey, $customerIndex): bool {
            $response = $responses->get($item['key']);
            if (! $response) {
                return false;
            }
            if ($mode === 'time_slots') {
                $marks = data_get($response->details, 'slots', []);
                $requiredSlots = $slotKey ? collect([$slotKey]) : $slots;

                return $requiredSlots->isNotEmpty() && $requiredSlots->every(fn ($slot): bool => in_array(data_get($marks, $slot), ['good', 'not_good', 'bad', 'yes', 'no', 'na'], true));
            }
            if ($mode === 'dos_documentation') {
                $customers = collect(data_get($response->details, 'customers', []));
                $customer = $customers->firstWhere('customer_index', $customerIndex);

                return in_array(data_get($customer, 'answers.'.$item['key']), ['yes', 'no', 'na'], true);
            }

            return in_array($response->status, ['yes', 'no', 'na'], true);
        });
        $nextItem = $items->first(fn (array $item): bool => ! $answered->contains('key', $item['key']));
        $savedItem = $items->firstWhere('key', data_get($position, 'item_key'));
        $resumeItem = $savedItem ?? $nextItem;
        $itemNumber = $resumeItem ? (string) (data_get($resumeItem, 'metadata.number') ?: $items->search(fn ($item): bool => $item['key'] === $resumeItem['key']) + 1) : null;
        $canRemind = $owner && $owner->account_status === 'active' && $draft->template?->is_active
            && $owner->canAccessChecklist($slug)
            && ($owner->hasAdministrativeAccess() || mb_strtolower(trim((string) $owner->branch)) === mb_strtolower(trim((string) $draft->branch)));
        $lastReminder = $owner?->notifications()->where('type', ChecklistDraftReminder::class)
            ->where('data->submission_id', $draft->id)->latest()->first();

        return [
            'id' => $draft->id,
            'user_id' => $draft->user_id,
            'user_name' => $owner?->name ?? 'User no longer available',
            'user_role' => $owner?->roleLabel() ?? 'Unknown',
            'user_type' => $owner?->roleCode() ?? User::roleCodeFor($draft->submitted_by_user_type),
            'template_slug' => $slug,
            'template_name' => $name,
            'branch' => $draft->branch,
            'audit_date' => $draft->audit_date->toDateString(),
            'updated_at' => $draft->updated_at?->toISOString(),
            'answered_count' => $answered->count(),
            'total_count' => $items->count(),
            'item_key' => $resumeItem['key'] ?? null,
            'item_number' => $itemNumber,
            'item_prompt' => $resumeItem['prompt'] ?? null,
            'section_title' => $resumeItem['section_title'] ?? null,
            'position_label' => $savedItem ? 'Saved at question' : ($nextItem ? 'Next unanswered question' : 'Ready to submit'),
            'slot_key' => $slotKey,
            'customer_index' => $mode === 'dos_documentation' ? $customerIndex : null,
            'can_remind' => (bool) $canRemind,
            'unavailable_reason' => $canRemind ? null : 'The owner no longer has an active account or access to this checklist.',
            'last_reminded_at' => $lastReminder?->created_at?->toISOString(),
            'remind_url' => route('notifications.drafts.remind', $draft),
        ];
    }
}
