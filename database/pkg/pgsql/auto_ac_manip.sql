/*
 * Copyright (c) 2015 Todd Kover
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * $Id$
 */

-- Create schema if it does not exist, do nothing otherwise.
DO $$
DECLARE
	_tal INTEGER;
BEGIN
	select count(*)
	from pg_catalog.pg_namespace
	into _tal
	where nspname = 'auto_ac_manip';
	IF _tal = 0 THEN
		DROP SCHEMA IF EXISTS auto_ac_manip;
		CREATE SCHEMA auto_ac_manip AUTHORIZATION jazzhands;
		COMMENT ON SCHEMA auto_ac_manip IS 'part of jazzhands';
	END IF;
END;
$$;

\set ON_ERROR_STOP


--------------------------------------------------------------------------------
-- returns the Id tag for CM
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_ac_manip.id_tag()
RETURNS VARCHAR AS $$
BEGIN
	RETURN('<-- $Id$ -->');
END;
$$ LANGUAGE plpgsql;
-- end of procedure id_tag

--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_ac_manip.find_or_create_automated_ac(
	account_id 	account.account_id%TYPE,
	ac_type		account_collection.account_collection_type%TYPE
)  RETURNS account_collection.account_collection_id%TYPE AS $_$
DECLARE
	_acname		text;
	_account	account%ROWTYPE;
	_acid		account_collection.account_collection_id%TYPE;
BEGIN
	EXECUTE 'SELECT * from account where account_id = $1' 
		INTO _account USING account_id;

	IF ac_type = 'AutomatedDirectsAC' THEN
		_acname := concat(_account.login, '-directs');
	ELSIF ac_type = 'AutomatedRollupsAC' THEN
		_acname := concat(_account.login, '-reports');
	ELSE
		RAISE EXCEPTION 'Do not know how to name Automated AC type %', ac_type;
	END IF;

	--
	-- Check to see if a -direct account collection exists already.  If not,
	-- create it.  There is a bit of a problem here if the name is not unique
	-- or otherwise messed up.  This will just raise errors.
	--
	EXECUTE 'SELECT ac.account_collection_id
			FROM account_collection ac
				INNER JOIN property p
					ON p.property_value_account_coll_id = ac.account_collection_id
		   WHERE ac.account_collection_name = $1
		    AND	ac.account_collection_type = $2
			AND	p.property_name = $3
			AND p.property_type = $4
			AND p.account_id = $5
		' INTO _acid USING _acname, 'automated',
				ac_type, 'auto_acct_coll', account_id;

	-- Assume the person is always in their own account collection, or if tehy
	-- are not someone took them out for a good reason.  (Thus, they are only
	-- added on creation).
	IF _acid IS NULL THEN
		EXECUTE 'INSERT INTO account_collection (
					account_collection_name, account_collection_type
				) VALUES ( $1, $2) RETURNING *
			' INTO _acid USING _acname, 'automated';

		IF ac_type = 'AutomatedDirectsAC' THEN
			EXECUTE 'INSERT INTO account_collection_account (
						account_collection_id, account_id
					) VALUES (  $1, $2 )
				' USING _acid, account_id;
		END IF;

		EXECUTE '
			INSERT INTO property ( 
				account_id,
				property_name,
				property_type,
				property_value_account_coll_id
			)  VALUES ( $1, $2, $3, $4)'
			USING account_id, ac_type, 'auto_acct_coll', _acid;
	END IF;

	RETURN _acid;
END;
$_$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = jazzhands;

--------------------------------------------------------------------------------
--
-- Creates the account collection and associated property if it exists,
-- makes sure the membership is what it should be (excluding the account,
-- itself, which may be a mistake -- the assumption is it was removed for a
-- good reason.
--
-- Returns the account_collection_id
--
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_ac_manip.populate_direct_report_ac(
	account_id 	account.account_id%TYPE
)  RETURNS account_collection.account_collection_id%TYPE AS $_$
DECLARE
	_directac	account_collection.account_collection_id%TYPE;
BEGIN
	_directac := auto_ac_manip.find_or_create_automated_ac(account_id,
		'AutomatedDirectsAC');

	--
	-- Make membership right
	--
	EXECUTE '
		WITH peeps AS (
			SELECT	account_realm_id, account_id, login, person_id, 
					manager_person_id
			FROM	account
				INNER JOIN person_company USING (person_id, company_id)
			WHERE	account_role = $2
		), arethere AS (
			SELECT account_collection_id, account_id FROM
				account_collection_account
				WHERE account_collection_id = $3
		), shouldbethere AS (
			SELECT $3 as account_collection_id, reports.account_id
			FROM peeps reports
				INNER JOIN peeps managers on  
					managers.person_id = reports.manager_person_id
				AND	managers.account_realm_id = reports.account_realm_id
			WHERE	managers.account_id =  $1
		), ins AS (
			INSERT INTO account_collection_account 
				(account_collection_id, account_id)
			SELECT account_collection_id, account_id 
			FROM shouldbethere
			WHERE (account_collection_id, account_id)
				NOT IN (select account_collection_id, account_id FROM arethere)
			RETURNING *
		), del AS (
			DELETE FROM account_collection_account
			WHERE (account_collection_id, account_id)
			IN (
				SELECT account_collection_id, account_id 
				FROM arethere
			) AND (account_collection_id, account_id) NOT IN (
				SELECT account_collection_id, account_id 
				FROM shouldbethere
			) RETURNING *
		) SELECT * from ins UNION SELECT * from del
		'USING account_id, 'primary', _directac;

	RETURN _directac;
END;
$_$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = jazzhands;

--------------------------------------------------------------------------------
--
-- Creates the account collection and associated property if it exists,
-- makes sure the membership is what it should be .  This does NOT manipulate
-- the -direct account collection at all
--
-- Returns the account_collection_id
--
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_ac_manip.populate_rollup_report_ac(
	account_id 	account.account_id%TYPE
)  RETURNS account_collection.account_collection_id%TYPE AS $_$
DECLARE
	_rollupac	account_collection.account_collection_id%TYPE;
BEGIN
	_rollupac := auto_ac_manip.find_or_create_automated_ac(account_id,
		'AutomatedRollupsAC');

	EXECUTE '
		WITH peeps AS (
			SELECT	account_realm_id, account_id, login, person_id, 
					manager_person_id
			FROM	account
				INNER JOIN person_company USING (person_id, company_id)
			WHERE	account_role = $2
		), agg AS ( SELECT reports.*, managers.account_id as manager_account_id,
				managers.login as manager_login, p.property_name,
				p.property_value_account_coll_id as account_collection_id
			FROM peeps reports
			INNER JOIN peeps managers
				ON managers.person_id = reports.manager_person_id
				AND	managers.account_realm_id = reports.account_realm_id
			INNER JOIN property p 
				ON p.account_id = reports.account_id
				AND p.property_name IN ($3,$4)
				AND p.property_type = $5
		), rank AS (
			SELECT *,
				rank() OVER (partition by account_id ORDER BY property_name desc)
					as rank
			FROM agg
		), shouldbethere AS (
			SELECT $6 as account_collection_id,
					account_collection_id as child_account_collection_id
			FROM rank
	 		WHERE	manager_account_id =  $1
			AND	rank = 1
		), arethere AS (
			SELECT account_collection_id, child_account_collection_id FROM
				account_collection_hier
			WHERE account_collection_id = $6
		), ins AS (
			INSERT INTO account_collection_hier 
				(account_collection_id, child_account_collection_id)
			SELECT account_collection_id, child_account_collection_id
			FROM shouldbethere
			WHERE (account_collection_id, child_account_collection_id)
				NOT IN (SELECT * from arethere)
			RETURNING *
		), del AS (
			DELETE FROM account_collection_hier
			WHERE (account_collection_id, child_account_collection_id)
				IN (SELECT * from arethere)
			AND (account_collection_id, child_account_collection_id)
				NOT IN (SELECT * FROM shouldbethere)
			RETURNING *
		) select * from ins UNION select * from del;

	' USING account_id, 'primary',
				'AutomatedDirectsAC','AutomatedRollupsAC','auto_acct_coll',
				_rollupac;

	RETURN _rollupac;
END;
$_$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = jazzhands;



CREATE OR REPLACE FUNCTION auto_ac_manip.create_report_account_collections(
	account_id 	account.account_id%TYPE,
	force		boolean DEFAULT false
)  RETURNS VOID AS $_$
DECLARE
	_account	account%ROWTYPE;
	_directac	account_collection.account_collection_id%TYPE;
	_rollupac	account_collection.account_collection_id%TYPE;
	_numrpt		integer;
	_numrlup	integer;
BEGIN
	-- get number of direct reports
	EXECUTE '
		WITH peeps AS (
			SELECT	account_realm_id, account_id, login, person_id, 
					manager_person_id
			FROM	account
				INNER JOIN person_company USING (person_id, company_id)
			WHERE	account_role = $2
		) SELECT count(*)
		FROM peeps reports
			INNER JOIN peeps managers on  
				managers.person_id = reports.manager_person_id
			AND	managers.account_realm_id = reports.account_realm_id
		WHERE	managers.account_id = $1
	' INTO _numrpt USING account_id, 'primary';

	IF force = false AND _numrpt = 0 THEN
		RETURN;
	END IF;

	_directac := auto_ac_manip.populate_direct_report_ac(account_id);

	-- now check to see if the roll up should be created and add appropriate
	-- teams
	EXECUTE '
		WITH peeps AS (
			SELECT	account_realm_id, account_id, login, person_id, 
					manager_person_id
			FROM	account
				INNER JOIN person_company USING (person_id, company_id)
			WHERE	account_role = $2
		), agg AS ( SELECT reports.*, managers.account_id as manager_account_id,
				managers.login as manager_login, p.property_name,
				p.property_value_account_coll_id as account_collection_id
			FROM peeps reports
			INNER JOIN peeps managers
				ON managers.person_id = reports.manager_person_id
				AND	managers.account_realm_id = reports.account_realm_id
			INNER JOIN property p 
				ON p.account_id = reports.account_id
				AND p.property_name IN ($3,$4)
				AND p.property_type = $5
		), rank AS (
			SELECT *,
				rank() OVER (partition by account_id ORDER BY property_name desc)
					as rank
			FROM agg
		) SELECT count(*) from rank
		WHERE	manager_account_id =  $1
		AND	rank = 1;
	' INTO _numrlup USING account_id, 'primary',
				'AutomatedDirectsAC','AutomatedRollupsAC','auto_acct_coll';
	IF _numrlup = 0 THEN
		RETURN;
	END IF;

	_rollupac := auto_ac_manip.populate_rollup_report_ac(account_id);

	-- add directs to rollup
	EXECUTE '
		INSERT INTO account_collection_hier (
			account_collection_id, child_account_collection_id
		) VALUES (
			$1, $2
		)' USING _rollupac, _directac;
END;
$_$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = jazzhands;

CREATE OR REPLACE FUNCTION auto_ac_manip.destroy_report_account_collections(
	account_id 	account.account_id%TYPE,
	force		boolean DEFAULT false
)  RETURNS VOID AS $_$
DECLARE
	_account	account%ROWTYPE;
	_directac	account_collection.account_collection_id%TYPE;
	_rollupac	account_collection.account_collection_id%TYPE;
	_numrpt		integer;
	_numrlup	integer;
BEGIN
	-- get number of direct reports
	EXECUTE '
		WITH peeps AS (
			SELECT	account_realm_id, account_id, login, person_id, 
					manager_person_id
			FROM	account
				INNER JOIN person_company USING (person_id, company_id)
			WHERE	account_role = $2
		) SELECT count(*)
		FROM peeps reports
			INNER JOIN peeps managers on  
				managers.person_id = reports.manager_person_id
			AND	managers.account_realm_id = reports.account_realm_id
		WHERE	managers.account_id = $1
	' INTO _numrpt USING account_id, 'primary';

	IF force = false AND _numrpt > 0 THEN
		RETURN;
	END IF;

	EXECUTE '
		DELETE FROM account_collection_account
		WHERE account_collection_ID IN (
			SELECT	property_value_account_coll_id
			FROM	property
			WHERE	property_name = $2
			AND		property_type = $3
			AND		account_id = $1
		)' USING account_id, 'AutomatedDirectsAC', 'auto_acct_coll';

	EXECUTE '
		WITH p AS (
			SELECT	property_value_account_coll_id AS account_collection_id
			FROM	property
			WHERE	property_name IN ($2,$3)
			AND		property_type = $4
			AND		account_id = $1
		)
		DELETE FROM account_collection_hier
		WHERE account_collection_id IN ( select account_collection_id from p)
		OR child_account_collection_id IN ( select account_collection_id from p)
		' USING account_id, 'AutomatedRollupsAC', 'AutomatedDirectsAC',
			'auto_acct_coll';

	EXECUTE '
		WITH list AS (
			SELECT	property_value_account_coll_id as account_collection_id,
					property_id
			FROM	property
			WHERE	property_name IN ($2,$3)
			AND		property_type = $4
			AND		account_id = $1
		), props AS (
			DELETE FROM property WHERE property_id IN
				(select property_id FROM list ) RETURNING *
		) DELETE FROM account_collection WHERE account_collection_id IN
				(select property_value_account_coll_id FROM props )
		' USING account_id, 'AutomatedRollupsAC', 'AutomatedDirectsAC',
			'auto_acct_coll';

END;
$_$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = jazzhands;


grant usage on schema auto_ac_manip to iud_role;
revoke all on schema auto_ac_manip from public;
revoke all on  all functions in schema auto_ac_manip from public;
grant execute on all functions in schema auto_ac_manip to iud_role;

