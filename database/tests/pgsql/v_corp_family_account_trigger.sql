-- Copyright (c) 2014 Todd Kover
-- All rights reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- $Id$


\set ON_ERROR_STOP

\t on

-- 
-- Trigger tests
--
CREATE OR REPLACE FUNCTION v_corp_family_account_regression() RETURNS BOOLEAN AS $$
DECLARE
	_tally			integer;
	_personid		company.person_id%type;
	_companyid		company.company_id%type;
	_defprop		property%rowtype;
	_acc_realm_id		account_realm.account_realm_id%type;
	_acc1			account%rowtype;
	_acc2			account%rowtype;
BEGIN
	RAISE NOTICE 'v_corp_family_account regression: BEGIN';
	RAISE NOTICE 'v_corp_family_account: Cleanup Records from Previous Tests';

	RAISE NOTICE 'v_corp_family_account: Adding prerequisites';
	INSERT INTO account_realm (account_realm_name)
		VALUES ('JHTEST-AR') RETURNING account_realm_id INTO _acc_realm_id

	INSERT INTO person (first_name, last_name)
		VALUES ('JH', 'TEST') RETURNING person_id INTO _personid;

	INSERT INTO company (company_name, is_corporate_family)
		VALUES ('JHTEST, Inc', 'Y') RETURNING company_id into _companyid;

	RAISE NOTICE 'Testing insert into v_corp_family_account... ';
	INSERT INTO v_corp_family_account (login, person_id

	RAISE NOTICE 'Testing to see if max_num_collections works... ';
	BEGIN
		INSERT INTO account_collection_account (
			account_collection_id, account_Id
		) VALUES (
			_ac_onecol2.account_collection_id, _acc1.account_id
		);
		RAISE EXCEPTION '... IT DID NOT.';
	EXCEPTION WHEN unique_violation THEN
		RAISE NOTICE '... It did';
	END;

	RAISE NOTICE 'Cleaning up...';

	RAISE NOTICE 'v_corp_family_account regression: DONE';
	RAISE EXCEPTION 'Need to write these';
	RETURN true;
END;
$$ LANGUAGE plpgsql;

-- set search_path=public;
SELECT v_corp_family_account_regression();
-- set search_path=jazzhands;
DROP FUNCTION v_corp_family_account_regression();

\t off
