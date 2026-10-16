-- Run this SQL once in Supabase SQL Editor before deploying weather-chat.
create table if not exists public.weather_chat_rate_limits (
  ip_hash text primary key,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 1
);

alter table public.weather_chat_rate_limits enable row level security;
revoke all on table public.weather_chat_rate_limits from anon, authenticated;

create or replace function public.take_weather_chat_slot(p_ip_hash text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if p_ip_hash is null or length(p_ip_hash) <> 64 then
    return false;
  end if;

  insert into public.weather_chat_rate_limits (ip_hash, window_started_at, request_count)
  values (p_ip_hash, now(), 1)
  on conflict (ip_hash) do update
  set
    request_count = case
      when public.weather_chat_rate_limits.window_started_at < now() - interval '10 minutes' then 1
      else public.weather_chat_rate_limits.request_count + 1
    end,
    window_started_at = case
      when public.weather_chat_rate_limits.window_started_at < now() - interval '10 minutes' then now()
      else public.weather_chat_rate_limits.window_started_at
    end
  returning request_count into v_count;

  -- Keep the table small; only hashes are stored, never raw IP addresses.
  delete from public.weather_chat_rate_limits
  where window_started_at < now() - interval '2 days';

  return v_count <= 8;
end;
$$;

revoke all on function public.take_weather_chat_slot(text) from public, anon, authenticated;
grant execute on function public.take_weather_chat_slot(text) to service_role;
