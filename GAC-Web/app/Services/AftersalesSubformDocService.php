<?php

namespace App\Services;

use App\Models\ChecklistItem;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class AftersalesSubformDocService
{
    public const SUBFORM_SLUG = 'dealer-operations-standards-subform';
    public const DOCUMENTATION_SLUG = 'dealer-operations-standards-documentation';
    public const AFTERSALES_SLUG = 'dealer-operations-standards';

    /**
     * Retrieve and compile subform and documentation audit results.
     *
     * @param string|null $branch
     * @param string|null $date
     * @param int|null $submissionId
     * @param string $summaryMode 'user' | 'overall'
     * @param int|null $userId
     * @return array
     */
    public function getSubformAndDocumentationResults(
        ?string $branch = null,
        ?string $date = null,
        ?int $submissionId = null,
        string $summaryMode = 'user',
        ?int $userId = null
    ): array {
        $subformTemplate = ChecklistTemplate::query()
            ->with(['sections.items' => fn ($q) => $q->where('is_active', true)->orderBy('sort_order')])
            ->where('slug', self::SUBFORM_SLUG)
            ->first();

        $docTemplate = ChecklistTemplate::query()
            ->with(['sections.items' => fn ($q) => $q->where('is_active', true)->orderBy('sort_order')])
            ->where('slug', self::DOCUMENTATION_SLUG)
            ->first();

        $dosTemplate = ChecklistTemplate::query()
            ->with(['sections.items' => fn ($q) => $q->where('is_active', true)->orderBy('sort_order')])
            ->where('slug', self::AFTERSALES_SLUG)
            ->first();

        // 1. Gather relevant submissions from database
        $subformSubmission = $this->findTemplateSubmission(self::SUBFORM_SLUG, $branch, $date, $userId);
        $docSubmission = $this->findTemplateSubmission(self::DOCUMENTATION_SLUG, $branch, $date, $userId);
        $dosSubmissions = $this->findDosSubmissions($branch, $date, $submissionId, $summaryMode, $userId);

        // Resolve real auditor names and date from DB submissions
        $auditors = collect();
        if ($subformSubmission) {
            $name = $subformSubmission->submitted_by_name ?: $subformSubmission->user?->name;
            if ($name) {
                $auditors->push($name);
            }
        }
        if ($docSubmission) {
            $name = $docSubmission->submitted_by_name ?: $docSubmission->user?->name;
            if ($name) {
                $auditors->push($name);
            }
        }
        foreach ($dosSubmissions as $sub) {
            $name = $sub->submitted_by_name ?: $sub->user?->name;
            if ($name) {
                $auditors->push($name);
            }
        }
        $auditorText = $auditors->unique()->filter()->implode(', ') ?: 'Operational Checkers';

        $resolvedDate = $date
            ?: ($dosSubmissions->first()?->audit_date?->toDateString()
            ?: ($subformSubmission?->audit_date?->toDateString()
            ?: ($docSubmission?->audit_date?->toDateString()
            ?: now()->toDateString())));

        $resolvedBranch = $branch ?: ($dosSubmissions->first()?->branch ?: '');

        // 2. Extract Subform Answers from database
        $extractedSubformAnswers = [];

        // Check direct subform submission responses
        if ($subformSubmission) {
            foreach ($subformSubmission->responses as $response) {
                $status = $response->status;
                if ($status) {
                    $entry = [
                        'status' => $status,
                        'remark' => $response->remark ?? $response->finding ?? '',
                    ];
                    if ($response->item_key) {
                        $extractedSubformAnswers[$response->item_key] = $entry;
                    }
                    if ($response->checklist_item_id) {
                        $extractedSubformAnswers[(string) $response->checklist_item_id] = $entry;
                    }
                }
            }
        }

        // Check embedded responses across DOS submissions
        foreach ($dosSubmissions as $submission) {
            foreach ($submission->responses as $response) {
                $details = (array) ($response->details ?? []);
                $subAnswers = (array) ($details['subform_answers'] ?? []);
                foreach ($subAnswers as $k => $val) {
                    $status = null;
                    $remark = '';
                    if (is_string($val)) {
                        $status = $val;
                    } elseif (is_array($val)) {
                        $status = (string) ($val['status'] ?? '');
                        $remark = (string) ($val['remark'] ?? '');
                    }

                    if ($status && ! isset($extractedSubformAnswers[$k])) {
                        $extractedSubformAnswers[$k] = [
                            'status' => $status,
                            'remark' => $remark,
                        ];
                    }
                }
            }
        }

        // 3. Extract Documentation Samples & Answers from database
        $extractedDocSamples = [];

        // Check embedded documentation in DOS submissions (e.g. item 61)
        foreach ($dosSubmissions as $submission) {
            foreach ($submission->responses as $response) {
                $details = (array) ($response->details ?? []);
                if (! empty($details['documentation_samples']) && is_array($details['documentation_samples']) && empty($extractedDocSamples)) {
                    $validSamples = array_filter($details['documentation_samples'], function ($sample) {
                        if (! is_array($sample)) {
                            return false;
                        }
                        $answers = array_filter((array) ($sample['answers'] ?? []));
                        return ! empty($sample['ro_number']) || ! empty($sample['job_type']) || ! empty($answers);
                    });
                    if (! empty($validSamples)) {
                        $extractedDocSamples = array_values($validSamples);
                    }
                }

                if (empty($extractedDocSamples) && ! empty($details['documentation_answers']) && is_array($details['documentation_answers'])) {
                    $answers = array_filter($details['documentation_answers']);
                    if (! empty($answers)) {
                        $extractedDocSamples = [
                            [
                                'ro_number' => '',
                                'job_type' => '',
                                'answers' => $answers,
                            ],
                        ];
                    }
                }
            }
        }

        // Check standalone documentation submission
        if ($docSubmission && empty($extractedDocSamples)) {
            $context = (array) ($docSubmission->context ?? []);
            if (! empty($context['documentation_samples']) && is_array($context['documentation_samples'])) {
                $validSamples = array_filter($context['documentation_samples'], function ($sample) {
                    if (! is_array($sample)) {
                        return false;
                    }
                    $answers = array_filter((array) ($sample['answers'] ?? []));
                    return ! empty($sample['ro_number']) || ! empty($sample['job_type']) || ! empty($answers);
                });
                if (! empty($validSamples)) {
                    $extractedDocSamples = array_values($validSamples);
                }
            }

            if (empty($extractedDocSamples)) {
                foreach ($docSubmission->responses as $r) {
                    $details = (array) ($r->details ?? []);
                    if (! empty($details['customers']) && is_array($details['customers'])) {
                        $validSamples = array_filter($details['customers'], function ($sample) {
                            if (! is_array($sample)) {
                                return false;
                            }
                            $answers = array_filter((array) ($sample['answers'] ?? []));
                            return ! empty($sample['ro_number']) || ! empty($sample['mileage']) || ! empty($sample['job_type']) || ! empty($answers);
                        });
                        if (! empty($validSamples)) {
                            $extractedDocSamples = array_map(function ($s) {
                                return [
                                    'ro_number' => (string) ($s['ro_number'] ?? ''),
                                    'job_type' => (string) ($s['mileage'] ?? ($s['job_type'] ?? '')),
                                    'answers' => (array) ($s['answers'] ?? []),
                                ];
                            }, array_values($validSamples));
                            break;
                        }
                    }
                }
            }

            if (empty($extractedDocSamples) && $docSubmission->responses->isNotEmpty()) {
                $answers = [];
                foreach ($docSubmission->responses as $r) {
                    if ($r->status) {
                        if ($r->item_key) {
                            $answers[$r->item_key] = $r->status;
                        }
                        if ($r->checklist_item_id) {
                            $answers[(string) $r->checklist_item_id] = $r->status;
                        }
                    }
                }
                if (! empty($answers)) {
                    $extractedDocSamples = [
                        [
                            'ro_number' => (string) ($context['ro_number'] ?? ''),
                            'job_type' => (string) ($context['job_type'] ?? ''),
                            'answers' => $answers,
                        ],
                    ];
                }
            }
        }

        // 4. Compile Subform Results
        $subformResult = $this->compileSubformResults($subformTemplate, $extractedSubformAnswers);

        // 5. Compile Documentation Results (purely from database, no synthetic fake samples)
        $documentationResult = $this->compileDocumentationResults($docTemplate, $extractedDocSamples);

        $hasSubform = $subformResult['answered_count'] > 0;
        $hasDocumentation = $documentationResult['has_data'];
        $hasSubmissions = $hasSubform || $hasDocumentation;

        $buttonLabel = match (true) {
            $hasSubform && $hasDocumentation => 'Existing Submissions: Subform & Documentation',
            $hasSubform => 'Existing Submission: Subform',
            $hasDocumentation => 'Existing Submission: Documentation',
            default => 'No Subform / Documentation Submissions',
        };

        $badgeLabel = match (true) {
            $hasSubform && $hasDocumentation => 'SUBFORM & DOC SUBMITTED',
            $hasSubform => 'SUBFORM SUBMITTED',
            $hasDocumentation => 'DOC SUBMITTED',
            default => 'NO SUBFORM/DOC RECORDED',
        };

        return [
            'has_submissions' => $hasSubmissions,
            'has_subform' => $hasSubform,
            'has_documentation' => $hasDocumentation,
            'button_label' => $buttonLabel,
            'badge_label' => $badgeLabel,
            'audit_date' => $resolvedDate,
            'auditor' => $auditorText,
            'branch' => $resolvedBranch,
            'subform' => $subformResult,
            'documentation' => $documentationResult,
        ];
    }

    private function findTemplateSubmission(string $slug, ?string $branch, ?string $date, ?int $userId): ?ChecklistSubmission
    {
        return ChecklistSubmission::query()
            ->whereHas('template', fn ($q) => $q->where('slug', $slug))
            ->when($branch, fn ($q, $b) => $q->whereRaw('LOWER(TRIM(branch)) = ?', [mb_strtolower(trim($b))]))
            ->when($date, fn ($q, $d) => $q->whereDate('audit_date', $d))
            ->when($userId, fn ($q, $u) => $q->where(fn ($sub) => $sub->where('user_id', $u)->orWhere('submitted_by_user_id', $u)))
            ->with(['responses.item'])
            ->orderByDesc('audit_date')
            ->orderByDesc('id')
            ->first();
    }

    private function findDosSubmissions(?string $branch, ?string $date, ?int $submissionId, string $summaryMode, ?int $userId): Collection
    {
        if ($submissionId) {
            $single = ChecklistSubmission::query()
                ->where('id', $submissionId)
                ->with(['responses.item', 'submittedBy', 'user'])
                ->first();

            return $single ? collect([$single]) : collect();
        }

        $query = ChecklistSubmission::query()
            ->whereHas('template', fn ($q) => $q->where('slug', self::AFTERSALES_SLUG))
            ->when($branch, fn ($q, $b) => $q->whereRaw('LOWER(TRIM(branch)) = ?', [mb_strtolower(trim($b))]))
            ->when($date, fn ($q, $d) => $q->whereDate('audit_date', $d))
            ->when($summaryMode === 'user' && $userId, fn ($q) => $q->where(fn ($sub) => $sub->where('user_id', $userId)->orWhere('submitted_by_user_id', $userId)))
            ->with(['responses.item', 'submittedBy', 'user'])
            ->orderByDesc('audit_date')
            ->orderByDesc('id');

        $submissions = $query->get();

        if ($summaryMode === 'overall' && ! $date) {
            // Keep one latest submission per user
            return $submissions
                ->unique(fn (ChecklistSubmission $s) => $s->submitted_by_user_id ?: $s->user_id)
                ->values();
        }

        return $submissions;
    }

    private function compileSubformResults(?ChecklistTemplate $template, array $answers): array
    {
        if (! $template) {
            return [
                'total_items' => 0,
                'answered_count' => 0,
                'yes_count' => 0,
                'no_count' => 0,
                'na_count' => 0,
                'score_percent' => 0.0,
                'rating' => 'N/A',
                'sections' => [],
            ];
        }

        $sections = [];
        $totalItems = 0;
        $totalAnswered = 0;
        $totalYes = 0;
        $totalNo = 0;
        $totalNa = 0;

        foreach ($template->sections as $secIndex => $section) {
            $secItems = [];
            $secYes = 0;
            $secNo = 0;
            $secNa = 0;
            $secAnswered = 0;

            foreach ($section->items as $item) {
                $totalItems++;
                $answerData = $answers[$item->key]
                    ?? ($answers[(string) $item->id]
                    ?? null);

                $status = is_array($answerData) ? ($answerData['status'] ?? null) : (is_string($answerData) ? $answerData : null);
                $remark = is_array($answerData) ? ($answerData['remark'] ?? '') : '';

                if ($status && in_array(strtolower($status), ['yes', 'no', 'na'], true)) {
                    $status = strtolower($status);
                    $secAnswered++;
                    $totalAnswered++;
                    if ($status === 'yes') {
                        $secYes++;
                        $totalYes++;
                    } elseif ($status === 'no') {
                        $secNo++;
                        $totalNo++;
                    } elseif ($status === 'na') {
                        $secNa++;
                        $totalNa++;
                    }
                } else {
                    $status = null;
                }

                $meta = (array) ($item->metadata ?? []);

                $secItems[] = [
                    'id' => $item->id,
                    'key' => $item->key,
                    'number' => $meta['number'] ?? ($secIndex + 1),
                    'prompt' => $item->prompt,
                    'level' => $meta['level'] ?? 'Standard',
                    'coverage' => $meta['coverage'] ?? $section->title,
                    'subject' => $meta['subject'] ?? '',
                    'checker' => $meta['checker'] ?? ($item->responsible_role ?? ''),
                    'pic' => $meta['pic'] ?? '',
                    'status' => $status ?: 'unanswered',
                    'remark' => $remark,
                ];
            }

            $secApplicable = max(0, $secAnswered - $secNa);
            $secScore = $secApplicable > 0 ? round(($secYes / $secApplicable) * 100, 1) : 0.0;
            $secRating = $secAnswered > 0 ? ($secScore >= 80.0 ? 'PASS' : 'FAIL') : 'N/A';

            $sections[] = [
                'id' => $section->id,
                'key' => $section->key,
                'title' => $section->title,
                'items' => $secItems,
                'total' => count($secItems),
                'answered' => $secAnswered,
                'yes' => $secYes,
                'no' => $secNo,
                'na' => $secNa,
                'score_percent' => $secScore,
                'rating' => $secRating,
            ];
        }

        $overallApplicable = max(0, $totalAnswered - $totalNa);
        $overallScore = $overallApplicable > 0 ? round(($totalYes / $overallApplicable) * 100, 1) : 0.0;
        $overallRating = $totalAnswered > 0 ? ($overallScore >= 80.0 ? 'PASS' : 'FAIL') : 'N/A';

        return [
            'total_items' => $totalItems,
            'answered_count' => $totalAnswered,
            'yes_count' => $totalYes,
            'no_count' => $totalNo,
            'na_count' => $totalNa,
            'score_percent' => $overallScore,
            'rating' => $overallRating,
            'sections' => $sections,
        ];
    }

    private function compileDocumentationResults(?ChecklistTemplate $template, array $samples): array
    {
        if (! $template || empty($samples)) {
            return [
                'has_data' => false,
                'total_samples' => 0,
                'total_checks' => 0,
                'yes_count' => 0,
                'no_count' => 0,
                'na_count' => 0,
                'score_percent' => 0.0,
                'rating' => 'N/A',
                'samples' => [],
                'items_matrix' => [],
            ];
        }

        $allDocItems = $template->sections->flatMap->items;
        $totalDocItemsCount = $allDocItems->count(); // typically 17

        $totalChecks = 0;
        $totalYes = 0;
        $totalNo = 0;
        $totalNa = 0;

        $samplesSummary = [];
        foreach ($samples as $sIdx => $sData) {
            $ans = (array) ($sData['answers'] ?? []);
            $sYes = 0;
            $sNo = 0;
            $sNa = 0;
            $sAnswered = 0;

            foreach ($allDocItems as $di) {
                $val = $ans[$di->key] ?? ($ans[(string) $di->id] ?? null);
                if ($val && in_array(strtolower($val), ['yes', 'no', 'na'], true)) {
                    $val = strtolower($val);
                    $sAnswered++;
                    $totalChecks++;
                    if ($val === 'yes') {
                        $sYes++;
                        $totalYes++;
                    } elseif ($val === 'no') {
                        $sNo++;
                        $totalNo++;
                    } elseif ($val === 'na') {
                        $sNa++;
                        $totalNa++;
                    }
                }
            }

            $sApplicable = max(0, $sAnswered - $sNa);
            $sScore = $sApplicable > 0 ? round(($sYes / $sApplicable) * 100, 1) : ($sAnswered > 0 ? 100.0 : 0.0);
            $sRating = $sAnswered > 0 ? ($sScore >= 80.0 ? 'PASS' : 'FAIL') : 'N/A';

            $samplesSummary[] = [
                'index' => $sIdx + 1,
                'ro_number' => (string) ($sData['ro_number'] ?? ''),
                'job_type' => (string) ($sData['job_type'] ?? ''),
                'total' => $totalDocItemsCount,
                'answered' => $sAnswered,
                'yes' => $sYes,
                'no' => $sNo,
                'na' => $sNa,
                'score_percent' => $sScore,
                'rating' => $sRating,
                'answers' => $ans,
            ];
        }

        // Build 17-item evaluation matrix dynamically based on actual evaluated samples
        $itemsMatrix = [];
        $itemCounter = 1;
        foreach ($template->sections as $section) {
            foreach ($section->items as $docItem) {
                $sampleAnswers = [];
                $hasNo = false;
                $hasAnyEvaluated = false;
                $allEvaluatedAreYesOrNa = true;

                foreach ($samples as $sIdx => $sData) {
                    $ans = (array) ($sData['answers'] ?? []);
                    $val = $ans[$docItem->key] ?? ($ans[(string) $docItem->id] ?? '-');
                    if (is_string($val)) {
                        $val = strtolower(trim($val));
                    }
                    if (! in_array($val, ['yes', 'no', 'na'], true)) {
                        $val = '-';
                    }

                    $sampleAnswers[$sIdx] = $val;

                    if ($val === 'no') {
                        $hasNo = true;
                        $hasAnyEvaluated = true;
                        $allEvaluatedAreYesOrNa = false;
                    } elseif ($val === 'yes') {
                        $hasAnyEvaluated = true;
                    } elseif ($val === 'na') {
                        $hasAnyEvaluated = true;
                    }
                }

                $overallStatus = '-';
                if ($hasNo) {
                    $overallStatus = 'no';
                } elseif ($hasAnyEvaluated && $allEvaluatedAreYesOrNa) {
                    $overallStatus = 'yes';
                }

                $itemsMatrix[] = [
                    'number' => $itemCounter++,
                    'key' => $docItem->key,
                    'section' => $section->title,
                    'prompt' => $docItem->prompt,
                    'samples' => $sampleAnswers,
                    'sample_1' => $sampleAnswers[0] ?? '-',
                    'sample_2' => $sampleAnswers[1] ?? '-',
                    'sample_3' => $sampleAnswers[2] ?? '-',
                    'overall_status' => $overallStatus,
                ];
            }
        }

        $overallApplicable = max(0, $totalChecks - $totalNa);
        $overallScore = $overallApplicable > 0 ? round(($totalYes / $overallApplicable) * 100, 1) : 0.0;
        $overallRating = $totalChecks > 0 ? ($overallScore >= 80.0 ? 'PASS' : 'FAIL') : 'N/A';

        return [
            'has_data' => true,
            'total_samples' => count($samplesSummary),
            'total_checks' => $totalChecks,
            'yes_count' => $totalYes,
            'no_count' => $totalNo,
            'na_count' => $totalNa,
            'score_percent' => $overallScore,
            'rating' => $overallRating,
            'samples' => $samplesSummary,
            'items_matrix' => $itemsMatrix,
        ];
    }
}
