-- Create helper functions for RLS
CREATE OR REPLACE FUNCTION public.get_user_role(agency_id_param text)
RETURNS text AS $$
BEGIN
    RETURN (
        SELECT role FROM public.user_agencies 
        WHERE user_id = auth.uid() AND agency_id = agency_id_param
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin_for_agency(agency_id_param text)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_agencies 
        WHERE user_id = auth.uid() 
        AND agency_id = agency_id_param 
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_dialer_for_agency(agency_id_param text)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_agencies 
        WHERE user_id = auth.uid() 
        AND agency_id = agency_id_param 
        AND role = 'dialer'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_sales_for_agency(agency_id_param text)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_agencies 
        WHERE user_id = auth.uid() 
        AND agency_id = agency_id_param 
        AND role = 'sales'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_agencies 
        WHERE user_id = auth.uid() 
        AND role = 'super_admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing policies that don't match our requirements
DROP POLICY IF EXISTS "Users can view their agency's calls" ON public.daily_call_report;
DROP POLICY IF EXISTS "Authenticated users can view call reports" ON public.daily_call_report;

-- Create proper role-based policies
CREATE POLICY "Dialer access to call reports" 
ON public.daily_call_report FOR SELECT 
TO authenticated
USING (
    (public.is_dialer_for_agency(agency_id) AND user_id::text = auth.uid()::text) OR
    public.is_sales_for_agency(agency_id) OR
    public.is_admin_for_agency(agency_id) OR
    public.is_super_admin()
);

-- Consolidate service role policies
DROP POLICY IF EXISTS "Service role can insert call reports" ON public.daily_call_report;
DROP POLICY IF EXISTS "Service role can insert calls" ON public.daily_call_report;

CREATE POLICY "Service role full access" 
ON public.daily_call_report FOR ALL 
TO service_role
USING (true)
WITH CHECK (true);
