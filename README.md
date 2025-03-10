# Insurance Dashboard RLS Migration

This repository contains the SQL migration needed to fix the Row Level Security (RLS) for the Insurance Dashboard project.

## What's Included

- Helper functions for role-based security (dialer, sales, admin, super_admin)
- Correctly configured RLS policies for the `daily_call_report` table

## How to Apply the Migration

1. Copy the SQL migration file to your Supabase project:

```bash
# Navigate to your project
cd /Users/craigpretzinger/projects/InsuranceDash/insurance-dashboard-helper

# Create a new migration file
cp /path/to/20250310225500_create_rls_helper_functions.sql supabase/migrations/
```

2. Apply the migration:

```bash
# Run the migration
supabase db push
```

3. Verify that the migration worked by checking the functions:

```sql
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname IN ('is_dialer_for_agency', 'is_sales_for_agency', 'is_admin_for_agency', 'is_super_admin');
```

You should see 4 rows returned.

4. Check the RLS policies:

```sql
SELECT policyname, cmd, roles::text 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'daily_call_report';
```

You should see policies including "Dialer access to call reports" and "Service role full access".

## Troubleshooting

- If you encounter issues with existing policies, you can drop all policies and start fresh:

```sql
DROP POLICY IF EXISTS "Dialer access to call reports" ON public.daily_call_report;
DROP POLICY IF EXISTS "Service role full access" ON public.daily_call_report;
DROP POLICY IF EXISTS "Users can view their agency's calls" ON public.daily_call_report;
DROP POLICY IF EXISTS "Authenticated users can view call reports" ON public.daily_call_report;
DROP POLICY IF EXISTS "Service role can insert call reports" ON public.daily_call_report;
DROP POLICY IF EXISTS "Service role can insert calls" ON public.daily_call_report;
```

Then run the migration again.
