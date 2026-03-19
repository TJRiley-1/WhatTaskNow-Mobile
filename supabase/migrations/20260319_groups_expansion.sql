-- Groups Expansion Phase 1: Event Driven Groups + F&F Leaderboard Enhancements

-- ============================================================
-- 1. Alter `groups` table
-- ============================================================
ALTER TABLE groups ADD COLUMN group_type text NOT NULL DEFAULT 'friends_family';
ALTER TABLE groups ADD COLUMN event_date timestamptz;
ALTER TABLE groups ADD COLUMN leaderboard_period text NOT NULL DEFAULT 'weekly';
ALTER TABLE groups ADD COLUMN leaderboard_metric text NOT NULL DEFAULT 'points';

-- ============================================================
-- 2. Alter `group_members` table
-- ============================================================
ALTER TABLE group_members ADD COLUMN role text NOT NULL DEFAULT 'member';
ALTER TABLE group_members ADD COLUMN allow_task_assignment boolean;

-- Set existing group creators as admins
UPDATE group_members gm
SET role = 'admin'
FROM groups g
WHERE gm.group_id = g.id
  AND gm.user_id = g.created_by;

-- ============================================================
-- 3. New `group_tasks` table
-- ============================================================
CREATE TABLE group_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  type text NOT NULL DEFAULT 'other',
  time int NOT NULL DEFAULT 15,
  social text NOT NULL DEFAULT 'low',
  energy text NOT NULL DEFAULT 'low',
  due_date date,
  status text NOT NULL DEFAULT 'unassigned',
  created_by uuid NOT NULL REFERENCES auth.users(id),
  assigned_to uuid REFERENCES auth.users(id),
  claimed_at timestamptz,
  completed_at timestamptz,
  synced_task_id uuid REFERENCES tasks(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_group_tasks_group_id ON group_tasks(group_id);
CREATE INDEX idx_group_tasks_assigned_to ON group_tasks(assigned_to);
CREATE INDEX idx_group_tasks_status ON group_tasks(status);

-- ============================================================
-- 4. Add group columns to `tasks` table
-- ============================================================
ALTER TABLE tasks ADD COLUMN group_task_id uuid REFERENCES group_tasks(id) ON DELETE SET NULL;
ALTER TABLE tasks ADD COLUMN group_id uuid REFERENCES groups(id) ON DELETE SET NULL;
ALTER TABLE tasks ADD COLUMN group_name text;

-- ============================================================
-- 5. RLS policies for `group_tasks`
-- ============================================================
ALTER TABLE group_tasks ENABLE ROW LEVEL SECURITY;

-- Members can view tasks in their groups
CREATE POLICY "group_tasks_select" ON group_tasks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_tasks.group_id
        AND group_members.user_id = auth.uid()
    )
  );

-- Admins can insert tasks
CREATE POLICY "group_tasks_insert" ON group_tasks
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_tasks.group_id
        AND group_members.user_id = auth.uid()
        AND group_members.role = 'admin'
    )
  );

-- Admins can update any task; members can only claim unassigned tasks
CREATE POLICY "group_tasks_update" ON group_tasks
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_tasks.group_id
        AND group_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    -- Admin: full update
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_tasks.group_id
        AND group_members.user_id = auth.uid()
        AND group_members.role = 'admin'
    )
    OR
    -- Member: can only claim unassigned tasks (assign to self)
    (
      group_tasks.assigned_to = auth.uid()
      AND group_tasks.status IN ('claimed', 'in_progress', 'done')
    )
  );

-- Admins can delete tasks
CREATE POLICY "group_tasks_delete" ON group_tasks
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM group_members
      WHERE group_members.group_id = group_tasks.group_id
        AND group_members.user_id = auth.uid()
        AND group_members.role = 'admin'
    )
  );

-- ============================================================
-- 6. Leaderboard RPC function (replaces weekly_leaderboard view)
-- ============================================================
CREATE OR REPLACE FUNCTION get_group_leaderboard(
  p_group_id uuid,
  p_period text DEFAULT 'weekly',
  p_metric text DEFAULT 'points'
)
RETURNS TABLE (
  user_id uuid,
  display_name text,
  avatar_url text,
  current_rank text,
  period_points bigint,
  period_tasks bigint,
  score bigint
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_start timestamptz;
BEGIN
  -- Determine period start
  v_start := CASE p_period
    WHEN 'weekly' THEN date_trunc('week', now())
    WHEN 'monthly' THEN date_trunc('month', now())
    WHEN 'quarterly' THEN date_trunc('quarter', now())
    ELSE date_trunc('week', now())
  END;

  RETURN QUERY
  SELECT
    ct.user_id,
    p.display_name,
    p.avatar_url,
    p.current_rank,
    COALESCE(SUM(ct.points), 0)::bigint AS period_points,
    COUNT(ct.id)::bigint AS period_tasks,
    CASE p_metric
      WHEN 'points' THEN COALESCE(SUM(ct.points), 0)::bigint
      WHEN 'tasks' THEN COUNT(ct.id)::bigint
      WHEN 'combined' THEN (COALESCE(SUM(ct.points), 0) + COUNT(ct.id) * 10)::bigint
      ELSE COALESCE(SUM(ct.points), 0)::bigint
    END AS score
  FROM group_members gm
  JOIN completed_tasks ct ON ct.user_id = gm.user_id
    AND ct.completed_at >= v_start
  JOIN profiles p ON p.id = gm.user_id
  WHERE gm.group_id = p_group_id
  GROUP BY ct.user_id, p.display_name, p.avatar_url, p.current_rank
  ORDER BY score DESC;
END;
$$;

-- ============================================================
-- 7. Sync group task to user's personal task list
-- ============================================================
CREATE OR REPLACE FUNCTION sync_group_task_to_user(
  p_group_task_id uuid,
  p_user_id uuid
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_gt group_tasks%ROWTYPE;
  v_group_name text;
  v_task_id uuid;
BEGIN
  SELECT * INTO v_gt FROM group_tasks WHERE id = p_group_task_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Group task not found';
  END IF;

  SELECT name INTO v_group_name FROM groups WHERE id = v_gt.group_id;

  -- Check if already synced
  IF v_gt.synced_task_id IS NOT NULL THEN
    RETURN v_gt.synced_task_id;
  END IF;

  INSERT INTO tasks (user_id, name, description, type, time, social, energy, due_date, group_task_id, group_id, group_name)
  VALUES (p_user_id, v_gt.name, v_gt.description, v_gt.type, v_gt.time, v_gt.social, v_gt.energy, v_gt.due_date, p_group_task_id, v_gt.group_id, v_group_name)
  RETURNING id INTO v_task_id;

  UPDATE group_tasks SET synced_task_id = v_task_id WHERE id = p_group_task_id;

  RETURN v_task_id;
END;
$$;
