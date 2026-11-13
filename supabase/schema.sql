-- Le Dépanneur : à coller dans Supabase > SQL Editor > Run (une seule fois).

-- Profil d'abonnement (essai de 7 jours créé automatiquement à l'inscription)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users on delete cascade,
  trial_start timestamptz not null default now(),
  paid_until timestamptz
);
alter table public.profiles enable row level security;
create policy "profil: lecture perso" on public.profiles for select using (auth.uid() = user_id);
-- TEST SEULEMENT : permet le paiement simulé. À retirer avec le vrai paiement Google Play.
create policy "profil: maj perso (test)" on public.profiles for update using (auth.uid() = user_id);

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (user_id) values (new.id) on conflict do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Professionnels et entreprises
create table if not exists public.pros (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users on delete cascade,
  type text not null check (type in ('person','company')),
  name text not null,
  trade text not null,
  phone text not null,
  address text not null default '',
  description text not null default '',
  photo_url text not null default '',
  id_doc_path text not null default '',
  lat double precision not null,
  lng double precision not null,
  created_at timestamptz not null default now()
);
alter table public.pros enable row level security;
create policy "pros: lecture (connecté)" on public.pros for select to authenticated using (true);
create policy "pros: ajout perso" on public.pros for insert to authenticated with check (owner_id = auth.uid());
create policy "pros: suppression perso" on public.pros for delete to authenticated using (owner_id = auth.uid());

-- Stockage : photos publiques, pièces d'identité privées (visibles seulement par leur propriétaire)
insert into storage.buckets (id, name, public) values ('photos', 'photos', true) on conflict do nothing;
insert into storage.buckets (id, name, public) values ('ids', 'ids', false) on conflict do nothing;

create policy "photos: envoi dans son dossier" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "ids: envoi dans son dossier" on storage.objects for insert to authenticated
  with check (bucket_id = 'ids' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "ids: lecture perso" on storage.objects for select to authenticated
  using (bucket_id = 'ids' and (storage.foldername(name))[1] = auth.uid()::text);
