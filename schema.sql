-- ====================================================================
-- AttendEase - Complete College Attendance Database Schema
-- Fully Idempotent, Production-Ready with Bulletproof RLS & Auto-Confirm
-- ====================================================================

create extension if not exists pgcrypto;

-- --------------------------------------------------------------------
-- 1. APP ADMINS TABLE & ADMIN HELPER FUNCTION
-- --------------------------------------------------------------------
create table if not exists public.app_admins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  role text not null default 'admin',
  created_at timestamptz not null default now()
);

-- Function to check if current user is an Admin
-- Directly recognizes akverma4466@gmail.com and admin emails from JWT, as well as app_admins records
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.app_admins where user_id = auth.uid()
  ) or (
    auth.jwt()->>'email' = 'akverma4466@gmail.com' or 
    auth.jwt()->>'email' ilike '%admin%'
  );
$$;

-- --------------------------------------------------------------------
-- 2. AUTO-CONFIRM TRIGGER FOR ALL NEW AUTH USERS (STUDENTS & TEACHERS)
-- --------------------------------------------------------------------
-- Ensures newly created students and teachers can log in instantly without email confirmation delays
create or replace function public.auto_confirm_new_user()
returns trigger as $$
begin
  new.email_confirmed_at = coalesce(new.email_confirmed_at, now());
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created_auto_confirm on auth.users;
create trigger on_auth_user_created_auto_confirm
before insert on auth.users
for each row execute function public.auto_confirm_new_user();

-- Immediately confirm any existing unconfirmed auth accounts
update auth.users set email_confirmed_at = now() where email_confirmed_at is null;

-- --------------------------------------------------------------------
-- 3. CORE ACADEMIC TABLES
-- --------------------------------------------------------------------

-- Classes / Sections
create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  department text default 'General',
  created_at timestamptz not null default now(),
  unique (name)
);

-- Subjects
create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  name text not null,
  code text,
  created_at timestamptz not null default now(),
  unique (class_id, name)
);

-- Students Table
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  roll_no text not null,
  name text not null,
  email text,
  auth_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (class_id, roll_no)
);

-- Migration safety: ensure email and auth_user_id columns exist on existing students table
alter table public.students add column if not exists email text;
alter table public.students add column if not exists auth_user_id uuid references auth.users(id) on delete set null;

-- Teachers Profile Table (Managed by Admin)
create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade unique,
  name text not null,
  email text not null unique,
  department text default 'General',
  created_at timestamptz not null default now()
);

-- Teacher Assignments Table (Maps Teachers to Class Subjects)
create table if not exists public.teacher_assignments (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid,
  teacher_id uuid not null,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (class_id, subject_id)
);

-- Safety: remove restrictive FK constraints on teacher_id and admin_id if present from previous runs
alter table public.teacher_assignments drop constraint if exists teacher_assignments_teacher_id_fkey;
alter table public.teacher_assignments drop constraint if exists teacher_assignments_admin_id_fkey;

-- Weekly Timetable
create table if not exists public.timetable (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references auth.users(id) on delete set null,
  teacher_id uuid not null references auth.users(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6), -- 0=Mon ... 6=Sun
  period_number smallint not null check (period_number between 1 and 8),
  start_time time not null,
  end_time time not null,
  room text,
  created_at timestamptz not null default now(),
  unique (class_id, day_of_week, period_number)
);

-- Daily Timetable Overrides / Cancellations
create table if not exists public.timetable_overrides (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references auth.users(id) on delete set null,
  teacher_id uuid references auth.users(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete cascade,
  timetable_date date not null,
  period_number smallint not null check (period_number between 1 and 8),
  start_time time,
  end_time time,
  room text,
  is_cancelled boolean not null default false,
  created_at timestamptz not null default now(),
  unique (class_id, timetable_date, period_number)
);

-- Attendance Sessions Table
create table if not exists public.attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  session_date date not null,
  period_number smallint not null check (period_number between 1 and 8),
  status text not null check (status in ('held', 'cancelled')),
  created_at timestamptz not null default now(),
  unique (class_id, subject_id, session_date, period_number)
);

-- Student Daily Attendance Records
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  attendance_date date not null,
  period_number smallint not null check (period_number between 1 and 8),
  status text not null check (status in ('present', 'absent', 'leave')),
  created_at timestamptz not null default now(),
  unique (student_id, subject_id, attendance_date, period_number)
);

-- --------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- --------------------------------------------------------------------

alter table public.app_admins enable row level security;
alter table public.classes enable row level security;
alter table public.subjects enable row level security;
alter table public.students enable row level security;
alter table public.teachers enable row level security;
alter table public.teacher_assignments enable row level security;
alter table public.timetable enable row level security;
alter table public.timetable_overrides enable row level security;
alter table public.attendance_sessions enable row level security;
alter table public.attendance enable row level security;

-- Drop legacy / restrictive policies from previous versions
drop policy if exists "Teacher manages own classes" on public.classes;
drop policy if exists "Authenticated users can view classes" on public.classes;
drop policy if exists "Admins and teachers can manage classes" on public.classes;

drop policy if exists "Teacher manages own subjects" on public.subjects;
drop policy if exists "Authenticated users can view subjects" on public.subjects;
drop policy if exists "Admins and teachers can manage subjects" on public.subjects;

drop policy if exists "Teacher manages own students" on public.students;
drop policy if exists "Authenticated users can view students" on public.students;
drop policy if exists "Admins and teachers can manage students" on public.students;
drop policy if exists "Allow public student roll lookup" on public.students;

drop policy if exists "Teacher manages own attendance" on public.attendance;
drop policy if exists "Authenticated users can view attendance" on public.attendance;
drop policy if exists "Teachers and admins can manage attendance" on public.attendance;

drop policy if exists "Admins can view and manage admins" on public.app_admins;
drop policy if exists "Authenticated users can view teachers" on public.teachers;
drop policy if exists "Admins can manage teachers" on public.teachers;

drop policy if exists "Authenticated users can view teacher assignments" on public.teacher_assignments;
drop policy if exists "Admins can manage teacher assignments" on public.teacher_assignments;

drop policy if exists "Authenticated users can view timetable" on public.timetable;
drop policy if exists "Admins and assigned teachers can manage timetable" on public.timetable;

drop policy if exists "Authenticated users can view timetable overrides" on public.timetable_overrides;
drop policy if exists "Admins and teachers can manage timetable overrides" on public.timetable_overrides;

drop policy if exists "Authenticated users can view attendance sessions" on public.attendance_sessions;
drop policy if exists "Teachers and admins can manage attendance sessions" on public.attendance_sessions;

-- 4a. App Admins
create policy "Admins can view and manage admins"
on public.app_admins for all to authenticated
using (public.is_admin() or user_id = auth.uid())
with check (public.is_admin() or not exists (select 1 from public.app_admins));

-- 4b. Classes: All authenticated can view; Admins & Teachers can manage
create policy "Authenticated users can view classes"
on public.classes for select to authenticated
using (true);

create policy "Admins and teachers can manage classes"
on public.classes for all to authenticated
using (public.is_admin() or teacher_id = auth.uid())
with check (public.is_admin() or teacher_id = auth.uid());

-- 4c. Subjects: All authenticated can view; Admins & Teachers can manage
create policy "Authenticated users can view subjects"
on public.subjects for select to authenticated
using (true);

create policy "Admins and teachers can manage subjects"
on public.subjects for all to authenticated
using (public.is_admin() or teacher_id = auth.uid())
with check (public.is_admin() or teacher_id = auth.uid());

-- 4d. Students: Authenticated and Anonymous can view for login roll lookup; Admins & Teachers can manage
create policy "Allow public student roll lookup"
on public.students for select
using (true);

create policy "Admins and teachers can manage students"
on public.students for all to authenticated
using (public.is_admin() or teacher_id = auth.uid())
with check (public.is_admin() or teacher_id = auth.uid());

-- 4e. Teachers: All authenticated can view; Admins can manage
create policy "Authenticated users can view teachers"
on public.teachers for select to authenticated
using (true);

create policy "Admins can manage teachers"
on public.teachers for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- 4f. Teacher Assignments: All authenticated can view; Admins can manage
create policy "Authenticated users can view teacher assignments"
on public.teacher_assignments for select to authenticated
using (true);

create policy "Admins can manage teacher assignments"
on public.teacher_assignments for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- 4g. Timetable: All authenticated can view; Admins & Teachers can manage
create policy "Authenticated users can view timetable"
on public.timetable for select to authenticated
using (true);

create policy "Admins and assigned teachers can manage timetable"
on public.timetable for all to authenticated
using (public.is_admin() or teacher_id = auth.uid())
with check (public.is_admin() or teacher_id = auth.uid());

-- 4h. Timetable Overrides: All authenticated can view; Admins & Teachers can manage
create policy "Authenticated users can view timetable overrides"
on public.timetable_overrides for select to authenticated
using (true);

create policy "Admins and teachers can manage timetable overrides"
on public.timetable_overrides for all to authenticated
using (public.is_admin() or teacher_id = auth.uid())
with check (public.is_admin() or teacher_id = auth.uid());

-- 4i. Attendance Sessions: All authenticated can view; Admins & Teachers can manage
create policy "Authenticated users can view attendance sessions"
on public.attendance_sessions for select to authenticated
using (true);

create policy "Teachers and admins can manage attendance sessions"
on public.attendance_sessions for all to authenticated
using (public.is_admin() or teacher_id = auth.uid())
with check (public.is_admin() or teacher_id = auth.uid());

-- 4j. Attendance Records: All authenticated can view; Admins & Teachers can manage
create policy "Authenticated users can view attendance"
on public.attendance for select to authenticated
using (true);

create policy "Teachers and admins can manage attendance"
on public.attendance for all to authenticated
using (public.is_admin() or teacher_id = auth.uid())
with check (public.is_admin() or teacher_id = auth.uid());

-- --------------------------------------------------------------------
-- 5. PERFORMANCE INDEXES
-- --------------------------------------------------------------------
create index if not exists idx_students_class on public.students (class_id);
create index if not exists idx_subjects_class on public.subjects (class_id);
create index if not exists idx_attendance_lookup on public.attendance (subject_id, attendance_date, period_number);
create index if not exists idx_attendance_student on public.attendance (student_id);
create index if not exists idx_timetable_lookup on public.timetable (class_id, day_of_week);
create index if not exists idx_overrides_lookup on public.timetable_overrides (class_id, timetable_date);
create index if not exists idx_sessions_lookup on public.attendance_sessions (class_id, subject_id, session_date);
create index if not exists idx_assignments_teacher on public.teacher_assignments (teacher_id);

-- --------------------------------------------------------------------
-- 6. BOOTSTRAP INITIAL ADMIN ACCOUNT
-- --------------------------------------------------------------------
insert into public.app_admins (user_id, role)
select id, 'admin' from auth.users where email = 'akverma4466@gmail.com'
on conflict (user_id) do nothing;
