<?php

use App\Models\ChecklistItem;
use App\Models\ChecklistSection;
use App\Models\ChecklistTemplate;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (app()->runningUnitTests()) {
            return;
        }

        DB::transaction(function (): void {
            $this->seedSubformTemplate();
            $this->seedDocumentationTemplate();
        });
    }

    public function down(): void
    {
        ChecklistTemplate::query()
            ->whereIn('slug', [
                'dealer-operations-standards-subform',
                'dealer-operations-standards-documentation',
            ])
            ->delete();
    }

    private function seedSubformTemplate(): void
    {
        $template = ChecklistTemplate::query()->firstOrCreate([
            'slug' => 'dealer-operations-standards-subform',
        ], [
            'name' => 'Dealer Operations Standards - Subform',
            'description' => 'FY2025 Aftersales Standards Compliance Audit Subform (39 Standards).',
            'version' => 1,
            'settings' => [
                'validation_mode' => 'dos_subform',
                'response_options' => ['yes', 'no', 'na'],
                'instructions' => 'Check each standard according to your assigned role. Note: Choosing "No" triggers a prerequisite cascade setting related items in the section to No.',
                'prerequisite_cascade' => true,
                'short_name' => 'DOS Subform',
                'time_slots' => [],
            ],
            'is_active' => true,
        ]);

        if (! $template->wasRecentlyCreated && $template->sections()->exists()) {
            return;
        }

        $sections = [
            [
                'key' => 'subform-service-reception',
                'title' => 'Service Reception c/o CE',
                'items' => [
                    [
                        'key' => 'subform-sr-1',
                        'prompt' => 'Service Reception signage follows the standard design, and must be clearly displayed at the entrance',
                        'metadata' => [
                            'number' => 1, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify signage follows MMPC VI design standards and is clearly visible at entrance.',
                        ],
                    ],
                    [
                        'key' => 'subform-sr-2',
                        'prompt' => 'Business hours clearly displayed at the entrance door',
                        'metadata' => [
                            'number' => 2, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Check if business hours are clearly posted on entrance door.',
                        ],
                    ],
                    [
                        'key' => 'subform-sr-3',
                        'prompt' => 'Three (3) monitors (with 42" minimum dimension) are wall-mounted behind the Service Advisor counters, and displays service information and promotional videos',
                        'metadata' => [
                            'number' => 3, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm 3 monitors (min 42") behind SA counters playing updated promo videos and service info.',
                        ],
                    ],
                    [
                        'key' => 'subform-sr-4',
                        'prompt' => 'Service hotlines (appointment, customer, car carrier) and MM360c App QR codes are clearly displayed at the Reception Area',
                        'metadata' => [
                            'number' => 4, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Check hotlines and MM360c app QR codes display at reception.',
                        ],
                    ],
                    [
                        'key' => 'subform-sr-5',
                        'prompt' => "Must be provided with proper AC temperature (must be minimum of 25°C in thermometer) for customers' convenience",
                        'metadata' => [
                            'number' => 5, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify room thermometer reads at least 25°C.',
                        ],
                    ],
                    [
                        'key' => 'subform-sr-6',
                        'prompt' => "Service reception counter must observe 5S (mainly service advisor's table)",
                        'metadata' => [
                            'number' => 6, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Perform 5S audit on SA desks and service reception counter.',
                        ],
                    ],
                    [
                        'key' => 'subform-sr-7',
                        'prompt' => 'Standard PMS menu and cost are displayed in the center monitor',
                        'metadata' => [
                            'number' => 7, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm center monitor displays current PMS menu pricing.',
                        ],
                    ],
                    [
                        'key' => 'subform-sr-8',
                        'prompt' => 'Receptionist/SA on duty must be located near the entrance.',
                        'metadata' => [
                            'number' => 8, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Observe if Receptionist or SA on duty is positioned at entrance.',
                        ],
                    ],
                    [
                        'key' => 'subform-sr-9',
                        'prompt' => 'Must have sufficient illumination (open lights during operations) and no busted lights',
                        'metadata' => [
                            'number' => 9, 'level' => 'Standard', 'coverage' => 'Service Reception',
                            'subject' => 'Service Reception Area', 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify all lighting fixtures are operational with no busted bulbs.',
                        ],
                    ],
                ],
            ],
            [
                'key' => 'subform-employee-facilities',
                'title' => 'Employee Facilities c/o WS/Foreman/Leadman',
                'items' => [
                    [
                        'key' => 'subform-ef-1',
                        'prompt' => "Employees' Restroom (Maintained clean and must have the proper amenities for convenience of use i.e. soap, water supply, tissue, etc.)",
                        'metadata' => [
                            'number' => 1, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Inspect employee restroom cleanliness, soap, water, and tissue.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-2',
                        'prompt' => 'Technician Locker Room and Shower are adjacent with each other',
                        'metadata' => [
                            'number' => 2, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify technician locker room and shower are adjacent.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-3',
                        'prompt' => "Sufficient no. of technicians' lockers",
                        'metadata' => [
                            'number' => 3, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify sufficient lockers allocated for all technicians.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-4',
                        'prompt' => 'Technician Locker Room has sufficient no. of tables and benches',
                        'metadata' => [
                            'number' => 4, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Check adequacy of tables and seating in locker room.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-5',
                        'prompt' => 'Technician Locker Room walls and flooring must have proper paint',
                        'metadata' => [
                            'number' => 5, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Inspect condition of paint on walls and flooring.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-6',
                        'prompt' => 'Technician Locker Room has proper lighting and ventilation',
                        'metadata' => [
                            'number' => 6, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Inspect lighting and ventilation operational status.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-7',
                        'prompt' => 'Technician Shower Room has sufficient no. of showers, urinals, and toilet cubicle',
                        'metadata' => [
                            'number' => 7, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Count and check function of showers, urinals, cubicles.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-8',
                        'prompt' => 'Technician Shower Room has clean toilets bowls with flush, bidet, tissue and soap',
                        'metadata' => [
                            'number' => 8, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Check amenities in shower room toilets.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-9',
                        'prompt' => 'Technician shower and toilets are completely functional',
                        'metadata' => [
                            'number' => 9, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Test all fixtures for water flow, drainage, and flushing.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-10',
                        'prompt' => 'Technician waiting area (Near the Job Controller room for efficient job order dispatch)',
                        'metadata' => [
                            'number' => 10, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify location is near JC room for dispatch.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-11',
                        'prompt' => 'Technician waiting area (Sufficient benches)',
                        'metadata' => [
                            'number' => 11, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify benches are sufficient for technicians on standby.',
                        ],
                    ],
                    [
                        'key' => 'subform-ef-12',
                        'prompt' => 'Technician handwash booth (Adequate supply of water) (separate booth is optional)',
                        'metadata' => [
                            'number' => 12, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Employee Facilities', 'checker' => 'WS SUP', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify water supply and cleanliness at handwash station.',
                        ],
                    ],
                ],
            ],
            [
                'key' => 'subform-meeting-room',
                'title' => 'Meeting Room c/o ASM',
                'items' => [
                    [
                        'key' => 'subform-mr-1',
                        'prompt' => 'Allocated Meeting/ Conference Room especially for online trainings',
                        'metadata' => [
                            'number' => 1, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Meeting Room', 'checker' => 'ASM', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify designated meeting/conference room exists.',
                        ],
                    ],
                    [
                        'key' => 'subform-mr-2',
                        'prompt' => 'Available projector and PC/laptop (to be used for online trainings)',
                        'metadata' => [
                            'number' => 2, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Meeting Room', 'checker' => 'ASM', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Check presence and functionality of projector/laptop.',
                        ],
                    ],
                    [
                        'key' => 'subform-mr-3',
                        'prompt' => 'Available Wi-Fi (Internet Connection = 10mbps)',
                        'metadata' => [
                            'number' => 3, 'level' => 'Standard', 'coverage' => 'Facilities',
                            'subject' => 'Meeting Room', 'checker' => 'ASM', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Run speed test to verify minimum 10mbps connection.',
                        ],
                    ],
                ],
            ],
            [
                'key' => 'subform-mitsubishi-quick-service',
                'title' => 'Mitsubishi Quick Service (MQS) c/o WS',
                'items' => [
                    [
                        'key' => 'subform-mqs-1',
                        'prompt' => 'Dedicated MQS bay with complete MQS basic and advanced tools',
                        'metadata' => [
                            'number' => 1, 'level' => 'Standard', 'coverage' => 'Repair Order Processing and Quality of Work',
                            'subject' => 'Mitsubishi Quick Service', 'checker' => 'WS', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'GM',
                            'how_to_check' => 'Verify dedicated MQS bay has complete basic and advanced tool sets.',
                        ],
                    ],
                    [
                        'key' => 'subform-mqs-2',
                        'prompt' => 'Proper execution of MQS sequence',
                        'metadata' => [
                            'number' => 2, 'level' => 'Standard', 'coverage' => 'Repair Order Processing and Quality of Work',
                            'subject' => 'Mitsubishi Quick Service', 'checker' => 'WS', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'GM',
                            'how_to_check' => 'Observe technicians conducting standard MQS sequence.',
                        ],
                    ],
                    [
                        'key' => 'subform-mqs-3',
                        'prompt' => 'Check 1 sample of MQS vehicle if within prescribed time',
                        'metadata' => [
                            'number' => 3, 'level' => 'Standard', 'coverage' => 'Repair Order Processing and Quality of Work',
                            'subject' => 'Mitsubishi Quick Service', 'checker' => 'WS', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'GM',
                            'how_to_check' => 'Sample 1 MQS job to ensure adherence to promised delivery duration.',
                        ],
                    ],
                    [
                        'key' => 'subform-mqs-4',
                        'prompt' => 'MQS technician must be provided with complete QS uniforms',
                        'metadata' => [
                            'number' => 4, 'level' => 'Standard', 'coverage' => 'Repair Order Processing and Quality of Work',
                            'subject' => 'Mitsubishi Quick Service', 'checker' => 'WS', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'GM',
                            'how_to_check' => 'Inspect MQS technician uniforms.',
                        ],
                    ],
                ],
            ],
            [
                'key' => 'subform-customers-lounge',
                'title' => "Customer's Lounge c/o CE",
                'items' => [
                    [
                        'key' => 'subform-cl-1',
                        'prompt' => 'Sofas must be sufficient, comfortable, and maintained in good condition (Refer to MMPC corporate Visual Identity (VI) manual for the color)',
                        'metadata' => [
                            'number' => 1, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Inspect lounge sofas for condition, comfort, and MMPC VI color.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-2',
                        'prompt' => 'Room temperature must be minimum of 25°C; temperature must be displayed through a thermometer',
                        'metadata' => [
                            'number' => 2, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify room thermometer reads at least 25°C.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-3',
                        'prompt' => 'Must have sufficient illumination (open lights during operations) and no busted lights',
                        'metadata' => [
                            'number' => 3, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify all lighting fixtures are operational with no busted bulbs.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-4',
                        'prompt' => 'Must offer at least three kinds of complimentary beverage (water, coffee, and juice) and at least one kind of snack',
                        'metadata' => [
                            'number' => 4, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm 3 beverage varieties and at least 1 snack available.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-5',
                        'prompt' => 'Television must have media player or cable channels',
                        'metadata' => [
                            'number' => 5, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm television has working media player or cable channels.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-6',
                        'prompt' => "There's an available Wi-Fi with a speed of at least 10 Mbps when measured using speed test (Measuring tool: https://www.speedtest.net/)",
                        'metadata' => [
                            'number' => 6, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Perform speed test and ensure ≥10 Mbps speed.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-7',
                        'prompt' => 'There are available power outlets for mobile phone, tablet, and laptop',
                        'metadata' => [
                            'number' => 7, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Inspect availability and function of charging outlets.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-8',
                        'prompt' => 'Service customer lounge must observe 5S at all times',
                        'metadata' => [
                            'number' => 8, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify customer lounge complies with 5S cleanliness.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-9',
                        'prompt' => "Customer restroom's cleanliness is maintained at all times, and with updated maintenance monitoring sheet (clean, no foul odor, etc.)",
                        'metadata' => [
                            'number' => 9, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Check customer restroom hygiene and log sheet.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-10',
                        'prompt' => 'Customer restroom must have complete amenities (Minimum requirements: clean water supply, toilet bowl, sink, urinal, bidet, trash cans, air freshener and no foul odor, tissue, paper towel or hand dryer, hand wash soap, and hand sanitizer)',
                        'metadata' => [
                            'number' => 10, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify all required restroom amenities are stocked.',
                        ],
                    ],
                    [
                        'key' => 'subform-cl-11',
                        'prompt' => 'Signages must be clearly displayed and follows the latest VI design: “Customer Lounge”, “Complimentary Wi-Fi”, “Complimentary Beverages and Snacks”, “Charging Station”, “Customer Restroom”',
                        'metadata' => [
                            'number' => 11, 'level' => 'Standard', 'coverage' => 'Customer Care and Communication',
                            'subject' => "Customers' Lounge", 'checker' => 'CE SERVICE', 'pic' => 'GM',
                            'bom_task' => 'follow up action plan and monitor compliance',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify all required directional and amenity signages.',
                        ],
                    ],
                ],
            ],
        ];

        $this->createSectionsAndItems($template, $sections);
    }

    private function seedDocumentationTemplate(): void
    {
        $template = ChecklistTemplate::query()->firstOrCreate([
            'slug' => 'dealer-operations-standards-documentation',
        ], [
            'name' => 'Dealer Operations Standards - Documentation',
            'description' => 'FY2025 Aftersales Standards Compliance Audit Documentation Sheet (17 Standards).',
            'version' => 1,
            'settings' => [
                'validation_mode' => 'dos_documentation',
                'response_options' => ['yes', 'no', 'na'],
                'instructions' => 'Audit service documents (Rationalized Checksheet, Repair Order, Service Invoice) across multiple customers.',
                'prerequisite_cascade' => true,
                'multi_customer' => true,
                'default_customer_count' => 3,
                'short_name' => 'DOS Documentation',
                'time_slots' => [],
            ],
            'is_active' => true,
        ]);

        if (! $template->wasRecentlyCreated && $template->sections()->exists()) {
            return;
        }

        $sections = [
            [
                'key' => 'doc-rationalized-checksheet',
                'title' => 'Rationalized Checksheet',
                'items' => [
                    [
                        'key' => 'doc-rc-1',
                        'prompt' => 'Uses latest Rationalized Checksheet (5k or 10k)',
                        'metadata' => [
                            'number' => 1, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify rationalized checksheet revision used',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify current version 5k or 10k checksheet is attached.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-2',
                        'prompt' => 'Complete Name and Plate Number',
                        'metadata' => [
                            'number' => 2, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Check vehicle and customer details completeness',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify customer full name and vehicle plate number are written.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-3',
                        'prompt' => 'PMS checklist is properly filled-out',
                        'metadata' => [
                            'number' => 3, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Check completeness of PMS line items',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify all PMS checklist items are checked/accomplished.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-4',
                        'prompt' => 'Safety checklist is properly filled-out',
                        'metadata' => [
                            'number' => 4, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Check safety inspection items completeness',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify safety inspection checklist is filled out completely.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-5',
                        'prompt' => 'Carwash checklist is properly filled-out',
                        'metadata' => [
                            'number' => 5, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify carwash inspection sheet',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify carwash completion check is recorded.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-6',
                        'prompt' => 'Final walk-around inspection checklist is properly filled-out',
                        'metadata' => [
                            'number' => 6, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Check final walk-around checklist',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm final walk-around inspection section is completed.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-7',
                        'prompt' => '10pts. Service Advisor Checklist is properly filled-out',
                        'metadata' => [
                            'number' => 7, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Check 10-point SA checklist',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Verify all 10 points in the SA checklist are accomplished.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-8',
                        'prompt' => "With SA' Signature",
                        'metadata' => [
                            'number' => 8, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify Service Advisor signature',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm SA signed the checksheet.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-9',
                        'prompt' => "With Technician's signature",
                        'metadata' => [
                            'number' => 9, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify Technician signature',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm attending technician signed the checksheet.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-10',
                        'prompt' => "With Leadman's signature",
                        'metadata' => [
                            'number' => 10, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify Leadman signature',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm Leadman/Foreman signature is present.',
                        ],
                    ],
                    [
                        'key' => 'doc-rc-11',
                        'prompt' => "With customer's signature",
                        'metadata' => [
                            'number' => 11, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify customer signature on reception',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm customer signature acknowledging the checksheet.',
                        ],
                    ],
                ],
            ],
            [
                'key' => 'doc-repair-order',
                'title' => 'Repair Order',
                'items' => [
                    [
                        'key' => 'doc-ro-1',
                        'prompt' => 'Complete customer and vehicle details',
                        'metadata' => [
                            'number' => 12, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Check RO header details completeness',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm customer name, contact, VIN, plate number, mileage on RO.',
                        ],
                    ],
                    [
                        'key' => 'doc-ro-2',
                        'prompt' => 'Promised time of delivery is indicated',
                        'metadata' => [
                            'number' => 13, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify promised delivery time entry',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm promised delivery date and time are clearly written on RO.',
                        ],
                    ],
                    [
                        'key' => 'doc-ro-3',
                        'prompt' => "With Customer's signature",
                        'metadata' => [
                            'number' => 14, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify customer authorization signature',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm customer signature authorizing the repair order.',
                        ],
                    ],
                ],
            ],
            [
                'key' => 'doc-service-invoice',
                'title' => 'Service Invoice',
                'items' => [
                    [
                        'key' => 'doc-si-1',
                        'prompt' => 'Date/time actual repair time is indicated',
                        'metadata' => [
                            'number' => 15, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Check actual repair time notation',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm actual date and time repair concluded is recorded on invoice.',
                        ],
                    ],
                    [
                        'key' => 'doc-si-2',
                        'prompt' => "Customer's and SA's signature",
                        'metadata' => [
                            'number' => 16, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Verify release signatures',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm both customer and SA signed upon vehicle release.',
                        ],
                    ],
                    [
                        'key' => 'doc-si-3',
                        'prompt' => 'Next PMS Schedule is indicated with MM360c App booking code',
                        'metadata' => [
                            'number' => 17, 'level' => 'Standard', 'coverage' => 'Repair Order Completion and Invoicing',
                            'subject' => 'Service Documents', 'checker' => 'CE SERVICE', 'pic' => 'CE SERVICE',
                            'bom_task' => 'Check next PMS notation and MM360c booking code',
                            'escalation' => 'AS BRAND HEAD',
                            'how_to_check' => 'Confirm next PMS schedule and MM360c booking code are noted on invoice.',
                        ],
                    ],
                ],
            ],
        ];

        $this->createSectionsAndItems($template, $sections);
    }

    private function createSectionsAndItems(ChecklistTemplate $template, array $sections): void
    {
        foreach ($sections as $sectionOrder => $sectionData) {
            $section = ChecklistSection::query()->firstOrCreate([
                'checklist_template_id' => $template->id,
                'key' => $sectionData['key'],
            ], [
                'title' => $sectionData['title'],
                'sort_order' => $sectionOrder,
                'metadata' => ['code' => $sectionData['key']],
                'is_active' => true,
            ]);

            foreach ($sectionData['items'] as $itemOrder => $itemData) {
                ChecklistItem::query()->firstOrCreate([
                    'checklist_template_id' => $template->id,
                    'key' => $itemData['key'],
                ], [
                    'checklist_section_id' => $section->id,
                    'prompt' => $itemData['prompt'],
                    'sort_order' => $itemOrder,
                    'metadata' => $itemData['metadata'] ?? null,
                    'is_active' => true,
                ]);
            }
        }
    }
};
