@include('checklists.database-page', [
    'pageTitle' => $checklistPage['title'],
    'pageSubtitle' => $checklistPage['subtitle'],
    'pageEyebrow' => $checklistPage['eyebrow'],
    'stylesheet' => $checklistPage['stylesheet'],
    'bodyClass' => $checklistPage['body_class'],
    'variant' => $checklistPage['variant'],
])
