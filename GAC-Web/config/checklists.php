<?php

return [
    'navigation_groups' => [
        [
            'label' => '5S Checklist',
            'items' => [
                ['label' => 'Sales 5S', 'slug' => 'sales', 'icon' => 'fa-car-side'],
                ['label' => 'Service 5S', 'slug' => 'service', 'icon' => 'fa-screwdriver-wrench'],
            ],
        ],
        [
            'label' => 'DOS Checklist',
            'items' => [
                ['label' => 'Sales DOS', 'slug' => 'dealer-operations-standards-sales', 'icon' => 'fa-clipboard-check'],
                ['label' => 'Aftersales DOS', 'slug' => 'dealer-operations-standards', 'icon' => 'fa-clipboard-check'],
            ],
        ],
        [
            'label' => 'Utilities Checklist',
            'items' => [
                ['label' => 'Restroom', 'slug' => 'restroom', 'icon' => 'fa-restroom'],
            ],
        ],
    ],
];
