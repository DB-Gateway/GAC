param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Release-ComObject {
    param([object]$Object)
    if ($null -ne $Object -and [System.Runtime.InteropServices.Marshal]::IsComObject($Object)) {
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Object)
    }
}

function Convert-ExcelValue {
    param([object]$Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [System.DBNull]) { return $null }

    try {
        if ($Value.GetType().FullName -eq 'System.Reflection.Missing') { return $null }
    } catch { }

    return $Value
}

function Get-TextAt {
    param(
        [object]$Worksheet,
        [int]$Row,
        [int]$Column
    )
    $cell = $null
    try {
        $cell = $Worksheet.Cells.Item($Row, $Column)
        $value = Convert-ExcelValue $cell.Value2
        if ($null -eq $value) { return $null }
        return [string]$value
    } finally {
        Release-ComObject $cell
    }
}

function Get-FormulaAt {
    param(
        [object]$Worksheet,
        [int]$Row,
        [int]$Column
    )
    $cell = $null
    try {
        $cell = $Worksheet.Cells.Item($Row, $Column)
        if (-not $cell.HasFormula) { return $null }
        return [string]$cell.Formula
    } finally {
        Release-ComObject $cell
    }
}

function Get-PrimaryAuditRows {
    param([object]$Worksheet)

    $records = [System.Collections.Generic.List[object]]::new()
    $row = 3
    while ($row -le 10000) {
        $numberText = Get-TextAt $Worksheet $row 1
        $number = 0
        if ([string]::IsNullOrWhiteSpace($numberText) -or -not [int]::TryParse($numberText, [ref]$number)) {
            break
        }

        $record = [ordered]@{
            number = $number
            source_row = $row
            category = Get-TextAt $Worksheet $row 2
            coverage = Get-TextAt $Worksheet $row 3
            subject = Get-TextAt $Worksheet $row 4
            checklist_item = Get-TextAt $Worksheet $row 5
            person_accountable = Get-TextAt $Worksheet $row 6
            checker = Get-TextAt $Worksheet $row 7
            sample_judgment = Get-TextAt $Worksheet $row 8
            sample_findings = Get-TextAt $Worksheet $row 9
            bom_task = Get-TextAt $Worksheet $row 10
            escalation = Get-TextAt $Worksheet $row 11
            sample_action_plan = Get-TextAt $Worksheet $row 12
            sample_commitment_date = Get-TextAt $Worksheet $row 13
            count_na_formula = Get-FormulaAt $Worksheet $row 14
            audit_result_part_1_formula = Get-FormulaAt $Worksheet $row 15
            audit_result_part_2_formula = Get-FormulaAt $Worksheet $row 16
        }
        $records.Add([pscustomobject]$record)
        $row++
    }
    return @($records)
}

function Get-HowToRows {
    param([object]$Worksheet)

    $records = [System.Collections.Generic.List[object]]::new()
    $row = 3
    while ($row -le 10000) {
        $numberText = Get-TextAt $Worksheet $row 1
        $number = 0
        if ([string]::IsNullOrWhiteSpace($numberText) -or -not [int]::TryParse($numberText, [ref]$number)) {
            break
        }
        $records.Add([pscustomobject][ordered]@{
            number = $number
            source_row = $row
            category = Get-TextAt $Worksheet $row 2
            coverage = Get-TextAt $Worksheet $row 3
            subject = Get-TextAt $Worksheet $row 4
            checklist_item = Get-TextAt $Worksheet $row 5
            how_to_check = Get-TextAt $Worksheet $row 6
            source_column_g = Get-TextAt $Worksheet $row 7
            source_column_h = Get-TextAt $Worksheet $row 8
        })
        $row++
    }
    return @($records)
}

function Get-FullWorksheetData {
    param([object]$Worksheet)

    $used = $null
    try {
        $used = $Worksheet.UsedRange
        $startRow = [int]$used.Row
        $startColumn = [int]$used.Column
        $endRow = $startRow + [int]$used.Rows.Count - 1
        $endColumn = $startColumn + [int]$used.Columns.Count - 1

        $cells = [System.Collections.Generic.List[object]]::new()
        $mergeSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        for ($row = $startRow; $row -le $endRow; $row++) {
            for ($column = $startColumn; $column -le $endColumn; $column++) {
                $cell = $null
                $mergeArea = $null
                $comment = $null
                try {
                    $cell = $Worksheet.Cells.Item($row, $column)
                    $rawValue = Convert-ExcelValue $cell.Value2
                    $hasFormula = [bool]$cell.HasFormula
                    $hasComment = $null -ne $cell.Comment
                    $hasHyperlink = $cell.Hyperlinks.Count -gt 0

                    if ($cell.MergeCells) {
                        $mergeArea = $cell.MergeArea
                        [void]$mergeSet.Add([string]$mergeArea.Address($false, $false))
                    }

                    if ($null -eq $rawValue -and -not $hasFormula -and -not $hasComment -and -not $hasHyperlink) {
                        continue
                    }

                    $formula = $null
                    if ($hasFormula) { $formula = [string]$cell.Formula }
                    $commentText = $null
                    if ($hasComment) {
                        $comment = $cell.Comment
                        $commentText = [string]$comment.Text()
                    }
                    $hyperlinks = @()
                    if ($hasHyperlink) {
                        foreach ($hyperlink in $cell.Hyperlinks) {
                            $hyperlinks += [pscustomobject]@{
                                address = [string]$hyperlink.Address
                                sub_address = [string]$hyperlink.SubAddress
                                text_to_display = [string]$hyperlink.TextToDisplay
                            }
                            Release-ComObject $hyperlink
                        }
                    }

                    $cells.Add([pscustomobject][ordered]@{
                        address = [string]$cell.Address($false, $false)
                        row = $row
                        column = $column
                        value = $rawValue
                        displayed_text = [string]$cell.Text
                        formula = $formula
                        number_format = [string]$cell.NumberFormat
                        comment = $commentText
                        hyperlinks = $hyperlinks
                    })
                } finally {
                    Release-ComObject $comment
                    Release-ComObject $mergeArea
                    Release-ComObject $cell
                }
            }
        }

        $tables = @()
        foreach ($table in $Worksheet.ListObjects) {
            $headers = @()
            foreach ($column in $table.ListColumns) {
                $headers += [string]$column.Name
                Release-ComObject $column
            }
            $tables += [pscustomobject]@{
                name = [string]$table.Name
                display_name = [string]$table.DisplayName
                range = [string]$table.Range.Address($false, $false)
                headers = $headers
            }
            Release-ComObject $table
        }

        $validations = @()
        $validationRange = $null
        try {
            $validationRange = $used.SpecialCells(-4174)
            foreach ($area in $validationRange.Areas) {
                $firstCell = $null
                $validation = $null
                try {
                    $firstCell = $area.Cells.Item(1, 1)
                    $validation = $firstCell.Validation
                    $validations += [pscustomobject]@{
                        range = [string]$area.Address($false, $false)
                        type = [int]$validation.Type
                        alert_style = [int]$validation.AlertStyle
                        operator = [int]$validation.Operator
                        formula1 = [string]$validation.Formula1
                        formula2 = [string]$validation.Formula2
                        ignore_blank = [bool]$validation.IgnoreBlank
                        in_cell_dropdown = [bool]$validation.InCellDropdown
                        input_title = [string]$validation.InputTitle
                        input_message = [string]$validation.InputMessage
                        error_title = [string]$validation.ErrorTitle
                        error_message = [string]$validation.ErrorMessage
                    }
                } finally {
                    Release-ComObject $validation
                    Release-ComObject $firstCell
                    Release-ComObject $area
                }
            }
        } catch {
            # No validation cells on this sheet.
        } finally {
            Release-ComObject $validationRange
        }

        $shapes = @()
        foreach ($shape in $Worksheet.Shapes) {
            $shapes += [pscustomobject]@{
                name = [string]$shape.Name
                type = [int]$shape.Type
                alternative_text = [string]$shape.AlternativeText
                title = [string]$shape.Title
                top_left_cell = [string]$shape.TopLeftCell.Address($false, $false)
                bottom_right_cell = [string]$shape.BottomRightCell.Address($false, $false)
            }
            Release-ComObject $shape
        }

        $visibility = switch ([int]$Worksheet.Visible) {
            -1 { 'visible' }
            0 { 'hidden' }
            2 { 'very_hidden' }
            default { [string]$Worksheet.Visible }
        }

        return [pscustomobject][ordered]@{
            name = [string]$Worksheet.Name
            index = [int]$Worksheet.Index
            visibility = $visibility
            used_range = [string]$used.Address($false, $false)
            start_row = $startRow
            start_column = $startColumn
            end_row = $endRow
            end_column = $endColumn
            cells = @($cells)
            merged_ranges = @($mergeSet | Sort-Object)
            tables = $tables
            data_validations = $validations
            shapes = $shapes
        }
    } finally {
        Release-ComObject $used
    }
}

function Get-DistinctSummary {
    param([object[]]$Rows)

    $fields = @('category', 'coverage', 'subject', 'person_accountable', 'checker', 'escalation')
    $summary = [ordered]@{}
    foreach ($field in $fields) {
        $groups = $Rows |
            ForEach-Object { $_.$field } |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
            Group-Object |
            Sort-Object Name |
            ForEach-Object { [pscustomobject]@{ value = $_.Name; count = $_.Count } }
        $summary[$field] = @($groups)
    }
    return [pscustomobject]$summary
}

$workspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$sources = @(
    [pscustomobject]@{
        audit_type = 'DOS Sales'
        file = Join-Path $workspace 'FY25 Sales Standards Compliance Audit Sheet (REV02)_1.xlsx'
    },
    [pscustomobject]@{
        audit_type = 'DOS Aftersales'
        file = Join-Path $workspace 'FY25 Aftersales Standards Compliance Audit Sheet_updated as 08262026.xlsx'
    }
)

$excel = $null
$result = [ordered]@{
    extracted_at = (Get-Date).ToString('o')
    note = 'Read-only extraction via Microsoft Excel COM. sample_* values are prefilled examples/current workbook responses and should not be seeded as blank-audit defaults.'
    workbooks = @()
}

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $excel.AskToUpdateLinks = $false

    foreach ($source in $sources) {
        $workbook = $null
        try {
            $workbook = $excel.Workbooks.Open($source.file, 0, $true)
            $primarySheet = $workbook.Worksheets.Item('Main Form')
            $howToSheet = $workbook.Worksheets.Item('How To Check')
            try {
                $primaryRows = @(Get-PrimaryAuditRows $primarySheet)
                $howToRows = @(Get-HowToRows $howToSheet)
            } finally {
                Release-ComObject $howToSheet
                Release-ComObject $primarySheet
            }

            $howToByNumber = @{}
            foreach ($howTo in $howToRows) { $howToByNumber[[int]$howTo.number] = $howTo }
            $joinedRows = @()
            foreach ($row in $primaryRows) {
                $howTo = $howToByNumber[[int]$row.number]
                $joinedRows += [pscustomobject][ordered]@{
                    number = $row.number
                    source_row = $row.source_row
                    category = $row.category
                    coverage = $row.coverage
                    subject = $row.subject
                    checklist_item = $row.checklist_item
                    how_to_check = if ($null -ne $howTo) { $howTo.how_to_check } else { $null }
                    person_accountable = $row.person_accountable
                    checker = $row.checker
                    bom_task = $row.bom_task
                    escalation = $row.escalation
                    sample_judgment = $row.sample_judgment
                    sample_findings = $row.sample_findings
                    sample_action_plan = $row.sample_action_plan
                    sample_commitment_date = $row.sample_commitment_date
                    source_consistency = [pscustomobject]@{
                        how_to_row_found = $null -ne $howTo
                        category_matches = $null -ne $howTo -and $row.category -ceq $howTo.category
                        coverage_matches = $null -ne $howTo -and $row.coverage -ceq $howTo.coverage
                        subject_matches = $null -ne $howTo -and $row.subject -ceq $howTo.subject
                        checklist_item_matches = $null -ne $howTo -and $row.checklist_item -ceq $howTo.checklist_item
                    }
                }
            }

            $sheets = @()
            foreach ($worksheet in $workbook.Worksheets) {
                $sheets += Get-FullWorksheetData $worksheet
                Release-ComObject $worksheet
            }

            $names = @()
            foreach ($name in $workbook.Names) {
                $names += [pscustomobject]@{
                    name = [string]$name.Name
                    refers_to = [string]$name.RefersTo
                    visible = [bool]$name.Visible
                }
                Release-ComObject $name
            }

            $result.workbooks += [pscustomobject][ordered]@{
                audit_type = $source.audit_type
                file_name = [IO.Path]::GetFileName($source.file)
                full_path = $source.file
                sheet_count = [int]$workbook.Worksheets.Count
                names = $names
                sheets = $sheets
                primary_records = $joinedRows
                primary_source_rows = $primaryRows
                how_to_source_rows = $howToRows
                distinct_values = Get-DistinctSummary $primaryRows
            }
        } finally {
            if ($null -ne $workbook) {
                $workbook.Close($false)
                Release-ComObject $workbook
            }
        }
    }
} finally {
    if ($null -ne $excel) {
        $excel.Quit()
        Release-ComObject $excel
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    [IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}
$json = $result | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText($OutputPath, $json, [Text.UTF8Encoding]::new($false))
Write-Output $OutputPath
