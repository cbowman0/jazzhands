DO $$
BEGIN
	PERFORM * FROM company WHERE company_name = 'Dell';
	IF NOT FOUND THEN
		INSERT INTO company (company_name) VALUEs ('Dell');
	END IF;
END; $$ language plpgsql;

\ir Dell_PowerEdge_C6100.sql
\ir Dell_PowerEdge_C6220.sql
