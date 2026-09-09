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
            'bom' => 'BOM',
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
            'as_brand_head' => 'AS Brand Head',
            'as_head' => 'AS Head',
            'brand_head' => 'Brand Head',
        ];
    }

    /**
     * Limit the dashboard dropdown to the recipients found in the applicable
     * FY25 source workbook. Other reporting screens retain the full union so
     * historical assignments remain editable.
     *
     * @return array<string, string>
     */
    public static function escalationTargetOptionsFor(?string $templateSlug): array
    {
        $keys = match (mb_strtolower(trim((string) $templateSlug))) {
            'dealer-operations-standards-sales' => [
                'bom',
                'ce_central',
                'central_admin',
                'dnd',
                'general_manager',
                'general_manager_ce_central',
                'inventory',
                'it',
                'logistic',
                'marketing',
                'marketing_purchasing',
                'marketing_property_management',
                'mmpc_cs_team',
                'mmpc_training_team',
                'n_a',
                'property_management',
                'purchasing',
            ],
            'dealer-operations-standards' => [
                'as_brand_head',
                'as_head',
                'brand_head',
                'ce_central',
                'general_manager',
            ],
            default => array_keys(self::escalationTargetOptions()),
        };

        $options = self::escalationTargetOptions();
        $filtered = [];

        foreach ($keys as $key) {
            if (isset($options[$key])) {
                $filtered[$key] = $options[$key];
            }
        }

        return $filtered;
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
