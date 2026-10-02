<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChecklistTemplate extends Model
{
    use HasFactory;

    protected $fillable = [
        'slug',
        'name',
        'description',
        'version',
        'settings',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'version' => 'integer',
            'settings' => 'array',
            'is_active' => 'boolean',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'slug';
    }

    public function resolveRouteBinding($value, $field = null)
    {
        $resolved = parent::resolveRouteBinding($value, $field);
        if ($resolved !== null) {
            return $resolved;
        }

        $strValue = strtolower(trim((string) $value));
        if ($strValue === 'utilities') {
            return parent::resolveRouteBinding('restroom', $field);
        }

        if (preg_match('/^restroom-(\d+)-(male|female|pwd)$/i', trim((string) $value), $matches)) {
            $restroomId = (int) $matches[1];
            $gender = strtolower($matches[2]);
            $baseTemplate = parent::resolveRouteBinding('restroom', $field);
            if ($baseTemplate !== null) {
                $restroom = BranchRestroom::find($restroomId);
                if ($restroom !== null) {
                    $template = clone $baseTemplate;
                    $template->id = $baseTemplate->id;
                    $template->slug = (string) $value;
                    $template->name = $restroom->titleForGender($gender);
                    $settings = is_array($template->settings) ? $template->settings : [];
                    $settings['restroom_id'] = $restroom->id;
                    $settings['restroom_name'] = $restroom->name;
                    $settings['restroom_area'] = $restroom->area_type;
                    $settings['restroom_gender'] = $gender;
                    $settings['time_slots'] = [
                        ['key' => '08:00', 'label' => '8 AM'],
                        ['key' => '11:00', 'label' => '11 AM'],
                        ['key' => '13:00', 'label' => '1 PM'],
                        ['key' => '16:00', 'label' => '4 PM'],
                    ];
                    $template->settings = $settings;

                    return $template;
                }
            }
        }

        return null;
    }

    public function sections(): HasMany
    {
        return $this->hasMany(ChecklistSection::class)->orderBy('sort_order');
    }

    public function items(): HasMany
    {
        return $this->hasMany(ChecklistItem::class)->orderBy('sort_order');
    }

    public function submissions(): HasMany
    {
        return $this->hasMany(ChecklistSubmission::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(Report::class);
    }

    /**
     * Limit already-loaded DOS sections/items to the authenticated operational
     * role. Administrators, BOMs, and PIC accounts retain their existing view.
     */
    public function retainAccessibleItemsFor(User $user): static
    {
        if (! $user->canAccessChecklist($this->slug)) {
            $this->setRelation('sections', collect());

            return $this;
        }

        if (! $user->hasChecklistItemRestrictions($this->slug)
            || ! $this->relationLoaded('sections')) {
            return $this;
        }

        $sections = $this->sections
            ->map(function (ChecklistSection $section) use ($user): ChecklistSection {
                if ($section->relationLoaded('items')) {
                    $section->setRelation(
                        'items',
                        $section->items
                            ->filter(fn (ChecklistItem $item): bool => $user->canAccessChecklistItem(
                                $this->slug,
                                data_get($item->metadata, 'checker')
                            ))
                            ->values()
                    );
                }

                return $section;
            })
            ->filter(fn (ChecklistSection $section): bool => ! $section->relationLoaded('items')
                || $section->items->isNotEmpty())
            ->values();

        $this->setRelation('sections', $sections);

        return $this;
    }
}
