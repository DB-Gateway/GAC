<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\BranchPicSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BranchPicSeederTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'gac.seeded_pic_accounts.email_domain' => 'pic.gateway.test',
            'gac.seeded_pic_accounts.initial_password' => 'Test-only-PIC-password!',
        ]);
    }

    public function test_seeder_idempotently_creates_two_assigned_active_pics_for_each_unique_branch(): void
    {
        $branches = config('gac.branches');

        $this->assertCount(49, $branches);
        $this->assertCount(49, collect($branches)->unique(fn (string $branch): string => strtolower(trim($branch))));
        $this->assertContains('Iligian', $branches);

        $this->seed(BranchPicSeeder::class);
        $firstPasswordHash = User::where('email', 'makati.utilities@pic.gateway.test')
            ->firstOrFail()
            ->password;
        $this->seed(BranchPicSeeder::class);

        $assignedPics = User::query()
            ->where('user_type', User::ROLE_PERSON_IN_CHARGE)
            ->whereNotNull('pic_assignment_type')
            ->get();

        $this->assertCount(98, $assignedPics);
        $this->assertSame($firstPasswordHash, User::where('email', 'makati.utilities@pic.gateway.test')->firstOrFail()->password);

        foreach ($branches as $branch) {
            $branchPics = $assignedPics->where('branch', $branch);

            $this->assertCount(2, $branchPics, "Expected two assigned PICs for {$branch}.");
            $this->assertSame(
                [User::PIC_ASSIGNMENT_SALES_SERVICE, User::PIC_ASSIGNMENT_UTILITIES],
                $branchPics->pluck('pic_assignment_type')->sort()->values()->all()
            );
            $this->assertTrue($branchPics->every(fn (User $user): bool => $user->account_status === 'active'));
        }
    }

    public function test_seeder_reuses_an_active_legacy_pic_for_sales_service_without_resetting_password(): void
    {
        $legacy = User::factory()->create([
            'name' => 'Existing Pasong Tamo PIC',
            'email' => 'pic@gateway.com',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => null,
            'account_status' => 'active',
        ]);
        $passwordHash = $legacy->password;

        $this->seed(BranchPicSeeder::class);

        $legacy->refresh();
        $this->assertSame(User::PIC_ASSIGNMENT_SALES_SERVICE, $legacy->pic_assignment_type);
        $this->assertSame($passwordHash, $legacy->password);
        $this->assertSame('Existing Pasong Tamo PIC', $legacy->name);
        $this->assertSame('pic@gateway.com', $legacy->email);
        $this->assertSame('active', $legacy->account_status);
        $this->assertDatabaseMissing('users', [
            'email' => 'pasong-tamo.sales-service@pic.gateway.test',
        ]);
        $this->assertSame(98, User::whereNotNull('pic_assignment_type')->count());
    }
}
