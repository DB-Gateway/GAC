<?php

$branchesByRegion = [
    'NCR' => [
        'Makati',
        'Pasong Tamo',
        'Otis',
        'Fairview',
        'Quezon Avenue',
        'Marcos Highway',
        'Cainta',
        'Pasig',
        'Sucat',
        'Alabang',
        'Las Pinas',
        'Bacoor (Old Nissan)',
        'Dasmarinas',
        'Marilao',
        'Angeles',
        'Tarlac',
        'Isabela',
        'Santa Rosa',
        'Calamba',
        'Lipa',
        'Alaminos',
        'San Pablo',
        'Pili',
        'Legazpi',
        'Greenhills',
        'Manila Bay',
    ],
    'Visayas' => [
        'Mandaue',
        'Cebu City',
        'Talisay',
        'Gorordo',
        'NRA',
        'Cebu',
        'Bohol',
        'Bacolod',
    ],
    'Mindanao' => [
        'Matina',
        'Buhangin',
        'Lanang',
        'Digos',
        'Kidapawan',
        'Cotabato City',
        'Tagum',
        'Panabo',
        'San Francisco',
        'Negros',
        'Cagayan de Oro',
        'Butuan',
        'Valencia',
        'Iligian',
        'Dipolog',
    ],
];

$branches = [];
foreach ($branchesByRegion as $regionBranches) {
    foreach ($regionBranches as $branch) {
        $normalized = strtolower(trim($branch));
        if (! isset($branches[$normalized])) {
            $branches[$normalized] = $branch;
        }
    }
}

return [
    'report_timezone' => env('GAC_REPORT_TIMEZONE', 'Asia/Manila'),

    'branches_by_region' => $branchesByRegion,

    // The source list contains repeated rows. This is the canonical 49-name list.
    'branches' => array_values($branches),

    'registration_roles' => [
        'Person In Charge',
        'Sales Manager',
        'Aftersales Manager',
        'Customer Experience (CE) Service',
        'Job Controller',
        'Parts Supervisor',
        'Workshop Supervisor',
        'Workshop',
        'Branch Operations Manager',
        'Compliance Administrator',
    ],

    'pic_assignment_types' => [
        'utilities' => 'Utilities',
        'sales_service' => 'Sales & Service',
    ],

    'seeded_pic_accounts' => [
        'email_domain' => env('GAC_PIC_EMAIL_DOMAIN', 'pic.gateway.local'),
        'initial_password' => env('GAC_PIC_INITIAL_PASSWORD'),
    ],

    'seeded_dos_accounts' => [
        'branch' => env('GAC_DOS_ACCOUNT_BRANCH', 'Pasong Tamo'),
        'initial_password' => env('GAC_DOS_INITIAL_PASSWORD'),
    ],
];
