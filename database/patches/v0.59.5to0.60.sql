/*
 *
 * Copyright (c) 2014 Todd Kover
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
  TODO before release:

 	- trigger for phsicalish_volume to deal with only one of lgid/compid set
	- check inner_device_commonet_trigger to make sure it is right
	- mdr to finish component triggers
	- resolve component issues
		- device_type becomes component_type?
		- rack becomes a component?
	- compatibility views
	- finish testing all the new account collection triggers
		(write stored procedures)
	- check init/ *.sql changes for updates that should happen

	- search for XXX's
	- trigger functions (maybe done?)

 */

SELECT schema_support.begin_maintenance();
\set ON_ERROR_STOP

select now();

 ALTER TABLE ACCOUNT_REALM_COMPANY DROP CONSTRAINT FK_ACCT_RLM_CMPY_CMPY_ID;
 ALTER TABLE ACCOUNT_REALM_COMPANY 
	ADD CONSTRAINT FK_ACCT_RLM_CMPY_CMPY_ID FOREIGN KEY (COMPANY_ID) 
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE CIRCUIT DROP CONSTRAINT FK_CIRCUIT_VEND_COMPANYID;
 ALTER TABLE CIRCUIT
	ADD CONSTRAINT FK_CIRCUIT_VEND_COMPANYID FOREIGN KEY (VENDOR_COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE CIRCUIT DROP CONSTRAINT FK_CIRCUIT_ALOC_COMPANYID;
 ALTER TABLE CIRCUIT
	ADD CONSTRAINT FK_CIRCUIT_ALOC_COMPANYID FOREIGN KEY (ALOC_LEC_COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE CIRCUIT DROP CONSTRAINT FK_CIRCUIT_ZLOC_COMPANY_ID;
 ALTER TABLE CIRCUIT
	ADD CONSTRAINT FK_CIRCUIT_ZLOC_COMPANY_ID FOREIGN KEY (ZLOC_LEC_COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE COMPANY DROP CONSTRAINT FK_COMPANY_PARENT_COMPANY_ID;
 ALTER TABLE COMPANY
	ADD CONSTRAINT FK_COMPANY_PARENT_COMPANY_ID FOREIGN KEY (PARENT_COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE COMPANY_TYPE DROP CONSTRAINT FK_COMPANY_TYPE_COMPANY_ID;
 ALTER TABLE COMPANY_TYPE
	ADD CONSTRAINT FK_COMPANY_TYPE_COMPANY_ID FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE CONTRACT DROP CONSTRAINT FK_CONTRACT_COMPANY_ID;
 ALTER TABLE CONTRACT
	ADD CONSTRAINT FK_CONTRACT_COMPANY_ID FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE DEPARTMENT DROP CONSTRAINT FK_DEPT_COMPANY;
 ALTER TABLE DEPARTMENT
	ADD CONSTRAINT FK_DEPT_COMPANY FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE  ;

 ALTER TABLE DEVICE DROP CONSTRAINT FK_DEVICE_COMPANY__ID;
 ALTER TABLE DEVICE
	ADD CONSTRAINT FK_DEVICE_COMPANY__ID FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE DEVICE_TYPE DROP CONSTRAINT FK_DEVTYP_COMPANY;
 ALTER TABLE DEVICE_TYPE
	ADD CONSTRAINT FK_DEVTYP_COMPANY FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE NETBLOCK DROP CONSTRAINT FK_NETBLOCK_COMPANY;
 ALTER TABLE NETBLOCK
	ADD CONSTRAINT FK_NETBLOCK_COMPANY FOREIGN KEY (NIC_COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE OPERATING_SYSTEM DROP CONSTRAINT FK_OS_COMPANY;
 ALTER TABLE OPERATING_SYSTEM
	ADD CONSTRAINT FK_OS_COMPANY FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE PERSON_COMPANY DROP CONSTRAINT FK_PERSON_COMPANY_COMPANY_ID;
 ALTER TABLE PERSON_COMPANY
	ADD CONSTRAINT FK_PERSON_COMPANY_COMPANY_ID FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE PERSON_CONTACT DROP CONSTRAINT FK_PRSN_CONTECT_CR_CMPYID;
 ALTER TABLE PERSON_CONTACT
	ADD CONSTRAINT FK_PRSN_CONTECT_CR_CMPYID FOREIGN KEY (PERSON_CONTACT_CR_COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE PHYSICAL_ADDRESS DROP CONSTRAINT FK_PHYSADDR_COMPANY_ID;
 ALTER TABLE PHYSICAL_ADDRESS
	ADD CONSTRAINT FK_PHYSADDR_COMPANY_ID FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE PROPERTY DROP CONSTRAINT FK_PROPERTY_COMPID;
 ALTER TABLE PROPERTY
	ADD CONSTRAINT FK_PROPERTY_COMPID FOREIGN KEY (COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE PROPERTY DROP CONSTRAINT FK_PROPERTY_PVAL_COMPID;
 ALTER TABLE PROPERTY
	ADD CONSTRAINT FK_PROPERTY_PVAL_COMPID FOREIGN KEY (PROPERTY_VALUE_COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE SITE DROP CONSTRAINT FK_SITE_COLO_COMPANY_ID;
 ALTER TABLE SITE
	ADD CONSTRAINT FK_SITE_COLO_COMPANY_ID FOREIGN KEY (COLO_COMPANY_ID)
	REFERENCES COMPANY (COMPANY_ID)  DEFERRABLE  INITIALLY IMMEDIATE;

 ALTER TABLE PERSON_ACCOUNT_REALM_COMPANY 
	DROP CONSTRAINT FK_AC_AC_RLM_CPY_ACT_RLM_CPY;
 ALTER TABLE PERSON_ACCOUNT_REALM_COMPANY
       ADD CONSTRAINT FK_AC_AC_RLM_CPY_ACT_RLM_CPY 
	FOREIGN KEY (ACCOUNT_REALM_ID, COMPANY_ID) 
	REFERENCES ACCOUNT_REALM_COMPANY (ACCOUNT_REALM_ID, COMPANY_ID)  
	DEFERRABLE  INITIALLY IMMEDIATE;


--------------------------------------------------------------------
-- BEGIN kill IntegrityPackage
--------------------------------------------------------------------

DROP FUNCTION IF EXISTS "IntegrityPackage"."InitNestLevel"();
DROP FUNCTION IF EXISTS "IntegrityPackage"."NextNestLevel"();
DROP FUNCTION IF EXISTS "IntegrityPackage"."PreviousNestLevel"();
DROP FUNCTION IF EXISTS "IntegrityPackage"."GetNestLevel"();
DROP SCHEMA IF EXISTS "IntegrityPackage";

--------------------------------------------------------------------
-- END kill IntegrityPackage
--------------------------------------------------------------------

--------------------------------------------------------------------
-- migrate per-user to per-account and give a genericy name 
--------------------------------------------------------------------

alter table account_collection drop constraint "fk_acctcol_usrcoltyp";

WITH merge AS (
	SELECT  account_collection_id, account_id, login,
		account_collection_name
	FROM    account_collection
		INNER JOIN account_collection_account
			USING (account_collection_id)
		INNER JOIN account USING (account_id)
	WHERE   account_collection_type = 'per-account'
)  UPDATE account_collection ac
	SET account_collection_name =
		CONCAT(m.login, '_', m.account_id),
	account_collection_type = 'per-account'
FROM merge m
WHERE m.account_collection_id = ac.account_collection_Id;


update val_account_collection_type set account_collection_type = 'per-account'
where account_collection_type = 'per-user';

update account_collection set account_collection_type = 'per-account'
where account_collection_type = 'per-user';

ALTER TABLE ACCOUNT_COLLECTION
	ADD CONSTRAINT FK_ACCTCOL_USRCOLTYP 
	FOREIGN KEY (ACCOUNT_COLLECTION_TYPE) 
	REFERENCES VAL_ACCOUNT_COLLECTION_TYPE (ACCOUNT_COLLECTION_TYPE)  ;

-- related; the procedures are dropped later
-- triggers
DROP TRIGGER IF EXISTS trig_automated_ac ON account;
DROP TRIGGER IF EXISTS trigger_delete_peruser_account_collection ON account;
DROP TRIGGER IF EXISTS trigger_update_account_type_account_collection ON account;
DROP TRIGGER IF EXISTS trigger_update_peruser_account_collection ON account;

--------------------------------------------------------------------
-- DONE: migrate per-user to per-account and give a genericy name 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- BEGIN add physical_address_utils
--------------------------------------------------------------------

--
-- Copyright (c) 2014 Matthew Ragan
-- All rights reserved.
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

DO $$
DECLARE
	_tal INTEGER;
BEGIN
	select count(*)
	from pg_catalog.pg_namespace
	into _tal
	where nspname = 'physical_address_utils';
	IF _tal = 0 THEN
		DROP SCHEMA IF EXISTS physical_address_utils;
		CREATE SCHEMA physical_address_utils AUTHORIZATION jazzhands;
		COMMENT ON SCHEMA physical_address_utils IS 'part of jazzhands';
	END IF;
END;
$$;

CREATE OR REPLACE FUNCTION physical_address_utils.localized_physical_address(
	physical_address_id integer,
	line_separator text DEFAULT ', ',
	include_country boolean DEFAULT true
) RETURNS text AS $$
DECLARE
	address	text;
BEGIN
	SELECT concat_ws(line_separator,
			CASE WHEN iso_country_code IN 
					('SG', 'US', 'CA', 'UK', 'GB', 'FR', 'AU') THEN 
				concat_ws(' ', address_housename, address_street)
			WHEN iso_country_code IN ('IL') THEN
				concat_ws(', ', address_housename, address_street)
			WHEN iso_country_code IN ('ES') THEN
				concat_ws(', ', address_street, address_housename)
			ELSE
				concat_ws(' ', address_street, address_housename)
			END,
			address_pobox,
			address_building,
			address_neighborhood,
			CASE WHEN iso_country_code IN ('US', 'CA', 'UK') THEN 
				concat_ws(', ', address_city, 
					concat_ws(' ', address_region, postal_code))
			WHEN iso_country_code IN ('SG', 'AU') THEN
				concat_ws(' ', address_city, address_region, postal_code)
			ELSE
				concat_ws(' ', postal_code, address_city, address_region)
			END,
			iso_country_code
		)
	INTO address
	FROM
		physical_address pa
	WHERE
		pa.physical_address_id = 
			localized_physical_address.physical_address_id;
	RETURN address;
END; $$
SET search_path=jazzhands
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION physical_address_utils.localized_street_address(
	address_housename text DEFAULT NULL,
	address_street text DEFAULT NULL,
	address_building text DEFAULT NULL,
	address_pobox text DEFAULT NULL,
	iso_country_code text DEFAULT NULL,
	line_separator text DEFAULT ', '
) RETURNS text AS $$
BEGIN
	RETURN concat_ws(line_separator,
			CASE WHEN iso_country_code IN 
					('SG', 'US', 'CA', 'UK', 'GB', 'FR', 'AU') THEN 
				concat_ws(' ', address_housename, address_street)
			WHEN iso_country_code IN ('IL') THEN
				concat_ws(', ', address_housename, address_street)
			WHEN iso_country_code IN ('ES') THEN
				concat_ws(', ', address_street, address_housename)
			ELSE
				concat_ws(' ', address_street, address_housename)
			END,
			address_pobox,
			address_building
		);
END; $$
SET search_path=jazzhands
LANGUAGE plpgsql;

GRANT USAGE ON SCHEMA physical_address_utils TO public;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA physical_address_utils TO ro_role;

--------------------------------------------------------------------
-- END add physical_address_utils
--------------------------------------------------------------------

--------------------------------------------------------------------
-- BEGIN add company_manip
--------------------------------------------------------------------

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

\set ON_ERROR_STOP

-- Create schema if it does not exist, do nothing otherwise.
DO $$
DECLARE
	_tal INTEGER;
BEGIN
	select count(*)
	from pg_catalog.pg_namespace
	into _tal
	where nspname = 'company_manip';
	IF _tal = 0 THEN
		DROP SCHEMA IF EXISTS company_manip;
		CREATE SCHEMA company_manip AUTHORIZATION jazzhands;
		COMMENT ON SCHEMA company_manip IS 'part of jazzhands';
	END IF;
END;
$$;

------------------------------------------------------------------------------

--
-- account realm is here because its possible for companies to be part of
-- multiple account realms.
--

--
-- sets up the automated account collections.  This assumes some carnal
-- knowledge of some of the types.
--
-- This is typically only called from add_company.
--
-- note that there is no 'remove_auto_collections'
--
CREATE OR REPLACE FUNCTION company_manip.add_auto_collections(
	_company_id		company.company_id%type,
	_account_realm_id	account_realm.account_realm_id%type,
	_company_type	text
) RETURNS void AS
$$
DECLARE
	_ar		account_realm.account_realm_name%TYPE;
	_csn	company.company_short_name%TYPE;
	_r		RECORD;
	_v		text[];
	i		text;
	acname	account_collection.account_collection_name%TYPE;
	acid	account_collection.account_collection_id%TYPE;
	propv	text;
	tally	integer;
BEGIN
	PERFORM
	FROM	account_realm_company
	WHERE	company_id = _company_id
	AND		account_realm_id = _account_realm_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Company and Account Realm are not associated together'
			USING ERRCODE = 'not_null_violation';
	END IF;

	PERFORM *
	FROM	company_type
	WHERE	company_id = _company_id
	AND		company_type = _company_type;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Company % is not of type %', _company_id, _company_type
			USING ERRCODE = 'not_null_violation';
	END IF;
	
	tally := 0;
	FOR _r IN SELECT	property_name, property_type, permit_company_id
				FROM    property_collection_property pcp
				INNER JOIN property_collection pc
					USING (property_collection_id)
				INNER JOIN val_property vp USING (property_name,property_type)
				WHERE property_collection_type = 'auto_ac_assignment'
				AND property_collection_name = _company_type
				AND property_name != 'site'
	LOOP
		IF _r.property_name = 'account_type' THEN
			SELECT array_agg( account_type)
			INTO _v
			FROM val_account_type
			WHERE account_type != 'blacklist';
		ELSE
			_v := ARRAY[NULL]::text[];
		END IF;

	SELECT	account_realm_name
	INTO	_ar
	FROM	account_realm
	WHERE	account_realm_id = _account_realm_id;

	SELECT	company_short_name
	INTO	_csn
	FROM	company
	WHERE	company_id = _company_id;

		FOREACH i IN ARRAY _v
		LOOP
			IF i IS NULL THEN
				acname := concat(_ar, '_', _csn, '_', _r.property_name);
				propv := NULL;
			ELSE
				acname := concat(_ar, '_', _csn, '_', i);
				propv := i;
			END IF;

			INSERT INTO account_collection (
				account_collection_name, account_collection_type
			) VALUES (
				acname, 'automated'
			) RETURNING account_collection_id INTO acid;

			INSERT INTO property (
				property_name, property_type, account_realm_id,
				account_collection_id,
				company_id, property_value
			) VALUES (
				_r.property_name, _r.property_type, _account_realm_id,
				acid,
				_company_id, propv
			);
			tally := tally + 1;
		END LOOP;
	END LOOP;
END;
$$ 
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

--
-- add site based automated account collections for the given realm to be
-- automanaged by trigger.
--
-- NOTE:  There is no remove_auto_collections_site.
--
CREATE OR REPLACE FUNCTION company_manip.add_auto_collections_site(
	_company_id		company.company_id%type,
	_account_realm_id	account_realm.account_realm_id%type,
	_site_code		site.site_code%type
) RETURNS void AS
$$
DECLARE
	_ar		account_realm.account_realm_name%TYPE;
	_csn	company.company_short_name%TYPE;
	acname	account_collection.account_collection_name%TYPE;
	acid	account_collection.account_collection_id%TYPE;
	tally	integer;
BEGIN
	PERFORM
	FROM	account_realm_company
	WHERE	company_id = _company_id
	AND		account_realm_id = _account_realm_id;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Company and Account Realm are not associated together'
			USING ERRCODE = 'not_null_violation';
	END IF;

	acname := concat(_ar, '_', _site_code);

	INSERT INTO account_collection (
		account_collection_name, account_collection_type
	) VALUES (
		acname, 'automated'
	) RETURNING account_collection_id INTO acid;

	INSERT INTO property (
		property_name, property_type, account_realm_id,
		account_collection_id,
		site_code
	) VALUES (
		'site', 'auto_acct_coll', _account_realm_id,
		acid,
		_site_code
	);
	tally := tally + 1;
END;
$$ 
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;



------------------------------------------------------------------------------

--
-- addds company types to company, and sets up any automated classes
-- associated via company_manip.add_auto_collections.
--
-- note that there is no 'remove_company_types'
--
CREATE OR REPLACE FUNCTION company_manip.add_company_types(
	_company_id		company.company_id%type,
	_account_realm_id	account_realm.account_realm_id%type DEFAULT NULL,
	_company_types	text[] default NULL
) RETURNS integer AS
$$
DECLARE
	x		text;
	count	integer;
BEGIN
	count := 0;
	FOREACH x IN ARRAY _company_types
	LOOP
		INSERT INTO company_type (company_id, company_type)
			VALUES (_company_id, x);
		PERFORM company_manip.add_auto_collections(_company_id, _account_realm_id, x);
		count := count + 1;
	END LOOP;
	return count;
END;
$$ 
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

------------------------------------------------------------------------------

--
-- primary interface to add things to the company table.  It does other
-- necessary manipulations based on company types.
--
-- shortname is inferred if not set
--
-- NOTE: There is no remove_company.
--
CREATE OR REPLACE FUNCTION company_manip.add_company(
	_company_name		text,
	_company_types		text[] default NULL,
	_parent_company_id	company.company_id%type DEFAULT NULL,
	_account_realm_id	account_realm.account_realm_id%type DEFAULT NULL,
	_company_short_name	text DEFAULT NULL,
	_description		text DEFAULT NULL

) RETURNS integer AS
$$
DECLARE
	_cmpid	company.company_id%type;
	_short	text;
	_isfam	char(1);
BEGIN
	IF _company_types @> ARRAY['corporate family'] THEN
		_isfam := 'Y';
	ELSE
		_isfam := 'N';
	END IF;
	IF _company_short_name IS NULL and _isfam = 'Y' THEN
		_short := lower(regexp_replace(
				regexp_replace(
					regexp_replace(_company_name, 
						E'\\s+(ltd|sarl|limited|pt[ye]|GmbH|ag|ab|inc)', 
						'', 'gi'),
					E'[,\\.\\$#@]', '', 'mg'),
				E'\\s+', '_', 'gi'));
	END IF;

	INSERT INTO company (
		company_name, company_short_name, is_corporate_family,
		parent_company_id, description
	) VALUES (
		_company_name, _short, _isfam,
		_parent_company_id, _description
	) RETURNING company_id INTO _cmpid;

	IF _account_realm_id IS NOT NULL THEN
		INSERT INTO account_realm_company (
			account_realm_id, company_id
		) VALUES (
			_account_realm_id, _cmpid
		);
	END IF;

	IF _company_types IS NOT NULL THEN
		PERFORM company_manip.add_company_types(_cmpid, _account_realm_id, _company_types);
	END IF;

	RETURN _cmpid;
END;
$$ 
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

------------------------------------------------------------------------------
--
-- Adds a location to a company with the given site code and address.  It will
-- take are of any automated account collections that are needed.
--
-- NOTE: There is no remove_location.
--
CREATE OR REPLACE FUNCTION company_manip.add_location(
	_company_id		company.company_id%type,
	_site_code		site.site_code%type,
	_physical_address_id	physical_address.physical_address_id%type,
	_account_realm_id	account_realm.account_realm_id%type DEFAULT NULL,
	_site_status		site.site_status%type DEFAULT 'ACTIVE',
	_description		text DEFAULT NULL
) RETURNS void AS
$$
DECLARE
BEGIN
	INSERT INTO site (site_code, colo_company_id,
		physical_address_id, site_status, description
	) VALUES (
		_site_code, _company_id,
		_physical_address_id, _site_status, _description
	);

	if _account_realm_id IS NOT NULL THEN
		PERFORM company_manip.add_auto_collections_site(
			_company_id,
			_account_realm_id,
			_site_code
		);
	END IF;
END;
$$ 
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

--------------------------------------------------------------------
-- END add company_manip
--------------------------------------------------------------------

--------------------------------------------------------------------
-- BEGIN AUTOGEN DDL
--------------------------------------------------------------------


/*
Invoked:

	--scan-tables
	--suffix=v59
	netblock_utils.calculate_intermediate_netblocks
	netblock_manip.allocate_netblock
	delete_peraccount_account_collection
	update_peraccount_account_collection
	asset
	device_type
	device
	val_volume_group_relation
	val_logical_volume_property
	val_component_property
	val_raid_type
	val_slot_function
	val_component_function
	val_filesystem_type
	val_slot_physical_interface
	val_component_property_value
	val_component_property_type
	slot_type_prmt_rem_slot_type
	inter_component_connection
	component_type
	component_property
	component_type_slot_tmplt
	slot_type_prmt_comp_slot_type
	slot_type
	logical_port_slot
	slot
	component_type_component_func
	component
	physicalish_volume
	volume_group_physicalish_vol
	logical_volume
	logical_volume_property
	volume_group
	delete_peruser_account_collection
	update_peruser_account_collection
	netblock_utils.list_unallocated_netblocks
	person_manip.purge_account
	automated_ac_on_account
	automated_ac_on_person_company
	automated_ac_on_person
	automated_realm_site_ac_pl
*/

\set ON_ERROR_STOP
-- Creating new sequences....
CREATE SEQUENCE logical_volume_logical_volume_id_seq;
CREATE SEQUENCE component_component_id_seq;
CREATE SEQUENCE inter_component_connection_inter_component_connection_id_seq;
CREATE SEQUENCE component_property_component_property_id_seq;
CREATE SEQUENCE physicalish_volume_physicalish_volume_id_seq;
CREATE SEQUENCE component_type_component_type_id_seq;
CREATE SEQUENCE slot_slot_id_seq;
CREATE SEQUENCE component_type_slot_tmplt_component_type_slot_tmplt_id_seq;
CREATE SEQUENCE volume_group_volume_group_id_seq;
CREATE SEQUENCE slot_type_slot_type_id_seq;


--------------------------------------------------------------------
-- DEALING WITH TABLE val_property_type [538947]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'val_property_type', 'val_property_type');

-- FOREIGN KEYS FROM
ALTER TABLE val_property DROP CONSTRAINT IF EXISTS fk_valprop_proptyp;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.val_property_type DROP CONSTRAINT IF EXISTS fk_prop_typ_pv_uctyp_rst;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_property_type');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_property_type DROP CONSTRAINT IF EXISTS pk_val_property_type;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif1val_property_type";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.val_property_type DROP CONSTRAINT IF EXISTS ckc_val_prop_typ_ismulti;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_property_type ON jazzhands.val_property_type;
DROP TRIGGER IF EXISTS trig_userlog_val_property_type ON jazzhands.val_property_type;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_property_type');
---- BEGIN audit.val_property_type TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_property_type');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_property_type_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_property_type');
---- DONE audit.val_property_type TEARDOWN


ALTER TABLE val_property_type RENAME TO val_property_type_v59;
ALTER TABLE audit.val_property_type RENAME TO val_property_type_v59;

CREATE TABLE val_property_type
(
	property_type	varchar(50) NOT NULL,
	description	varchar(255)  NULL,
	prop_val_acct_coll_type_rstrct	varchar(50)  NULL,
	is_multivalue	character(1) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_property_type', false);
ALTER TABLE val_property_type
	ALTER is_multivalue
	SET DEFAULT 'Y'::bpchar;
INSERT INTO val_property_type (
	property_type,
	description,
	prop_val_acct_coll_type_rstrct,
	is_multivalue,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	property_type,
	description,
	prop_val_acct_coll_type_rstrct,
	is_multivalue,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM val_property_type_v59;

INSERT INTO audit.val_property_type (
	property_type,
	description,
	prop_val_acct_coll_type_rstrct,
	is_multivalue,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	property_type,
	description,
	prop_val_acct_coll_type_rstrct,
	is_multivalue,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.val_property_type_v59;

ALTER TABLE val_property_type
	ALTER is_multivalue
	SET DEFAULT 'Y'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_property_type ADD CONSTRAINT pk_val_property_type PRIMARY KEY (property_type);

-- Table/Column Comments
COMMENT ON TABLE val_property_type IS 'validation table for property types';
COMMENT ON COLUMN val_property_type.is_multivalue IS 'If N, this acts like an alternate key on lhs,property_type';
-- INDEXES
CREATE INDEX xif1val_property_type ON val_property_type USING btree (prop_val_acct_coll_type_rstrct);

-- CHECK CONSTRAINTS
ALTER TABLE val_property_type ADD CONSTRAINT ckc_val_prop_typ_ismulti
	CHECK (is_multivalue = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK val_property_type and val_property
ALTER TABLE val_property
	ADD CONSTRAINT fk_valprop_proptyp
	FOREIGN KEY (property_type) REFERENCES val_property_type(property_type);

-- FOREIGN KEYS TO
-- consider FK val_property_type and val_account_collection_type
ALTER TABLE val_property_type
	ADD CONSTRAINT fk_prop_typ_pv_uctyp_rst
	FOREIGN KEY (prop_val_acct_coll_type_rstrct) REFERENCES val_account_collection_type(account_collection_type);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_property_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_property_type');
DROP TABLE IF EXISTS val_property_type_v59;
DROP TABLE IF EXISTS audit.val_property_type_v59;
-- DONE DEALING WITH TABLE val_property_type [546738]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_property [538886]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'val_property', 'val_property');

-- FOREIGN KEYS FROM
ALTER TABLE property_collection_property DROP CONSTRAINT IF EXISTS fk_prop_col_propnamtyp;
ALTER TABLE val_property_value DROP CONSTRAINT IF EXISTS fk_valproval_namtyp;
ALTER TABLE property DROP CONSTRAINT IF EXISTS fk_property_nmtyp;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_propdttyp;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_proptyp;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_val_prop_nblk_coll_type;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_pv_actyp_rst;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_property');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS pk_val_property;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif3val_property";
DROP INDEX IF EXISTS "jazzhands"."xif1val_property";
DROP INDEX IF EXISTS "jazzhands"."xif2val_property";
DROP INDEX IF EXISTS "jazzhands"."xif4val_property";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_osid;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pucls_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_cmp_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_2016888554;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_ismulti;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_354296970;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_sitec;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_prodstate;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pacct_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1279736247;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_606225804;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_271462566;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pdnsdomid;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_2139007167;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1279736503;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pdevcol_id;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_val_property ON jazzhands.val_property;
DROP TRIGGER IF EXISTS trigger_audit_val_property ON jazzhands.val_property;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_property');
---- BEGIN audit.val_property TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_property');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_property_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_property');
---- DONE audit.val_property TEARDOWN


ALTER TABLE val_property RENAME TO val_property_v59;
ALTER TABLE audit.val_property RENAME TO val_property_v59;

CREATE TABLE val_property
(
	property_name	varchar(255) NOT NULL,
	property_type	varchar(50) NOT NULL,
	description	varchar(255)  NULL,
	is_multivalue	character(1) NOT NULL,
	prop_val_acct_coll_type_rstrct	varchar(50)  NULL,
	prop_val_nblk_coll_type_rstrct	varchar(50)  NULL,
	property_data_type	varchar(50) NOT NULL,
	permit_account_collection_id	character(10) NOT NULL,
	permit_account_id	character(10) NOT NULL,
	permit_account_realm_id	character(10) NOT NULL,
	permit_company_id	character(10) NOT NULL,
	permit_device_collection_id	character(10) NOT NULL,
	permit_dns_domain_id	character(10) NOT NULL,
	permit_layer2_network_id	character(10) NOT NULL,
	permit_layer3_network_id	character(10) NOT NULL,
	permit_netblock_collection_id	character(10) NOT NULL,
	permit_operating_system_id	character(10) NOT NULL,
	permit_person_id	character(10) NOT NULL,
	permit_property_collection_id	character(10) NOT NULL,
	permit_service_env_collection	character(10) NOT NULL,
	permit_site_code	character(10) NOT NULL,
	permit_property_rank	character(10) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_property', false);
ALTER TABLE val_property
	ALTER is_multivalue
	SET DEFAULT 'N'::bpchar;
ALTER TABLE val_property
	ALTER permit_account_collection_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_account_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_account_realm_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_company_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_device_collection_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_dns_domain_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_layer2_network_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_layer3_network_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_netblock_collection_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_operating_system_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_person_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_property_collection_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_service_env_collection
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_site_code
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_property_rank
	SET DEFAULT 'PROHIBITED'::bpchar;
INSERT INTO val_property (
	property_name,
	property_type,
	description,
	is_multivalue,
	prop_val_acct_coll_type_rstrct,
	prop_val_nblk_coll_type_rstrct,
	property_data_type,
	permit_account_collection_id,
	permit_account_id,
	permit_account_realm_id,
	permit_company_id,
	permit_device_collection_id,
	permit_dns_domain_id,
	permit_layer2_network_id,
	permit_layer3_network_id,
	permit_netblock_collection_id,
	permit_operating_system_id,
	permit_person_id,
	permit_property_collection_id,
	permit_service_env_collection,
	permit_site_code,
	permit_property_rank,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	property_name,
	property_type,
	description,
	is_multivalue,
	prop_val_acct_coll_type_rstrct,
	prop_val_nblk_coll_type_rstrct,
	property_data_type,
	permit_account_collection_id,
	permit_account_id,
	permit_account_realm_id,
	permit_company_id,
	permit_device_collection_id,
	permit_dns_domain_id,
	permit_layer2_network_id,
	permit_layer3_network_id,
	permit_netblock_collection_id,
	permit_operating_system_id,
	permit_person_id,
	permit_property_collection_id,
	permit_service_env_collection,
	permit_site_code,
	permit_property_rank,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM val_property_v59;

INSERT INTO audit.val_property (
	property_name,
	property_type,
	description,
	is_multivalue,
	prop_val_acct_coll_type_rstrct,
	prop_val_nblk_coll_type_rstrct,
	property_data_type,
	permit_account_collection_id,
	permit_account_id,
	permit_account_realm_id,
	permit_company_id,
	permit_device_collection_id,
	permit_dns_domain_id,
	permit_layer2_network_id,
	permit_layer3_network_id,
	permit_netblock_collection_id,
	permit_operating_system_id,
	permit_person_id,
	permit_property_collection_id,
	permit_service_env_collection,
	permit_site_code,
	permit_property_rank,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	property_name,
	property_type,
	description,
	is_multivalue,
	prop_val_acct_coll_type_rstrct,
	prop_val_nblk_coll_type_rstrct,
	property_data_type,
	permit_account_collection_id,
	permit_account_id,
	permit_account_realm_id,
	permit_company_id,
	permit_device_collection_id,
	permit_dns_domain_id,
	permit_layer2_network_id,
	permit_layer3_network_id,
	permit_netblock_collection_id,
	permit_operating_system_id,
	permit_person_id,
	permit_property_collection_id,
	permit_service_env_collection,
	permit_site_code,
	permit_property_rank,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.val_property_v59;

ALTER TABLE val_property
	ALTER is_multivalue
	SET DEFAULT 'N'::bpchar;
ALTER TABLE val_property
	ALTER permit_account_collection_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_account_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_account_realm_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_company_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_device_collection_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_dns_domain_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_layer2_network_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_layer3_network_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_netblock_collection_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_operating_system_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_person_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_property_collection_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_service_env_collection
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_site_code
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_property
	ALTER permit_property_rank
	SET DEFAULT 'PROHIBITED'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_property ADD CONSTRAINT pk_val_property PRIMARY KEY (property_name, property_type);

-- Table/Column Comments
COMMENT ON TABLE val_property IS 'valid values and attributes for (name,type) pairs in the property table';
COMMENT ON COLUMN val_property.property_name IS 'property name for validation purposes';
COMMENT ON COLUMN val_property.property_type IS 'property type for validation purposes';
COMMENT ON COLUMN val_property.is_multivalue IS 'If N, acts like an alternate key on property.(lhs,property_type)';
COMMENT ON COLUMN val_property.property_data_type IS 'which of the property_table_* columns should be used for this value';
COMMENT ON COLUMN val_property.permit_account_collection_id IS 'defines how company id should be used in the property for this (name,type)';
COMMENT ON COLUMN val_property.permit_account_id IS 'defines how company id should be used in the property for this (name,type)';
COMMENT ON COLUMN val_property.permit_company_id IS 'defines how company id should be used in the property for this (name,type)';
COMMENT ON COLUMN val_property.permit_device_collection_id IS 'defines how company id should be used in the property for this (name,type)';
COMMENT ON COLUMN val_property.permit_dns_domain_id IS 'defines how company id should be used in the property for this (name,type)';
-- INDEXES
CREATE INDEX xif3val_property ON val_property USING btree (prop_val_acct_coll_type_rstrct);
CREATE INDEX xif4val_property ON val_property USING btree (prop_val_nblk_coll_type_rstrct);
CREATE INDEX xif1val_property ON val_property USING btree (property_data_type);
CREATE INDEX xif2val_property ON val_property USING btree (property_type);

-- CHECK CONSTRAINTS
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_prodstate
	CHECK (permit_service_env_collection = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pacct_id
	CHECK (permit_account_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_1279736247
	CHECK (permit_layer3_network_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_606225804
	CHECK (permit_person_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_271462566
	CHECK (permit_property_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pdnsdomid
	CHECK (permit_dns_domain_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_2139007167
	CHECK (permit_property_rank = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_1279736503
	CHECK (permit_layer2_network_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pdevcol_id
	CHECK (permit_device_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_osid
	CHECK (permit_operating_system_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pucls_id
	CHECK (permit_account_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_cmp_id
	CHECK (permit_company_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_2016888554
	CHECK (permit_account_realm_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_ismulti
	CHECK (is_multivalue = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_354296970
	CHECK (permit_netblock_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_sitec
	CHECK (permit_site_code = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK val_property and property
ALTER TABLE property
	ADD CONSTRAINT fk_property_nmtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);
-- consider FK val_property and val_property_value
ALTER TABLE val_property_value
	ADD CONSTRAINT fk_valproval_namtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);
-- consider FK val_property and property_collection_property
ALTER TABLE property_collection_property
	ADD CONSTRAINT fk_prop_col_propnamtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);

-- FOREIGN KEYS TO
-- consider FK val_property and val_property_data_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_valprop_propdttyp
	FOREIGN KEY (property_data_type) REFERENCES val_property_data_type(property_data_type);
-- consider FK val_property and val_property_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_valprop_proptyp
	FOREIGN KEY (property_type) REFERENCES val_property_type(property_type);
-- consider FK val_property and val_account_collection_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_valprop_pv_actyp_rst
	FOREIGN KEY (prop_val_acct_coll_type_rstrct) REFERENCES val_account_collection_type(account_collection_type);
-- consider FK val_property and val_netblock_collection_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_val_prop_nblk_coll_type
	FOREIGN KEY (prop_val_nblk_coll_type_rstrct) REFERENCES val_netblock_collection_type(netblock_collection_type);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_property');
DROP TABLE IF EXISTS val_property_v59;
DROP TABLE IF EXISTS audit.val_property_v59;
-- DONE DEALING WITH TABLE val_property [546676]
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH proc netblock_utils.calculate_intermediate_netblocks -> calculate_intermediate_netblocks 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('netblock_utils', 'calculate_intermediate_netblocks', 'calculate_intermediate_netblocks');

-- DROP OLD FUNCTION
-- consider old oid 544116
DROP FUNCTION IF EXISTS netblock_utils.calculate_intermediate_netblocks(ip_block_1 inet, ip_block_2 inet);

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider old oid 544116
DROP FUNCTION IF EXISTS netblock_utils.calculate_intermediate_netblocks(ip_block_1 inet, ip_block_2 inet);
-- consider NEW oid 552584
CREATE OR REPLACE FUNCTION netblock_utils.calculate_intermediate_netblocks(ip_block_1 inet DEFAULT NULL::inet, ip_block_2 inet DEFAULT NULL::inet, netblock_type text DEFAULT 'default'::text, ip_universe_id integer DEFAULT 0)
 RETURNS TABLE(ip_addr inet)
 LANGUAGE plpgsql
AS $function$
DECLARE
	current_nb		inet;
	new_nb			inet;
	min_addr		inet;
	max_addr		inet;
BEGIN
	IF ip_block_1 IS NULL OR ip_block_2 IS NULL THEN
		RAISE EXCEPTION 'Must specify both ip_block_1 and ip_block_2';
	END IF;

	IF family(ip_block_1) != family(ip_block_2) THEN
		RAISE EXCEPTION 'families of ip_block_1 and ip_block_2 must match';
	END IF;

	-- Make sure these are network blocks
	ip_block_1 := network(ip_block_1);
	ip_block_2 := network(ip_block_2);

	-- If the blocks are subsets of each other, then error

	IF ip_block_1 <<= ip_block_2 OR ip_block_2 <<= ip_block_1 THEN
		RAISE EXCEPTION 'netblocks intersect each other';
	END IF;

	-- Order the blocks correctly

	IF ip_block_1 > ip_block_2 THEN
		new_nb := ip_block_1;
		ip_block_1 := ip_block_2;
		ip_block_2 := new_nb;
	END IF;

	current_nb := ip_block_1;
	max_addr := broadcast(ip_block_1);

	-- Loop through bumping the netmask up and seeing if the destination block is in the new block
	LOOP
		new_nb := network(set_masklen(current_nb, masklen(current_nb) - 1));

		-- If the block is in our new larger netblock, then exit this loop
		IF (new_nb >>= ip_block_2) THEN
			current_nb := broadcast(current_nb) + 1;
			EXIT;
		END IF;
	
		-- If the max address of the new netblock is larger than the last one, then it's empty
		IF set_masklen(broadcast(new_nb), 32) > set_masklen(max_addr, 32) THEN
			ip_addr := set_masklen(max_addr + 1, masklen(current_nb));
			-- Validate that this isn't an empty can_subnet='Y' block already
			-- If it is, split it in half and return both halves
			PERFORM * FROM netblock n WHERE
				n.ip_address = ip_addr AND
				n.ip_universe_id =
					calculate_intermediate_netblocks.ip_universe_id AND
				n.netblock_type =
					calculate_intermediate_netblocks.netblock_type;
			IF FOUND THEN
				ip_addr := set_masklen(ip_addr, masklen(ip_addr) + 1);
				RETURN NEXT;
				ip_addr := broadcast(ip_addr) + 1;
				RETURN NEXT;
			ELSE
				RETURN NEXT;
			END IF;
			max_addr := broadcast(new_nb);
		END IF;
		current_nb := new_nb;
	END LOOP;

	-- Now loop through there to find the unused blocks at the front

	LOOP
		IF host(current_nb) = host(ip_block_2) THEN
			RETURN;
		END IF;
		current_nb := set_masklen(current_nb, masklen(current_nb) + 1);
		IF NOT (current_nb >>= ip_block_2) THEN
			ip_addr := current_nb;
			-- Validate that this isn't an empty can_subnet='Y' block already
			-- If it is, split it in half and return both halves
			PERFORM * FROM netblock n WHERE
				n.ip_address = ip_addr AND
				n.ip_universe_id =
					calculate_intermediate_netblocks.ip_universe_id AND
				n.netblock_type =
					calculate_intermediate_netblocks.netblock_type;
			IF FOUND THEN
				ip_addr := set_masklen(ip_addr, masklen(ip_addr) + 1);
				RAISE NOTICE 'IP is %', ip_addr;
				RETURN NEXT;
				ip_addr := broadcast(ip_addr) + 1;
				RETURN NEXT;
			ELSE
				RETURN NEXT;
			END IF;
			current_nb := broadcast(current_nb) + 1;
			CONTINUE;
		END IF;
	END LOOP;
	RETURN;
END;
$function$
;

-- DONE WITH proc netblock_utils.calculate_intermediate_netblocks -> calculate_intermediate_netblocks 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc netblock_manip.allocate_netblock -> allocate_netblock 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('netblock_manip', 'allocate_netblock', 'allocate_netblock');

-- DROP OLD FUNCTION
-- consider old oid 544121
DROP FUNCTION IF EXISTS netblock_manip.allocate_netblock(parent_netblock_id integer, netmask_bits integer, address_type text, can_subnet boolean, allocation_method text, rnd_masklen_threshold integer, rnd_max_count integer, ip_address inet, description character varying, netblock_status character varying);
-- consider old oid 544122
DROP FUNCTION IF EXISTS netblock_manip.allocate_netblock(parent_netblock_list integer[], netmask_bits integer, address_type text, can_subnet boolean, allocation_method text, rnd_masklen_threshold integer, rnd_max_count integer, ip_address inet, description character varying, netblock_status character varying);

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider old oid 544121
DROP FUNCTION IF EXISTS netblock_manip.allocate_netblock(parent_netblock_id integer, netmask_bits integer, address_type text, can_subnet boolean, allocation_method text, rnd_masklen_threshold integer, rnd_max_count integer, ip_address inet, description character varying, netblock_status character varying);
-- consider old oid 544122
DROP FUNCTION IF EXISTS netblock_manip.allocate_netblock(parent_netblock_list integer[], netmask_bits integer, address_type text, can_subnet boolean, allocation_method text, rnd_masklen_threshold integer, rnd_max_count integer, ip_address inet, description character varying, netblock_status character varying);
-- consider NEW oid 552589
CREATE OR REPLACE FUNCTION netblock_manip.allocate_netblock(parent_netblock_id integer, netmask_bits integer DEFAULT NULL::integer, address_type text DEFAULT 'netblock'::text, can_subnet boolean DEFAULT true, allocation_method text DEFAULT NULL::text, rnd_masklen_threshold integer DEFAULT 110, rnd_max_count integer DEFAULT 1024, ip_address inet DEFAULT NULL::inet, description character varying DEFAULT NULL::character varying, netblock_status character varying DEFAULT 'Allocated'::character varying)
 RETURNS netblock
 LANGUAGE plpgsql
AS $function$
DECLARE
	netblock_rec	RECORD;
BEGIN
	SELECT * into netblock_rec FROM netblock_manip.allocate_netblock(
		parent_netblock_list := ARRAY[parent_netblock_id],
		netmask_bits := netmask_bits,
		address_type := address_type,
		can_subnet := can_subnet,
		description := description,
		allocation_method := allocation_method,
		ip_address := ip_address,
		rnd_masklen_threshold := rnd_masklen_threshold,
		rnd_max_count := rnd_max_count,
		netblock_status := netblock_status
	);
	RETURN netblock_rec;
END;
$function$
;
-- consider NEW oid 552590
CREATE OR REPLACE FUNCTION netblock_manip.allocate_netblock(parent_netblock_list integer[], netmask_bits integer DEFAULT NULL::integer, address_type text DEFAULT 'netblock'::text, can_subnet boolean DEFAULT true, allocation_method text DEFAULT NULL::text, rnd_masklen_threshold integer DEFAULT 110, rnd_max_count integer DEFAULT 1024, ip_address inet DEFAULT NULL::inet, description character varying DEFAULT NULL::character varying, netblock_status character varying DEFAULT 'Allocated'::character varying)
 RETURNS netblock
 LANGUAGE plpgsql
AS $function$
DECLARE
	parent_rec		RECORD;
	netblock_rec	RECORD;
	inet_rec		RECORD;
	loopback_bits	integer;
	inet_family		integer;
BEGIN
	IF parent_netblock_list IS NULL THEN
		RAISE 'parent_netblock_list must be specified'
		USING ERRCODE = 'null_value_not_allowed';
	END IF;

	IF address_type NOT IN ('netblock', 'single', 'loopback') THEN
		RAISE 'address_type must be one of netblock, single, or loopback'
		USING ERRCODE = 'invalid_parameter_value';
	END IF;

	IF netmask_bits IS NULL AND address_type = 'netblock' THEN
		RAISE EXCEPTION
			'You must specify a netmask when address_type is netblock'
			USING ERRCODE = 'invalid_parameter_value';
	END IF;

	-- Lock the parent row, which should keep parallel processes from
	-- trying to obtain the same address

	FOR parent_rec IN SELECT * FROM jazzhands.netblock WHERE netblock_id = 
			ANY(allocate_netblock.parent_netblock_list) FOR UPDATE LOOP

		IF parent_rec.is_single_address = 'Y' THEN
			RAISE EXCEPTION 'parent_netblock_id refers to a single_address netblock'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;

		IF inet_family IS NULL THEN
			inet_family := family(parent_rec.ip_address);
		ELSIF inet_family != family(parent_rec.ip_address) 
				AND ip_address IS NULL THEN
			RAISE EXCEPTION 'Allocation may not mix IPv4 and IPv6 addresses'
			USING ERRCODE = 'JH10F';
		END IF;

		IF address_type = 'loopback' THEN
			loopback_bits := 
				CASE WHEN 
					family(parent_rec.ip_address) = 4 THEN 32 ELSE 128 END;

			IF parent_rec.can_subnet = 'N' THEN
				RAISE EXCEPTION 'parent subnet must have can_subnet set to Y'
					USING ERRCODE = 'JH10B';
			END IF;
		ELSIF address_type = 'single' THEN
			IF parent_rec.can_subnet = 'Y' THEN
				RAISE EXCEPTION
					'parent subnet for single address must have can_subnet set to N'
					USING ERRCODE = 'JH10B';
			END IF;
		ELSIF address_type = 'netblock' THEN
			IF parent_rec.can_subnet = 'N' THEN
				RAISE EXCEPTION 'parent subnet must have can_subnet set to Y'
					USING ERRCODE = 'JH10B';
			END IF;
		END IF;
	END LOOP;

 	IF NOT FOUND THEN
 		RETURN NULL;
 	END IF;

	IF address_type = 'loopback' THEN
		-- If we're allocating a loopback address, then we need to create
		-- a new parent to hold the single loopback address

		SELECT * INTO inet_rec FROM netblock_utils.find_free_netblocks(
			parent_netblock_list := parent_netblock_list,
			netmask_bits := loopback_bits,
			single_address := false,
			allocation_method := allocation_method,
			desired_ip_address := ip_address,
			max_addresses := 1
			);

		IF NOT FOUND THEN
			RETURN NULL;
		END IF;

		INSERT INTO jazzhands.netblock (
			ip_address,
			netblock_type,
			is_single_address,
			can_subnet,
			ip_universe_id,
			description,
			netblock_status
		) VALUES (
			inet_rec.ip_address,
			inet_rec.netblock_type,
			'N',
			'N',
			inet_rec.ip_universe_id,
			allocate_netblock.description,
			allocate_netblock.netblock_status
		) RETURNING * INTO parent_rec;

		INSERT INTO jazzhands.netblock (
			ip_address,
			netblock_type,
			is_single_address,
			can_subnet,
			ip_universe_id,
			description,
			netblock_status
		) VALUES (
			inet_rec.ip_address,
			parent_rec.netblock_type,
			'Y',
			'N',
			inet_rec.ip_universe_id,
			allocate_netblock.description,
			allocate_netblock.netblock_status
		) RETURNING * INTO netblock_rec;

		RETURN netblock_rec;
	END IF;

	IF address_type = 'single' THEN
		SELECT * INTO inet_rec FROM netblock_utils.find_free_netblocks(
			parent_netblock_list := parent_netblock_list,
			single_address := true,
			allocation_method := allocation_method,
			desired_ip_address := ip_address,
			rnd_masklen_threshold := rnd_masklen_threshold,
			rnd_max_count := rnd_max_count,
			max_addresses := 1
			);

		IF NOT FOUND THEN
			RETURN NULL;
		END IF;

		RAISE DEBUG 'ip_address is %', inet_rec.ip_address;

		INSERT INTO jazzhands.netblock (
			ip_address,
			netblock_type,
			is_single_address,
			can_subnet,
			ip_universe_id,
			description,
			netblock_status
		) VALUES (
			inet_rec.ip_address,
			inet_rec.netblock_type,
			'Y',
			'N',
			inet_rec.ip_universe_id,
			allocate_netblock.description,
			allocate_netblock.netblock_status
		) RETURNING * INTO netblock_rec;

		RETURN netblock_rec;
	END IF;
	IF address_type = 'netblock' THEN
		SELECT * INTO inet_rec FROM netblock_utils.find_free_netblocks(
			parent_netblock_list := parent_netblock_list,
			netmask_bits := netmask_bits,
			single_address := false,
			allocation_method := allocation_method,
			desired_ip_address := ip_address,
			max_addresses := 1);

		IF NOT FOUND THEN
			RETURN NULL;
		END IF;

		INSERT INTO jazzhands.netblock (
			ip_address,
			netblock_type,
			is_single_address,
			can_subnet,
			ip_universe_id,
			description,
			netblock_status
		) VALUES (
			inet_rec.ip_address,
			inet_rec.netblock_type,
			'N',
			CASE WHEN can_subnet THEN 'Y' ELSE 'N' END,
			inet_rec.ip_universe_id,
			allocate_netblock.description,
			allocate_netblock.netblock_status
		) RETURNING * INTO netblock_rec;

		RETURN netblock_rec;
	END IF;
END;
$function$
;

-- DONE WITH proc netblock_manip.allocate_netblock -> allocate_netblock 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc delete_peraccount_account_collection -> delete_peraccount_account_collection 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 552616
CREATE OR REPLACE FUNCTION jazzhands.delete_peraccount_account_collection()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	acid			account_collection.account_collection_id%TYPE;
BEGIN
	IF TG_OP = 'DELETE' THEN
		SELECT	account_collection_id
		  INTO	acid
		  FROM	account_collection ac
				INNER JOIN account_collection_account aca
					USING (account_collection_id)
		 WHERE	aca.account_id = OLD.account_Id
		   AND	ac.account_collection_type = 'per-account';

		 DELETE from account_collection_account
		  where account_collection_id = acid;

		 DELETE from account_collection
		  where account_collection_id = acid;
	END IF;
	RETURN OLD;
END;
$function$
;

-- DONE WITH proc delete_peraccount_account_collection -> delete_peraccount_account_collection 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc update_peraccount_account_collection -> update_peraccount_account_collection 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 552618
CREATE OR REPLACE FUNCTION jazzhands.update_peraccount_account_collection()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	def_acct_rlm	account_realm.account_realm_id%TYPE;
	acid			account_collection.account_collection_id%TYPE;
DECLARE
	newname	TEXT;
BEGIN
	newname = concat(NEW.login, '_', NEW.account_id);
	if TG_OP = 'INSERT' THEN
		insert into account_collection 
			(account_collection_name, account_collection_type)
		values
			(newname, 'per-account')
		RETURNING account_collection_id INTO acid;
		insert into account_collection_account 
			(account_collection_id, account_id)
		VALUES
			(acid, NEW.account_id);
	END IF;

	IF TG_OP = 'UPDATE' AND OLD.login != NEW.login THEN
		UPDATE	account_collection
		    set	account_collection_name = newname
		  where	account_collection_type = 'per-account'
		    and	account_collection_id = (
				SELECT	account_collection_id
		  		FROM	account_collection ac
						INNER JOIN account_collection_account aca
							USING (account_collection_id)
		 		WHERE	aca.account_id = OLD.account_Id
		   		AND	ac.account_collection_type = 'per-account'
			);
	END IF;
	return NEW;
END;
$function$
;

-- DONE WITH proc update_peraccount_account_collection -> update_peraccount_account_collection 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH TABLE asset [536985]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'asset', 'asset');

-- FOREIGN KEYS FROM
ALTER TABLE device DROP CONSTRAINT IF EXISTS fk_device_asset_id;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.asset DROP CONSTRAINT IF EXISTS fk_asset_contract_id;
ALTER TABLE jazzhands.asset DROP CONSTRAINT IF EXISTS fk_asset_ownshp_stat;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'asset');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.asset DROP CONSTRAINT IF EXISTS pk_asset;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_asset_ownshp_stat";
DROP INDEX IF EXISTS "jazzhands"."xif_asset_contract_id";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_asset ON jazzhands.asset;
DROP TRIGGER IF EXISTS trig_userlog_asset ON jazzhands.asset;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'asset');
---- BEGIN audit.asset TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'asset');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."asset_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'asset');
---- DONE audit.asset TEARDOWN


ALTER TABLE asset RENAME TO asset_v59;
ALTER TABLE audit.asset RENAME TO asset_v59;

CREATE TABLE asset
(
	asset_id	integer NOT NULL,
	component_id	integer  NULL,
	description	varchar(255)  NULL,
	contract_id	integer  NULL,
	serial_number	varchar(255)  NULL,
	part_number	varchar(255)  NULL,
	asset_tag	varchar(255)  NULL,
	ownership_status	varchar(50) NOT NULL,
	lease_expiration_date	timestamp with time zone  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'asset', false);
ALTER TABLE asset
	ALTER asset_id
	SET DEFAULT nextval('asset_asset_id_seq'::regclass);
INSERT INTO asset (
	asset_id,
	component_id,		-- new column (component_id)
	description,
	contract_id,
	serial_number,
	part_number,
	asset_tag,
	ownership_status,
	lease_expiration_date,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	asset_id,
	NULL,		-- new column (component_id)
	description,
	contract_id,
	serial_number,
	part_number,
	asset_tag,
	ownership_status,
	lease_expiration_date,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM asset_v59;

INSERT INTO audit.asset (
	asset_id,
	component_id,		-- new column (component_id)
	description,
	contract_id,
	serial_number,
	part_number,
	asset_tag,
	ownership_status,
	lease_expiration_date,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	asset_id,
	NULL,		-- new column (component_id)
	description,
	contract_id,
	serial_number,
	part_number,
	asset_tag,
	ownership_status,
	lease_expiration_date,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.asset_v59;

ALTER TABLE asset
	ALTER asset_id
	SET DEFAULT nextval('asset_asset_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE asset ADD CONSTRAINT ak_asset_component_id UNIQUE (component_id);
ALTER TABLE asset ADD CONSTRAINT pk_asset PRIMARY KEY (asset_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_asset_contract_id ON asset USING btree (contract_id);
CREATE INDEX xif_asset_ownshp_stat ON asset USING btree (ownership_status);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK asset and device
ALTER TABLE device
	ADD CONSTRAINT fk_device_asset_id
	FOREIGN KEY (asset_id) REFERENCES asset(asset_id);

-- FOREIGN KEYS TO
-- consider FK asset and val_ownership_status
ALTER TABLE asset
	ADD CONSTRAINT fk_asset_ownshp_stat
	FOREIGN KEY (ownership_status) REFERENCES val_ownership_status(ownership_status);
-- consider FK asset and component
-- Skipping this FK since table does not exist yet
--ALTER TABLE asset
--	ADD CONSTRAINT fk_asset_comp_id
--	FOREIGN KEY (component_id) REFERENCES component(component_id);

-- consider FK asset and contract
ALTER TABLE asset
	ADD CONSTRAINT fk_asset_contract_id
	FOREIGN KEY (contract_id) REFERENCES contract(contract_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'asset');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'asset');
ALTER SEQUENCE asset_asset_id_seq
	 OWNED BY asset.asset_id;
DROP TABLE IF EXISTS asset_v59;
DROP TABLE IF EXISTS audit.asset_v59;
-- DONE DEALING WITH TABLE asset [544499]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE device_type [537296]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'device_type', 'device_type');

-- FOREIGN KEYS FROM
ALTER TABLE device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_devtype_ref_devtphysprttmpl;
ALTER TABLE device_type_module DROP CONSTRAINT IF EXISTS fk_devt_mod_dev_type_id;
ALTER TABLE device_type_power_port_templt DROP CONSTRAINT IF EXISTS fk_dev_type_dev_pwr_prt_tmpl;
ALTER TABLE chassis_location DROP CONSTRAINT IF EXISTS fk_chass_loc_mod_dev_typ_id;
ALTER TABLE device_type_module_device_type DROP CONSTRAINT IF EXISTS fk_dt_mod_dev_type_mod_dtid;
ALTER TABLE device DROP CONSTRAINT IF EXISTS fk_dev_devtp_id;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS fk_device_t_fk_device_val_proc;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS fk_devtyp_company;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'device_type');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS pk_device_type;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif4device_type";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS ckc_has_802_11_interf_device_t;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS ckc_devtyp_ischs;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS ckc_snmp_capable_device_t;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS ckc_has_802_3_interfa_device_t;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_device_type ON jazzhands.device_type;
DROP TRIGGER IF EXISTS trigger_device_type_chassis_check ON jazzhands.device_type;
DROP TRIGGER IF EXISTS trigger_audit_device_type ON jazzhands.device_type;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'device_type');
---- BEGIN audit.device_type TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'device_type');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."device_type_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'device_type');
---- DONE audit.device_type TEARDOWN


ALTER TABLE device_type RENAME TO device_type_v59;
ALTER TABLE audit.device_type RENAME TO device_type_v59;

CREATE TABLE device_type
(
	device_type_id	integer NOT NULL,
	component_type_id	integer  NULL,
	company_id	integer  NULL,
	model	varchar(255) NOT NULL,
	device_type_depth_in_cm	character(18)  NULL,
	processor_architecture	varchar(50)  NULL,
	config_fetch_type	varchar(50)  NULL,
	rack_units	integer NOT NULL,
	description	varchar(4000)  NULL,
	has_802_3_interface	character(1) NOT NULL,
	has_802_11_interface	character(1) NOT NULL,
	snmp_capable	character(1) NOT NULL,
	is_chassis	character(1) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'device_type', false);
ALTER TABLE device_type
	ALTER device_type_id
	SET DEFAULT nextval('device_type_device_type_id_seq'::regclass);
ALTER TABLE device_type
	ALTER is_chassis
	SET DEFAULT 'N'::bpchar;
INSERT INTO device_type (
	device_type_id,
	component_type_id,		-- new column (component_type_id)
	company_id,
	model,
	device_type_depth_in_cm,
	processor_architecture,
	config_fetch_type,
	rack_units,
	description,
	has_802_3_interface,
	has_802_11_interface,
	snmp_capable,
	is_chassis,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	device_type_id,
	NULL,		-- new column (component_type_id)
	company_id,
	model,
	device_type_depth_in_cm,
	processor_architecture,
	config_fetch_type,
	rack_units,
	description,
	has_802_3_interface,
	has_802_11_interface,
	snmp_capable,
	is_chassis,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM device_type_v59;

INSERT INTO audit.device_type (
	device_type_id,
	component_type_id,		-- new column (component_type_id)
	company_id,
	model,
	device_type_depth_in_cm,
	processor_architecture,
	config_fetch_type,
	rack_units,
	description,
	has_802_3_interface,
	has_802_11_interface,
	snmp_capable,
	is_chassis,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	device_type_id,
	NULL,		-- new column (component_type_id)
	company_id,
	model,
	device_type_depth_in_cm,
	processor_architecture,
	config_fetch_type,
	rack_units,
	description,
	has_802_3_interface,
	has_802_11_interface,
	snmp_capable,
	is_chassis,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.device_type_v59;

ALTER TABLE device_type
	ALTER device_type_id
	SET DEFAULT nextval('device_type_device_type_id_seq'::regclass);
ALTER TABLE device_type
	ALTER is_chassis
	SET DEFAULT 'N'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE device_type ADD CONSTRAINT pk_device_type PRIMARY KEY (device_type_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_fevtyp_component_id ON device_type USING btree (component_type_id);
CREATE INDEX xif4device_type ON device_type USING btree (company_id);

-- CHECK CONSTRAINTS
ALTER TABLE device_type ADD CONSTRAINT ckc_has_802_11_interf_device_t
	CHECK (has_802_11_interface = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE device_type ADD CONSTRAINT ckc_devtyp_ischs
	CHECK (is_chassis = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE device_type ADD CONSTRAINT ckc_snmp_capable_device_t
	CHECK (snmp_capable = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE device_type ADD CONSTRAINT ckc_has_802_3_interfa_device_t
	CHECK (has_802_3_interface = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK device_type and device
ALTER TABLE device
	ADD CONSTRAINT fk_dev_devtp_id
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device_type and device_type_module_device_type
ALTER TABLE device_type_module_device_type
	ADD CONSTRAINT fk_dt_mod_dev_type_mod_dtid
	FOREIGN KEY (module_device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device_type and device_type_phys_port_templt
ALTER TABLE device_type_phys_port_templt
	ADD CONSTRAINT fk_devtype_ref_devtphysprttmpl
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device_type and device_type_module
ALTER TABLE device_type_module
	ADD CONSTRAINT fk_devt_mod_dev_type_id
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device_type and chassis_location
ALTER TABLE chassis_location
	ADD CONSTRAINT fk_chass_loc_mod_dev_typ_id
	FOREIGN KEY (module_device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device_type and device_type_power_port_templt
ALTER TABLE device_type_power_port_templt
	ADD CONSTRAINT fk_dev_type_dev_pwr_prt_tmpl
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);

-- FOREIGN KEYS TO
-- consider FK device_type and val_processor_architecture
ALTER TABLE device_type
	ADD CONSTRAINT fk_device_t_fk_device_val_proc
	FOREIGN KEY (processor_architecture) REFERENCES val_processor_architecture(processor_architecture);
-- consider FK device_type and component_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE device_type
--	ADD CONSTRAINT fk_fevtyp_component_id
--	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);

-- consider FK device_type and company
ALTER TABLE device_type
	ADD CONSTRAINT fk_devtyp_company
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

-- TRIGGERS
CREATE TRIGGER trigger_device_type_chassis_check BEFORE UPDATE OF is_chassis ON device_type FOR EACH ROW EXECUTE PROCEDURE device_type_chassis_check();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'device_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'device_type');
ALTER SEQUENCE device_type_device_type_id_seq
	 OWNED BY device_type.device_type_id;
DROP TABLE IF EXISTS device_type_v59;
DROP TABLE IF EXISTS audit.device_type_v59;
-- DONE DEALING WITH TABLE device_type [544894]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE device [537117]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'device', 'device');

-- FOREIGN KEYS FROM
ALTER TABLE mlag_peering DROP CONSTRAINT IF EXISTS fk_mlag_peering_devid2;
ALTER TABLE device_layer2_network DROP CONSTRAINT IF EXISTS fk_device_l2_net_devid;
ALTER TABLE static_route DROP CONSTRAINT IF EXISTS fk_statrt_devsrc_id;
ALTER TABLE device_encapsulation_domain DROP CONSTRAINT IF EXISTS fk_dev_encap_domain_devid;
ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_l1conn_ref_device;
ALTER TABLE device_ticket DROP CONSTRAINT IF EXISTS fk_dev_tkt_dev_id;
ALTER TABLE mlag_peering DROP CONSTRAINT IF EXISTS fk_mlag_peering_devid1;
ALTER TABLE chassis_location DROP CONSTRAINT IF EXISTS fk_chass_loc_chass_devid;
ALTER TABLE device_collection_device DROP CONSTRAINT IF EXISTS fk_devcolldev_dev_id;
ALTER TABLE device_ssh_key DROP CONSTRAINT IF EXISTS fk_dev_ssh_key_ssh_key_id;
ALTER TABLE network_service DROP CONSTRAINT IF EXISTS fk_netsvc_device_id;
ALTER TABLE device_power_interface DROP CONSTRAINT IF EXISTS fk_device_device_power_supp;
ALTER TABLE device_management_controller DROP CONSTRAINT IF EXISTS fk_dev_mgmt_ctlr_dev_id;
ALTER TABLE device_management_controller DROP CONSTRAINT IF EXISTS fk_dvc_mgmt_ctrl_mgr_dev_id;
ALTER TABLE network_interface_purpose DROP CONSTRAINT IF EXISTS fk_netint_purpose_device_id;
ALTER TABLE device_note DROP CONSTRAINT IF EXISTS fk_device_note_device;
ALTER TABLE physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_dev_id;
ALTER TABLE network_interface DROP CONSTRAINT IF EXISTS fk_netint_device_id;
ALTER TABLE snmp_commstr DROP CONSTRAINT IF EXISTS fk_snmpstr_device_id;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_fk_dev_v_svcenv;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_site_code;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_reference_val_devi;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_devtp_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_ref_voesymbtrk;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_rack_location_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_fk_voe;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_ref_parent_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_os_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_fk_dev_val_stat;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_company__id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_asset_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_chass_loc_id_mod_enfc;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_dnsrecord;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_chasloc_chass_devid;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'device');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS pk_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ak_device_rack_location_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ak_device_chassis_location_id;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_dev_iddnsrec";
DROP INDEX IF EXISTS "jazzhands"."xif17device";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_islclymgd";
DROP INDEX IF EXISTS "jazzhands"."xif16device";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_ismonitored";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_osid";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_dev_status";
DROP INDEX IF EXISTS "jazzhands"."idx_device_type_location";
DROP INDEX IF EXISTS "jazzhands"."xif18device";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_svcenv";
DROP INDEX IF EXISTS "jazzhands"."xifdevice_sitecode";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_voeid";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_monitored_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_should_fetch_conf_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069059;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_locally_manage_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS dev_osid_notnull;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_virtual_device_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069051;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069060;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069057;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069052;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_update_per_device_device_collection ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_verify_device_voe ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_delete_per_device_device_collection ON jazzhands.device;
DROP TRIGGER IF EXISTS trig_userlog_device ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_audit_device ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_device_one_location_validate ON jazzhands.device;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'device');
---- BEGIN audit.device TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'device');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."device_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'device');
---- DONE audit.device TEARDOWN


ALTER TABLE device RENAME TO device_v59;
ALTER TABLE audit.device RENAME TO device_v59;

CREATE TABLE device
(
	device_id	integer NOT NULL,
	component_id	integer  NULL,
	device_type_id	integer NOT NULL,
	company_id	integer  NULL,
	asset_id	integer  NULL,
	device_name	varchar(255)  NULL,
	site_code	varchar(50)  NULL,
	identifying_dns_record_id	integer  NULL,
	host_id	varchar(255)  NULL,
	physical_label	varchar(255)  NULL,
	rack_location_id	integer  NULL,
	chassis_location_id	integer  NULL,
	parent_device_id	integer  NULL,
	description	varchar(255)  NULL,
	device_status	varchar(50) NOT NULL,
	operating_system_id	integer NOT NULL,
	service_environment_id	integer NOT NULL,
	voe_id	integer  NULL,
	auto_mgmt_protocol	varchar(50)  NULL,
	voe_symbolic_track_id	integer  NULL,
	is_locally_managed	character(1) NOT NULL,
	is_monitored	character(1) NOT NULL,
	is_virtual_device	character(1) NOT NULL,
	should_fetch_config	character(1) NOT NULL,
	date_in_service	timestamp with time zone  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'device', false);
ALTER TABLE device
	ALTER device_id
	SET DEFAULT nextval('device_device_id_seq'::regclass);
ALTER TABLE device
	ALTER operating_system_id
	SET DEFAULT 0;
ALTER TABLE device
	ALTER is_locally_managed
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE device
	ALTER is_virtual_device
	SET DEFAULT 'N'::bpchar;
ALTER TABLE device
	ALTER should_fetch_config
	SET DEFAULT 'Y'::bpchar;
INSERT INTO device (
	device_id,
	component_id,		-- new column (component_id)
	device_type_id,
	company_id,
	asset_id,
	device_name,
	site_code,
	identifying_dns_record_id,
	host_id,
	physical_label,
	rack_location_id,
	chassis_location_id,
	parent_device_id,
	description,
	device_status,
	operating_system_id,
	service_environment_id,
	voe_id,
	auto_mgmt_protocol,
	voe_symbolic_track_id,
	is_locally_managed,
	is_monitored,
	is_virtual_device,
	should_fetch_config,
	date_in_service,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	device_id,
	NULL,		-- new column (component_id)
	device_type_id,
	company_id,
	asset_id,
	device_name,
	site_code,
	identifying_dns_record_id,
	host_id,
	physical_label,
	rack_location_id,
	chassis_location_id,
	parent_device_id,
	description,
	device_status,
	operating_system_id,
	service_environment_id,
	voe_id,
	auto_mgmt_protocol,
	voe_symbolic_track_id,
	is_locally_managed,
	is_monitored,
	is_virtual_device,
	should_fetch_config,
	date_in_service,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM device_v59;

INSERT INTO audit.device (
	device_id,
	component_id,		-- new column (component_id)
	device_type_id,
	company_id,
	asset_id,
	device_name,
	site_code,
	identifying_dns_record_id,
	host_id,
	physical_label,
	rack_location_id,
	chassis_location_id,
	parent_device_id,
	description,
	device_status,
	operating_system_id,
	service_environment_id,
	voe_id,
	auto_mgmt_protocol,
	voe_symbolic_track_id,
	is_locally_managed,
	is_monitored,
	is_virtual_device,
	should_fetch_config,
	date_in_service,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	device_id,
	NULL,		-- new column (component_id)
	device_type_id,
	company_id,
	asset_id,
	device_name,
	site_code,
	identifying_dns_record_id,
	host_id,
	physical_label,
	rack_location_id,
	chassis_location_id,
	parent_device_id,
	description,
	device_status,
	operating_system_id,
	service_environment_id,
	voe_id,
	auto_mgmt_protocol,
	voe_symbolic_track_id,
	is_locally_managed,
	is_monitored,
	is_virtual_device,
	should_fetch_config,
	date_in_service,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.device_v59;

ALTER TABLE device
	ALTER device_id
	SET DEFAULT nextval('device_device_id_seq'::regclass);
ALTER TABLE device
	ALTER operating_system_id
	SET DEFAULT 0;
ALTER TABLE device
	ALTER is_locally_managed
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE device
	ALTER is_virtual_device
	SET DEFAULT 'N'::bpchar;
ALTER TABLE device
	ALTER should_fetch_config
	SET DEFAULT 'Y'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE device ADD CONSTRAINT pk_device PRIMARY KEY (device_id);
-- ALTER TABLE device ADD CONSTRAINT ak_device_rack_location_id UNIQUE (rack_location_id);
ALTER TABLE device ADD CONSTRAINT ak_device_chassis_location_id UNIQUE (chassis_location_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_device_company__id ON device USING btree (company_id);
CREATE INDEX xif_dev_os_id ON device USING btree (operating_system_id);
CREATE INDEX xif_device_asset_id ON device USING btree (asset_id);
CREATE INDEX idx_dev_ismonitored ON device USING btree (is_monitored);
CREATE INDEX xif_device_fk_voe ON device USING btree (voe_id);
CREATE INDEX idx_dev_islclymgd ON device USING btree (is_locally_managed);
CREATE INDEX xif_device_dev_val_status ON device USING btree (device_status);
CREATE INDEX xif_device_dev_v_svcenv ON device USING btree (service_environment_id);
CREATE INDEX idx_device_type_location ON device USING btree (device_type_id);
CREATE INDEX xif_device_comp_id ON device USING btree (component_id);
CREATE INDEX xif_device_site_code ON device USING btree (site_code);
CREATE INDEX xif_device_id_dnsrecord ON device USING btree (identifying_dns_record_id);
CREATE INDEX xif_dev_chass_loc_id_mod_enfc ON device USING btree (chassis_location_id, parent_device_id, device_type_id);

-- CHECK CONSTRAINTS
ALTER TABLE device ADD CONSTRAINT ckc_is_virtual_device_device
	CHECK ((is_virtual_device = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_virtual_device)::text = upper((is_virtual_device)::text)));
ALTER TABLE device ADD CONSTRAINT ckc_should_fetch_conf_device
	CHECK ((should_fetch_config = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((should_fetch_config)::text = upper((should_fetch_config)::text)));
ALTER TABLE device ADD CONSTRAINT sys_c0069059
	CHECK (is_virtual_device IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT ckc_is_monitored_device
	CHECK ((is_monitored = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_monitored)::text = upper((is_monitored)::text)));
ALTER TABLE device ADD CONSTRAINT ckc_is_locally_manage_device
	CHECK ((is_locally_managed = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_locally_managed)::text = upper((is_locally_managed)::text)));
ALTER TABLE device ADD CONSTRAINT dev_osid_notnull
	CHECK (operating_system_id IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT sys_c0069052
	CHECK (device_type_id IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT sys_c0069051
	CHECK (device_id IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT sys_c0069057
	CHECK (is_monitored IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT sys_c0069060
	CHECK (should_fetch_config IS NOT NULL);

-- FOREIGN KEYS FROM
-- consider FK device and physical_port
ALTER TABLE physical_port
	ADD CONSTRAINT fk_phys_port_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and snmp_commstr
ALTER TABLE snmp_commstr
	ADD CONSTRAINT fk_snmpstr_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and network_interface
ALTER TABLE network_interface
	ADD CONSTRAINT fk_netint_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_management_controller
ALTER TABLE device_management_controller
	ADD CONSTRAINT fk_dvc_mgmt_ctrl_mgr_dev_id
	FOREIGN KEY (manager_device_id) REFERENCES device(device_id);
-- consider FK device and network_interface_purpose
ALTER TABLE network_interface_purpose
	ADD CONSTRAINT fk_netint_purpose_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_note
ALTER TABLE device_note
	ADD CONSTRAINT fk_device_note_device
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_ssh_key
ALTER TABLE device_ssh_key
	ADD CONSTRAINT fk_dev_ssh_key_ssh_key_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and network_service
ALTER TABLE network_service
	ADD CONSTRAINT fk_netsvc_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_power_interface
ALTER TABLE device_power_interface
	ADD CONSTRAINT fk_device_device_power_supp
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_management_controller
ALTER TABLE device_management_controller
	ADD CONSTRAINT fk_dev_mgmt_ctlr_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and layer1_connection
ALTER TABLE layer1_connection
	ADD CONSTRAINT fk_l1conn_ref_device
	FOREIGN KEY (tcpsrv_device_id) REFERENCES device(device_id);
-- consider FK device and device_ticket
ALTER TABLE device_ticket
	ADD CONSTRAINT fk_dev_tkt_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and chassis_location
ALTER TABLE chassis_location
	ADD CONSTRAINT fk_chass_loc_chass_devid
	FOREIGN KEY (chassis_device_id) REFERENCES device(device_id) DEFERRABLE;
-- consider FK device and mlag_peering
ALTER TABLE mlag_peering
	ADD CONSTRAINT fk_mlag_peering_devid1
	FOREIGN KEY (device1_id) REFERENCES device(device_id);
-- consider FK device and device_collection_device
ALTER TABLE device_collection_device
	ADD CONSTRAINT fk_devcolldev_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_encapsulation_domain
ALTER TABLE device_encapsulation_domain
	ADD CONSTRAINT fk_dev_encap_domain_devid
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and static_route
ALTER TABLE static_route
	ADD CONSTRAINT fk_statrt_devsrc_id
	FOREIGN KEY (device_src_id) REFERENCES device(device_id);
-- consider FK device and mlag_peering
ALTER TABLE mlag_peering
	ADD CONSTRAINT fk_mlag_peering_devid2
	FOREIGN KEY (device2_id) REFERENCES device(device_id);
-- consider FK device and device_layer2_network
ALTER TABLE device_layer2_network
	ADD CONSTRAINT fk_device_l2_net_devid
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- FOREIGN KEYS TO
-- consider FK device and asset
ALTER TABLE device
	ADD CONSTRAINT fk_device_asset_id
	FOREIGN KEY (asset_id) REFERENCES asset(asset_id);
-- consider FK device and dns_record
ALTER TABLE device
	ADD CONSTRAINT fk_device_id_dnsrecord
	FOREIGN KEY (identifying_dns_record_id) REFERENCES dns_record(dns_record_id);
-- consider FK device and service_environment
ALTER TABLE device
	ADD CONSTRAINT fk_device_dev_v_svcenv
	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);
-- consider FK device and device
ALTER TABLE device
	ADD CONSTRAINT fk_device_ref_parent_device
	FOREIGN KEY (parent_device_id) REFERENCES device(device_id);
-- consider FK device and val_device_status
ALTER TABLE device
	ADD CONSTRAINT fk_device_dev_val_status
	FOREIGN KEY (device_status) REFERENCES val_device_status(device_status);
-- consider FK device and voe_symbolic_track
ALTER TABLE device
	ADD CONSTRAINT fk_device_ref_voesymbtrk
	FOREIGN KEY (voe_symbolic_track_id) REFERENCES voe_symbolic_track(voe_symbolic_track_id);
-- consider FK device and rack_location
ALTER TABLE device
	ADD CONSTRAINT fk_dev_rack_location_id
	FOREIGN KEY (rack_location_id) REFERENCES rack_location(rack_location_id);
-- consider FK device and site
ALTER TABLE device
	ADD CONSTRAINT fk_device_site_code
	FOREIGN KEY (site_code) REFERENCES site(site_code);
-- consider FK device and component
-- Skipping this FK since table does not exist yet
--ALTER TABLE device
--	ADD CONSTRAINT fk_device_comp_id
--	FOREIGN KEY (component_id) REFERENCES component(component_id);

-- consider FK device and company
ALTER TABLE device
	ADD CONSTRAINT fk_device_company__id
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;
-- consider FK device and chassis_location
ALTER TABLE device
	ADD CONSTRAINT fk_dev_chass_loc_id_mod_enfc
	FOREIGN KEY (chassis_location_id, parent_device_id, device_type_id) REFERENCES chassis_location(chassis_location_id, chassis_device_id, module_device_type_id) DEFERRABLE;
-- consider FK device and chassis_location
ALTER TABLE device
	ADD CONSTRAINT fk_chasloc_chass_devid
	FOREIGN KEY (chassis_location_id) REFERENCES chassis_location(chassis_location_id) DEFERRABLE;
-- consider FK device and operating_system
ALTER TABLE device
	ADD CONSTRAINT fk_dev_os_id
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);
-- consider FK device and val_device_auto_mgmt_protocol
ALTER TABLE device
	ADD CONSTRAINT fk_dev_ref_mgmt_proto
	FOREIGN KEY (auto_mgmt_protocol) REFERENCES val_device_auto_mgmt_protocol(auto_mgmt_protocol);
-- consider FK device and voe
ALTER TABLE device
	ADD CONSTRAINT fk_device_fk_voe
	FOREIGN KEY (voe_id) REFERENCES voe(voe_id);
-- consider FK device and device_type
ALTER TABLE device
	ADD CONSTRAINT fk_dev_devtp_id
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);

-- TRIGGERS
CREATE TRIGGER trigger_update_per_device_device_collection AFTER INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE update_per_device_device_collection();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_verify_device_voe BEFORE INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE verify_device_voe();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_delete_per_device_device_collection BEFORE DELETE ON device FOR EACH ROW EXECUTE PROCEDURE delete_per_device_device_collection();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_device_one_location_validate BEFORE INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE device_one_location_validate();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'device');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'device');
ALTER SEQUENCE device_device_id_seq
	 OWNED BY device.device_id;
DROP TABLE IF EXISTS device_v59;
DROP TABLE IF EXISTS audit.device_v59;
-- DONE DEALING WITH TABLE device [544714]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_volume_group_relation
CREATE TABLE val_volume_group_relation
(
	volume_group_relation	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_volume_group_relation', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_volume_group_relation ADD CONSTRAINT pk_val_volume_group_relation PRIMARY KEY (volume_group_relation);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_volume_group_relation and volume_group_physicalish_vol
-- Skipping this FK since table does not exist yet
--ALTER TABLE volume_group_physicalish_vol
--	ADD CONSTRAINT r_645
--	FOREIGN KEY (volume_group_relation) REFERENCES val_volume_group_relation(volume_group_relation);


-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_volume_group_relation');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_volume_group_relation');
-- DONE DEALING WITH TABLE val_volume_group_relation [546891]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_logical_volume_property
CREATE TABLE val_logical_volume_property
(
	logical_volume_property_name	varchar(50) NOT NULL,
	filesystem_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_logical_volume_property', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_logical_volume_property ADD CONSTRAINT pk_val_logical_volume_property PRIMARY KEY (logical_volume_property_name, filesystem_type);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif1val_logical_volume_propert ON val_logical_volume_property USING btree (filesystem_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_logical_volume_property and logical_volume_property
-- Skipping this FK since table does not exist yet
--ALTER TABLE logical_volume_property
--	ADD CONSTRAINT r_644
--	FOREIGN KEY (logical_volume_property_name, filesystem_type) REFERENCES val_logical_volume_property(logical_volume_property_name, filesystem_type);


-- FOREIGN KEYS TO
-- consider FK val_logical_volume_property and val_filesystem_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE val_logical_volume_property
--	ADD CONSTRAINT r_643
--	FOREIGN KEY (filesystem_type) REFERENCES val_filesystem_type(filesystem_type);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_logical_volume_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_logical_volume_property');
-- DONE DEALING WITH TABLE val_logical_volume_property [546437]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_component_property
CREATE TABLE val_component_property
(
	component_property_name	varchar(50) NOT NULL,
	component_property_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	is_multivalue	character(1) NOT NULL,
	property_data_type	varchar(50) NOT NULL,
	permit_component_type_id	character(10) NOT NULL,
	required_component_type_id	integer  NULL,
	permit_component_function	character(10) NOT NULL,
	required_component_function	varchar(50)  NULL,
	permit_component_id	character(10) NOT NULL,
	permit_slot_type_id	character(10) NOT NULL,
	required_slot_type_id	integer  NULL,
	permit_slot_function	character(10) NOT NULL,
	required_slot_function	varchar(50)  NULL,
	permit_slot_id	character(10) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_component_property', true);
ALTER TABLE val_component_property
	ALTER permit_component_type_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_component_property
	ALTER permit_component_function
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_component_property
	ALTER permit_component_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_component_property
	ALTER permit_slot_type_id
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_component_property
	ALTER permit_slot_function
	SET DEFAULT 'PROHIBITED'::bpchar;
ALTER TABLE val_component_property
	ALTER permit_slot_id
	SET DEFAULT 'PROHIBITED'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_component_property ADD CONSTRAINT pk_val_component_property PRIMARY KEY (component_property_name, component_property_type);

-- Table/Column Comments
COMMENT ON TABLE val_component_property IS 'Contains a list of all valid properties for component tables (component, component_type, component_function, slot, slot_type, slot_function)';
-- INDEXES
CREATE INDEX xif_vcomp_prop_rqd_cmpfunc ON val_component_property USING btree (required_component_function);
CREATE INDEX xif_vcomp_prop_rqd_cmptypid ON val_component_property USING btree (required_component_type_id);
CREATE INDEX xif_vcomp_prop_rqd_slttyp_id ON val_component_property USING btree (required_slot_type_id);
CREATE INDEX xif_vcomp_prop_comp_prop_type ON val_component_property USING btree (component_property_type);
CREATE INDEX xif_prop_rqd_slt_func ON val_component_property USING btree (required_slot_function);

-- CHECK CONSTRAINTS
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_1618700758
	CHECK (permit_component_function = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_27441051
	CHECK (permit_component_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_1181188899
	CHECK (permit_component_type_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_yes_no_1709686918
	CHECK (is_multivalue = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_1984425150
	CHECK (permit_slot_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_342055273
	CHECK (permit_slot_type_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_1784750469
	CHECK (permit_slot_function = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK val_component_property and val_component_property_value
-- Skipping this FK since table does not exist yet
--ALTER TABLE val_component_property_value
--	ADD CONSTRAINT fk_comp_prop_val_nametyp
--	FOREIGN KEY (component_property_name, component_property_type) REFERENCES val_component_property(component_property_name, component_property_type);

-- consider FK val_component_property and component_property
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_property
--	ADD CONSTRAINT fk_comp_prop_prop_nmty
--	FOREIGN KEY (component_property_name, component_property_type) REFERENCES val_component_property(component_property_name, component_property_type);


-- FOREIGN KEYS TO
-- consider FK val_component_property and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE val_component_property
--	ADD CONSTRAINT fk_vcomp_prop_rqd_slttyp_id
--	FOREIGN KEY (required_slot_type_id) REFERENCES slot_type(slot_type_id);

-- consider FK val_component_property and val_component_function
-- Skipping this FK since table does not exist yet
--ALTER TABLE val_component_property
--	ADD CONSTRAINT fk_cmop_prop_rqd_cmpfunc
--	FOREIGN KEY (required_component_function) REFERENCES val_component_function(component_function);

-- consider FK val_component_property and val_component_property_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE val_component_property
--	ADD CONSTRAINT fk_comp_prop_comp_prop_type
--	FOREIGN KEY (component_property_type) REFERENCES val_component_property_type(component_property_type);

-- consider FK val_component_property and component_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE val_component_property
--	ADD CONSTRAINT fk_comp_prop_rqd_cmptypid
--	FOREIGN KEY (required_component_type_id) REFERENCES component_type(component_type_id);

-- consider FK val_component_property and val_slot_function
-- Skipping this FK since table does not exist yet
--ALTER TABLE val_component_property
--	ADD CONSTRAINT fk_vcomp_prop_rqd_slt_func
--	FOREIGN KEY (required_slot_function) REFERENCES val_slot_function(slot_function);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_component_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_component_property');
-- DONE DEALING WITH TABLE val_component_property [546204]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_raid_type
CREATE TABLE val_raid_type
(
	raid_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_raid_type', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_raid_type ADD CONSTRAINT pk_raid_type PRIMARY KEY (raid_type);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_raid_type and volume_group
-- Skipping this FK since table does not exist yet
--ALTER TABLE volume_group
--	ADD CONSTRAINT r_639
--	FOREIGN KEY (raid_type) REFERENCES val_raid_type(raid_type);


-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_raid_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_raid_type');
-- DONE DEALING WITH TABLE val_raid_type [546766]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_slot_function
CREATE TABLE val_slot_function
(
	slot_function	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_slot_function', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_slot_function ADD CONSTRAINT pk_val_slot_function PRIMARY KEY (slot_function);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_slot_function and val_component_property
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_vcomp_prop_rqd_slt_func
	FOREIGN KEY (required_slot_function) REFERENCES val_slot_function(slot_function);
-- consider FK val_slot_function and val_slot_physical_interface
-- Skipping this FK since table does not exist yet
--ALTER TABLE val_slot_physical_interface
--	ADD CONSTRAINT fk_slot_phys_int_slot_func
--	FOREIGN KEY (slot_function) REFERENCES val_slot_function(slot_function);

-- consider FK val_slot_function and component_property
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_property
--	ADD CONSTRAINT fk_comp_prop_sltfuncid
--	FOREIGN KEY (slot_function) REFERENCES val_slot_function(slot_function);

-- consider FK val_slot_function and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot_type
--	ADD CONSTRAINT fk_slot_type_slt_func
--	FOREIGN KEY (slot_function) REFERENCES val_slot_function(slot_function);


-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_slot_function');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_slot_function');
-- DONE DEALING WITH TABLE val_slot_function [546784]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_component_function
CREATE TABLE val_component_function
(
	component_function	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_component_function', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_component_function ADD CONSTRAINT pk_val_component_function PRIMARY KEY (component_function);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_component_function and val_component_property
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_cmop_prop_rqd_cmpfunc
	FOREIGN KEY (required_component_function) REFERENCES val_component_function(component_function);
-- consider FK val_component_function and component_type_component_func
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_type_component_func
--	ADD CONSTRAINT fk_cmptypcf_comp_func
--	FOREIGN KEY (component_function) REFERENCES val_component_function(component_function);

-- consider FK val_component_function and component_property
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_property
--	ADD CONSTRAINT fk_comp_prop_comp_func
--	FOREIGN KEY (component_function) REFERENCES val_component_function(component_function);


-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_component_function');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_component_function');
-- DONE DEALING WITH TABLE val_component_function [546196]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_filesystem_type
CREATE TABLE val_filesystem_type
(
	filesystem_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_filesystem_type', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_filesystem_type ADD CONSTRAINT pk_val_filesytem_type PRIMARY KEY (filesystem_type);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_filesystem_type and val_logical_volume_property
ALTER TABLE val_logical_volume_property
	ADD CONSTRAINT r_643
	FOREIGN KEY (filesystem_type) REFERENCES val_filesystem_type(filesystem_type);
-- consider FK val_filesystem_type and logical_volume
-- Skipping this FK since table does not exist yet
--ALTER TABLE logical_volume
--	ADD CONSTRAINT r_638
--	FOREIGN KEY (filesystem_type) REFERENCES val_filesystem_type(filesystem_type);


-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_filesystem_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_filesystem_type');
-- DONE DEALING WITH TABLE val_filesystem_type [546389]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_slot_physical_interface
CREATE TABLE val_slot_physical_interface
(
	slot_physical_interface_type	varchar(50) NOT NULL,
	slot_function	varchar(50) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_slot_physical_interface', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_slot_physical_interface ADD CONSTRAINT pk_val_slot_physical_interface PRIMARY KEY (slot_physical_interface_type, slot_function);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_slot_phys_int_slot_func ON val_slot_physical_interface USING btree (slot_function);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_slot_physical_interface and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot_type
--	ADD CONSTRAINT fk_slot_type_physint_func
--	FOREIGN KEY (slot_physical_interface_type, slot_function) REFERENCES val_slot_physical_interface(slot_physical_interface_type, slot_function);


-- FOREIGN KEYS TO
-- consider FK val_slot_physical_interface and val_slot_function
ALTER TABLE val_slot_physical_interface
	ADD CONSTRAINT fk_slot_phys_int_slot_func
	FOREIGN KEY (slot_function) REFERENCES val_slot_function(slot_function);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_slot_physical_interface');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_slot_physical_interface');
-- DONE DEALING WITH TABLE val_slot_physical_interface [546792]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_component_property_value
CREATE TABLE val_component_property_value
(
	component_property_name	varchar(50) NOT NULL,
	component_property_type	varchar(50) NOT NULL,
	valid_property_value	varchar(255) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_component_property_value', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_component_property_value ADD CONSTRAINT pk_val_component_property_valu PRIMARY KEY (component_property_name, component_property_type, valid_property_value);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_comp_prop_val_nametyp ON val_component_property_value USING btree (component_property_name, component_property_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK val_component_property_value and val_component_property
ALTER TABLE val_component_property_value
	ADD CONSTRAINT fk_comp_prop_val_nametyp
	FOREIGN KEY (component_property_name, component_property_type) REFERENCES val_component_property(component_property_name, component_property_type);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_component_property_value');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_component_property_value');
-- DONE DEALING WITH TABLE val_component_property_value [546240]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_component_property_type
CREATE TABLE val_component_property_type
(
	component_property_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	is_multivalue	character(1) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_component_property_type', true);
ALTER TABLE val_component_property_type
	ALTER is_multivalue
	SET DEFAULT 'N'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_component_property_type ADD CONSTRAINT pk_val_component_property_type PRIMARY KEY (component_property_type);

-- Table/Column Comments
COMMENT ON TABLE val_component_property_type IS 'Contains list of valid component_property_types';
-- INDEXES

-- CHECK CONSTRAINTS
ALTER TABLE val_component_property_type ADD CONSTRAINT check_yes_no_46206456
	CHECK (is_multivalue = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK val_component_property_type and val_component_property
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_comp_prop_comp_prop_type
	FOREIGN KEY (component_property_type) REFERENCES val_component_property_type(component_property_type);

-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_component_property_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_component_property_type');
-- DONE DEALING WITH TABLE val_component_property_type [546230]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE slot_type_prmt_rem_slot_type
CREATE TABLE slot_type_prmt_rem_slot_type
(
	slot_type_id	integer NOT NULL,
	remote_slot_type_id	integer NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'slot_type_prmt_rem_slot_type', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE slot_type_prmt_rem_slot_type ADD CONSTRAINT pk_slot_type_prmt_rem_slot_typ PRIMARY KEY (slot_type_id, remote_slot_type_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_stprst_slot_type_id ON slot_type_prmt_rem_slot_type USING btree (slot_type_id);
CREATE INDEX xif_stprst_remote_slot_type_id ON slot_type_prmt_rem_slot_type USING btree (remote_slot_type_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK slot_type_prmt_rem_slot_type and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot_type_prmt_rem_slot_type
--	ADD CONSTRAINT fk_stprst_slot_type_id
--	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);

-- consider FK slot_type_prmt_rem_slot_type and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot_type_prmt_rem_slot_type
--	ADD CONSTRAINT fk_stprst_remote_slot_type_id
--	FOREIGN KEY (remote_slot_type_id) REFERENCES slot_type(slot_type_id);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'slot_type_prmt_rem_slot_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'slot_type_prmt_rem_slot_type');
-- DONE DEALING WITH TABLE slot_type_prmt_rem_slot_type [545874]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE inter_component_connection
CREATE TABLE inter_component_connection
(
	inter_component_connection_id	integer NOT NULL,
	slot1_id	integer NOT NULL,
	slot2_id	integer NOT NULL,
	circuit_id	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'inter_component_connection', true);
ALTER TABLE inter_component_connection
	ALTER inter_component_connection_id
	SET DEFAULT nextval('inter_component_connection_inter_component_connection_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE inter_component_connection ADD CONSTRAINT pk_inter_component_connection PRIMARY KEY (inter_component_connection_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_intercom_conn_circ_id ON inter_component_connection USING btree (circuit_id);
CREATE INDEX xif_intercomp_conn_slot1_id ON inter_component_connection USING btree (slot1_id);
CREATE INDEX xif_intercomp_conn_slot2_id ON inter_component_connection USING btree (slot2_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK inter_component_connection and circuit
ALTER TABLE inter_component_connection
	ADD CONSTRAINT fk_intercom_conn_circ_id
	FOREIGN KEY (circuit_id) REFERENCES circuit(circuit_id);
-- consider FK inter_component_connection and slot
-- Skipping this FK since table does not exist yet
--ALTER TABLE inter_component_connection
--	ADD CONSTRAINT fk_intercomp_conn_slot2_id
--	FOREIGN KEY (slot2_id) REFERENCES slot(slot_id);

-- consider FK inter_component_connection and slot
-- Skipping this FK since table does not exist yet
--ALTER TABLE inter_component_connection
--	ADD CONSTRAINT fk_intercomp_conn_slot1_id
--	FOREIGN KEY (slot1_id) REFERENCES slot(slot_id);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'inter_component_connection');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'inter_component_connection');
ALTER SEQUENCE inter_component_connection_inter_component_connection_id_seq
	 OWNED BY inter_component_connection.inter_component_connection_id;
-- DONE DEALING WITH TABLE inter_component_connection [545047]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE component_type
CREATE TABLE component_type
(
	component_type_id	integer NOT NULL,
	company_id	integer  NULL,
	model	varchar(255)  NULL,
	slot_type_id	integer  NULL,
	description	varchar(255)  NULL,
	part_number	varchar(255)  NULL,
	is_removable	character(1) NOT NULL,
	asset_permitted	character(1) NOT NULL,
	is_rack_mountable	character(1) NOT NULL,
	is_virtual_component	character(1) NOT NULL,
	size_units	varchar(50) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'component_type', true);
ALTER TABLE component_type
	ALTER component_type_id
	SET DEFAULT nextval('component_type_component_type_id_seq'::regclass);
ALTER TABLE component_type
	ALTER is_removable
	SET DEFAULT 'N'::bpchar;
ALTER TABLE component_type
	ALTER asset_permitted
	SET DEFAULT 'N'::bpchar;
ALTER TABLE component_type
	ALTER is_rack_mountable
	SET DEFAULT 'N'::bpchar;
ALTER TABLE component_type
	ALTER is_virtual_component
	SET DEFAULT 'N'::bpchar;
ALTER TABLE component_type
	ALTER size_units
	SET DEFAULT 0;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE component_type ADD CONSTRAINT pk_component_type PRIMARY KEY (component_type_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_component_type_slt_type_id ON component_type USING btree (slot_type_id);
CREATE INDEX xif_component_type_company_id ON component_type USING btree (company_id);

-- CHECK CONSTRAINTS
ALTER TABLE component_type ADD CONSTRAINT check_yes_no_53094976
	CHECK (asset_permitted = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE component_type ADD CONSTRAINT check_yes_no_1730011385
	CHECK (is_removable = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE component_type ADD CONSTRAINT check_yes_no_981718444
	CHECK (is_virtual_component = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE component_type ADD CONSTRAINT check_yes_no_25197360
	CHECK (is_rack_mountable = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK component_type and val_component_property
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_comp_prop_rqd_cmptypid
	FOREIGN KEY (required_component_type_id) REFERENCES component_type(component_type_id);
-- consider FK component_type and component_type_slot_tmplt
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_type_slot_tmplt
--	ADD CONSTRAINT fk_comp_typ_slt_tmplt_cmptypid
--	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);

-- consider FK component_type and component_property
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_property
--	ADD CONSTRAINT fk_comp_prop_comp_typ_id
--	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);

-- consider FK component_type and component_type_component_func
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_type_component_func
--	ADD CONSTRAINT fk_cmptypecf_comp_typ_id
--	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);

-- consider FK component_type and component
-- Skipping this FK since table does not exist yet
--ALTER TABLE component
--	ADD CONSTRAINT fk_component_comp_type_i
--	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);

-- consider FK component_type and device_type
ALTER TABLE device_type
	ADD CONSTRAINT fk_fevtyp_component_id
	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);

-- FOREIGN KEYS TO
-- consider FK component_type and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_type
--	ADD CONSTRAINT fk_component_type_slt_type_id
--	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);

-- consider FK component_type and company
ALTER TABLE component_type
	ADD CONSTRAINT fk_component_type_company_id
	FOREIGN KEY (company_id) REFERENCES company(company_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'component_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'component_type');
ALTER SEQUENCE component_type_component_type_id_seq
	 OWNED BY component_type.component_type_id;
-- DONE DEALING WITH TABLE component_type [544636]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE component_property
CREATE TABLE component_property
(
	component_property_id	integer NOT NULL,
	component_function	varchar(50)  NULL,
	component_type_id	integer  NULL,
	component_id	integer  NULL,
	slot_function	varchar(50)  NULL,
	slot_type_id	integer  NULL,
	slot_id	integer  NULL,
	component_property_name	varchar(50)  NULL,
	component_property_type	varchar(50)  NULL,
	property_value	varchar(255)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'component_property', true);
ALTER TABLE component_property
	ALTER component_property_id
	SET DEFAULT nextval('component_property_component_property_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE component_property ADD CONSTRAINT pk_component_property PRIMARY KEY (component_property_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_comp_prop_sltfuncid ON component_property USING btree (slot_function);
CREATE INDEX xif_comp_prop_slt_typ_id ON component_property USING btree (slot_type_id);
CREATE INDEX xif_comp_prop_prop_nmty ON component_property USING btree (component_property_name, component_property_type);
CREATE INDEX xif_comp_prop_comp_typ_id ON component_property USING btree (component_type_id);
CREATE INDEX xif_comp_prop_slt_slt_id ON component_property USING btree (slot_id);
CREATE INDEX xif_comp_prop_cmp_id ON component_property USING btree (component_id);
CREATE INDEX xif_comp_prop_comp_func ON component_property USING btree (component_function);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK component_property and val_slot_function
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_sltfuncid
	FOREIGN KEY (slot_function) REFERENCES val_slot_function(slot_function);
-- consider FK component_property and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_property
--	ADD CONSTRAINT fk_comp_prop_slt_typ_id
--	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);

-- consider FK component_property and val_component_property
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_prop_nmty
	FOREIGN KEY (component_property_name, component_property_type) REFERENCES val_component_property(component_property_name, component_property_type);
-- consider FK component_property and component
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_property
--	ADD CONSTRAINT fk_comp_prop_cmp_id
--	FOREIGN KEY (component_id) REFERENCES component(component_id);

-- consider FK component_property and slot
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_property
--	ADD CONSTRAINT fk_comp_prop_slt_slt_id
--	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);

-- consider FK component_property and component_type
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_comp_typ_id
	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);
-- consider FK component_property and val_component_function
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_comp_func
	FOREIGN KEY (component_function) REFERENCES val_component_function(component_function);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'component_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'component_property');
ALTER SEQUENCE component_property_component_property_id_seq
	 OWNED BY component_property.component_property_id;
-- DONE DEALING WITH TABLE component_property [544618]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE component_type_slot_tmplt
CREATE TABLE component_type_slot_tmplt
(
	component_type_slot_tmplt_id	integer NOT NULL,
	component_type_id	integer NOT NULL,
	slot_type_id	integer NOT NULL,
	slot_name_template	varchar(50) NOT NULL,
	child_slot_name_template	varchar(50)  NULL,
	child_slot_offset	integer  NULL,
	slot_index	integer  NULL,
	physical_label	varchar(50)  NULL,
	slot_x_offset	integer  NULL,
	slot_y_offset	character(18)  NULL,
	slot_z_offset	integer  NULL,
	slot_side	varchar(50)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'component_type_slot_tmplt', true);
ALTER TABLE component_type_slot_tmplt
	ALTER component_type_slot_tmplt_id
	SET DEFAULT nextval('component_type_slot_tmplt_component_type_slot_tmplt_id_seq'::regclass);
ALTER TABLE component_type_slot_tmplt
	ALTER slot_side
	SET DEFAULT 'FRONT'::character varying;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE component_type_slot_tmplt ADD CONSTRAINT pk_component_type_slot_tmplt PRIMARY KEY (component_type_slot_tmplt_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_comp_typ_slt_tmplt_slttypi ON component_type_slot_tmplt USING btree (slot_type_id);
CREATE INDEX xif_comp_typ_slt_tmplt_cmptypi ON component_type_slot_tmplt USING btree (component_type_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK component_type_slot_tmplt and slot
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot
--	ADD CONSTRAINT fk_slot_cmp_typ_tmp_id
--	FOREIGN KEY (component_type_slot_tmplt_id) REFERENCES component_type_slot_tmplt(component_type_slot_tmplt_id);


-- FOREIGN KEYS TO
-- consider FK component_type_slot_tmplt and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE component_type_slot_tmplt
--	ADD CONSTRAINT fk_comp_typ_slt_tmplt_slttypid
--	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);

-- consider FK component_type_slot_tmplt and component_type
ALTER TABLE component_type_slot_tmplt
	ADD CONSTRAINT fk_comp_typ_slt_tmplt_cmptypid
	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'component_type_slot_tmplt');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'component_type_slot_tmplt');
ALTER SEQUENCE component_type_slot_tmplt_component_type_slot_tmplt_id_seq
	 OWNED BY component_type_slot_tmplt.component_type_slot_tmplt_id;
-- DONE DEALING WITH TABLE component_type_slot_tmplt [544668]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE slot_type_prmt_comp_slot_type
CREATE TABLE slot_type_prmt_comp_slot_type
(
	slot_type_id	integer NOT NULL,
	component_slot_type_id	integer NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'slot_type_prmt_comp_slot_type', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE slot_type_prmt_comp_slot_type ADD CONSTRAINT pk_slot_type_prmt_comp_slot_ty PRIMARY KEY (slot_type_id, component_slot_type_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_stpcst_slot_type_id ON slot_type_prmt_comp_slot_type USING btree (component_slot_type_id);
CREATE INDEX xif_stpcst_cmp_slt_typ_id ON slot_type_prmt_comp_slot_type USING btree (slot_type_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK slot_type_prmt_comp_slot_type and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot_type_prmt_comp_slot_type
--	ADD CONSTRAINT fk_stpcst_slot_type_id
--	FOREIGN KEY (component_slot_type_id) REFERENCES slot_type(slot_type_id);

-- consider FK slot_type_prmt_comp_slot_type and slot_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot_type_prmt_comp_slot_type
--	ADD CONSTRAINT fk_stpcst_cmp_slt_typ_id
--	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'slot_type_prmt_comp_slot_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'slot_type_prmt_comp_slot_type');
-- DONE DEALING WITH TABLE slot_type_prmt_comp_slot_type [545864]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE slot_type
CREATE TABLE slot_type
(
	slot_type_id	integer NOT NULL,
	slot_type	varchar(50) NOT NULL,
	slot_function	varchar(50) NOT NULL,
	slot_physical_interface_type	varchar(50) NOT NULL,
	description	varchar(255)  NULL,
	remote_slot_permitted	character(1) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'slot_type', true);
ALTER TABLE slot_type
	ALTER slot_type_id
	SET DEFAULT nextval('slot_type_slot_type_id_seq'::regclass);
ALTER TABLE slot_type
	ALTER remote_slot_permitted
	SET DEFAULT 'N'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE slot_type ADD CONSTRAINT pk_slot_type PRIMARY KEY (slot_type_id);
ALTER TABLE slot_type ADD CONSTRAINT ak_slot_type_name_type UNIQUE (slot_type, slot_function);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_slot_type_slt_func ON slot_type USING btree (slot_function);
CREATE INDEX xif_slot_type_physint_func ON slot_type USING btree (slot_physical_interface_type, slot_function);

-- CHECK CONSTRAINTS
ALTER TABLE slot_type ADD CONSTRAINT check_yes_no_28083896
	CHECK (remote_slot_permitted = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK slot_type and component_property
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_slt_typ_id
	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK slot_type and slot
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot
--	ADD CONSTRAINT fk_slot_slot_type_id
--	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);

-- consider FK slot_type and component_type
ALTER TABLE component_type
	ADD CONSTRAINT fk_component_type_slt_type_id
	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK slot_type and val_component_property
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_vcomp_prop_rqd_slttyp_id
	FOREIGN KEY (required_slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK slot_type and slot_type_prmt_comp_slot_type
ALTER TABLE slot_type_prmt_comp_slot_type
	ADD CONSTRAINT fk_stpcst_cmp_slt_typ_id
	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK slot_type and slot_type_prmt_comp_slot_type
ALTER TABLE slot_type_prmt_comp_slot_type
	ADD CONSTRAINT fk_stpcst_slot_type_id
	FOREIGN KEY (component_slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK slot_type and slot_type_prmt_rem_slot_type
ALTER TABLE slot_type_prmt_rem_slot_type
	ADD CONSTRAINT fk_stprst_slot_type_id
	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK slot_type and slot_type_prmt_rem_slot_type
ALTER TABLE slot_type_prmt_rem_slot_type
	ADD CONSTRAINT fk_stprst_remote_slot_type_id
	FOREIGN KEY (remote_slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK slot_type and component_type_slot_tmplt
ALTER TABLE component_type_slot_tmplt
	ADD CONSTRAINT fk_comp_typ_slt_tmplt_slttypid
	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);

-- FOREIGN KEYS TO
-- consider FK slot_type and val_slot_function
ALTER TABLE slot_type
	ADD CONSTRAINT fk_slot_type_slt_func
	FOREIGN KEY (slot_function) REFERENCES val_slot_function(slot_function);
-- consider FK slot_type and val_slot_physical_interface
ALTER TABLE slot_type
	ADD CONSTRAINT fk_slot_type_physint_func
	FOREIGN KEY (slot_physical_interface_type, slot_function) REFERENCES val_slot_physical_interface(slot_physical_interface_type, slot_function);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'slot_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'slot_type');
ALTER SEQUENCE slot_type_slot_type_id_seq
	 OWNED BY slot_type.slot_type_id;
-- DONE DEALING WITH TABLE slot_type [545849]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE logical_port_slot
CREATE TABLE logical_port_slot
(
	logical_port_id	integer NOT NULL,
	slot_id	integer NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'logical_port_slot', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE logical_port_slot ADD CONSTRAINT pk_logical_port_slot PRIMARY KEY (logical_port_id, slot_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_lgl_port_slot_slot_id ON logical_port_slot USING btree (slot_id);
CREATE INDEX xif_lgl_port_slot_lgl_port_id ON logical_port_slot USING btree (logical_port_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK logical_port_slot and logical_port
ALTER TABLE logical_port_slot
	ADD CONSTRAINT fk_lgl_port_slot_lgl_port_id
	FOREIGN KEY (logical_port_id) REFERENCES logical_port(logical_port_id);
-- consider FK logical_port_slot and slot
-- Skipping this FK since table does not exist yet
--ALTER TABLE logical_port_slot
--	ADD CONSTRAINT fk_lgl_port_slot_slot_id
--	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'logical_port_slot');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'logical_port_slot');
-- DONE DEALING WITH TABLE logical_port_slot [545217]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE slot
CREATE TABLE slot
(
	slot_id	integer NOT NULL,
	component_id	integer NOT NULL,
	slot_name	varchar(50) NOT NULL,
	slot_type_id	integer NOT NULL,
	component_type_slot_tmplt_id	integer  NULL,
	is_enabled	character(1) NOT NULL,
	physical_label	varchar(50)  NULL,
	description	varchar(255)  NULL,
	slot_x_offset	integer  NULL,
	slot_y_offset	integer  NULL,
	slot_z_offset	integer  NULL,
	slot_side	varchar(50) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'slot', true);
ALTER TABLE slot
	ALTER slot_id
	SET DEFAULT nextval('slot_slot_id_seq'::regclass);
ALTER TABLE slot
	ALTER is_enabled
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE slot
	ALTER slot_side
	SET DEFAULT 'FRONT'::character varying;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE slot ADD CONSTRAINT ak_slot_slot_type_id UNIQUE (slot_id, slot_type_id);
ALTER TABLE slot ADD CONSTRAINT pk_slot_id PRIMARY KEY (slot_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_slot_cmp_typ_tmp_id ON slot USING btree (component_type_slot_tmplt_id);
CREATE INDEX xif_slot_slot_type_id ON slot USING btree (slot_type_id);
CREATE INDEX xif_slot_component_id ON slot USING btree (component_id);

-- CHECK CONSTRAINTS
ALTER TABLE slot ADD CONSTRAINT checkslot_enbled__yes_no
	CHECK (is_enabled = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE slot ADD CONSTRAINT ckc_slot_slot_side
	CHECK ((slot_side)::text = ANY ((ARRAY['FRONT'::character varying, 'BACK'::character varying])::text[]));

-- FOREIGN KEYS FROM
-- consider FK slot and component_property
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_slt_slt_id
	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);
-- consider FK slot and inter_component_connection
ALTER TABLE inter_component_connection
	ADD CONSTRAINT fk_intercomp_conn_slot2_id
	FOREIGN KEY (slot2_id) REFERENCES slot(slot_id);
-- consider FK slot and inter_component_connection
ALTER TABLE inter_component_connection
	ADD CONSTRAINT fk_intercomp_conn_slot1_id
	FOREIGN KEY (slot1_id) REFERENCES slot(slot_id);
-- consider FK slot and component
-- Skipping this FK since table does not exist yet
--ALTER TABLE component
--	ADD CONSTRAINT fk_component_prnt_slt_id
--	FOREIGN KEY (parent_slot_id) REFERENCES slot(slot_id);

-- consider FK slot and logical_port_slot
ALTER TABLE logical_port_slot
	ADD CONSTRAINT fk_lgl_port_slot_slot_id
	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);

-- FOREIGN KEYS TO
-- consider FK slot and component_type_slot_tmplt
ALTER TABLE slot
	ADD CONSTRAINT fk_slot_cmp_typ_tmp_id
	FOREIGN KEY (component_type_slot_tmplt_id) REFERENCES component_type_slot_tmplt(component_type_slot_tmplt_id);
-- consider FK slot and slot_type
ALTER TABLE slot
	ADD CONSTRAINT fk_slot_slot_type_id
	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK slot and component
-- Skipping this FK since table does not exist yet
--ALTER TABLE slot
--	ADD CONSTRAINT fk_slot_component_id
--	FOREIGN KEY (component_id) REFERENCES component(component_id);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'slot');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'slot');
ALTER SEQUENCE slot_slot_id_seq
	 OWNED BY slot.slot_id;
-- DONE DEALING WITH TABLE slot [545829]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE component_type_component_func
CREATE TABLE component_type_component_func
(
	component_function	varchar(50) NOT NULL,
	component_type_id	integer NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'component_type_component_func', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE component_type_component_func ADD CONSTRAINT pk_component_type_component_fu PRIMARY KEY (component_function, component_type_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_cmptypcf_comp_func ON component_type_component_func USING btree (component_function);
CREATE INDEX xif_cmptypecf_comp_typ_id ON component_type_component_func USING btree (component_type_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK component_type_component_func and component_type
ALTER TABLE component_type_component_func
	ADD CONSTRAINT fk_cmptypecf_comp_typ_id
	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);
-- consider FK component_type_component_func and val_component_function
ALTER TABLE component_type_component_func
	ADD CONSTRAINT fk_cmptypcf_comp_func
	FOREIGN KEY (component_function) REFERENCES val_component_function(component_function);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'component_type_component_func');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'component_type_component_func');
-- DONE DEALING WITH TABLE component_type_component_func [544656]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE component
CREATE TABLE component
(
	component_id	integer NOT NULL,
	component_type_id	integer NOT NULL,
	component_name	varchar(255)  NULL,
	rack_location_id	integer  NULL,
	parent_slot_id	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'component', true);
ALTER TABLE component
	ALTER component_id
	SET DEFAULT nextval('component_component_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE component ADD CONSTRAINT ak_component_component_type_id UNIQUE (component_id, component_type_id);
ALTER TABLE component ADD CONSTRAINT pk_component PRIMARY KEY (component_id);
ALTER TABLE component ADD CONSTRAINT ak_component_parent_slot_id UNIQUE (parent_slot_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_component_rack_loc_id ON component USING btree (rack_location_id);
CREATE INDEX xif_component_comp_type_id ON component USING btree (component_type_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK component and asset
ALTER TABLE asset
	ADD CONSTRAINT fk_asset_comp_id
	FOREIGN KEY (component_id) REFERENCES component(component_id);
-- consider FK component and device
ALTER TABLE device
	ADD CONSTRAINT fk_device_comp_id
	FOREIGN KEY (component_id) REFERENCES component(component_id);
-- consider FK component and slot
ALTER TABLE slot
	ADD CONSTRAINT fk_slot_component_id
	FOREIGN KEY (component_id) REFERENCES component(component_id);
-- consider FK component and physicalish_volume
-- Skipping this FK since table does not exist yet
--ALTER TABLE physicalish_volume
--	ADD CONSTRAINT r_636
--	FOREIGN KEY (component_id) REFERENCES component(component_id);

-- consider FK component and component_property
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_cmp_id
	FOREIGN KEY (component_id) REFERENCES component(component_id);

-- FOREIGN KEYS TO
-- consider FK component and component_type
ALTER TABLE component
	ADD CONSTRAINT fk_component_comp_type_i
	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);
-- consider FK component and rack_location
ALTER TABLE component
	ADD CONSTRAINT fk_component_rack_loc_id
	FOREIGN KEY (rack_location_id) REFERENCES rack_location(rack_location_id);
-- consider FK component and slot
ALTER TABLE component
	ADD CONSTRAINT fk_component_prnt_slt_id
	FOREIGN KEY (parent_slot_id) REFERENCES slot(slot_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'component');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'component');
ALTER SEQUENCE component_component_id_seq
	 OWNED BY component.component_id;
-- DONE DEALING WITH TABLE component [544601]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE physicalish_volume
CREATE TABLE physicalish_volume
(
	physicalish_volume_id	integer NOT NULL,
	logical_volume_id	integer  NULL,
	component_id	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'physicalish_volume', true);
ALTER TABLE physicalish_volume
	ALTER physicalish_volume_id
	SET DEFAULT nextval('physicalish_volume_physicalish_volume_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE physicalish_volume ADD CONSTRAINT pk_physicalish_volume PRIMARY KEY (physicalish_volume_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif2physicalish_volume ON physicalish_volume USING btree (component_id);
CREATE INDEX xif1physicalish_volume ON physicalish_volume USING btree (logical_volume_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK physicalish_volume and volume_group_physicalish_vol
-- Skipping this FK since table does not exist yet
--ALTER TABLE volume_group_physicalish_vol
--	ADD CONSTRAINT r_630
--	FOREIGN KEY (physicalish_volume_id) REFERENCES physicalish_volume(physicalish_volume_id);


-- FOREIGN KEYS TO
-- consider FK physicalish_volume and logical_volume
-- Skipping this FK since table does not exist yet
--ALTER TABLE physicalish_volume
--	ADD CONSTRAINT r_634
--	FOREIGN KEY (logical_volume_id) REFERENCES logical_volume(logical_volume_id);

-- consider FK physicalish_volume and component
ALTER TABLE physicalish_volume
	ADD CONSTRAINT r_636
	FOREIGN KEY (component_id) REFERENCES component(component_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'physicalish_volume');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'physicalish_volume');
ALTER SEQUENCE physicalish_volume_physicalish_volume_id_seq
	 OWNED BY physicalish_volume.physicalish_volume_id;
-- DONE DEALING WITH TABLE physicalish_volume [545646]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE volume_group_physicalish_vol
CREATE TABLE volume_group_physicalish_vol
(
	physicalish_volume_id	integer NOT NULL,
	volume_group_id	integer NOT NULL,
	volume_group_position	integer NOT NULL,
	volume_group_relation	varchar(50) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'volume_group_physicalish_vol', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE volume_group_physicalish_vol ADD CONSTRAINT ak_volgrp_pv_position UNIQUE (volume_group_id, volume_group_position);
ALTER TABLE volume_group_physicalish_vol ADD CONSTRAINT pk_volume_group_physicalish_vo PRIMARY KEY (physicalish_volume_id, volume_group_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif4volume_group_physicalish_v ON volume_group_physicalish_vol USING btree (volume_group_relation);
CREATE INDEX xif1volume_group_physicalish_v ON volume_group_physicalish_vol USING btree (physicalish_volume_id);
CREATE INDEX xif3volume_group_physicalish_v ON volume_group_physicalish_vol USING btree (volume_group_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK volume_group_physicalish_vol and volume_group
-- Skipping this FK since table does not exist yet
--ALTER TABLE volume_group_physicalish_vol
--	ADD CONSTRAINT r_633
--	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id);

-- consider FK volume_group_physicalish_vol and val_volume_group_relation
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT r_645
	FOREIGN KEY (volume_group_relation) REFERENCES val_volume_group_relation(volume_group_relation);
-- consider FK volume_group_physicalish_vol and physicalish_volume
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT r_630
	FOREIGN KEY (physicalish_volume_id) REFERENCES physicalish_volume(physicalish_volume_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'volume_group_physicalish_vol');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'volume_group_physicalish_vol');
-- DONE DEALING WITH TABLE volume_group_physicalish_vol [546986]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE logical_volume
CREATE TABLE logical_volume
(
	logical_volume_id	integer NOT NULL,
	volume_group_id	integer NOT NULL,
	logical_volume_name	varchar(50) NOT NULL,
	logical_volume_size_in_mb	integer NOT NULL,
	logical_volume_offset_in_mb	integer  NULL,
	filesystem_type	varchar(50) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'logical_volume', true);
ALTER TABLE logical_volume
	ALTER logical_volume_id
	SET DEFAULT nextval('logical_volume_logical_volume_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE logical_volume ADD CONSTRAINT pk_logical_volume PRIMARY KEY (logical_volume_id);
ALTER TABLE logical_volume ADD CONSTRAINT ak_logical_volume_filesystem UNIQUE (logical_volume_id, filesystem_type);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif1logical_volume ON logical_volume USING btree (volume_group_id);
CREATE INDEX xif2logical_volume ON logical_volume USING btree (filesystem_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK logical_volume and logical_volume_property
-- Skipping this FK since table does not exist yet
--ALTER TABLE logical_volume_property
--	ADD CONSTRAINT r_642
--	FOREIGN KEY (logical_volume_id, filesystem_type) REFERENCES logical_volume(logical_volume_id, filesystem_type);

-- consider FK logical_volume and physicalish_volume
ALTER TABLE physicalish_volume
	ADD CONSTRAINT r_634
	FOREIGN KEY (logical_volume_id) REFERENCES logical_volume(logical_volume_id);

-- FOREIGN KEYS TO
-- consider FK logical_volume and val_filesystem_type
ALTER TABLE logical_volume
	ADD CONSTRAINT r_638
	FOREIGN KEY (filesystem_type) REFERENCES val_filesystem_type(filesystem_type);
-- consider FK logical_volume and volume_group
-- Skipping this FK since table does not exist yet
--ALTER TABLE logical_volume
--	ADD CONSTRAINT r_632
--	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'logical_volume');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'logical_volume');
ALTER SEQUENCE logical_volume_logical_volume_id_seq
	 OWNED BY logical_volume.logical_volume_id;
-- DONE DEALING WITH TABLE logical_volume [545229]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE logical_volume_property
CREATE TABLE logical_volume_property
(
	logical_volume_property_id	integer NOT NULL,
	logical_volume_id	integer  NULL,
	filesystem_type	varchar(50)  NULL,
	logical_volume_property_name	varchar(50)  NULL,
	logical_volume_property_value	varchar(255)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'logical_volume_property', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE logical_volume_property ADD CONSTRAINT ak_logical_vol_prop_fs_lv_name UNIQUE (logical_volume_id, logical_volume_property_name);
ALTER TABLE logical_volume_property ADD CONSTRAINT pk_logical_volume_property PRIMARY KEY (logical_volume_property_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif1logical_volume_property ON logical_volume_property USING btree (logical_volume_id, filesystem_type);
CREATE INDEX xif2logical_volume_property ON logical_volume_property USING btree (logical_volume_property_name, filesystem_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK logical_volume_property and val_logical_volume_property
ALTER TABLE logical_volume_property
	ADD CONSTRAINT r_644
	FOREIGN KEY (logical_volume_property_name, filesystem_type) REFERENCES val_logical_volume_property(logical_volume_property_name, filesystem_type);
-- consider FK logical_volume_property and logical_volume
ALTER TABLE logical_volume_property
	ADD CONSTRAINT r_642
	FOREIGN KEY (logical_volume_id, filesystem_type) REFERENCES logical_volume(logical_volume_id, filesystem_type);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'logical_volume_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'logical_volume_property');
-- DONE DEALING WITH TABLE logical_volume_property [545242]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE volume_group
CREATE TABLE volume_group
(
	volume_group_id	integer NOT NULL,
	volume_group_name	varchar(50) NOT NULL,
	raid_type	varchar(50)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'volume_group', true);
ALTER TABLE volume_group
	ALTER volume_group_id
	SET DEFAULT nextval('volume_group_volume_group_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE volume_group ADD CONSTRAINT pk_volume_group PRIMARY KEY (volume_group_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif1volume_group ON volume_group USING btree (raid_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK volume_group and volume_group_physicalish_vol
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT r_633
	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id);
-- consider FK volume_group and logical_volume
ALTER TABLE logical_volume
	ADD CONSTRAINT r_632
	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id);

-- FOREIGN KEYS TO
-- consider FK volume_group and val_raid_type
ALTER TABLE volume_group
	ADD CONSTRAINT r_639
	FOREIGN KEY (raid_type) REFERENCES val_raid_type(raid_type);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'volume_group');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'volume_group');
ALTER SEQUENCE volume_group_volume_group_id_seq
	 OWNED BY volume_group.volume_group_id;
-- DONE DEALING WITH TABLE volume_group [546976]
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH proc delete_peruser_account_collection -> delete_peruser_account_collection 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'delete_peruser_account_collection', 'delete_peruser_account_collection');

-- DROP OLD FUNCTION
-- consider old oid 544137
DROP FUNCTION IF EXISTS delete_peruser_account_collection();

-- DONE WITH proc delete_peruser_account_collection -> delete_peruser_account_collection 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc update_peruser_account_collection -> update_peruser_account_collection 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'update_peruser_account_collection', 'update_peruser_account_collection');

-- DROP OLD FUNCTION
-- consider old oid 544139
DROP FUNCTION IF EXISTS update_peruser_account_collection();

-- DONE WITH proc update_peruser_account_collection -> update_peruser_account_collection 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc netblock_utils.list_unallocated_netblocks -> list_unallocated_netblocks 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('netblock_utils', 'list_unallocated_netblocks', 'list_unallocated_netblocks');

-- DROP OLD FUNCTION
-- consider old oid 544115
DROP FUNCTION IF EXISTS netblock_utils.list_unallocated_netblocks(netblock_id integer, ip_address inet, ip_universe_id integer, netblock_type text);

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider old oid 544115
DROP FUNCTION IF EXISTS netblock_utils.list_unallocated_netblocks(netblock_id integer, ip_address inet, ip_universe_id integer, netblock_type text);
-- consider NEW oid 552583
CREATE OR REPLACE FUNCTION netblock_utils.list_unallocated_netblocks(netblock_id integer DEFAULT NULL::integer, ip_address inet DEFAULT NULL::inet, ip_universe_id integer DEFAULT 0, netblock_type text DEFAULT 'default'::text)
 RETURNS TABLE(ip_addr inet)
 LANGUAGE plpgsql
AS $function$
DECLARE
	ip_array		inet[];
	netblock_rec	RECORD;
	parent_nbid		jazzhands.netblock.netblock_id%TYPE;
	family_bits		integer;
	idx				integer;
BEGIN
	IF netblock_id IS NOT NULL THEN
		SELECT * INTO netblock_rec FROM jazzhands.netblock n WHERE n.netblock_id = 
			list_unallocated_netblocks.netblock_id;
		IF NOT FOUND THEN
			RAISE EXCEPTION 'netblock_id % not found', netblock_id;
		END IF;
		IF netblock_rec.is_single_address = 'Y' THEN
			RETURN;
		END IF;
		ip_address := netblock_rec.ip_address;
		ip_universe_id := netblock_rec.ip_universe_id;
		netblock_type := netblock_rec.netblock_type;
	ELSIF ip_address IS NOT NULL THEN
		ip_universe_id := 0;
		netblock_type := 'default';
	ELSE
		RAISE EXCEPTION 'netblock_id or ip_address must be passed';
	END IF;
	SELECT ARRAY(
		SELECT 
			n.ip_address
		FROM
			netblock n
		WHERE
			n.ip_address <<= list_unallocated_netblocks.ip_address AND
			n.ip_universe_id = list_unallocated_netblocks.ip_universe_id AND
			n.netblock_type = list_unallocated_netblocks.netblock_type AND
			is_single_address = 'N' AND
			can_subnet = 'N'
		ORDER BY
			n.ip_address
	) INTO ip_array;

	IF array_length(ip_array, 1) IS NULL THEN
		ip_addr := ip_address;
		RETURN NEXT;
		RETURN;
	END IF;

	ip_array := array_prepend(
		list_unallocated_netblocks.ip_address - 1, 
		array_append(
			ip_array, 
			broadcast(list_unallocated_netblocks.ip_address) + 1
			));

	idx := 1;
	WHILE idx < array_length(ip_array, 1) LOOP
		RETURN QUERY SELECT cin.ip_addr FROM
			netblock_utils.calculate_intermediate_netblocks(ip_array[idx], ip_array[idx + 1]) cin;
		idx := idx + 1;
	END LOOP;

	RETURN;
END;
$function$
;

-- DONE WITH proc netblock_utils.list_unallocated_netblocks -> list_unallocated_netblocks 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc person_manip.purge_account -> purge_account 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('person_manip', 'purge_account', 'purge_account');

-- DROP OLD FUNCTION
-- consider old oid 544069
DROP FUNCTION IF EXISTS person_manip.purge_account(in_account_id integer);

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider old oid 544069
DROP FUNCTION IF EXISTS person_manip.purge_account(in_account_id integer);
-- consider NEW oid 552542
CREATE OR REPLACE FUNCTION person_manip.purge_account(in_account_id integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
	-- note the per-account account collection is removed in triggers

	DELETE FROM account_assignd_cert where ACCOUNT_ID = in_account_id;
	DELETE FROM account_token where ACCOUNT_ID = in_account_id;
	DELETE FROM account_unix_info where ACCOUNT_ID = in_account_id;
	DELETE FROM klogin where ACCOUNT_ID = in_account_id;
	DELETE FROM property where ACCOUNT_ID = in_account_id;
	DELETE FROM account_password where ACCOUNT_ID = in_account_id;
	DELETE FROM unix_group where account_collection_id in
		(select account_collection_id from account_collection 
			where account_collection_name in
				(select login from account where account_id = in_account_id)
				and account_collection_type in ('unix-group')
		);
	DELETE FROM account_collection_account where ACCOUNT_ID = in_account_id;

	DELETE FROM account_collection where account_collection_name in
		(select login from account where account_id = in_account_id)
		and account_collection_type in ('per-account', 'unix-group');

	DELETE FROM account where ACCOUNT_ID = in_account_id;
END;
$function$
;

-- DONE WITH proc person_manip.purge_account -> purge_account 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc automated_ac_on_account -> automated_ac_on_account 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 552680
CREATE OR REPLACE FUNCTION jazzhands.automated_ac_on_account()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_tally	INTEGER;
	_r		RECORD;
BEGIN
	IF TG_OP = 'DELETE' THEN
		IF OLD.account_role != 'primary' THEN
			RETURN OLD;
		END IF;
	ELSIF TG_OP = 'INSERT' THEN
		IF NEW.account_role != 'primary' THEN
			RETURN NEW;
		END IF;
	ELSIF TG_OP = 'UPDATE' THEN
		IF NEW.account_role != 'primary' AND OLD.account_role != 'primary' THEN
			RETURN NEW;
		END IF;
	END IF;


	SELECT  count(*)
	  INTO  _tally
	  FROM  pg_catalog.pg_class
	 WHERE  relname = '__automated_ac__'
	   AND  relpersistence = 't';

	IF _tally = 0 THEN
		CREATE TEMPORARY TABLE IF NOT EXISTS __automated_ac__ (account_collection_id integer, account_id integer, direction text);
	END IF;


	--
	-- based on the old and new values, check for account collections that
	-- may need to be changed based on data.  Note that this may end up being
	-- a no-op.
	-- 
	IF TG_OP = 'INSERT' or TG_OP = 'UPDATE' THEN
		WITH acct AS (
			    SELECT  a.account_id, a.account_type, a.account_role, parc.*,
				    pc.is_management, pc.is_full_time, pc.is_exempt,
				    p.gender
			     FROM   account a
				    INNER JOIN person_account_realm_company parc
					    USING (person_id, company_id, account_realm_id)
				    INNER JOIN person_company pc USING (person_id,company_id)
				    INNER JOIN person p USING (person_id)
			),
		list AS (
			SELECT  p.account_collection_id, a.account_id, a.account_type,
				a.account_role,
				a.person_id, a.company_id
			FROM    property p
			    INNER JOIN acct a
				ON a.account_realm_id = p.account_realm_id
			WHERE   (p.company_id is NULL or a.company_id = p.company_id)
			    AND     property_type = 'auto_acct_coll'
			    AND     (
				    property_name =
					CASE WHEN a.is_exempt = 'N'
					    THEN 'non_exempt'
					    ELSE 'exempt' END
				OR
				    property_name =
					CASE WHEN a.is_management = 'N'
					    THEN 'non_management'
					    ELSE 'management' END
				OR
				    property_name =
					CASE WHEN a.is_full_time = 'N'
					    THEN 'non_full_time'
					    ELSE 'full_time' END
				OR
				    property_name =
					CASE WHEN a.gender = 'M' THEN 'male'
					    WHEN a.gender = 'F' THEN 'female'
					    ELSE 'unspecified_gender' END
				OR (
				    property_name = 'account_type'
				    AND property_value = a.account_type
				    )
				)
		) 
		INSERT INTO __automated_ac__ (
			account_collection_id, account_id, direction
		) select account_collection_id, account_id, 'add'
		FROM list 
		WHERE account_id = NEW.account_id
		AND NEW.account_role = 'primary'
		;
	END IF;
	IF TG_OP = 'UPDATE' or TG_OP = 'DELETE' THEN
		WITH acct AS (
			    SELECT  a.account_id, a.account_type, a.account_role, parc.*,
				    pc.is_management, pc.is_full_time, pc.is_exempt,
				    p.gender
			     FROM   account a
				    INNER JOIN person_account_realm_company parc
					    USING (person_id, company_id, account_realm_id)
				    INNER JOIN person_company pc USING (person_id,company_id)
				    INNER JOIN person p USING (person_id)
			),
		list AS (
			SELECT  p.account_collection_id, a.account_id, a.account_type,
				a.account_role,
				a.person_id, a.company_id
			FROM    property p
			    INNER JOIN acct a
				ON a.account_realm_id = p.account_realm_id
			WHERE   (p.company_id is NULL or a.company_id = p.company_id)
			    AND     property_type = 'auto_acct_coll'
				AND (
					( account_role != 'primary' AND
						property_name in ('non_exempt', 'exempt',
						'management', 'non_management', 'full_time',
						'non_full_time', 'male', 'female', 'unspecified_gender')
				) OR (
					account_role != 'primary'
				    AND property_name = 'account_type'
				    AND property_value = a.account_type
				    )
				)
		) 
		INSERT INTO __automated_ac__ (
			account_collection_id, account_id, direction
		) select account_collection_id, account_id, 'remove'
		FROM list 
		WHERE account_id = OLD.account_id
		;
	END IF;

	/*
		FOR _r IN SELECT * from __automated_ac__
		LOOP
			RAISE NOTICE '%', _r;
		END LOOP;
	 */

	--
	-- Remove rows from the temporary table that are in "remove" but not in
	-- "add".
	--
	DELETE FROM account_collection_account
	WHERE (account_collection_id, account_id) IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'remove'
		)
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'add'
	)
	;
	--
	-- Add rows from the temporary table that are in 'add" but not "remove"
	-- "add".
	--
	INSERT INTO account_collection_account (
		account_collection_id, account_id)
	SELECT account_collection_id, account_id 
	FROM __automated_ac__
	WHERE direction = 'add'
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'remove'
	)
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM account_collection_account)
	;

	DROP TABLE IF EXISTS __automated_ac__;

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	ELSE
		RETURN NEW;
	END IF;
END;
$function$
;

-- DONE WITH proc automated_ac_on_account -> automated_ac_on_account 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc automated_ac_on_person_company -> automated_ac_on_person_company 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'automated_ac_on_person_company', 'automated_ac_on_person_company');

-- DROP OLD FUNCTION
-- consider old oid 544218

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider old oid 544218
-- consider NEW oid 552683
CREATE OR REPLACE FUNCTION jazzhands.automated_ac_on_person_company()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_tally	INTEGER;
BEGIN
	SELECT  count(*)
	  INTO  _tally
	  FROM  pg_catalog.pg_class
	 WHERE  relname = '__automated_ac__'
	   AND  relpersistence = 't';

	IF _tally = 0 THEN
		CREATE TEMPORARY TABLE IF NOT EXISTS __automated_ac__ (account_collection_id integer, account_id integer, direction text);
	END IF;


	--
	-- based on the old and new values, check for account collections that
	-- may need to be changed based on data.  Note that this may end up being
	-- a no-op.
	-- 
	IF TG_OP = 'INSERT' or TG_OP = 'UPDATE' THEN
		INSERT INTO __automated_ac__ (
			account_collection_id, account_id, direction
		)
		SELECT	p.account_collection_id, a.account_id, 'add'
		FROM    property p
			INNER JOIN account_realm_company arc USING (account_realm_id)
			INNER JOIN account a 
				ON a.account_realm_id = arc.account_realm_id
				AND a.company_id = arc.company_id
		WHERE	arc.company_id = NEW.company_id
		AND     (p.company_id is NULL or arc.company_id = p.company_id)
			AND	a.person_id = NEW.person_id
			AND     property_type = 'auto_acct_coll'
			AND     (
				    property_name =
				    CASE WHEN NEW.is_exempt = 'N'
					THEN 'non_exempt'
					ELSE 'exempt' END
				OR
				    property_name =
				    CASE WHEN NEW.is_management = 'N'
					THEN 'non_management'
					ELSE 'management' END
				OR
				    property_name =
				    CASE WHEN NEW.is_full_time = 'N'
					THEN 'non_full_time'
					ELSE 'full_time' END
				);
	END IF;
	IF TG_OP = 'UPDATE' or TG_OP = 'DELETE' THEN
		INSERT INTO __automated_ac__ (
			account_collection_id, account_id, direction
		)
		SELECT	p.account_collection_id, a.account_id, 'remove'
		FROM    property p
			INNER JOIN account_realm_company arc USING (account_realm_id)
			INNER JOIN account a 
				ON a.account_realm_id = arc.account_realm_id
				AND a.company_id = arc.company_id
		WHERE	arc.company_id = OLD.company_id
		AND     (p.company_id is NULL or arc.company_id = p.company_id)
			AND	a.person_id = OLD.person_id
			AND     property_type = 'auto_acct_coll'
			AND     (
				    property_name =
				    CASE WHEN OLD.is_exempt = 'N'
					THEN 'non_exempt'
					ELSE 'exempt' END
				OR
				    property_name =
				    CASE WHEN OLD.is_management = 'N'
					THEN 'non_management'
					ELSE 'management' END
				OR
				    property_name =
				    CASE WHEN OLD.is_full_time = 'N'
					THEN 'non_full_time'
					ELSE 'full_time' END
				);
	END IF;

	--
	-- Remove rows from the temporary table that are in "remove" but not in
	-- "add".
	--
	DELETE FROM account_collection_account
	WHERE (account_collection_id, account_id) IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'remove'
		)
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'add'
	);

	--
	-- Add rows from the temporary table that are in 'add" but not "remove"
	-- "add".
	--
	INSERT INTO account_collection_account (
		account_collection_id, account_id)
	SELECT account_collection_id, account_id 
	FROM __automated_ac__
	WHERE direction = 'add'
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'remove'
	);

	DROP TABLE IF EXISTS __automated_ac__;

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	ELSE
		RETURN NEW;
	END IF;
END;
$function$
;

-- DONE WITH proc automated_ac_on_person_company -> automated_ac_on_person_company 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc automated_ac_on_person -> automated_ac_on_person 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'automated_ac_on_person', 'automated_ac_on_person');

-- DROP OLD FUNCTION
-- consider old oid 544220

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider old oid 544220
-- consider NEW oid 552685
CREATE OR REPLACE FUNCTION jazzhands.automated_ac_on_person()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_tally	INTEGER;
BEGIN
	SELECT  count(*)
	  INTO  _tally
	  FROM  pg_catalog.pg_class
	 WHERE  relname = '__automated_ac__'
	   AND  relpersistence = 't';

	IF _tally = 0 THEN
		CREATE TEMPORARY TABLE IF NOT EXISTS __automated_ac__ (account_collection_id integer, account_id integer, direction text);
	END IF;


	--
	-- based on the old and new values, check for account collections that
	-- may need to be changed based on data.  Note that this may end up being
	-- a no-op.
	-- 
	IF TG_OP = 'UPDATE' THEN
		INSERT INTO __automated_ac__ (
			account_collection_id, account_id, direction
		)
		SELECT	p.account_collection_id, a.account_id, 'add'
		FROM    property p
			INNER JOIN account_realm_company arc USING (account_realm_id)
			INNER JOIN account a 
				ON a.account_realm_id = arc.account_realm_id
				AND a.company_id = arc.company_id
		WHERE	arc.company_id = NEW.company_id
		AND     (p.company_id is NULL or arc.company_id = p.company_id)
			AND	a.person_id = NEW.person_id
			AND     property_type = 'auto_acct_coll'
			AND     (
				    property_name =
				    	CASE WHEN NEW.gender = 'M' THEN 'male'
				    		WHEN NEW.gender = 'F' THEN 'female'
							ELSE 'unspecified_gender' END
					);

		INSERT INTO __automated_ac__ (
			account_collection_id, account_id, direction
		)
		SELECT	p.account_collection_id, a.account_id, 'remove'
		FROM    property p
			INNER JOIN account_realm_company arc USING (account_realm_id)
			INNER JOIN account a 
				ON a.account_realm_id = arc.account_realm_id
				AND a.company_id = arc.company_id
		WHERE	arc.company_id = OLD.company_id
		AND     (p.company_id is NULL or arc.company_id = p.company_id)
			AND	a.person_id = OLD.person_id
			AND     property_type = 'auto_acct_coll'
			AND     (
				    property_name =
				    	CASE WHEN OLD.gender = 'M' THEN 'male'
				    	WHEN OLD.gender = 'F' THEN 'female'
						ELSE 'unspecified_gender' END
				);
	END IF;

	--
	-- Remove rows from the temporary table that are in "remove" but not in
	-- "add".
	--
	DELETE FROM account_collection_account
	WHERE (account_collection_id, account_id) IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'remove'
		)
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'add'
	);

	--
	-- Add rows from the temporary table that are in 'add" but not "remove"
	-- "add".
	--
	INSERT INTO account_collection_account (
		account_collection_id, account_id)
	SELECT account_collection_id, account_id 
	FROM __automated_ac__
	WHERE direction = 'add'
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'remove'
	);

	DROP TABLE IF EXISTS __automated_ac__;

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	ELSE
		RETURN NEW;
	END IF;

END;
$function$
;

-- DONE WITH proc automated_ac_on_person -> automated_ac_on_person 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc automated_realm_site_ac_pl -> automated_realm_site_ac_pl 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'automated_realm_site_ac_pl', 'automated_realm_site_ac_pl');

-- DROP OLD FUNCTION
-- consider old oid 544222

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider old oid 544222
-- consider NEW oid 552687
CREATE OR REPLACE FUNCTION jazzhands.automated_realm_site_ac_pl()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_tally	INTEGER;
BEGIN
	SELECT  count(*)
	  INTO  _tally
	  FROM  pg_catalog.pg_class
	 WHERE  relname = '__automated_ac__'
	   AND  relpersistence = 't';

	IF _tally = 0 THEN
		CREATE TEMPORARY TABLE IF NOT EXISTS __automated_ac__ (account_collection_id integer, account_id integer, direction text);
	END IF;

	--
	-- based on the old and new values, check for account collections that
	-- may need to be changed based on data.  Note that this may end up being
	-- a no-op.
	-- 
	IF TG_OP = 'INSERT' or TG_OP = 'UPDATE' THEN
		INSERT INTO __automated_ac__ (
			account_collection_id, account_id, direction
		)
		SELECT	p.account_collection_id, a.account_id, 'add'
		FROM    property p
			INNER JOIN account_realm_company arc USING (account_realm_id)
			INNER JOIN account a 
				ON a.account_realm_id = arc.account_realm_id
				AND a.company_id = arc.company_id
		WHERE   (p.company_id is NULL or arc.company_id = p.company_id)
			AND	a.person_id = NEW.person_id
			AND		p.site_code = NEW.site_code
			AND     property_type = 'auto_acct_coll'
			AND     property_name = 'site'
		;
	END IF;
	IF TG_OP = 'UPDATE' or TG_OP = 'DELETE' THEN
		INSERT INTO __automated_ac__ (
			account_collection_id, account_id, direction
		)
		SELECT	p.account_collection_id, a.account_id, 'remove'
		FROM    property p
			INNER JOIN account_realm_company arc USING (account_realm_id)
			INNER JOIN account a 
				ON a.account_realm_id = arc.account_realm_id
				AND a.company_id = arc.company_id
		WHERE   (p.company_id is NULL or arc.company_id = p.company_id)
			AND	a.person_id = OLD.person_id
			AND		p.site_code = OLD.site_code
			AND     property_type = 'auto_acct_coll'
			AND     property_name = 'site'
		;
	END IF;
	--
	-- Remove rows from the temporary table that are in "remove" but not in
	-- "add".
	--
	DELETE FROM account_collection_account
	WHERE (account_collection_id, account_id) IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'remove'
		)
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'add'
	);

	--
	-- Add rows from the temporary table that are in 'add" but not "remove"
	-- "add".
	--
	INSERT INTO account_collection_account (
		account_collection_id, account_id)
	SELECT account_collection_id, account_id 
	FROM __automated_ac__
	WHERE direction = 'add'
	AND (account_collection_id, account_id) NOT IN
		(select account_collection_id, account_id FROM __automated_ac__
			WHERE direction = 'remove'
	);

	DROP TABLE IF EXISTS __automated_ac__;

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	ELSE
		RETURN NEW;
	END IF;

END;
$function$
;

-- DONE WITH proc automated_realm_site_ac_pl -> automated_realm_site_ac_pl 
--------------------------------------------------------------------

-- Dropping obsoleted sequences....


-- Dropping obsoleted audit sequences....


-- Processing tables with no structural changes
-- Some of these may be redundant
-- fk constraints
ALTER TABLE account_realm_company DROP CONSTRAINT IF EXISTS fk_acct_rlm_cmpy_cmpy_id;
ALTER TABLE account_realm_company
	ADD CONSTRAINT fk_acct_rlm_cmpy_cmpy_id
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE circuit DROP CONSTRAINT IF EXISTS fk_circuit_aloc_companyid;
ALTER TABLE circuit
	ADD CONSTRAINT fk_circuit_aloc_companyid
	FOREIGN KEY (aloc_lec_company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE circuit DROP CONSTRAINT IF EXISTS fk_circuit_vend_companyid;
ALTER TABLE circuit
	ADD CONSTRAINT fk_circuit_vend_companyid
	FOREIGN KEY (vendor_company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE circuit DROP CONSTRAINT IF EXISTS fk_circuit_zloc_company_id;
ALTER TABLE circuit
	ADD CONSTRAINT fk_circuit_zloc_company_id
	FOREIGN KEY (zloc_lec_company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE company DROP CONSTRAINT IF EXISTS fk_company_parent_company_id;
ALTER TABLE company
	ADD CONSTRAINT fk_company_parent_company_id
	FOREIGN KEY (parent_company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE company_type DROP CONSTRAINT IF EXISTS fk_company_type_company_id;
ALTER TABLE company_type
	ADD CONSTRAINT fk_company_type_company_id
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE contract DROP CONSTRAINT IF EXISTS fk_contract_company_id;
ALTER TABLE contract
	ADD CONSTRAINT fk_contract_company_id
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE department DROP CONSTRAINT IF EXISTS fk_dept_company;
ALTER TABLE department
	ADD CONSTRAINT fk_dept_company
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE netblock DROP CONSTRAINT IF EXISTS fk_netblock_company;
ALTER TABLE netblock
	ADD CONSTRAINT fk_netblock_company
	FOREIGN KEY (nic_company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE operating_system DROP CONSTRAINT IF EXISTS fk_os_company;
ALTER TABLE operating_system
	ADD CONSTRAINT fk_os_company
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE person_account_realm_company DROP CONSTRAINT IF EXISTS fk_ac_ac_rlm_cpy_act_rlm_cpy;
ALTER TABLE person_account_realm_company
	ADD CONSTRAINT fk_ac_ac_rlm_cpy_act_rlm_cpy
	FOREIGN KEY (account_realm_id, company_id) REFERENCES account_realm_company(account_realm_id, company_id) DEFERRABLE;

ALTER TABLE person_company DROP CONSTRAINT IF EXISTS fk_person_company_company_id;
ALTER TABLE person_company
	ADD CONSTRAINT fk_person_company_company_id
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE person_contact DROP CONSTRAINT IF EXISTS fk_prsn_contect_cr_cmpyid;
ALTER TABLE person_contact
	ADD CONSTRAINT fk_prsn_contect_cr_cmpyid
	FOREIGN KEY (person_contact_cr_company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE physical_address DROP CONSTRAINT IF EXISTS fk_physaddr_company_id;
ALTER TABLE physical_address
	ADD CONSTRAINT fk_physaddr_company_id
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE property DROP CONSTRAINT IF EXISTS fk_property_compid;
ALTER TABLE property
	ADD CONSTRAINT fk_property_compid
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE property DROP CONSTRAINT IF EXISTS fk_property_pval_compid;
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_compid
	FOREIGN KEY (property_value_company_id) REFERENCES company(company_id) DEFERRABLE;

ALTER TABLE site DROP CONSTRAINT IF EXISTS fk_site_colo_company_id;
ALTER TABLE site
	ADD CONSTRAINT fk_site_colo_company_id
	FOREIGN KEY (colo_company_id) REFERENCES company(company_id) DEFERRABLE;

-- triggers
DROP TRIGGER IF EXISTS trig_automated_ac ON account;
DROP TRIGGER IF EXISTS trigger_delete_peruser_account_collection ON account;
DROP TRIGGER IF EXISTS trigger_update_account_type_account_collection ON account;
DROP TRIGGER IF EXISTS trigger_update_peruser_account_collection ON account;
CREATE TRIGGER trig_add_automated_ac_on_account AFTER INSERT OR UPDATE OF account_type, account_role ON account FOR EACH ROW EXECUTE PROCEDURE automated_ac_on_account();
CREATE TRIGGER trig_rm_automated_ac_on_account BEFORE DELETE ON account FOR EACH ROW EXECUTE PROCEDURE automated_ac_on_account();
CREATE TRIGGER trigger_delete_peraccount_account_collection BEFORE DELETE ON account FOR EACH ROW EXECUTE PROCEDURE delete_peraccount_account_collection();
CREATE TRIGGER trigger_update_peraccount_account_collection AFTER INSERT OR UPDATE ON account FOR EACH ROW EXECUTE PROCEDURE update_peraccount_account_collection();

--------------------------------------------------------------------
-- END AUTOGEN DDL
--------------------------------------------------------------------

--------------------------------------------------------------------
-- BEGIN legacy per-user bits
--------------------------------------------------------------------

/*
RAISE EXCEPTION 'Need to cleanup per-user stuff';

-- random queries related to sorting out all the automated/usertype stuff
delete from account_collection_account
where account_collection_id in (
	select account_collection_id
	from account_collection
	where account_collection_type in ('automated', 'usertype')
);
 
 delete from account_collection
where account_collection_id in (
	select account_collection_id
	from account_collection
	where account_collection_type in ('automated', 'usertype')
);
 
select * from account_collection
where account_collection_id in (
	select child_account_collection_id
	from account_collection_hier
) and account_collection_type='automated';

-- Dropping obsoleted sequences....


-- Dropping obsoleted audit sequences....
 */

--------------------------------------------------------------------
-- DONE legacy per-user bits
--------------------------------------------------------------------

--------------------------------------------------------------------
-- BEGIN redo account automated triggers
--------------------------------------------------------------------

DROP TRIGGER IF EXISTS trig_automated_ac ON account;
DROP FUNCTION IF EXISTS automated_ac();

DROP FUNCTION IF EXISTS acct_coll_manip.get_automated_account_collection_id(varchar);
DROP FUNCTION IF EXISTS acct_coll_manip.insert_or_delete_automated_ac(boolean, integer, integer[]);
DROP FUNCTION IF EXISTS acct_coll_manip.person_company_flags_to_automated_ac_name(varchar, varchar, OUT varchar, OUT varchar);
DROP FUNCTION IF EXISTS acct_coll_manip.person_gender_char_to_automated_ac_name(varchar);
DROP SCHEMA IF EXISTS acct_coll_manip;

DROP TRIGGER IF EXISTS trigger_update_account_type_account_collection ON account;
DROP FUNCTION IF EXISTS update_account_type_account_collection(); 


delete from property where property_type = 'auto_acct_coll';
delete from val_property_value where property_type = 'auto_acct_coll';
delete from val_property where property_type = 'auto_acct_coll';
delete from val_property_type where property_type = 'auto_acct_coll';

insert into val_property_type (
	property_type, is_multivalue,
	description
) values (
	'auto_acct_coll', 'Y',
	'properties that define how people are added to account collections automatically based on column changes'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'exempt', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'non_exempt', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'male', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'female', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'unspecified_gender', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'management', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'non_management', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'full_time', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'non_full_time', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'none',
	'N'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'account_type', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'PROHIBITED',
	'list',
	'N'
);

insert into val_property_value (
	property_name, property_type, valid_property_value
) values (
	'account_type', 'auto_acct_coll', 'person'
);

insert into val_property_value (
	property_name, property_type, valid_property_value
) values (
	'account_type', 'auto_acct_coll', 'pseudouser'
);

insert into val_property (
	property_name, property_type,
	permit_account_collection_id,
	permit_account_realm_id,
	permit_company_id,
	permit_site_code,
	property_data_type,
	is_multivalue
) values (
	'site', 'auto_acct_coll',
	'REQUIRED',
	'REQUIRED',
	'ALLOWED',
	'REQUIRED',
	'none',
	'N'
);


create or replace function _v60_add_person_company_ac(
	acname text, 
	propname text DEFAULT NULL,
	val text DEFAULT NULL
)
RETURNS void
AS
$$
BEGIN
	IF propname IS NULL THEN
		propname := acname;
	END IF;
	WITH acmap AS (
		select account_realm_id, company_id,
		array_to_string(ARRAY[account_realm_name, company_short_name,
			acname], '_') as company_ac
		from account_realm, company
	), ac AS (
		select	*
		from	account_collection ac
			join acmap on ac.account_collection_name = company_ac
		where	account_collection_type = 'automated'
	) insert into property (property_name, property_type, 
		account_realm_id, company_id,
		account_collection_id, property_value
	) select propname, 'auto_acct_coll', 
		account_realm_id, company_id,
		account_collection_id, val
	from ac;
END;
$$ LANGUAGE plpgsql;

create or replace function _v60_add_account_realm_ac(
	acname text, 
	propname text DEFAULT NULL,
	val text DEFAULT NULL
)
RETURNS void
AS
$$
BEGIN
	IF propname IS NULL THEN
		propname := acname;
	END IF;
	WITH acmap AS (
		select account_realm_id,
		array_to_string(ARRAY[account_realm_name, acname], '_') 
			as company_ac
		from account_realm
	), ac AS (
		select	*
		from	account_collection ac
			join acmap on ac.account_collection_name = company_ac
		where	account_collection_type = 'automated'
	) insert into property (property_name, property_type, 
		account_realm_id,
		account_collection_id, property_value
	) select propname, 'auto_acct_coll', 
		account_realm_id,
		account_collection_id, val
	from ac;
END;
$$ LANGUAGE plpgsql;

create or replace function _v60_add_sitecode_ac(
	propname text DEFAULT NULL,
	val text DEFAULT NULL
)
RETURNS void
AS
$$
BEGIN
	WITH acmap AS (
		select account_realm_id, site_code,
		array_to_string(ARRAY[account_realm_name, site_code], '_') 
			as company_ac
		from account_realm, site
	), ac AS (
		select	*
		from	account_collection ac
			join acmap on ac.account_collection_name = company_ac
		where	account_collection_type = 'automated'
	) insert into property (property_name, property_type, 
		account_realm_id, site_code,
		account_collection_id, property_value
	) select propname, 'auto_acct_coll', 
		account_realm_id, site_code,
		account_collection_id, val
	from ac;
END;
$$ LANGUAGE plpgsql;

select _v60_add_person_company_ac('exempt');
select _v60_add_person_company_ac('non_exempt');
select _v60_add_person_company_ac('male');
select _v60_add_person_company_ac('female');
select _v60_add_person_company_ac('unspecified_gender');
select _v60_add_person_company_ac('management');
select _v60_add_person_company_ac('non_management');
select _v60_add_person_company_ac('full_time');
select _v60_add_person_company_ac('non_full_time');

select _v60_add_person_company_ac('person', 'account_type', 'person');
select _v60_add_person_company_ac('pseudouser', 'account_type', 'pseudouser');

select _v60_add_account_realm_ac('person', 'account_type', 'person');
select _v60_add_account_realm_ac('pseudouser', 'account_type', 'pseudouser');

select _v60_add_sitecode_ac('site');

drop function IF EXISTS _v60_add_person_company_ac(text, text, text);
drop function IF EXISTS _v60_add_account_realm_ac(text, text, text);
drop function IF EXISTS _v60_add_sitecode_ac(text, text);

delete from account_collection_account where account_collection_id in (
	select account_collection_id from account_collection
	where account_collection_type = 'usertype'
);

delete from account_collection_hier where account_collection_id in (
	select account_collection_id from account_collection
	where account_collection_type = 'usertype'
);

delete from account_collection_hier where child_account_collection_id in (
	select account_collection_id from account_collection
	where account_collection_type = 'usertype'
);

delete from account_collection where 
	account_collection_type = 'usertype';

delete from val_account_collection_type where 
	account_collection_type IN ('usertype', 'company');

--------------------------------------------------------------------
-- DONE redo account automated triggers
--------------------------------------------------------------------

--------------------------------------------------------------------
-- BEGIN dns_record_cname_checker search path
--------------------------------------------------------------------
alter function dns_record_cname_checker() set search_path=jazzhands;
--------------------------------------------------------------------
-- END dns_record_cname_checker search path
--------------------------------------------------------------------

DROP TRIGGER IF EXISTS trig_add_automated_ac_on_account ON account;
DROP TRIGGER IF EXISTS trig_rm_automated_ac_on_account ON account;
DROP TRIGGER IF EXISTS trig_automated_realm_site_ac_pl ON person_location;
DROP TRIGGER IF EXISTS trigger_automated_ac_on_person ON person;
DROP TRIGGER IF EXISTS trigger_automated_ac_on_person_company ON person_company;

CREATE TRIGGER trig_add_automated_ac_on_account AFTER INSERT OR UPDATE OF account_type, account_role ON account FOR EACH ROW EXECUTE PROCEDURE automated_ac_on_account();
CREATE TRIGGER trig_rm_automated_ac_on_account BEFORE DELETE ON account FOR EACH ROW EXECUTE PROCEDURE automated_ac_on_account();
CREATE TRIGGER trig_automated_realm_site_ac_pl AFTER INSERT OR DELETE OR UPDATE OF site_code, person_id ON person_location FOR EACH ROW EXECUTE PROCEDURE automated_realm_site_ac_pl();
CREATE TRIGGER trigger_automated_ac_on_person AFTER UPDATE OF gender ON person FOR EACH ROW EXECUTE PROCEDURE automated_ac_on_person();
CREATE TRIGGER trigger_automated_ac_on_person_company AFTER UPDATE OF is_management, is_exempt, is_full_time ON person_company FOR EACH ROW EXECUTE PROCEDURE automated_ac_on_person_company();


-- Processing tables with no structural changes
-- Some of these may be redundant
ALTER TABLE rack_location 
	DROP CONSTRAINT IF EXISTS ak_uq_rack_offset_sid_location;
ALTER TABLE ONLY rack_location
	ADD CONSTRAINT ak_uq_rack_offset_sid_location 
	UNIQUE (rack_id, rack_u_offset_of_device_top, rack_side);

-- fk constraints
-- triggers

-- Function arguments changed, so adjust the regrant
UPDATE __regrants SET regrant=
	regexp_replace(regrant, 'calculate_intermediate_netblocks\([^\)]+\)',
		'calculate_intermediate_netblocks(ip_block_1 inet, ip_block_2 inet, netblock_type text, ip_universe_id integer)');
	
-- random comments
COMMENT ON SCHEMA audit IS 'part of jazzhands project';
COMMENT ON SCHEMA jazzhands IS 'http://sourceforge.net/projects/jazzhands/';
COMMENT ON SCHEMA device_utils IS 'part of jazzhands';
COMMENT ON SCHEMA net_manip IS 'part of jazzhands';
COMMENT ON SCHEMA netblock_utils IS 'part of jazzhands';
COMMENT ON SCHEMA network_strings IS 'part of jazzhands';
COMMENT ON SCHEMA person_manip IS 'part of jazzhands';
COMMENT ON SCHEMA port_support IS 'part of jazzhands';
COMMENT ON SCHEMA port_utils IS 'part of jazzhands';
COMMENT ON SCHEMA schema_support IS 'part of jazzhands';
COMMENT ON SCHEMA time_util IS 'part of jazzhands';
COMMENT ON SCHEMA physical_address_utils IS 'part of jazzhands';


-- Clean Up
SELECT schema_support.replay_object_recreates();
SELECT schema_support.replay_saved_grants();
GRANT select on all tables in schema jazzhands to ro_role;
GRANT insert,update,delete on all tables in schema jazzhands to iud_role;
GRANT select on all sequences in schema jazzhands to ro_role;
GRANT usage on all sequences in schema jazzhands to iud_role;

select now();
-- SELECT schema_support.end_maintenance();
