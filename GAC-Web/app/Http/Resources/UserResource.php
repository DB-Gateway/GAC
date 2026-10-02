<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'username' => $this->email,
            // Kept temporarily for older mobile builds that still read `email`.
            'email' => $this->email,
            'branch' => $this->branch,
            'user_type' => $this->user_type,
            'role_label' => $this->roleLabel(),
            'pic_assignment_type' => $this->picAssignmentType(),
            'pic_assignment_label' => $this->picAssignmentLabel(),
            'account_status' => $this->account_status,
            'must_change_password' => (bool) $this->must_change_password,
            'avatar_url' => $this->avatarUrl(),
        ];
    }
}
