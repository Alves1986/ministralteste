create table public.support_tickets (
  id uuid default gen_random_uuid() primary key,
  organization_id uuid references public.organizations(id) on delete cascade not null,
  author_id uuid references auth.users(id) on delete set null,
  author_name text not null,
  subject text not null,
  description text not null,
  image_url text,
  status text not null default 'open',
  priority text not null default 'normal',
  replies jsonb not null default '[]'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.support_tickets enable row level security;

-- Membros da mesma organização podem ver seus tickets
create policy "Org members can view their org tickets"
on public.support_tickets for select
using (
  organization_id in (
    select om.organization_id from public.organization_ministries om
    join public.ministry_members mm on mm.ministry_id = om.id
    where mm.profile_id = auth.uid()
  )
  or public.is_super_admin()
);

-- Membros autenticados podem criar tickets para sua organização
create policy "Users can insert tickets for their org"
on public.support_tickets for insert
with check (
  author_id = auth.uid()
  or public.is_super_admin()
);

-- Autor do ticket ou super admin pode atualizar
create policy "Author or super admin can update tickets"
on public.support_tickets for update
using (
  author_id = auth.uid()
  or public.is_super_admin()
);

-- Super admin pode deletar tickets
create policy "Super admin can delete tickets"
on public.support_tickets for delete
using (
  public.is_super_admin()
);
