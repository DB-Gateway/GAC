<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChecklistResponse extends Model
{
    use HasFactory;

    protected $fillable = [
        'checklist_submission_id',
        'checklist_item_id',
        'item_key',
        'status',
        'remark',
        'finding',
        'action_plan',
        'escalation_target',
        'commitment_date',
        'details',
        'attachment_path',
        'item_snapshot',
    ];

    protected function casts(): array
    {
        return [
            'commitment_date' => 'datetime',
            'details' => 'array',
            'item_snapshot' => 'array',
        ];
    }

    public function submission(): BelongsTo
    {
        return $this->belongsTo(ChecklistSubmission::class, 'checklist_submission_id');
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(ChecklistItem::class, 'checklist_item_id');
    }

    /**
     * @return array<string, string>
     */
    public static function escalationTargetOptions(): array
    {
        return [
            'as_brand_head' => 'AS Brand Head',
            'as_head' => 'AS Head',
            'bom' => 'BOM',
            'brand_head' => 'Brand Head',
            'ce_central' => 'CE Central',
            'central_admin' => 'Central Admin',
            'dnd' => 'DND',
            'general_manager' => 'General Manager (GM)',
            'general_manager_ce_central' => 'General Manager / CE Central',
            'inventory' => 'Inventory',
            'it' => 'IT',
            'logistic' => 'Logistic',
            'marketing' => 'Marketing',
            'marketing_purchasing' => 'Marketing / Purchasing',
            'marketing_property_management' => 'Marketing / Property Management (PM)',
            'mmpc_cs_team' => 'MMPC CS Team',
            'mmpc_training_team' => 'MMPC Training Team',
            'n_a' => 'N/A',
            'property_management' => 'Property Management (PM)',
            'purchasing' => 'Purchasing',
        ];
    }

    /**
     * Designated manager escalation targets across the system.
     * Excludes non-manager teams/departments (e.g. MMPC Training Team, Inventory, Purchasing).
     *
     * @return array<string, string>
     */
    public static function managerEscalationOptions(): array
    {
        return [
            'as_brand_head' => 'AS Brand Head',
            'as_head' => 'AS Head',
            'bom' => 'BOM',
            'brand_head' => 'Brand Head',
            'ce_central' => 'CE Central',
            'central_admin' => 'Central Admin',
            'general_manager' => 'General Manager (GM)',
            'property_management' => 'Property Management (PM)',
        ];
    }

    /**
     * Limit escalation choices strictly to designated managers according to the
     * specific user, checker role, and checklist context.
     *
     * - Utility findings / utility personnel: strictly Property Management (PM) and General Manager (GM).
     * - Sales Standards: strictly managers from Sales sheet (BOM, CE Central, Central Admin, GM, PM).
     * - Aftersales Standards: strictly managers/heads from Aftersales sheet (AS Brand Head, AS Head, Brand Head, CE Central, GM).
     * - Teams (MMPC Training Team, Inventory, Marketing, Purchasing, etc.) are excluded.
     *
     * @return array<string, string>
     */
    public static function escalationTargetOptionsFor(
        ?string $templateSlug = null,
        User|string|null $userOrRole = null,
        ?string $checkerRole = null,
        bool $isRestroom = false
    ): array {
        $normalizedSlug = mb_strtolower(trim((string) $templateSlug));
        $normalizedChecker = mb_strtolower(trim((string) $checkerRole));
        $roleString = $userOrRole instanceof User
            ? $userOrRole->roleCode()
            : mb_strtolower(trim((string) $userOrRole));

        $isUtilityContext = $isRestroom
            || in_array($normalizedSlug, ['restroom', 'utilities'], true)
            || ($userOrRole instanceof User && $userOrRole->isUtility())
            || in_array($roleString, ['5s_utilities', 'utility', 'utilities', 'restroom', mb_strtolower(User::ROLE_5S_UTILITIES)], true)
            || str_contains($normalizedChecker, 'utility');

        if ($isUtilityContext) {
            return [
                'property_management' => self::escalationTargetOptions()['property_management'],
                'general_manager' => self::escalationTargetOptions()['general_manager'],
            ];
        }

        $isSalesStandards = in_array($normalizedSlug, ['dealer-operations-standards-sales', 'dos-sales'], true)
            || in_array($roleString, ['sales_manager', 'sm', mb_strtolower(User::ROLE_SALES_MANAGER)], true)
            || str_contains($normalizedChecker, 'sales manager');

        if ($isSalesStandards) {
            $keys = [
                'bom',
                'ce_central',
                'central_admin',
                'general_manager',
                'property_management',
            ];

            return array_intersect_key(self::escalationTargetOptions(), array_flip($keys));
        }

        $isAftersalesStandards = in_array($normalizedSlug, [
            'dealer-operations-standards',
            'dealer-operations-standards-subform',
            'dealer-operations-standards-documentation',
            'dos',
            'subform',
            'documentation',
        ], true) || in_array($roleString, [
            'asm',
            'aftersales_manager',
            'ce',
            'ce_service',
            'jc',
            'job_controller',
            'parts',
            'parts_supervisor',
            'ws',
            'workshop',
            'workshop_sup',
            'workshop_supervisor',
            mb_strtolower(User::ROLE_AFTERSALES_MANAGER),
            mb_strtolower(User::ROLE_CE_SERVICE),
            mb_strtolower(User::ROLE_JOB_CONTROLLER),
            mb_strtolower(User::ROLE_PARTS_SUPERVISOR),
            mb_strtolower(User::ROLE_WORKSHOP_SUPERVISOR),
        ], true) || str_contains($normalizedChecker, 'asm')
            || str_contains($normalizedChecker, 'ce service')
            || str_contains($normalizedChecker, 'jc')
            || str_contains($normalizedChecker, 'parts')
            || str_contains($normalizedChecker, 'workshop');

        if ($isAftersalesStandards) {
            if (str_contains($normalizedChecker, 'jc')
                || str_contains($normalizedChecker, 'job controller')
                || str_contains($normalizedChecker, 'parts')
                || str_contains($normalizedChecker, 'workshop')
                || in_array($roleString, ['jc', 'job_controller', 'parts', 'parts_supervisor', 'ws', 'workshop', 'workshop_sup', 'workshop_supervisor'], true)) {
                return [
                    'general_manager' => self::escalationTargetOptions()['general_manager'],
                ];
            }

            if (str_contains($normalizedChecker, 'asm')
                || in_array($roleString, ['asm', 'aftersales_manager', mb_strtolower(User::ROLE_AFTERSALES_MANAGER)], true)) {
                $keys = ['as_brand_head', 'as_head', 'ce_central', 'general_manager'];

                return array_intersect_key(self::escalationTargetOptions(), array_flip($keys));
            }

            if (str_contains($normalizedChecker, 'ce service')
                || in_array($roleString, ['ce', 'ce_service', mb_strtolower(User::ROLE_CE_SERVICE)], true)) {
                $keys = ['as_brand_head', 'brand_head', 'ce_central', 'general_manager'];

                return array_intersect_key(self::escalationTargetOptions(), array_flip($keys));
            }

            $keys = [
                'as_brand_head',
                'as_head',
                'brand_head',
                'ce_central',
                'general_manager',
            ];

            return array_intersect_key(self::escalationTargetOptions(), array_flip($keys));
        }

        if (in_array($normalizedSlug, ['sales', 'service', '5s', 'gateway-5s'], true)) {
            $keys = ['bom', 'general_manager', 'property_management'];

            return array_intersect_key(self::escalationTargetOptions(), array_flip($keys));
        }

        return self::managerEscalationOptions();
    }

    /**
     * Helper to resolve allowed escalation manager options from an associative context array.
     *
     * @param array<string, mixed> $context
     * @return array<string, string>
     */
    public static function escalationTargetOptionsForContext(array $context): array
    {
        return self::escalationTargetOptionsFor(
            templateSlug: (string) ($context['template_slug'] ?? $context['template'] ?? ''),
            userOrRole: $context['user'] ?? $context['auditor_role'] ?? $context['auditor'] ?? null,
            checkerRole: (string) ($context['checker_role'] ?? $context['checker'] ?? ''),
            isRestroom: ! empty($context['is_restroom'])
        );
    }

    /**
     * Map of contextual manager options passed to the frontend for dynamic modal population.
     *
     * @return array<string, array<string, string>>
     */
    public static function contextualEscalationOptionsMap(): array
    {
        return [
            'utility' => self::escalationTargetOptionsFor('restroom'),
            'sales' => self::escalationTargetOptionsFor('dealer-operations-standards-sales'),
            'aftersales' => self::escalationTargetOptionsFor('dealer-operations-standards'),
            'aftersales_asm' => self::escalationTargetOptionsFor('dealer-operations-standards', null, 'ASM'),
            'aftersales_ce' => self::escalationTargetOptionsFor('dealer-operations-standards', null, 'CE SERVICE'),
            'aftersales_single_gm' => self::escalationTargetOptionsFor('dealer-operations-standards', null, 'JC'),
            'five_s' => self::escalationTargetOptionsFor('sales'),
            'default' => self::managerEscalationOptions(),
        ];
    }

    public static function normalizeEscalationTarget(mixed $value): mixed
    {
        if ($value === null || (is_string($value) && trim($value) === '')) {
            return null;
        }

        if (! is_string($value)) {
            return $value;
        }

        $value = trim($value);
        $compact = preg_replace('/[^a-z0-9]+/', '', mb_strtolower($value));

        return match ($compact) {
            'bom', 'branchoperationsmanager' => 'bom',
            'cecentral', 'customerexperiencecentral' => 'ce_central',
            'centraladmin', 'centraladministrator' => 'central_admin',
            'dnd' => 'dnd',
            'gm', 'generalmanager', 'generalmanagergm' => 'general_manager',
            'generalmanagercecentral', 'gmcecentral' => 'general_manager_ce_central',
            'purchasing', 'purchasingteam' => 'purchasing',
            'pm', 'propertymanagement', 'propertymanagementpm',
            'pmpropertymanagement', 'propertymgmt', 'purchasingmanager',
            'purchasingmanagerpm', 'pmpurchasingmanager',
            'purchasingmgr' => 'property_management',
            'inventory', 'inventoryteam' => 'inventory',
            'it', 'informationtechnology' => 'it',
            'logistic', 'logistics' => 'logistic',
            'marketing' => 'marketing',
            'marketingpurchasing', 'marketingandpurchasing' => 'marketing_purchasing',
            'marketingpm', 'marketingpropertymanagement', 'marketingpropertymanagementpm',
            'marketingandpropertymanagement' => 'marketing_property_management',
            'mmpccsteam', 'mmpccustomerexperienceteam' => 'mmpc_cs_team',
            'mmpctrainingteam' => 'mmpc_training_team',
            'na', 'notapplicable' => 'n_a',
            'asbrandhead', 'aftersalesbrandhead' => 'as_brand_head',
            'ashead', 'aftersaleshead' => 'as_head',
            'brandhead' => 'brand_head',
            default => $value,
        };
    }

    public function escalationTargetLabel(): ?string
    {
        $target = $this->escalation_target ?? data_get($this->details, 'escalation_target') ?? data_get($this->details, 'escalation');
        if (! $target) {
            return null;
        }

        $target = self::normalizeEscalationTarget($target);

        return self::escalationTargetOptions()[$target] ?? ucwords(str_replace('_', ' ', (string) $target));
    }

    public function isOverridden(): bool
    {
        return is_array(data_get($this->details, 'override'));
    }

    /**
     * @return array<string, mixed>|null
     */
    public function overrideDetails(): ?array
    {
        return data_get($this->details, 'override');
    }
}
