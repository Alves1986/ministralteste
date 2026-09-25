## Table `organizations`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `text` |  |
| `slug` | `text` |  Nullable Unique |
| `active` | `bool` |  Nullable |
| `plan_type` | `text` |  Nullable |
| `billing_status` | `text` |  Nullable |
| `trial_ends_at` | `timestamptz` |  Nullable |
| `checkout_url` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `access_locked` | `bool` |  Nullable |
| `stripe_subscription_id` | `text` |  Nullable |
| `stripe_customer_id` | `text` |  Nullable |
| `logo_url` | `text` |  Nullable |
| `whatsapp_enabled` | `bool` |  Nullable |

## Table `profiles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  Nullable |
| `ministry_id` | `uuid` |  Nullable |
| `name` | `text` |  Nullable |
| `email` | `text` |  Nullable |
| `whatsapp` | `text` |  Nullable |
| `birth_date` | `date` |  Nullable |
| `avatar_url` | `text` |  Nullable |
| `is_admin` | `bool` |  Nullable |
| `is_super_admin` | `bool` |  Nullable |
| `allowed_ministries` | `_uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `organization_ministries`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `code` | `text` |  |
| `label` | `text` |  |
| `availability_start` | `date` |  Nullable |
| `availability_end` | `date` |  Nullable |
| `enabled_tabs` | `_text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `whatsapp_enabled` | `bool` |  Nullable |

## Table `ministry_members`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `ministry_id` | `uuid` |  |
| `profile_id` | `uuid` |  |
| `role` | `text` |  Nullable |
| `functions` | `_text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `ministry_settings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `ministry_id` | `uuid` |  |
| `organization_id` | `uuid` |  |
| `display_name` | `text` |  Nullable |
| `roles` | `_text` |  Nullable |
| `availability_start` | `date` |  Nullable |
| `availability_end` | `date` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `spotify_client_id` | `text` |  Nullable |
| `spotify_client_secret` | `text` |  Nullable |
| `youtube_api_key` | `text` |  Nullable |
| `qr_code_url` | `text` |  Nullable |
| `social_link_url` | `text` |  Nullable |
| `whatsapp_custom_message` | `text` |  Nullable |
| `whatsapp_custom_instructions` | `text` |  Nullable |
| `whatsapp_instructions_updated_at` | `timestamptz` |  Nullable |
| `whatsapp_instructions_updated_by` | `uuid` |  Nullable |
| `practical_guidelines` | `text` |  Nullable |

## Table `invite_tokens`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `token` | `text` |  Unique |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `created_by` | `uuid` |  Nullable |
| `label` | `text` |  Nullable |
| `used` | `bool` |  Nullable |
| `expires_at` | `timestamptz` |  |
| `created_at` | `timestamptz` |  Nullable |

## Table `event_rules`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `title` | `text` |  |
| `type` | `text` |  |
| `weekday` | `int4` |  Nullable |
| `date` | `date` |  Nullable |
| `time` | `time` |  Nullable |
| `active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `schedule_assignments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `event_rule_id` | `uuid` |  |
| `event_date` | `date` |  |
| `role` | `text` |  |
| `member_id` | `uuid` |  Nullable |
| `confirmed` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `event_key` | `text` |  Nullable |

## Table `member_availability`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `user_id` | `uuid` |  |
| `available_date` | `date` |  |
| `note` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `swap_requests`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `requester_id` | `uuid` |  Nullable |
| `requester_name` | `text` |  Nullable |
| `taken_by_id` | `uuid` |  Nullable |
| `role` | `text` |  |
| `event_datetime` | `timestamptz` |  Nullable |
| `event_title` | `text` |  Nullable |
| `status` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `reason` | `text` |  Nullable |
| `origin` | `text` |  Nullable |
| `taken_by_name` | `text` |  Nullable |
| `taken_at` | `timestamptz` |  Nullable |
| `event_rule_id` | `uuid` |  Nullable |
| `event_date` | `date` |  Nullable |

## Table `repertoire_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `title` | `text` |  |
| `link` | `text` |  Nullable |
| `date` | `date` |  Nullable |
| `observation` | `text` |  Nullable |
| `added_by` | `text` |  Nullable |
| `content` | `text` |  Nullable |
| `key` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `event_rule_id` | `uuid` |  Nullable |

## Table `notifications`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `title` | `text` |  |
| `message` | `text` |  Nullable |
| `type` | `text` |  Nullable |
| `action_link` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `notification_reads`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `notification_id` | `uuid` |  |
| `organization_id` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `announcements`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `title` | `text` |  |
| `message` | `text` |  Nullable |
| `type` | `text` |  Nullable |
| `expiration_date` | `date` |  Nullable |
| `author_name` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `is_pinned` | `bool` |  Nullable |

## Table `announcement_interactions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `announcement_id` | `uuid` |  |
| `user_id` | `uuid` |  |
| `organization_id` | `uuid` |  Nullable |
| `interaction_type` | `text` |  |
| `created_at` | `timestamptz` |  Nullable |

## Table `schedule_conflict_rules`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `rule_type` | `text` |  |
| `functions` | `_text` |  |
| `label` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `push_subscriptions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `endpoint` | `text` |  Unique |
| `p256dh` | `text` |  Nullable |
| `auth` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `glory_transactions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `profile_id` | `uuid` |  |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  Nullable |
| `amount` | `int4` |  |
| `type` | `text` |  |
| `description` | `text` |  Nullable |
| `ref_id` | `text` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `glory_balance`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `profile_id` | `uuid` |  |
| `organization_id` | `uuid` |  |
| `balance` | `int4` |  |
| `total_earned` | `int4` |  |
| `updated_at` | `timestamptz` |  |

## Table `whatsapp_settings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `org_id` | `uuid` |  Unique |
| `enabled` | `bool` |  Nullable |
| `send_days_before` | `int4` |  Nullable |
| `send_time` | `time` |  Nullable |
| `ministry_settings` | `jsonb` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `ministry_whatsapp`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `text` |  |
| `instance_name` | `text` |  |
| `phone_number` | `text` |  Nullable |
| `connected` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `stripe_event_log`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `event_id` | `text` | Primary |
| `processed_at` | `timestamptz` |  |

## Table `whatsapp_pending_actions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `type` | `text` |  |
| `member_id` | `uuid` |  |
| `phone` | `text` |  |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `event_date` | `date` |  Nullable |
| `event_rule_id` | `text` |  Nullable |
| `swap_request_id` | `uuid` |  Nullable |
| `role` | `text` |  Nullable |
| `status` | `text` |  |
| `created_at` | `timestamptz` |  |
| `expires_at` | `timestamptz` |  Nullable |

## Table `whatsapp_scheduled_notifications`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `event_rule_id` | `uuid` |  Nullable |
| `event_date` | `date` |  |
| `event_title` | `text` |  Nullable |
| `scheduled_at` | `timestamptz` |  |
| `status` | `text` |  Nullable |
| `created_by` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `event_checkins`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `member_id` | `uuid` |  |
| `event_rule_id` | `uuid` |  |
| `date` | `date` |  |
| `created_at` | `timestamptz` |  |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |

## Table `whatsapp_usage_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  |
| `sent_at` | `timestamptz` |  |
| `instance_name` | `text` |  Nullable |

## Table `super_admin_audit_log`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `action` | `varchar` |  |
| `performed_by` | `uuid` |  |
| `target_id` | `uuid` |  Nullable |
| `details` | `jsonb` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `support_tickets`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `organization_id` | `uuid` |  |
| `author_id` | `uuid` |  Nullable |
| `author_name` | `text` |  |
| `subject` | `text` |  |
| `description` | `text` |  |
| `status` | `text` |  |
| `priority` | `text` |  |
| `replies` | `jsonb` |  |
| `created_at` | `timestamptz` |  |
| `image_url` | `text` |  Nullable |

## Table `ministry_audit_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `created_at` | `timestamptz` |  |
| `organization_id` | `uuid` |  |
| `ministry_id` | `uuid` |  Nullable |
| `actor_id` | `uuid` |  Nullable |
| `actor_name` | `text` |  |
| `action` | `text` |  |
| `target_type` | `text` |  Nullable |
| `target_id` | `text` |  Nullable |
| `target_name` | `text` |  Nullable |
| `metadata` | `jsonb` |  Nullable |

## Table `notification_clears`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `notification_id` | `uuid` |  |
| `organization_id` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `push_reminder_log`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `member_id` | `uuid` |  Nullable |
| `ministry_id` | `uuid` |  Nullable |
| `reminder_type` | `text` |  |
| `reminder_date` | `date` |  |
| `created_at` | `timestamptz` |  Nullable |

## Table `app_config`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `key` | `text` | Primary |
| `value` | `text` |  Nullable |

## RLS Policies

### `invite_tokens`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Allow anon read valid invites` | SELECT | anon | PERMISSIVE | `((used = false) AND (expires_at > now()))` | — |
| `invite_insert_auth` | INSERT | public | PERMISSIVE | — | `((organization_id = get_my_org_id()) OR is_super_admin())` |
| `invite_read_public` | SELECT | public | PERMISSIVE | `((used = false) AND (expires_at > now()))` | — |
| `invite_update_auth` | UPDATE | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |

### `ministry_whatsapp`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Enable all for admins` | ALL | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.organization_id = ministry_whatsapp.organization_id) AND ((profiles.is_admin = true) OR (profiles.is_super_admin = true)))))` | `(EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.organization_id = ministry_whatsapp.organization_id) AND ((profiles.is_admin = true) OR (profiles.is_super_admin = true)))))` |
| `Enable read for org members` | SELECT | authenticated | PERMISSIVE | `(organization_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid())))` | — |

### `whatsapp_settings`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Enable read access for authenticated users in same org` | SELECT | authenticated | PERMISSIVE | `(org_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid())))` | — |
| `Enable update/insert for admins` | ALL | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.organization_id = whatsapp_settings.org_id) AND ((profiles.is_admin = true) OR (profiles.is_super_admin = true)))))` | `(EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.organization_id = whatsapp_settings.org_id) AND ((profiles.is_admin = true) OR (profiles.is_super_admin = true)))))` |

### `repertoire_items`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Permitir acesso total a repertoire_items` | ALL | public | PERMISSIVE | `true` | — |
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |

### `schedule_assignments`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Permitir acesso total a schedule_assignments` | ALL | public | PERMISSIVE | `true` | — |
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |
| `Members can update schedule assignments in their org` | UPDATE | public | PERMISSIVE | `((auth.uid() IS NOT NULL) AND (organization_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))))` | `((auth.uid() IS NOT NULL) AND (organization_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))))` |

### `event_checkins`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Permitir leitura de check-ins pelos membros do mesmo ministéri` | SELECT | public | PERMISSIVE | `(EXISTS ( SELECT 1    FROM ministry_members   WHERE ((ministry_members.ministry_id = event_checkins.ministry_id) AND (ministry_members.profile_id = auth.uid()))))` | — |
| `Permitir que membros insiram seus próprios check-ins` | INSERT | public | PERMISSIVE | — | `(auth.uid() = member_id)` |

### `push_subscriptions`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Service role can read all subscriptions` | SELECT | service_role | PERMISSIVE | `true` | — |
| `Users can manage their own subscriptions` | ALL | public | PERMISSIVE | `(auth.uid() = user_id)` | `(auth.uid() = user_id)` |
| `push_insert` | INSERT | public | PERMISSIVE | — | `(user_id = auth.uid())` |
| `push_own` | ALL | public | PERMISSIVE | `(user_id = auth.uid())` | — |
| `push_own_insert` | INSERT | public | PERMISSIVE | — | `(user_id = auth.uid())` |
| `push_own_select` | SELECT | public | PERMISSIVE | `(user_id = auth.uid())` | — |
| `push_own_update` | UPDATE | public | PERMISSIVE | `(user_id = auth.uid())` | — |
| `push_service` | ALL | public | PERMISSIVE | `(auth.role() = 'service_role'::text)` | — |
| `push_service_role` | ALL | public | PERMISSIVE | `(auth.role() = 'service_role'::text)` | — |
| `push_subscriptions_own_select` | SELECT | public | PERMISSIVE | `(auth.uid() = user_id)` | — |
| `push_subscriptions_own_insert` | INSERT | public | PERMISSIVE | — | `(auth.uid() = user_id)` |
| `push_subscriptions_own_update` | UPDATE | public | PERMISSIVE | `(auth.uid() = user_id)` | — |
| `push_subscriptions_own_delete` | DELETE | public | PERMISSIVE | `(auth.uid() = user_id)` | — |

### `whatsapp_scheduled_notifications`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Service role full access` | ALL | service_role | PERMISSIVE | `true` | `true` |
| `Users can manage their org notifications` | ALL | public | PERMISSIVE | `(organization_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid())))` | `(organization_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid())))` |

### `notifications`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |

### `schedule_conflict_rules`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `conflict_rules_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |

### `event_rules`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `event_rules_access` | ALL | public | PERMISSIVE | `(organization_id = ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid())))` | `(organization_id = ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid())))` |
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |

### `glory_balance`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `glory_balance_admin` | ALL | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.organization_id = glory_balance.organization_id) AND ((profiles.is_admin = true) OR (profiles.is_super_admin = true)))))` | — |
| `glory_balance_own` | SELECT | authenticated | PERMISSIVE | `(profile_id = auth.uid())` | — |

### `glory_transactions`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `glory_transactions_admin` | ALL | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.organization_id = glory_transactions.organization_id) AND ((profiles.is_admin = true) OR (profiles.is_super_admin = true)))))` | — |
| `glory_transactions_own` | SELECT | authenticated | PERMISSIVE | `(profile_id = auth.uid())` | — |

### `ministry_members`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `ministry_members_access` | ALL | public | PERMISSIVE | `((EXISTS ( SELECT 1    FROM organization_ministries om   WHERE ((om.id = ministry_members.ministry_id) AND (om.organization_id = get_my_org_id())))) OR is_super_admin())` | — |
| `Permitir leitura de ministry_members para usuarios autenticados` | SELECT | public | PERMISSIVE | `(auth.role() = 'authenticated'::text)` | — |
| `Super admins podem ver ministry_members` | SELECT | public | PERMISSIVE | `is_super_admin()` | — |
| `Super admins podem deletar ministry_members` | DELETE | public | PERMISSIVE | `is_super_admin()` | — |

### `announcement_interactions`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |

### `announcements`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |

### `member_availability`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |

### `ministry_settings`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |
| `Permitir leitura de ministry_settings para usuarios autenticado` | SELECT | public | PERMISSIVE | `(auth.role() = 'authenticated'::text)` | — |
| `Permitir leitura de ministry_settings` | SELECT | public | PERMISSIVE | `(is_super_admin() OR (organization_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))))` | — |

### `notification_reads`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |
| `notification_reads_own_all` | ALL | authenticated | PERMISSIVE | `(auth.uid() = user_id)` | `(auth.uid() = user_id)` |

### `swap_requests`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `org_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |
| `Members can update swap requests in their org` | UPDATE | public | PERMISSIVE | `((auth.uid() IS NOT NULL) AND (organization_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))))` | `((auth.uid() IS NOT NULL) AND (organization_id IN ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))))` |

### `organization_ministries`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `org_ministries_access` | ALL | public | PERMISSIVE | `((organization_id = get_my_org_id()) OR is_super_admin())` | — |
| `Permitir leitura de organization_ministries para usuarios auten` | SELECT | public | PERMISSIVE | `(auth.role() = 'authenticated'::text)` | — |
| `Super admins podem ver todos os ministries` | SELECT | public | PERMISSIVE | `is_super_admin()` | — |
| `Super admins podem atualizar ministries` | UPDATE | public | PERMISSIVE | `is_super_admin()` | — |
| `Super admins podem deletar ministries` | DELETE | public | PERMISSIVE | `is_super_admin()` | — |

### `organizations`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `organizations_access` | ALL | public | PERMISSIVE | `((id = get_my_org_id()) OR is_super_admin())` | — |
| `Permitir leitura de organizations para usuarios autenticados` | SELECT | public | PERMISSIVE | `(auth.role() = 'authenticated'::text)` | — |
| `Super admins podem ver todas as organizations` | SELECT | public | PERMISSIVE | `is_super_admin()` | — |
| `Super admins podem atualizar organizations` | UPDATE | public | PERMISSIVE | `is_super_admin()` | — |
| `Super admins podem deletar organizations` | DELETE | public | PERMISSIVE | `is_super_admin()` | — |
| `Super admins podem criar organizations` | INSERT | public | PERMISSIVE | — | `is_super_admin()` |

### `profiles`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `profiles_access` | ALL | public | PERMISSIVE | `((auth.uid() = id) OR (organization_id = get_my_org_id()) OR is_super_admin())` | — |
| `Permitir leitura de profiles para usuarios autenticados` | SELECT | public | PERMISSIVE | `(auth.role() = 'authenticated'::text)` | — |
| `Super admins podem ver todos os profiles` | SELECT | public | PERMISSIVE | `is_super_admin()` | — |
| `Super admins podem atualizar profiles` | UPDATE | public | PERMISSIVE | `is_super_admin()` | — |
| `Super admins podem deletar profiles` | DELETE | public | PERMISSIVE | `is_super_admin()` | — |

### `stripe_event_log`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `service_role only` | ALL | public | PERMISSIVE | `(auth.role() = 'service_role'::text)` | — |

### `whatsapp_usage_logs`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `whatsapp_usage_logs_insert` | INSERT | public | PERMISSIVE | — | `true` |
| `whatsapp_usage_logs_view` | SELECT | public | PERMISSIVE | `(EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.is_super_admin = true))))` | — |
| `Super admins podem ver os logs de uso do whatsapp` | SELECT | authenticated | PERMISSIVE | `(is_super_admin() = true)` | — |

### `super_admin_audit_log`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `select_super_admin_audit_log` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.is_super_admin = true))))` | — |
| `insert_super_admin_audit_log` | INSERT | authenticated | PERMISSIVE | — | `(performed_by = auth.uid())` |

### `notification_clears`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `notification_clears_own_all` | ALL | authenticated | PERMISSIVE | `(auth.uid() = user_id)` | `(auth.uid() = user_id)` |

### `push_reminder_log`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `push_reminder_log_no_user_access` | ALL | service_role | PERMISSIVE | `true` | `true` |

### `ministry_audit_logs`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Admins podem ver logs de auditoria da sua org` | SELECT | authenticated | PERMISSIVE | `((organization_id = ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))) AND ((EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND ((profiles.is_admin = true) OR (profiles.is_super_admin = true))))) OR (EXISTS ( SELECT 1    FROM ministry_members   WHERE ((ministry_members.profile_id = auth.uid()) AND (ministry_members.ministry_id = ministry_audit_logs.ministry_id) AND (ministry_members.role = 'admin'::text))))))` | — |
| `Super admins podem ver todos os logs de auditoria` | SELECT | authenticated | PERMISSIVE | `(is_super_admin() = true)` | — |
| `Admins podem inserir logs de auditoria` | INSERT | authenticated | PERMISSIVE | — | `((EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND ((profiles.is_admin = true) OR (profiles.is_super_admin = true))))) OR (EXISTS ( SELECT 1    FROM ministry_members   WHERE ((ministry_members.profile_id = auth.uid()) AND (ministry_members.ministry_id = ministry_audit_logs.ministry_id) AND (ministry_members.role = 'admin'::text)))))` |
| `Super admins podem ver audit logs` | SELECT | public | PERMISSIVE | `is_super_admin()` | — |

### `support_tickets`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Membros podem ler tickets da sua org` | SELECT | authenticated | PERMISSIVE | `((organization_id = ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))) OR is_super_admin())` | — |
| `Membros podem abrir tickets da sua org` | INSERT | authenticated | PERMISSIVE | — | `((organization_id = ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))) AND (author_id = auth.uid()))` |
| `Admin da org pode atualizar tickets` | UPDATE | authenticated | PERMISSIVE | `(((organization_id = ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))) AND (EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.is_admin = true) AND (profiles.is_super_admin = false))))) OR is_super_admin())` | `((organization_id = ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))) OR is_super_admin())` |
| `Admin da org pode deletar tickets` | DELETE | authenticated | PERMISSIVE | `(((organization_id = ( SELECT profiles.organization_id    FROM profiles   WHERE (profiles.id = auth.uid()))) AND (EXISTS ( SELECT 1    FROM profiles   WHERE ((profiles.id = auth.uid()) AND (profiles.is_admin = true) AND (profiles.is_super_admin = false))))) OR is_super_admin())` | — |

