<?php

namespace Database\Seeders;

use App\Models\ChecklistItem;
use App\Models\ChecklistSection;
use App\Models\ChecklistTemplate;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use JsonException;
use RuntimeException;

class ChecklistTemplateSeeder extends Seeder
{
    public function run(): void
    {
        DB::transaction(function (): void {
            $this->seedTemplate($this->fiveS());
            $this->seedTemplate($this->dealerOperationsStandards());
            $this->seedTemplate($this->dealerOperationsStandardsSales());
            $this->seedTemplate($this->sales());
            $this->seedTemplate($this->service());
            $this->syncTemplate($this->sales());
            $this->syncTemplate($this->service());
            $this->seedTemplate($this->restroom());
        });
    }

    public function syncTemplate(array $preset): ChecklistTemplate
    {
        $template = ChecklistTemplate::query()->firstOrCreate([
            'slug' => $preset['slug'],
        ], [
            'name' => $preset['name'],
            'description' => $preset['description'],
            'version' => 1,
            'settings' => $preset['settings'],
            'is_active' => $preset['is_active'] ?? true,
        ]);

        $template->update([
            'name' => $preset['name'],
            'description' => $preset['description'],
            'settings' => array_merge($template->settings ?? [], $preset['settings']),
            'is_active' => $preset['is_active'] ?? true,
        ]);

        $activeSectionIds = [];
        $activeItemIds = [];

        foreach ($preset['sections'] as $sectionOrder => $sectionData) {
            $section = ChecklistSection::query()->updateOrCreate([
                'checklist_template_id' => $template->id,
                'key' => $sectionData['key'],
            ], [
                'title' => $sectionData['title'],
                'sort_order' => $sectionOrder,
                'metadata' => $sectionData['metadata'] ?? null,
                'is_active' => true,
            ]);

            $activeSectionIds[] = $section->id;

            foreach ($sectionData['items'] as $itemOrder => $itemData) {
                $item = ChecklistItem::query()->updateOrCreate([
                    'checklist_template_id' => $template->id,
                    'key' => $itemData['key'],
                ], [
                    'checklist_section_id' => $section->id,
                    'prompt' => $itemData['prompt'],
                    'sort_order' => $itemOrder,
                    'metadata' => $itemData['metadata'] ?? null,
                    'is_active' => true,
                ]);

                $activeItemIds[] = $item->id;
            }
        }

        ChecklistItem::query()
            ->where('checklist_template_id', $template->id)
            ->whereNotIn('id', $activeItemIds)
            ->delete();

        ChecklistSection::query()
            ->where('checklist_template_id', $template->id)
            ->whereNotIn('id', $activeSectionIds)
            ->delete();

        return $template->fresh(['sections.items']);
    }

    private function seedTemplate(array $preset): void
    {
        $template = ChecklistTemplate::query()->firstOrCreate([
            'slug' => $preset['slug'],
        ], [
            'name' => $preset['name'],
            'description' => $preset['description'],
            'version' => 1,
            'settings' => $preset['settings'],
            'is_active' => $preset['is_active'] ?? true,
        ]);

        if (! $template->wasRecentlyCreated) {
            return;
        }

        foreach ($preset['sections'] as $sectionOrder => $sectionData) {
            $section = ChecklistSection::query()->create([
                'checklist_template_id' => $template->id,
                'key' => $sectionData['key'],
                'title' => $sectionData['title'],
                'sort_order' => $sectionOrder,
                'metadata' => $sectionData['metadata'] ?? null,
                'is_active' => true,
            ]);

            foreach ($sectionData['items'] as $itemOrder => $itemData) {
                ChecklistItem::query()->create([
                    'checklist_template_id' => $template->id,
                    'key' => $itemData['key'],
                    'checklist_section_id' => $section->id,
                    'prompt' => $itemData['prompt'],
                    'sort_order' => $itemOrder,
                    'metadata' => $itemData['metadata'] ?? null,
                    'is_active' => true,
                ]);
            }
        }
    }

    private function fiveS(): array
    {
        $sections = $this->numberedSections($this->fiveSSectionDefinitions());

        return [
            'slug' => 'gateway-5s',
            'name' => 'Gateway Sales and Service 5S Checklist',
            'description' => 'Legacy combined Sales and Service 5S audit retained for existing records and mobile clients.',
            'settings' => [
                'validation_mode' => 'yes_no_na',
                'response_options' => ['yes', 'no', 'na'],
                'instructions' => 'Complete every item before business hours. A remark is required for NO and N/A.',
                'schedule' => ['start' => '08:00', 'end' => '08:30'],
                'source' => 'Gateway 5S Checklist.xlsx / Combined Sales and Service',
                'workspace_hidden' => true,
            ],
            'sections' => $sections,
        ];
    }

    public function sales(): array
    {
        $salesSections = [
            'parking-area',
            'showroom-sales-negotiation-area',
            'sales-reception-area',
            'vehicles-display',
            'restrooms',
            'customer-lounge',
            'sales-executives-on-showroom-duty',
        ];

        return [
            'slug' => 'sales',
            'name' => 'Sales Checklist',
            'description' => 'Daily Sales showroom, reception, vehicle-display, and customer-readiness audit.',
            'settings' => [
                'validation_mode' => 'yes_no_na',
                'response_options' => ['yes', 'no', 'na'],
                'instructions' => "Pre-Business Hours Checklist Instructions:\nThe Sales Officer-in-Charge of the day (GRM) is required to complete this checklist before the start of business hours.\nThe Branch Operations Officer is responsible for overseeing the showroom and ensuring the checklist is accurately and regularly completed each day.",
                'schedule' => ['start' => '08:00', 'end' => '08:30'],
                'source' => 'Gateway 5S Checklist_2.xlsx / Sales',
                'performed_by' => 'Sales Officer of the Day',
                'workspace_order' => 20,
            ],
            'sections' => $this->numberedSections($this->salesSectionDefinitions()),
        ];
    }

    public function service(): array
    {
        return [
            'slug' => 'service',
            'name' => 'Service Checklist',
            'description' => 'Daily Service reception, working-bay, and customer-readiness audit.',
            'settings' => [
                'validation_mode' => 'yes_no_na',
                'response_options' => ['yes', 'no', 'na'],
                'instructions' => "Pre-Business Hours Checklist Instructions:\nThe Service Officer-in-Charge of the day(CE & Workshop Sup/Leadman/Foreman) is required to complete this checklist before the start of business hours.\nThe Branch Operations Manager is responsible for overseeing the service facility and ensuring the checklist is accurately and regularly completed each day.",
                'schedule' => ['start' => '08:00', 'end' => '08:30'],
                'source' => 'Gateway 5S Checklist_2.xlsx / Service',
                'performed_by' => 'Service Officer of the Day',
                'workspace_order' => 30,
            ],
            'sections' => $this->numberedSections($this->serviceSectionDefinitions()),
        ];
    }

    /**
     * @return array<int, array{0: string, 1: string, 2: list<string>}>
     */
    public function salesSectionDefinitions(): array
    {
        return [
            ['parking-area', 'Parking Area', [
                'Is the parking area clearly visible and easy for customers to find parking, with well-defined parking lines and proper signage?',
                'Is the parking area clean and free from dirt and Dirt? (well maintained)?',
            ]],
            ['showroom-sales-negotiation-area', 'Showroom / Sales Negotiation Area', [
                'Is the area clean and well-organized, with no unnecessary items on the floor?',
                'Are there no broken or damaged tiles?',
                'Are all the lights in the showroom functioning properly',
                'Are the sales materials (posters, banners, and illuminated signage) current, well-maintained, clean, and properly organized?',
                'Are the windows clean, free from fingerprints, watermarks, tape, or any other marks?',
                'Are the ceilings and walls free of dirt, damage and water leakage?',
                'Are the sales negotiation tables and chairs clean and properly sanitized?',
                'Is free Wi-Fi available and easily accessible to customers?',
                'Is the ventilation and A/C system adequate and fully operational?',
            ]],
            ['sales-reception-area', 'Sales Reception Area', [
                'Reception area is kept neat and tidy. Surrounding area are kept free of dirt and waste. No personal belongings shown.',
                'The reception counter and chairs are clean and free from damage.',
            ]],
            ['test-drive-vehicle', 'Test Drive Vehicle', [
                'Test drive vehicle are maintained clean.',
                'Test drive vehicle are fully functional and complies with regular PMS.',
                'Test drive vehicle are free from damage',
            ]],
            ['vehicles-display', 'Vehicles Display', [
                'Is the car display area clean, free of dirt and waste, and properly sanitized?',
                'Is at least one unit of each MG model displayed in the showroom, and does it include the latest model year with a mix of high-end variants?',
                'Is there an information stand available near each display unit?',
                'Are the displayed cars kept clean and free of protective coverings?',
                'Are the engine compartments clean?',
                'Are the display units unlocked?',
                'Are genuine floor mats installed? And no paper mat is installed?',
                'Is the battery charged, or is there a power supply from the floor, with all electric equipment functioning properly?',
                'Are the vehicle interiors clean?',
                'Is there enough space secured between the vehicles?',
                'Are the test drive units available, organized, and properly sanitized?',
            ]],
            ['restrooms', 'Restrooms', [
                'Are the necessary items (e.g., papers, soap, hand dryers) available?',
                'Is the restroom free from dirt and waste, including the floor, walls, and tiles?',
                'Are the sinks and faucets in proper working condition?',
                'Are the toilet bowls and urinals in proper working condition?',
                'Is the Female restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the Male restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the PWD restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the restroom checklist updated?',
            ]],
            ['customer-lounge', 'Customer Lounge', [
                'Are there free snacks available? ( Biscuits, etc.)',
                'Are there available free refreshments (Coffee and Water)?',
                'Are the seats/sofas comfortable, undamaged, and properly sanitized?',
                'Is the LED television in working condition and well-maintained?',
                'Is the ventilation and A/C system adequate and fully operational?',
                'Is  free Wi-Fi available and easily accessible to customers?',
            ]],
            ['sales-executives-on-showroom-duty', 'Sales Executives on Showroom Duty', [
                'Are they wearing the prescribed uniform and ID badge?',
                'Are they well-groomed and dressed in the proper uniform?',
                'Do they have the Sales Kit, including the pricelist, business cards, and bank application form?',
            ]],
        ];
    }

    /**
     * @return array<int, array{0: string, 1: string, 2: list<string>}>
     */
    public function serviceSectionDefinitions(): array
    {
        return [
            ['parking-area', 'Parking Area', [
                'Is the service parking area clearly visible and easy for customers to find parking, with well-defined parking lines and proper signage?',
                'Is the parking area clean and free from dirt and Dirt? (well maintained)?',
            ]],
            ['service-reception', 'Service Reception', [
                'Is the area clean and well-organized, with no unnecessary items on the floor?',
                'Are there no broken or damaged tiles?',
                'Are all the lights in the showroom functioning properly',
                'Are the windows clean, free from fingerprints, watermarks, tape, or any other marks?',
                'Are the ceilings and walls free of dirt, damage and water leakage?',
                'Are the service reception tables and chairs clean and properly sanitized?',
                'Is free Wi-Fi available and easily accessible to customers?',
                'Is the ventilation and A/C system adequate and fully operational?',
                'The reception counter and chairs are clean and free from damage.',
            ]],
            ['service-working-bay', 'Service Working Bay', [
                'Is the working bay clean, free of dirt and waste, and properly sanitized?',
                'Are all trolleys stored within the painted work bay when not in use, with no unnecessary items such as drinking bottles, shoes, etc., left behind?',
                'Are there no used parts or empty plastic containers left in the work bay?',
                'Are the lifters clean and returned to their normal (down) position when not in use and at the end of working hours?',
                'Are the vehicle windows closed at all times, except when repairs are in progress?',
                'Are the tools organized, complete, and placed in their proper locations?',
            ]],
            ['restrooms', 'Restrooms', [
                'Are the necessary items (e.g., papers, soap, hand dryers) available?',
                'Is the restroom free from dirt and waste, including the floor, walls, and tiles?',
                'Are the sinks and faucets in proper working condition?',
                'Are the toilet bowls and urinals in proper working condition?',
                'Is the Female restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the Male restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the PWD restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the restroom checklist updated?',
            ]],
            ['customer-lounge', 'Customer Lounge', [
                'Are there free snacks available? ( Biscuits, etc.)',
                'Are there available free refreshments (Coffee and Water)?',
                'Are the seats/sofas comfortable, undamaged, and properly sanitized?',
                'Is the LED television in working condition and well-maintained?',
                'Is the ventilation and A/C system adequate and fully operational?',
                'Is  free Wi-Fi available and easily accessible to customers?',
            ]],
            ['frontliners', 'Frontliners', [
                'Are they wearing the prescribed uniform and ID badge?',
                'Are they well-groomed and dressed in the proper uniform?',
            ]],
        ];
    }

    /**
     * @return array<int, array{0: string, 1: string, 2: list<string>}>
     */
    private function fiveSSectionDefinitions(): array
    {
        return [
            ['parking-area', 'Parking Area', [
                'Is the parking area clearly visible and easy for customers to find, with well-defined parking lines and proper signage?',
                'Is the parking area clean, free from dirt and debris, and well maintained?',
            ]],
            ['showroom-sales-negotiation-area', 'Showroom / Sales Negotiation Area', [
                'Is the area clean and well-organized, with no unnecessary items on the floor?',
                'Are there no broken or damaged tiles?',
                'Are all the lights in the showroom functioning properly?',
                'Are the sales materials (posters, banners, and illuminated signage) current, well-maintained, clean, and properly organized?',
                'Are the windows clean and free from fingerprints, watermarks, tape, or any other marks?',
                'Are the ceilings and walls free from dirt, damage, and water leakage?',
                'Are the sales negotiation tables and chairs clean and properly sanitized?',
                'Is free Wi-Fi available and easily accessible to customers?',
                'Is the ventilation and A/C system adequate and fully operational?',
            ]],
            ['sales-reception-area', 'Sales Reception Area', [
                'Is the reception area kept neat and tidy, with the surroundings free from dirt, waste, and visible personal belongings?',
                'Are the reception counter and chairs clean and free from damage?',
            ]],
            ['vehicles-display', 'Vehicles Display', [
                'Is the vehicle display area clean, free from dirt and waste, and properly sanitized?',
                'Is at least one unit of each MG model displayed in the showroom, including the latest model year and a mix of high-end variants?',
                'Is an information stand available near each display unit?',
                'Are the displayed vehicles clean and free of protective coverings?',
                'Are the engine compartments clean?',
                'Are the display units unlocked?',
                'Are genuine floor mats installed, with no paper mats in use?',
                'Is the battery charged or connected to a floor power supply, with all electrical equipment functioning properly?',
                'Are the vehicle interiors clean?',
                'Is sufficient space maintained between the vehicles?',
                'Are the test-drive units available, organized, and properly sanitized?',
            ]],
            ['service-reception', 'Service Reception', [
                'Is the area clean and well-organized, with no unnecessary items on the floor?',
                'Are there no broken or damaged tiles?',
                'Are all the lights in the service reception area functioning properly?',
                'Are the windows clean and free from fingerprints, watermarks, tape, or any other marks?',
                'Are the ceilings and walls free from dirt, damage, and water leakage?',
                'Are the service reception tables and chairs clean and properly sanitized?',
                'Is free Wi-Fi available and easily accessible to customers?',
                'Is the ventilation and A/C system adequate and fully operational?',
            ]],
            ['service-working-bay', 'Service Working Bay', [
                'Is the working bay clean, free from dirt and waste, and properly sanitized?',
                'Are all trolleys stored within the painted work bay when not in use, with no unnecessary items such as drinking bottles or shoes left behind?',
                'Are there no used parts or empty plastic containers left in the work bay?',
                'Are the lifters clean and returned to their normal down position when not in use and at the end of working hours?',
                'Are the vehicle windows closed at all times, except when repairs are in progress?',
                'Are the tools organized, complete, and placed in their proper locations?',
                'Are the service reception counter and chairs clean and free from damage?',
            ]],
            ['restrooms', 'Restrooms', [
                'Are the necessary supplies, such as paper products, soap, and hand-drying facilities, available?',
                'Is the restroom free from dirt and waste, including the floor, walls, and tiles?',
                'Are the sinks and faucets in proper working condition?',
                'Are the toilet bowls and urinals in proper working condition?',
                'Is the female restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the male restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the PWD restroom clean and sanitized, with no water splashes around the sink or unnecessary items on the floor?',
                'Is the restroom checklist updated?',
            ]],
            ['customer-lounge', 'Customer Lounge', [
                'Are complimentary snacks, such as biscuits, available?',
                'Are complimentary refreshments, including coffee and water, available?',
                'Are the seats and sofas comfortable, undamaged, and properly sanitized?',
                'Is the LED television in working condition and well maintained?',
                'Is the ventilation and A/C system adequate and fully operational?',
                'Is free Wi-Fi available and easily accessible to customers?',
            ]],
            ['sales-executives-on-showroom-duty', 'Sales Executives on Showroom Duty', [
                'Are the sales executives wearing the prescribed uniform and ID badge?',
                'Are the sales executives well-groomed and dressed in the proper uniform?',
                'Do the sales executives have the complete Sales Kit, including the price list, business cards, and bank application form?',
            ]],
        ];
    }

    /**
     * @param  list<string>  $keys
     * @return array<int, array{0: string, 1: string, 2: list<string>}>
     */
    private function onlySections(array $keys): array
    {
        $sections = collect($this->fiveSSectionDefinitions())->keyBy(fn (array $section): string => $section[0]);

        return collect($keys)
            ->map(fn (string $key): array => $sections->get($key))
            ->values()
            ->all();
    }

    /**
     * @param  array<int, array{0: string, 1: string, 2: list<string>}>  $definitions
     * @return list<array{key: string, title: string, items: list<array{key: string, prompt: string, metadata: array{number: int}}>}>
     */
    private function numberedSections(array $definitions): array
    {
        $number = 0;

        return array_map(function (array $section) use (&$number): array {
            return [
                'key' => $section[0],
                'title' => $section[1],
                'items' => array_map(function (string $prompt) use (&$number): array {
                    $number++;

                    return [
                        'key' => "item-$number",
                        'prompt' => $prompt,
                        'metadata' => ['number' => $number],
                    ];
                }, $section[2]),
            ];
        }, $definitions);
    }

    private function dealerOperationsStandards(): array
    {
        $coverageOrder = [
            'Manpower',
            'Pro-active Customer Contact',
            'Customer Appointment',
            'Systems',
            'Facilities',
            'Personalized Customer Reception',
            'Menu Pricing / Commitment of Price and Time Delivery',
            'Customer Care and Communication',
            'Workshop Scheduling',
            'Advance Info to Parts Store',
            'Repair Order Processing and Quality of Work',
            'Repair Order Completion and Invoicing',
            'Customer Information and Car Return',
            'Customer After Service Contact',
            'Concern Prevention and Resolution',
        ];

        $rows = $this->jsonItems('dos_aftersales_items.json');
        $grouped = array_fill_keys($coverageOrder, []);
        foreach ($rows as $row) {
            $number = (int) $row['No'];
            $level = trim((string) ($row['Category'] ?? 'Standard'));
            $coverage = Str::squish((string) ($row['Coverage'] ?? ''));
            $subject = trim((string) ($row['Subject'] ?? ''));
            $prompt = trim((string) ($row['CheckItem'] ?? ''));

            $grouped[$coverage] ??= [];
            $grouped[$coverage][] = [
                'key' => "dos-as-$number",
                'prompt' => $prompt,
                'metadata' => [
                    'number' => $number,
                    'level' => $level,
                    'category' => $level,
                    'coverage' => $coverage,
                    'subject' => $subject,
                    'checker' => $this->normalizedChecker((string) ($row['Checker'] ?? 'ASM')),
                    'pic' => trim((string) ($row['PersonAccountable'] ?? 'GM')),
                    'bom_task' => trim((string) ($row['BOMTask'] ?? '')),
                    'escalation' => trim((string) ($row['Escalation'] ?? '')),
                    'how_to_check' => trim((string) ($row['HowToCheck'] ?? '')),
                ],
            ];
        }

        $sections = [];
        $sectionNumber = 0;
        foreach ($grouped as $coverage => $items) {
            if (! $items) {
                continue;
            }
            $sectionNumber++;
            $sections[] = [
                'key' => "coverage-$sectionNumber",
                'title' => $coverage,
                'items' => $items,
            ];
        }

        return [
            'slug' => 'dealer-operations-standards',
            'name' => 'Dealer Operations Standards',
            'description' => 'FY2025 Aftersales Standards Compliance Audit Main Form.',
            'settings' => [
                'validation_mode' => 'dos',
                'response_options' => ['yes', 'no', 'na'],
                'instructions' => 'Judge every standard. NO requires a finding; N/A requires a reason.',
                'scoring' => [
                    'basic_required_percentage' => 100,
                    'standard_required_percentage' => 80,
                    'overall_required_percentage' => 80,
                ],
                'source' => 'FY25 Aftersales Standards Compliance Audit Sheet_updated as 08262026.xlsx / Main Form and How To Check',
            ],
            'sections' => $sections,
        ];
    }

    private function restroom(): array
    {
        $sectionDefs = [
            ['restroom-lighting', 'Lighting', [
                'All are working',
                'Light switch are working',
            ]],
            ['restroom-exhaust', 'Exhaust', [
                'All exhaust fans are working',
                'All exhaust fans are clean',
                'No foul smell is present',
            ]],
            ['restroom-floor-wall-ceiling', 'Floor, Wall & Ceiling', [
                'All are clean',
                'Tiles are complete and no cracks',
                'Floor drain is working',
            ]],
            ['restroom-toilet-bowl', 'Toilet Bowl', [
                'All are clean',
                'Flush is working properly',
                'Bidet is working properly',
                'No water leak',
            ]],
            ['restroom-urinal', 'Urinal', [
                'All are clean',
                'Flush is working properly',
                'No water leak',
            ]],
            ['restroom-sink-and-faucet', 'Sink and faucet', [
                'All are clean',
                'Faucet is working properly',
                'Drain is working properly',
                'No water leak',
            ]],
            ['restroom-toilet-accessories', 'Toilet Accessories', [
                'Toilet tissue is available',
                'Toilet tissue holder is available',
                'Liquid Soap is available',
                'Liquid Soap Dispenser is available',
                'Hand  Drier is working',
                'Mirror is clean',
                'Mirror has no damage',
            ]],
            ['restroom-trash-bin', 'Trash Bin', [
                'All are clean',
                'All bin with trash bag',
            ]],
            ['restroom-water-supply', 'Water Supply', [
                'Water pressure is ok',
            ]],
            ['restroom-cleaning-materials', 'Cleaning Materials', [
                'Are stored properly',
            ]],
        ];

        $itemNumber = 1;
        $sections = [];

        foreach ($sectionDefs as [$sectionKey, $sectionTitle, $prompts]) {
            $items = [];
            foreach ($prompts as $promptOrder => $prompt) {
                $items[] = [
                    'key' => 'restroom-item-'.$itemNumber,
                    'prompt' => $prompt,
                    'metadata' => [
                        'number' => $itemNumber,
                        'response_type' => 'time_slots',
                        'subject' => $sectionTitle,
                    ],
                ];
                $itemNumber++;
            }

            $sections[] = [
                'key' => $sectionKey,
                'title' => $sectionTitle,
                'items' => $items,
            ];
        }

        return [
            'slug' => 'restroom',
            'name' => 'Restroom Checklist',
            'description' => 'Restroom condition and orderliness inspection at 8 AM, 11 AM, 1 PM, and 4 PM.',
            'settings' => [
                'validation_mode' => 'time_slots',
                'instructions' => 'Mark each scheduled inspection as Good (/) or Not Good (X), and add a row remark when needed.',
                'time_slots' => [
                    ['key' => '08:00', 'label' => '8 AM'],
                    ['key' => '11:00', 'label' => '11 AM'],
                    ['key' => '13:00', 'label' => '1 PM'],
                    ['key' => '16:00', 'label' => '4 PM'],
                ],
                'legend' => ['good' => '/', 'not_good' => 'X'],
                'remark_per_item' => true,
                'source' => 'Gateway 5S Checklist_2.xlsx / Restroom - Utility',
            ],
            'sections' => $sections,
        ];
    }

    private function dealerOperationsStandardsSales(): array
    {
        $items = $this->jsonItems('dos_sales_items.json');

        $sectionDefs = [
            ['dos-facade', 'Facilities — Facade', 'Facade'],
            ['dos-showroom-area', 'Facilities — Showroom Area', 'Showroom Area'],
            ['dos-test-drive', 'Product Presentation and Test Drive — Test Drive', 'Test Drive'],
        ];

        $sections = [];
        foreach ($sectionDefs as $sDef) {
            $secItems = [];
            foreach ($items as $i) {
                if (trim((string) ($i['Subject'] ?? '')) !== $sDef[2]) {
                    continue;
                }

                $no = (int) $i['No'];
                $secItems[] = [
                    'key' => "dos-$no",
                    'prompt' => trim($i['CheckItem']),
                    'metadata' => [
                        'number' => $no,
                        'level' => trim($i['Category'] ?? 'Standard'),
                        'category' => trim($i['Category'] ?? 'Standard'),
                        'coverage' => trim($i['Coverage'] ?? ''),
                        'subject' => trim($i['Subject'] ?? ''),
                        'checker' => trim($i['Checker'] ?? 'SALES MANAGER'),
                        'pic' => trim($i['PIC'] ?? 'GM'),
                        'bom_task' => trim($i['BOMTask'] ?? ''),
                        'escalation' => trim($i['Escalation'] ?? ''),
                        'how_to_check' => trim($i['HowToCheck'] ?? ''),
                    ],
                ];
            }
            $sections[] = [
                'key' => $sDef[0],
                'title' => $sDef[1],
                'items' => $secItems,
            ];
        }

        return [
            'slug' => 'dealer-operations-standards-sales',
            'name' => 'Dealer Operations Standards - Sales',
            'description' => 'DEALS STANDARD COMPLIANCE AUDIT SHEET FOR SALES (22 Standards)',
            'settings' => [
                'validation_mode' => 'dos',
                'response_options' => ['yes', 'no', 'na'],
                'instructions' => 'Judge every standard. NO requires a finding; N/A requires a reason.',
                'scoring' => [
                    'basic_required_percentage' => 100,
                    'standard_required_percentage' => 80,
                    'overall_required_percentage' => 80,
                ],
                'source' => 'FY25 Sales Standards Compliance Audit Sheet (REV02)_1.xlsx',
            ],
            'sections' => $sections,
        ];
    }

    private function normalizedChecker(string $checker): string
    {
        return match (strtoupper(trim($checker))) {
            'WS', 'WS SUP', 'WORKSHOP', 'WORSHOP SUP',
            'WORKSHOP SUP', 'WORKSHOP SUPERVISOR' => 'WORKSHOP SUP',
            default => trim($checker),
        };
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function jsonItems(string $filename): array
    {
        $path = database_path("data/$filename");
        if (! is_file($path)) {
            throw new RuntimeException("Missing DOS template data file: $path");
        }

        $raw = file_get_contents($path);

        if ($raw === false) {
            throw new RuntimeException("Unable to read DOS template data file: $path");
        }

        try {
            $items = json_decode($raw, true, flags: JSON_THROW_ON_ERROR);
        } catch (JsonException $exception) {
            throw new RuntimeException(
                "Invalid DOS template data file: $path",
                previous: $exception
            );
        }

        if (! is_array($items) || ! array_is_list($items)) {
            throw new RuntimeException("DOS template data must be a JSON list: $path");
        }

        return $items;
    }
}
