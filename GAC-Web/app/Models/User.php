<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    public const ROLE_ADMINISTRATOR = 'ADMIN';

    public const ROLE_BRANCH_OPERATIONS_MANAGER = 'BOM';

    public const ROLE_5S_UTILITIES = '5S_UTILITIES';

    public const ROLE_5S_SERVICE = '5S_SERVICE';

    public const ROLE_5S_SALES = '5S_SALES';

    public const ROLE_PERSON_IN_CHARGE = 'PIC';

    public const ROLE_SALES_MANAGER = 'SALES_MANAGER';

    public const ROLE_AFTERSALES_MANAGER = 'ASM';

    public const ROLE_CE_SERVICE = 'CE SERVICE';

    public const ROLE_JOB_CONTROLLER = 'JOB CONTROLLER';

    public const ROLE_PARTS_SUPERVISOR = 'PARTS SUPERVISOR';

    public const ROLE_WORKSHOP_SUPERVISOR = 'WORKSHOP SUP';

    public const ROLE_WORKSHOP = 'WORKSHOP';

    public const ROLE_PURCHASING = 'PURCHASING';

    public const ROLE_PROPERTY_MANAGEMENT = 'PROPERTY_MANAGEMENT';

    public const ROLE_INVENTORY = 'INVENTORY';

    public const PIC_ASSIGNMENT_UTILITIES = 'utilities';

    public const PIC_ASSIGNMENT_SALES_SERVICE = 'sales_service';

    private const PIC_ASSIGNMENT_CHECKLISTS = [
        self::PIC_ASSIGNMENT_UTILITIES => ['restroom'],
        self::PIC_ASSIGNMENT_SALES_SERVICE => ['sales', 'service'],
    ];

    private const DOS_ROLE_CHECKLISTS = [
        self::ROLE_SALES_MANAGER => ['dealer-operations-standards-sales'],
        self::ROLE_AFTERSALES_MANAGER => ['dealer-operations-standards'],
        self::ROLE_CE_SERVICE => ['dealer-operations-standards'],
        self::ROLE_JOB_CONTROLLER => ['dealer-operations-standards'],
        self::ROLE_PARTS_SUPERVISOR => ['dealer-operations-standards'],
        self::ROLE_WORKSHOP_SUPERVISOR => ['dealer-operations-standards'],
        self::ROLE_WORKSHOP => ['dealer-operations-standards'],
    ];

    protected $fillable = [
        'name',
        'email',
        'branch',
        'user_type',
        'pic_assignment_type',
        'account_status',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'avatar_path',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function checklistSubmissions(): HasMany
    {
        return $this->hasMany(ChecklistSubmission::class);
    }

    public function submittedChecklists(): HasMany
    {
        return $this->hasMany(ChecklistSubmission::class, 'submitted_by_user_id');
    }

    public function generatedReports(): HasMany
    {
        return $this->hasMany(Report::class, 'generated_by_user_id');
    }

    /**
     * Canonical roles used by forms and filters.
     *
     * @return array<string, string>
     */
    public static function roleOptions(): array
    {
        return [
            self::ROLE_5S_UTILITIES => '5S Utilities',
            self::ROLE_5S_SERVICE => '5S Service',
            self::ROLE_5S_SALES => '5S Sales',
            self::ROLE_SALES_MANAGER => 'Sales Manager',
            self::ROLE_AFTERSALES_MANAGER => 'Aftersales Manager',
            self::ROLE_CE_SERVICE => 'Customer Experience (CE) Service',
            self::ROLE_JOB_CONTROLLER => 'Job Controller',
            self::ROLE_PARTS_SUPERVISOR => 'Parts Supervisor',
            self::ROLE_WORKSHOP_SUPERVISOR => 'Workshop Supervisor',
            self::ROLE_WORKSHOP => 'Workshop',
            self::ROLE_PURCHASING => 'Purchasing',
            self::ROLE_PROPERTY_MANAGEMENT => 'Property Management',
            self::ROLE_INVENTORY => 'Inventory',
            self::ROLE_PERSON_IN_CHARGE => 'Person In Charge',
            self::ROLE_BRANCH_OPERATIONS_MANAGER => 'Branch Operations Manager',
            self::ROLE_ADMINISTRATOR => 'Compliance Administrator',
        ];
    }

    /**
     * Accepted values include historical records so existing accounts keep working.
     *
     * @return list<string>
     */
    public static function acceptedRoleValues(): array
    {
        return [
            ...array_keys(self::roleOptions()),
            ...array_values(self::roleOptions()),
            'PIC',
            'Person In Charge',
            'Administrator',
            'GAC Administrator',
            'Gateway Administrator',
            'GM',
            'General Manager',
            'SM',
            'Sales_Manager',
            'Sales Mgr',
            'Aftersales_Manager',
            'AS Mgr',
            'CE',
            'CE_Service',
            'JC',
            'Job_Controller',
            'Parts',
            'Parts_Supervisor',
            'WS SUP',
            'WS.SUP',
            'Workshop_Sup',
            'Worshop Sup',
            'WS',
            'Purchasing Team',
            'PM',
            'Property Management',
            'Property_Management',
            'Property Management (PM)',
            'PM (Property Management)',
            'Property Mgmt',
            // Historical names accepted only so old accounts are migrated.
            'Purchasing Manager',
            'Purchasing_Manager',
            'Purchasing Manager (PM)',
            'PM (Purchasing Manager)',
            'Purchasing Mgr',
            'Inventory Team',
            '5S Utilities',
            '5S_Utilities',
            '5S-Utilities',
            '5S Service',
            '5S_Service',
            '5S-Service',
            '5S Sales',
            '5S_Sales',
            '5S-Sales',
            'Utilities',
            'Utility',
            'Restroom',
        ];
    }

    public static function roleCodeFor(?string $role): string
    {
        return match (strtolower(trim((string) $role))) {
            'admin', 'administrator', 'compliance administrator', 'gac administrator',
            'gateway administrator', 'gm', 'general manager' => self::ROLE_ADMINISTRATOR,
            'bom', 'branch operations manager' => self::ROLE_BRANCH_OPERATIONS_MANAGER,
            '5s_utilities', '5s utilities', '5s-utilities', 'utilities', 'utility', 'restroom' => self::ROLE_5S_UTILITIES,
            '5s_service', '5s service', '5s-service', 'service 5s' => self::ROLE_5S_SERVICE,
            '5s_sales', '5s sales', '5s-sales', 'sales 5s' => self::ROLE_5S_SALES,
            'pic', 'person in charge' => self::ROLE_PERSON_IN_CHARGE,
            'sm', 'sales manager', 'sales_manager', 'sales mgr' => self::ROLE_SALES_MANAGER,
            'asm', 'aftersales manager', 'aftersales_manager', 'as mgr' => self::ROLE_AFTERSALES_MANAGER,
            'ce', 'ce service', 'ce_service', 'customer experience service',
            'customer experience (ce) service' => self::ROLE_CE_SERVICE,
            'jc', 'job controller', 'job_controller' => self::ROLE_JOB_CONTROLLER,
            'parts', 'part supervisor', 'parts supervisor', 'parts_supervisor',
            'part supervisor/analys', 'parts supervisor/analys',
            'part supervisor/analyst', 'parts supervisor/analyst' => self::ROLE_PARTS_SUPERVISOR,
            'ws sup', 'ws.sup', 'workshop sup', 'workshop_sup', 'workshop supervisor',
            'worshop sup', 'worshop supervisor' => self::ROLE_WORKSHOP_SUPERVISOR,
            'ws', 'workshop' => self::ROLE_WORKSHOP,
            'purchasing', 'purchasing team', 'purchasing_team' => self::ROLE_PURCHASING,
            'pm', 'property management', 'property_management', 'property management (pm)',
            'pm (property management)', 'property mgmt',
            'purchasing manager', 'purchasing_manager', 'purchasing manager (pm)',
            'pm (purchasing manager)',
            'purchasing mgr' => self::ROLE_PROPERTY_MANAGEMENT,
            'inventory', 'inventory team', 'inventory_team' => self::ROLE_INVENTORY,
            default => strtoupper(trim((string) $role)),
        };
    }

    public static function roleLabelFor(?string $role): string
    {
        $normalizedRole = self::roleCodeFor($role);

        return self::roleOptions()[$normalizedRole] ?? (trim((string) $role) ?: 'Gateway User');
    }

    public function roleCode(): string
    {
        return self::roleCodeFor($this->user_type);
    }

    public function roleLabel(): string
    {
        return self::roleLabelFor($this->user_type);
    }

    /**
     * @return array<string, string>
     */
    public static function picAssignmentOptions(): array
    {
        return [
            self::PIC_ASSIGNMENT_UTILITIES => 'Utilities',
            self::PIC_ASSIGNMENT_SALES_SERVICE => 'Sales & Service',
        ];
    }

    public static function picAssignmentTypeFor(?string $assignment): ?string
    {
        return match (strtolower(trim((string) $assignment))) {
            'utilities', 'utility' => self::PIC_ASSIGNMENT_UTILITIES,
            'sales_service', 'sales-service', 'sales & service', 'sales and service' => self::PIC_ASSIGNMENT_SALES_SERVICE,
            default => null,
        };
    }

    public static function picAssignmentLabelFor(?string $assignment): ?string
    {
        $type = self::picAssignmentTypeFor($assignment);

        return $type === null ? null : self::picAssignmentOptions()[$type];
    }

    public function picAssignmentType(): ?string
    {
        if ($this->roleCode() !== self::ROLE_PERSON_IN_CHARGE) {
            return null;
        }

        return self::picAssignmentTypeFor($this->pic_assignment_type);
    }

    public function picAssignmentLabel(): ?string
    {
        return self::picAssignmentLabelFor($this->picAssignmentType());
    }

    /**
     * Null means unrestricted for an explicitly privileged role. An empty
     * list deliberately fails closed for unassigned PIC and unknown roles.
     *
     * @return list<string>|null
     */
    public function allowedChecklistSlugs(): ?array
    {
        $role = $this->roleCode();

        if ($role === self::ROLE_5S_UTILITIES) {
            return ['restroom', 'utilities'];
        }

        if ($role === self::ROLE_5S_SERVICE) {
            return ['service'];
        }

        if ($role === self::ROLE_5S_SALES) {
            return ['sales'];
        }

        if ($role === self::ROLE_PERSON_IN_CHARGE) {
            return self::PIC_ASSIGNMENT_CHECKLISTS[$this->picAssignmentType()] ?? [];
        }

        if (array_key_exists($role, self::DOS_ROLE_CHECKLISTS)) {
            return self::DOS_ROLE_CHECKLISTS[$role];
        }

        return in_array($role, [
            self::ROLE_ADMINISTRATOR,
            self::ROLE_BRANCH_OPERATIONS_MANAGER,
        ], true) ? null : [];
    }

    public function isDosOperationalRole(): bool
    {
        return array_key_exists($this->roleCode(), self::DOS_ROLE_CHECKLISTS);
    }

    public function hasChecklistItemRestrictions(string $slug): bool
    {
        $normalized = $this->normalizedChecklistSlug($slug);

        return $this->isDosOperationalRole()
            && (in_array($normalized, $this->allowedChecklistSlugs() ?? [], true)
                || in_array($normalized, [
                    'dealer-operations-standards-subform',
                    'dealer-operations-standards-documentation',
                ], true));
    }

    public function canAccessChecklistItem(string $slug, ?string $checker): bool
    {
        if (! $this->canAccessChecklist($slug)) {
            return false;
        }

        if (! $this->hasChecklistItemRestrictions($slug)) {
            return true;
        }

        $normalizedSlug = $this->normalizedChecklistSlug($slug);
        $role = $this->roleCode();

        if ($role === self::ROLE_AFTERSALES_MANAGER && in_array($normalizedSlug, [
            'dealer-operations-standards-subform',
            'dealer-operations-standards-documentation',
        ], true)) {
            return true;
        }

        if ($role === self::ROLE_WORKSHOP && $normalizedSlug === 'dealer-operations-standards-subform') {
            $checkerCode = self::roleCodeFor($checker);

            return in_array($checkerCode, [self::ROLE_WORKSHOP, self::ROLE_WORKSHOP_SUPERVISOR], true);
        }

        return filled($checker) && self::roleCodeFor($checker) === $role;
    }

    public function canAccessChecklist(string $slug): bool
    {
        $normalized = $this->normalizedChecklistSlug($slug);

        $allowed = $this->allowedChecklistSlugs();

        if ($allowed === null
            || in_array($normalized, $allowed, true)
            || in_array($slug, $allowed, true)) {
            return true;
        }

        if ($this->isDosOperationalRole()) {
            $role = $this->roleCode();
            if ($normalized === 'dealer-operations-standards-subform') {
                return in_array($role, [
                    self::ROLE_AFTERSALES_MANAGER,
                    self::ROLE_CE_SERVICE,
                    self::ROLE_WORKSHOP_SUPERVISOR,
                    self::ROLE_WORKSHOP,
                ], true);
            }
            if ($normalized === 'dealer-operations-standards-documentation') {
                return in_array($role, [
                    self::ROLE_AFTERSALES_MANAGER,
                    self::ROLE_CE_SERVICE,
                ], true);
            }
        }

        return false;
    }

    private function normalizedChecklistSlug(string $slug): string
    {
        return match (strtolower(trim($slug))) {
            'utilities' => 'restroom',
            '5s', 'gateway-5s' => 'sales',
            'dos', 'dealer-operations' => 'dealer-operations-standards',
            'dos-sales', 'dealer-operations-sales' => 'dealer-operations-standards-sales',
            'dos-subform', 'subform' => 'dealer-operations-standards-subform',
            'dos-documentation', 'documentation' => 'dealer-operations-standards-documentation',
            default => strtolower(trim($slug)),
        };
    }

    public function hasAdministrativeAccess(): bool
    {
        return $this->roleCode() === self::ROLE_ADMINISTRATOR;
    }

    public function canOverrideChecklistResponses(): bool
    {
        return in_array($this->roleCode(), [
            self::ROLE_ADMINISTRATOR,
            self::ROLE_BRANCH_OPERATIONS_MANAGER,
        ], true);
    }

    public function canOverrideChecklistResponse(ChecklistResponse $response): bool
    {
        if (! $this->canOverrideChecklistResponses()) {
            return false;
        }

        if ($this->hasAdministrativeAccess()) {
            return true;
        }

        $userBranch = trim((string) $this->branch);
        if ($userBranch === '') {
            return false;
        }

        $submission = $response->relationLoaded('submission')
            ? $response->submission
            : $response->submission()->first();

        $submissionBranch = trim((string) ($submission?->branch ?? ''));

        return mb_strtolower($userBranch) === mb_strtolower($submissionBranch);
    }

    public function receivesTaskCompletionNotifications(): bool
    {
        return in_array($this->roleCode(), [
            self::ROLE_ADMINISTRATOR,
            self::ROLE_BRANCH_OPERATIONS_MANAGER,
        ], true);
    }

    public function avatarUrl(): ?string
    {
        return filled($this->avatar_path)
            ? Storage::disk('public')->url($this->avatar_path)
            : null;
    }

    protected static function booted(): void
    {
        static::saving(function (User $user): void {
            $user->pic_assignment_type = $user->roleCode() === self::ROLE_PERSON_IN_CHARGE
                ? self::picAssignmentTypeFor($user->pic_assignment_type)
                : null;
        });
    }
}
