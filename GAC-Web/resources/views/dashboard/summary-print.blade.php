@php
    $printIsAftersales = $activeForm === 'aftersales';
    $printIsFiveS = $activeForm === 'five_s';
    $printIsTimeSlots = $summarySheet['isTimeSlotChecklist'];
    $printTitle = $printIsFiveS
        ? $summarySheet['activeFormTitle']
        : ($printIsAftersales
            ? 'AFTERSALES STANDARDS COMPLIANCE AUDIT FORM FY2025'
            : 'SALES STANDARDS COMPLIANCE AUDIT FORM FY2025');
    $printCriteriaRows = collect($overallScores)->values();
    $canonicalPrintCoverages = $summarySheet['printCoverageOrder'];
    $normalizeCoverage = static fn ($value): string => mb_strtolower(
        \Illuminate\Support\Str::squish((string) $value)
    );
    $availablePrintCoverages = collect($coverageRows)
        ->values()
        ->map(fn (array $row): array => [...$row, '_has_score' => true])
        ->keyBy(fn (array $row): string => $normalizeCoverage($row['coverage']));
    $canonicalCoverageKeys = collect($canonicalPrintCoverages)
        ->map($normalizeCoverage);
    $printCoverageRows = collect($canonicalPrintCoverages)
        ->map(function (string $coverage, int $index) use ($availablePrintCoverages, $normalizeCoverage): array {
            $row = $availablePrintCoverages->get($normalizeCoverage($coverage));

            return $row
                ? [...$row, 'no' => $index + 1, 'coverage' => $coverage]
                : [
                    'no' => $index + 1,
                    'coverage' => $coverage,
                    'total' => null,
                    'score' => null,
                    'percent' => null,
                    '_has_score' => false,
                ];
        })
        ->concat(
            $availablePrintCoverages
                ->reject(fn (array $row, string $key): bool => $canonicalCoverageKeys->contains($key))
                ->values()
                ->map(fn (array $row, int $index): array => [
                    ...$row,
                    'no' => count($canonicalPrintCoverages) + $index + 1,
                ])
        )
        ->values();
    $printCoverageLabelLines = [
        'Customer Engagement and Showroom Operations' => ['Customer Engagement and Showroom', 'Operations'],
        'Menu Pricing / Commitment of Price and Time Delivery' => ['Menu Pricing / Commitment of Price and Time', 'Delivery'],
        'Repair Order Processing and Quality of Work' => ['Repair Order Processing and', 'Quality of Work'],
        'Repair Order Completion and Invoicing' => ['Repair Order Completion', 'and Invoicing'],
        'Customer Information and Car Return' => ['Customer Information', 'and Car Return'],
        'Concern Prevention and Resolution' => ['Concern Prevention', 'and Resolution'],
    ];
    $printPercent = static function ($value): string {
        $number = round((float) $value, 1);

        return (fmod(abs($number), 1.0) < 0.05
            ? number_format($number, 0)
            : number_format($number, 1)).'%';
    };

    $barPlot = ['x' => 54.0, 'y' => 12.0, 'width' => 430.0, 'height' => 210.0];
    $barCount = max(1, $printCriteriaRows->count());
    $barMinimum = ($printIsAftersales || $printIsFiveS) ? 0.0 : 80.0;
    $barRange = 100.0 - $barMinimum;
    $barTickStep = $barRange / 10;
    $printCoverageFillerCount = max(0, ($printIsAftersales ? 15 : ($printIsFiveS ? 7 : 13)) - $printCoverageRows->count());

    $radarCenterX = 202.5;
    $radarCenterY = 130.0;
    $radarRadius = 78.0;
    $radarLabelRadius = 112.0;
    $radarCount = max(1, $printCoverageRows->count());
    $radarPoint = static function (float $radius, int $index) use ($radarCenterX, $radarCenterY, $radarCount): array {
        $angle = deg2rad(-90 + (($index * 360) / $radarCount));

        return [
            $radarCenterX + cos($angle) * $radius,
            $radarCenterY + sin($angle) * $radius,
            cos($angle),
        ];
    };
    $radarRings = collect(range(1, 5))->map(function (int $ring) use ($radarCount, $radarRadius, $radarPoint): string {
        return collect(range(0, $radarCount - 1))
            ->map(function (int $index) use ($ring, $radarRadius, $radarPoint): string {
                [$x, $y] = $radarPoint($radarRadius * ($ring / 5), $index);

                return number_format($x, 2, '.', '').','.number_format($y, 2, '.', '');
            })
            ->implode(' ');
    });
    $radarScoredCoordinates = $printCoverageRows
        ->map(function (array $row, int $index) use ($radarRadius, $radarPoint): ?array {
            if (! $row['_has_score']) {
                return null;
            }

            $scoreRadius = $radarRadius * (min(100, max(0, (float) $row['percent'])) / 100);
            [$x, $y] = $radarPoint($scoreRadius, $index);

            return ['x' => $x, 'y' => $y];
        })
        ->filter()
        ->values();
    $radarScorePoints = $radarScoredCoordinates
        ->map(fn (array $point): string => number_format($point['x'], 2, '.', '').','.number_format($point['y'], 2, '.', ''))
        ->implode(' ');
    $wrapRadarLabel = static fn (string $label): array => explode("\n", wordwrap($label, 25, "\n", false));
@endphp

<section class="workbook-print-sheet {{ $printIsAftersales ? 'workbook-print-aftersales' : 'workbook-print-sales' }}"
         data-print-template="{{ $activeForm }}"
         data-print-scope="{{ $summaryMode }}"
         data-print-user-id="{{ $summarySheet['selectedUserId'] }}"
         data-print-overall-percent="{{ number_format((float) $overallSummary['percent'], 1, '.', '') }}"
         aria-label="{{ $printTitle }} print sheet">
    <header class="workbook-print-header">
        <img src="{{ asset('images/Gateway_logo_circle.png') }}"
             class="workbook-print-logo"
             alt="Gateway">
        <h1>{{ $printTitle }}</h1>

        <div class="workbook-print-meta">
            <span class="workbook-meta-spacer" aria-hidden="true"></span>
            <span class="workbook-meta-label">Dealer:</span>
            <span class="workbook-meta-value">{{ $summarySheet['dealer'] }}</span>
            <span class="workbook-meta-label">{{ $summarySheet['isStandardsChecklist'] ? 'Audit Month:' : 'Date:' }}</span>
            <span class="workbook-meta-value {{ $printIsAftersales ? 'is-input' : '' }}">{{ $summarySheet['date'] }}</span>

            <span class="workbook-meta-spacer" aria-hidden="true"></span>
            <span class="workbook-meta-label">Outlet:</span>
            <span class="workbook-meta-value {{ $printIsAftersales ? 'is-input' : '' }}">{{ $summarySheet['outlet'] }}</span>
            <span class="workbook-meta-label">Auditor:</span>
            <span class="workbook-meta-value {{ $printIsAftersales ? 'is-input' : '' }}">{{ $summarySheet['auditor'] }}</span>
        </div>
    </header>

    <section class="workbook-print-block workbook-print-criteria" aria-labelledby="workbookCriteriaTitle">
        <h2 id="workbookCriteriaTitle">Overall Audit Score</h2>
        <table>
            <colgroup>
                <col class="workbook-col-no">
                <col class="workbook-col-category">
                <col class="workbook-col-number">
                <col class="workbook-col-number">
                <col class="workbook-col-number">
                <col class="workbook-col-number">
                <col class="workbook-col-number">
            </colgroup>
            <thead>
                <tr>
                    <th>No.</th>
                    <th>Category</th>
                    <th>{{ $printIsTimeSlots ? 'Slots' : 'Total' }}</th>
                    <th>{{ $printIsTimeSlots ? 'Good' : 'Score' }}</th>
                    <th>N/A</th>
                    <th>% Score</th>
                    <th>Rating</th>
                </tr>
            </thead>
            <tbody>
                @foreach ($printCriteriaRows as $row)
                    <tr data-print-criteria="{{ $row['category'] }}"
                        data-print-percent="{{ number_format((float) $row['percent'], 1, '.', '') }}">
                        <td>{{ $row['no'] }}</td>
                        <td>{{ $row['category'] }}</td>
                        <td>{{ $row['total'] }}</td>
                        <td>{{ $row['score'] }}</td>
                        <td>{{ $row['na'] ?? 0 }}</td>
                        <td>{{ $printPercent($row['percent']) }}</td>
                        <td class="workbook-rating-cell {{ $row['rating'] === 'PASS' ? 'is-pass' : ($row['rating'] === 'FAIL' ? 'is-fail' : 'is-neutral') }}">
                            {{ in_array($row['rating'], ['PASS', 'FAIL'], true) ? $row['rating'] : '' }}
                        </td>
                    </tr>
                @endforeach
                <tr class="workbook-total-row">
                    <td colspan="2">TOTAL:</td>
                    <td>{{ $overallSummary['total'] }}</td>
                    <td>{{ $overallSummary['score'] }}</td>
                    <td>{{ $overallSummary['na'] ?? 0 }}</td>
                    <td>{{ $printPercent($overallSummary['percent']) }}</td>
                    <td class="workbook-rating-cell {{ $overallSummary['rating'] === 'PASS' ? 'is-pass' : ($overallSummary['rating'] === 'FAIL' ? 'is-fail' : 'is-neutral') }}">
                        {{ in_array($overallSummary['rating'], ['PASS', 'FAIL'], true) ? $overallSummary['rating'] : '' }}
                    </td>
                </tr>
            </tbody>
        </table>
    </section>

    <section class="workbook-print-block workbook-print-coverage" aria-labelledby="workbookCoverageTitle">
        <h2 id="workbookCoverageTitle">Compliance Per Category</h2>
        <table>
            <colgroup>
                <col class="workbook-col-no">
                <col class="workbook-col-category">
                <col class="workbook-col-number">
                <col class="workbook-col-number">
                <col class="workbook-col-number">
                <col class="workbook-col-double">
            </colgroup>
            <thead>
                <tr>
                    <th>No.</th>
                    <th>Coverage</th>
                    <th>{{ $printIsTimeSlots ? 'Slots' : 'Total' }}</th>
                    <th>{{ $printIsTimeSlots ? 'Good' : 'Score' }}</th>
                    <th>N/A</th>
                    <th>% Score</th>
                </tr>
            </thead>
            <tbody>
                @foreach ($printCoverageRows as $row)
                    <tr data-print-coverage="{{ $row['coverage'] }}"
                        data-print-assigned="{{ $row['_has_score'] ? 'true' : 'false' }}"
                        data-print-percent="{{ $row['_has_score'] ? number_format((float) $row['percent'], 1, '.', '') : '' }}">
                        <td>{{ $row['no'] }}</td>
                        <td>
                            @foreach ($printCoverageLabelLines[$row['coverage']] ?? [$row['coverage']] as $line)
                                @if (! $loop->first)<br>@endif{{ $line }}
                            @endforeach
                        </td>
                        <td>{{ $row['total'] }}</td>
                        <td>{{ $row['score'] }}</td>
                        <td>{{ $row['na'] ?? 0 }}</td>
                        <td class="workbook-percent-cell {{ $row['_has_score'] ? ($row['percent'] >= 80 ? 'is-pass' : 'is-fail') : 'is-unassigned' }}">
                            {{ $row['_has_score'] ? $printPercent($row['percent']) : '' }}
                        </td>
                    </tr>
                @endforeach
                @for ($filler = 0; $filler < $printCoverageFillerCount; $filler++)
                    <tr class="workbook-scope-filler" aria-hidden="true">
                        <td>&nbsp;</td>
                        <td></td>
                        <td></td>
                        <td></td>
                        <td></td>
                        <td></td>
                    </tr>
                @endfor
                <tr class="workbook-total-row">
                    <td colspan="2">Total:</td>
                    <td>{{ $coverageSummary['total'] }}</td>
                    <td>{{ $coverageSummary['score'] }}</td>
                    <td>{{ $coverageSummary['na'] ?? 0 }}</td>
                    <td class="workbook-percent-cell {{ $coverageSummary['percent'] >= 80 ? 'is-pass' : 'is-fail' }}">
                        {{ $printPercent($coverageSummary['percent']) }}
                    </td>
                </tr>
            </tbody>
        </table>
    </section>

    <section class="workbook-print-charts" aria-label="Workbook summary charts">
        <figure class="workbook-print-chart workbook-column-chart">
            <svg viewBox="0 0 520 270" role="img" aria-label="Overall audit score by criteria">
                @foreach (range(0, 10) as $tick)
                    @php
                        $tickValue = $barMinimum + ($tick * $barTickStep);
                        $tickY = $barPlot['y'] + $barPlot['height'] - (($tickValue - $barMinimum) / $barRange * $barPlot['height']);
                    @endphp
                    <line x1="{{ $barPlot['x'] }}" y1="{{ $tickY }}"
                          x2="{{ $barPlot['x'] + $barPlot['width'] }}" y2="{{ $tickY }}"
                          class="workbook-chart-gridline" />
                    <text x="{{ $barPlot['x'] - 8 }}" y="{{ $tickY + 3 }}" text-anchor="end" class="workbook-chart-tick">{{ number_format($tickValue, 0) }}%</text>
                @endforeach

                <line x1="{{ $barPlot['x'] }}" y1="{{ $barPlot['y'] }}"
                      x2="{{ $barPlot['x'] }}" y2="{{ $barPlot['y'] + $barPlot['height'] }}"
                      class="workbook-chart-axis" />
                <line x1="{{ $barPlot['x'] }}" y1="{{ $barPlot['y'] + $barPlot['height'] }}"
                      x2="{{ $barPlot['x'] + $barPlot['width'] }}" y2="{{ $barPlot['y'] + $barPlot['height'] }}"
                      class="workbook-chart-axis" />

                @foreach ($printCriteriaRows as $index => $row)
                    @php
                        $slotWidth = $barPlot['width'] / $barCount;
                        $barWidth = min(44.0, $slotWidth * 0.32);
                        $normalizedBarValue = (min(100, max($barMinimum, (float) $row['percent'])) - $barMinimum) / $barRange;
                        $barHeight = $barPlot['height'] * $normalizedBarValue;
                        $barX = $barPlot['x'] + ($slotWidth * $index) + (($slotWidth - $barWidth) / 2);
                        $barY = $barPlot['y'] + $barPlot['height'] - $barHeight;
                        $labelX = $barPlot['x'] + ($slotWidth * ($index + 0.5));
                        $valueLabelY = $barHeight > 0
                            ? $barY + ($barHeight / 2) + 3
                            : $barPlot['y'] + $barPlot['height'] - 5;
                    @endphp
                    <rect x="{{ $barX }}" y="{{ $barY }}" width="{{ $barWidth }}" height="{{ $barHeight }}" class="workbook-chart-bar" />
                    <text x="{{ $labelX }}" y="{{ $valueLabelY }}" text-anchor="middle" class="workbook-chart-value">{{ $printPercent($row['percent']) }}</text>
                    <text x="{{ $labelX }}" y="{{ $barPlot['y'] + $barPlot['height'] + 20 }}" text-anchor="middle" class="workbook-chart-label">{{ $row['category'] }}</text>
                @endforeach
            </svg>
        </figure>

        <figure class="workbook-print-chart workbook-radar-chart">
            <svg viewBox="0 0 405 270" role="img" aria-label="Compliance score by category">
                @foreach ($radarRings as $ringPoints)
                    <polygon points="{{ $ringPoints }}" class="workbook-radar-ring" />
                @endforeach

                <text x="{{ $radarCenterX - 5 }}" y="{{ $radarCenterY + 2 }}" text-anchor="end" class="workbook-radar-scale">0%</text>
                @foreach (range(1, 5) as $ring)
                    <text x="{{ $radarCenterX - 5 }}"
                          y="{{ $radarCenterY - ($radarRadius * ($ring / 5)) + 2 }}"
                          text-anchor="end"
                          class="workbook-radar-scale">{{ $ring * 20 }}%</text>
                @endforeach

                @foreach ($printCoverageRows as $index => $row)
                    @php
                        [$axisX, $axisY] = $radarPoint($radarRadius, $index);
                        [$labelX, $labelY, $direction] = $radarPoint($radarLabelRadius, $index);
                        $labelAnchor = $direction > 0.22 ? 'start' : ($direction < -0.22 ? 'end' : 'middle');
                        $labelLines = $wrapRadarLabel($row['coverage']);
                        $labelStartY = $labelY - ((count($labelLines) - 1) * 3.0);
                    @endphp
                    <line x1="{{ $radarCenterX }}" y1="{{ $radarCenterY }}"
                          x2="{{ $axisX }}" y2="{{ $axisY }}" class="workbook-radar-axis" />
                    <text x="{{ $labelX }}" y="{{ $labelStartY }}" text-anchor="{{ $labelAnchor }}" class="workbook-radar-label">
                        @foreach ($labelLines as $lineIndex => $line)
                            <tspan x="{{ $labelX }}" dy="{{ $lineIndex === 0 ? 0 : 6 }}">{{ $line }}</tspan>
                        @endforeach
                    </text>
                @endforeach

                @if ($radarScoredCoordinates->count() >= 3)
                    <polygon points="{{ $radarScorePoints }}" class="workbook-radar-score" />
                @elseif ($radarScoredCoordinates->count() === 2)
                    <polyline points="{{ $radarScorePoints }}" class="workbook-radar-score" />
                @elseif ($radarScoredCoordinates->count() === 1)
                    <line x1="{{ $radarCenterX }}" y1="{{ $radarCenterY }}"
                          x2="{{ $radarScoredCoordinates->first()['x'] }}"
                          y2="{{ $radarScoredCoordinates->first()['y'] }}"
                          class="workbook-radar-score" />
                @endif
            </svg>
        </figure>
    </section>

    <footer class="workbook-print-signatures">
        <section>
            <strong>Prepared by:</strong>
            <span>Auditor:</span>
        </section>
        <section>
            <strong>Approved by:</strong>
            @if ($printIsFiveS)
                <span>Branch Operations Manager:</span>
            @elseif ($printIsAftersales)
                <span>Service Manager:</span>
            @else
                <span>Sales Manager:</span>
            @endif
        </section>
        <section>
            <strong>Conforme:</strong>
            <span>Branch Head:</span>
        </section>
    </footer>
</section>
