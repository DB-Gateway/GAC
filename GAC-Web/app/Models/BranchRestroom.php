<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class BranchRestroom extends Model
{
    use HasFactory;

    public const AREA_CUSTOMER = 'customer';
    public const AREA_OFFICE = 'office';

    protected $fillable = [
        'branch',
        'name',
        'area_type',
        'has_male',
        'has_female',
        'has_pwd',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'has_male' => 'boolean',
            'has_female' => 'boolean',
            'has_pwd' => 'boolean',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function submissions(): HasMany
    {
        return $this->hasMany(ChecklistSubmission::class, 'branch_restroom_id');
    }

    public function isCustomerArea(): bool
    {
        return $this->area_type === self::AREA_CUSTOMER;
    }

    public function isOfficeArea(): bool
    {
        return $this->area_type === self::AREA_OFFICE;
    }

    public function areaLabel(): string
    {
        return match ($this->area_type) {
            self::AREA_OFFICE => 'Office Restroom',
            default => 'Customer Area Restroom',
        };
    }

    /**
     * @return list<string>
     */
    public function enabledGenders(): array
    {
        $genders = [];
        if ($this->has_male) {
            $genders[] = 'male';
        }
        if ($this->has_female) {
            $genders[] = 'female';
        }
        if ($this->has_pwd && $this->isCustomerArea()) {
            $genders[] = 'pwd';
        }
        return $genders;
    }

    public static function genderLabel(string $gender): string
    {
        return match (strtolower(trim($gender))) {
            'male' => 'Male',
            'female' => 'Female',
            'pwd' => 'PWD',
            default => ucfirst($gender),
        };
    }

    public function slugForGender(string $gender): string
    {
        return "restroom-{$this->id}-{$gender}";
    }

    public function titleForGender(string $gender): string
    {
        return "{$this->name} - " . self::genderLabel($gender);
    }

    public static function ensureDefaultsForBranch(string $branch): Collection
    {
        $branch = trim($branch);
        if ($branch === '') {
            return new Collection();
        }

        $existing = static::query()
            ->whereRaw('LOWER(TRIM(branch)) = ?', [Str::lower($branch)])
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        if ($existing->isNotEmpty()) {
            return $existing;
        }

        $customer = static::create([
            'branch' => $branch,
            'name' => 'Customer Area Restroom',
            'area_type' => self::AREA_CUSTOMER,
            'has_male' => true,
            'has_female' => true,
            'has_pwd' => true,
            'is_active' => true,
            'sort_order' => 1,
        ]);

        $office = static::create([
            'branch' => $branch,
            'name' => 'Office Restroom',
            'area_type' => self::AREA_OFFICE,
            'has_male' => true,
            'has_female' => true,
            'has_pwd' => false,
            'is_active' => true,
            'sort_order' => 2,
        ]);

        return new Collection([$customer, $office]);
    }

    public static function forBranch(?string $branch, bool $onlyActive = true): Collection
    {
        $branch = trim((string) $branch);
        if ($branch === '') {
            $query = static::query();
            if ($onlyActive) {
                $query->where('is_active', true);
            }
            $all = $query->orderBy('sort_order')->orderBy('id')->get();
            if ($all->isNotEmpty()) {
                return $all;
            }
            return static::ensureDefaultsForBranch('Pasong Tamo');
        }

        $restrooms = static::ensureDefaultsForBranch($branch);
        if ($onlyActive) {
            return $restrooms->where('is_active', true)->values();
        }
        return $restrooms;
    }
}
