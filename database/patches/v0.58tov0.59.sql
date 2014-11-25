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

\set ON_ERROR_STOP
SELECT schema_support.begin_maintenance();

DO $$
	-- deal with _root_account_realm_id 
	DECLARE x INTEGER;
	BEGIN
		SELECT account_realm_id
		INTO x
		FROM property
		WHERE property_name = '_root_account_realm_id'
		AND property_type  = 'Defaults';

		IF x IS NOT NULL THEN
			INSERT INTO property (
        			property_name, property_type,
	        		account_realm_id
			) VALUES  (
		        	'_root_account_realm_id', 'Defaults',
			        (select account_realm_id
				        from account_realm_company
						where company_id IN (
							select  property_value_company_id
						    from  property
							where  property_name = '_rootcompanyid'
							and  property_type = 'Defaults'
						)
					)
			);
			-- not making _rootcompanyid go away, but should
		END IF;
	END;
$$;

/*
 * populate network_interface_netblock before putting triggers in 
 */

insert into network_interface_netblock
	(network_interface_id, netblock_id)
select network_interface_id, netblock_id
from network_interface where
	(network_interface_id, netblock_id) NOT IN
		(SELECT network_interface_id, netblock_id 
		from network_interface_netblock
		)
and netblock_id is not NULL
;

-- SELECT schema_support.end_maintenance();
/*
Invoked:

	--suffix=v58
	service_environment
	netblock_single_address_ni
	network_interface_netblock_to_ni
	network_interface_drop_tt
	netblock
	svc_environment_coll_svc_env
	network_interface_netblock
	device
	property
	property_collection
	property_collection_hier
	property_collection_property
	val_property_collection_type
	val_property
	sw_package
	sw_package_release
	network_service
	appaal_instance
*/

CREATE SEQUENCE service_environment_service_environment_id_seq;
CREATE SEQUENCE property_collection_property_collection_id_seq;


--------------------------------------------------------------------
-- DEALING WITH TABLE service_environment [280382]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'service_environment', 'service_environment');

-- FOREIGN KEYS FROM
ALTER TABLE network_service DROP CONSTRAINT IF EXISTS fk_netsvc_csvcenv;
ALTER TABLE appaal_instance DROP CONSTRAINT IF EXISTS fk_appaal_i_fk_applic_svcenv;
ALTER TABLE sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_pkg_rel_ref_vsvcenv;
ALTER TABLE voe DROP CONSTRAINT IF EXISTS fk_voe_ref_v_svcenv;
ALTER TABLE svc_environment_coll_svc_env DROP CONSTRAINT IF EXISTS fk_svc_env_col_svc_env;
ALTER TABLE device DROP CONSTRAINT IF EXISTS fk_device_fk_dev_v_svcenv;
ALTER TABLE sw_package DROP CONSTRAINT IF EXISTS fk_sw_pkg_ref_v_prod_state;


-- FOREIGN KEYS TO
ALTER TABLE jazzhands.service_environment DROP CONSTRAINT IF EXISTS fk_val_svcenv_prodstate;
ALTER TABLE jazzhands.service_environment DROP CONSTRAINT IF EXISTS pk_service_environment;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif1service_environment";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_update_per_svc_env_svc_env_collection ON jazzhands.service_environment;
DROP TRIGGER IF EXISTS trigger_audit_service_environment ON jazzhands.service_environment;
DROP TRIGGER IF EXISTS trig_userlog_service_environment ON jazzhands.service_environment;
DROP TRIGGER IF EXISTS trigger_delete_per_svc_env_svc_env_collection ON jazzhands.service_environment;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'service_environment');
---- BEGIN audit.service_environment TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."service_environment_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'service_environment');
---- DONE audit.service_environment TEARDOWN


ALTER TABLE service_environment RENAME TO service_environment_v58;
ALTER TABLE audit.service_environment RENAME TO service_environment_v58;

CREATE TABLE service_environment
(
	service_environment_id	integer NOT NULL,
	service_environment_name	varchar(50) NOT NULL,
	production_state	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'service_environment', false);
ALTER TABLE service_environment
	ALTER service_environment_id
	SET DEFAULT nextval('service_environment_service_environment_id_seq'::regclass);

INSERT INTO service_environment (
	service_environment_id,		-- new column (service_environment_id)
	service_environment_name,		-- new column (service_environment_name)
	production_state,
	description,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	nextval('service_environment_service_environment_id_seq'::regclass),		-- new column (service_environment_id)
	service_environment,		-- new column (service_environment_name)
	production_state,
	description,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM service_environment_v58;

INSERT INTO audit.service_environment (
	service_environment_id,		-- new column (service_environment_id)
	service_environment_name,		-- new column (service_environment_name)
	production_state,
	description,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	b.service_environment_id,		-- new column (service_environment_id)
	a.service_environment,		-- new column (service_environment_name)
	a.production_state,
	a.description,
	a.data_ins_user,
	a.data_ins_date,
	a.data_upd_user,
	a.data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.service_environment_v58 a
	left join service_environment b on
		a.service_environment = b.service_environment_name;

ALTER TABLE service_environment
	ALTER service_environment_id
	SET DEFAULT nextval('service_environment_service_environment_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE service_environment ADD CONSTRAINT pk_service_environment PRIMARY KEY (service_environment_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif1service_environment ON service_environment USING btree (production_state);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK service_environment and device
-- gets created later
-- ALTER TABLE device
--	ADD CONSTRAINT fk_device_fk_dev_v_svcenv
--	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);

-- consider FK service_environment and sw_package
-- created later
--ALTER TABLE sw_package
--	ADD CONSTRAINT fk_sw_pkg_ref_v_prod_state
--	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);

-- consider FK service_environment and svc_environment_coll_svc_env
-- created later
--ALTER TABLE svc_environment_coll_svc_env
--	ADD CONSTRAINT fk_svc_env_col_svc_env
--	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);

-- consider FK service_environment and voe
-- ALTER TABLE voe
-- 	ADD CONSTRAINT fk_voe_ref_v_svcenv
-- 	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);

-- consider FK service_environment and sw_package_release
-- ALTER TABLE sw_package_release
-- 	ADD CONSTRAINT fk_sw_pkg_rel_ref_vsvcenv
-- 	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);

-- consider FK service_environment and network_service
-- ALTER TABLE network_service
-- 	ADD CONSTRAINT fk_netsvc_csvcenv
-- 	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);

-- consider FK service_environment and appaal_instance
-- ALTER TABLE appaal_instance
-- 	ADD CONSTRAINT fk_appaal_i_fk_applic_svcenv
-- 	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);

-- FOREIGN KEYS TO
-- consider FK service_environment and val_production_state
ALTER TABLE service_environment
	ADD CONSTRAINT fk_val_svcenv_prodstate
	FOREIGN KEY (production_state) REFERENCES val_production_state(production_state);


-- TRIGGERS
CREATE TRIGGER trigger_delete_per_svc_env_svc_env_collection BEFORE DELETE ON service_environment FOR EACH ROW EXECUTE PROCEDURE delete_per_svc_env_svc_env_collection();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_update_per_svc_env_svc_env_collection AFTER INSERT OR UPDATE ON service_environment FOR EACH ROW EXECUTE PROCEDURE update_per_svc_env_svc_env_collection();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'service_environment');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'service_environment');
ALTER SEQUENCE service_environment_service_environment_id_seq
	 OWNED BY service_environment.service_environment_id;
DROP TABLE IF EXISTS service_environment_v58;
DROP TABLE IF EXISTS audit.service_environment_v58;
-- DONE DEALING WITH TABLE service_environment [369659]
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH TABLE network_interface_netblock [280022]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'network_interface_netblock', 'network_interface_netblock');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.network_interface_netblock DROP CONSTRAINT IF EXISTS fk_netint_nb_netint_id;
ALTER TABLE jazzhands.network_interface_netblock DROP CONSTRAINT IF EXISTS fk_netint_nb_nblk_id;
ALTER TABLE jazzhands.network_interface_netblock DROP CONSTRAINT IF EXISTS pk_network_interface_netblock;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_netint_nb_netint_id";
DROP INDEX IF EXISTS "jazzhands"."xif_netint_nb_nblk_id";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_network_interface_netblock ON jazzhands.network_interface_netblock;
DROP TRIGGER IF EXISTS trigger_audit_network_interface_netblock ON jazzhands.network_interface_netblock;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'network_interface_netblock');
---- BEGIN audit.network_interface_netblock TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."network_interface_netblock_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'network_interface_netblock');
---- DONE audit.network_interface_netblock TEARDOWN


ALTER TABLE network_interface_netblock RENAME TO network_interface_netblock_v58;
ALTER TABLE audit.network_interface_netblock RENAME TO network_interface_netblock_v58;

CREATE TABLE network_interface_netblock
(
	network_interface_id	integer NOT NULL,
	netblock_id	integer NOT NULL,
	network_interface_rank	integer NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'network_interface_netblock', false);
ALTER TABLE network_interface_netblock
	ALTER network_interface_rank
	SET DEFAULT 0;
INSERT INTO network_interface_netblock (
	network_interface_id,
	netblock_id,
	network_interface_rank,		-- new column (network_interface_rank)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	network_interface_id,
	netblock_id,
	0,		-- new column (network_interface_rank)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM network_interface_netblock_v58;

INSERT INTO audit.network_interface_netblock (
	network_interface_id,
	netblock_id,
	network_interface_rank,		-- new column (network_interface_rank)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	network_interface_id,
	netblock_id,
	NULL,		-- new column (network_interface_rank)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.network_interface_netblock_v58;

ALTER TABLE network_interface_netblock
	ALTER network_interface_rank
	SET DEFAULT 0;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE network_interface_netblock ADD CONSTRAINT pk_network_interface_netblock PRIMARY KEY (network_interface_id, netblock_id);
ALTER TABLE network_interface_netblock ADD CONSTRAINT ak_netint_nblk_nblk_id UNIQUE (netblock_id);
ALTER TABLE network_interface_netblock ADD CONSTRAINT ak_network_interface_nblk_ni_r UNIQUE (network_interface_id, network_interface_rank);

-- Table/Column Comments
COMMENT ON COLUMN network_interface_netblock.network_interface_rank IS 'specifies the order of priority for the ip address.  generally only the highest priority matters (or highest priority v4 and v6) and is the "primary" if the underlying device supports it.';
-- INDEXES
CREATE INDEX xif_netint_nb_nblk_id ON network_interface_netblock USING btree (network_interface_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK network_interface_netblock and netblock
ALTER TABLE network_interface_netblock
	ADD CONSTRAINT fk_netint_nb_netint_id
	FOREIGN KEY (netblock_id) REFERENCES netblock(netblock_id) DEFERRABLE;
-- consider FK network_interface_netblock and network_interface
-- Skipping this FK since table does not exist yet
--ALTER TABLE network_interface_netblock
--	ADD CONSTRAINT fk_netint_nb_nblk_id
--	FOREIGN KEY (network_interface_id) REFERENCES network_interface(network_interface_id) DEFERRABLE;


-- TRIGGERS

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'network_interface_netblock');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'network_interface_netblock');
DROP TABLE IF EXISTS network_interface_netblock_v58;
DROP TABLE IF EXISTS audit.network_interface_netblock_v58;
-- DONE DEALING WITH TABLE network_interface_netblock [369256]
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc network_interface_drop_tt -> network_interface_drop_tt 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 375726
CREATE OR REPLACE FUNCTION jazzhands.network_interface_drop_tt()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_tally INTEGER;
BEGIN
	SELECT  count(*)
	  INTO  _tally
	  FROM  pg_catalog.pg_class
	 WHERE  relname = '__network_interface_netblocks'
	   AND  relpersistence = 't';

	IF _tally > 0 THEN
		DROP TABLE IF EXISTS __network_interface_netblocks;
	END IF;

	SET CONSTRAINTS FK_NETINT_NB_NETINT_ID IMMEDIATE;
	SET CONSTRAINTS FK_NETINT_NB_NBLK_ID IMMEDIATE;

	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	ELSE
		RETURN NEW;
	END IF;
END;
$function$
;

-- Dropping obsoleted sequences....


-- Dropping obsoleted audit sequences....


-- Processing tables with no structural changes
-- Some of these may be redundant
-- fk constraints
-- triggers


-- XXX - may need to include trigger function
CREATE TRIGGER trigger_network_interface_drop_tt_netint_nb AFTER INSERT OR DELETE OR UPDATE ON network_interface_netblock FOR EACH STATEMENT EXECUTE PROCEDURE network_interface_drop_tt();

-- DONE WITH proc network_interface_drop_tt -> network_interface_drop_tt 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH proc network_interface_netblock_to_ni -> network_interface_netblock_to_ni 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 375724
CREATE OR REPLACE FUNCTION jazzhands.network_interface_netblock_to_ni()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_r		network_interface_netblock%ROWTYPE;
	_rank	network_interface_netblock.network_interface_rank%TYPE;
	_tally	INTEGER;
BEGIN
	SELECT  count(*)
	  INTO  _tally
	  FROM  pg_catalog.pg_class
	 WHERE  relname = '__network_interface_netblocks'
	   AND  relpersistence = 't';

	IF _tally = 0 THEN
		CREATE TEMPORARY TABLE IF NOT EXISTS __network_interface_netblocks (
			network_interface_id INTEGER, netblock_id INTEGER
		);
	END IF;
	IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
		SELECT count(*) INTO _tally FROM __network_interface_netblocks
		WHERE network_interface_id = NEW.network_interface_id
		AND netblock_id = NEW.netblock_id;
		if _tally >  0 THEN
			RETURN NEW;
		END IF;
		INSERT INTO __network_interface_netblocks
			(network_interface_id, netblock_id)
		VALUES (NEW.network_interface_id,NEW.netblock_id);
	ELSIF TG_OP = 'DELETE' THEN
		SELECT count(*) INTO _tally FROM __network_interface_netblocks
		WHERE network_interface_id = OLD.network_interface_id
		AND netblock_id = OLD.netblock_id;
		if _tally >  0 THEN
			RETURN OLD;
		END IF;
		INSERT INTO __network_interface_netblocks
			(network_interface_id, netblock_id)
		VALUES (OLD.network_interface_id,OLD.netblock_id);
	END IF;

	IF TG_OP = 'INSERT' THEN
		SELECT min(network_interface_rank), count(*)
		INTO _rank, _tally
		FROM network_interface_netblock
		WHERE network_interface_id = NEW.network_interface_id;

		IF _tally = 0 OR NEW.network_interface_rank <= _rank THEN
			UPDATE network_interface set netblock_id = NEW.netblock_id
			WHERE network_interface_id = NEW.network_interface_id
			AND netblock_id IS DISTINCT FROM (NEW.netblock_id)
			;
		END IF;
	ELSIF TG_OP = 'DELETE'  THEN
		-- if we started to disallow NULLs, just ignore this for now
		BEGIN
			UPDATE network_interface
				SET netblock_id = NULL
				WHERE network_interface_id = OLD.network_interface_id
				AND netblock_id = OLD.netblock_id;
		EXCEPTION WHEN null_value_not_allowed THEN
			RAISE DEBUG 'null_value_not_allowed';
		END;
		RETURN OLD;
	ELSIF TG_OP = 'UPDATE'  THEN
		SELECT min(network_interface_rank)
			INTO _rank
			FROM network_interface_netblock
			WHERE network_interface_id = NEW.network_interface_id;

		IF NEW.network_interface_rank <= _rank THEN
			UPDATE network_interface
				SET network_interface_id = NEW.network_interface_id,
					netblock_id = NEW.netblock_id
				WHERE network_interface_Id = OLD.network_interface_id
				AND netblock_id IS NOT DISTINCT FROM ( OLD.netblock_id );
		END IF;
	END IF;
	RETURN NEW;
END;
$function$
;

CREATE TRIGGER trigger_network_interface_netblock_to_ni AFTER INSERT OR DELETE OR UPDATE ON network_interface_netblock FOR EACH ROW EXECUTE PROCEDURE network_interface_netblock_to_ni();

-- DONE WITH proc network_interface_netblock_to_ni -> network_interface_netblock_to_ni 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH proc netblock_single_address_ni -> netblock_single_address_ni 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 375684
CREATE OR REPLACE FUNCTION jazzhands.netblock_single_address_ni()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_tally	INTEGER;
BEGIN
	IF (NEW.is_single_address = 'N' AND OLD.is_single_address = 'Y') OR
		(NEW.netblock_type != 'default' AND OLD.netblock_type = 'default')
			THEN
		select count(*)
		INTO _tally
		FROM network_interface
		WHERE netblock_id = NEW.netblock_id;

		IF _tally > 0 THEN
			RAISE EXCEPTION 'network interfaces must refer to single ip addresses of type default address (%,%)', NEW.ip_address, NEW.netblock_id
				USING errcode = 'foreign_key_violation';
		END IF;
	END IF;
	RETURN NEW;
END;
$function$
;

-- DONE WITH proc netblock_single_address_ni -> netblock_single_address_ni 
--------------------------------------------------------------------

-- Dropping obsoleted sequences....


-- Dropping obsoleted audit sequences....


-- Processing tables with no structural changes
-- Some of these may be redundant
-- fk constraints
-- triggers


--------------------------------------------------------------------
-- DEALING WITH TABLE netblock [279932]

SELECT schema_support.save_grants_for_replay('jazzhands', 'v_netblock_hier');
drop view v_netblock_hier;

DROP TRIGGER IF EXISTS trigger_validate_netblock_parentage ON jazzhands.netblock;
DROP TRIGGER IF EXISTS zzzz_trigger_retire_netblock_columns ON jazzhands.netblock;
DROP TRIGGER IF EXISTS trigger_netblock_complain_on_mismatch ON jazzhands.netblock;
DROP TRIGGER IF EXISTS trig_userlog_netblock ON jazzhands.netblock;
DROP TRIGGER IF EXISTS trigger_audit_netblock ON jazzhands.netblock;
DROP TRIGGER IF EXISTS tb_a_validate_netblock ON jazzhands.netblock;
DROP TRIGGER IF EXISTS tb_manipulate_netblock_parentage ON jazzhands.netblock;
DROP TRIGGER IF EXISTS aaa_ta_manipulate_netblock_parentage ON jazzhands.netblock;

ALTER TABLE jazzhands.netblock DROP COLUMN IF EXISTS netmask_bits;
ALTER TABLE jazzhands.netblock DROP COLUMN IF EXISTS is_ipv4_address;

ALTER TABLE audit.netblock DROP COLUMN IF EXISTS netmask_bits;
ALTER TABLE audit.netblock DROP COLUMN IF EXISTS is_ipv4_address;

CREATE TRIGGER tb_manipulate_netblock_parentage BEFORE INSERT OR UPDATE OF ip_address, netblock_type, ip_universe_id ON netblock FOR EACH ROW EXECUTE PROCEDURE manipulate_netblock_parentage_before();
CREATE TRIGGER tb_a_validate_netblock BEFORE INSERT OR UPDATE ON netblock FOR EACH ROW EXECUTE PROCEDURE validate_netblock();
CREATE CONSTRAINT TRIGGER aaa_ta_manipulate_netblock_parentage AFTER INSERT OR DELETE ON netblock NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE manipulate_netblock_parentage_after();
CREATE TRIGGER trigger_netblock_single_address_ni BEFORE UPDATE OF is_single_address, netblock_type ON netblock FOR EACH ROW EXECUTE PROCEDURE netblock_single_address_ni();
CREATE CONSTRAINT TRIGGER trigger_validate_netblock_parentage AFTER INSERT OR UPDATE ON netblock DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE validate_netblock_parentage();


-- DONE DEALING WITH TABLE netblock [369167]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE svc_environment_coll_svc_env [280508]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'svc_environment_coll_svc_env', 'svc_environment_coll_svc_env');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.svc_environment_coll_svc_env DROP CONSTRAINT IF EXISTS fk_svc_env_col_svc_env;
ALTER TABLE jazzhands.svc_environment_coll_svc_env DROP CONSTRAINT IF EXISTS fk_svc_env_coll_svc_coll_id;
ALTER TABLE jazzhands.svc_environment_coll_svc_env DROP CONSTRAINT IF EXISTS pk_svc_environment_coll_svc_en;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif1svc_environment_coll_svc_e";
DROP INDEX IF EXISTS "jazzhands"."xif2svc_environment_coll_svc_e";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_service_environment_collection_member_enforce ON jazzhands.svc_environment_coll_svc_env;
DROP TRIGGER IF EXISTS trig_userlog_svc_environment_coll_svc_env ON jazzhands.svc_environment_coll_svc_env;
DROP TRIGGER IF EXISTS trigger_audit_svc_environment_coll_svc_env ON jazzhands.svc_environment_coll_svc_env;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'svc_environment_coll_svc_env');
---- BEGIN audit.svc_environment_coll_svc_env TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."svc_environment_coll_svc_env_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'svc_environment_coll_svc_env');
---- DONE audit.svc_environment_coll_svc_env TEARDOWN


ALTER TABLE svc_environment_coll_svc_env RENAME TO svc_environment_coll_svc_env_v58;
ALTER TABLE audit.svc_environment_coll_svc_env RENAME TO svc_environment_coll_svc_env_v58;

CREATE TABLE svc_environment_coll_svc_env
(
	service_env_collection_id	integer NOT NULL,
	service_environment_id	integer NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'svc_environment_coll_svc_env', false);
INSERT INTO svc_environment_coll_svc_env (
	service_env_collection_id,
	service_environment_id,		-- new column (service_environment_id)
	description,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	x.service_env_collection_id,
	b.service_environment_id,		-- new column (service_environment_id)
	x.description,
	x.data_ins_user,
	x.data_ins_date,
	x.data_upd_user,
	x.data_upd_date
FROM svc_environment_coll_svc_env_v58 x
	join service_environment b ON x.service_environment =
		b.service_environment_name;
	

INSERT INTO audit.svc_environment_coll_svc_env (
	service_env_collection_id,
	service_environment_id,		-- new column (service_environment_id)
	description,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	x.service_env_collection_id,
	b.service_environment_id,		-- new column (service_environment_id)
	x.description,
	x.data_ins_user,
	x.data_ins_date,
	x.data_upd_user,
	x.data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.svc_environment_coll_svc_env_v58 x
	join service_environment b ON x.service_environment =
		b.service_environment_name;


-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE svc_environment_coll_svc_env ADD CONSTRAINT pk_svc_environment_coll_svc_en PRIMARY KEY (service_env_collection_id, service_environment_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif1svc_environment_coll_svc_e ON svc_environment_coll_svc_env USING btree (service_environment_id);
CREATE INDEX xif2svc_environment_coll_svc_e ON svc_environment_coll_svc_env USING btree (service_env_collection_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK svc_environment_coll_svc_env and service_environment
ALTER TABLE svc_environment_coll_svc_env
	ADD CONSTRAINT fk_svc_env_col_svc_env
	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);
-- consider FK svc_environment_coll_svc_env and service_environment_collection
-- Skipping this FK since table does not exist yet
--ALTER TABLE svc_environment_coll_svc_env
--	ADD CONSTRAINT fk_svc_env_coll_svc_coll_id
--	FOREIGN KEY (service_env_collection_id) REFERENCES service_environment_collection(service_env_collection_id);


-- TRIGGERS
CREATE CONSTRAINT TRIGGER trigger_service_environment_collection_member_enforce AFTER INSERT OR UPDATE ON svc_environment_coll_svc_env DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE service_environment_collection_member_enforce();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'svc_environment_coll_svc_env');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'svc_environment_coll_svc_env');
DROP TABLE IF EXISTS svc_environment_coll_svc_env_v58;
DROP TABLE IF EXISTS audit.svc_environment_coll_svc_env_v58;
-- DONE DEALING WITH TABLE svc_environment_coll_svc_env [369786]
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH TABLE device [279424]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'device', 'device');

-- FOREIGN KEYS FROM
-- Skipping this FK since table been dropped
ALTER TABLE physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_dev_id;
ALTER TABLE device_layer2_network DROP CONSTRAINT IF EXISTS fk_device_l2_net_devid;
ALTER TABLE device_ticket DROP CONSTRAINT IF EXISTS fk_dev_tkt_dev_id;
ALTER TABLE network_interface_purpose DROP CONSTRAINT IF EXISTS fk_netint_purpose_device_id;
ALTER TABLE mlag_peering DROP CONSTRAINT IF EXISTS fk_mlag_peering_devid2;
ALTER TABLE device_management_controller DROP CONSTRAINT IF EXISTS fk_dev_mgmt_ctlr_dev_id;
ALTER TABLE network_service DROP CONSTRAINT IF EXISTS fk_netsvc_device_id;
ALTER TABLE chassis_location DROP CONSTRAINT IF EXISTS fk_chass_loc_chass_devid;
ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_l1conn_ref_device;
ALTER TABLE device_management_controller DROP CONSTRAINT IF EXISTS fk_dvc_mgmt_ctrl_mgr_dev_id;
ALTER TABLE device_collection_device DROP CONSTRAINT IF EXISTS fk_devcolldev_dev_id;
ALTER TABLE device_ssh_key DROP CONSTRAINT IF EXISTS fk_dev_ssh_key_ssh_key_id;
ALTER TABLE mlag_peering DROP CONSTRAINT IF EXISTS fk_mlag_peering_devid1;
ALTER TABLE network_interface DROP CONSTRAINT IF EXISTS fk_netint_device_id;
ALTER TABLE snmp_commstr DROP CONSTRAINT IF EXISTS fk_snmpstr_device_id;
ALTER TABLE device_note DROP CONSTRAINT IF EXISTS fk_device_note_device;
ALTER TABLE device_encapsulation_domain DROP CONSTRAINT IF EXISTS fk_dev_encap_domain_devid;
ALTER TABLE static_route DROP CONSTRAINT IF EXISTS fk_statrt_devsrc_id;
ALTER TABLE device_power_interface DROP CONSTRAINT IF EXISTS fk_device_device_power_supp;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_chasloc_chass_devid;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_fk_dev_v_svcenv;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_os_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_devtp_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_fk_voe;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_site_code;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_rack_location_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_fk_dev_val_stat;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_asset_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_vownerstatus;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_ref_voesymbtrk;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_chass_loc_id_mod_enfc;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_company__id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_dnsrecord;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_ref_parent_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_reference_val_devi;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ak_device_rack_location_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ak_device_chassis_location_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS pk_device;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_dev_ismonitored";
DROP INDEX IF EXISTS "jazzhands"."xif16device";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_iddnsrec";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_dev_status";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_voeid";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_islclymgd";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_ownershipstatus";
DROP INDEX IF EXISTS "jazzhands"."idx_device_type_location";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_osid";
DROP INDEX IF EXISTS "jazzhands"."xif18device";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_svcenv";
DROP INDEX IF EXISTS "jazzhands"."xifdevice_sitecode";
DROP INDEX IF EXISTS "jazzhands"."xif17device";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_monitored_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069052;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_virtual_device_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069059;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS dev_osid_notnull;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_should_fetch_conf_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069057;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069054;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_baselined_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069056;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069051;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069060;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069061;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_locally_manage_device;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_verify_device_voe ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_update_per_device_device_collection ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_audit_device ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_device_one_location_validate ON jazzhands.device;
DROP TRIGGER IF EXISTS trig_userlog_device ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_delete_per_device_device_collection ON jazzhands.device;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'device');
---- BEGIN audit.device TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."device_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'device');
---- DONE audit.device TEARDOWN


ALTER TABLE device RENAME TO device_v58;
ALTER TABLE audit.device RENAME TO device_v58;

CREATE TABLE device
(
	device_id	integer NOT NULL,
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
	service_environment_id,	-- new column (service_environment_id)
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
	d.device_id,
	d.device_type_id,
	d.company_id,
	d.asset_id,
	d.device_name,
	d.site_code,
	d.identifying_dns_record_id,
	d.host_id,
	d.physical_label,
	d.rack_location_id,
	d.chassis_location_id,
	d.parent_device_id,
	d.description,
	d.device_status,
	d.operating_system_id,
	se.service_environment_id,	-- new column (service_environment_id)
	d.voe_id,
	d.auto_mgmt_protocol,
	d.voe_symbolic_track_id,
	d.is_locally_managed,
	d.is_monitored,
	d.is_virtual_device,
	d.should_fetch_config,
	d.date_in_service,
	d.data_ins_user,
	d.data_ins_date,
	d.data_upd_user,
	d.data_upd_date
FROM device_v58 d
	join service_environment se on
		d.service_environment = se.service_environment_name;

INSERT INTO audit.device (
	device_id,
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
	service_environment_id,		-- new column (service_environment_id)
	operating_system_id,
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
	d.device_id,
	d.device_type_id,
	d.company_id,
	d.asset_id,
	d.device_name,
	d.site_code,
	d.identifying_dns_record_id,
	d.host_id,
	d.physical_label,
	d.rack_location_id,
	d.chassis_location_id,
	d.parent_device_id,
	d.description,
	d.device_status,
	se.service_environment_id,	-- new column (service_environment_id)
	d.operating_system_id,
	d.voe_id,
	d.auto_mgmt_protocol,
	d.voe_symbolic_track_id,
	d.is_locally_managed,
	d.is_monitored,
	d.is_virtual_device,
	d.should_fetch_config,
	d.date_in_service,
	d.data_ins_user,
	d.data_ins_date,
	d.data_upd_user,
	d.data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.device_v58 d
	join service_environment se on
		d.service_environment = se.service_environment_name;

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
ALTER TABLE device ADD CONSTRAINT ak_device_chassis_location_id UNIQUE (chassis_location_id);
ALTER TABLE device ADD CONSTRAINT ak_device_rack_location_id UNIQUE (rack_location_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xifdevice_sitecode ON device USING btree (site_code);
CREATE INDEX xif17device ON device USING btree (company_id);
CREATE INDEX xif18device ON device USING btree (asset_id);
CREATE INDEX idx_dev_svcenv ON device USING btree (service_environment_id);
CREATE INDEX idx_device_type_location ON device USING btree (device_type_id);
CREATE INDEX idx_dev_osid ON device USING btree (operating_system_id);
CREATE INDEX idx_dev_voeid ON device USING btree (voe_id);
CREATE INDEX idx_dev_dev_status ON device USING btree (device_status);
CREATE INDEX idx_dev_islclymgd ON device USING btree (is_locally_managed);
CREATE INDEX idx_dev_ismonitored ON device USING btree (is_monitored);
CREATE INDEX xif16device ON device USING btree (chassis_location_id, parent_device_id, device_type_id);
CREATE INDEX idx_dev_iddnsrec ON device USING btree (identifying_dns_record_id);

-- CHECK CONSTRAINTS
ALTER TABLE device ADD CONSTRAINT ckc_is_locally_manage_device
	CHECK ((is_locally_managed = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_locally_managed)::text = upper((is_locally_managed)::text)));
ALTER TABLE device ADD CONSTRAINT sys_c0069051
	CHECK (device_id IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT sys_c0069060
	CHECK (should_fetch_config IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT dev_osid_notnull
	CHECK (operating_system_id IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT ckc_should_fetch_conf_device
	CHECK ((should_fetch_config = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((should_fetch_config)::text = upper((should_fetch_config)::text)));
ALTER TABLE device ADD CONSTRAINT sys_c0069057
	CHECK (is_monitored IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT sys_c0069052
	CHECK (device_type_id IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT ckc_is_monitored_device
	CHECK ((is_monitored = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_monitored)::text = upper((is_monitored)::text)));
ALTER TABLE device ADD CONSTRAINT ckc_is_virtual_device_device
	CHECK ((is_virtual_device = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_virtual_device)::text = upper((is_virtual_device)::text)));
ALTER TABLE device ADD CONSTRAINT sys_c0069059
	CHECK (is_virtual_device IS NOT NULL);

-- FOREIGN KEYS FROM
-- consider FK device and device_layer2_network
ALTER TABLE device_layer2_network
	ADD CONSTRAINT fk_device_l2_net_devid
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and physical_port
ALTER TABLE physical_port
	ADD CONSTRAINT fk_phys_port_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and mlag_peering
ALTER TABLE mlag_peering
	ADD CONSTRAINT fk_mlag_peering_devid2
	FOREIGN KEY (device2_id) REFERENCES device(device_id);

-- consider FK device and device_ticket
ALTER TABLE device_ticket
	ADD CONSTRAINT fk_dev_tkt_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and network_interface_purpose
ALTER TABLE network_interface_purpose
	ADD CONSTRAINT fk_netint_purpose_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and chassis_location
ALTER TABLE chassis_location
	ADD CONSTRAINT fk_chass_loc_chass_devid
	FOREIGN KEY (chassis_device_id) REFERENCES device(device_id) DEFERRABLE;

-- consider FK device and network_service
ALTER TABLE network_service
	ADD CONSTRAINT fk_netsvc_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and device_management_controller
ALTER TABLE device_management_controller
	ADD CONSTRAINT fk_dev_mgmt_ctlr_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and layer1_connection
ALTER TABLE layer1_connection
	ADD CONSTRAINT fk_l1conn_ref_device
	FOREIGN KEY (tcpsrv_device_id) REFERENCES device(device_id);

-- consider FK device and device_management_controller
ALTER TABLE device_management_controller
	ADD CONSTRAINT fk_dvc_mgmt_ctrl_mgr_dev_id
	FOREIGN KEY (manager_device_id) REFERENCES device(device_id);

-- consider FK device and device_collection_device
ALTER TABLE device_collection_device
	ADD CONSTRAINT fk_devcolldev_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and device_ssh_key
ALTER TABLE device_ssh_key
	ADD CONSTRAINT fk_dev_ssh_key_ssh_key_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and mlag_peering
ALTER TABLE mlag_peering
	ADD CONSTRAINT fk_mlag_peering_devid1
	FOREIGN KEY (device1_id) REFERENCES device(device_id);

-- consider FK device and snmp_commstr
ALTER TABLE snmp_commstr
	ADD CONSTRAINT fk_snmpstr_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and network_interface
ALTER TABLE network_interface
	ADD CONSTRAINT fk_netint_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and static_route
ALTER TABLE static_route
	ADD CONSTRAINT fk_statrt_devsrc_id
	FOREIGN KEY (device_src_id) REFERENCES device(device_id);

-- consider FK device and device_power_interface
ALTER TABLE device_power_interface
	ADD CONSTRAINT fk_device_device_power_supp
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and device_note
ALTER TABLE device_note
	ADD CONSTRAINT fk_device_note_device
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- consider FK device and device_encapsulation_domain
ALTER TABLE device_encapsulation_domain
	ADD CONSTRAINT fk_dev_encap_domain_devid
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- FOREIGN KEYS TO
-- consider FK device and asset
ALTER TABLE device
	ADD CONSTRAINT fk_device_asset_id
	FOREIGN KEY (asset_id) REFERENCES asset(asset_id);

-- consider FK device and chassis_location
ALTER TABLE device
	ADD CONSTRAINT fk_chasloc_chass_devid
	FOREIGN KEY (chassis_location_id) REFERENCES chassis_location(chassis_location_id) DEFERRABLE;

-- consider FK device and service_environment
ALTER TABLE device
	ADD CONSTRAINT fk_device_fk_dev_v_svcenv
	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);

-- consider FK device and operating_system
ALTER TABLE device
	ADD CONSTRAINT fk_dev_os_id
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);

-- consider FK device and voe_symbolic_track
ALTER TABLE device
	ADD CONSTRAINT fk_device_ref_voesymbtrk
	FOREIGN KEY (voe_symbolic_track_id) REFERENCES voe_symbolic_track(voe_symbolic_track_id);

-- consider FK device and device_type
ALTER TABLE device
	ADD CONSTRAINT fk_dev_devtp_id
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);

-- consider FK device and voe
ALTER TABLE device
	ADD CONSTRAINT fk_device_fk_voe
	FOREIGN KEY (voe_id) REFERENCES voe(voe_id);

-- consider FK device and chassis_location
ALTER TABLE device
	ADD CONSTRAINT fk_dev_chass_loc_id_mod_enfc
	FOREIGN KEY (chassis_location_id, parent_device_id, device_type_id) REFERENCES chassis_location(chassis_location_id, chassis_device_id, module_device_type_id) DEFERRABLE;

-- consider FK device and company
ALTER TABLE device
	ADD CONSTRAINT fk_device_company__id
	FOREIGN KEY (company_id) REFERENCES company(company_id);

-- consider FK device and site
ALTER TABLE device
	ADD CONSTRAINT fk_device_site_code
	FOREIGN KEY (site_code) REFERENCES site(site_code);

-- consider FK device and dns_record
ALTER TABLE device
	ADD CONSTRAINT fk_device_dnsrecord
	FOREIGN KEY (identifying_dns_record_id) REFERENCES dns_record(dns_record_id);

-- consider FK device and device
ALTER TABLE device
	ADD CONSTRAINT fk_device_ref_parent_device
	FOREIGN KEY (parent_device_id) REFERENCES device(device_id);
-- consider FK device and val_device_auto_mgmt_protocol
ALTER TABLE device
	ADD CONSTRAINT fk_device_reference_val_devi
	FOREIGN KEY (auto_mgmt_protocol) REFERENCES val_device_auto_mgmt_protocol(auto_mgmt_protocol);

-- consider FK device and rack_location
ALTER TABLE device
	ADD CONSTRAINT fk_dev_rack_location_id
	FOREIGN KEY (rack_location_id) REFERENCES rack_location(rack_location_id);

-- consider FK device and val_device_status
ALTER TABLE device
	ADD CONSTRAINT fk_device_fk_dev_val_stat
	FOREIGN KEY (device_status) REFERENCES val_device_status(device_status);


-- TRIGGERS
CREATE TRIGGER trigger_delete_per_device_device_collection BEFORE DELETE ON device FOR EACH ROW EXECUTE PROCEDURE delete_per_device_device_collection();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_verify_device_voe BEFORE INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE verify_device_voe();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_update_per_device_device_collection AFTER INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE update_per_device_device_collection();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_device_one_location_validate BEFORE INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE device_one_location_validate();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'device');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'device');
ALTER SEQUENCE device_device_id_seq
	 OWNED BY device.device_id;
DROP TABLE IF EXISTS device_v58;
DROP TABLE IF EXISTS audit.device_v58;
-- DONE DEALING WITH TABLE device [368665]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE property [280306]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'property', 'property');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_osid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_compid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_person_id;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_acctid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_nblk_coll_id;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_acct_colid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_prop_l3netid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_acct_col;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_site_code;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_val_prsnid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_nmtyp;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_prop_svc_env_coll_id;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_compid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_prop_l2netid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_pwdtyp;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_dnsdomid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_swpkgid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_devcolid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_tokcolid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_dnsdomid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_acctrealmid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pv_nblkcol_id;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS pk_property;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_compid";
DROP INDEX IF EXISTS "jazzhands"."xif24property";
DROP INDEX IF EXISTS "jazzhands"."xif17property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_acctcol_id";
DROP INDEX IF EXISTS "jazzhands"."xif19property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_site_code";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_swpkgid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_dnsdomid";
DROP INDEX IF EXISTS "jazzhands"."xif18property";
DROP INDEX IF EXISTS "jazzhands"."xif22property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_account_id";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_pwdtyp";
DROP INDEX IF EXISTS "jazzhands"."xifprop_nmtyp";
DROP INDEX IF EXISTS "jazzhands"."xif23property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_dnsdomid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_devcolid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_acct_colid";
DROP INDEX IF EXISTS "jazzhands"."xif21property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_compid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_tokcolid";
DROP INDEX IF EXISTS "jazzhands"."xif20property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_osid";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS ckc_prop_isenbld;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_validate_property ON jazzhands.property;
DROP TRIGGER IF EXISTS trigger_audit_property ON jazzhands.property;
DROP TRIGGER IF EXISTS trig_userlog_property ON jazzhands.property;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'property');
---- BEGIN audit.property TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."property_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'property');
---- DONE audit.property TEARDOWN


ALTER TABLE property RENAME TO property_v58;
ALTER TABLE audit.property RENAME TO property_v58;

CREATE TABLE property
(
	property_id	integer NOT NULL,
	account_collection_id	integer  NULL,
	account_id	integer  NULL,
	account_realm_id	integer  NULL,
	company_id	integer  NULL,
	device_collection_id	integer  NULL,
	dns_domain_id	integer  NULL,
	netblock_collection_id	integer  NULL,
	layer2_network_id	integer  NULL,
	layer3_network_id	integer  NULL,
	operating_system_id	integer  NULL,
	person_id	integer  NULL,
	property_collection_id	integer  NULL,
	service_env_collection_id	integer  NULL,
	site_code	varchar(50)  NULL,
	property_name	varchar(255) NOT NULL,
	property_type	varchar(50) NOT NULL,
	property_value	varchar(1024)  NULL,
	property_value_timestamp	timestamp without time zone  NULL,
	property_value_company_id	integer  NULL,
	property_value_account_coll_id	integer  NULL,
	property_value_dns_domain_id	integer  NULL,
	property_value_nblk_coll_id	integer  NULL,
	property_value_password_type	varchar(50)  NULL,
	property_value_person_id	integer  NULL,
	property_value_sw_package_id	integer  NULL,
	property_value_token_col_id	integer  NULL,
	property_rank	integer  NULL,
	start_date	timestamp without time zone  NULL,
	finish_date	timestamp without time zone  NULL,
	is_enabled	character(1) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'property', false);
ALTER TABLE property
	ALTER property_id
	SET DEFAULT nextval('property_property_id_seq'::regclass);
ALTER TABLE property
	ALTER is_enabled
	SET DEFAULT 'Y'::bpchar;
INSERT INTO property (
	property_id,
	account_collection_id,
	account_id,
	account_realm_id,
	company_id,
	device_collection_id,
	dns_domain_id,
	netblock_collection_id,
	layer2_network_id,
	layer3_network_id,
	operating_system_id,
	person_id,
	property_collection_id,		-- new column (property_collection_id)
	service_env_collection_id,
	site_code,
	property_name,
	property_type,
	property_value,
	property_value_timestamp,
	property_value_company_id,
	property_value_account_coll_id,
	property_value_dns_domain_id,
	property_value_nblk_coll_id,
	property_value_password_type,
	property_value_person_id,
	property_value_sw_package_id,
	property_value_token_col_id,
	property_rank,
	start_date,
	finish_date,
	is_enabled,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	property_id,
	account_collection_id,
	account_id,
	account_realm_id,
	company_id,
	device_collection_id,
	dns_domain_id,
	netblock_collection_id,
	layer2_network_id,
	layer3_network_id,
	operating_system_id,
	person_id,
	NULL,		-- new column (property_collection_id)
	service_env_collection_id,
	site_code,
	property_name,
	property_type,
	property_value,
	property_value_timestamp,
	property_value_company_id,
	property_value_account_coll_id,
	property_value_dns_domain_id,
	property_value_nblk_coll_id,
	property_value_password_type,
	property_value_person_id,
	property_value_sw_package_id,
	property_value_token_col_id,
	property_rank,
	start_date,
	finish_date,
	is_enabled,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM property_v58;

INSERT INTO audit.property (
	property_id,
	account_collection_id,
	account_id,
	account_realm_id,
	company_id,
	device_collection_id,
	dns_domain_id,
	netblock_collection_id,
	layer2_network_id,
	layer3_network_id,
	operating_system_id,
	person_id,
	property_collection_id,		-- new column (property_collection_id)
	service_env_collection_id,
	site_code,
	property_name,
	property_type,
	property_value,
	property_value_timestamp,
	property_value_company_id,
	property_value_account_coll_id,
	property_value_dns_domain_id,
	property_value_nblk_coll_id,
	property_value_password_type,
	property_value_person_id,
	property_value_sw_package_id,
	property_value_token_col_id,
	property_rank,
	start_date,
	finish_date,
	is_enabled,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	property_id,
	account_collection_id,
	account_id,
	account_realm_id,
	company_id,
	device_collection_id,
	dns_domain_id,
	netblock_collection_id,
	layer2_network_id,
	layer3_network_id,
	operating_system_id,
	person_id,
	NULL,		-- new column (property_collection_id)
	service_env_collection_id,
	site_code,
	property_name,
	property_type,
	property_value,
	property_value_timestamp,
	property_value_company_id,
	property_value_account_coll_id,
	property_value_dns_domain_id,
	property_value_nblk_coll_id,
	property_value_password_type,
	property_value_person_id,
	property_value_sw_package_id,
	property_value_token_col_id,
	property_rank,
	start_date,
	finish_date,
	is_enabled,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.property_v58;

ALTER TABLE property
	ALTER property_id
	SET DEFAULT nextval('property_property_id_seq'::regclass);
ALTER TABLE property
	ALTER is_enabled
	SET DEFAULT 'Y'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE property ADD CONSTRAINT pk_property PRIMARY KEY (property_id);

-- Table/Column Comments
COMMENT ON TABLE property IS 'generic property instance that describes system wide properties, as well as properties for various values of columns used throughout the db for configuration, acls, defaults, etc; also used to relate some tables';
COMMENT ON COLUMN property.property_id IS 'primary key for table to uniquely identify rows.';
COMMENT ON COLUMN property.account_collection_id IS 'user collection that properties may be set on.';
COMMENT ON COLUMN property.account_id IS 'system user that properties may be set on.';
COMMENT ON COLUMN property.company_id IS 'company that properties may be set on.';
COMMENT ON COLUMN property.device_collection_id IS 'device collection that properties may be set on.';
COMMENT ON COLUMN property.dns_domain_id IS 'dns domain that properties may be set on.';
COMMENT ON COLUMN property.operating_system_id IS 'operating system that properties may be set on.';
COMMENT ON COLUMN property.site_code IS 'site_code that properties may be set on';
COMMENT ON COLUMN property.property_name IS 'textual name of a property';
COMMENT ON COLUMN property.property_type IS 'textual type of a department';
COMMENT ON COLUMN property.property_value IS 'general purpose column for value of property not defined by other types.  This may be enforced by fk (trigger) if val_property.property_data_type is list (fk is to val_property_value).';
COMMENT ON COLUMN property.property_value_timestamp IS 'property is defined as a timestamp';
COMMENT ON COLUMN property.start_date IS 'date/time that the assignment takes effect';
COMMENT ON COLUMN property.finish_date IS 'date/time that the assignment ceases taking effect';
COMMENT ON COLUMN property.is_enabled IS 'indiciates if the property is temporarily disabled or not.';
-- INDEXES
CREATE INDEX xif23property ON property USING btree (layer2_network_id);
CREATE INDEX xifprop_nmtyp ON property USING btree (property_name, property_type);
CREATE INDEX xifprop_devcolid ON property USING btree (device_collection_id);
CREATE INDEX xifprop_dnsdomid ON property USING btree (dns_domain_id);
CREATE INDEX xif25property ON property USING btree (property_collection_id);
CREATE INDEX xifprop_pval_tokcolid ON property USING btree (property_value_token_col_id);
CREATE INDEX xifprop_compid ON property USING btree (company_id);
CREATE INDEX xif21property ON property USING btree (service_env_collection_id);
CREATE INDEX xifprop_pval_acct_colid ON property USING btree (property_value_account_coll_id);
CREATE INDEX xif20property ON property USING btree (netblock_collection_id);
CREATE INDEX xifprop_osid ON property USING btree (operating_system_id);
CREATE INDEX xif17property ON property USING btree (property_value_person_id);
CREATE INDEX xifprop_acctcol_id ON property USING btree (account_collection_id);
CREATE INDEX xif24property ON property USING btree (layer3_network_id);
CREATE INDEX xifprop_pval_compid ON property USING btree (property_value_company_id);
CREATE INDEX xifprop_site_code ON property USING btree (site_code);
CREATE INDEX xif19property ON property USING btree (property_value_nblk_coll_id);
CREATE INDEX xif18property ON property USING btree (person_id);
CREATE INDEX xifprop_pval_dnsdomid ON property USING btree (property_value_dns_domain_id);
CREATE INDEX xifprop_pval_swpkgid ON property USING btree (property_value_sw_package_id);
CREATE INDEX xifprop_account_id ON property USING btree (account_id);
CREATE INDEX xifprop_pval_pwdtyp ON property USING btree (property_value_password_type);
CREATE INDEX xif22property ON property USING btree (account_realm_id);

-- CHECK CONSTRAINTS
ALTER TABLE property ADD CONSTRAINT ckc_prop_isenbld
	CHECK (is_enabled = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK property and dns_domain
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_dnsdomid
	FOREIGN KEY (property_value_dns_domain_id) REFERENCES dns_domain(dns_domain_id);

-- consider FK property and netblock_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_pv_nblkcol_id
	FOREIGN KEY (property_value_nblk_coll_id) REFERENCES netblock_collection(netblock_collection_id);

-- consider FK property and account_realm
ALTER TABLE property
	ADD CONSTRAINT fk_property_acctrealmid
	FOREIGN KEY (account_realm_id) REFERENCES account_realm(account_realm_id);

-- consider FK property and token_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_tokcolid
	FOREIGN KEY (property_value_token_col_id) REFERENCES token_collection(token_collection_id);

-- consider FK property and device_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_devcolid
	FOREIGN KEY (device_collection_id) REFERENCES device_collection(device_collection_id);

-- consider FK property and dns_domain
ALTER TABLE property
	ADD CONSTRAINT fk_property_dnsdomid
	FOREIGN KEY (dns_domain_id) REFERENCES dns_domain(dns_domain_id);

-- consider FK property and sw_package
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_swpkgid
	FOREIGN KEY (property_value_sw_package_id) REFERENCES sw_package(sw_package_id);

-- consider FK property and layer2_network
ALTER TABLE property
	ADD CONSTRAINT fk_prop_l2netid
	FOREIGN KEY (layer2_network_id) REFERENCES layer2_network(layer2_network_id);

-- consider FK property and val_password_type
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_pwdtyp
	FOREIGN KEY (property_value_password_type) REFERENCES val_password_type(password_type);

-- consider FK property and val_property
ALTER TABLE property
	ADD CONSTRAINT fk_property_nmtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);

-- consider FK property and person
ALTER TABLE property
	ADD CONSTRAINT fk_property_val_prsnid
	FOREIGN KEY (property_value_person_id) REFERENCES person(person_id);

-- consider FK property and service_environment_collection
ALTER TABLE property
	ADD CONSTRAINT fk_prop_svc_env_coll_id
	FOREIGN KEY (service_env_collection_id) REFERENCES service_environment_collection(service_env_collection_id);

-- consider FK property and company
ALTER TABLE property
	ADD CONSTRAINT fk_property_compid
	FOREIGN KEY (company_id) REFERENCES company(company_id);

-- consider FK property and layer3_network
ALTER TABLE property
	ADD CONSTRAINT fk_prop_l3netid
	FOREIGN KEY (layer3_network_id) REFERENCES layer3_network(layer3_network_id);

-- consider FK property and account_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_acct_col
	FOREIGN KEY (account_collection_id) REFERENCES account_collection(account_collection_id);

-- consider FK property and site
ALTER TABLE property
	ADD CONSTRAINT fk_property_site_code
	FOREIGN KEY (site_code) REFERENCES site(site_code);

-- consider FK property and property_collection
-- skipping; does not exist yet
--ALTER TABLE property
--	ADD CONSTRAINT fk_property_prop_coll_id
--	FOREIGN KEY (property_collection_id) REFERENCES property_collection(property_collection_id);

-- consider FK property and person
ALTER TABLE property
	ADD CONSTRAINT fk_property_person_id
	FOREIGN KEY (person_id) REFERENCES person(person_id);

-- consider FK property and account
ALTER TABLE property
	ADD CONSTRAINT fk_property_acctid
	FOREIGN KEY (account_id) REFERENCES account(account_id);

-- consider FK property and account_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_acct_colid
	FOREIGN KEY (property_value_account_coll_id) REFERENCES account_collection(account_collection_id);

-- consider FK property and netblock_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_nblk_coll_id
	FOREIGN KEY (netblock_collection_id) REFERENCES netblock_collection(netblock_collection_id);

-- consider FK property and operating_system
ALTER TABLE property
	ADD CONSTRAINT fk_property_osid
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);

-- consider FK property and company
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_compid
	FOREIGN KEY (property_value_company_id) REFERENCES company(company_id);

-- TRIGGERS
CREATE TRIGGER trigger_validate_property BEFORE INSERT OR UPDATE ON property FOR EACH ROW EXECUTE PROCEDURE validate_property();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'property');
ALTER SEQUENCE property_property_id_seq
	 OWNED BY property.property_id;
DROP TABLE IF EXISTS property_v58;
DROP TABLE IF EXISTS audit.property_v58;
-- DONE DEALING WITH TABLE property [369544]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE property_collection
CREATE TABLE property_collection
(
	property_collection_id	integer NOT NULL,
	property_collection_name	varchar(255) NOT NULL,
	property_collection_type	varchar(50) NOT NULL,
	description	varchar(255)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'property_collection', true);
ALTER TABLE property_collection
	ALTER property_collection_id
	SET DEFAULT nextval('property_collection_property_collection_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE property_collection ADD CONSTRAINT pk_property_collection PRIMARY KEY (property_collection_id);
ALTER TABLE property_collection ADD CONSTRAINT ak_uqpropcoll_name_type UNIQUE (property_collection_name, property_collection_type);

-- Table/Column Comments
COMMENT ON TABLE property_collection IS 'Collections of Property Name/Types.  Used for grouping properties for different purposes';
-- INDEXES
CREATE INDEX xif1property_collection ON property_collection USING btree (property_collection_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK property_collection and property_collection_hier
-- Skipping this FK since table does not exist yet
--ALTER TABLE property_collection_hier
--	ADD CONSTRAINT fk_propcollhier_propcolid
--	FOREIGN KEY (property_collection_id) REFERENCES property_collection(property_collection_id);

-- consider FK property_collection and property_collection_property
-- Skipping this FK since table does not exist yet
--ALTER TABLE property_collection_property
--	ADD CONSTRAINT fk_prop_coll_prop_prop_coll_id
--	FOREIGN KEY (property_collection_id) REFERENCES property_collection(property_collection_id);

-- consider FK property_collection and property
ALTER TABLE property
	ADD CONSTRAINT fk_property_prop_coll_id
	FOREIGN KEY (property_collection_id) REFERENCES property_collection(property_collection_id);
-- consider FK property_collection and property_collection_hier
-- Skipping this FK since table does not exist yet
--ALTER TABLE property_collection_hier
--	ADD CONSTRAINT fk_propcollhier_chldpropcoll_i
--	FOREIGN KEY (child_property_collection_id) REFERENCES property_collection(property_collection_id);


-- FOREIGN KEYS TO
-- consider FK property_collection and val_property_collection_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE property_collection
--	ADD CONSTRAINT fk_propcol_propcoltype
--	FOREIGN KEY (property_collection_type) REFERENCES val_property_collection_type(property_collection_type);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'property_collection');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'property_collection');
ALTER SEQUENCE property_collection_property_collection_id_seq
	 OWNED BY property_collection.property_collection_id;
-- DONE DEALING WITH TABLE property_collection [369580]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE property_collection_hier
CREATE TABLE property_collection_hier
(
	property_collection_id	integer NOT NULL,
	child_property_collection_id	integer NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'property_collection_hier', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE property_collection_hier ADD CONSTRAINT pk_property_collection_hier PRIMARY KEY (property_collection_id, child_property_collection_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif2property_collection_hier ON property_collection_hier USING btree (child_property_collection_id);
CREATE INDEX xif1property_collection_hier ON property_collection_hier USING btree (property_collection_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK property_collection_hier and property_collection
ALTER TABLE property_collection_hier
	ADD CONSTRAINT fk_propcollhier_chldpropcoll_i
	FOREIGN KEY (child_property_collection_id) REFERENCES property_collection(property_collection_id);
-- consider FK property_collection_hier and property_collection
ALTER TABLE property_collection_hier
	ADD CONSTRAINT fk_propcollhier_propcolid
	FOREIGN KEY (property_collection_id) REFERENCES property_collection(property_collection_id);

-- TRIGGERS

SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'property_collection_hier');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'property_collection_hier');
-- DONE DEALING WITH TABLE property_collection_hier [369592]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE property_collection_property
CREATE TABLE property_collection_property
(
	property_collection_id	integer NOT NULL,
	property_name	varchar(255) NOT NULL,
	property_type	varchar(50) NOT NULL,
	property_id_rank	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'property_collection_property', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE property_collection_property ADD CONSTRAINT pk_property_collection_propert PRIMARY KEY (property_collection_id, property_name, property_type);
ALTER TABLE property_collection_property ADD CONSTRAINT xakprop_coll_prop_rank UNIQUE (property_collection_id, property_id_rank);

-- Table/Column Comments
COMMENT ON TABLE property_collection_property IS 'name,type members of a property collection';
COMMENT ON COLUMN property_collection_property.property_name IS 'property name for validation purposes';
COMMENT ON COLUMN property_collection_property.property_type IS 'property type for validation purposes';
-- INDEXES
CREATE INDEX xifprop_coll_prop_prop_coll_id ON property_collection_property USING btree (property_collection_id);
CREATE INDEX xifprop_coll_prop_namtyp ON property_collection_property USING btree (property_name, property_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK property_collection_property and val_property
-- Skipping this FK since table does not exist yet
--ALTER TABLE property_collection_property
--	ADD CONSTRAINT fk_prop_col_propnamtyp
--	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);

-- consider FK property_collection_property and property_collection
ALTER TABLE property_collection_property
	ADD CONSTRAINT fk_prop_coll_prop_prop_coll_id
	FOREIGN KEY (property_collection_id) REFERENCES property_collection(property_collection_id);

-- TRIGGERS

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'property_collection_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'property_collection_property');
-- DONE DEALING WITH TABLE property_collection_property [369602]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_property_collection_type
CREATE TABLE val_property_collection_type
(
	property_collection_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	max_num_members	integer  NULL,
	max_num_collections	integer  NULL,
	can_have_hierarchy	character(1) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_property_collection_type', true);
ALTER TABLE val_property_collection_type
	ALTER can_have_hierarchy
	SET DEFAULT 'Y'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_property_collection_type ADD CONSTRAINT pk_property_collction_type PRIMARY KEY (property_collection_type);

-- Table/Column Comments
COMMENT ON COLUMN val_property_collection_type.max_num_members IS 'Maximum INTEGER of members in a given collection of this type
';
COMMENT ON COLUMN val_property_collection_type.max_num_collections IS 'Maximum INTEGER of collections a given member can be a part of of this type.
';
COMMENT ON COLUMN val_property_collection_type.can_have_hierarchy IS 'Indicates if the collections can have other collections to make it hierarchical.';
-- INDEXES

-- CHECK CONSTRAINTS
ALTER TABLE val_property_collection_type ADD CONSTRAINT check_yes_no_1132635988
	CHECK (can_have_hierarchy = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK val_property_collection_type and property_collection
ALTER TABLE property_collection
	ADD CONSTRAINT fk_propcol_propcoltype
	FOREIGN KEY (property_collection_type) REFERENCES val_property_collection_type(property_collection_type);

-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_property_collection_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_property_collection_type');
-- DONE DEALING WITH TABLE val_property_collection_type [370477]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_property [281156]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'val_property', 'val_property');

-- FOREIGN KEYS FROM
ALTER TABLE property DROP CONSTRAINT IF EXISTS fk_property_nmtyp;
ALTER TABLE val_property_value DROP CONSTRAINT IF EXISTS fk_valproval_namtyp;


-- FOREIGN KEYS TO
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_propdttyp;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_val_prop_nblk_coll_type;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_pv_actyp_rst;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_proptyp;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS pk_val_property;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif3val_property";
DROP INDEX IF EXISTS "jazzhands"."xif1val_property";
DROP INDEX IF EXISTS "jazzhands"."xif4val_property";
DROP INDEX IF EXISTS "jazzhands"."xif2val_property";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_prodstate;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pdnsdomid;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_606225804;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_cmp_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pdevcol_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_354296970;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1279736247;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_sitec;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_2139007167;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_osid;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_2016888554;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pacct_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pucls_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1279736503;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_ismulti;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_val_property ON jazzhands.val_property;
DROP TRIGGER IF EXISTS trigger_audit_val_property ON jazzhands.val_property;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_property');
---- BEGIN audit.val_property TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_property_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_property');
---- DONE audit.val_property TEARDOWN


ALTER TABLE val_property RENAME TO val_property_v58;
ALTER TABLE audit.val_property RENAME TO val_property_v58;

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
	permit_property_collection_id,		-- new column (permit_property_collection_id)
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
	'PROHIBITED'::bpchar,		-- new column (permit_property_collection_id)
	permit_service_env_collection,
	permit_site_code,
	permit_property_rank,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM val_property_v58;

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
	permit_property_collection_id,		-- new column (permit_property_collection_id)
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
	NULL,		-- new column (permit_property_collection_id)
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
FROM audit.val_property_v58;

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
COMMENT ON COLUMN val_property.is_multivalue IS 'If N, acts like an ak on property.(*_id,property_type)';
COMMENT ON COLUMN val_property.property_data_type IS 'which of the property_table_* columns should be used for this value';
COMMENT ON COLUMN val_property.permit_account_collection_id IS 'defines how company id should be used in the property for this (name,type)';
COMMENT ON COLUMN val_property.permit_account_id IS 'defines how company id should be used in the property for this (name,type)';
COMMENT ON COLUMN val_property.permit_company_id IS 'defines how company id should be used in the property for this (name,type)';
COMMENT ON COLUMN val_property.permit_device_collection_id IS 'defines how company id should be used in the property for this (name,type)';
COMMENT ON COLUMN val_property.permit_dns_domain_id IS 'defines how company id should be used in the property for this (name,type)';
-- INDEXES
CREATE INDEX xif1val_property ON val_property USING btree (property_data_type);
CREATE INDEX xif3val_property ON val_property USING btree (prop_val_acct_coll_type_rstrct);
CREATE INDEX xif2val_property ON val_property USING btree (property_type);
CREATE INDEX xif4val_property ON val_property USING btree (prop_val_nblk_coll_type_rstrct);

-- CHECK CONSTRAINTS
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_2016888554
	CHECK (permit_account_realm_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_1279736247
	CHECK (permit_layer3_network_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_271462566
	CHECK (permit_property_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_354296970
	CHECK (permit_netblock_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pdevcol_id
	CHECK (permit_device_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pdnsdomid
	CHECK (permit_dns_domain_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_prodstate
	CHECK (permit_service_env_collection = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_1279736503
	CHECK (permit_layer2_network_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pacct_id
	CHECK (permit_account_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_osid
	CHECK (permit_operating_system_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_2139007167
	CHECK (permit_property_rank = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_sitec
	CHECK (permit_site_code = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_606225804
	CHECK (permit_person_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_cmp_id
	CHECK (permit_company_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pucls_id
	CHECK (permit_account_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_ismulti
	CHECK (is_multivalue = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK val_property and val_property_value
-- Skipping this FK since table does not exist yet
ALTER TABLE val_property_value
	ADD CONSTRAINT fk_valproval_namtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);

-- consider FK val_property and property
ALTER TABLE property
	ADD CONSTRAINT fk_property_nmtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);
-- consider FK val_property and property_collection_property
ALTER TABLE property_collection_property
	ADD CONSTRAINT fk_prop_col_propnamtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);

-- FOREIGN KEYS TO
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

-- consider FK val_property and val_property_data_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_valprop_propdttyp
	FOREIGN KEY (property_data_type) REFERENCES val_property_data_type(property_data_type);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_property');
DROP TABLE IF EXISTS val_property_v58;
DROP TABLE IF EXISTS audit.val_property_v58;
-- DONE DEALING WITH TABLE val_property [370434]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE sw_package [280520]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'sw_package', 'sw_package');

-- FOREIGN KEYS FROM
ALTER TABLE sw_package_relation DROP CONSTRAINT IF EXISTS fk_sw_pkgrel_ref_sw_pkg;

ALTER TABLE sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_pkg_ref_sw_pkg_rel;

ALTER TABLE property DROP CONSTRAINT IF EXISTS fk_property_pval_swpkgid;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.sw_package DROP CONSTRAINT IF EXISTS fk_sw_pkg_ref_v_prod_state;
ALTER TABLE jazzhands.sw_package DROP CONSTRAINT IF EXISTS fk_swpkg_ref_vswpkgtype;
ALTER TABLE jazzhands.sw_package DROP CONSTRAINT IF EXISTS pk_sw_package;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_sw_package ON jazzhands.sw_package;
DROP TRIGGER IF EXISTS trig_userlog_sw_package ON jazzhands.sw_package;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'sw_package');
---- BEGIN audit.sw_package TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."sw_package_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'sw_package');
---- DONE audit.sw_package TEARDOWN


ALTER TABLE sw_package RENAME TO sw_package_v58;
ALTER TABLE audit.sw_package RENAME TO sw_package_v58;

CREATE TABLE sw_package
(
	sw_package_id	integer NOT NULL,
	sw_package_name	varchar(50) NOT NULL,
	sw_package_type	varchar(50) NOT NULL,
	description	varchar(255)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL,
	service_environment_id	integer  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'sw_package', false);
ALTER TABLE sw_package
	ALTER sw_package_id
	SET DEFAULT nextval('sw_package_sw_package_id_seq'::regclass);
INSERT INTO sw_package (
	sw_package_id,
	sw_package_name,
	sw_package_type,
	description,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	sw_package_id,
	sw_package_name,
	sw_package_type,
	description,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM sw_package_v58 sw;

INSERT INTO audit.sw_package (
	sw_package_id,
	sw_package_name,
	sw_package_type,
	description,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	sw.sw_package_id,
	sw.sw_package_name,
	sw.sw_package_type,
	sw.description,
	sw.data_ins_user,
	sw.data_ins_date,
	sw.data_upd_user,
	sw.data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.sw_package_v58 sw;

ALTER TABLE sw_package
	ALTER sw_package_id
	SET DEFAULT nextval('sw_package_sw_package_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE sw_package ADD CONSTRAINT pk_sw_package PRIMARY KEY (sw_package_id);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK sw_package and sw_package_release
-- Skipping this FK since table does not exist yet
--ALTER TABLE sw_package_release
--	ADD CONSTRAINT fk_sw_pkg_ref_sw_pkg_rel
--	FOREIGN KEY (sw_package_id) REFERENCES sw_package(sw_package_id);

-- consider FK sw_package and property
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_swpkgid
	FOREIGN KEY (property_value_sw_package_id) REFERENCES sw_package(sw_package_id);
-- consider FK sw_package and sw_package_relation
-- Skipping this FK since table does not exist yet
--ALTER TABLE sw_package_relation
--	ADD CONSTRAINT fk_sw_pkgrel_ref_sw_pkg
--	FOREIGN KEY (related_sw_package_id) REFERENCES sw_package(sw_package_id);


-- FOREIGN KEYS TO
-- consider FK sw_package and service_environment
ALTER TABLE sw_package
	ADD CONSTRAINT fk_sw_pkg_ref_v_prod_state
	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);
-- consider FK sw_package and val_sw_package_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE sw_package
--	ADD CONSTRAINT fk_swpkg_ref_vswpkgtype
--	FOREIGN KEY (sw_package_type) REFERENCES val_sw_package_type(sw_package_type);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'sw_package');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'sw_package');
ALTER SEQUENCE sw_package_sw_package_id_seq
	 OWNED BY sw_package.sw_package_id;
DROP TABLE IF EXISTS sw_package_v58;
DROP TABLE IF EXISTS audit.sw_package_v58;
-- DONE DEALING WITH TABLE sw_package [369798]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE sw_package_release [280545]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'sw_package_release', 'sw_package_release');

-- FOREIGN KEYS FROM
ALTER TABLE voe_sw_package DROP CONSTRAINT IF EXISTS fk_voe_swpkg_ref_swpkg_rel;
ALTER TABLE sw_package_relation DROP CONSTRAINT IF EXISTS fk_swpkgrltn_ref_swpkgrel;


-- FOREIGN KEYS TO
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_pkg_ref_sw_pkg_rel;
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_pkg_rel_ref_vdevarch;
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_package_type;
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_pkg_rel_ref_vsvcenv;
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_pkg_rel_ref_sys_user;
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_pkg_rel_ref_vswpkgfmt;
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS fk_sw_pkg_rel_ref_sw_pkg_rep;
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS pk_sw_package_release;
ALTER TABLE jazzhands.sw_package_release DROP CONSTRAINT IF EXISTS ak_uq_sw_pkg_rel_comb_sw_packa;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_sw_pkg_rel_sw_pkg_id";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_sw_package_release ON jazzhands.sw_package_release;
DROP TRIGGER IF EXISTS trigger_audit_sw_package_release ON jazzhands.sw_package_release;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'sw_package_release');
---- BEGIN audit.sw_package_release TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."sw_package_release_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'sw_package_release');
---- DONE audit.sw_package_release TEARDOWN


ALTER TABLE sw_package_release RENAME TO sw_package_release_v58;
ALTER TABLE audit.sw_package_release RENAME TO sw_package_release_v58;

CREATE TABLE sw_package_release
(
	sw_package_release_id	integer NOT NULL,
	sw_package_id	integer NOT NULL,
	sw_package_version	varchar(50) NOT NULL,
	sw_package_format	varchar(50) NOT NULL,
	sw_package_type	varchar(50)  NULL,
	creation_account_id	integer NOT NULL,
	processor_architecture	varchar(50) NOT NULL,
	sw_package_repository_id	integer NOT NULL,
	uploading_principal	varchar(255)  NULL,
	package_size	integer  NULL,
	installed_package_size_kb	integer  NULL,
	pathname	varchar(1024)  NULL,
	md5sum	varchar(255)  NULL,
	description	varchar(255)  NULL,
	instantiation_date	timestamp with time zone  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL,
	service_environment_id	integer NOT NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'sw_package_release', false);
ALTER TABLE sw_package_release
	ALTER sw_package_release_id
	SET DEFAULT nextval('sw_package_release_sw_package_release_id_seq'::regclass);
INSERT INTO sw_package_release (
	sw_package_release_id,
	sw_package_id,
	sw_package_version,
	sw_package_format,
	sw_package_type,
	creation_account_id,
	processor_architecture,
	service_environment_id,		-- new column (service_environment_id)
	sw_package_repository_id,
	uploading_principal,
	package_size,
	installed_package_size_kb,
	pathname,
	md5sum,
	description,
	instantiation_date,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	sw.sw_package_release_id,
	sw.sw_package_id,
	sw.sw_package_version,
	sw.sw_package_format,
	sw.sw_package_type,
	sw.creation_account_id,
	sw.processor_architecture,
	se.service_environment_id ,	-- new column (service_environment_id)
	sw.sw_package_repository_id,
	sw.uploading_principal,
	sw.package_size,
	sw.installed_package_size_kb,
	sw.pathname,
	sw.md5sum,
	sw.description,
	sw.instantiation_date,
	sw.data_ins_user,
	sw.data_ins_date,
	sw.data_upd_user,
	sw.data_upd_date
FROM sw_package_release_v58 sw
	inner join service_environment se on
		sw.service_environment = se.service_environment_name;

INSERT INTO audit.sw_package_release (
	sw_package_release_id,
	sw_package_id,
	sw_package_version,
	sw_package_format,
	sw_package_type,
	creation_account_id,
	processor_architecture,
	service_environment_id,		-- new column (service_environment_id)
	sw_package_repository_id,
	uploading_principal,
	package_size,
	installed_package_size_kb,
	pathname,
	md5sum,
	description,
	instantiation_date,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	sw.sw_package_release_id,
	sw.sw_package_id,
	sw.sw_package_version,
	sw.sw_package_format,
	sw.sw_package_type,
	sw.creation_account_id,
	sw.processor_architecture,
	se.service_environment_id,	-- new column (service_environment_id)
	sw.sw_package_repository_id,
	sw.uploading_principal,
	sw.package_size,
	sw.installed_package_size_kb,
	sw.pathname,
	sw.md5sum,
	sw.description,
	sw.instantiation_date,
	sw.data_ins_user,
	sw.data_ins_date,
	sw.data_upd_user,
	sw.data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.sw_package_release_v58 sw
	inner join service_environment se on
		sw.service_environment = se.service_environment_name;

ALTER TABLE sw_package_release
	ALTER sw_package_release_id
	SET DEFAULT nextval('sw_package_release_sw_package_release_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE sw_package_release ADD CONSTRAINT ak_uq_sw_pkg_rel_comb_sw_packa UNIQUE (sw_package_id, sw_package_version, processor_architecture, sw_package_repository_id);
ALTER TABLE sw_package_release ADD CONSTRAINT pk_sw_package_release PRIMARY KEY (sw_package_release_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX idx_sw_pkg_rel_sw_pkg_id ON sw_package_release USING btree (sw_package_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK sw_package_release and sw_package_relation
ALTER TABLE sw_package_relation
	ADD CONSTRAINT fk_swpkgrltn_ref_swpkgrel
	FOREIGN KEY (sw_package_release_id) REFERENCES sw_package_release(sw_package_release_id);

-- consider FK sw_package_release and voe_sw_package
ALTER TABLE voe_sw_package
	ADD CONSTRAINT fk_voe_swpkg_ref_swpkg_rel
	FOREIGN KEY (sw_package_release_id) REFERENCES sw_package_release(sw_package_release_id);


-- FOREIGN KEYS TO
-- consider FK sw_package_release and val_sw_package_format
ALTER TABLE sw_package_release
	ADD CONSTRAINT fk_sw_pkg_rel_ref_vswpkgfmt
	FOREIGN KEY (sw_package_format) REFERENCES val_sw_package_format(sw_package_format);

-- consider FK sw_package_release and account
ALTER TABLE sw_package_release
	ADD CONSTRAINT fk_sw_pkg_rel_ref_sys_user
	FOREIGN KEY (creation_account_id) REFERENCES account(account_id);

-- consider FK sw_package_release and sw_package_repository
ALTER TABLE sw_package_release
	ADD CONSTRAINT fk_sw_pkg_rel_ref_sw_pkg_rep
	FOREIGN KEY (sw_package_repository_id) REFERENCES sw_package_repository(sw_package_repository_id);

-- consider FK sw_package_release and sw_package
ALTER TABLE sw_package_release
	ADD CONSTRAINT fk_sw_pkg_ref_sw_pkg_rel
	FOREIGN KEY (sw_package_id) REFERENCES sw_package(sw_package_id);

-- consider FK sw_package_release and val_processor_architecture
ALTER TABLE sw_package_release
	ADD CONSTRAINT fk_sw_pkg_rel_ref_vdevarch
	FOREIGN KEY (processor_architecture) REFERENCES val_processor_architecture(processor_architecture);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'sw_package_release');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'sw_package_release');
ALTER SEQUENCE sw_package_release_sw_package_release_id_seq
	 OWNED BY sw_package_release.sw_package_release_id;
DROP TABLE IF EXISTS sw_package_release_v58;
DROP TABLE IF EXISTS audit.sw_package_release_v58;
-- DONE DEALING WITH TABLE sw_package_release [369823]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE network_service [280059]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'network_service', 'network_service');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.network_service DROP CONSTRAINT IF EXISTS fk_netsvc_dnsid_id;
ALTER TABLE jazzhands.network_service DROP CONSTRAINT IF EXISTS fk_netsvc_netint_id;
ALTER TABLE jazzhands.network_service DROP CONSTRAINT IF EXISTS fk_netsvc_csvcenv;
ALTER TABLE jazzhands.network_service DROP CONSTRAINT IF EXISTS fk_netsvc_device_id;
ALTER TABLE jazzhands.network_service DROP CONSTRAINT IF EXISTS fk_netsvc_netsvctyp_id;
ALTER TABLE jazzhands.network_service DROP CONSTRAINT IF EXISTS pk_service;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_netsvc_svcenv";
DROP INDEX IF EXISTS "jazzhands"."ix_netsvc_netintid";
DROP INDEX IF EXISTS "jazzhands"."ix_netsvc_dnsidrecid";
DROP INDEX IF EXISTS "jazzhands"."ix_netsvc_netdevid";
DROP INDEX IF EXISTS "jazzhands"."idx_netsvc_ismonitored";
DROP INDEX IF EXISTS "jazzhands"."idx_netsvc_netsvctype";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.network_service DROP CONSTRAINT IF EXISTS ckc_is_monitored_network_;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_network_service ON jazzhands.network_service;
DROP TRIGGER IF EXISTS trigger_audit_network_service ON jazzhands.network_service;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'network_service');
---- BEGIN audit.network_service TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."network_service_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'network_service');
---- DONE audit.network_service TEARDOWN


ALTER TABLE network_service RENAME TO network_service_v58;
ALTER TABLE audit.network_service RENAME TO network_service_v58;

CREATE TABLE network_service
(
	network_service_id	integer NOT NULL,
	name	varchar(255)  NULL,
	description	varchar(255)  NULL,
	network_service_type	varchar(50) NOT NULL,
	is_monitored	character(1)  NULL,
	device_id	integer  NULL,
	network_interface_id	integer  NULL,
	dns_record_id	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL,
	service_environment_id	integer NOT NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'network_service', false);
ALTER TABLE network_service
	ALTER network_service_id
	SET DEFAULT nextval('network_service_network_service_id_seq'::regclass);

INSERT INTO network_service (
	network_service_id,
	name,
	description,
	network_service_type,
	is_monitored,
	device_id,
	network_interface_id,
	dns_record_id,
	service_environment_id,		-- new column (service_environment_id)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	ns.network_service_id,
	ns.name,
	ns.description,
	ns.network_service_type,
	ns.is_monitored,
	ns.device_id,
	ns.network_interface_id,
	ns.dns_record_id,
	se.service_environment_id,	-- new column (service_environment_id)
	ns.data_ins_user,
	ns.data_ins_date,
	ns.data_upd_user,
	ns.data_upd_date
FROM network_service_v58 ns
	inner join service_environment se on
		ns.service_environment = se.service_environment_name;

INSERT INTO audit.network_service (
	network_service_id,
	name,
	description,
	network_service_type,
	is_monitored,
	device_id,
	network_interface_id,
	dns_record_id,
	service_environment_id,		-- new column (service_environment_id)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	ns.network_service_id,
	ns.name,
	ns.description,
	ns.network_service_type,
	ns.is_monitored,
	ns.device_id,
	ns.network_interface_id,
	ns.dns_record_id,
	se.service_environment_id,	-- new column (service_environment_id)
	ns.data_ins_user,
	ns.data_ins_date,
	ns.data_upd_user,
	ns.data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.network_service_v58 ns
	inner join service_environment se on
		ns.service_environment = se.service_environment_name;

ALTER TABLE network_service
	ALTER network_service_id
	SET DEFAULT nextval('network_service_network_service_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE network_service ADD CONSTRAINT pk_service PRIMARY KEY (network_service_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX idx_netsvc_ismonitored ON network_service USING btree (is_monitored);
CREATE INDEX idx_netsvc_netsvctype ON network_service USING btree (network_service_type);
CREATE INDEX idx_netsvc_svcenv ON network_service USING btree (service_environment_id);
CREATE INDEX ix_netsvc_netintid ON network_service USING btree (network_interface_id);
CREATE INDEX ix_netsvc_netdevid ON network_service USING btree (device_id);
CREATE INDEX ix_netsvc_dnsidrecid ON network_service USING btree (dns_record_id);

-- CHECK CONSTRAINTS
ALTER TABLE network_service ADD CONSTRAINT ckc_is_monitored_network_
	CHECK ((is_monitored IS NULL) OR ((is_monitored = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_monitored)::text = upper((is_monitored)::text))));

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK network_service and device
ALTER TABLE network_service
	ADD CONSTRAINT fk_netsvc_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK network_service and service_environment
ALTER TABLE network_service
	ADD CONSTRAINT fk_netsvc_csvcenv
	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);
-- consider FK network_service and val_network_service_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE network_service
--	ADD CONSTRAINT fk_netsvc_netsvctyp_id
--	FOREIGN KEY (network_service_type) REFERENCES val_network_service_type(network_service_type);

-- consider FK network_service and network_interface
-- Skipping this FK since table does not exist yet
--ALTER TABLE network_service
--	ADD CONSTRAINT fk_netsvc_netint_id
--	FOREIGN KEY (network_interface_id) REFERENCES network_interface(network_interface_id);

-- consider FK network_service and dns_record
-- Skipping this FK since table does not exist yet
--ALTER TABLE network_service
--	ADD CONSTRAINT fk_netsvc_dnsid_id
--	FOREIGN KEY (dns_record_id) REFERENCES dns_record(dns_record_id);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'network_service');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'network_service');
ALTER SEQUENCE network_service_network_service_id_seq
	 OWNED BY network_service.network_service_id;
DROP TABLE IF EXISTS network_service_v58;
DROP TABLE IF EXISTS audit.network_service_v58;
-- DONE DEALING WITH TABLE network_service [369297]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE appaal_instance [279262]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'appaal_instance', 'appaal_instance');

-- FOREIGN KEYS FROM
ALTER TABLE appaal_instance_property DROP CONSTRAINT IF EXISTS fk_appaalins_ref_appaalinsprop;
ALTER TABLE appaal_instance_device_coll DROP CONSTRAINT IF EXISTS fk_appaalins_ref_appaalinsdcol;


-- FOREIGN KEYS TO
ALTER TABLE jazzhands.appaal_instance DROP CONSTRAINT IF EXISTS fk_appaal_ref_appaal_inst;
ALTER TABLE jazzhands.appaal_instance DROP CONSTRAINT IF EXISTS fk_appaal_inst_filgrpacctcolid;
ALTER TABLE jazzhands.appaal_instance DROP CONSTRAINT IF EXISTS fk_appaal_i_fk_applic_svcenv;
ALTER TABLE jazzhands.appaal_instance DROP CONSTRAINT IF EXISTS fk_appaal_i_reference_fo_accti;
ALTER TABLE jazzhands.appaal_instance DROP CONSTRAINT IF EXISTS pk_appaal_instance;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xifappaal_inst_filgrpacctcolid";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.appaal_instance DROP CONSTRAINT IF EXISTS ckc_file_mode_appaal_i;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_appaal_instance ON jazzhands.appaal_instance;
DROP TRIGGER IF EXISTS trigger_audit_appaal_instance ON jazzhands.appaal_instance;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'appaal_instance');
---- BEGIN audit.appaal_instance TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- INDEXES
DROP INDEX IF EXISTS "audit"."appaal_instance_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'appaal_instance');
---- DONE audit.appaal_instance TEARDOWN


ALTER TABLE appaal_instance RENAME TO appaal_instance_v58;
ALTER TABLE audit.appaal_instance RENAME TO appaal_instance_v58;

CREATE TABLE appaal_instance
(
	appaal_instance_id	integer NOT NULL,
	appaal_id	integer  NULL,
	file_mode	integer NOT NULL,
	file_owner_account_id	integer NOT NULL,
	file_group_acct_collection_id	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL,
	service_environment_id	integer NOT NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'appaal_instance', false);
ALTER TABLE appaal_instance
	ALTER appaal_instance_id
	SET DEFAULT nextval('appaal_instance_appaal_instance_id_seq'::regclass);

INSERT INTO appaal_instance (
	appaal_instance_id,
	appaal_id,
	service_environment_id,		-- new column (service_environment_id)
	file_mode,
	file_owner_account_id,
	file_group_acct_collection_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	ai.appaal_instance_id,
	ai.appaal_id,
	se.service_environment_id,	-- new column (service_environment_id)
	ai.file_mode,
	ai.file_owner_account_id,
	ai.file_group_acct_collection_id,
	ai.data_ins_user,
	ai.data_ins_date,
	ai.data_upd_user,
	ai.data_upd_date
FROM appaal_instance_v58 ai
	inner join service_environment se on
		ai.service_environment = se.service_environment_name;

INSERT INTO audit.appaal_instance (
	appaal_instance_id,
	appaal_id,
	service_environment_id,		-- new column (service_environment_id)
	file_mode,
	file_owner_account_id,
	file_group_acct_collection_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	ai.appaal_instance_id,
	ai.appaal_id,
	se.service_environment_id,	-- new column (service_environment_id)
	ai.file_mode,
	ai.file_owner_account_id,
	ai.file_group_acct_collection_id,
	ai.data_ins_user,
	ai.data_ins_date,
	ai.data_upd_user,
	ai.data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.appaal_instance_v58 ai
	inner join service_environment se on
		ai.service_environment = se.service_environment_name;

ALTER TABLE appaal_instance
	ALTER appaal_instance_id
	SET DEFAULT nextval('appaal_instance_appaal_instance_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE appaal_instance ADD CONSTRAINT pk_appaal_instance PRIMARY KEY (appaal_instance_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xifappaal_inst_filgrpacctcolid ON appaal_instance USING btree (file_group_acct_collection_id);

-- CHECK CONSTRAINTS
ALTER TABLE appaal_instance ADD CONSTRAINT ckc_file_mode_appaal_i
	CHECK ((file_mode >= 0) AND (file_mode <= 4095));

-- FOREIGN KEYS FROM
-- consider FK appaal_instance and appaal_instance_device_coll
ALTER TABLE appaal_instance_device_coll
	ADD CONSTRAINT fk_appaalins_ref_appaalinsdcol
	FOREIGN KEY (appaal_instance_id) REFERENCES appaal_instance(appaal_instance_id);

-- consider FK appaal_instance and appaal_instance_property
ALTER TABLE appaal_instance_property
	ADD CONSTRAINT fk_appaalins_ref_appaalinsprop
	FOREIGN KEY (appaal_instance_id) REFERENCES appaal_instance(appaal_instance_id);


-- FOREIGN KEYS TO
-- consider FK appaal_instance and account
ALTER TABLE appaal_instance
	ADD CONSTRAINT fk_appaal_i_reference_fo_accti
	FOREIGN KEY (file_owner_account_id) REFERENCES account(account_id);

-- consider FK appaal_instance and service_environment
ALTER TABLE appaal_instance
	ADD CONSTRAINT fk_appaal_i_fk_applic_svcenv
	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);
-- consider FK appaal_instance and account_collection
ALTER TABLE appaal_instance
	ADD CONSTRAINT fk_appaal_inst_filgrpacctcolid
	FOREIGN KEY (file_group_acct_collection_id) REFERENCES account_collection(account_collection_id);

-- consider FK appaal_instance and appaal
ALTER TABLE appaal_instance
	ADD CONSTRAINT fk_appaal_ref_appaal_inst
	FOREIGN KEY (appaal_id) REFERENCES appaal(appaal_id);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'appaal_instance');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'appaal_instance');
ALTER SEQUENCE appaal_instance_appaal_instance_id_seq
	 OWNED BY appaal_instance.appaal_instance_id;
DROP TABLE IF EXISTS appaal_instance_v58;
DROP TABLE IF EXISTS audit.appaal_instance_v58;
-- DONE DEALING WITH TABLE appaal_instance [368503]
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH property collection triggers


/*
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


--
-- $HeadURL$
-- $Id$
--

CREATE OR REPLACE FUNCTION property_collection_hier_enforce()
RETURNS TRIGGER AS $$
DECLARE
	pct	val_property_collection_type%ROWTYPE;
BEGIN
	SELECT *
	INTO	pct
	FROM	val_property_collection_type
	WHERE	property_collection_type =
		(select property_collection_type from property_collection
			where property_collection_id = NEW.parent_property_collection_id);

	IF pct.can_have_hierarchy = 'N' THEN
		RAISE EXCEPTION 'Device Collections of type % may not be hierarcical',
			pct.property_collection_type
			USING ERRCODE= 'unique_violation';
	END IF;
	RETURN NEW;
END;
$$
LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_property_collection_hier_enforce
	 ON property_collection_hier;
CREATE CONSTRAINT TRIGGER trigger_property_collection_hier_enforce
        AFTER INSERT OR UPDATE 
        ON property_collection_hier
		DEFERRABLE INITIALLY IMMEDIATE
        FOR EACH ROW
        EXECUTE PROCEDURE property_collection_hier_enforce();


-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION property_collection_member_enforce()
RETURNS TRIGGER AS $$
DECLARE
	pct	val_property_collection_type%ROWTYPE;
	tally integer;
BEGIN
	SELECT *
	INTO	pct
	FROM	val_property_collection_type
	WHERE	property_collection_type =
		(select property_collection_type from property_collection
			where property_collection_id = NEW.property_collection_id);

	IF pct.MAX_NUM_MEMBERS IS NOT NULL THEN
		select count(*)
		  into tally
		  from property_collection_property
		  where property_collection_id = NEW.property_collection_id;
		IF tally > pct.MAX_NUM_MEMBERS THEN
			RAISE EXCEPTION 'Too many members'
				USING ERRCODE = 'unique_violation';
		END IF;
	END IF;

	IF pct.MAX_NUM_COLLECTIONS IS NOT NULL THEN
		select count(*)
		  into tally
		  from property_collection_property
		  		inner join property_collection using (property_collection_id)
		  where	
				property_name = NEW.property_name
		  and	property_type = NEW.property_typw
		  and	property_collection_type = pct.property_collection_type;
		IF tally > pct.MAX_NUM_COLLECTIONS THEN
			RAISE EXCEPTION 'Device may not be a member of more than % collections of type %',
				pct.MAX_NUM_COLLECTIONS, pct.property_collection_type
				USING ERRCODE = 'unique_violation';
		END IF;
	END IF;

	RETURN NEW;
END;
$$
LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_property_collection_member_enforce
	 ON property_collection_property;
CREATE CONSTRAINT TRIGGER trigger_property_collection_member_enforce
        AFTER INSERT OR UPDATE 
        ON property_collection_property
		DEFERRABLE INITIALLY IMMEDIATE
        FOR EACH ROW
        EXECUTE PROCEDURE property_collection_member_enforce();

-- DONE DEALING WITH property collection triggers
--------------------------------------------------------------------

-- Dropping obsoleted sequences....


-- Dropping obsoleted audit sequences....


-- Processing tables with no structural changes
-- Some of these may be redundant
-- fk constraints
-- triggers


-- Clean Up
SELECT schema_support.replay_saved_grants();
SELECT schema_support.replay_object_recreates();

RAISE EXCEPTION 'Not done';
SELECT schema_support.end_maintenance();
