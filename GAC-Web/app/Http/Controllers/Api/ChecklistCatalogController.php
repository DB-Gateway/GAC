<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ChecklistCatalogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'date' => ['nullable', 'date_format:Y-m-d'],
        ]);

        $date = $data['date'] ?? now()->toDateString();
        $user = $request->user();
        $branch = trim((string) $user->branch) ?: null;
        $scopeKey = hash('sha256', Str::lower($branch ?? 'unassigned'));
        $allowedSlugs = $user->allowedChecklistSlugs();

        $templates = ChecklistTemplate::query()
            ->where('is_active', true)
            ->when(
                $allowedSlugs !== null,
                fn ($query) => $query->whereIn('slug', $allowedSlugs)
            )
            ->with([
                'sections' => fn ($query) => $query
                    ->where('is_active', true)
                    ->orderBy('sort_order'),
                'sections.items' => fn ($query) => $query
                    ->where('is_active', true)
                    ->orderBy('sort_order'),
            ])
            ->orderBy('id')
            ->get()
            ->reject(fn (ChecklistTemplate $template): bool => (bool) data_get(
                $template->settings,
                'workspace_hidden',
                false
            ))
            ->values();

        $templates->each(
            fn (ChecklistTemplate $template) => $template->retainAccessibleItemsFor($user)
        );

        $submissions = ChecklistSubmission::query()
            ->whereIn('checklist_template_id', $templates->modelKeys())
            ->whereDate('audit_date', $date)
            ->where('scope_key', $scopeKey)
            ->where('user_id', $user->id)
            ->whereIn('status', ['draft', 'submitted'])
            ->latest('updated_at')
            ->get()
            ->groupBy('checklist_template_id');

        return response()->json([
            'date' => $date,
            'branch' => $branch,
            'checklists' => $templates->map(function (ChecklistTemplate $template) use ($submissions): array {
                $records = $submissions->get($template->id, collect());
                $submission = $records->firstWhere('status', 'draft') ?? $records->first();
                $itemCount = $template->sections->sum(fn ($section): int => $section->items->count());
                $usesTimeSlots = ($template->settings['validation_mode'] ?? null) === 'time_slots';
                $workUnitCount = $usesTimeSlots
                    ? $itemCount * count($template->settings['time_slots'] ?? [])
                    : $itemCount;

                return [
                    'id' => $template->id,
                    'slug' => $template->slug,
                    'name' => $template->name,
                    'description' => $template->description,
                    'version' => $template->version,
                    'settings' => $template->settings,
                    'section_count' => $template->sections->count(),
                    'item_count' => $itemCount,
                    'work_unit_count' => $workUnitCount,
                    'updated_at' => $template->updated_at?->toISOString(),
                    'submission' => $submission ? $this->submissionSummary(
                        $submission,
                        $itemCount,
                        $usesTimeSlots
                    ) : null,
                ];
            })->values(),
        ]);
    }

    private function submissionSummary(
        ChecklistSubmission $submission,
        int $itemCount,
        bool $usesTimeSlots
    ): array {
        $scores = is_array($submission->scores) ? $submission->scores : [];
        $answered = (int) ($usesTimeSlots
            ? ($scores['slots_answered'] ?? 0)
            : ($scores['answered'] ?? 0));
        $total = (int) ($usesTimeSlots
            ? ($scores['slot_total'] ?? 0)
            : ($scores['total'] ?? $itemCount));
        $completion = (float) ($scores['completion_percentage']
            ?? ($total > 0 ? ($answered / $total) * 100 : 0));

        return [
            'id' => $submission->id,
            'status' => $submission->status,
            'audit_date' => $submission->audit_date?->toDateString(),
            'template_version' => $submission->template_version,
            'answered_items' => $answered,
            'total_items' => $total,
            'completion_percentage' => round($completion, 2),
            'issue_count' => (int) ($usesTimeSlots
                ? ($scores['bad'] ?? 0)
                : ($scores['no'] ?? 0)),
            'scores' => $scores,
            'submitted_at' => $submission->submitted_at?->toISOString(),
            'updated_at' => $submission->updated_at?->toISOString(),
        ];
    }
}
