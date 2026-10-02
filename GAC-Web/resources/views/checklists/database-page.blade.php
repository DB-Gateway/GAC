@php
    $bootstrapData = isset($checklistBootstrap)
        ? (is_array($checklistBootstrap) ? $checklistBootstrap : json_decode(json_encode($checklistBootstrap), true))
        : [];
    $templateSource = $template ?? data_get($bootstrapData, 'template', []);
    $submissionSource = $submission ?? data_get($bootstrapData, 'submission');
    $templateData = (is_array($templateSource) ? $templateSource : json_decode(json_encode($templateSource), true)) ?: [];
    $submissionData = $submissionSource
        ? (is_array($submissionSource) ? $submissionSource : json_decode(json_encode($submissionSource), true))
        : null;
    $branchSource = $branches ?? data_get($bootstrapData, 'branches', []);
    $branchData = (is_array($branchSource) ? $branchSource : json_decode(json_encode($branchSource), true)) ?: [];
    $templateSlug = (string) data_get($templateData, 'slug', '');
    $templateName = (string) data_get($templateData, 'name', $pageTitle);
    $templateDescription = (string) data_get($templateData, 'description', '');
    $templateInstructions = (string) data_get(
        $templateData,
        'instructions',
        data_get($templateData, 'settings.instructions', '')
    );
    $canManageTemplate = (bool) ($canManageTemplate
        ?? data_get(
            $bootstrapData,
            'can_manage_template',
            Auth::user()?->hasAdministrativeAccess() === true
        ));
    $subformTemplateSource = $subformTemplate ?? data_get($bootstrapData, 'subform_template');
    $subformTemplateData = (is_array($subformTemplateSource) ? $subformTemplateSource : json_decode(json_encode($subformTemplateSource), true)) ?: null;
    $documentationTemplateSource = $documentationTemplate ?? data_get($bootstrapData, 'documentation_template');
    $documentationTemplateData = (is_array($documentationTemplateSource) ? $documentationTemplateSource : json_decode(json_encode($documentationTemplateSource), true)) ?: null;

    $resolveChecklistRoute = static function (array $names) use ($templateSlug): ?string {
        if ($templateSlug === '') {
            return null;
        }

        foreach ($names as $name) {
            if (\Illuminate\Support\Facades\Route::has($name)) {
                return route($name, [$templateSlug]);
            }
        }

        return null;
    };

    $loadUrl = $resolveChecklistRoute(['checklists.load', 'checklists.submission.show']);
    $draftUrl = $resolveChecklistRoute(['checklists.save-draft', 'checklists.draft', 'checklists.submission.store']);
    $submitUrl = $resolveChecklistRoute(['checklists.submit', 'checklists.submission.store']);
    $resetUrl = $resolveChecklistRoute(['checklists.reset', 'checklists.submission.destroy']);
    $templateUrl = $resolveChecklistRoute(['checklists.template.update', 'checklists.update-template']);
    $deleteTemplateUrl = $resolveChecklistRoute(['checklists.template.destroy', 'api.checklists.destroy']);
    $subformTemplateUrl = \Illuminate\Support\Facades\Route::has('checklists.template.update')
        ? route('checklists.template.update', ['dealer-operations-standards-subform'])
        : '/checklists/dealer-operations-standards-subform';
    $documentationTemplateUrl = \Illuminate\Support\Facades\Route::has('checklists.template.update')
        ? route('checklists.template.update', ['dealer-operations-standards-documentation'])
        : '/checklists/dealer-operations-standards-documentation';
    $toggleItemUrl = $resolveChecklistRoute(['checklists.item.toggle', 'api.checklists.item.toggle']);
    $createTemplateUrl = \Illuminate\Support\Facades\Route::has('checklists.template.store')
        ? route('checklists.template.store')
        : '/checklists/templates';
    $initialDate = (string) data_get(
        $submissionData,
        'audit_date',
        data_get($submissionData, 'date', data_get($bootstrapData, 'date', now()->toDateString()))
    );
    $initialBranch = (string) data_get(
        $submissionData,
        'branch',
        data_get($bootstrapData, 'branch', Auth::user()->branch ?? '')
    );
    $workspaceData = collect($checklistWorkspace ?? [])->map(
        fn ($option) => is_array($option) ? $option : json_decode(json_encode($option), true)
    )->all();
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    @include('partials.browser-push-head')
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#F5F6F8">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Gateway Audit Compliance | Checklists - {{ $pageTitle }}</title>
    <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
    <link rel="stylesheet" href="{{ asset($stylesheet) }}">
    <link rel="stylesheet" href="{{ asset('css/gateway-theme.css') }}">
    <style>
        .database-checklist .filters { grid-template-columns: minmax(190px, 1fr) minmax(170px, .7fr) minmax(220px, 1fr) auto; }
        .database-checklist .template-chip { min-height: 39px; display: flex; align-items: center; padding: 8px 10px; border: 1px solid var(--line-dark); border-radius: 6px; background: var(--fog-100); font-size: 11px; font-weight: 750; }
        .database-checklist .database-status { min-width: 122px; justify-self: end; text-align: right; color: var(--slate-600); font-size: 10px; font-weight: 800; }
        .database-checklist .item-copy { display: grid; gap: 7px; }
        .database-checklist .item-title-row { min-width: 0; display: flex; align-items: flex-start; gap: 8px; }
        .database-checklist .item-title-row .item-text { min-width: 0; flex: 1 1 auto; }
        .database-checklist .how-to-check-button { width: 24px; height: 24px; flex: 0 0 24px; display: inline-grid; place-items: center; padding: 0; border: 1px solid var(--line-dark); border-radius: 50%; color: var(--gateway-red-500); background: #fff; font: 800 12px/1 Georgia, serif; cursor: pointer; transition: border-color 150ms ease, background 150ms ease, color 150ms ease, box-shadow 150ms ease; }
        .database-checklist .how-to-check-button:hover { border-color: var(--gateway-red-500); color: #fff; background: var(--gateway-red-500); }
        .database-checklist .how-to-check-button:focus-visible { border-color: var(--gateway-red-500); outline: 0; box-shadow: 0 0 0 3px rgba(227, 28, 61, .16); }
        .database-checklist .item-description { margin: 0; color: var(--slate-600); font-size: 10px; line-height: 1.5; white-space: pre-line; }
        .database-checklist .response-fields { display: grid; gap: 7px; }
        .database-checklist .response-fields textarea { width: 100%; min-height: 48px; resize: vertical; }
        .database-checklist .response-fields label { display: grid; gap: 4px; color: var(--slate-600); font-size: 8px; font-weight: 850; letter-spacing: .05em; text-transform: uppercase; }
        .database-checklist .response-fields :is(input, select) { width: 100%; }
        .database-checklist .escalation-input { min-height: 39px; padding: 8px 10px; border: 1px solid var(--line-dark); border-radius: 6px; outline: 0; color: var(--graphite-900); background: #fff; font-size: 11px; }
        .database-checklist .escalation-input:focus { border-color: var(--gateway-red-500); box-shadow: 0 0 0 3px rgba(227, 28, 61, .12); }
        .database-checklist .response-fields .photo-attachment-label { display: inline-flex; align-items: center; gap: 5px; width: max-content; max-width: 100%; color: var(--gateway-red-500); font-size: 10px; font-weight: 750; letter-spacing: 0; text-transform: none; cursor: pointer; }
        .database-checklist .section-empty { padding: 24px; color: var(--slate-600); text-align: center; }
        .database-checklist .loading-mask { padding: 16px; color: var(--slate-600); text-align: center; }
        .database-checklist [hidden] { display: none !important; }
        .database-checklist .restroom-scroll { overflow-x: auto; }
        .database-checklist .restroom-table { width: 100%; min-width: 980px; border-collapse: collapse; background: #fff; }
        .database-checklist .restroom-table th,
        .database-checklist .restroom-table td { padding: 9px; border-right: 1px solid var(--line); border-bottom: 1px solid var(--line); vertical-align: middle; }
        .database-checklist .restroom-table th:first-child { min-width: 300px; text-align: left; }
        .database-checklist .restroom-table th:last-child { min-width: 210px; }
        .database-checklist .restroom-table .slot-cell { min-width: 82px; text-align: center; }
        .database-checklist .restroom-table tbody th .item-text { text-transform: lowercase; }
        .database-checklist .restroom-table tbody th .item-text::first-letter { text-transform: uppercase; }
        .database-checklist .checklist-workspace-header { min-width: 0; display: flex; align-items: center; gap: 14px; margin-bottom: 16px; }
        .database-checklist .checklist-workspace-switcher { min-width: 0; display: flex; align-items: stretch; flex: 1 1 auto; gap: 4px; margin: 0; padding: 4px; overflow-x: auto; overscroll-behavior-inline: contain; border: 1px solid #e7edf3; border-radius: 8px !important; background: #fff; box-shadow: none; scrollbar-width: thin; }
        .database-checklist .checklist-workspace-option { min-width: max-content; min-height: 36px; flex: 1 0 auto; display: inline-flex; align-items: center; justify-content: center; padding: 7px 11px; border: 1px solid transparent; border-radius: 6px !important; color: #526176; font-size: 10px; font-weight: 800; line-height: 1.35; text-align: center; text-decoration: none; white-space: nowrap; transition: background 150ms ease, color 150ms ease, border-color 150ms ease; }
        .database-checklist .checklist-workspace-option > i { display: none; }
        .database-checklist .checklist-workspace-option:hover,
        .database-checklist .checklist-workspace-option.is-active { border-color: rgba(232, 25, 63, .34); color: #122033; background: rgba(232, 25, 63, .1); box-shadow: none; }
        .database-checklist .checklist-page-heading { display: flex; align-items: center; justify-content: space-between; gap: 18px; margin-bottom: 15px; padding: 18px 20px; border: 1px solid rgba(138, 148, 166, .28); border-left: 4px solid var(--gateway-red-500); background: #fff; box-shadow: 0 2px 10px rgba(11, 15, 26, .055); }
        .database-checklist .checklist-editor-actions { width: auto; flex: 0 0 auto; margin: 0; }
        .database-checklist .slot-select { min-height: 34px; width: 100%; padding: 5px; border: 1px solid var(--line-dark); border-radius: 6px; background: #fff; font-size: 9px; font-weight: 800; }
        .database-checklist .slot-select.is-good { border-color: var(--success); color: var(--success); background: var(--success-soft); }
        .database-checklist .slot-select.is-not-good { border-color: var(--danger); color: var(--danger); background: var(--danger-soft); }
        .database-checklist .restroom-remark { width: 100%; min-height: 48px; resize: vertical; }
        .database-checklist .slot-cell-toggle { min-width: 82px; text-align: center; }
        .database-checklist .restroom-slot-checkbox-label { display: inline-flex; align-items: center; justify-content: center; width: 100%; height: 100%; min-height: 32px; cursor: pointer; }
        .database-checklist .restroom-slot-toggle { width: 18px; height: 18px; accent-color: var(--gateway-red-500); cursor: pointer; }
        .database-checklist .slot-cell-off { min-width: 82px; text-align: center; background-color: #f8fafc; }
        .database-checklist .badge-slot-off { display: inline-block; color: #94a3b8; font-size: 16px; font-weight: 700; user-select: none; }
        .database-checklist .restroom-include-cell { width: 72px; min-width: 60px; text-align: center; }
        .database-checklist .restroom-checkbox-label { display: inline-flex; align-items: center; justify-content: center; cursor: pointer; }
        .database-checklist .restroom-item-toggle { width: 18px; height: 18px; accent-color: var(--gateway-red-500); cursor: pointer; }
        .database-checklist .item-row-excluded { background-color: #f8fafc; opacity: 0.78; }
        .database-checklist .item-text-excluded { color: #64748b; text-decoration: line-through; }
        .database-checklist .item-excluded-tag { display: inline-flex; align-items: center; gap: 4px; margin-left: 6px; padding: 2px 7px; border-radius: 4px; background: #fee2e2; color: #dc2626; font-size: 10px; font-weight: 700; text-decoration: none !important; }
        .database-checklist .template-editor-dialog { width: min(1050px, calc(100vw - 32px)); max-height: 90vh; padding: 0; border: 0; border-radius: 12px; box-shadow: 0 24px 80px rgba(11, 15, 26, .28); }
        .database-checklist .template-editor-dialog::backdrop { background: rgba(11, 15, 26, .62); }
        .database-checklist .how-to-check-dialog { width: min(620px, calc(100vw - 32px)); max-height: min(82vh, 720px); padding: 0; overflow: hidden; border: 0; border-radius: 12px; color: var(--graphite-900); background: #fff; box-shadow: 0 24px 80px rgba(11, 15, 26, .28); }
        .database-checklist .how-to-check-dialog::backdrop { background: rgba(11, 15, 26, .62); }
        .database-checklist .how-to-check-shell { max-height: min(82vh, 720px); display: grid; grid-template-rows: auto minmax(0, 1fr) auto; }
        .database-checklist .how-to-check-header,
        .database-checklist .how-to-check-footer { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 14px 18px; border-bottom: 1px solid var(--line); }
        .database-checklist .how-to-check-header h3 { margin: 0; font-size: 16px; }
        .database-checklist .how-to-check-body { overflow: auto; padding: 18px; }
        .database-checklist .how-to-check-item { margin: 0 0 12px; color: var(--graphite-800); font-size: 12px; line-height: 1.5; white-space: pre-line; }
        .database-checklist .how-to-check-guidance { margin: 0; padding: 14px; border: 1px solid var(--line); border-left: 4px solid var(--gateway-red-500); border-radius: 8px; color: var(--slate-600); background: var(--fog-100); font-size: 12px; line-height: 1.65; white-space: pre-line; }
        .database-checklist .how-to-check-footer { justify-content: flex-end; border-top: 1px solid var(--line); border-bottom: 0; }
        .database-checklist .template-editor-shell { max-height: 90vh; display: grid; grid-template-rows: auto minmax(0, 1fr) auto; background: #fff; }
        .database-checklist .template-editor-header,
        .database-checklist .template-editor-footer { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 15px 18px; border-bottom: 1px solid var(--line); }
        .database-checklist .template-editor-footer { justify-content: flex-end; border-top: 1px solid var(--line); border-bottom: 0; }
        .database-checklist .template-editor-header h3 { margin: 0; font-size: 16px; }
        .database-checklist .template-editor-body { overflow: auto; padding: 18px; }
        .database-checklist .editor-template-fields { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; margin-bottom: 18px; }
        .database-checklist .editor-template-fields .wide { grid-column: 1 / -1; }
        .database-checklist .editor-section { margin-bottom: 14px; padding: 14px; border: 1px solid var(--line); border-radius: 9px; background: var(--fog-100); }
        .database-checklist .editor-section-head { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 9px; margin-bottom: 10px; }
        .database-checklist .editor-add-row { margin-top: 10px; }
        @media (max-width: 1100px) {
            .database-checklist .filters { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        @media (max-width: 900px) {
            .database-checklist .checklist-workspace-header { align-items: stretch; flex-direction: column; }
            .database-checklist .checklist-workspace-switcher { width: 100%; }
        }
        @media (max-width: 680px) {
            .database-checklist .filters,
            .database-checklist .editor-template-fields { grid-template-columns: 1fr; }
            .database-checklist .database-status { justify-self: start; text-align: left; }
            .database-checklist .checklist-page-heading { align-items: stretch; flex-direction: column; padding: 15px; }
            .database-checklist .checklist-editor-actions { width: 100%; justify-content: stretch; }
            .database-checklist .checklist-editor-actions .button { flex: 1 1 auto; }
        }
        @media print {
            .database-checklist .checklist-editor-actions,
            .database-checklist .template-editor-dialog { display: none !important; }
            .database-checklist .restroom-table { min-width: 0; font-size: 7px; }
            .database-checklist .restroom-table th,
            .database-checklist .restroom-table td { padding: 3px; }
        }
        /* Checklist Summary Banner (Horizontal Container matching checklist-page-heading) */
        .database-checklist .checklist-summary-banner { display: flex; flex-direction: column; gap: 14px; margin-bottom: 15px; padding: 18px 20px; border: 1px solid rgba(138, 148, 166, .28); border-left: 4px solid var(--gateway-red-500); background: #fff; box-shadow: 0 2px 10px rgba(11, 15, 26, .055); }
        .database-checklist .checklist-summary-banner .summary-banner-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 24px; width: 100%; }
        .database-checklist .checklist-summary-banner .summary-main { flex: 1 1 auto; min-width: 0; text-align: left; margin: 0; padding: 0; align-self: flex-start; }
        .database-checklist .checklist-summary-banner .summary-eyebrow { display: inline-flex; align-items: center; gap: 6px; color: var(--gateway-red-500); font-size: 10px; font-weight: 850; text-transform: uppercase; letter-spacing: .06em; margin-bottom: 4px; text-align: left; }
        .database-checklist .checklist-summary-banner .summary-eyebrow-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--gateway-red-500); }
        .database-checklist .checklist-summary-banner .summary-heading { font-size: 15.5px; font-weight: 850; color: var(--graphite-900); margin: 0 0 6px; text-align: left; }
        .database-checklist .checklist-summary-banner .summary-guide { font-size: 12px; color: var(--slate-600); margin: 0; line-height: 1.5; text-align: left; }
        .database-checklist .checklist-summary-banner .summary-metrics { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px 10px; flex-shrink: 0; align-self: flex-start; min-width: 310px; max-width: 440px; }
        .database-checklist .checklist-summary-banner .summary-chip { display: flex; align-items: center; gap: 8px; padding: 6px 12px; border-radius: 6px; border: 1px solid #e2e8f0; background: #f8fafc; font-size: 11px; font-weight: 800; color: #334155; white-space: nowrap; box-shadow: 0 1px 2px rgba(0,0,0,.02); }
        .database-checklist .checklist-summary-banner .summary-chip i { width: 14px; text-align: center; flex-shrink: 0; }
        .database-checklist .checklist-summary-banner .summary-chip.is-items { background: #eff6ff; color: #1d4ed8; border-color: #bfdbfe; }
        .database-checklist .checklist-summary-banner .summary-chip.is-subform { background: #f5f3ff; color: #6d28d9; border-color: #ddd6fe; }
        .database-checklist .checklist-summary-banner .summary-chip.is-doc { background: #fdf2f8; color: #be185d; border-color: #fbcfe8; }
        .database-checklist .checklist-summary-banner .summary-chip.is-total { grid-column: 1 / -1; justify-content: center; background: #fef2f2; color: #b91c1c; border-color: #fecaca; }
        .database-checklist .checklist-summary-banner .summary-chip.is-no-subform { background: #f1f5f9; color: #64748b; border-color: #e2e8f0; }
        .database-checklist .checklist-summary-banner .checker-filter-bar { display: flex; align-items: center; gap: 10px; padding-top: 13px; border-top: 1px solid #f1f5f9; flex-wrap: wrap; width: 100%; margin: 0; text-align: left; }
        .database-checklist .checklist-summary-banner .checker-filter-label { font-size: 11px; font-weight: 850; color: #64748b; text-transform: uppercase; letter-spacing: .04em; margin-right: 2px; display: inline-flex; align-items: center; gap: 6px; flex-shrink: 0; }
        .database-checklist .checklist-summary-banner .checker-filter-label i { color: var(--gateway-red-500); }
        .database-checklist .checklist-summary-banner .checker-filter-pills { display: flex; align-items: center; gap: 7px; flex-wrap: wrap; flex: 1 1 auto; }
        .database-checklist .checklist-summary-banner .checker-pill-btn { border: 1px solid #cbd5e1; background: #ffffff; color: #475569; font-size: 11px; font-weight: 800; padding: 5px 12px; border-radius: 6px; cursor: pointer; transition: all 140ms ease; display: inline-flex; align-items: center; gap: 6px; box-shadow: 0 1px 2px rgba(0,0,0,.03); }
        .database-checklist .checklist-summary-banner .checker-pill-btn:hover { background: #f8fafc; border-color: #94a3b8; color: #1e293b; }
        .database-checklist .checklist-summary-banner .checker-pill-btn.is-active { background: var(--gateway-red-500); border-color: var(--gateway-red-500); color: #ffffff; box-shadow: 0 2px 6px rgba(185, 28, 28, .22); }
        @media (max-width: 960px) {
            .database-checklist .checklist-summary-banner .summary-banner-top { flex-direction: column; align-items: stretch; gap: 14px; }
            .database-checklist .checklist-summary-banner .summary-metrics { min-width: 0; max-width: none; width: 100%; }
            .database-checklist .checklist-summary-banner .checker-filter-bar { flex-direction: column; align-items: flex-start; gap: 8px; }
        }
        @media (max-width: 540px) {
            .database-checklist .checklist-summary-banner .summary-metrics { grid-template-columns: 1fr; }
        }
        .database-checklist .checker-badge { display: inline-flex; align-items: center; gap: 4px; padding: 2px 7px; border-radius: 4px; font-size: 10px; font-weight: 850; letter-spacing: .03em; text-transform: uppercase; background: #f1f5f9; color: #334155; border: 1px solid #cbd5e1; }
        .database-checklist .checker-badge.is-ce { background: #e0f2fe; color: #0284c7; border-color: #bae6fd; }
        .database-checklist .checker-badge.is-ws { background: #ede9fe; color: #6d28d9; border-color: #ddd6fe; }
        .database-checklist .checker-badge.is-asm { background: #fee2e2; color: #b91c1c; border-color: #fecaca; }
        .database-checklist .checker-badge.is-parts { background: #fef3c7; color: #b45309; border-color: #fde68a; }
        .database-checklist .checker-badge.is-jc { background: #d1fae5; color: #047857; border-color: #a7f3d0; }

        /* Subform Eligibility & Dropdown Box */
        .database-checklist .subform-eligibility-box { background: #f0f7ff; border: 1.5px solid #bfdbfe; border-radius: 12px; padding: 14px 16px; margin: 10px 0; }
        .database-checklist .subform-eligibility-header { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 6px; flex-wrap: wrap; }
        .database-checklist .subform-eligibility-title { display: inline-flex; align-items: center; gap: 6px; color: #1d4ed8; font-size: 11px; font-weight: 900; letter-spacing: .06em; text-transform: uppercase; }
        .database-checklist .subform-eligibility-badge { padding: 3px 8px; border-radius: 5px; font-size: 10px; font-weight: 800; text-transform: uppercase; letter-spacing: .04em; }
        .database-checklist .subform-eligibility-badge.is-subform { background: #dcfce7; color: #15803d; border: 1px solid #86efac; }
        .database-checklist .subform-eligibility-badge.is-na { background: #fef3c7; color: #b45309; border: 1px solid #fde68a; }
        .database-checklist .subform-eligibility-badge.is-pending { background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; }
        .database-checklist .subform-eligibility-desc { font-size: 11.5px; color: #475569; margin: 0 0 12px; line-height: 1.4; font-weight: 600; }
        .database-checklist .subform-eligibility-buttons { display: flex; gap: 10px; }
        .database-checklist .eligibility-btn { flex: 1; display: inline-flex; align-items: center; justify-content: center; gap: 8px; padding: 10px 14px; border: 1.5px solid #cbd5e1; border-radius: 8px; background: #ffffff; font-size: 11.5px; font-weight: 800; color: #475569; cursor: pointer; transition: all 150ms ease; }
        .database-checklist .eligibility-btn:hover { background: #f8fafc; border-color: #94a3b8; }
        .database-checklist .eligibility-btn.is-active.btn-subform { border-color: #2563eb; background: #2563eb; color: #ffffff; box-shadow: 0 2px 6px rgba(37,99,235,.25); }
        .database-checklist .eligibility-btn.is-active.btn-na { border-color: #d97706; background: #d97706; color: #ffffff; box-shadow: 0 2px 6px rgba(217,119,6,.25); }

        .database-checklist .subform-dropbox-container { background: #f8fafc; border: 1.5px solid #cbd5e1; border-radius: 12px; padding: 16px; margin-top: 14px; box-shadow: 0 2px 10px rgba(15,23,42,.04); }
        .database-checklist .subform-dropbox-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 14px; }
        .database-checklist .subform-title { display: block; font-size: 11.5px; font-weight: 900; color: #1e293b; letter-spacing: .05em; margin-bottom: 3px; }
        .database-checklist .subform-counts { display: flex; align-items: center; gap: 8px; font-size: 11px; font-weight: 750; color: #64748b; }
        .database-checklist .subform-counts .noncompliant-pill { color: #dc2626; font-weight: 800; }
        .database-checklist .subform-view-toggle { padding: 4px 9px; font-size: 10.5px; }

        .database-checklist .subform-question-select { width: 100%; min-height: 38px; padding: 7px 10px; border: 1.5px solid #94a3b8; border-radius: 8px; background: #ffffff; font-size: 12px; font-weight: 750; color: #1e293b; margin-bottom: 12px; cursor: pointer; }
        .database-checklist .subform-question-select:focus { border-color: #2563eb; outline: 0; box-shadow: 0 0 0 3px rgba(37,99,235,.15); }

        .database-checklist .subform-active-card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 16px; box-shadow: 0 2px 8px rgba(15,23,42,.04); margin-bottom: 12px; }
        .database-checklist .subform-card-pills { display: flex; gap: 8px; margin-bottom: 10px; flex-wrap: wrap; }
        .database-checklist .subform-card-badge { display: inline-flex; align-items: center; padding: 3px 8px; border-radius: 5px; font-size: 10px; font-weight: 850; letter-spacing: .04em; }
        .database-checklist .subform-card-badge.question-num { background: #e0f2fe; color: #0284c7; }
        .database-checklist .subform-card-badge.checker-badge { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
        .database-checklist .subform-active-prompt { font-size: 13.5px; font-weight: 800; color: #0f172a; line-height: 1.45; margin-bottom: 10px; }
        .database-checklist .subform-htc-box { background: #f8fafc; border-left: 3px solid #3b82f6; padding: 8px 12px; font-size: 11px; color: #475569; border-radius: 4px; margin-bottom: 12px; display: flex; gap: 8px; align-items: flex-start; }
        .database-checklist .subform-htc-box i { color: #3b82f6; margin-top: 2px; }

        .database-checklist .subform-choices-row { display: flex; gap: 8px; margin-bottom: 12px; }
        .database-checklist .subform-choice-btn { flex: 1; min-height: 38px; display: inline-flex; align-items: center; justify-content: center; gap: 6px; padding: 8px; border: 1.5px solid #cbd5e1; border-radius: 8px; background: #ffffff; font-size: 12px; font-weight: 850; color: #475569; cursor: pointer; transition: all 140ms ease; }
        .database-checklist .subform-choice-btn:hover { background: #f8fafc; border-color: #94a3b8; }
        .database-checklist .subform-choice-btn.btn-yes.is-active { background: #16a34a; border-color: #16a34a; color: #ffffff; }
        .database-checklist .subform-choice-btn.btn-no.is-active { background: #dc2626; border-color: #dc2626; color: #ffffff; }
        .database-checklist .subform-choice-btn.btn-na.is-active { background: #d97706; border-color: #d97706; color: #ffffff; }

        .database-checklist .subform-nav-row { display: flex; justify-content: space-between; align-items: center; }
        .database-checklist .subform-status-banner { display: flex; align-items: center; gap: 8px; padding: 10px 14px; border-radius: 8px; font-size: 11.5px; font-weight: 800; margin-top: 10px; }
        .database-checklist .subform-status-banner.is-compliant { background: #dcfce7; color: #166534; border: 1px solid #86efac; }
        .database-checklist .subform-status-banner.is-noncompliant { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
        .database-checklist .subform-status-banner.is-inprogress { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; }

        .database-checklist .subform-all-view-mode { display: flex; flex-direction: column; gap: 10px; margin-bottom: 12px; }
        .database-checklist .subform-list-card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; display: grid; gap: 8px; }
        .database-checklist .subform-list-card-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 12px; font-weight: 800; color: #1e293b; }

        /* Documentation Box & Multi-Sample Audit */
        .database-checklist .documentation-inline-wrapper { margin-top: 12px; }
        .database-checklist .doc-audit-container { background: #f8fafc; border: 1.5px solid #cbd5e1; border-radius: 12px; padding: 16px; box-shadow: 0 2px 10px rgba(15,23,42,.04); }
        .database-checklist .doc-audit-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 14px; flex-wrap: wrap; }
        .database-checklist .doc-title { display: block; font-size: 11.5px; font-weight: 900; color: #1e293b; letter-spacing: .05em; margin-bottom: 3px; }
        .database-checklist .doc-counts { display: flex; align-items: center; gap: 8px; font-size: 11px; font-weight: 750; color: #64748b; }
        .database-checklist .doc-counts .noncompliant-pill { color: #dc2626; font-weight: 800; }
        .database-checklist .doc-sample-tabs { display: flex; gap: 8px; margin-bottom: 14px; border-bottom: 1.5px solid #e2e8f0; padding-bottom: 8px; flex-wrap: wrap; }
        .database-checklist .doc-sample-tab { display: inline-flex; align-items: center; gap: 6px; padding: 6px 14px; border-radius: 8px; border: 1.5px solid #cbd5e1; background: #ffffff; color: #475569; font-size: 11.5px; font-weight: 800; cursor: pointer; transition: all 140ms ease; }
        .database-checklist .doc-sample-tab:hover { background: #f1f5f9; border-color: #94a3b8; }
        .database-checklist .doc-sample-tab.is-active { background: #2563eb; border-color: #2563eb; color: #ffffff; box-shadow: 0 2px 6px rgba(37,99,235,.25); }
        .database-checklist .doc-sample-tab-badge { font-size: 10px; padding: 2px 6px; border-radius: 9999px; background: rgba(0,0,0,.08); }
        .database-checklist .doc-sample-tab.is-active .doc-sample-tab-badge { background: rgba(255,255,255,.25); color: #ffffff; }
        .database-checklist .doc-meta-card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px 14px; margin-bottom: 14px; display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .database-checklist .doc-meta-field { display: flex; flex-direction: column; gap: 4px; }
        .database-checklist .doc-meta-label { font-size: 10.5px; font-weight: 800; text-transform: uppercase; letter-spacing: .04em; color: #64748b; }
        .database-checklist .doc-meta-input { padding: 6px 10px; border: 1.5px solid #cbd5e1; border-radius: 6px; font-size: 12px; font-weight: 700; color: #1e293b; background: #ffffff; }
        .database-checklist .doc-meta-input:focus { border-color: #2563eb; outline: 0; box-shadow: 0 0 0 3px rgba(37,99,235,.15); }
        .database-checklist .doc-section-card { background: #ffffff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px; margin-bottom: 12px; }
        .database-checklist .doc-section-title { font-size: 12px; font-weight: 850; color: #0f172a; margin-bottom: 10px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 6px; }
        .database-checklist .doc-question-row { padding: 10px 0; border-bottom: 1px solid #f1f5f9; }
        .database-checklist .doc-question-row:last-child { border-bottom: none; padding-bottom: 0; }
        .database-checklist .doc-question-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; margin-bottom: 6px; }
        .database-checklist .doc-question-prompt { font-size: 12px; font-weight: 750; color: #1e293b; line-height: 1.4; }
        .database-checklist .doc-choices-row { display: flex; gap: 8px; margin-top: 6px; }
        .database-checklist .doc-choice-btn { flex: 1; min-height: 32px; display: inline-flex; align-items: center; justify-content: center; gap: 5px; padding: 6px; border: 1.5px solid #cbd5e1; border-radius: 6px; background: #ffffff; font-size: 11px; font-weight: 800; color: #475569; cursor: pointer; transition: all 140ms ease; }
        .database-checklist .doc-choice-btn:hover { background: #f8fafc; border-color: #94a3b8; }
        .database-checklist .doc-choice-btn.btn-yes.is-active { background: #16a34a; border-color: #16a34a; color: #ffffff; }
        .database-checklist .doc-choice-btn.btn-no.is-active { background: #dc2626; border-color: #dc2626; color: #ffffff; }
        .database-checklist .doc-choice-btn.btn-na.is-active { background: #d97706; border-color: #d97706; color: #ffffff; }
        .database-checklist .doc-status-banner { display: flex; align-items: center; gap: 8px; padding: 10px 14px; border-radius: 8px; font-size: 11.5px; font-weight: 800; margin-top: 10px; }
        .database-checklist .doc-status-banner.is-compliant { background: #dcfce7; color: #166534; border: 1px solid #86efac; }
        .database-checklist .doc-status-banner.is-noncompliant { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
        .database-checklist .doc-status-banner.is-inprogress { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; }

        /* Scope Switcher Tabs in Template Editor */
        .editor-scope-tabs { display: flex; gap: 6px; margin-top: 8px; flex-wrap: wrap; }
        .editor-scope-tab { display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; border-radius: 6px; border: 1.5px solid #cbd5e1; background: #ffffff; color: #475569; font-size: 11.5px; font-weight: 800; cursor: pointer; transition: all 140ms ease; }
        .editor-scope-tab:hover { background: #f8fafc; border-color: #94a3b8; }
        .editor-scope-tab.is-active { background: var(--gateway-red-500, #e8193f); border-color: var(--gateway-red-500, #e8193f); color: #ffffff; }

        /* User / Checker Filter in Template Editor */
        .database-checklist .editor-filter-card { margin: 0 0 16px; padding: 12px 14px; border: 1.5px solid #cbd5e1; border-radius: 9px; background: #ffffff; box-shadow: 0 1px 3px rgba(0,0,0,.04); }
        .database-checklist .editor-filter-header { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; margin-bottom: 10px; }
        .database-checklist .editor-filter-title { display: inline-flex; align-items: center; gap: 7px; font-size: 12px; font-weight: 800; color: #1e293b; text-transform: uppercase; letter-spacing: .02em; }
        .database-checklist .editor-filter-title i { color: var(--gateway-red-500, #e8193f); }
        .database-checklist .editor-filter-search-wrap { position: relative; display: flex; align-items: center; min-width: 220px; flex: 0 1 320px; }
        .database-checklist .editor-filter-search-wrap i { position: absolute; left: 10px; font-size: 11px; color: #94a3b8; pointer-events: none; }
        .database-checklist .editor-filter-search { width: 100%; padding: 6px 10px 6px 30px !important; border: 1px solid #cbd5e1 !important; border-radius: 6px !important; font-size: 11.5px !important; background: #f8fafc; transition: all 120ms ease; }
        .database-checklist .editor-filter-search:focus { border-color: var(--gateway-red-500, #e8193f) !important; background: #fff; outline: 0; box-shadow: 0 0 0 2px rgba(232, 25, 63, .12); }
        .database-checklist .editor-checker-pills { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
        .database-checklist .editor-checker-pill { border: 1.5px solid #cbd5e1; background: #ffffff; color: #475569; font-size: 11px; font-weight: 800; padding: 5px 12px; border-radius: 6px; cursor: pointer; transition: all 140ms ease; display: inline-flex; align-items: center; gap: 6px; box-shadow: 0 1px 2px rgba(0,0,0,.03); }
        .database-checklist .editor-checker-pill:hover { background: #f8fafc; border-color: #94a3b8; color: #0f172a; }
        .database-checklist .editor-checker-pill.is-active { background: var(--gateway-red-500, #e8193f); border-color: var(--gateway-red-500, #e8193f); color: #ffffff; box-shadow: 0 2px 6px rgba(185, 28, 28, .22); }
        .database-checklist .editor-filter-summary { display: flex; align-items: center; justify-content: space-between; gap: 10px; margin-top: 9px; padding-top: 8px; border-top: 1px dashed #e2e8f0; font-size: 11px; font-weight: 700; color: #64748b; }
        .database-checklist .editor-filter-reset-btn { background: none; border: none; color: var(--gateway-red-500, #e8193f); font-size: 11px; font-weight: 750; cursor: pointer; padding: 2px 6px; border-radius: 4px; }
        .database-checklist .editor-filter-reset-btn:hover { background: #fee2e2; }
        .database-checklist .editor-item-user-badge { display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px; border-radius: 999px; font-size: 10.5px; font-weight: 800; letter-spacing: .02em; background: #f1f5f9; color: #334155; border: 1px solid #cbd5e1; margin-left: 6px; }
        .database-checklist .editor-item-user-badge.is-ce { background: #eff6ff; color: #1d4ed8; border-color: #bfdbfe; }
        .database-checklist .editor-item-user-badge.is-ws { background: #f0fdf4; color: #15803d; border-color: #bbf7d0; }
        .database-checklist .editor-item-user-badge.is-asm { background: #fef3c7; color: #b45309; border-color: #fde68a; }
        .database-checklist .editor-item-user-badge.is-parts { background: #f3e8ff; color: #7e22ce; border-color: #e9d5ff; }
        .database-checklist .editor-item-user-badge.is-jc { background: #fce7f3; color: #be185d; border-color: #fbcfe8; }
        .database-checklist .editor-item-user-badge.is-gm { background: #fee2e2; color: #b91c1c; border-color: #fecaca; }
    </style>
    <link rel="stylesheet" href="{{ asset('css/checklist-template-editor.css') }}">
    <link rel="stylesheet" href="{{ asset('css/checklist-editor-sort.css') }}">
    <link rel="stylesheet" href="{{ asset('css/checklist-view-mode.css') }}">
</head>
<body class="gateway-dashboard database-checklist {{ $bodyClass }}" data-checklist-variant="{{ $variant }}">
    @include('layouts.navigation')

    <div class="main-shell">
        @include('partials.app-topbar', [
            'topbarTitle' => $canManageTemplate ? 'Checklist Editor' : $pageTitle,
            'topbarSubtitle' => $pageSubtitle,
            'notificationId' => 'notificationsBtn',
            'notificationBadge' => (string) ($notificationBadgeCount ?? 0),
            'notificationBadgeId' => 'notificationsBadge',
        ])

        <main class="content">
            @if (! $canManageTemplate && $workspaceData !== [])
                <div class="checklist-workspace-header">
                    <nav class="checklist-workspace-switcher" aria-label="Select checklist" role="tablist">
                        @foreach ($workspaceData as $option)
                            <a href="{{ $option['url'] }}"
                               class="checklist-workspace-option{{ $option['selected'] ? ' is-active' : '' }}"
                               role="tab"
                               aria-selected="{{ $option['selected'] ? 'true' : 'false' }}"
                               @if ($option['selected']) aria-current="page" @endif>
                                <i class="fas {{ $option['icon'] }}" aria-hidden="true"></i>
                                <span>{{ $option['label'] }}</span>
                            </a>
                        @endforeach
                    </nav>
                </div>
            @endif

            <section class="page-heading checklist-page-heading">
                <div>
                    <span class="eyebrow"><span class="eyebrow-dot"></span>{{ $pageEyebrow }}</span>
                    <h2 id="pageChecklistName">{{ $templateName }}</h2>
                    <p id="pageChecklistDescription" @if ($templateDescription === '') hidden @endif>{{ $templateDescription }}</p>
                </div>
                <div class="header-actions checklist-editor-actions">
                    @if (!empty($subformDocData['has_submissions']))
                        <button class="button soft btn-subform-doc-header" id="checklistOpenSubformDocModalBtn" type="button" onclick="openSubformDocModal()" title="View existing Subform and Documentation submissions">
                            <i class="fas fa-file-circle-check" style="color: #10b981;"></i>
                            <span>{{ $subformDocData['button_label'] }}</span>
                        </button>
                    @endif
                    <button class="button soft" id="printButton" type="button">
                        <i class="fas fa-print" aria-hidden="true"></i> Print
                    </button>
                    @if ($canManageTemplate)
                        <button class="button soft" id="createTemplateButton" type="button">
                            <i class="fas fa-plus" aria-hidden="true"></i> Create New Checklist
                        </button>
                        <button class="button primary" id="editTemplateButton" type="button">
                            <i class="fas fa-pen-to-square" aria-hidden="true"></i> Edit Master Checklist
                        </button>
                        <button class="button soft" id="archiveTemplateButton" type="button">
                            <i class="fas fa-trash-can" aria-hidden="true"></i> Delete Audit Form
                        </button>
                    @endif
                </div>
            </section>


            <section class="page-heading checklist-page-heading checklist-summary-banner" id="checklistSummaryBanner" aria-label="Checklist summary and scope">
                <div class="summary-banner-top">
                    <div class="summary-main">
                        <span class="summary-eyebrow">
                            <span class="summary-eyebrow-dot"></span>
                            Checklist Specification · {{ $checklistSummary['frequency'] ?? 'Active Checklist' }}
                        </span>
                        <h3 class="summary-heading">{{ $checklistSummary['title'] ?? $templateName }} Summary</h3>
                        <p class="summary-guide" id="checklistSummaryGuide">{{ $checklistSummary['guide'] ?? '' }}</p>
                    </div>

                    <div class="summary-metrics">
                        <div class="summary-chip is-items" title="Total checklist items in this active checklist">
                            <i class="fas fa-list-check"></i>
                            <span>{{ $checklistSummary['items_count'] }} Checklist Items</span>
                        </div>
                        <div class="summary-chip" title="Total sections in this active checklist">
                            <i class="fas fa-folder-tree"></i>
                            <span>{{ $checklistSummary['sections_count'] }} Sections</span>
                        </div>

                        @if (! empty($checklistSummary['has_subform']))
                            <div class="summary-chip is-subform" title="Operational subforms: {{ implode(', ', array_map(fn ($s) => $s['name'].' ('.$s['count'].')', $checklistSummary['subform_breakdown'] ?? [])) }}">
                                <i class="fas fa-layer-group"></i>
                                <span>{{ count($checklistSummary['subform_breakdown'] ?? []) ?: 5 }} Subforms ({{ $checklistSummary['subform_count'] }} Qs)</span>
                            </div>
                        @else
                            <div class="summary-chip is-no-subform" title="No subform audit required for this checklist">
                                <i class="fas fa-minus-circle"></i>
                                <span>No Subforms</span>
                            </div>
                        @endif

                        @if (! empty($checklistSummary['has_documentation']))
                            <div class="summary-chip is-doc" title="Documentation standards: Rationalized Checksheet (11), Repair Order (3), Service Invoice (3)">
                                <i class="fas fa-file-invoice"></i>
                                <span>{{ $checklistSummary['doc_count'] }} Documentation Qs</span>
                            </div>
                        @endif

                        @if (! empty($checklistSummary['total_audit_count']) && $checklistSummary['total_audit_count'] > $checklistSummary['items_count'])
                            <div class="summary-chip is-total" title="Comprehensive audit scope: {{ $checklistSummary['items_count'] }} Core + {{ $checklistSummary['subform_count'] }} Subform + {{ $checklistSummary['doc_count'] }} Documentation">
                                <i class="fas fa-shield-halved"></i>
                                <span>{{ $checklistSummary['total_audit_count'] }} Total Audit Scope</span>
                            </div>
                        @endif

                        @if (! empty($checklistSummary['assigned_pic']) && empty($checklistSummary['roles']))
                            <div class="summary-chip" title="Responsible PIC role">
                                <i class="fas fa-user-check"></i>
                                <span>{{ $checklistSummary['assigned_pic'] }}</span>
                            </div>
                        @endif
                    </div>
                </div>

                @if (! empty($checklistSummary['roles']))
                    <div class="checker-filter-bar">
                        <span class="checker-filter-label"><i class="fas fa-filter"></i> Checkers:</span>
                        <div class="checker-filter-pills">
                            <button type="button" class="checker-pill-btn is-active" data-checker-filter="all">
                                All ({{ $checklistSummary['items_count'] }})
                            </button>
                            @foreach ($checklistSummary['roles'] as $role)
                                @php
                                    $subformText = $role['subform'] > 0 ? '+ '.$role['subform'].' Subform' : '';
                                    $docText = $role['doc'] > 0 ? '+ '.$role['doc'].' Doc' : '';
                                    $subShort = $role['subform'] > 0 ? '+'.$role['subform'].' sub' : '';
                                @endphp
                                <button type="button" class="checker-pill-btn" data-checker-filter="{{ $role['code'] }}" title="{{ $role['label'] }}: {{ $role['core'] }} Core {{ $subformText }} {{ $docText }}">
                                    {{ $role['code'] }} ({{ $role['core'] }}{{ $subShort }})
                                </button>
                            @endforeach
                        </div>
                    </div>
                @endif

                <div hidden aria-hidden="true" style="display:none !important;">
                    <span id="scoreValue"></span><span id="scoreBar"></span><span id="scoreMeta"></span>
                    <span id="completionValue"></span><span id="completionBar"></span><span id="answeredCount"></span>
                    <span id="findingsValue"></span><span id="findingsBar"></span><span id="findingsMeta"></span>
                    <span id="itemCountValue"></span><span id="sectionCountValue"></span>
                </div>
            </section>

            <section class="panel filters" aria-label="Checklist details">
                <div class="field">
                    <label for="branchSelect">Branch</label>
                    <select id="branchSelect" autocomplete="organization">
                        @forelse ($branchData as $branch)
                            @php
                                $branchValue = is_scalar($branch)
                                    ? (string) $branch
                                    : (string) data_get($branch, 'name', data_get($branch, 'branch', data_get($branch, 'label', '')));
                            @endphp
                            @if ($branchValue !== '')
                                <option value="{{ $branchValue }}" @selected($branchValue === $initialBranch)>{{ $branchValue }}</option>
                            @endif
                        @empty
                            @if ($initialBranch !== '')
                                <option value="{{ $initialBranch }}">{{ $initialBranch }}</option>
                            @else
                                <option value="">No branch assigned</option>
                            @endif
                        @endforelse
                    </select>
                </div>
                <div class="field">
                    <label for="auditDate">Checklist Date</label>
                    <input id="auditDate" type="date" value="{{ $initialDate }}">
                </div>
                <div class="field">
                    <label>Checklist Template</label>
                    <div class="template-chip" id="templateChip">{{ $templateName }}</div>
                </div>
                <div class="database-status" id="recordStatus" role="status">Loading database record…</div>
            </section>

            <section class="notice" id="checklistInstructionsNotice" aria-label="Checklist instructions" @if ($templateInstructions === '') hidden @endif>
                <div class="notice-icon"><i class="fas fa-info" aria-hidden="true"></i></div>
                <div>
                    <strong>Checklist instructions</strong>
                    <p id="checklistInstructions">{{ $templateInstructions }}</p>
                </div>
            </section>

            <section class="panel {{ $variant === 'dos' ? 'audit-panel' : 'checklist-panel' }}" aria-labelledby="checklistHeading">
                <div class="{{ $variant === 'dos' ? 'audit-toolbar' : 'checklist-toolbar' }}">
                    <div class="{{ $variant === 'dos' ? 'audit-title' : 'checklist-title' }}">
                        <h3 id="checklistHeading">{{ $templateName }} <span class="mode-badge" id="modeBadge">Database form</span></h3>
                        <p>Checklist sections and items are loaded from the GAC database.</p>
                    </div>
                    <div class="toolbar-actions">
                        <button class="button soft" id="resetResponsesButton" type="button">Reset</button>
                        <button class="button" id="saveDraftButton" type="button">Save Draft</button>
                        <button class="button primary" id="submitButton" type="button">Submit</button>
                    </div>
                </div>

                <div class="audit-filters" id="auditFilters" @if ($variant === 'restroom') hidden @endif>
                    <input class="filter-control" id="searchInput" type="search" placeholder="Search checklist items…">
                    <select class="filter-control" id="sectionFilter"><option value="all">All sections</option></select>
                    <select class="filter-control" id="levelFilter"><option value="all">All levels</option></select>
                    <div class="showing-count" id="showingCount">Loading items…</div>
                </div>

                <div class="column-headings" aria-hidden="true" @if ($variant === 'restroom') hidden @endif>
                    <div>No.</div>
                    <div>Checklist Item</div>
                    <div>Response</div>
                    <div>Remarks / Corrective Action</div>
                    <div></div>
                </div>

                <div id="checklistContainer"><div class="loading-mask">Loading checklist…</div></div>

                <div class="{{ $variant === 'dos' ? 'audit-footer' : 'checklist-footer' }}">
                    <div class="footer-summary" id="footerSummary">Select a branch and date to load a database record.</div>
                    <div class="footer-actions">
                        <button class="button soft" id="scrollTopButton" type="button">Back to Top</button>
                        <button class="button primary" id="footerSubmitButton" type="button">Submit</button>
                    </div>
                </div>
            </section>
        </main>
    </div>

        <dialog class="how-to-check-dialog" id="howToCheckDialog" aria-labelledby="howToCheckTitle" aria-describedby="howToCheckGuidance">
            <div class="how-to-check-shell">
                <div class="how-to-check-header">
                    <h3 id="howToCheckTitle">How to Check</h3>
                    <button class="button soft" id="closeHowToCheck" type="button" aria-label="Close How to Check dialog">
                        <i class="fas fa-xmark" aria-hidden="true"></i>
                    </button>
                </div>
                <div class="how-to-check-body">
                    <p class="how-to-check-item" id="howToCheckItem"></p>
                    <p class="how-to-check-guidance" id="howToCheckGuidance"></p>
                </div>
                <div class="how-to-check-footer">
                    <button class="button primary" id="dismissHowToCheck" type="button">Close</button>
                </div>
            </div>
        </dialog>

    @if ($canManageTemplate)
        <dialog class="template-editor-dialog" id="templateEditor" aria-labelledby="templateEditorTitle">
            <form class="template-editor-shell" id="templateEditorForm" method="dialog">
                <div class="template-editor-header">
                    <div>
                        <h3 id="templateEditorTitle">Edit Master Checklist</h3>
                        <div class="editor-scope-tabs" id="editorScopeTabs" style="display:none;">
                            <button type="button" class="editor-scope-tab is-active" data-editor-scope="main">
                                <i class="fas fa-list-check"></i> Core Standards (<span id="editorCountMain">0</span>)
                            </button>
                            <button type="button" class="editor-scope-tab" data-editor-scope="subform">
                                <i class="fas fa-folder-tree"></i> DOS Subform Standards (<span id="editorCountSubform">0</span>)
                            </button>
                            <button type="button" class="editor-scope-tab" data-editor-scope="documentation">
                                <i class="fas fa-file-circle-check"></i> DOS Documentation Standards (<span id="editorCountDoc">0</span>)
                            </button>
                        </div>
                    </div>
                    <button class="button soft" id="closeTemplateEditor" type="button" aria-label="Close editor"><i class="fas fa-xmark"></i></button>
                </div>
                <div class="template-editor-body">
                    <div class="editor-template-fields">
                        <div class="field"><label for="editorName">Template Name</label><input id="editorName" required></div>
                        <div class="field"><label for="editorShortName">Short Name</label><input id="editorShortName"></div>
                        <div class="field wide"><label for="editorDescription">Description</label><textarea id="editorDescription" rows="2"></textarea></div>
                        <div class="field wide"><label for="editorInstructions">Checklist instructions</label><textarea id="editorInstructions" rows="3" placeholder="Explain how to complete this checklist."></textarea></div>
                    </div>
                    <div class="editor-filter-card" id="editorFilterCard">
                        <div class="editor-filter-header">
                            <div class="editor-filter-title">
                                <i class="fas fa-users-viewfinder"></i>
                                <span>Filter by User / Auditor</span>
                            </div>
                            <div class="editor-filter-search-wrap">
                                <i class="fas fa-search"></i>
                                <input type="search" id="editorItemSearch" class="editor-filter-search" placeholder="Search standard text or #...">
                            </div>
                        </div>
                        <div class="editor-checker-pills" id="editorCheckerPills">
                            <button type="button" class="editor-checker-pill is-active" data-editor-user="all">All</button>
                        </div>
                        <div class="editor-filter-summary" id="editorFilterSummary" style="display:none;">
                            <span id="editorFilterCountText">Showing all questions</span>
                            <button type="button" class="editor-filter-reset-btn" id="editorFilterResetBtn"><i class="fas fa-times"></i> Clear Filter</button>
                        </div>
                    </div>
                    <p class="editor-order-help" id="editorOrderHelp">Drag a section or question using its handle to change the sequence. Question numbers update automatically. You can also focus a handle and use the Up and Down arrow keys.</p>
                    <p class="editor-order-status" id="editorOrderStatus" role="status" aria-live="polite"></p>
                    <div id="editorSections"></div>
                    <button class="button" id="addEditorSection" type="button"><i class="fas fa-plus"></i> Add Section</button>
                </div>
                <div class="template-editor-footer">
                    <button class="button soft" id="cancelTemplateEditor" type="button">Cancel</button>
                    <button class="button primary" id="saveTemplateButton" type="button">Save Master Checklist</button>
                </div>
            </form>
        </dialog>

        <dialog class="template-editor-dialog create-template-dialog" id="createTemplateDialog" aria-labelledby="createTemplateTitle">
            <form class="template-editor-shell" id="createTemplateForm" method="dialog">
                <div class="template-editor-header">
                    <h3 id="createTemplateTitle"><i class="fas fa-plus-circle" style="color: var(--gateway-red-500); margin-right: 6px;"></i> Create New Master Checklist</h3>
                    <button class="button soft" id="closeCreateTemplate" type="button" aria-label="Close dialog"><i class="fas fa-xmark"></i></button>
                </div>
                <div class="template-editor-body">
                    <div class="editor-template-fields">
                        <div class="field"><label for="newTemplateName">Checklist Name *</label><input id="newTemplateName" required placeholder="e.g. FY26 Aftersales Standards Audit"></div>
                        <div class="field"><label for="newTemplateSlug">Identifier (Slug) *</label><input id="newTemplateSlug" required placeholder="e.g. fy26-aftersales-audit"></div>
                        <div class="field wide"><label for="newTemplateDescription">Description</label><textarea id="newTemplateDescription" rows="2" placeholder="Brief purpose or scope of this checklist..."></textarea></div>
                        <div class="field">
                            <label for="newTemplateVariant">Checklist Standard Type</label>
                            <select id="newTemplateVariant">
                                <option value="dos">Dealer Operations Standards (DOS - Escalation, Levels, Subforms)</option>
                                <option value="standard">5S Standards (Showroom, Service readiness)</option>
                                <option value="restroom">Restroom Monitoring (Scheduled time slots)</option>
                            </select>
                        </div>
                        <div class="field">
                            <label for="newTemplateClone">Base Template / Clone From</label>
                            <select id="newTemplateClone">
                                <option value="">-- Start Blank (Default Section) --</option>
                                @foreach ($availableBaseTemplates ?? [] as $baseTpl)
                                    <option value="{{ $baseTpl['slug'] }}">Clone {{ $baseTpl['name'] }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="field wide"><label for="newTemplateInstructions">Checklist instructions</label><textarea id="newTemplateInstructions" rows="2" placeholder="Explain how auditors or users should complete this checklist..."></textarea></div>
                    </div>
                </div>
                <div class="template-editor-footer">
                    <button class="button soft" id="cancelCreateTemplate" type="button">Cancel</button>
                    <button class="button primary" id="saveNewTemplateButton" type="button">Create Checklist Template</button>
                </div>
            </form>
        </dialog>
    @endif

    <div class="toast-region" id="toastRegion" aria-live="polite" aria-atomic="true"></div>

    <script src="{{ asset('js/checklist-editor-sort.js') }}"></script>
    <script src="{{ asset('js/checklist-view-mode.js') }}"></script>
    <script>
        (() => {
            'use strict';

            const endpoints = Object.freeze({
                load: @json($loadUrl),
                draft: @json($draftUrl),
                submit: @json($submitUrl),
                reset: @json($resetUrl),
                template: @json($templateUrl),
                subformTemplate: @json($subformTemplateUrl),
                documentationTemplate: @json($documentationTemplateUrl),
                toggleItem: @json($toggleItemUrl),
                createTemplate: @json($createTemplateUrl),
                deleteTemplate: @json($deleteTemplateUrl),
            });
            const canManageTemplate = {{ \Illuminate\Support\Js::from($canManageTemplate) }};
            const variant = @json($variant);
            const initialTemplate = {{ \Illuminate\Support\Js::from($templateData) }};
            const initialSubmission = {{ \Illuminate\Support\Js::from($submissionData) }};
            let subformTemplate = {{ \Illuminate\Support\Js::from($subformTemplateData ?? $subformTemplate ?? null) }};
            let documentationTemplate = {{ \Illuminate\Support\Js::from($documentationTemplateData ?? null) }};
            let userChecklistOverview = {{ \Illuminate\Support\Js::from($userChecklistOverview ?? null) }};
            const checklistSummary = {{ \Illuminate\Support\Js::from($checklistSummary ?? null) }};
            userChecklistOverview = checklistSummary;
            const availableBaseTemplates = {{ \Illuminate\Support\Js::from($availableBaseTemplates ?? []) }};
            const subformState = {};
            const documentationState = {};
            let activeEditorScope = 'main';
            let activeEditorUserFilter = 'all';
            let currentOverviewTab = variant === 'dos' ? 'dos' : 'all';
            let activeUserFilter = null;
            const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
            const container = document.getElementById('checklistContainer');
            const branchSelect = document.getElementById('branchSelect');
            const auditDate = document.getElementById('auditDate');
            const statusElement = document.getElementById('recordStatus');
            const toastRegion = document.getElementById('toastRegion');
            let template = normalizeTemplate(initialTemplate);
            let currentSubmission = initialSubmission;
            let loadController = null;
            let howToCheckReturnFocus = null;
            let editorSorter = null;
            const checklistView = window.ChecklistViewMode?.create
                ? window.ChecklistViewMode.create({ container, slug: template.slug })
                : { refresh: () => {}, reveal: () => {} };

            function asObject(value) {
                if (!value || typeof value !== 'object') return {};
                return value;
            }

            function parseObject(value) {
                if (value && typeof value === 'object') return value;
                if (typeof value !== 'string' || value.trim() === '') return {};
                try { return JSON.parse(value); } catch (_) { return {}; }
            }

            function escapeHTML(value) {
                return String(value ?? '')
                    .replaceAll('&', '&amp;')
                    .replaceAll('<', '&lt;')
                    .replaceAll('>', '&gt;')
                    .replaceAll('"', '&quot;')
                    .replaceAll("'", '&#039;');
            }

            function slug(value, fallback) {
                const normalized = String(value ?? '')
                    .toLowerCase()
                    .trim()
                    .replace(/[^a-z0-9]+/g, '-')
                    .replace(/^-|-$/g, '');
                return normalized || fallback;
            }

            function normalizeStatus(value) {
                const status = String(value ?? '').toLowerCase().replaceAll('/', '').replaceAll('_', '');
                if (['yes', 'good', 'pass', 'compliant'].includes(status)) return 'yes';
                if (['no', 'notgood', 'fail', 'noncompliant'].includes(status)) return 'no';
                if (['na', 'notapplicable'].includes(status)) return 'na';
                return '';
            }

            function normalizeEscalation(value) {
                const compact = String(value ?? '').trim().toLowerCase().replace(/[^a-z0-9]+/g, '');
                if (!compact) return '';
                if (compact === 'pm' || compact.includes('propertymanagement') || compact.includes('purchasingmanager')) return 'property_management';
                if (compact === 'gm' || compact.includes('generalmanager')) return 'general_manager';
                if (compact.includes('inventory')) return 'inventory';
                if (compact.includes('purchasing')) return 'purchasing';
                return '';
            }

            function normalizeDateTimeLocal(value) {
                const match = String(value ?? '').trim().match(/^(\d{4}-\d{2}-\d{2})(?:[T\s](\d{2}:\d{2}))?/);
                if (!match) return '';
                return `${match[1]}T${match[2] || '00:00'}`;
            }

            function normalizeTemplate(rawTemplate) {
                const raw = asObject(rawTemplate);
                const settings = asObject(raw.settings);
                const metadata = asObject(raw.metadata);
                const rawSlots = raw.time_slots ?? settings.time_slots ?? metadata.time_slots ?? [];
                const timeSlots = Array.isArray(rawSlots) ? rawSlots.map((slotValue, index) => {
                    const slotObject = asObject(slotValue);
                    const key = typeof slotValue === 'string'
                        ? slotValue
                        : String(slotObject.key ?? slotObject.value ?? slotObject.time ?? slotObject.label ?? index);
                    const label = typeof slotValue === 'string'
                        ? slotValue
                        : String(slotObject.label ?? slotObject.time ?? slotObject.value ?? key);
                    return { key, label };
                }).filter((slotValue) => slotValue.key !== '') : [];

                const sections = Array.isArray(raw.sections) ? raw.sections.map((sectionValue, sectionIndex) => {
                    const section = asObject(sectionValue);
                    const sectionMetadata = asObject(section.metadata);
                    const sectionKey = String(section.key ?? section.slug ?? section.id ?? `section-${sectionIndex + 1}`);
                    const items = Array.isArray(section.items) ? section.items.map((itemValue, itemIndex) => {
                        const item = asObject(itemValue);
                        const itemMetadata = asObject(item.metadata);
                        const itemKey = String(item.key ?? item.code ?? item.id ?? `${sectionKey}-item-${itemIndex + 1}`);
                        const prompt = String(item.prompt ?? item.label ?? item.description ?? '');
                        const label = String(item.label ?? itemMetadata.label ?? itemMetadata.subject ?? item.code ?? prompt);
                        const description = String(item.description ?? itemMetadata.description ?? (prompt !== label ? prompt : ''));
                        const itemChecker = String(item.checker || itemMetadata.checker || '').trim();
                        return {
                            id: item.id ?? null,
                            key: itemKey,
                            code: String(item.code ?? itemMetadata.code ?? itemMetadata.number ?? ''),
                            label,
                            description,
                            level: String(item.level ?? itemMetadata.level ?? ''),
                            responsible_role: String(item.responsible_role || itemMetadata.responsible_role || itemMetadata.responsible || itemMetadata.pic || raw.editor_options?.default_responsible_role || ''),
                            checker: itemChecker,
                            escalation_to: String(item.escalation_to ?? itemMetadata.escalation_to ?? itemMetadata.escalation ?? ''),
                            how_to_check: String(item.how_to_check ?? item.howToCheck ?? itemMetadata.how_to_check ?? itemMetadata.howToCheck ?? ''),
                            is_active: item.is_active !== undefined
                                ? Boolean(item.is_active)
                                : (itemMetadata.is_active !== undefined ? Boolean(itemMetadata.is_active) : true),
                            active_slots: item.active_slots ?? itemMetadata.active_slots ?? null,
                            metadata: itemMetadata,
                        };
                    }) : [];
                    return {
                        id: section.id ?? null,
                        key: sectionKey,
                        title: String(section.title ?? section.name ?? sectionMetadata.title ?? ''),
                        metadata: sectionMetadata,
                        items,
                    };
                }) : [];

                return {
                    id: raw.id ?? null,
                    slug: String(raw.slug ?? ''),
                    name: String(raw.name ?? ''),
                    short_name: String(raw.short_name ?? settings.short_name ?? ''),
                    description: String(raw.description ?? ''),
                    instructions: String(raw.instructions ?? settings.instructions ?? ''),
                    settings,
                    editor_options: asObject(raw.editor_options),
                    metadata,
                    time_slots: timeSlots,
                    sections,
                };
            }

            // Restroom templates can be either the legacy hourly time-slot
            // form or the newer once-per-audit yes/no form. The template
            // setting is the source of truth so an edited template keeps the
            // same response shape everywhere in the workspace.
            function usesRestroomTimeSlots() {
                return variant === 'restroom'
                    && template.settings?.validation_mode === 'time_slots'
                    && template.time_slots.length > 0;
            }

            function syncChecklistModeUI() {
                const hourly = usesRestroomTimeSlots();
                const filters = document.getElementById('auditFilters');
                const headings = document.querySelector('.column-headings');
                if (filters) filters.hidden = hourly;
                if (headings) headings.hidden = hourly;
                if (hourly && canManageTemplate) {
                    const saveBtn = document.getElementById('saveDraftButton');
                    const submitBtn = document.getElementById('submitButton');
                    const resetBtn = document.getElementById('resetResponsesButton');
                    const footerSubmit = document.getElementById('footerSubmitButton');
                    if (saveBtn) saveBtn.hidden = true;
                    if (submitBtn) submitBtn.hidden = true;
                    if (resetBtn) resetBtn.hidden = true;
                    if (footerSubmit) footerSubmit.hidden = true;
                }
            }

            function responseMap(submissionValue) {
                const source = asObject(submissionValue).responses ?? submissionValue ?? {};
                if (Array.isArray(source)) {
                    return source.reduce((map, response, index) => {
                        const entry = asObject(response);
                        const key = String(entry.item_key ?? entry.key ?? entry.item_id ?? entry.checklist_item_id ?? index);
                        map[key] = entry;
                        return map;
                    }, {});
                }
                return asObject(source);
            }

            function responseFor(item, responses) {
                const candidates = [item.key, item.id, item.code].filter((value) => value !== null && value !== undefined && value !== '');
                for (const candidate of candidates) {
                    if (Object.prototype.hasOwnProperty.call(responses, String(candidate))) return asObject(responses[String(candidate)]);
                }
                return {};
            }

            function resolveItemChecker(item) {
                if (!item) return '';
                const meta = asObject(item.metadata);
                return String(item.checker || meta.checker || item.responsible_role || meta.responsible_role || meta.responsible || meta.pic || '').trim();
            }

            function itemMeta(item) {
                const badges = [];
                if (item.level) badges.push(`<span class="level-badge ${escapeHTML(item.level.toLowerCase())}">${escapeHTML(item.level)}</span>`);
                const checker = resolveItemChecker(item);
                if (checker) {
                    const cUpper = checker.toUpperCase();
                    let colorClass = '';
                    if (cUpper.includes('CE')) colorClass = 'is-ce';
                    else if (cUpper.includes('WORKSHOP') || cUpper.includes('WS')) colorClass = 'is-ws';
                    else if (cUpper.includes('ASM') || cUpper.includes('AFTERSALES')) colorClass = 'is-asm';
                    else if (cUpper.includes('PARTS')) colorClass = 'is-parts';
                    else if (cUpper.includes('JC')) colorClass = 'is-jc';
                    badges.push(`<span class="checker-badge ${colorClass}" title="Auditor: ${escapeHTML(checker)}"><i class="fas fa-user-check" aria-hidden="true"></i> ${escapeHTML(checker)}</span>`);
                }
                return badges.length ? `<div class="item-meta">${badges.join('')}</div>` : '';
            }

            function responsibilities(item) {
                const entries = [];
                const roleLabel = template.editor_options.responsible_roles?.find((role) => role.value === item.responsible_role)?.label || item.responsible_role;
                const checker = resolveItemChecker(item);
                if (roleLabel && roleLabel.toUpperCase() !== checker.toUpperCase()) {
                    entries.push(`<div class="responsibility"><span>Accountable</span><strong>${escapeHTML(roleLabel)}</strong></div>`);
                }
                return entries.length ? `<div class="responsibility-grid">${entries.join('')}</div>` : '';
            }

            function howToCheckButton(item) {
                if (variant !== 'dos' && !item.how_to_check.trim()) return '';
                return `<button type="button" class="how-to-check-button" data-action="show-how-to-check" data-item-key="${escapeHTML(item.key)}" aria-label="How to check ${escapeHTML(item.label)}" aria-haspopup="dialog" aria-controls="howToCheckDialog" title="How to Check"><span aria-hidden="true">i</span></button>`;
            }

            function openHowToCheck(trigger) {
                const dialog = document.getElementById('howToCheckDialog');
                if (!dialog) return;
                const itemKey = trigger.dataset.itemKey || trigger.closest('[data-item-key]')?.dataset.itemKey;
                const item = template.sections.flatMap((section) => section.items).find((entry) => entry.key === itemKey);
                if (!item) return;

                const itemHeading = [item.code ? `Item ${item.code}` : '', item.label].filter(Boolean).join(' — ');
                document.getElementById('howToCheckItem').textContent = itemHeading || 'Checklist item';
                document.getElementById('howToCheckGuidance').textContent = item.how_to_check.trim()
                    || 'No How to Check guidance is available for this checklist item.';
                howToCheckReturnFocus = trigger;
                typeof dialog.showModal === 'function' ? dialog.showModal() : dialog.setAttribute('open', '');
                document.getElementById('closeHowToCheck')?.focus();
            }

            function closeHowToCheck() {
                const dialog = document.getElementById('howToCheckDialog');
                if (!dialog) return;
                if (typeof dialog.close === 'function' && dialog.open) {
                    dialog.close();
                    return;
                }
                dialog.removeAttribute('open');
                howToCheckReturnFocus?.focus();
                howToCheckReturnFocus = null;
            }

            function isSubformReferenceItem(item) {
                if (!item) return false;
                if (variant !== 'dos') return false;
                if (template.slug !== 'dealer-operations-standards') return false;
                const num = String(item.code || item.metadata?.number || '');
                const desc = String(item.description || item.label || '').toLowerCase();
                const htc = String(item.how_to_check || '').toLowerCase();
                if (['23', '27', '53', '54', '55'].includes(num)) return true;
                if (desc.includes('subform') || htc.includes('subform')) return true;
                if (desc.includes('service reception area') || desc.includes('customers\' lounge') || desc.includes('customers lounge') || desc.includes('employee facilities') || desc.includes('meeting room') || desc.includes('mitsubishi quick service')) return true;
                return false;
            }

            function getSubformSection(item) {
                if (!subformTemplate || !Array.isArray(subformTemplate.sections)) return null;
                const num = String(item.code || item.metadata?.number || '');
                const desc = String(item.description || item.label || '').toLowerCase();
                if (num === '23' || desc.includes('service reception') || desc.includes('reception')) {
                    return subformTemplate.sections.find((s) => s.key === 'subform-service-reception') || subformTemplate.sections[0] || null;
                }
                if (num === '27' || desc.includes('lounge')) {
                    return subformTemplate.sections.find((s) => s.key === 'subform-customers-lounge') || subformTemplate.sections[4] || null;
                }
                if (num === '53' || desc.includes('quick service') || desc.includes('mqs')) {
                    return subformTemplate.sections.find((s) => s.key === 'subform-mitsubishi-quick-service') || subformTemplate.sections[3] || null;
                }
                if (num === '54' || desc.includes('employee facilities') || desc.includes('facilities')) {
                    return subformTemplate.sections.find((s) => s.key === 'subform-employee-facilities') || subformTemplate.sections[1] || null;
                }
                if (num === '55' || desc.includes('meeting room')) {
                    return subformTemplate.sections.find((s) => s.key === 'subform-meeting-room') || subformTemplate.sections[2] || null;
                }
                return null;
            }

            function deriveSubformOverallStatus(subformSection, subformAnswers) {
                if (!subformSection || !Array.isArray(subformSection.items) || subformSection.items.length === 0) return null;
                const answers = asObject(subformAnswers);
                const hasAnyNo = subformSection.items.some((sub) => {
                    const val = answers[String(sub.id)] ?? answers[sub.key];
                    return val === 'no';
                });
                if (hasAnyNo) return 'no';

                const allAnswered = subformSection.items.every((sub) => {
                    const val = answers[String(sub.id)] ?? answers[sub.key];
                    return val === 'yes' || val === 'no' || val === 'na';
                });
                if (!allAnswered) return null;

                const allNa = subformSection.items.every((sub) => {
                    const val = answers[String(sub.id)] ?? answers[sub.key];
                    return val === 'na';
                });
                if (allNa) return 'na';

                return 'yes';
            }

            function renderSubformBox(row, item, subformSection) {
                if (!subformSection) return;
                const wrapper = row.querySelector('.subform-inline-wrapper');
                if (!wrapper) return;

                if (!subformState[item.key]) {
                    subformState[item.key] = {
                        eligibility: null,
                        answers: {},
                        activeIndex: 0,
                        viewMode: 'dropdown',
                    };
                }
                const state = subformState[item.key];
                const items = subformSection.items || [];
                const answeredCount = items.filter((i) => {
                    const val = state.answers[String(i.id)] ?? state.answers[i.key];
                    return val === 'yes' || val === 'no' || val === 'na';
                }).length;
                const noCount = items.filter((i) => {
                    const val = state.answers[String(i.id)] ?? state.answers[i.key];
                    return val === 'no';
                }).length;
                const derivedStatus = state.eligibility === 'na' ? 'na' : (state.eligibility === 'show_subform' ? deriveSubformOverallStatus(subformSection, state.answers) : null);

                if (derivedStatus) {
                    const radio = row.querySelector(`input[type="radio"][value="${derivedStatus}"]`);
                    if (radio) radio.checked = true;
                } else {
                    row.querySelectorAll('input[type="radio"]').forEach((r) => { r.checked = false; });
                }

                let badgeClass = 'is-pending';
                let badgeText = 'Select eligibility';
                if (state.eligibility === 'show_subform') {
                    badgeClass = 'is-subform';
                    badgeText = 'Eligible (Subform Active)';
                } else if (state.eligibility === 'na') {
                    badgeClass = 'is-na';
                    badgeText = 'Not Applicable (N/A)';
                }

                let subformContent = '';
                if (state.eligibility === 'show_subform') {
                    const activeIdx = Math.max(0, Math.min(state.activeIndex, items.length - 1));
                    const activeItem = items[activeIdx] || {};
                    const activeVal = state.answers[String(activeItem.id)] ?? state.answers[activeItem.key] ?? '';
                    const activeChecker = activeItem.metadata?.checker || activeItem.responsible_role || 'AUDITOR';

                    let bodyHtml = '';
                    if (state.viewMode === 'all') {
                        bodyHtml = `<div class="subform-all-view-mode">
                            ${items.map((sub, i) => {
                                const sVal = state.answers[String(sub.id)] ?? state.answers[sub.key] ?? '';
                                const checker = sub.metadata?.checker || sub.responsible_role || 'AUDITOR';
                                return `<div class="subform-list-card" data-subitem-id="${escapeHTML(sub.id)}" data-subitem-key="${escapeHTML(sub.key)}">
                                    <div class="subform-list-card-head">
                                        <div>
                                            <strong style="color:var(--gateway-red-500);margin-right:6px;">Q${i + 1}.</strong>
                                            <span>${escapeHTML(sub.prompt || sub.label)}</span>
                                        </div>
                                        <span class="subform-card-badge checker-badge">${escapeHTML(checker)}</span>
                                    </div>
                                    ${sub.how_to_check ? `<div class="subform-htc-box"><i class="fas fa-info-circle"></i> <div><strong>How to check:</strong> ${escapeHTML(sub.how_to_check)}</div></div>` : ''}
                                    <div class="subform-choices-row">
                                        <button type="button" class="subform-choice-btn btn-yes ${sVal === 'yes' ? 'is-active' : ''}" data-action="answer-sub-item" data-item-key="${escapeHTML(item.key)}" data-subitem-id="${escapeHTML(sub.id)}" data-value="yes"><i class="fas fa-check-circle"></i> YES</button>
                                        <button type="button" class="subform-choice-btn btn-no ${sVal === 'no' ? 'is-active' : ''}" data-action="answer-sub-item" data-item-key="${escapeHTML(item.key)}" data-subitem-id="${escapeHTML(sub.id)}" data-value="no"><i class="fas fa-times-circle"></i> NO</button>
                                        <button type="button" class="subform-choice-btn btn-na ${sVal === 'na' ? 'is-active' : ''}" data-action="answer-sub-item" data-item-key="${escapeHTML(item.key)}" data-subitem-id="${escapeHTML(sub.id)}" data-value="na"><i class="fas fa-ban"></i> N/A</button>
                                    </div>
                                </div>`;
                            }).join('')}
                        </div>`;
                    } else {
                        const options = items.map((sub, i) => {
                            const sVal = state.answers[String(sub.id)] ?? state.answers[sub.key] ?? '';
                            const sym = sVal === 'yes' ? '✓' : (sVal === 'no' ? '✕' : (sVal === 'na' ? '⊘' : '○'));
                            return `<option value="${i}" ${i === activeIdx ? 'selected' : ''}>Q${i + 1} (${sym}): ${escapeHTML(sub.prompt || sub.label)}</option>`;
                        }).join('');

                        const pills = items.map((sub, i) => {
                            const sVal = state.answers[String(sub.id)] ?? state.answers[sub.key] ?? '';
                            const sym = sVal === 'yes' ? '✓' : (sVal === 'no' ? '✕' : (sVal === 'na' ? '⊘' : '○'));
                            const isActive = i === activeIdx;
                            const symColor = isActive ? '#ffffff' : (sVal === 'yes' ? '#16a34a' : (sVal === 'no' ? '#dc2626' : (sVal === 'na' ? '#d97706' : '#94a3b8')));
                            return `<button type="button" class="subform-pill-btn" data-action="nav-subform-index" data-item-key="${escapeHTML(item.key)}" data-index="${i}" style="border:1.5px solid ${isActive ? 'var(--gateway-red-500)' : '#cbd5e1'};background:${isActive ? 'var(--gateway-red-500)' : '#ffffff'};color:${isActive ? '#ffffff' : '#1e293b'};border-radius:6px;padding:4px 9px;font-size:11px;font-weight:800;cursor:pointer;display:inline-flex;align-items:center;gap:4px;flex-shrink:0;">
                                <span>Q${i + 1}</span>
                                <span style="color:${symColor};font-weight:900;">${sym}</span>
                            </button>`;
                        }).join('');

                        bodyHtml = `
                            <select class="subform-question-select" data-action="change-subform-select" data-item-key="${escapeHTML(item.key)}" aria-label="Select subform question">
                                ${options}
                            </select>
                            <div class="subform-active-card">
                                <div class="subform-card-pills">
                                    <span class="subform-card-badge question-num">QUESTION ${activeIdx + 1} OF ${items.length}</span>
                                    <span class="subform-card-badge checker-badge"><i class="fas fa-user-check"></i> CHECKER: ${escapeHTML(activeChecker)}</span>
                                </div>
                                <div class="subform-active-prompt">${escapeHTML(activeItem.prompt || activeItem.label)}</div>
                                ${activeItem.how_to_check ? `<div class="subform-htc-box"><i class="fas fa-info-circle"></i> <div><strong>How to check:</strong> ${escapeHTML(activeItem.how_to_check)}</div></div>` : ''}
                                <div class="subform-choices-row">
                                    <button type="button" class="subform-choice-btn btn-yes ${activeVal === 'yes' ? 'is-active' : ''}" data-action="answer-sub-item" data-item-key="${escapeHTML(item.key)}" data-subitem-id="${escapeHTML(activeItem.id)}" data-value="yes"><i class="fas fa-check-circle"></i> YES</button>
                                    <button type="button" class="subform-choice-btn btn-no ${activeVal === 'no' ? 'is-active' : ''}" data-action="answer-sub-item" data-item-key="${escapeHTML(item.key)}" data-subitem-id="${escapeHTML(activeItem.id)}" data-value="no"><i class="fas fa-times-circle"></i> NO</button>
                                    <button type="button" class="subform-choice-btn btn-na ${activeVal === 'na' ? 'is-active' : ''}" data-action="answer-sub-item" data-item-key="${escapeHTML(item.key)}" data-subitem-id="${escapeHTML(activeItem.id)}" data-value="na"><i class="fas fa-ban"></i> N/A</button>
                                </div>
                                <div class="subform-nav-row">
                                    <button type="button" class="button soft" data-action="nav-subform" data-item-key="${escapeHTML(item.key)}" data-dir="prev" ${activeIdx === 0 ? 'disabled' : ''}><i class="fas fa-arrow-left"></i> Previous</button>
                                    <button type="button" class="button soft" data-action="nav-subform" data-item-key="${escapeHTML(item.key)}" data-dir="next" ${activeIdx === items.length - 1 ? 'disabled' : ''}>Next <i class="fas fa-arrow-right"></i></button>
                                </div>
                            </div>
                            <div class="subform-pills-strip" style="display:flex;gap:6px;overflow-x:auto;padding-bottom:4px;margin-top:8px;">
                                ${pills}
                            </div>
                        `;
                    }

                    subformContent = `
                        <div class="subform-dropbox-container">
                            <div class="subform-dropbox-head">
                                <div>
                                    <span class="subform-title"><i class="fas fa-folder-open" style="color:var(--gateway-red-500);margin-right:6px;"></i> SUBFORM: ${escapeHTML(subformSection.title.toUpperCase())}</span>
                                    <div class="subform-counts">
                                        <span>${answeredCount} of ${items.length} answered</span>
                                        ${noCount > 0 ? `<span class="noncompliant-pill">· ${noCount} non-compliant</span>` : ''}
                                    </div>
                                </div>
                                <div style="display:flex;gap:6px;flex-wrap:wrap;">
                                    <button type="button" class="button soft subform-view-toggle" data-action="toggle-subform-view" data-item-key="${escapeHTML(item.key)}">
                                        <i class="fas ${state.viewMode === 'all' ? 'fa-table-cells-large' : 'fa-list'}"></i>
                                        <span>${state.viewMode === 'all' ? 'Dropdown View' : 'View All Questions'}</span>
                                    </button>
                                    ${canManageTemplate ? `
                                        <button type="button" class="button soft subform-edit-toggle" data-action="open-editor-subform" style="padding:4px 9px;font-size:10.5px;">
                                            <i class="fas fa-edit"></i> <span>Edit Subform Standards</span>
                                        </button>
                                    ` : ''}
                                </div>
                            </div>
                            ${bodyHtml}
                            <div class="subform-status-banner ${derivedStatus === 'yes' ? 'is-compliant' : (derivedStatus === 'no' ? 'is-noncompliant' : 'is-inprogress')}">
                                <i class="fas ${derivedStatus === 'yes' ? 'fa-circle-check' : (derivedStatus === 'no' ? 'fa-circle-xmark' : (derivedStatus === 'na' ? 'fa-ban' : 'fa-hourglass-half'))}"></i>
                                <span>
                                    ${derivedStatus === 'yes'
                                        ? 'All subform standards compliant (YES)'
                                        : (derivedStatus === 'no'
                                            ? `Non-compliant items detected (${noCount} NO) — Corrective Action Plan & Finding required on parent standard`
                                            : (derivedStatus === 'na'
                                                ? 'All subform standards are Not Applicable (N/A)'
                                                : `Subform audit in progress (${answeredCount} of ${items.length} answered)`
                                            )
                                        )}
                                </span>
                            </div>
                        </div>
                    `;
                }

                wrapper.innerHTML = `
                    <div class="subform-eligibility-box">
                        <div class="subform-eligibility-header">
                            <div class="subform-eligibility-title">
                                <i class="fas fa-list-check"></i>
                                <span>Subform Eligibility Audit</span>
                            </div>
                            <span class="subform-eligibility-badge ${badgeClass}">${escapeHTML(badgeText)}</span>
                        </div>
                        <p class="subform-eligibility-desc">Does this branch have a distinct operational area for <strong>${escapeHTML(subformSection.title)}</strong>?</p>
                        <div class="subform-eligibility-buttons">
                            <button type="button" class="eligibility-btn btn-subform ${state.eligibility === 'show_subform' ? 'is-active' : ''}" data-action="set-eligibility" data-item-key="${escapeHTML(item.key)}" data-eligibility="show_subform">
                                <i class="fas fa-check-circle"></i> Eligible (Audit Subform)
                            </button>
                            <button type="button" class="eligibility-btn btn-na ${state.eligibility === 'na' ? 'is-active' : ''}" data-action="set-eligibility" data-item-key="${escapeHTML(item.key)}" data-eligibility="na">
                                <i class="fas fa-ban"></i> N/A (Not Applicable)
                            </button>
                        </div>
                    </div>
                    ${subformContent}
                `;
            }

            function isDocumentationReferenceItem(item) {
                if (!item) return false;
                if (variant !== 'dos') return false;
                if (template.slug !== 'dealer-operations-standards') return false;
                const num = String(item.code || item.metadata?.number || '');
                const desc = String(item.description || item.label || '').toLowerCase();
                const htc = String(item.how_to_check || '').toLowerCase();
                if (num === '61') return true;
                if (desc.includes('rationalized checksheet') || desc.includes('proper utilization of all service documents') || desc.includes('service documents')) return true;
                return false;
            }

            function deriveDocumentationOverallStatus(docTemplate, samples) {
                if (!docTemplate || !Array.isArray(docTemplate.sections) || !Array.isArray(samples)) return null;
                const allItems = docTemplate.sections.flatMap((s) => s.items || []);
                if (allItems.length === 0) return null;

                let hasAnyAnswer = false;
                let hasAnyNo = false;

                for (const sample of samples) {
                    const answers = asObject(sample.answers);
                    for (const docItem of allItems) {
                        const val = answers[String(docItem.id)] ?? answers[docItem.key];
                        if (val) hasAnyAnswer = true;
                        if (val === 'no') {
                            hasAnyNo = true;
                            return 'no';
                        }
                    }
                }

                if (!hasAnyAnswer) return null;

                const allCompleted = samples.every((sample) => {
                    const answers = asObject(sample.answers);
                    return allItems.every((docItem) => {
                        const val = answers[String(docItem.id)] ?? answers[docItem.key];
                        return val === 'yes' || val === 'no' || val === 'na';
                    });
                });

                if (allCompleted) {
                    return 'yes';
                }

                return hasAnyNo ? 'no' : null;
            }

            function renderDocumentationBox(row, item) {
                const wrapper = row.querySelector('.documentation-inline-wrapper');
                if (!wrapper) return;
                if (!documentationTemplate || !Array.isArray(documentationTemplate.sections)) {
                    wrapper.innerHTML = `<div style="padding:10px;background:#fef2f2;border:1px solid #fecaca;border-radius:8px;font-size:12px;color:#991b1b;">
                        Documentation checklist template is not loaded.
                    </div>`;
                    return;
                }

                if (!documentationState[item.key]) {
                    documentationState[item.key] = {
                        activeSampleIndex: 0,
                        viewMode: 'tabs',
                        samples: [
                            { ro_number: '', job_type: '', answers: {} },
                            { ro_number: '', job_type: '', answers: {} },
                            { ro_number: '', job_type: '', answers: {} },
                        ],
                    };
                }
                const state = documentationState[item.key];
                if (!Array.isArray(state.samples) || state.samples.length < 3) {
                    state.samples = [
                        state.samples?.[0] || { ro_number: '', job_type: '', answers: {} },
                        state.samples?.[1] || { ro_number: '', job_type: '', answers: {} },
                        state.samples?.[2] || { ro_number: '', job_type: '', answers: {} },
                    ];
                }

                const docSections = documentationTemplate.sections || [];
                const allDocItems = docSections.flatMap((s) => s.items || []);
                const totalDocQuestions = allDocItems.length;

                const sampleStats = state.samples.map((s) => {
                    const ans = asObject(s.answers);
                    const answered = allDocItems.filter((di) => {
                        const val = ans[String(di.id)] ?? ans[di.key];
                        return val === 'yes' || val === 'no' || val === 'na';
                    }).length;
                    const noCount = allDocItems.filter((di) => {
                        const val = ans[String(di.id)] ?? ans[di.key];
                        return val === 'no';
                    }).length;
                    return { answered, noCount };
                });

                const totalNo = sampleStats.reduce((sum, st) => sum + st.noCount, 0);
                const derivedStatus = deriveDocumentationOverallStatus(documentationTemplate, state.samples);

                if (derivedStatus) {
                    const radio = row.querySelector(`input[type="radio"][value="${derivedStatus}"]`);
                    if (radio) radio.checked = true;
                } else {
                    row.querySelectorAll('input[type="radio"]').forEach((r) => { r.checked = false; });
                }

                const activeIdx = Math.max(0, Math.min(state.activeSampleIndex || 0, 2));
                const activeSample = state.samples[activeIdx];
                const activeAnswers = asObject(activeSample.answers);

                let bodyHtml = '';

                if (state.viewMode === 'all') {
                    bodyHtml = `
                        <div style="overflow-x:auto;margin-bottom:12px;">
                            <table style="width:100%;border-collapse:collapse;font-size:11.5px;background:#ffffff;border-radius:8px;overflow:hidden;border:1px solid #e2e8f0;">
                                <thead>
                                    <tr style="background:#f1f5f9;border-bottom:1.5px solid #cbd5e1;text-align:left;">
                                        <th style="padding:8px 10px;font-weight:800;color:#334155;width:40%;">Standard</th>
                                        ${[0, 1, 2].map((sIdx) => `
                                            <th style="padding:8px 10px;font-weight:800;color:#334155;text-align:center;width:20%;border-left:1px solid #e2e8f0;">
                                                <div style="font-size:12px;color:var(--gateway-red-500,#e8193f);margin-bottom:4px;">Sample ${sIdx + 1}</div>
                                                <input type="text" class="doc-meta-input" placeholder="R.O. #" value="${escapeHTML(state.samples[sIdx].ro_number || '')}" data-action="change-doc-meta" data-item-key="${escapeHTML(item.key)}" data-sample-index="${sIdx}" data-field="ro_number" style="width:90%;font-size:11px;padding:3px 6px;margin-bottom:2px;">
                                                <input type="text" class="doc-meta-input" placeholder="Job/Mileage" value="${escapeHTML(state.samples[sIdx].job_type || '')}" data-action="change-doc-meta" data-item-key="${escapeHTML(item.key)}" data-sample-index="${sIdx}" data-field="job_type" style="width:90%;font-size:11px;padding:3px 6px;">
                                            </th>
                                        `).join('')}
                                    </tr>
                                </thead>
                                <tbody>
                                    ${docSections.map((sec) => `
                                        <tr style="background:#f8fafc;border-top:1.5px solid #cbd5e1;border-bottom:1px solid #e2e8f0;">
                                            <td colspan="4" style="padding:6px 10px;font-weight:850;color:#0f172a;text-transform:uppercase;font-size:11px;letter-spacing:.04em;">
                                                <i class="fas fa-folder" style="color:var(--gateway-red-500);margin-right:4px;"></i> ${escapeHTML(sec.title)} (${sec.items?.length || 0} Standards)
                                            </td>
                                        </tr>
                                        ${(sec.items || []).map((docItem, dIdx) => {
                                            const itemNumber = docItem.code || docItem.metadata?.number || (dIdx + 1);
                                            return `<tr style="border-bottom:1px solid #f1f5f9;">
                                                <td style="padding:8px 10px;vertical-align:middle;">
                                                    <div style="font-weight:750;color:#1e293b;line-height:1.35;">
                                                        <strong style="color:var(--gateway-red-500);margin-right:4px;">#${itemNumber}</strong>
                                                        ${escapeHTML(docItem.prompt || docItem.label)}
                                                    </div>
                                                    ${docItem.how_to_check ? `<div style="font-size:10.5px;color:#64748b;margin-top:2px;"><i class="fas fa-info-circle" style="color:#3b82f6;"></i> ${escapeHTML(docItem.how_to_check)}</div>` : ''}
                                                </td>
                                                ${[0, 1, 2].map((sIdx) => {
                                                    const sAns = asObject(state.samples[sIdx].answers);
                                                    const val = sAns[String(docItem.id)] ?? sAns[docItem.key] ?? '';
                                                    return `<td style="padding:6px;vertical-align:middle;text-align:center;border-left:1px solid #e2e8f0;">
                                                        <div style="display:inline-flex;gap:4px;">
                                                            <button type="button" class="doc-choice-btn btn-yes ${val === 'yes' ? 'is-active' : ''}" data-action="answer-doc-item" data-item-key="${escapeHTML(item.key)}" data-sample-index="${sIdx}" data-docitem-id="${escapeHTML(docItem.id)}" data-value="yes" title="Yes" style="min-height:26px;padding:3px 7px;font-size:10px;">✓</button>
                                                            <button type="button" class="doc-choice-btn btn-no ${val === 'no' ? 'is-active' : ''}" data-action="answer-doc-item" data-item-key="${escapeHTML(item.key)}" data-sample-index="${sIdx}" data-docitem-id="${escapeHTML(docItem.id)}" data-value="no" title="No" style="min-height:26px;padding:3px 7px;font-size:10px;">✕</button>
                                                            <button type="button" class="doc-choice-btn btn-na ${val === 'na' ? 'is-active' : ''}" data-action="answer-doc-item" data-item-key="${escapeHTML(item.key)}" data-sample-index="${sIdx}" data-docitem-id="${escapeHTML(docItem.id)}" data-value="na" title="N/A" style="min-height:26px;padding:3px 7px;font-size:10px;">⊘</button>
                                                        </div>
                                                    </td>`;
                                                }).join('')}
                                            </tr>`;
                                        }).join('')}
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    `;
                } else {
                    const sampleTabsHtml = [0, 1, 2].map((sIdx) => {
                        const st = sampleStats[sIdx];
                        const isActive = sIdx === activeIdx;
                        return `
                            <button type="button" class="doc-sample-tab ${isActive ? 'is-active' : ''}" data-action="select-doc-sample" data-item-key="${escapeHTML(item.key)}" data-sample-index="${sIdx}">
                                <i class="fas fa-file-alt"></i>
                                <span>Sample ${sIdx + 1}</span>
                                <span class="doc-sample-tab-badge">${st.answered}/${totalDocQuestions}</span>
                                ${st.noCount > 0 ? `<span style="color:#dc2626;font-weight:900;margin-left:2px;">•</span>` : ''}
                            </button>
                        `;
                    }).join('');

                    const sectionsHtml = docSections.map((sec) => `
                        <div class="doc-section-card">
                            <div class="doc-section-title">
                                <span><i class="fas fa-folder" style="color:var(--gateway-red-500);margin-right:6px;"></i> ${escapeHTML(sec.title)}</span>
                                <span style="font-size:11px;font-weight:750;color:#64748b;">${sec.items?.length || 0} standards</span>
                            </div>
                            <div>
                                ${(sec.items || []).map((docItem, dIdx) => {
                                    const itemNumber = docItem.code || docItem.metadata?.number || (dIdx + 1);
                                    const val = activeAnswers[String(docItem.id)] ?? activeAnswers[docItem.key] ?? '';
                                    const checker = docItem.metadata?.checker || docItem.responsible_role || 'CE SERVICE';
                                    return `
                                        <div class="doc-question-row">
                                            <div class="doc-question-head">
                                                <div class="doc-question-prompt">
                                                    <strong style="color:var(--gateway-red-500);margin-right:6px;">#${itemNumber}</strong>
                                                    <span>${escapeHTML(docItem.prompt || docItem.label)}</span>
                                                </div>
                                                <span class="subform-card-badge checker-badge" style="font-size:10px;padding:2px 6px;">${escapeHTML(checker)}</span>
                                            </div>
                                            ${docItem.how_to_check ? `<div class="subform-htc-box" style="margin-bottom:6px;"><i class="fas fa-info-circle"></i> <div><strong>How to check:</strong> ${escapeHTML(docItem.how_to_check)}</div></div>` : ''}
                                            <div class="doc-choices-row">
                                                <button type="button" class="doc-choice-btn btn-yes ${val === 'yes' ? 'is-active' : ''}" data-action="answer-doc-item" data-item-key="${escapeHTML(item.key)}" data-sample-index="${activeIdx}" data-docitem-id="${escapeHTML(docItem.id)}" data-value="yes"><i class="fas fa-check-circle"></i> YES</button>
                                                <button type="button" class="doc-choice-btn btn-no ${val === 'no' ? 'is-active' : ''}" data-action="answer-doc-item" data-item-key="${escapeHTML(item.key)}" data-sample-index="${activeIdx}" data-docitem-id="${escapeHTML(docItem.id)}" data-value="no"><i class="fas fa-times-circle"></i> NO</button>
                                                <button type="button" class="doc-choice-btn btn-na ${val === 'na' ? 'is-active' : ''}" data-action="answer-doc-item" data-item-key="${escapeHTML(item.key)}" data-sample-index="${activeIdx}" data-docitem-id="${escapeHTML(docItem.id)}" data-value="na"><i class="fas fa-ban"></i> N/A</button>
                                            </div>
                                        </div>
                                    `;
                                }).join('')}
                            </div>
                        </div>
                    `).join('');

                    bodyHtml = `
                        <div class="doc-sample-tabs">
                            ${sampleTabsHtml}
                        </div>
                        <div class="doc-meta-card">
                            <div class="doc-meta-field">
                                <label class="doc-meta-label">R.O. Number (Sample ${activeIdx + 1})</label>
                                <input type="text" class="doc-meta-input" placeholder="e.g. RO-104928" value="${escapeHTML(activeSample.ro_number || '')}" data-action="change-doc-meta" data-item-key="${escapeHTML(item.key)}" data-sample-index="${activeIdx}" data-field="ro_number">
                            </div>
                            <div class="doc-meta-field">
                                <label class="doc-meta-label">Type of Job / Mileage</label>
                                <input type="text" class="doc-meta-input" placeholder="e.g. 10,000 km PMS" value="${escapeHTML(activeSample.job_type || '')}" data-action="change-doc-meta" data-item-key="${escapeHTML(item.key)}" data-sample-index="${activeIdx}" data-field="job_type">
                            </div>
                        </div>
                        ${sectionsHtml}
                    `;
                }

                wrapper.innerHTML = `
                    <div class="doc-audit-container">
                        <div class="doc-audit-head">
                            <div>
                                <span class="doc-title"><i class="fas fa-file-invoice" style="color:var(--gateway-red-500);margin-right:6px;"></i> DOS DOCUMENTATION AUDIT (3 SAMPLES — ${totalDocQuestions} STANDARDS)</span>
                                <div class="doc-counts">
                                    <span>${sampleStats.reduce((s, st) => s + st.answered, 0)} of ${totalDocQuestions * 3} audited across 3 samples</span>
                                    ${totalNo > 0 ? `<span class="noncompliant-pill">· ${totalNo} non-compliant findings</span>` : ''}
                                </div>
                            </div>
                            <div style="display:flex;gap:6px;flex-wrap:wrap;">
                                <button type="button" class="button soft" data-action="toggle-doc-view" data-item-key="${escapeHTML(item.key)}" style="padding:4px 9px;font-size:10.5px;">
                                    <i class="fas ${state.viewMode === 'all' ? 'fa-table-columns' : 'fa-list'}"></i>
                                    <span>${state.viewMode === 'all' ? 'Tabbed Sample View' : 'Compare All 3 Samples'}</span>
                                </button>
                                ${canManageTemplate ? `
                                    <button type="button" class="button soft" data-action="open-editor-documentation" style="padding:4px 9px;font-size:10.5px;">
                                        <i class="fas fa-edit"></i> <span>Edit Documentation Standards</span>
                                    </button>
                                ` : ''}
                            </div>
                        </div>
                        ${bodyHtml}
                        <div class="doc-status-banner ${derivedStatus === 'yes' ? 'is-compliant' : (derivedStatus === 'no' ? 'is-noncompliant' : 'is-inprogress')}">
                            <i class="fas ${derivedStatus === 'yes' ? 'fa-circle-check' : (derivedStatus === 'no' ? 'fa-circle-xmark' : 'fa-hourglass-half')}"></i>
                            <span>
                                ${derivedStatus === 'yes'
                                    ? 'All 3 service document samples compliant across all 17 standards (YES)'
                                    : (derivedStatus === 'no'
                                        ? `Non-compliant documentation standards detected (${totalNo} NO) — Corrective Action Plan & Finding required on parent standard`
                                        : 'Documentation audit in progress — complete all 3 samples')}
                            </span>
                        </div>
                    </div>
                `;
            }

            function renderUserOverview() {
                // Kept as no-op for backward-compatibility with updateSummary() calls
            }

            function renderStandardItem(item, number, sectionKey) {
                const key = escapeHTML(item.key);
                const name = `status-${slug(item.key, String(number))}`;
                const displayNumber = item.code || number;
                const isSubform = isSubformReferenceItem(item);
                const isDoc = isDocumentationReferenceItem(item);
                const isDerived = isSubform || isDoc;
                const checker = resolveItemChecker(item);
                return `<div class="item-row ${isSubform ? 'is-subform-row' : ''} ${isDoc ? 'is-documentation-row' : ''}" data-item-key="${key}" data-section-key="${escapeHTML(sectionKey)}" data-level="${escapeHTML(item.level.toLowerCase())}" data-checker="${escapeHTML(checker)}" data-search="${escapeHTML([item.code, item.label, item.description, item.responsible_role, checker, isSubform ? 'subform' : '', isDoc ? 'documentation' : ''].join(' ').toLowerCase())}">
                    <div class="item-number">${escapeHTML(displayNumber)}</div>
                    <div class="item-copy">
                        ${itemMeta(item)}
                        <div class="item-title-row">
                            <strong class="item-text">${escapeHTML(item.label)}</strong>
                            ${howToCheckButton(item)}
                        </div>
                        ${item.description && item.description !== item.label ? `<p class="item-description">${escapeHTML(item.description)}</p>` : ''}
                        ${responsibilities(item)}
                        ${isSubform ? `<div class="subform-inline-wrapper" data-item-key="${key}"></div>` : ''}
                        ${isDoc ? `<div class="documentation-inline-wrapper" data-item-key="${key}"></div>` : ''}
                    </div>
                    <div>
                        <div class="status-options ${isDerived ? 'subform-derived-status' : ''}" role="radiogroup" aria-label="Response for item ${number}">
                            <label class="status-option"><input type="radio" name="${escapeHTML(name)}" value="yes" ${isDerived ? 'disabled' : ''}><span>YES</span></label>
                            <label class="status-option"><input type="radio" name="${escapeHTML(name)}" value="no" ${isDerived ? 'disabled' : ''}><span>NO</span></label>
                            <label class="status-option"><input type="radio" name="${escapeHTML(name)}" value="na" ${isDerived ? 'disabled' : ''}><span>N/A</span></label>
                        </div>
                        ${isSubform ? `<div class="subform-status-badge-note" style="margin-top:6px;font-size:10px;font-weight:750;color:#64748b;text-align:center;">Derived from Subform</div>` : ''}
                        ${isDoc ? `<div class="subform-status-badge-note" style="margin-top:6px;font-size:10px;font-weight:750;color:#64748b;text-align:center;">Derived from Documentation</div>` : ''}
                    </div>
                    <div class="response-fields">
                        ${variant === 'dos'
                            ? `<label>Finding / N/A reason<textarea class="audit-input" data-field="finding" placeholder="Describe the finding or reason"></textarea></label>
                               <label>Escalation<select class="escalation-input" data-field="escalation">
                                   <option value="">Select escalation recipient</option>
                                   <option value="general_manager">General Manager</option>
                                   <option value="purchasing">Purchasing</option>
                                   <option value="property_management">PM (Property Management)</option>
                                   <option value="inventory">Inventory</option>
                               </select></label>
                               <label>Action plan<textarea class="audit-input" data-field="action_plan" placeholder="Required for NO"></textarea></label>
                               <label>Commitment date and time<input class="commitment-input" data-field="commitment_date" type="datetime-local" step="60"></label>
                               <div class="standard-attachment-block dos-photo-attachment">
                                   <label class="photo-attachment-label">
                                       <i class="fas fa-camera" aria-hidden="true"></i> <span>Attach photo (optional for NO / N/A)</span>
                                       <input type="file" class="standard-photo-file" accept="image/*" hidden>
                                   </label>
                                   <div class="attachment-preview" style="margin-top:4px;"></div>
                               </div>`
                            : `<label>Remarks (Required for NO or N/A)<textarea class="remark-input" data-field="remark" placeholder="Enter remarks (required for NO or N/A)"></textarea></label>
                               <div class="standard-attachment-block" style="margin-top:6px;">
                                   <label class="photo-attachment-label">
                                       <i class="fas fa-camera" aria-hidden="true"></i> <span>Attach photo (optional)</span>
                                       <input type="file" class="standard-photo-file" accept="image/*" hidden>
                                   </label>
                                   <div class="attachment-preview" style="margin-top:4px;"></div>
                               </div>`}
                    </div>
                    <div class="row-spacer" aria-hidden="true"></div>
                </div>`;
            }

            function isItemSlotActive(item, slotKey) {
                const activeSlots = item.active_slots ?? item.metadata?.active_slots;
                if (!activeSlots) {
                    return true;
                }
                if (Array.isArray(activeSlots)) {
                    return activeSlots.includes(slotKey);
                }
                if (typeof activeSlots === 'object') {
                    return Boolean(activeSlots[slotKey]);
                }
                return true;
            }

            function renderRestroomSection(section, sectionIndex, responses) {
                const slots = template.time_slots;
                const auditDateValue = auditDate ? auditDate.value : '';
                let todayStr = '';
                let curH = 0;
                let curM = 0;
                try {
                    todayStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Manila' }).format(new Date());
                    const manilaTimeParts = new Intl.DateTimeFormat('en-US', {
                        timeZone: 'Asia/Manila',
                        hour: 'numeric',
                        minute: 'numeric',
                        hour12: false,
                    }).formatToParts(new Date());
                    curH = parseInt(manilaTimeParts.find(p => p.type === 'hour')?.value || '0', 10);
                    curM = parseInt(manilaTimeParts.find(p => p.type === 'minute')?.value || '0', 10);
                } catch (e) {
                    const now = new Date();
                    todayStr = now.toISOString().slice(0, 10);
                    curH = now.getHours();
                    curM = now.getMinutes();
                }
                const isToday = !auditDateValue || auditDateValue === todayStr;
                const currentMinutes = curH * 60 + curM;

                const isFutureSlot = (slotKey) => {
                    if (canManageTemplate) return false;
                    if (!isToday) {
                        return auditDateValue > todayStr;
                    }
                    const parts = (slotKey || '').split(':');
                    const slotMinutes = (parseInt(parts[0], 10) || 0) * 60 + (parseInt(parts[1], 10) || 0);
                    return slotMinutes > currentMinutes;
                };

                const headings = slots.map((slotValue) => {
                    const locked = isFutureSlot(slotValue.key);
                    return `<th class="slot-cell${locked ? ' slot-locked-col' : ''}" scope="col">${escapeHTML(slotValue.label)}${locked ? ' <i class="fas fa-lock" title="Locked until ' + escapeHTML(slotValue.label) + '" style="font-size:10px;opacity:0.6;margin-left:3px;"></i>' : ''}</th>`;
                }).join('');

                const visibleItems = canManageTemplate
                    ? section.items
                    : section.items.filter((item) => item.is_active !== false);

                const rows = visibleItems.length === 0
                    ? `<tr><td colspan="${slots.length + 2}" class="section-empty">No active checklist questions in this section.</td></tr>`
                    : visibleItems.map((item, itemIndex) => {
                        const response = responseFor(item, responses);
                        const details = parseObject(response.details);
                        const savedSlots = asObject(details.slots);
                        const slotCells = slots.map((slotValue) => {
                            const isActive = isItemSlotActive(item, slotValue.key);

                            if (canManageTemplate) {
                                return `<td class="slot-cell slot-cell-toggle">
                                    <label class="restroom-slot-checkbox-label" title="${isActive ? 'Active for ' + escapeHTML(slotValue.label) + '. Click to turn off.' : 'Turned off for ' + escapeHTML(slotValue.label) + '. Click to turn on.'}">
                                        <input type="checkbox"
                                            class="restroom-slot-toggle"
                                            data-item-key="${escapeHTML(item.key)}"
                                            data-slot="${escapeHTML(slotValue.key)}"
                                            ${isActive ? 'checked' : ''}
                                            aria-label="${escapeHTML(item.label)} at ${escapeHTML(slotValue.label)}">
                                    </label>
                                </td>`;
                            }

                            if (!isActive) {
                                return `<td class="slot-cell slot-cell-off" title="Turned off by administrator"><span class="badge-slot-off">—</span></td>`;
                            }

                            const locked = isFutureSlot(slotValue.key);
                            if (locked) {
                                return `<td class="slot-cell slot-cell-locked"><span class="badge-slot-locked" title="Locked until ${escapeHTML(slotValue.label)}. Future inspections cannot be recorded ahead of time." style="display:inline-flex;align-items:center;gap:3px;padding:3px 6px;border-radius:4px;background:#f1f5f9;color:#94a3b8;font-size:10px;font-weight:700;cursor:not-allowed;"><i class="fas fa-lock" style="font-size:9px;"></i>Locked</span></td>`;
                            }
                            const storedValue = String(savedSlots[slotValue.key] ?? savedSlots[slotValue.label] ?? '').toLowerCase();
                            const value = ['good', '/', 'yes'].includes(storedValue)
                                ? 'good'
                                : (['not_good', 'not-good', 'x', 'no'].includes(storedValue) ? 'not_good' : '');
                            return `<td class="slot-cell"><select class="slot-select" data-slot="${escapeHTML(slotValue.key)}" aria-label="${escapeHTML(item.label)} at ${escapeHTML(slotValue.label)}">
                                <option value=""></option>
                                <option value="good"${value === 'good' ? ' selected' : ''}>Good</option>
                                <option value="not_good"${value === 'not_good' ? ' selected' : ''}>Not good</option>
                            </select></td>`;
                        }).join('');
                        const remark = response.remark ?? response.remarks ?? '';
                        const attachmentPath = response.attachment_path ?? '';
                        const attachmentUrl = response.attachment_url ?? (attachmentPath ? `/storage/${attachmentPath.replace(/^\/+/, '')}` : '');
                        const itemNumber = escapeHTML(item.code || (template.sections.slice(0, sectionIndex).reduce((count, entry) => count + entry.items.length, 0) + itemIndex + 1));
                        return `<tr data-item-key="${escapeHTML(item.key)}" data-attachment-path="${escapeHTML(attachmentPath)}">
                            <th scope="row">
                                <span class="item-number">${itemNumber}.</span>
                                <span class="item-text">${escapeHTML(item.label)}</span>
                                ${howToCheckButton(item)}
                                ${item.description && item.description !== item.label ? `<p class="item-description">${escapeHTML(item.description)}</p>` : ''}
                                ${responsibilities(item)}
                            </th>
                            ${slotCells}
                            <td>
                                <textarea class="restroom-remark" data-field="remark" placeholder="Add remarks"${canManageTemplate ? ' readonly' : ''}>${escapeHTML(remark)}</textarea>
                                ${attachmentUrl ? `<div class="attachment-preview" style="margin-top:6px;"><a href="${escapeHTML(attachmentUrl)}" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:700;color:var(--gateway-red-500,#e8193f);text-decoration:none;"><i class="fas fa-image"></i> View photo</a></div>` : ''}
                            </td>
                        </tr>`;
                    }).join('');
                return `<section class="checklist-section restroom-section" data-section-key="${escapeHTML(section.key)}">
                    <div class="section-header"><div class="section-heading-copy"><span class="section-index">${sectionIndex + 1}</span><div><h4>${escapeHTML(section.title)}</h4><span class="section-count">${visibleItems.length} item${visibleItems.length === 1 ? '' : 's'}</span></div></div></div>
                    ${slots.length ? `<div class="restroom-scroll"><table class="restroom-table"><thead><tr><th scope="col">Checklist Item</th>${headings}<th scope="col">Remarks</th></tr></thead><tbody>${rows}</tbody></table></div>` : '<div class="section-empty">No inspection time slots are configured for this template.</div>'}
                </section>`;
            }

            function renderChecklist(submissionValue = currentSubmission) {
                const responses = responseMap(submissionValue);
                let runningNumber = 0;
                if (!template.sections.length) {
                    container.innerHTML = '<div class="empty-state">This database template has no active sections.</div>';
                } else if (usesRestroomTimeSlots()) {
                    container.innerHTML = template.sections.map((section, sectionIndex) => renderRestroomSection(section, sectionIndex, responses)).join('');
                } else {
                    container.innerHTML = template.sections.map((section, sectionIndex) => {
                        const items = section.items.map((item) => renderStandardItem(item, ++runningNumber, section.key)).join('');
                        return `<section class="${variant === 'dos' ? 'coverage-section' : 'checklist-section'}" data-section-key="${escapeHTML(section.key)}">
                            <div class="section-header"><div class="section-heading-copy"><span class="section-index">${sectionIndex + 1}</span><div><h4>${escapeHTML(section.title)}</h4><span class="section-count">${section.items.length} item${section.items.length === 1 ? '' : 's'}</span></div></div></div>
                            ${items || '<div class="section-empty">No active items in this section.</div>'}
                        </section>`;
                    }).join('');
                    applyResponses(submissionValue);
                    populateFilters();
                }
                syncChecklistModeUI();
                paintSlotSelects();
                updateSummary();
                checklistView.refresh();
            }

            function applyResponses(submissionValue) {
                const responses = responseMap(submissionValue);
                container.querySelectorAll('.item-row[data-item-key], tbody tr[data-item-key]').forEach((row) => {
                    const item = template.sections.flatMap((section) => section.items).find((entry) => entry.key === row.dataset.itemKey);
                    if (!item) return;
                    const response = responseFor(item, responses);
                    const details = parseObject(response.details);

                    if (isSubformReferenceItem(item)) {
                        const subformSection = getSubformSection(item);
                        const savedEligibility = details.eligibility || (response.status === 'na' ? 'na' : (details.subform_answers && Object.keys(details.subform_answers).length > 0 ? 'show_subform' : null));
                        const savedAnswers = asObject(details.subform_answers);
                        subformState[item.key] = {
                            eligibility: savedEligibility,
                            answers: { ...savedAnswers },
                            activeIndex: subformState[item.key]?.activeIndex || 0,
                            viewMode: subformState[item.key]?.viewMode || 'dropdown',
                        };
                        renderSubformBox(row, item, subformSection);
                    } else if (isDocumentationReferenceItem(item)) {
                        const savedSamples = Array.isArray(details.documentation_samples) ? details.documentation_samples : [];
                        const savedAnswers = asObject(details.documentation_answers);
                        const defaultSamples = [
                            { ro_number: '', job_type: '', answers: {} },
                            { ro_number: '', job_type: '', answers: {} },
                            { ro_number: '', job_type: '', answers: {} },
                        ];
                        const samples = defaultSamples.map((def, idx) => {
                            const existing = savedSamples[idx] || {};
                            return {
                                ro_number: existing.ro_number || '',
                                job_type: existing.job_type || '',
                                answers: { ...(existing.answers || (idx === 0 ? savedAnswers : {})) },
                            };
                        });
                        documentationState[item.key] = {
                            activeSampleIndex: documentationState[item.key]?.activeSampleIndex || 0,
                            viewMode: documentationState[item.key]?.viewMode || 'tabs',
                            samples,
                        };
                        renderDocumentationBox(row, item);
                    } else {
                        const status = normalizeStatus(response.status);
                        const statusInput = Array.from(row.querySelectorAll('input[type="radio"]')).find((input) => input.value === status);
                        if (statusInput) statusInput.checked = true;
                    }
                    const attachmentPath = response.attachment_path ?? '';
                    const attachmentUrl = response.attachment_url ?? (attachmentPath ? `/storage/${attachmentPath.replace(/^\/+/, '')}` : '');
                    row.dataset.attachmentPath = attachmentPath;
                    const previewEl = row.querySelector('.attachment-preview');
                    if (previewEl) {
                        if (attachmentUrl) {
                            previewEl.innerHTML = `<div style="display:inline-flex;align-items:center;gap:8px;">
                                <a href="${escapeHTML(attachmentUrl)}" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:700;color:var(--gateway-red-500,#e8193f);text-decoration:none;"><i class="fas fa-image"></i> View photo</a>
                                <button type="button" class="btn-remove-photo" style="background:none;border:none;color:#94a3b8;font-size:11px;cursor:pointer;padding:0;" title="Remove photo"><i class="fas fa-times"></i></button>
                            </div>`;
                            const removeBtn = previewEl.querySelector('.btn-remove-photo');
                            if (removeBtn) {
                                removeBtn.addEventListener('click', () => {
                                    row.dataset.attachmentPath = '';
                                    previewEl.innerHTML = '';
                                    const fileInput = row.querySelector('.standard-photo-file');
                                    if (fileInput) fileInput.value = '';
                                });
                            }
                        } else {
                            previewEl.innerHTML = '';
                        }
                    }
                    const photoInput = row.querySelector('.standard-photo-file');
                    if (photoInput && !photoInput.dataset.bound) {
                        photoInput.dataset.bound = 'true';
                        photoInput.addEventListener('change', async (e) => {
                            const file = e.target.files?.[0];
                            if (!file) return;
                            try {
                                if (previewEl) previewEl.innerHTML = '<span style="font-size:11px;color:#64748b;"><i class="fas fa-spinner fa-spin"></i> Uploading photo...</span>';
                                const res = await uploadPhoto(file);
                                row.dataset.attachmentPath = res.path;
                                if (previewEl) {
                                    previewEl.innerHTML = `<div style="display:inline-flex;align-items:center;gap:8px;">
                                        <a href="${escapeHTML(res.url)}" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:700;color:var(--gateway-red-500,#e8193f);text-decoration:none;"><i class="fas fa-image"></i> View photo</a>
                                        <button type="button" class="btn-remove-photo" style="background:none;border:none;color:#94a3b8;font-size:11px;cursor:pointer;padding:0;" title="Remove photo"><i class="fas fa-times"></i></button>
                                    </div>`;
                                    previewEl.querySelector('.btn-remove-photo')?.addEventListener('click', () => {
                                        row.dataset.attachmentPath = '';
                                        previewEl.innerHTML = '';
                                        photoInput.value = '';
                                    });
                                }
                            } catch (err) {
                                alert(err.message || 'Photo upload failed.');
                                if (previewEl) previewEl.innerHTML = '';
                            }
                        });
                    }
                    row.querySelectorAll('[data-field]').forEach((input) => {
                        const field = input.dataset.field;
                        if (field === 'remark') {
                            input.value = String(response.remark ?? response.remarks ?? '');
                        } else if (field === 'escalation') {
                            input.value = normalizeEscalation(details.escalation ?? response.escalation);
                        } else if (field === 'commitment_date') {
                            input.value = normalizeDateTimeLocal(response.commitment_date ?? response.commitmentDate);
                        } else {
                            input.value = String(response[field] ?? '');
                        }
                    });
                });
            }

            async function uploadPhoto(file) {
                const formData = new FormData();
                formData.append('photo', file);
                const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
                const response = await fetch(`/checklists/${template.slug}/attachments`, {
                    method: 'POST',
                    headers: {
                        'X-CSRF-TOKEN': csrfToken,
                        'Accept': 'application/json',
                    },
                    body: formData,
                });
                if (!response.ok) {
                    const err = await response.json().catch(() => ({}));
                    throw new Error(err.message || 'Failed to upload photo.');
                }
                return await response.json();
            }

            function paintSlotSelects() {
                container.querySelectorAll('.slot-select').forEach((select) => {
                    select.classList.toggle('is-good', select.value === 'good');
                    select.classList.toggle('is-not-good', select.value === 'not_good');
                });
            }

            function populateFilters() {
                const sectionFilter = document.getElementById('sectionFilter');
                const levelFilter = document.getElementById('levelFilter');
                if (!sectionFilter || !levelFilter) return;
                const currentSection = sectionFilter.value;
                const currentLevel = levelFilter.value;
                sectionFilter.innerHTML = '<option value="all">All sections</option>' + template.sections
                    .map((section) => `<option value="${escapeHTML(section.key)}">${escapeHTML(section.title)}</option>`).join('');
                const levels = [...new Set(template.sections.flatMap((section) => section.items.map((item) => item.level)).filter(Boolean))];
                levelFilter.innerHTML = '<option value="all">All levels</option>' + levels
                    .map((level) => `<option value="${escapeHTML(level.toLowerCase())}">${escapeHTML(level)}</option>`).join('');
                if ([...sectionFilter.options].some((option) => option.value === currentSection)) sectionFilter.value = currentSection;
                if ([...levelFilter.options].some((option) => option.value === currentLevel)) levelFilter.value = currentLevel;
                filterItems();
            }

            function matchesCheckerFilter(item, filterCode) {
                if (!filterCode || filterCode === 'all') return true;
                const filterUpper = String(filterCode).toUpperCase().trim();
                const checker = resolveItemChecker(item).toUpperCase().trim();
                const respRole = String(item.responsible_role || item.metadata?.responsible_role || item.metadata?.responsible || '').toUpperCase().trim();
                const pic = String(item.metadata?.pic || '').toUpperCase().trim();

                // 1. Specific checker mappings for DOS Aftersales
                if (['CE_SERVICE', 'CE SERVICE', 'CE'].includes(filterUpper)) {
                    return ['CE SERVICE', 'CE'].includes(checker) || ['CE SERVICE', 'CE'].includes(respRole);
                }
                if (['WORKSHOP_SUP', 'WORKSHOP SUP', 'WS SUP', 'WS', 'WORKSHOP SUPERVISOR'].includes(filterUpper)) {
                    return ['WORKSHOP SUP', 'WS SUP', 'WS', 'WORKSHOP SUPERVISOR'].includes(checker) || ['WORKSHOP SUP', 'WS SUP', 'WS', 'WORKSHOP SUPERVISOR'].includes(respRole);
                }
                if (['AFTERSALES_MGR', 'ASM', 'AFTERSALES MANAGER'].includes(filterUpper)) {
                    return ['ASM', 'AFTERSALES MANAGER'].includes(checker) || ['ASM', 'AFTERSALES MANAGER'].includes(respRole);
                }
                if (['PARTS_SUP', 'PARTS', 'PARTS SUPERVISOR'].includes(filterUpper)) {
                    return ['PARTS', 'PARTS SUPERVISOR'].includes(checker) || ['PARTS', 'PARTS SUPERVISOR'].includes(respRole);
                }
                if (['JOB_CONTROLLER', 'JC', 'JOB CONTROLLER'].includes(filterUpper)) {
                    return ['JC', 'JOB CONTROLLER'].includes(checker) || ['JC', 'JOB CONTROLLER'].includes(respRole);
                }

                // 2. 5S and other roles
                if (['5S_UTILITIES', 'UTILITIES_USER', 'UTILITIES'].includes(filterUpper)) {
                    return variant === 'restroom' || ['5S_UTILITIES', 'UTILITIES'].includes(checker) || ['5S_UTILITIES', 'UTILITIES'].includes(respRole) || ['5S_UTILITIES', 'UTILITIES'].includes(pic);
                }
                if (['5S_SALES', 'SALES_5S_USER'].includes(filterUpper)) {
                    return template.slug === 'sales' || ['5S_SALES'].includes(checker) || ['5S_SALES'].includes(respRole) || ['5S_SALES'].includes(pic);
                }
                if (['5S_SERVICE', 'SERVICE_5S_USER'].includes(filterUpper)) {
                    return template.slug === 'service' || ['5S_SERVICE'].includes(checker) || ['5S_SERVICE'].includes(respRole) || ['5S_SERVICE'].includes(pic);
                }
                if (['SALES MANAGER', 'SALES_MANAGER', 'SM'].includes(filterUpper)) {
                    return template.slug === 'dealer-operations-standards-sales' || ['SALES MANAGER', 'SM'].includes(checker) || ['SALES MANAGER', 'SM'].includes(respRole) || ['SALES MANAGER', 'SM'].includes(pic);
                }

                return checker === filterUpper || respRole === filterUpper || pic === filterUpper;
            }

            function filterItems() {
                if (usesRestroomTimeSlots()) return;
                const query = document.getElementById('searchInput').value.trim().toLowerCase();
                const section = document.getElementById('sectionFilter').value;
                const level = document.getElementById('levelFilter').value;
                let visible = 0;
                container.querySelectorAll('.item-row').forEach((row) => {
                    const itemKey = row.dataset.itemKey;
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    let matchesUser = true;
                    if (activeUserFilter && item) {
                        matchesUser = matchesCheckerFilter(item, activeUserFilter);
                    }

                    const matches = (!query || row.dataset.search.includes(query))
                        && (section === 'all' || row.dataset.sectionKey === section)
                        && (level === 'all' || row.dataset.level === level)
                        && matchesUser;
                    row.hidden = !matches;
                    if (matches) visible += 1;
                });
                container.querySelectorAll('[data-section-key]').forEach((sectionElement) => {
                    const rows = sectionElement.querySelectorAll('.item-row');
                    if (rows.length) sectionElement.hidden = ![...rows].some((row) => !row.hidden);
                });

                const showingEl = document.getElementById('showingCount');
                if (showingEl) {
                    if (activeUserFilter) {
                        const totalQuestions = template.sections.reduce((sum, s) => sum + s.items.length, 0);
                        showingEl.innerHTML = `Showing <strong>${visible}</strong> of ${totalQuestions} items (filtered by <strong>${escapeHTML(activeUserFilter)}</strong>) <button type="button" id="clearCheckerFilterBtn" style="border:none;background:#fee2e2;color:#b91c1c;padding:2px 7px;border-radius:4px;font-size:10.5px;font-weight:800;cursor:pointer;margin-left:6px;" title="Clear filter">✕ Clear</button>`;
                        document.getElementById('clearCheckerFilterBtn')?.addEventListener('click', () => {
                            activeUserFilter = null;
                            document.querySelectorAll('.checker-pill-btn').forEach((b) => b.classList.remove('is-active'));
                            document.querySelector('.checker-filter-bar .checker-pill-btn')?.classList.add('is-active');
                            filterItems();
                        });
                    } else {
                        showingEl.textContent = `Showing ${visible} item${visible === 1 ? '' : 's'}`;
                    }
                }

                checklistView.refresh();
            }

            function collectResponses() {
                const itemLookup = new Map(template.sections.flatMap((section) => section.items).map((item) => [item.key, item]));
                if (usesRestroomTimeSlots()) {
                    return [...container.querySelectorAll('tbody tr[data-item-key]')].map((row) => {
                        const item = itemLookup.get(row.dataset.itemKey) || {};
                        const slots = {};
                        row.querySelectorAll('.slot-select').forEach((select) => { slots[select.dataset.slot] = select.value || null; });
                        const slotValues = Object.values(slots);
                        const status = slotValues.some((value) => value === 'not_good')
                            ? 'no'
                            : (slotValues.length && slotValues.every((value) => value === 'good') ? 'yes' : null);
                        const remark = row.querySelector('[data-field="remark"]')?.value.trim() || null;
                        return {
                            item_id: item.id,
                            item_key: item.key,
                            status,
                            remark,
                            remarks: remark,
                            finding: null,
                            action_plan: null,
                            commitment_date: null,
                            attachment_path: row.dataset.attachmentPath || null,
                            details: { slots },
                        };
                    });
                }
                return [...container.querySelectorAll('.item-row[data-item-key]')].map((row) => {
                    const item = itemLookup.get(row.dataset.itemKey) || {};
                    const value = (field) => row.querySelector(`[data-field="${field}"]`)?.value.trim() || null;
                    const remark = value('remark');
                    const isSub = isSubformReferenceItem(item);
                    const isDoc = isDocumentationReferenceItem(item);
                    let details = variant === 'dos' ? { escalation: value('escalation') } : {};

                    if (isSub) {
                        const state = subformState[item.key] || {};
                        details.eligibility = state.eligibility || null;
                        details.subform_answers = state.answers || {};
                    } else if (isDoc) {
                        const state = documentationState[item.key] || {};
                        details.documentation_samples = state.samples || [];
                        details.documentation_answers = state.samples?.[0]?.answers || {};
                    }

                    return {
                        item_id: item.id,
                        item_key: item.key,
                        status: row.querySelector('input[type="radio"]:checked')?.value || null,
                        remark,
                        remarks: remark,
                        finding: value('finding'),
                        action_plan: value('action_plan'),
                        commitment_date: value('commitment_date'),
                        attachment_path: row.dataset.attachmentPath || null,
                        details,
                    };
                });
            }

            function updateSummary() {
                renderUserOverview();

                if (canManageTemplate && usesRestroomTimeSlots()) {
                    const totalQuestions = template.sections.reduce((sum, s) => sum + s.items.length, 0);
                    document.getElementById('scoreValue').textContent = '—';
                    document.getElementById('scoreBar').style.width = '0%';
                    document.getElementById('scoreMeta').textContent = 'Admin control';
                    document.getElementById('completionValue').textContent = '—';
                    document.getElementById('completionBar').style.width = '0%';
                    document.getElementById('answeredCount').textContent = `${totalQuestions} questions`;
                    document.getElementById('findingsValue').textContent = '0';
                    document.getElementById('findingsBar').style.width = '0%';
                    document.getElementById('findingsMeta').textContent = 'Active';
                    document.getElementById('itemCountValue').textContent = totalQuestions;
                    document.getElementById('sectionCountValue').textContent = `${template.sections.length} section${template.sections.length === 1 ? '' : 's'}`;
                    document.getElementById('footerSummary').innerHTML = '<strong>Inspection schedule active:</strong> Check or uncheck time slots to enable or disable questions for each inspection on user checklists.';
                    return;
                }

                const responses = collectResponses();
                let total;
                let answered;
                let positive;
                let findings;
                if (usesRestroomTimeSlots()) {
                    const allSlots = responses.flatMap((response) => Object.values(response.details.slots));
                    total = allSlots.length;
                    answered = allSlots.filter(Boolean).length;
                    positive = allSlots.filter((value) => value === 'good').length;
                    findings = allSlots.filter((value) => value === 'not_good').length;
                } else {
                    total = responses.length;
                    answered = responses.filter((response) => response.status).length;
                    positive = responses.filter((response) => response.status === 'yes').length;
                    findings = responses.filter((response) => response.status === 'no').length;
                }
                const applicable = Math.max(0, answered - (usesRestroomTimeSlots() ? 0 : responses.filter((response) => response.status === 'na').length));
                const score = applicable ? Math.round((positive / applicable) * 100) : 0;
                const completion = total ? Math.round((answered / total) * 100) : 0;
                const itemCount = template.sections.reduce((sum, section) => sum + section.items.length, 0);
                document.getElementById('scoreValue').textContent = `${score}%`;
                document.getElementById('scoreBar').style.width = `${score}%`;
                document.getElementById('scoreMeta').textContent = `${positive} / ${applicable}`;
                document.getElementById('completionValue').textContent = `${completion}%`;
                document.getElementById('completionBar').style.width = `${completion}%`;
                document.getElementById('answeredCount').textContent = `${answered} / ${total}`;
                document.getElementById('findingsValue').textContent = findings;
                document.getElementById('findingsBar').style.width = total ? `${Math.round((findings / total) * 100)}%` : '0%';
                document.getElementById('findingsMeta').textContent = findings ? 'Review required' : 'Clear';
                document.getElementById('itemCountValue').textContent = itemCount;
                document.getElementById('sectionCountValue').textContent = `${template.sections.length} section${template.sections.length === 1 ? '' : 's'}`;
                document.getElementById('footerSummary').innerHTML = `<strong>${answered} of ${total}</strong> responses recorded · <strong>${score}%</strong> compliance · <strong>${findings}</strong> finding${findings === 1 ? '' : 's'}.`;
            }

            function validateForSubmit() {
                const responses = collectResponses();
                container.querySelectorAll('.validation-error').forEach((row) => row.classList.remove('validation-error'));
                let firstInvalid = null;
                if (usesRestroomTimeSlots()) {
                    container.querySelectorAll('tbody tr[data-item-key]').forEach((row, index) => {
                        if (Object.values(responses[index].details.slots).some((value) => !value)) {
                            row.classList.add('validation-error');
                            firstInvalid ??= row;
                        }
                    });
                } else {
                    container.querySelectorAll('.item-row[data-item-key]').forEach((row, index) => {
                        const response = responses[index];
                        const dosInvalid = variant === 'dos' && (
                            (response.status === 'no' && (!response.finding || !response.action_plan || !response.commitment_date))
                            || (response.status === 'na' && !response.finding)
                        );
                        const standardInvalid = variant !== 'dos'
                            && ['no', 'na'].includes(response.status)
                            && !response.remark;
                        if (!response.status || dosInvalid || standardInvalid) {
                            row.classList.add('validation-error');
                            firstInvalid ??= row;
                        }
                    });
                }
                if (firstInvalid) {
                    document.getElementById('searchInput').value = '';
                    document.getElementById('sectionFilter').value = 'all';
                    document.getElementById('levelFilter').value = 'all';
                    filterItems();
                    checklistView.reveal(firstInvalid);
                    firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    firstInvalid.querySelector('input, select, textarea')?.focus({ preventScroll: true });
                    const message = usesRestroomTimeSlots()
                        ? 'Record every scheduled mark before submitting.'
                        : (variant === 'dos'
                            ? 'Complete every response and the required findings and corrective actions.'
                            : 'Complete every response and add remarks for NO or N/A items.');
                    showToast('Incomplete checklist', message, 'error');
                    return false;
                }
                return true;
            }

            function requestPayload(status) {
                return {
                    date: auditDate.value,
                    checklist_date: auditDate.value,
                    branch: branchSelect.value || null,
                    status,
                    context: { template_slug: template.slug, variant },
                    responses: collectResponses(),
                };
            }

            async function apiRequest(url, options = {}) {
                if (!url) throw new Error('The requested database endpoint is not configured.');
                const response = await fetch(url, {
                    credentials: 'same-origin',
                    ...options,
                    headers: {
                        Accept: 'application/json',
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': csrfToken,
                        ...(options.headers || {}),
                    },
                });
                const contentType = response.headers.get('content-type') || '';
                const data = response.status === 204
                    ? null
                    : (contentType.includes('application/json') ? await response.json() : null);
                if (!response.ok) {
                    const validation = data?.errors ? Object.values(data.errors).flat().join(' ') : '';
                    throw new Error(validation || data?.message || `Request failed (${response.status}).`);
                }
                return data;
            }

            function setBusy(button, busy, busyLabel) {
                if (!button) return;
                if (busy) {
                    button.dataset.label = button.innerHTML;
                    button.textContent = busyLabel;
                    button.disabled = true;
                } else {
                    button.innerHTML = button.dataset.label || button.innerHTML;
                    button.disabled = false;
                }
            }

            async function save(status, sourceButton) {
                if (!auditDate.value) {
                    showToast('Date required', 'Choose a checklist date before saving.', 'error');
                    return;
                }
                if (status === 'submitted' && !validateForSubmit()) return;
                const url = status === 'submitted' ? endpoints.submit : endpoints.draft;
                setBusy(sourceButton, true, status === 'submitted' ? 'Submitting…' : 'Saving…');
                try {
                    const data = await apiRequest(url, { method: 'POST', body: JSON.stringify(requestPayload(status)) });
                    currentSubmission = data?.submission ?? data ?? { status, responses: responseMapFromArray(collectResponses()) };
                    setRecordStatus(currentSubmission.status ?? status);
                    showToast(status === 'submitted' ? 'Checklist submitted' : 'Draft saved', 'The database record is up to date.', 'success');
                } catch (error) {
                    showToast('Unable to save', error.message, 'error');
                } finally {
                    setBusy(sourceButton, false);
                }
            }

            function responseMapFromArray(responses) {
                return responses.reduce((map, response) => {
                    map[String(response.item_key ?? response.item_id)] = response;
                    return map;
                }, {});
            }

            function setRecordStatus(status) {
                const normalized = String(status ?? '').toLowerCase();
                const labels = { draft: 'Draft in database', submitted: 'Submitted', complete: 'Submitted' };
                statusElement.textContent = labels[normalized] || 'No saved record';
            }

            async function loadSubmission({ quiet = false } = {}) {
                if (!endpoints.load || !auditDate.value) {
                    setRecordStatus(currentSubmission?.status);
                    return;
                }
                if (loadController) loadController.abort();
                loadController = new AbortController();
                statusElement.textContent = 'Loading database record…';
                const url = new URL(endpoints.load, window.location.origin);
                url.searchParams.set('date', auditDate.value);
                url.searchParams.set('checklist_date', auditDate.value);
                if (branchSelect.value) url.searchParams.set('branch', branchSelect.value);
                try {
                    const data = await apiRequest(url.toString(), { method: 'GET', signal: loadController.signal });
                    if (data?.template) {
                        template = normalizeTemplate(data.template);
                        syncTemplateHeadings();
                    }
                    currentSubmission = data?.submission ?? (data && Object.prototype.hasOwnProperty.call(data, 'responses') ? data : null);
                    renderChecklist(currentSubmission);
                    setRecordStatus(currentSubmission?.status);
                    if (!quiet) showToast('Checklist loaded', currentSubmission ? 'Saved responses were loaded from the database.' : 'No saved responses exist for this branch and date.');
                } catch (error) {
                    if (error.name === 'AbortError') return;
                    currentSubmission = null;
                    renderChecklist(null);
                    setRecordStatus(null);
                    if (!quiet) showToast('Unable to load', error.message, 'error');
                }
            }

            async function resetSubmission() {
                if (!confirm('Reset the responses for this branch and date? Saved draft responses will be cleared.')) return;
                const button = document.getElementById('resetResponsesButton');
                setBusy(button, true, 'Resetting…');
                const url = endpoints.reset ? new URL(endpoints.reset, window.location.origin) : null;
                if (url) {
                    url.searchParams.set('date', auditDate.value);
                    url.searchParams.set('checklist_date', auditDate.value);
                    if (branchSelect.value) url.searchParams.set('branch', branchSelect.value);
                }
                try {
                    await apiRequest(url?.toString(), {
                        method: 'DELETE',
                        body: JSON.stringify({ date: auditDate.value, checklist_date: auditDate.value, branch: branchSelect.value || null }),
                    });
                    currentSubmission = null;
                    renderChecklist(null);
                    setRecordStatus(null);
                    showToast('Responses reset', 'The saved draft responses were cleared.', 'success');
                } catch (error) {
                    showToast('Unable to reset', error.message, 'error');
                } finally {
                    setBusy(button, false);
                }
            }

            function syncTemplateHeadings() {
                document.getElementById('pageChecklistName').textContent = template.name;
                document.getElementById('checklistHeading').childNodes[0].nodeValue = `${template.name} `;
                document.getElementById('templateChip').textContent = template.name;
                const description = document.getElementById('pageChecklistDescription');
                if (description) {
                    description.textContent = template.description;
                    description.hidden = !template.description.trim();
                }
                const instructions = document.getElementById('checklistInstructions');
                if (instructions) instructions.textContent = template.instructions;
                document.getElementById('checklistInstructionsNotice').hidden = !template.instructions.trim();
            }

            function showToast(title, message, type = '') {
                const toast = document.createElement('div');
                const toastType = type || 'info';
                toast.className = `toast toast-${toastType} ${toastType}`;
                toast.setAttribute('role', 'alert');
                toast.setAttribute('aria-atomic', 'true');

                const markChar = toastType === 'error' ? '!' : (toastType === 'warning' ? '!' : (toastType === 'info' ? 'i' : '✓'));

                toast.innerHTML = `<span class="toast-mark" aria-hidden="true">${markChar}</span><div class="toast-body"><strong class="toast-title"></strong><span class="toast-message"></span></div><button type="button" class="toast-dismiss" aria-label="Close notification">×</button>`;
                toast.querySelector('.toast-title').textContent = title;
                toast.querySelector('.toast-message').textContent = message;

                let dismissed = false;
                const dismiss = () => {
                    if (dismissed) return;
                    dismissed = true;
                    toast.classList.add('toast-leaving');
                    window.setTimeout(() => toast.remove(), 220);
                };

                toast.querySelector('.toast-dismiss')?.addEventListener('click', dismiss);
                toastRegion.appendChild(toast);
                window.setTimeout(dismiss, 4200);
            }

            function editorSectionMarkup(section = {}, sectionIndex = 0) {
                const items = Array.isArray(section.items) ? section.items : [];
                return `<section class="editor-section" data-id="${escapeHTML(section.id ?? '')}" data-key="${escapeHTML(section.key ?? newEditorKey('section'))}">
                    <div class="editor-section-head">
                        <button class="editor-drag-handle" type="button" data-editor-drag="section" aria-label="Move section" aria-describedby="editorOrderHelp"><i class="fas fa-grip-vertical" aria-hidden="true"></i></button>
                        <label class="field"><span>Section <span data-editor-section-number>${sectionIndex + 1}</span></span><input class="section-name-input" data-editor-field="title" value="${escapeHTML(section.title ?? '')}" placeholder="Section title" required></label>
                        <button class="button danger editor-remove" type="button" data-editor-action="remove-section" aria-label="Remove section" title="Remove section"><i class="fas fa-trash" aria-hidden="true"></i></button>
                    </div>
                    <div data-editor-items>${items.map((item, itemIndex) => editorItemMarkup(item, itemIndex)).join('')}</div>
                    <div class="editor-add-row"><button class="button" type="button" data-editor-action="add-item"><i class="fas fa-plus" aria-hidden="true"></i> Add Question</button></div>
                </section>`;
            }

            function newEditorKey(prefix) {
                return `${prefix}-${Date.now()}-${++editorKeySequence}`;
            }

            function editorOptions(name, selected, placeholder) {
                const options = template.editor_options[name] || [];
                return `<option value="">${escapeHTML(placeholder)}</option>` + options.map((option) =>
                    `<option value="${escapeHTML(option.value)}"${option.value === selected ? ' selected' : ''}>${escapeHTML(option.label)}</option>`
                ).join('');
            }

            function normalizeUserFilterKey(value) {
                const u = String(value ?? '').toUpperCase().trim();
                if (!u) return 'UNASSIGNED';
                if (u.includes('CE')) return 'CE SERVICE';
                if (u.includes('WORKSHOP') || u.includes('WS')) return 'WORKSHOP SUP';
                if (u.includes('ASM') || u.includes('AFTERSALES')) return 'ASM';
                if (u.includes('PARTS')) return 'PARTS';
                if (u.includes('JC') || u.includes('JOB CONTROLLER')) return 'JC';
                if (u.includes('GM')) return 'GM';
                return u;
            }

            function editorItemMarkup(item = {}, itemIndex = 0) {
                const options = template.editor_options;
                const responsible = item.responsible_role || options.default_responsible_role || '';
                const hasLevels = (options.levels || []).length > 0;
                const checker = resolveItemChecker(item);
                const userRole = checker || responsible || '';
                const normalizedUser = normalizeUserFilterKey(userRole);
                let badgeClass = '';
                if (normalizedUser === 'CE SERVICE') badgeClass = 'is-ce';
                else if (normalizedUser === 'WORKSHOP SUP') badgeClass = 'is-ws';
                else if (normalizedUser === 'ASM') badgeClass = 'is-asm';
                else if (normalizedUser === 'PARTS') badgeClass = 'is-parts';
                else if (normalizedUser === 'JC') badgeClass = 'is-jc';
                else if (normalizedUser === 'GM') badgeClass = 'is-gm';

                return `<div class="editor-item" data-id="${escapeHTML(item.id ?? '')}" data-key="${escapeHTML(item.key ?? newEditorKey('item'))}" data-user="${escapeHTML(normalizedUser)}" data-checker="${escapeHTML(checker)}" data-responsible="${escapeHTML(responsible)}">
                    <div class="editor-item-head">
                        <button class="editor-drag-handle" type="button" data-editor-drag="item" aria-label="Move question" aria-describedby="editorOrderHelp"><i class="fas fa-grip-vertical" aria-hidden="true"></i></button>
                        <strong class="editor-question-number">Question <span data-editor-number>${itemIndex + 1}</span></strong>
                        ${userRole ? `<span class="editor-item-user-badge ${badgeClass}" title="User / Auditor: ${escapeHTML(userRole)}"><i class="fas fa-user-check"></i> ${escapeHTML(userRole)}</span>` : ''}
                        <label class="editor-active-toggle" style="margin-left:auto;margin-right:10px;display:inline-flex;align-items:center;gap:6px;font-size:11px;font-weight:700;color:var(--slate-600);cursor:pointer;" title="Uncheck to exclude this question from user checklists">
                            <input type="checkbox" data-editor-field="is_active" ${item.is_active !== false ? 'checked' : ''} style="width:15px;height:15px;accent-color:var(--gateway-red-500);cursor:pointer;">
                            <span>Include in checklist</span>
                        </label>
                        <button class="button danger editor-remove" type="button" data-editor-action="remove-item" aria-label="Remove question" title="Remove question"><i class="fas fa-trash" aria-hidden="true"></i></button>
                    </div>
                    <div class="editor-item-fields">
                        <label class="field wide"><span>Question <span aria-hidden="true">*</span></span><textarea class="edit-textarea" data-editor-field="label" placeholder="Enter the checklist question" required>${escapeHTML(item.label ?? '')}</textarea></label>
                        <label class="field wide"><span>Description</span><textarea class="edit-textarea" data-editor-field="description" placeholder="Add details or the standard to meet">${escapeHTML(item.description ?? '')}</textarea></label>
                        <label class="field"><span>Responsible <span aria-hidden="true">*</span></span><select class="edit-select" data-editor-field="responsible_role" required>${editorOptions('responsible_roles', responsible, 'Select responsible role')}</select></label>
                        <label class="field"><span>Level${options.level_required ? ' <span aria-hidden="true">*</span>' : ''}</span><select class="edit-select" data-editor-field="level"${!hasLevels ? ' disabled' : ''}${hasLevels && options.level_required ? ' required' : ''}>${editorOptions('levels', item.level || '', hasLevels ? 'Select level' : 'Not used for this checklist')}</select></label>
                        <label class="field wide"><span>How to check</span><textarea class="edit-textarea editor-guidance" data-editor-field="how_to_check" placeholder="Explain how to inspect or answer this question.">${escapeHTML(item.how_to_check ?? '')}</textarea></label>
                    </div>
                </div>`;
            }

            function refreshEditorSequence(announce = false) {
                let number = 0;
                document.querySelectorAll('#editorSections > .editor-section').forEach((section, sectionIndex) => {
                    section.querySelector('[data-editor-section-number]').textContent = sectionIndex + 1;
                    section.querySelector('[data-editor-drag="section"]').setAttribute('aria-label', `Move section ${sectionIndex + 1}`);
                    section.querySelectorAll(':scope > [data-editor-items] > .editor-item').forEach((item) => {
                        item.querySelector('[data-editor-number]').textContent = ++number;
                        item.querySelector('[data-editor-drag="item"]').setAttribute('aria-label', `Move question ${number}`);
                        item.querySelector('[data-editor-action="remove-item"]').setAttribute('aria-label', `Remove question ${number}`);
                    });
                });
                if (announce) document.getElementById('editorOrderStatus').textContent = `Sequence updated. ${number} questions. Save the master checklist to apply your changes.`;
                editorSorter?.refresh();
            }

            function getEditorActiveTemplate() {
                if (activeEditorScope === 'subform') return subformTemplate;
                if (activeEditorScope === 'documentation') return documentationTemplate;
                return template;
            }

            function getEditorActiveEndpoint() {
                if (activeEditorScope === 'subform') return endpoints.subformTemplate;
                if (activeEditorScope === 'documentation') return endpoints.documentationTemplate;
                return endpoints.template;
            }

            function renderEditorUserFilterPills() {
                const pillsContainer = document.getElementById('editorCheckerPills');
                if (!pillsContainer) return;
                const targetTemplate = getEditorActiveTemplate();
                if (!targetTemplate) return;

                const allItems = (targetTemplate.sections || []).flatMap((s) => s.items || []);
                const totalCount = allItems.length;

                const userCounts = {};
                allItems.forEach((item) => {
                    const u = resolveItemChecker(item) || item.responsible_role || 'Unassigned';
                    const uKey = normalizeUserFilterKey(u);
                    userCounts[uKey] = (userCounts[uKey] || 0) + 1;
                });

                const roleOrder = ['ASM', 'WORKSHOP SUP', 'CE SERVICE', 'PARTS', 'JC', 'GM'];
                const foundKeys = Object.keys(userCounts);
                const sortedRoles = [
                    ...roleOrder.filter((r) => foundKeys.includes(r)),
                    ...foundKeys.filter((k) => !roleOrder.includes(k)),
                ];

                let pillsHtml = `
                    <button type="button" class="editor-checker-pill ${activeEditorUserFilter === 'all' ? 'is-active' : ''}" data-editor-user="all">
                        <i class="fas fa-list-check"></i> All (${totalCount})
                    </button>
                `;

                sortedRoles.forEach((roleKey) => {
                    const count = userCounts[roleKey] || 0;
                    const isActive = activeEditorUserFilter.toUpperCase() === roleKey.toUpperCase();
                    pillsHtml += `
                        <button type="button" class="editor-checker-pill ${isActive ? 'is-active' : ''}" data-editor-user="${escapeHTML(roleKey)}">
                            <i class="fas fa-user"></i> ${escapeHTML(roleKey)} (${count})
                        </button>
                    `;
                });

                pillsContainer.innerHTML = pillsHtml;
            }

            function filterEditorItems() {
                const sections = document.querySelectorAll('#editorSections > .editor-section');
                const query = (document.getElementById('editorItemSearch')?.value || '').toLowerCase().trim();
                const selectedUser = (activeEditorUserFilter || 'all').toUpperCase().trim();

                let totalVisible = 0;
                let totalItems = 0;

                sections.forEach((sec) => {
                    let sectionVisibleCount = 0;
                    const items = sec.querySelectorAll(':scope > [data-editor-items] > .editor-item');
                    items.forEach((itemEl) => {
                        totalItems++;
                        const itemUser = (itemEl.dataset.user || '').toUpperCase().trim();
                        const itemChecker = (itemEl.dataset.checker || '').toUpperCase().trim();
                        const itemResp = (itemEl.dataset.responsible || '').toUpperCase().trim();
                        const label = (itemEl.querySelector('[data-editor-field="label"]')?.value || '').toLowerCase();
                        const desc = (itemEl.querySelector('[data-editor-field="description"]')?.value || '').toLowerCase();
                        const num = (itemEl.querySelector('[data-editor-number]')?.textContent || '').trim();

                        let matchesUser = selectedUser === 'ALL';
                        if (!matchesUser) {
                            matchesUser = itemUser === selectedUser
                                || itemChecker.includes(selectedUser)
                                || itemResp.includes(selectedUser);
                        }

                        let matchesSearch = !query;
                        if (query) {
                            matchesSearch = label.includes(query) || desc.includes(query) || num === query;
                        }

                        const isVisible = matchesUser && matchesSearch;
                        itemEl.style.display = isVisible ? '' : 'none';
                        if (isVisible) {
                            sectionVisibleCount++;
                            totalVisible++;
                        }
                    });

                    sec.style.display = sectionVisibleCount > 0 ? '' : 'none';
                });

                const summaryEl = document.getElementById('editorFilterSummary');
                const countTextEl = document.getElementById('editorFilterCountText');
                if (summaryEl && countTextEl) {
                    const isFiltered = selectedUser !== 'ALL' || query !== '';
                    summaryEl.style.display = isFiltered ? 'flex' : 'none';
                    if (isFiltered) {
                        const userLabel = selectedUser !== 'ALL' ? `for ${selectedUser}` : '';
                        const queryLabel = query ? `matching "${query}"` : '';
                        countTextEl.textContent = `Showing ${totalVisible} of ${totalItems} questions ${userLabel} ${queryLabel}`.trim();
                    }
                }
            }

            function updateEditorScopeTabs() {
                const tabsContainer = document.getElementById('editorScopeTabs');
                if (!tabsContainer) return;
                const isDos = template.slug === 'dealer-operations-standards';
                if (!isDos) {
                    tabsContainer.style.display = 'none';
                    return;
                }
                tabsContainer.style.display = 'flex';
                const countMain = template.sections.flatMap((s) => s.items).length;
                const countSub = subformTemplate ? subformTemplate.sections.flatMap((s) => s.items).length : 39;
                const countDoc = documentationTemplate ? documentationTemplate.sections.flatMap((s) => s.items).length : 17;

                const countMainEl = document.getElementById('editorCountMain');
                const countSubEl = document.getElementById('editorCountSubform');
                const countDocEl = document.getElementById('editorCountDoc');
                if (countMainEl) countMainEl.textContent = countMain;
                if (countSubEl) countSubEl.textContent = countSub;
                if (countDocEl) countDocEl.textContent = countDoc;

                tabsContainer.querySelectorAll('.editor-scope-tab').forEach((tab) => {
                    tab.classList.toggle('is-active', tab.dataset.editorScope === activeEditorScope);
                });
            }

            function switchEditorScope(newScope) {
                activeEditorScope = newScope;
                activeEditorUserFilter = 'all';
                if (document.getElementById('editorItemSearch')) document.getElementById('editorItemSearch').value = '';
                updateEditorScopeTabs();
                const targetTemplate = getEditorActiveTemplate();
                if (!targetTemplate) {
                    showToast('Template not found', 'The requested template could not be found.', 'error');
                    return;
                }
                document.getElementById('editorName').value = targetTemplate.name || '';
                document.getElementById('editorShortName').value = targetTemplate.short_name || '';
                document.getElementById('editorDescription').value = targetTemplate.description || '';
                document.getElementById('editorInstructions').value = targetTemplate.instructions || '';
                document.getElementById('editorSections').innerHTML = (targetTemplate.sections || []).map(editorSectionMarkup).join('');
                document.getElementById('editorOrderStatus').textContent = '';
                renderEditorUserFilterPills();
                filterEditorItems();
                refreshEditorSequence();
            }

            function openTemplateEditor(initialScope = 'main') {
                const dialog = document.getElementById('templateEditor');
                if (!dialog) return;
                activeEditorScope = typeof initialScope === 'string' ? initialScope : 'main';
                activeEditorUserFilter = 'all';
                if (document.getElementById('editorItemSearch')) document.getElementById('editorItemSearch').value = '';
                updateEditorScopeTabs();
                const targetTemplate = getEditorActiveTemplate();
                if (!targetTemplate) {
                    showToast('Template unavailable', 'Selected template could not be loaded.', 'error');
                    return;
                }
                document.getElementById('editorName').value = targetTemplate.name || '';
                document.getElementById('editorShortName').value = targetTemplate.short_name || '';
                document.getElementById('editorDescription').value = targetTemplate.description || '';
                document.getElementById('editorInstructions').value = targetTemplate.instructions || '';
                document.getElementById('editorSections').innerHTML = (targetTemplate.sections || []).map(editorSectionMarkup).join('');
                document.getElementById('editorOrderStatus').textContent = '';
                renderEditorUserFilterPills();
                filterEditorItems();
                if (!editorSorter && window.ChecklistEditorSort?.create) editorSorter = window.ChecklistEditorSort.create({
                    container: document.getElementById('editorSections'),
                    scrollContainer: dialog.querySelector('.template-editor-body'),
                    onReorder: () => refreshEditorSequence(true),
                });
                refreshEditorSequence();
                typeof dialog.showModal === 'function' ? dialog.showModal() : dialog.setAttribute('open', '');
            }

            function closeTemplateEditor() {
                const dialog = document.getElementById('templateEditor');
                if (!dialog) return;
                activeEditorUserFilter = 'all';
                if (document.getElementById('editorItemSearch')) document.getElementById('editorItemSearch').value = '';
                typeof dialog.close === 'function' ? dialog.close() : dialog.removeAttribute('open');
            }

            function collectTemplateEditor() {
                let questionNumber = 0;
                const targetTemplate = getEditorActiveTemplate();
                const existingItems = new Map((targetTemplate.sections || []).flatMap((section) => section.items).map((item) => [item.key, item]));
                const sections = [...document.querySelectorAll('#editorSections .editor-section')].map((sectionElement, sectionIndex) => {
                    const existingSection = (targetTemplate.sections || []).find((section) => section.key === sectionElement.dataset.key);
                    const items = [...sectionElement.querySelectorAll(':scope > [data-editor-items] > .editor-item')].map((itemElement, itemIndex) => {
                        const field = (name) => itemElement.querySelector(`[data-editor-field="${name}"]`).value.trim();
                        const id = itemElement.dataset.id || null;
                        const key = itemElement.dataset.key || `item-${sectionIndex + 1}-${itemIndex + 1}`;
                        const existingItem = existingItems.get(key);
                        const label = field('label');
                        const description = field('description');
                        const number = ++questionNumber;
                        const isActiveInput = itemElement.querySelector('[data-editor-field="is_active"]');
                        const isActive = isActiveInput ? isActiveInput.checked : (existingItem?.is_active !== undefined ? existingItem.is_active : true);
                        return {
                            id,
                            key,
                            code: String(number),
                            label,
                            prompt: description || label,
                            description,
                            level: field('level'),
                            responsible_role: field('responsible_role'),
                            how_to_check: field('how_to_check'),
                            is_active: isActive,
                            metadata: {
                                ...(existingItem?.metadata || {}),
                                code: String(number),
                                number,
                                label,
                                subject: label,
                                description,
                                level: field('level'),
                                responsible_role: field('responsible_role'),
                                pic: field('responsible_role'),
                                how_to_check: field('how_to_check'),
                            },
                        };
                    });
                    return {
                        id: sectionElement.dataset.id || null,
                        key: sectionElement.dataset.key || `section-${sectionIndex + 1}`,
                        title: sectionElement.querySelector('[data-editor-field="title"]').value.trim(),
                        metadata: { ...(existingSection?.metadata || {}) },
                        items,
                    };
                });
                return {
                    id: targetTemplate.id,
                    slug: targetTemplate.slug,
                    name: document.getElementById('editorName').value.trim(),
                    short_name: document.getElementById('editorShortName').value.trim(),
                    description: document.getElementById('editorDescription').value.trim(),
                    instructions: document.getElementById('editorInstructions').value.trim(),
                    time_slots: targetTemplate.time_slots,
                    settings: {
                        ...targetTemplate.settings,
                        short_name: document.getElementById('editorShortName').value.trim(),
                        instructions: document.getElementById('editorInstructions').value.trim(),
                        time_slots: targetTemplate.time_slots,
                    },
                    sections,
                };
            }

            async function saveTemplate() {
                const form = document.getElementById('templateEditorForm');
                if (!form.reportValidity()) return;
                const payload = collectTemplateEditor();
                if (!payload.name || !payload.sections.length || payload.sections.some((section) => !section.title || !section.items.length || section.items.some((item) => !item.label))) {
                    showToast('Template incomplete', 'Add at least one question to every section, and give each section and question a name.', 'error');
                    return;
                }
                const button = document.getElementById('saveTemplateButton');
                const preservedSubmission = { ...(currentSubmission || {}), responses: responseMapFromArray(collectResponses()) };
                setBusy(button, true, 'Saving…');
                const endpoint = getEditorActiveEndpoint();
                try {
                    const data = await apiRequest(endpoint, { method: 'PUT', body: JSON.stringify(payload) });
                    const saved = normalizeTemplate(data?.template ?? payload);
                    if (activeEditorScope === 'main') {
                        template = saved;
                        syncTemplateHeadings();
                    } else if (activeEditorScope === 'subform') {
                        subformTemplate = saved;
                    } else if (activeEditorScope === 'documentation') {
                        documentationTemplate = saved;
                    }
                    currentSubmission = preservedSubmission;
                    renderChecklist(currentSubmission);
                    updateEditorScopeTabs();
                    closeTemplateEditor();
                    setRecordStatus(currentSubmission.status);
                    const scopeLabel = activeEditorScope === 'subform' ? 'DOS Subform standards' : (activeEditorScope === 'documentation' ? 'DOS Documentation standards' : 'Master checklist');
                    showToast(`${scopeLabel} saved`, 'The database template has been updated.', 'success');
                } catch (error) {
                    showToast('Unable to save template', error.message, 'error');
                } finally {
                    setBusy(button, false);
                }
            }

            container.addEventListener('input', (event) => {
                if (event.target.matches('.doc-meta-input')) {
                    const input = event.target;
                    const itemKey = input.dataset.itemKey;
                    const sampleIndex = parseInt(input.dataset.sampleIndex, 10);
                    const field = input.dataset.field;
                    if (documentationState[itemKey]?.samples?.[sampleIndex] && field) {
                        documentationState[itemKey].samples[sampleIndex][field] = input.value;
                    }
                    return;
                }
                updateSummary();
            });
            container.addEventListener('change', async (event) => {
                if (event.target.matches('.doc-meta-input')) {
                    const input = event.target;
                    const itemKey = input.dataset.itemKey;
                    const sampleIndex = parseInt(input.dataset.sampleIndex, 10);
                    const field = input.dataset.field;
                    if (documentationState[itemKey]?.samples?.[sampleIndex] && field) {
                        documentationState[itemKey].samples[sampleIndex][field] = input.value;
                    }
                    return;
                }

                if (event.target.matches('.restroom-slot-toggle')) {
                    const checkbox = event.target;
                    const itemKey = checkbox.dataset.itemKey;
                    const slot = checkbox.dataset.slot;
                    const isChecked = checkbox.checked;
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);

                    checkbox.disabled = true;
                    if (item) {
                        if (!item.active_slots) {
                            item.active_slots = template.time_slots.map((s) => s.key);
                        }
                        if (isChecked) {
                            if (!item.active_slots.includes(slot)) {
                                item.active_slots.push(slot);
                            }
                        } else {
                            item.active_slots = item.active_slots.filter((s) => s !== slot);
                        }
                        item.is_active = item.active_slots.length > 0;
                    }

                    try {
                        if (!endpoints.toggleItem) throw new Error('Toggle item endpoint is not available.');
                        const data = await apiRequest(endpoints.toggleItem, {
                            method: 'POST',
                            body: JSON.stringify({ key: itemKey, slot: slot, is_active: isChecked }),
                        });
                        showToast(
                            isChecked ? 'Hour enabled' : 'Hour turned off',
                            data?.message || (isChecked ? `Question enabled for ${slot}.` : `Question turned off for ${slot}.`),
                            'success'
                        );
                    } catch (error) {
                        checkbox.checked = !isChecked;
                        if (item) {
                            if (!isChecked) {
                                if (!item.active_slots.includes(slot)) item.active_slots.push(slot);
                            } else {
                                item.active_slots = item.active_slots.filter((s) => s !== slot);
                            }
                            item.is_active = item.active_slots.length > 0;
                        }
                        showToast('Unable to update slot', error.message || 'Failed to update question slot setting.', 'error');
                    } finally {
                        checkbox.disabled = false;
                    }
                    return;
                }

                if (event.target.matches('.restroom-item-toggle')) {
                    const checkbox = event.target;
                    const itemKey = checkbox.dataset.itemKey;
                    const isChecked = checkbox.checked;
                    const row = checkbox.closest('tr[data-item-key]');
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);

                    checkbox.disabled = true;
                    if (item) item.is_active = isChecked;
                    if (row) {
                        row.classList.toggle('item-row-excluded', !isChecked);
                        const text = row.querySelector('.item-text');
                        text?.classList.toggle('item-text-excluded', !isChecked);
                        const existingTag = row.querySelector('.item-excluded-tag');
                        if (!isChecked && !existingTag && text) {
                            text.insertAdjacentHTML('afterend', '<span class="item-excluded-tag"><i class="fas fa-eye-slash" aria-hidden="true"></i> Excluded from user</span>');
                        } else if (isChecked && existingTag) {
                            existingTag.remove();
                        }
                    }

                    try {
                        if (!endpoints.toggleItem) throw new Error('Toggle item endpoint is not available.');
                        const data = await apiRequest(endpoints.toggleItem, {
                            method: 'POST',
                            body: JSON.stringify({ key: itemKey, is_active: isChecked }),
                        });
                        showToast(
                            isChecked ? 'Question included' : 'Question excluded',
                            data?.message || (isChecked ? 'Question will appear for the user.' : 'Question will not appear for the user.'),
                            'success'
                        );
                    } catch (error) {
                        checkbox.checked = !isChecked;
                        if (item) item.is_active = !isChecked;
                        if (row) {
                            row.classList.toggle('item-row-excluded', isChecked);
                            const text = row.querySelector('.item-text');
                            text?.classList.toggle('item-text-excluded', isChecked);
                            const existingTag = row.querySelector('.item-excluded-tag');
                            if (isChecked && !existingTag && text) {
                                text.insertAdjacentHTML('afterend', '<span class="item-excluded-tag"><i class="fas fa-eye-slash" aria-hidden="true"></i> Excluded from user</span>');
                            } else if (!isChecked && existingTag) {
                                existingTag.remove();
                            }
                        }
                        showToast('Unable to update question', error.message, 'error');
                    } finally {
                        checkbox.disabled = false;
                    }
                    return;
                }

                if (event.target.matches('[data-action="change-subform-select"]')) {
                    const select = event.target;
                    const itemKey = select.dataset.itemKey;
                    const idx = parseInt(select.value, 10);
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    const subformSection = getSubformSection(item);
                    if (subformState[itemKey] && !isNaN(idx)) {
                        subformState[itemKey].activeIndex = idx;
                        renderSubformBox(row, item, subformSection);
                    }
                    return;
                }

                if (event.target.matches('.slot-select')) paintSlotSelects();
                updateSummary();
            });
            container.addEventListener('click', (event) => {
                // Quick edit subform / documentation buttons
                if (event.target.closest('[data-action="open-editor-subform"]')) {
                    openTemplateEditor('subform');
                    return;
                }
                if (event.target.closest('[data-action="open-editor-documentation"]')) {
                    openTemplateEditor('documentation');
                    return;
                }

                // Documentation Sample selection tab
                const docSampleTab = event.target.closest('[data-action="select-doc-sample"]');
                if (docSampleTab) {
                    const itemKey = docSampleTab.dataset.itemKey;
                    const sampleIndex = parseInt(docSampleTab.dataset.sampleIndex, 10);
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    if (!documentationState[itemKey]) {
                        documentationState[itemKey] = {
                            activeSampleIndex: 0,
                            viewMode: 'tabs',
                            samples: [
                                { ro_number: '', job_type: '', answers: {} },
                                { ro_number: '', job_type: '', answers: {} },
                                { ro_number: '', job_type: '', answers: {} },
                            ],
                        };
                    }
                    documentationState[itemKey].activeSampleIndex = sampleIndex;
                    renderDocumentationBox(row, item);
                    return;
                }

                // Documentation Item answer button (YES/NO/N/A)
                const docAnsBtn = event.target.closest('[data-action="answer-doc-item"]');
                if (docAnsBtn) {
                    const itemKey = docAnsBtn.dataset.itemKey;
                    const sampleIdx = parseInt(docAnsBtn.dataset.sampleIndex, 10);
                    const docItemId = docAnsBtn.dataset.docitemId;
                    const val = docAnsBtn.dataset.value;
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);

                    if (!documentationState[itemKey]) {
                        documentationState[itemKey] = {
                            activeSampleIndex: sampleIdx,
                            viewMode: 'tabs',
                            samples: [
                                { ro_number: '', job_type: '', answers: {} },
                                { ro_number: '', job_type: '', answers: {} },
                                { ro_number: '', job_type: '', answers: {} },
                            ],
                        };
                    }
                    if (!documentationState[itemKey].samples[sampleIdx]) {
                        documentationState[itemKey].samples[sampleIdx] = { ro_number: '', job_type: '', answers: {} };
                    }
                    const sampleAnswers = asObject(documentationState[itemKey].samples[sampleIdx].answers);
                    if (sampleAnswers[docItemId] === val) {
                        delete sampleAnswers[docItemId];
                    } else {
                        sampleAnswers[docItemId] = val;
                    }
                    documentationState[itemKey].samples[sampleIdx].answers = sampleAnswers;

                    renderDocumentationBox(row, item);
                    updateSummary();
                    return;
                }

                // Documentation View mode toggle (tabs vs all)
                const docViewBtn = event.target.closest('[data-action="toggle-doc-view"]');
                if (docViewBtn) {
                    const itemKey = docViewBtn.dataset.itemKey;
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    if (!documentationState[itemKey]) {
                        documentationState[itemKey] = {
                            activeSampleIndex: 0,
                            viewMode: 'tabs',
                            samples: [
                                { ro_number: '', job_type: '', answers: {} },
                                { ro_number: '', job_type: '', answers: {} },
                                { ro_number: '', job_type: '', answers: {} },
                            ],
                        };
                    }
                    documentationState[itemKey].viewMode = documentationState[itemKey].viewMode === 'all' ? 'tabs' : 'all';
                    renderDocumentationBox(row, item);
                    return;
                }

                const eligBtn = event.target.closest('[data-action="set-eligibility"]');
                if (eligBtn) {
                    const itemKey = eligBtn.dataset.itemKey;
                    const targetEligibility = eligBtn.dataset.eligibility;
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    const subformSection = getSubformSection(item);
                    if (!subformState[itemKey]) {
                        subformState[itemKey] = { eligibility: null, answers: {}, activeIndex: 0, viewMode: 'dropdown' };
                    }
                    if (subformState[itemKey].eligibility === targetEligibility) {
                        subformState[itemKey].eligibility = null;
                    } else {
                        subformState[itemKey].eligibility = targetEligibility;
                    }
                    renderSubformBox(row, item, subformSection);
                    updateSummary();
                    return;
                }

                const ansBtn = event.target.closest('[data-action="answer-sub-item"]');
                if (ansBtn) {
                    const itemKey = ansBtn.dataset.itemKey;
                    const subitemId = ansBtn.dataset.subitemId;
                    const val = ansBtn.dataset.value;
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    const subformSection = getSubformSection(item);
                    if (!subformState[itemKey]) {
                        subformState[itemKey] = { eligibility: 'show_subform', answers: {}, activeIndex: 0, viewMode: 'dropdown' };
                    }
                    if (subformState[itemKey].answers[subitemId] === val) {
                        delete subformState[itemKey].answers[subitemId];
                    } else {
                        subformState[itemKey].answers[subitemId] = val;
                    }
                    renderSubformBox(row, item, subformSection);
                    updateSummary();
                    return;
                }

                const viewBtn = event.target.closest('[data-action="toggle-subform-view"]');
                if (viewBtn) {
                    const itemKey = viewBtn.dataset.itemKey;
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    const subformSection = getSubformSection(item);
                    if (subformState[itemKey]) {
                        subformState[itemKey].viewMode = subformState[itemKey].viewMode === 'all' ? 'dropdown' : 'all';
                        renderSubformBox(row, item, subformSection);
                    }
                    return;
                }

                const navBtn = event.target.closest('[data-action="nav-subform"]');
                if (navBtn) {
                    const itemKey = navBtn.dataset.itemKey;
                    const dir = navBtn.dataset.dir;
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    const subformSection = getSubformSection(item);
                    const totalItems = subformSection?.items?.length || 1;
                    if (subformState[itemKey]) {
                        if (dir === 'prev') subformState[itemKey].activeIndex = Math.max(0, subformState[itemKey].activeIndex - 1);
                        if (dir === 'next') subformState[itemKey].activeIndex = Math.min(totalItems - 1, subformState[itemKey].activeIndex + 1);
                        renderSubformBox(row, item, subformSection);
                    }
                    return;
                }

                const pillBtn = event.target.closest('[data-action="nav-subform-index"]');
                if (pillBtn) {
                    const itemKey = pillBtn.dataset.itemKey;
                    const idx = parseInt(pillBtn.dataset.index, 10);
                    const row = container.querySelector(`.item-row[data-item-key="${itemKey}"]`);
                    const item = template.sections.flatMap((s) => s.items).find((i) => i.key === itemKey);
                    const subformSection = getSubformSection(item);
                    if (subformState[itemKey] && !isNaN(idx)) {
                        subformState[itemKey].activeIndex = idx;
                        renderSubformBox(row, item, subformSection);
                    }
                    return;
                }

                const trigger = event.target.closest('[data-action="show-how-to-check"]');
                if (trigger) openHowToCheck(trigger);
            });
            document.getElementById('closeHowToCheck')?.addEventListener('click', closeHowToCheck);
            document.getElementById('dismissHowToCheck')?.addEventListener('click', closeHowToCheck);
            document.getElementById('howToCheckDialog')?.addEventListener('close', () => {
                howToCheckReturnFocus?.focus();
                howToCheckReturnFocus = null;
            });
            document.getElementById('searchInput')?.addEventListener('input', filterItems);
            document.getElementById('sectionFilter')?.addEventListener('change', filterItems);
            document.getElementById('levelFilter')?.addEventListener('change', filterItems);
            branchSelect.addEventListener('change', () => loadSubmission());
            auditDate.addEventListener('change', () => loadSubmission());
            document.getElementById('saveDraftButton').addEventListener('click', (event) => save('draft', event.currentTarget));
            document.getElementById('submitButton').addEventListener('click', (event) => save('submitted', event.currentTarget));
            document.getElementById('footerSubmitButton').addEventListener('click', (event) => save('submitted', event.currentTarget));
            document.getElementById('resetResponsesButton').addEventListener('click', resetSubmission);
            document.getElementById('printButton').addEventListener('click', () => window.print());
            document.getElementById('scrollTopButton').addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));

            document.querySelectorAll('.checker-pill-btn').forEach((btn) => {
                btn.addEventListener('click', () => {
                    const filter = btn.dataset.checkerFilter;
                    const isCurrentlyActive = btn.classList.contains('is-active') && filter !== 'all';
                    document.querySelectorAll('.checker-pill-btn').forEach((b) => b.classList.remove('is-active'));
                    if (isCurrentlyActive) {
                        activeUserFilter = null;
                        document.querySelector('.checker-filter-bar .checker-pill-btn')?.classList.add('is-active');
                    } else {
                        btn.classList.add('is-active');
                        activeUserFilter = (filter === 'all' || !filter) ? null : filter;
                    }
                    filterItems();
                });
            });

            const createDialog = document.getElementById('createTemplateDialog');
            document.getElementById('createTemplateButton')?.addEventListener('click', () => {
                if (createDialog) {
                    document.getElementById('newTemplateName').value = '';
                    document.getElementById('newTemplateSlug').value = '';
                    document.getElementById('newTemplateDescription').value = '';
                    document.getElementById('newTemplateInstructions').value = '';
                    document.getElementById('newTemplateVariant').value = 'dos';
                    document.getElementById('newTemplateClone').value = '';
                    typeof createDialog.showModal === 'function' ? createDialog.showModal() : createDialog.setAttribute('open', '');
                }
            });
            const closeCreateDialog = () => {
                if (createDialog) {
                    typeof createDialog.close === 'function' ? createDialog.close() : createDialog.removeAttribute('open');
                }
            };
            document.getElementById('closeCreateTemplate')?.addEventListener('click', closeCreateDialog);
            document.getElementById('cancelCreateTemplate')?.addEventListener('click', closeCreateDialog);

            document.getElementById('newTemplateName')?.addEventListener('input', (e) => {
                const slugInput = document.getElementById('newTemplateSlug');
                if (slugInput && !slugInput.dataset.touched) {
                    slugInput.value = slug(e.target.value, '');
                }
            });
            document.getElementById('newTemplateSlug')?.addEventListener('input', () => {
                document.getElementById('newTemplateSlug').dataset.touched = 'true';
            });

            document.getElementById('saveNewTemplateButton')?.addEventListener('click', async (e) => {
                const name = document.getElementById('newTemplateName').value.trim();
                const tSlug = document.getElementById('newTemplateSlug').value.trim();
                const description = document.getElementById('newTemplateDescription').value.trim();
                const instructions = document.getElementById('newTemplateInstructions').value.trim();
                const tVariant = document.getElementById('newTemplateVariant').value;
                const cloneFrom = document.getElementById('newTemplateClone').value;

                if (!name || !tSlug) {
                    showToast('Required fields missing', 'Please provide a checklist name and slug identifier.', 'error');
                    return;
                }

                const btn = e.currentTarget;
                setBusy(btn, true, 'Creating template…');
                try {
                    const targetUrl = endpoints.createTemplate || '/checklists/templates';
                    const data = await apiRequest(targetUrl, {
                        method: 'POST',
                        body: JSON.stringify({
                            name,
                            slug: tSlug,
                            description,
                            instructions,
                            variant: tVariant,
                            clone_from: cloneFrom || null,
                        }),
                    });
                    showToast('Checklist created', data?.message || 'New master checklist created successfully.', 'success');
                    closeCreateDialog();
                    window.setTimeout(() => {
                        const redirectSlug = data?.template?.slug || tSlug;
                        window.location.href = `/checklists?checklist=${encodeURIComponent(redirectSlug)}`;
                    }, 600);
                } catch (err) {
                    showToast('Unable to create template', err.message || 'Failed to create new checklist template.', 'error');
                } finally {
                    setBusy(btn, false);
                }
            });

            document.getElementById('editorScopeTabs')?.addEventListener('click', (e) => {
                const tab = e.target.closest('.editor-scope-tab');
                if (tab && tab.dataset.editorScope) {
                    switchEditorScope(tab.dataset.editorScope);
                }
            });

            document.getElementById('editorCheckerPills')?.addEventListener('click', (event) => {
                const pill = event.target.closest('.editor-checker-pill');
                if (!pill) return;
                activeEditorUserFilter = pill.dataset.editorUser || 'all';
                document.querySelectorAll('.editor-checker-pill').forEach((p) => {
                    p.classList.toggle('is-active', p === pill);
                });
                filterEditorItems();
            });

            document.getElementById('editorItemSearch')?.addEventListener('input', () => {
                filterEditorItems();
            });

            document.getElementById('editorFilterResetBtn')?.addEventListener('click', () => {
                activeEditorUserFilter = 'all';
                const search = document.getElementById('editorItemSearch');
                if (search) search.value = '';
                document.querySelectorAll('.editor-checker-pill').forEach((p) => {
                    p.classList.toggle('is-active', p.dataset.editorUser === 'all');
                });
                filterEditorItems();
            });

            document.getElementById('editTemplateButton')?.addEventListener('click', openTemplateEditor);
            document.getElementById('archiveTemplateButton')?.addEventListener('click', async (event) => {
                if (!endpoints.deleteTemplate) return;
                if (!window.confirm(`Delete "${template.name}" from active use? It will be hidden, while its audit history remains available to the administrator.`)) return;

                const button = event.currentTarget;
                setBusy(button, true, 'Deleting...');
                try {
                    const data = await apiRequest(endpoints.deleteTemplate, { method: 'DELETE' });
                    showToast('Audit form deleted', data?.message || 'The audit form was removed from active use.', 'success');
                    window.setTimeout(() => {
                        window.location.href = data?.redirect_url || '/checklists';
                    }, 500);
                } catch (error) {
                    showToast('Unable to archive audit form', error.message || 'The audit form could not be archived.', 'error');
                    setBusy(button, false);
                }
            });
            document.getElementById('closeTemplateEditor')?.addEventListener('click', closeTemplateEditor);
            document.getElementById('cancelTemplateEditor')?.addEventListener('click', closeTemplateEditor);
            document.getElementById('addEditorSection')?.addEventListener('click', () => {
                document.getElementById('editorSections').insertAdjacentHTML('beforeend', editorSectionMarkup({}, document.querySelectorAll('.editor-section').length));
                refreshEditorSequence(true);
            });
            document.getElementById('editorSections')?.addEventListener('click', (event) => {
                const action = event.target.closest('[data-editor-action]');
                if (!action) return;
                if (action.dataset.editorAction === 'remove-section') action.closest('.editor-section').remove();
                if (action.dataset.editorAction === 'remove-item') action.closest('.editor-item').remove();
                if (action.dataset.editorAction === 'add-item') {
                    const items = action.closest('.editor-section').querySelector('[data-editor-items]');
                    items.insertAdjacentHTML('beforeend', editorItemMarkup({}, items.children.length));
                    items.lastElementChild.querySelector('[data-editor-field="label"]').focus();
                }
                refreshEditorSequence(true);
            });
            document.getElementById('saveTemplateButton')?.addEventListener('click', saveTemplate);

            const sidebar = document.getElementById('sidebar');
            const mainShell = document.querySelector('.main-shell');
            const sidebarToggle = document.getElementById('sidebarToggle');
            const mobileMenuButton = document.getElementById('mobileMenuButton');
            const sidebarBackdrop = document.getElementById('sidebarBackdrop');

            const setDesktopSidebarCollapsed = (collapsed) => {
                if (!sidebar || !mainShell || !sidebarToggle) return;

                sidebar.classList.toggle('desktop-collapsed', collapsed);
                mainShell.classList.toggle('sidebar-collapsed', collapsed);
                sidebarToggle.classList.toggle('is-active', collapsed);
                sidebarToggle.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
                sidebarToggle.setAttribute('aria-label', collapsed ? 'Expand navigation' : 'Collapse navigation');
                const icon = sidebarToggle.querySelector('i');
                if (icon) icon.className = collapsed ? 'fas fa-angles-right' : 'fas fa-angles-left';
                localStorage.setItem('gatewaySidebarCollapsed', collapsed ? '1' : '0');
            };

            sidebarToggle?.addEventListener('click', () => {
                setDesktopSidebarCollapsed(!sidebar?.classList.contains('desktop-collapsed'));
            });

            const closeMobileSidebar = () => {
                sidebar?.classList.remove('open', 'mobile-open');
                sidebarBackdrop?.classList.remove('open');
            };
            mobileMenuButton?.addEventListener('click', () => {
                sidebar?.classList.add('open', 'mobile-open');
                sidebarBackdrop?.classList.add('open');
            });
            sidebarBackdrop?.addEventListener('click', closeMobileSidebar);

            if (localStorage.getItem('gatewaySidebarCollapsed') === '1' && window.innerWidth > 900) {
                setDesktopSidebarCollapsed(true);
            }

            renderChecklist(initialSubmission);
            setRecordStatus(initialSubmission?.status);
            if (endpoints.load) loadSubmission({ quiet: true });
            if (!endpoints.draft) document.getElementById('saveDraftButton').disabled = true;
            if (!endpoints.submit) {
                document.getElementById('submitButton').disabled = true;
                document.getElementById('footerSubmitButton').disabled = true;
            }
            if (!endpoints.reset) document.getElementById('resetResponsesButton').disabled = true;
            if (!endpoints.template) document.getElementById('editTemplateButton')?.setAttribute('disabled', 'disabled');
        })();
    </script>

    @if (!empty($subformDocData['has_submissions']))
        @include('dashboard.subform-doc-modal')
    @endif

    @include('partials.notifications-modal')
</body>
</html>
