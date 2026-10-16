-- هوای ایران: راه‌اندازی دیتابیس تبلیغات
-- 1) در Supabase > SQL Editor اجرا کن.
-- 2) بعد از ساخت کاربر ادمین در Authentication > Users، UUID او را در سیاست‌های پایین جایگزین ADMIN_USER_UUID کن.
-- 3) فقط anon/publishable key را در supabase-config.js قرار بده؛ هرگز service_role key را داخل سایت نگذار.

create table if not exists public.ads (
  position text primary key check (position in ('top','middle','bottom')),
  image_url text not null check (image_url ~* '^https?://'),
  target_url text not null check (target_url ~* '^https?://'),
  label text not null default '' check (char_length(label) <= 100),
  alt_text text not null default 'بنر تبلیغاتی' check (char_length(alt_text) <= 200),
  updated_at timestamptz not null default now()
);

alter table public.ads enable row level security;

drop policy if exists "Anyone can view ads" on public.ads;
create policy "Anyone can view ads"
on public.ads for select
to anon, authenticated
using (true);

drop policy if exists "Only admin can insert ads" on public.ads;
create policy "Only admin can insert ads"
on public.ads for insert
to authenticated
with check (auth.uid() = 'ADMIN_USER_UUID'::uuid);

drop policy if exists "Only admin can update ads" on public.ads;
create policy "Only admin can update ads"
on public.ads for update
to authenticated
using (auth.uid() = 'ADMIN_USER_UUID'::uuid)
with check (auth.uid() = 'ADMIN_USER_UUID'::uuid);

drop policy if exists "Only admin can delete ads" on public.ads;
create policy "Only admin can delete ads"
on public.ads for delete
to authenticated
using (auth.uid() = 'ADMIN_USER_UUID'::uuid);

grant select on public.ads to anon, authenticated;
grant insert, update, delete on public.ads to authenticated;
