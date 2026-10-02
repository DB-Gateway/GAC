<?php

namespace App\Http\Controllers;

use App\Models\BranchRestroom;
use App\Models\DealerChecklistSetting;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;
use Illuminate\View\View;

class DealerChecklistAccessController extends Controller
{
    private const BRAND_NAMES = [
        'Honda Cars', 'Mitsubishi', 'Suzuki', 'Nissan', 'Toyota',
        'Ford', 'Hyundai', 'Kia', 'Isuzu', 'Mazda', 'GAC',
    ];

    public function index(Request $request): View
    {
        $this->authorizeAdministrator($request);

        $allDealers = $this->dealers();

        foreach ($allDealers as $dealer) {
            BranchRestroom::ensureDefaultsForBranch($dealer);
        }

        $categories = DealerChecklistSetting::CATEGORIES;

        $settings = DealerChecklistSetting::query()
            ->whereIn('dealer', $allDealers)
            ->get()
            ->keyBy(fn (DealerChecklistSetting $setting): string => Str::lower(trim($setting->dealer)).'|'.$setting->category);

        $branchRestrooms = BranchRestroom::query()
            ->whereIn('branch', $allDealers)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->groupBy(fn (BranchRestroom $r): string => Str::lower(trim($r->branch)));

        $branchesByRegion = config('gac.branches_by_region', []);
        $branchRegionMap = [];
        foreach ($branchesByRegion as $regionName => $branchList) {
            foreach ($branchList as $b) {
                $branchRegionMap[Str::lower(trim($b))] = $regionName;
            }
        }

        $dealerRegions = [];
        $dealerBrands = [];
        $dealerStats = [];
        $totalFullyEnabled = 0;
        $totalRestricted = 0;
        $totalDisabled = 0;

        foreach ($allDealers as $dealer) {
            $key = Str::lower(trim($dealer));
            $region = $branchRegionMap[$key] ?? 'Other';
            $dealerRegions[$key] = $region;
            $dealerBrands[$key] = $this->brandForDealer($dealer);

            $enabledCount = 0;
            foreach ($categories as $catKey => $def) {
                $rec = $settings->get($key.'|'.$catKey);
                if ($rec?->is_enabled ?? true) {
                    $enabledCount++;
                }
            }

            if ($enabledCount === count($categories)) {
                $totalFullyEnabled++;
            } elseif ($enabledCount === 0) {
                $totalDisabled++;
            } else {
                $totalRestricted++;
            }

            $dealerStats[$key] = [
                'enabled_count' => $enabledCount,
                'total_categories' => count($categories),
                'restroom_count' => $branchRestrooms->get($key, collect())->count(),
            ];
        }

        $allRestroomsFlat = $branchRestrooms->flatten();
        $stats = [
            'total' => $allDealers->count(),
            'fully_enabled' => $totalFullyEnabled,
            'restricted' => $totalRestricted,
            'disabled' => $totalDisabled,
            'restrooms' => $allRestroomsFlat->count(),
            'customer_restrooms' => $allRestroomsFlat->filter(fn ($r) => $r->isCustomerArea())->count(),
            'office_restrooms' => $allRestroomsFlat->filter(fn ($r) => $r->isOfficeArea())->count(),
        ];

        // Filter dealers
        $search = Str::lower(trim((string) $request->query('search')));
        $regionFilter = trim((string) $request->query('region'));
        $brandFilter = trim((string) $request->query('brand'));
        $statusFilter = trim((string) $request->query('status'));
        $categoryFilter = trim((string) $request->query('category'));
        $restroomFilter = trim((string) $request->query('restroom'));
        $sortFilter = trim((string) $request->query('sort', 'name_asc'));

        $filteredDealers = $allDealers;

        if ($search !== '') {
            $filteredDealers = $filteredDealers->filter(
                fn (string $dealer): bool => str_contains(Str::lower($dealer), $search)
            );
        }

        if ($regionFilter !== '') {
            $filteredDealers = $filteredDealers->filter(function (string $dealer) use ($dealerRegions, $regionFilter): bool {
                $key = Str::lower(trim($dealer));
                return Str::lower($dealerRegions[$key] ?? 'Other') === Str::lower($regionFilter);
            });
        }

        if ($brandFilter !== '') {
            $filteredDealers = $filteredDealers->filter(
                fn (string $dealer): bool => Str::lower($dealerBrands[Str::lower(trim($dealer))] ?? '') === Str::lower($brandFilter)
            );
        }

        if ($statusFilter !== '') {
            $filteredDealers = $filteredDealers->filter(function (string $dealer) use ($dealerStats, $statusFilter, $categories): bool {
                $key = Str::lower(trim($dealer));
                $enabled = $dealerStats[$key]['enabled_count'] ?? 0;
                $total = count($categories);

                return match ($statusFilter) {
                    'fully_enabled' => $enabled === $total,
                    'restricted' => $enabled > 0 && $enabled < $total,
                    'all_disabled' => $enabled === 0,
                    default => true,
                };
            });
        }

        if ($categoryFilter !== '' && isset($categories[$categoryFilter])) {
            $filteredDealers = $filteredDealers->filter(function (string $dealer) use ($settings, $categoryFilter): bool {
                $key = Str::lower(trim($dealer));
                $rec = $settings->get($key.'|'.$categoryFilter);
                return $rec?->is_enabled ?? true;
            });
        }

        if ($restroomFilter !== '') {
            $filteredDealers = $filteredDealers->filter(function (string $dealer) use ($branchRestrooms, $restroomFilter): bool {
                $key = Str::lower(trim($dealer));
                /** @var Collection<int, BranchRestroom> $restrooms */
                $restrooms = $branchRestrooms->get($key, collect());

                return match ($restroomFilter) {
                    'has_restrooms' => $restrooms->isNotEmpty(),
                    'no_restrooms' => $restrooms->isEmpty(),
                    'has_customer' => $restrooms->contains(fn ($r) => $r->isCustomerArea()),
                    'has_office' => $restrooms->contains(fn ($r) => $r->isOfficeArea()),
                    'has_pwd' => $restrooms->contains(fn ($r) => $r->isCustomerArea() && $r->has_pwd),
                    default => true,
                };
            });
        }

        // Sorting
        $sortedDealers = match ($sortFilter) {
            'name_desc' => $filteredDealers->sortByDesc(fn ($d) => Str::lower($d)),
            'restrooms_desc' => $filteredDealers->sortByDesc(function ($d) use ($dealerStats) {
                return $dealerStats[Str::lower(trim($d))]['restroom_count'] ?? 0;
            }),
            'restrooms_asc' => $filteredDealers->sortBy(function ($d) use ($dealerStats) {
                return $dealerStats[Str::lower(trim($d))]['restroom_count'] ?? 0;
            }),
            'active_desc' => $filteredDealers->sortByDesc(function ($d) use ($dealerStats) {
                return $dealerStats[Str::lower(trim($d))]['enabled_count'] ?? 0;
            }),
            default => $filteredDealers->sortBy(fn ($d) => Str::lower($d)),
        };
        $filteredDealers = $sortedDealers->values();

        return view('admin.checklist-access', [
            'dealers' => $filteredDealers,
            'allDealersCount' => $allDealers->count(),
            'categories' => $categories,
            'settings' => $settings,
            'branchRestrooms' => $branchRestrooms,
            'dealerRegions' => $dealerRegions,
            'dealerBrands' => $dealerBrands,
            'brands' => self::BRAND_NAMES,
            'dealerStats' => $dealerStats,
            'stats' => $stats,
            'regions' => array_keys($branchesByRegion),
            'filters' => [
                'search' => $request->query('search', ''),
                'region' => $regionFilter,
                'brand' => $brandFilter,
                'status' => $statusFilter,
                'category' => $categoryFilter,
                'restroom' => $restroomFilter,
                'sort' => $sortFilter,
            ],
        ]);
    }

    public function update(Request $request, string $dealer): RedirectResponse
    {
        $this->authorizeAdministrator($request);
        $dealer = trim(urldecode($dealer));

        abort_unless(
            $this->dealers()->contains(fn (string $known): bool => Str::lower($known) === Str::lower($dealer)),
            404,
            'Dealer / brand was not found.'
        );

        $validated = $request->validate([
            'availability' => ['required', 'array'],
            'availability.*' => ['required', 'boolean'],
            'restrooms' => ['nullable', 'array'],
            'restrooms.*.has_male' => ['nullable', 'boolean'],
            'restrooms.*.has_female' => ['nullable', 'boolean'],
            'restrooms.*.has_pwd' => ['nullable', 'boolean'],
            'restrooms.*.is_active' => ['nullable', 'boolean'],
        ]);

        foreach (DealerChecklistSetting::CATEGORIES as $category => $definition) {
            DealerChecklistSetting::query()->updateOrCreate([
                'dealer' => $dealer,
                'category' => $category,
            ], [
                'is_enabled' => (bool) ($validated['availability'][$category] ?? false),
                'updated_by_user_id' => $request->user()->getKey(),
            ]);
        }

        $utilityEnabled = (bool) ($validated['availability'][DealerChecklistSetting::CATEGORY_5S_UTILITY] ?? false);

        if (! $utilityEnabled) {
            BranchRestroom::query()
                ->whereRaw('LOWER(TRIM(branch)) = ?', [Str::lower($dealer)])
                ->update([
                    'has_male' => false,
                    'has_female' => false,
                    'has_pwd' => false,
                ]);
        } elseif (! empty($validated['restrooms'])) {
            foreach ($validated['restrooms'] as $restroomId => $switches) {
                $restroom = BranchRestroom::where('id', $restroomId)
                    ->whereRaw('LOWER(TRIM(branch)) = ?', [Str::lower($dealer)])
                    ->first();

                if ($restroom) {
                    $isOffice = $restroom->isOfficeArea();
                    $restroom->update([
                        'has_male' => (bool) ($switches['has_male'] ?? false),
                        'has_female' => (bool) ($switches['has_female'] ?? false),
                        'has_pwd' => $isOffice ? false : (bool) ($switches['has_pwd'] ?? false),
                        'is_active' => isset($switches['is_active']) ? (bool) $switches['is_active'] : $restroom->is_active,
                    ]);
                }
            }
        }

        User::query()
            ->whereRaw('LOWER(TRIM(branch)) = ?', [Str::lower($dealer)])
            ->where('account_status', 'active')
            ->get()
            ->filter(fn (User $user): bool => $user->hasAssignedChecklists()
                && ! $user->hasAnyAvailableAssignedChecklist())
            ->each(fn (User $user) => $user->tokens()->delete());

        return back()->with('status', "Checklist availability for {$dealer} was updated.");
    }

    public function storeRestroom(Request $request, string $dealer): RedirectResponse
    {
        $this->authorizeAdministrator($request);
        $dealer = trim(urldecode($dealer));

        abort_unless(
            $this->dealers()->contains(fn (string $known): bool => Str::lower($known) === Str::lower($dealer)),
            404,
            'Dealer / brand was not found.'
        );
        $this->authorizeUtilityConfiguration($dealer);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'area_type' => ['required', 'in:customer,office'],
            'has_male' => ['nullable', 'boolean'],
            'has_female' => ['nullable', 'boolean'],
            'has_pwd' => ['nullable', 'boolean'],
        ]);

        $isOffice = $validated['area_type'] === BranchRestroom::AREA_OFFICE;
        $maxSort = BranchRestroom::whereRaw('LOWER(TRIM(branch)) = ?', [Str::lower($dealer)])->max('sort_order') ?? 0;

        BranchRestroom::create([
            'branch' => $dealer,
            'name' => trim($validated['name']),
            'area_type' => $validated['area_type'],
            'has_male' => (bool) ($validated['has_male'] ?? false),
            'has_female' => (bool) ($validated['has_female'] ?? false),
            'has_pwd' => $isOffice ? false : (bool) ($validated['has_pwd'] ?? false),
            'is_active' => true,
            'sort_order' => $maxSort + 1,
        ]);

        return back()->with('status', "Restroom '{$validated['name']}' was added for {$dealer}.");
    }

    public function updateRestroom(Request $request, string $dealer, BranchRestroom $restroom): RedirectResponse
    {
        $this->authorizeAdministrator($request);
        $dealer = trim(urldecode($dealer));

        abort_unless(
            Str::lower(trim($restroom->branch)) === Str::lower($dealer),
            404,
            'Restroom does not belong to this dealer.'
        );
        $this->authorizeUtilityConfiguration($dealer);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'has_male' => ['nullable', 'boolean'],
            'has_female' => ['nullable', 'boolean'],
            'has_pwd' => ['nullable', 'boolean'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $isOffice = $restroom->isOfficeArea();

        $restroom->update([
            'name' => trim($validated['name']),
            'has_male' => (bool) ($validated['has_male'] ?? false),
            'has_female' => (bool) ($validated['has_female'] ?? false),
            'has_pwd' => $isOffice ? false : (bool) ($validated['has_pwd'] ?? false),
            'is_active' => isset($validated['is_active']) ? (bool) $validated['is_active'] : $restroom->is_active,
        ]);

        return back()->with('status', "Restroom '{$restroom->name}' for {$dealer} was updated.");
    }

    public function destroyRestroom(Request $request, string $dealer, BranchRestroom $restroom): RedirectResponse
    {
        $this->authorizeAdministrator($request);
        $dealer = trim(urldecode($dealer));

        abort_unless(
            Str::lower(trim($restroom->branch)) === Str::lower($dealer),
            404,
            'Restroom does not belong to this dealer.'
        );

        $name = $restroom->name;
        $restroom->delete();

        return back()->with('status', "Restroom '{$name}' for {$dealer} was deleted.");
    }

    private function dealers(): Collection
    {
        return User::query()
            ->whereNotNull('branch')
            ->where('branch', '<>', '')
            ->distinct()
            ->pluck('branch')
            ->merge(config('gac.branches', []))
            ->filter(fn ($dealer): bool => is_string($dealer) && trim($dealer) !== '')
            ->unique(fn (string $dealer): string => Str::lower(trim($dealer)))
            ->sort()
            ->values();
    }

    private function brandForDealer(string $dealer): string
    {
        foreach (self::BRAND_NAMES as $brand) {
            if (Str::startsWith(Str::lower(trim($dealer)), Str::lower($brand).' ')) {
                return $brand;
            }
        }

        return 'Unspecified Brand';
    }

    private function authorizeAdministrator(Request $request): void
    {
        abort_unless(
            $request->user()?->hasAdministrativeAccess() === true,
            403,
            'Only the system administrator can assign checklist availability.'
        );
    }

    private function authorizeUtilityConfiguration(string $dealer): void
    {
        abort_unless(
            DealerChecklistSetting::isChecklistEnabled($dealer, 'restroom'),
            403,
            'Turn on 5S - Utility before configuring restroom types.'
        );
    }
}
