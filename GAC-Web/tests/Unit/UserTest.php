<?php

namespace Tests\Unit;

use App\Models\User;
use Tests\TestCase;

class UserTest extends TestCase
{
    public function test_name_with_role_formats_plain_user_name_with_role(): void
    {
        $user = new User([
            'name' => 'Marcus Sales',
            'user_type' => User::ROLE_SALES_MANAGER,
        ]);

        $this->assertSame('Marcus Sales (Sales Manager)', $user->nameWithRole());
    }

    public function test_name_with_role_avoids_duplicate_when_name_already_has_role_in_parentheses(): void
    {
        $user = new User([
            'name' => 'Marcus Sales (Sales Manager)',
            'user_type' => User::ROLE_SALES_MANAGER,
        ]);

        $this->assertSame('Marcus Sales (Sales Manager)', $user->nameWithRole());
    }

    public function test_name_with_role_avoids_duplicate_when_name_is_same_as_role(): void
    {
        $user = new User([
            'name' => '5S Utilities',
            'user_type' => User::ROLE_5S_UTILITIES,
        ]);

        $this->assertSame('5S Utilities', $user->nameWithRole());
    }

    public function test_name_with_role_avoids_duplicate_when_name_contains_role(): void
    {
        $user = new User([
            'name' => 'SUZUKI PASONG TAMO 5S Utilities',
            'user_type' => User::ROLE_5S_UTILITIES,
        ]);

        $this->assertSame('SUZUKI PASONG TAMO 5S Utilities', $user->nameWithRole());
    }

    public function test_name_with_role_appends_role_when_name_is_different(): void
    {
        $user = new User([
            'name' => 'General Manager',
            'user_type' => User::ROLE_ADMINISTRATOR,
        ]);

        $this->assertSame('General Manager (System Administrator)', $user->nameWithRole());
    }

    public function test_username_for_uses_role_brand_and_branch_format(): void
    {
        $this->assertSame(
            'BOM.MitsubishiSucat',
            User::usernameFor(User::ROLE_BRANCH_OPERATIONS_MANAGER, 'MITSUBISHI SUCAT')
        );
        $this->assertSame(
            '5SUtilities.MitsubishiSucat',
            User::usernameFor(User::ROLE_5S_UTILITIES, 'MITSUBISHI SUCAT')
        );
        $this->assertSame(
            'GM.SuzukiPasongTamo',
            User::usernameFor(User::ROLE_GENERAL_MANAGER, 'SUZUKI PASONG TAMO', name: 'General Manager')
        );
    }
}
