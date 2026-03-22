-- Streaks table: tracks daily streaks per user
create table if not exists public.streaks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  last_completed_date date, -- the most recent date a task was completed
  freeze_days_used int not null default 0, -- resets monthly
  freeze_days_reset_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint streaks_user_id_unique unique (user_id)
);

-- Enable RLS
alter table public.streaks enable row level security;

-- Users can only read/update their own streak
create policy "Users can view own streak"
  on public.streaks for select
  using (auth.uid() = user_id);

create policy "Users can update own streak"
  on public.streaks for update
  using (auth.uid() = user_id);

create policy "Users can insert own streak"
  on public.streaks for insert
  with check (auth.uid() = user_id);

-- Milestone badges table
create table if not exists public.streak_milestones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  milestone int not null, -- 7, 30, 100, 365
  achieved_at timestamptz not null default now(),
  constraint streak_milestones_unique unique (user_id, milestone)
);

alter table public.streak_milestones enable row level security;

create policy "Users can view own milestones"
  on public.streak_milestones for select
  using (auth.uid() = user_id);

create policy "Users can insert own milestones"
  on public.streak_milestones for insert
  with check (auth.uid() = user_id);

-- RPC: record_streak — called after task completion, handles streak logic server-side
create or replace function public.record_streak(p_user_id uuid)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_streak record;
  v_today date := current_date;
  v_yesterday date := current_date - 1;
  v_new_current int;
  v_new_longest int;
  v_new_milestones int[] := '{}';
  v_milestone int;
begin
  -- Upsert streak row
  insert into public.streaks (user_id, current_streak, longest_streak, last_completed_date)
  values (p_user_id, 0, 0, null)
  on conflict (user_id) do nothing;

  select * into v_streak from public.streaks where user_id = p_user_id for update;

  -- Already completed today — no change
  if v_streak.last_completed_date = v_today then
    return jsonb_build_object(
      'current_streak', v_streak.current_streak,
      'longest_streak', v_streak.longest_streak,
      'new_milestones', '[]'::jsonb
    );
  end if;

  -- Streak continues (yesterday or first ever)
  if v_streak.last_completed_date = v_yesterday or v_streak.last_completed_date is null then
    v_new_current := v_streak.current_streak + 1;
  else
    -- Streak broken — restart at 1
    v_new_current := 1;
  end if;

  v_new_longest := greatest(v_streak.longest_streak, v_new_current);

  update public.streaks
  set current_streak = v_new_current,
      longest_streak = v_new_longest,
      last_completed_date = v_today,
      updated_at = now()
  where user_id = p_user_id;

  -- Check milestones
  foreach v_milestone in array array[7, 30, 100, 365] loop
    if v_new_current >= v_milestone then
      insert into public.streak_milestones (user_id, milestone)
      values (p_user_id, v_milestone)
      on conflict (user_id, milestone) do nothing;
      if found then
        v_new_milestones := v_new_milestones || v_milestone;
      end if;
    end if;
  end loop;

  return jsonb_build_object(
    'current_streak', v_new_current,
    'longest_streak', v_new_longest,
    'new_milestones', to_jsonb(v_new_milestones)
  );
end;
$$;

-- RPC: use_streak_freeze — pauses streak for one day
create or replace function public.use_streak_freeze(p_user_id uuid, p_is_premium boolean default false)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_streak record;
  v_max_freezes int := case when p_is_premium then 999 else 2 end;
  v_today date := current_date;
begin
  select * into v_streak from public.streaks where user_id = p_user_id for update;
  if v_streak is null then
    return jsonb_build_object('success', false, 'reason', 'no_streak');
  end if;

  -- Reset monthly counter if needed
  if v_streak.freeze_days_reset_at < date_trunc('month', now()) then
    update public.streaks
    set freeze_days_used = 0, freeze_days_reset_at = now()
    where user_id = p_user_id;
    v_streak.freeze_days_used := 0;
  end if;

  if v_streak.freeze_days_used >= v_max_freezes then
    return jsonb_build_object('success', false, 'reason', 'no_freezes_left');
  end if;

  -- Freeze: set last_completed_date to today so tomorrow continues the streak
  update public.streaks
  set last_completed_date = v_today,
      freeze_days_used = freeze_days_used + 1,
      updated_at = now()
  where user_id = p_user_id;

  return jsonb_build_object(
    'success', true,
    'freezes_remaining', v_max_freezes - v_streak.freeze_days_used - 1
  );
end;
$$;
