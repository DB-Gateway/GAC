@php
    $sdPrint = $subformDocData ?? [];
    $hasSubformPrint = !empty($sdPrint['has_subform']);
    $hasDocPrint = !empty($sdPrint['has_documentation']);
    $subformPrint = $sdPrint['subform'] ?? [];
    $docPrint = $sdPrint['documentation'] ?? [];
    $subformSectionsPrint = $subformPrint['sections'] ?? [];
    $docSamplesPrint = $docPrint['samples'] ?? [];
    $docMatrixPrint = $docPrint['items_matrix'] ?? [];

    $printPercentFormatter = static function ($value): string {
        $number = round((float) $value, 1);
        return (fmod(abs($number), 1.0) < 0.05
            ? number_format($number, 0)
            : number_format($number, 1)) . '%';
    };
@endphp

<section class="workbook-print-sheet workbook-print-subform-doc"
         data-print-template="aftersales-subform-doc"
         aria-label="Aftersales Subform and Documentation print sheet">
    <header class="workbook-print-header">
        <img src="{{ asset('images/Gateway_logo_circle.png') }}"
             class="workbook-print-logo"
             alt="Gateway">
        <h1>AFTERSALES STANDARDS - SUBFORM &amp; DOCUMENTATION COMPLIANCE AUDIT FY2025</h1>

        <div class="workbook-print-meta">
            <span class="workbook-meta-spacer" aria-hidden="true"></span>
            <span class="workbook-meta-label">Dealer:</span>
            <span class="workbook-meta-value">{{ $summarySheet['dealer'] ?? 'Gateway Motors' }}</span>
            <span class="workbook-meta-label">Date:</span>
            <span class="workbook-meta-value is-input">{{ $sdPrint['audit_date'] ? \Carbon\Carbon::parse($sdPrint['audit_date'])->format('F j, Y') : ($summarySheet['date'] ?? now()->format('F j, Y')) }}</span>

            <span class="workbook-meta-spacer" aria-hidden="true"></span>
            <span class="workbook-meta-label">Outlet:</span>
            <span class="workbook-meta-value is-input">{{ $sdPrint['branch'] ?: ($summarySheet['outlet'] ?? '') }}</span>
            <span class="workbook-meta-label">Auditor:</span>
            <span class="workbook-meta-value is-input">{{ $sdPrint['auditor'] ?: ($summarySheet['auditor'] ?? 'Operational Checkers') }}</span>
        </div>
    </header>

    {{-- SECTION 1: SUBFORM COMPLIANCE SUMMARY --}}
    @if ($hasSubformPrint)
        <section class="workbook-print-block workbook-print-criteria" aria-labelledby="subformSummaryPrintTitle">
            <h2 id="subformSummaryPrintTitle">Subform Audit Score by Operational Area ({{ $subformPrint['total_items'] ?? 39 }} Standards)</h2>
            <table>
                <colgroup>
                    <col class="workbook-col-no" style="width: 6%;">
                    <col class="workbook-col-category" style="width: 48%;">
                    <col class="workbook-col-number" style="width: 11%;">
                    <col class="workbook-col-number" style="width: 11%;">
                    <col class="workbook-col-number" style="width: 12%;">
                    <col class="workbook-col-number" style="width: 12%;">
                </colgroup>
                <thead>
                    <tr>
                        <th>No.</th>
                        <th>Operational Area / Subform Section</th>
                        <th>Total</th>
                        <th>Score</th>
                        <th>% Score</th>
                        <th>Rating</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($subformSectionsPrint as $sIdx => $sec)
                        <tr data-print-criteria="{{ $sec['title'] }}">
                            <td>{{ $sIdx + 1 }}</td>
                            <td>{{ $sec['title'] }}</td>
                            <td>{{ $sec['total'] }}</td>
                            <td>{{ $sec['yes'] }}</td>
                            <td>{{ $sec['answered'] > 0 ? $printPercentFormatter($sec['score_percent']) : '—' }}</td>
                            <td class="workbook-rating-cell {{ $sec['answered'] > 0 ? ($sec['rating'] === 'PASS' ? 'is-pass' : 'is-fail') : '' }}">
                                {{ $sec['answered'] > 0 ? $sec['rating'] : 'N/A' }}
                            </td>
                        </tr>
                    @endforeach
                    <tr class="workbook-total-row">
                        <td colspan="2">SUBFORM TOTAL:</td>
                        <td>{{ $subformPrint['total_items'] ?? 39 }}</td>
                        <td>{{ $subformPrint['yes_count'] ?? 0 }}</td>
                        <td>{{ $printPercentFormatter($subformPrint['score_percent'] ?? 0) }}</td>
                        <td class="workbook-rating-cell {{ ($subformPrint['rating'] ?? '') === 'PASS' ? 'is-pass' : 'is-fail' }}">
                            {{ $subformPrint['rating'] ?? 'N/A' }}
                        </td>
                    </tr>
                </tbody>
            </table>
        </section>
    @endif

    {{-- SECTION 2: DOCUMENTATION MULTI-SAMPLE AUDIT --}}
    @if ($hasDocPrint && count($docSamplesPrint) > 0)
        <section class="workbook-print-block workbook-print-coverage" aria-labelledby="docSummaryPrintTitle" style="margin-top: 2.2mm;">
            <h2 id="docSummaryPrintTitle">Documentation Audit Multi-Sample Matrix ({{ count($docMatrixPrint) }} Standards &times; {{ count($docSamplesPrint) }} Samples)</h2>
            <table class="workbook-doc-print-table">
                <thead>
                    <tr>
                        <th style="width: 5%;">No.</th>
                        <th style="width: 47%;">Service Document Standard</th>
                        @foreach ($docSamplesPrint as $sIdx => $sData)
                            <th style="font-size: 6.8pt; line-height: 1.15; padding: 1.5mm 1mm;">
                                Sample {{ $sData['index'] }}<br>
                                <span style="font-weight: normal; font-size: 6.2pt;">
                                    {{ $sData['ro_number'] ?: 'RO-'.$sData['index'] }}
                                </span>
                            </th>
                        @endforeach
                    </tr>
                </thead>
                <tbody>
                    @foreach ($docMatrixPrint as $mRow)
                        <tr>
                            <td style="text-align: center;">{{ $mRow['number'] }}</td>
                            <td style="font-size: 6.8pt; line-height: 1.15;">
                                <strong>[{{ $mRow['section'] }}]</strong> {{ $mRow['prompt'] }}
                            </td>
                            @foreach ($docSamplesPrint as $sIdx => $sData)
                                @php
                                    $sVal = $mRow['samples'][$sIdx] ?? ($mRow['sample_'.($sIdx + 1)] ?? '-');
                                @endphp
                                <td style="text-align: center;" class="workbook-sample-cell {{ $sVal === 'yes' ? 'is-pass' : ($sVal === 'no' ? 'is-fail' : '') }}">
                                    {{ strtoupper($sVal) }}
                                </td>
                            @endforeach
                        </tr>
                    @endforeach
                    <tr class="workbook-total-row">
                        <td colspan="2">DOCUMENTATION AUDIT SCORE:</td>
                        @foreach ($docSamplesPrint as $sData)
                            <td style="text-align: center;" class="workbook-percent-cell {{ $sData['score_percent'] >= 80 ? 'is-pass' : 'is-fail' }}">
                                {{ $sData['yes'] }}/{{ $sData['total'] }} ({{ $printPercentFormatter($sData['score_percent']) }})
                            </td>
                        @endforeach
                    </tr>
                </tbody>
            </table>
        </section>
    @endif

    {{-- COMBINED SUBFORM & DOCUMENTATION SUMMARY ROW --}}
    <div class="workbook-print-combined-summary" style="margin-top: 2.2mm; border: 0.6pt solid #000; padding: 1.8mm 3mm; font-size: 7.2pt; display: flex; justify-content: space-between; align-items: center; background: #fafafa;">
        <div>
            <strong>Subform Compliance:</strong>
            @if ($hasSubformPrint)
                {{ $subformPrint['yes_count'] ?? 0 }}/{{ $subformPrint['total_items'] ?? 39 }} ({{ $printPercentFormatter($subformPrint['score_percent'] ?? 0) }}) - <span class="workbook-rating-cell {{ ($subformPrint['rating'] ?? '') === 'PASS' ? 'is-pass' : 'is-fail' }}" style="padding: 0.5mm 1.5mm; font-weight: bold;">{{ $subformPrint['rating'] ?? 'N/A' }}</span>
            @else
                <span class="text-muted">Not Recorded</span>
            @endif
        </div>
        <div>
            <strong>Documentation Compliance:</strong>
            @if ($hasDocPrint)
                {{ $docPrint['yes_count'] ?? 0 }}/{{ $docPrint['total_checks'] ?? 0 }} ({{ $printPercentFormatter($docPrint['score_percent'] ?? 0) }}) - <span class="workbook-rating-cell {{ ($docPrint['rating'] ?? '') === 'PASS' ? 'is-pass' : 'is-fail' }}" style="padding: 0.5mm 1.5mm; font-weight: bold;">{{ $docPrint['rating'] ?? 'N/A' }}</span>
            @else
                <span class="text-muted">Not Recorded</span>
            @endif
        </div>
    </div>

    {{-- FOOTER SIGNATURES MATCHING summary-print.blade.php --}}
    <footer class="workbook-print-signatures" style="margin-top: 3.5mm;">
        <section>
            <strong>Prepared by:</strong>
            <span>Auditor:</span>
        </section>
        <section>
            <strong>Approved by:</strong>
            <span>Service Manager:</span>
        </section>
        <section>
            <strong>Conforme:</strong>
            <span>Branch Head:</span>
        </section>
    </footer>
</section>
