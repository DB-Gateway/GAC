<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class DealerChecklistSetting extends Model
{
    use HasFactory;

    public const CATEGORY_DOS_SALES = 'dos_sales';

    public const CATEGORY_DOS_AFTERSALES = 'dos_aftersales';

    public const CATEGORY_5S_SALES = 'five_s_sales';

    public const CATEGORY_5S_SERVICE = 'five_s_service';

    public const CATEGORY_5S_UTILITY = 'five_s_utility';

    /** @var array<string, array{label: string, slugs: list<string>}> */
    public const CATEGORIES = [
        self::CATEGORY_DOS_SALES => [
            'label' => 'DOS - Sales',
            'slugs' => ['dealer-operations-standards-sales'],
        ],
        self::CATEGORY_DOS_AFTERSALES => [
            'label' => 'DOS - Aftersales',
            'slugs' => [
                'dealer-operations-standards',
                'dealer-operations-standards-subform',
                'dealer-operations-standards-documentation',
            ],
        ],
        self::CATEGORY_5S_SALES => [
            'label' => '5S - Sales',
            'slugs' => ['sales'],
        ],
        self::CATEGORY_5S_SERVICE => [
            'label' => '5S - Service',
            'slugs' => ['service'],
        ],
        self::CATEGORY_5S_UTILITY => [
            'label' => '5S - Utility',
            'slugs' => ['restroom', 'utilities'],
        ],
    ];

    protected $fillable = [
        'dealer',
        'category',
        'is_enabled',
        'updated_by_user_id',
    ];

    protected function casts(): array
    {
        return [
            'is_enabled' => 'boolean',
        ];
    }

    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by_user_id');
    }

    public static function categoryForSlug(string $slug): ?string
    {
        $normalized = match (Str::lower(trim($slug))) {
            'dos-sales', 'dealer-operations-sales' => 'dealer-operations-standards-sales',
            'dos', 'dealer-operations', 'aftersales' => 'dealer-operations-standards',
            'dos-subform', 'subform' => 'dealer-operations-standards-subform',
            'dos-documentation', 'documentation' => 'dealer-operations-standards-documentation',
            '5s', 'gateway-5s' => 'sales',
            'utilities' => 'restroom',
            default => Str::lower(trim($slug)),
        };

        foreach (self::CATEGORIES as $key => $category) {
            if (in_array($normalized, $category['slugs'], true)) {
                return $key;
            }
        }

        return null;
    }

    public static function isChecklistEnabled(?string $dealer, string $slug): bool
    {
        $dealer = trim((string) $dealer);
        $category = self::categoryForSlug($slug);

        if ($dealer === '' || $category === null) {
            return false;
        }

        $setting = static::query()
            ->whereRaw('LOWER(TRIM(dealer)) = ?', [Str::lower($dealer)])
            ->where('category', $category)
            ->first();

        // Existing dealers remain fully available until an administrator
        // explicitly switches a category off.
        return $setting?->is_enabled ?? true;
    }
}
