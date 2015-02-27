--
-- Copyright (c) 2015 Todd Kover
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

/*
Invoked:

	--suffix
	v60
	--scan
	set_slot_names_by_trigger
	create_component_slots_by_trigger
	create_device_component_by_trigger
	net_int_physical_id_to_slot_id_enforce
	pull_password_account_realm_from_account
	device_type_model_to_name
	device_type
	slot
	component_property
	operating_system
	operating_system_snapshot
	account_password
	account_realm_password_type
	val_property
	property
	val_component_property_value
	val_component_property
	physicalish_volume
	logical_volume
	volume_group
	volume_group_physicalish_vol
	volume_group_purpose
	logical_volume_purpose
	val_logical_volume_purpose
	val_physicalish_volume_type
	val_volume_group_purpose
	val_volume_group_type
	network_interface
	device
	physical_connection
	physical_port
	layer1_connection
	val_port_protocol
	val_baud
	val_data_bits
	val_port_speed
	val_stop_bits
	val_port_medium
	val_port_purpose
	val_port_plug_style
	device_type_phys_port_templt
	val_port_protocol_speed
	val_port_type
	device_power_interface
	val_flow_control
	val_power_plug_style
	device_type_power_port_templt
	val_parity
	device_power_connection
	v_l1_all_physical_ports
	v_physical_connection
*/

\set ON_ERROR_STOP
SELECT schema_support.begin_maintenance();
-- Creating new sequences....
CREATE SEQUENCE operating_system_snapshot_operating_system_snapshot_id_seq;

ALTER TABLE ACCOUNT
ADD CONSTRAINT  AK_ACCT_ACCTID_REALM_ID UNIQUE (ACCOUNT_ID,ACCOUNT_REALM_ID);

-- this is just a bad idea.
DELETE FROM account_password where account_id = 1 and password_type = 'des'
	AND password = 'T6r7sdlVHpZH2';

--------------------------------------------------------------------
-- DEALING WITH proc set_slot_names_by_trigger -> set_slot_names_by_trigger 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 2507717
CREATE OR REPLACE FUNCTION jazzhands.set_slot_names_by_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
BEGIN
	PERFORM component_utils.set_slot_names(
		slot_id_list := ARRAY(
				SELECT slot_id FROM slot WHERE component_id = NEW.component_id
			)
	);
	RETURN NEW;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc set_slot_names_by_trigger -> set_slot_names_by_trigger 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc create_component_slots_by_trigger -> create_component_slots_by_trigger 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 2507715
CREATE OR REPLACE FUNCTION jazzhands.create_component_slots_by_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
BEGIN
	PERFORM component_utils.create_component_template_slots(
		component_id := NEW.component_id);
	RETURN NEW;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc create_component_slots_by_trigger -> create_component_slots_by_trigger 
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH proc create_device_component_by_trigger -> create_device_component_by_trigger 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 2507719
CREATE OR REPLACE FUNCTION jazzhands.create_device_component_by_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	devtype		RECORD;
	cid			integer;
BEGIN

	--
	-- If component_id is already set, then assume that it's correct
	--
	IF NEW.component_id THEN
		RETURN NEW;
	END IF;

	SELECT
		dt.device_type_id,
		dt.component_type_id,
		dt.template_device_id,
		d.component_id
	INTO
		devtype
	FROM
		device_type dt LEFT JOIN
		device d ON (dt.template_device_id = d.device_id)
	WHERE
		dt.device_type_id = NEW.device_type_id;

	--
	-- If template_device_id doesn't exist, then create an instance of
	-- the component_id if it exists 
	--
	IF devtype.component_id IS NULL THEN
		--
		-- If the component_id doesn't exist, then we're done
		--
		IF devtype.component_type_id IS NULL THEN
			RETURN NEW;
		END IF;
		--
		-- Insert a component of the given type and tie it to the device
		--
		INSERT INTO component (component_type_id)
			VALUES (devtype.component_type_id)
			RETURNING component_id INTO cid;

		NEW.component_id := cid;
		RETURN NEW;
	ELSE
		--
		-- This is pretty nasty; welcome to SQL
		--
		-- Because we can't return any data from the subselect in the RETURNING
		-- clause of the INSERT within the WITH, we insert a new component for
		-- each member of the source device and return just the component_id.
		--
		-- This returns data into a temporary table (ugh) that's used as a
		-- key/value store to map each template component to the 
		-- newly-created one
		--
		CREATE TEMPORARY TABLE trig_comp_ins AS
		WITH comp_ins AS (
			INSERT INTO component (
				component_type_id
			) SELECT
				c.component_type_id
			FROM
				device_type dt JOIN 
				v_device_components dc ON
					(dc.device_id = dt.template_device_id) JOIN
				component c USING (component_id)
			WHERE
				device_type_id = NEW.device_type_id
			ORDER BY
				level, c.component_type_id
			RETURNING component_id
		)
		SELECT 
			src_comp.component_id as src_component_id,
			dst_comp.component_id as dst_component_id,
			src_comp.level as level
		FROM
			(SELECT
				c.component_id,
				level,
				row_number() OVER (ORDER BY level, c.component_type_id) AS rownum
			 FROM
				device_type dt JOIN 
				v_device_components dc ON
					(dc.device_id = dt.template_device_id) JOIN
				component c USING (component_id)
			 WHERE
				device_type_id = NEW.device_type_id
			) src_comp,
			(SELECT
				component_id,
				row_number() OVER () AS rownum
			 FROM
				comp_ins
			) dst_comp
		WHERE
			src_comp.rownum = dst_comp.rownum;

		/* 
			 Now take the mapping of components that were inserted above, and
			 tie the new components to the appropriate slot on the parent.
			 The logic below is:
				- Take the template component, and locate its parent slot
				- Find the correct slot on the corresponding new parent 
				  component by locating one with the same slot_name and
				  slot_type_id on the mapped parent component_id
				- Update the parent_slot_id of the component with the
				  mapped component_id to this slot_id 
			 
			 This works even if the top-level component is attached to some
			 other device, since there will not be a mapping for those in
			 the table to locate.
		*/
				  
		UPDATE
			component dc
		SET
			parent_slot_id = ds.slot_id
		FROM
			trig_comp_ins tt,
			trig_comp_ins ptt,
			component sc,
			slot ss,
			slot ds
		WHERE
			tt.src_component_id = sc.component_id AND
			tt.dst_component_id = dc.component_id AND
			ss.slot_id = sc.parent_slot_id AND
			ss.component_id = ptt.src_component_id AND
			ds.component_id = ptt.dst_component_id AND
			ss.slot_type_id = ds.slot_type_id AND
			ss.slot_name = ds.slot_name;

		SELECT dst_component_id INTO cid FROM trig_comp_ins WHERE level = 1;

		NEW.component_id := cid;

		DROP TABLE trig_comp_ins;

		RETURN NEW;
	END IF;
	RETURN NEW;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc create_device_component_by_trigger -> create_device_component_by_trigger 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH proc net_int_physical_id_to_slot_id_enforce -> net_int_physical_id_to_slot_id_enforce 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 2507638
CREATE OR REPLACE FUNCTION jazzhands.net_int_physical_id_to_slot_id_enforce()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_tally	INTEGER;
BEGIN
	IF TG_OP = 'UPDATE' AND  (NEW.slot_id IS DISTINCT FROM OLD.slot_ID AND
			NEW.physical_port_id IS DISTINCT FROM OLD.physical_port_id) THEN
		RAISE EXCEPTION 'Only slot_id should be updated.'
			USING ERRCODE = 'integrity_constraint_violation';
	ELSIF TG_OP = 'INSERT' THEN
		IF NEW.physical_port_id IS NOT NULL AND NEW.slot_id IS NOT NULL THEN
			RAISE EXCEPTION 'Only slot_id should be set.'
				USING ERRCODE = 'integrity_constraint_violation';
		END IF;
	 
	END IF;

	IF TG_OP = 'UPDATE' THEN
		IF OLD.slot_id IS DISTINCT FROM NEW.slot_id THEN
			NEW.physical_port_id = NEW.slot_id;
		ELSIF OLD.physical_port_id IS DISTINCT FROM NEW.physical_port_id THEN
			NEW.slot_id = NEW.physical_port_id;
		END IF;
	ELSIF TG_OP = 'INSERT' THEN
		IF NEW.slot_id IS NOT NULL THEN
			NEW.physical_port_id = NEW.slot_id;
		ELSIF NEW.physical_port_id IS NOT NULL THEN
			NEW.slot_id = NEW.physical_port_id;
		END IF;
	ELSE
	END IF;
	RETURN NEW;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc net_int_physical_id_to_slot_id_enforce -> net_int_physical_id_to_slot_id_enforce 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc pull_password_account_realm_from_account -> pull_password_account_realm_from_account 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 2507580
CREATE OR REPLACE FUNCTION jazzhands.pull_password_account_realm_from_account()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
BEGIN
	IF TG_OP = 'INSERT' THEN
		IF NEW.account_realm_id IS NULL THEN
			SELECT account_realm_id
			INTO	NEW.account_realm_id
			FROM	account
			WHERE	account_id = NEW.account_id;
		END IF;
	ELSIF NEW.account_realm_id = OLD.account_realm_id THEN
		IF NEW.account_realm_id IS NULL THEN
			SELECT account_realm_id
			INTO	NEW.account_realm_id
			FROM	account
			WHERE	account_id = NEW.account_id;
		END IF;
	END IF;
	RETURN NEW;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc pull_password_account_realm_from_account -> pull_password_account_realm_from_account 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc device_type_model_to_name -> device_type_model_to_name 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 2507606
CREATE OR REPLACE FUNCTION jazzhands.device_type_model_to_name()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_tally	INTEGER;
BEGIN
	IF TG_OP = 'UPDATE' AND  (NEW.model IS DISTINCT FROM OLD.model AND
			NEW.device_type_name IS DISTINCT FROM OLD.device_type_name) THEN
		RAISE EXCEPTION 'Only device_type_name should be updated.'
			USING ERRCODE = 'integrity_constraint_violation';
	ELSIF TG_OP = 'INSERT' THEN
		IF NEW.model IS NOT NULL AND NEW.device_type_name IS NOT NULL THEN
			RAISE EXCEPTION 'Only model should be set.'
				USING ERRCODE = 'integrity_constraint_violation';
		END IF;
	 
	END IF;

	IF TG_OP = 'UPDATE' THEN
		IF OLD.model IS DISTINCT FROM NEW.model THEN
			NEW.device_type_name = NEW.model;
		ELSIF OLD.device_type_name IS DISTINCT FROM NEW.device_type_name THEN
			NEW.model = NEW.device_type_name;
		END IF;
	ELSIF TG_OP = 'INSERT' THEN
		IF NEW.model IS NOT NULL THEN
			NEW.device_type_name = NEW.model;
		ELSIF NEW.device_type_name IS NOT NULL THEN
			NEW.model = NEW.device_type_name;
		END IF;
	ELSE
	END IF;

	-- company_id is going away
	IF NEW.company_id IS NULL THEN
		NEW.company_id := 0;
	END IF;

	RETURN NEW;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc device_type_model_to_name -> device_type_model_to_name 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH TABLE device_type [2460594]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'device_type', 'device_type');

-- FOREIGN KEYS FROM
ALTER TABLE chassis_location DROP CONSTRAINT IF EXISTS fk_chass_loc_mod_dev_typ_id;
ALTER TABLE device_type_module DROP CONSTRAINT IF EXISTS fk_devt_mod_dev_type_id;
ALTER TABLE device_type_power_port_templt DROP CONSTRAINT IF EXISTS fk_dev_type_dev_pwr_prt_tmpl;
ALTER TABLE device DROP CONSTRAINT IF EXISTS fk_dev_devtp_id;
ALTER TABLE device_type_module_device_type DROP CONSTRAINT IF EXISTS fk_dt_mod_dev_type_mod_dtid;
ALTER TABLE device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_devtype_ref_devtphysprttmpl;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS fk_fevtyp_component_id;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS fk_devtyp_company;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS fk_device_t_fk_device_val_proc;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'device_type');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS pk_device_type;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_fevtyp_component_id";
DROP INDEX IF EXISTS "jazzhands"."xif4device_type";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS ckc_has_802_11_interf_device_t;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS ckc_has_802_3_interfa_device_t;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS ckc_devtyp_ischs;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS ckc_snmp_capable_device_t;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_device_type ON jazzhands.device_type;
DROP TRIGGER IF EXISTS trigger_audit_device_type ON jazzhands.device_type;
DROP TRIGGER IF EXISTS trigger_device_type_chassis_check ON jazzhands.device_type;
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


ALTER TABLE device_type RENAME TO device_type_v60;
ALTER TABLE audit.device_type RENAME TO device_type_v60;

CREATE TABLE device_type
(
	device_type_id	integer NOT NULL,
	component_type_id	integer  NULL,
	device_type_name	varchar(50) NOT NULL,
	template_device_id	integer  NULL,
	description	varchar(4000)  NULL,
	company_id	integer  NULL,
	model	varchar(255) NOT NULL,
	device_type_depth_in_cm	character(18)  NULL,
	processor_architecture	varchar(50)  NULL,
	config_fetch_type	varchar(50)  NULL,
	rack_units	integer  NULL,
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
	ALTER has_802_3_interface
	SET DEFAULT 'N'::bpchar;
ALTER TABLE device_type
	ALTER has_802_11_interface
	SET DEFAULT 'N'::bpchar;
ALTER TABLE device_type
	ALTER snmp_capable
	SET DEFAULT 'N'::bpchar;
ALTER TABLE device_type
	ALTER is_chassis
	SET DEFAULT 'N'::bpchar;
INSERT INTO device_type (
	device_type_id,
	component_type_id,
	device_type_name,		-- new column (device_type_name)
	template_device_id,		-- new column (template_device_id)
	description,
	company_id,
	model,
	device_type_depth_in_cm,
	processor_architecture,
	config_fetch_type,
	rack_units,
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
	component_type_id,
	model,		-- new column (device_type_name)
	NULL,		-- new column (template_device_id)
	description,
	company_id,
	model,
	device_type_depth_in_cm,
	processor_architecture,
	config_fetch_type,
	rack_units,
	has_802_3_interface,
	has_802_11_interface,
	snmp_capable,
	is_chassis,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM device_type_v60;

INSERT INTO audit.device_type (
	device_type_id,
	component_type_id,
	device_type_name,		-- new column (device_type_name)
	template_device_id,		-- new column (template_device_id)
	description,
	company_id,
	model,
	device_type_depth_in_cm,
	processor_architecture,
	config_fetch_type,
	rack_units,
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
	component_type_id,
	model,		-- new column (device_type_name)
	NULL,		-- new column (template_device_id)
	description,
	company_id,
	model,
	device_type_depth_in_cm,
	processor_architecture,
	config_fetch_type,
	rack_units,
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
FROM audit.device_type_v60;

ALTER TABLE device_type
	ALTER device_type_id
	SET DEFAULT nextval('device_type_device_type_id_seq'::regclass);
ALTER TABLE device_type
	ALTER has_802_3_interface
	SET DEFAULT 'N'::bpchar;
ALTER TABLE device_type
	ALTER has_802_11_interface
	SET DEFAULT 'N'::bpchar;
ALTER TABLE device_type
	ALTER snmp_capable
	SET DEFAULT 'N'::bpchar;
ALTER TABLE device_type
	ALTER is_chassis
	SET DEFAULT 'N'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE device_type ADD CONSTRAINT ak_device_type_device_type_nam UNIQUE (device_type_name);
ALTER TABLE device_type ADD CONSTRAINT pk_device_type PRIMARY KEY (device_type_id);

-- Table/Column Comments
COMMENT ON TABLE device_type IS 'Conceptual device type.  This represents how it is typically referred to rather than a specific model INTEGER.  There may be many models (components) that are represented by one device type.';
COMMENT ON COLUMN device_type.component_type_id IS 'reference to the type of hardware that underlies this type';
COMMENT ON COLUMN device_type.device_type_name IS 'Human readable name of the device type.  The company and a model can be gleaned from component.';
COMMENT ON COLUMN device_type.template_device_id IS 'foreign key to a device that represents the typical/initial/minimum configuration of a given device type.  This device is typically non real but a template.';
-- INDEXES
CREATE INDEX xif4device_type ON device_type USING btree (company_id);
CREATE INDEX xif_fevtyp_component_id ON device_type USING btree (component_type_id);
CREATE INDEX xif_dev_typ_tmplt_dev_typ_id ON device_type USING btree (template_device_id);

-- CHECK CONSTRAINTS
ALTER TABLE device_type ADD CONSTRAINT ckc_has_802_11_interf_device_t
	CHECK (has_802_11_interface = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE device_type ADD CONSTRAINT ckc_has_802_3_interfa_device_t
	CHECK (has_802_3_interface = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE device_type ADD CONSTRAINT ckc_devtyp_ischs
	CHECK (is_chassis = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE device_type ADD CONSTRAINT ckc_snmp_capable_device_t
	CHECK (snmp_capable = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK device_type and device
ALTER TABLE device
	ADD CONSTRAINT fk_dev_devtp_id
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device_type and device_type_module_device_type
ALTER TABLE device_type_module_device_type
	ADD CONSTRAINT fk_dt_mod_dev_type_mod_dtid
	FOREIGN KEY (module_device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device_type and chassis_location
ALTER TABLE chassis_location
	ADD CONSTRAINT fk_chass_loc_mod_dev_typ_id
	FOREIGN KEY (module_device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device_type and device_type_module
ALTER TABLE device_type_module
	ADD CONSTRAINT fk_devt_mod_dev_type_id
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);

-- FOREIGN KEYS TO
-- consider FK device_type and val_processor_architecture
ALTER TABLE device_type
	ADD CONSTRAINT fk_device_t_fk_device_val_proc
	FOREIGN KEY (processor_architecture) REFERENCES val_processor_architecture(processor_architecture);
-- consider FK device_type and company
ALTER TABLE device_type
	ADD CONSTRAINT fk_devtyp_company
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;
-- consider FK device_type and component_type
ALTER TABLE device_type
	ADD CONSTRAINT fk_fevtyp_component_id
	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);
-- consider FK device_type and device
ALTER TABLE device_type
	ADD CONSTRAINT fk_dev_typ_tmplt_dev_typ_id
	FOREIGN KEY (template_device_id) REFERENCES device(device_id);

-- TRIGGERS
CREATE TRIGGER trigger_device_type_chassis_check BEFORE UPDATE OF is_chassis ON device_type FOR EACH ROW EXECUTE PROCEDURE device_type_chassis_check();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_device_type_model_to_name BEFORE INSERT OR UPDATE OF device_type_name, model ON device_type FOR EACH ROW EXECUTE PROCEDURE device_type_model_to_name();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'device_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'device_type');
ALTER SEQUENCE device_type_device_type_id_seq
	 OWNED BY device_type.device_type_id;
DROP TABLE IF EXISTS device_type_v60;
DROP TABLE IF EXISTS audit.device_type_v60;
-- DONE DEALING WITH TABLE device_type [2500050]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE slot [2461543]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'slot', 'slot');

-- FOREIGN KEYS FROM
ALTER TABLE inter_component_connection DROP CONSTRAINT IF EXISTS fk_intercomp_conn_slot1_id;
ALTER TABLE logical_port_slot DROP CONSTRAINT IF EXISTS fk_lgl_port_slot_slot_id;
ALTER TABLE component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_slt_slt_id;
ALTER TABLE component DROP CONSTRAINT IF EXISTS fk_component_prnt_slt_id;
ALTER TABLE inter_component_connection DROP CONSTRAINT IF EXISTS fk_intercomp_conn_slot2_id;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.slot DROP CONSTRAINT IF EXISTS fk_slot_cmp_typ_tmp_id;
ALTER TABLE jazzhands.slot DROP CONSTRAINT IF EXISTS fk_slot_component_id;
ALTER TABLE jazzhands.slot DROP CONSTRAINT IF EXISTS fk_slot_slot_type_id;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'slot');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.slot DROP CONSTRAINT IF EXISTS pk_slot_id;
ALTER TABLE jazzhands.slot DROP CONSTRAINT IF EXISTS ak_slot_slot_type_id;
ALTER TABLE jazzhands.slot DROP CONSTRAINT IF EXISTS uq_slot_cmp_slt_tmplt_id;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_slot_cmp_typ_tmp_id";
DROP INDEX IF EXISTS "jazzhands"."xif_slot_slot_type_id";
DROP INDEX IF EXISTS "jazzhands"."xif_slot_component_id";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.slot DROP CONSTRAINT IF EXISTS ckc_slot_slot_side;
ALTER TABLE jazzhands.slot DROP CONSTRAINT IF EXISTS checkslot_enbled__yes_no;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_slot ON jazzhands.slot;
DROP TRIGGER IF EXISTS trigger_audit_slot ON jazzhands.slot;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'slot');
---- BEGIN audit.slot TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'slot');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."slot_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'slot');
---- DONE audit.slot TEARDOWN


ALTER TABLE slot RENAME TO slot_v60;
ALTER TABLE audit.slot RENAME TO slot_v60;

CREATE TABLE slot
(
	slot_id	integer NOT NULL,
	component_id	integer NOT NULL,
	slot_name	varchar(50) NOT NULL,
	slot_index	integer  NULL,
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
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'slot', false);
ALTER TABLE slot
	ALTER slot_id
	SET DEFAULT nextval('slot_slot_id_seq'::regclass);
ALTER TABLE slot
	ALTER is_enabled
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE slot
	ALTER slot_side
	SET DEFAULT 'FRONT'::character varying;
INSERT INTO slot (
	slot_id,
	component_id,
	slot_name,
	slot_index,		-- new column (slot_index)
	slot_type_id,
	component_type_slot_tmplt_id,
	is_enabled,
	physical_label,
	description,
	slot_x_offset,
	slot_y_offset,
	slot_z_offset,
	slot_side,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	slot_id,
	component_id,
	slot_name,
	NULL,		-- new column (slot_index)
	slot_type_id,
	component_type_slot_tmplt_id,
	is_enabled,
	physical_label,
	description,
	slot_x_offset,
	slot_y_offset,
	slot_z_offset,
	slot_side,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM slot_v60;

INSERT INTO audit.slot (
	slot_id,
	component_id,
	slot_name,
	slot_index,		-- new column (slot_index)
	slot_type_id,
	component_type_slot_tmplt_id,
	is_enabled,
	physical_label,
	description,
	slot_x_offset,
	slot_y_offset,
	slot_z_offset,
	slot_side,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	slot_id,
	component_id,
	slot_name,
	NULL,		-- new column (slot_index)
	slot_type_id,
	component_type_slot_tmplt_id,
	is_enabled,
	physical_label,
	description,
	slot_x_offset,
	slot_y_offset,
	slot_z_offset,
	slot_side,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.slot_v60;

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
ALTER TABLE slot ADD CONSTRAINT uq_slot_cmp_slt_tmplt_id UNIQUE (component_id, component_type_slot_tmplt_id);
ALTER TABLE slot ADD CONSTRAINT pk_slot_id PRIMARY KEY (slot_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_slot_cmp_typ_tmp_id ON slot USING btree (component_type_slot_tmplt_id);
CREATE INDEX xif_slot_slot_type_id ON slot USING btree (slot_type_id);
CREATE INDEX xif_slot_component_id ON slot USING btree (component_id);

-- CHECK CONSTRAINTS
ALTER TABLE slot ADD CONSTRAINT ckc_slot_slot_side
	CHECK ((slot_side)::text = ANY ((ARRAY['FRONT'::character varying, 'BACK'::character varying])::text[]));
ALTER TABLE slot ADD CONSTRAINT checkslot_enbled__yes_no
	CHECK (is_enabled = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK slot and network_interface
ALTER TABLE network_interface
	ADD CONSTRAINT fk_net_int_phys_port_id
	FOREIGN KEY (physical_port_id) REFERENCES slot(slot_id);
-- consider FK slot and physical_connection
--ALTER TABLE physical_connection
--	ADD CONSTRAINT fk_physconn_slot2_id
--	FOREIGN KEY (slot2_id) REFERENCES slot(slot_id);
-- consider FK slot and physical_connection
--ALTER TABLE physical_connection
--	ADD CONSTRAINT fk_physconn_slot1_id
--	FOREIGN KEY (slot1_id) REFERENCES slot(slot_id);
-- consider FK slot and inter_component_connection
ALTER TABLE inter_component_connection
	ADD CONSTRAINT fk_intercomp_conn_slot1_id
	FOREIGN KEY (slot1_id) REFERENCES slot(slot_id);
-- consider FK slot and inter_component_connection
ALTER TABLE inter_component_connection
	ADD CONSTRAINT fk_intercomp_conn_slot2_id
	FOREIGN KEY (slot2_id) REFERENCES slot(slot_id);
-- consider FK slot and component
ALTER TABLE component
	ADD CONSTRAINT fk_component_prnt_slt_id
	FOREIGN KEY (parent_slot_id) REFERENCES slot(slot_id);
-- consider FK slot and logical_port_slot
ALTER TABLE logical_port_slot
	ADD CONSTRAINT fk_lgl_port_slot_slot_id
	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);
-- consider FK slot and component_property
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_slt_slt_id
	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);
-- consider FK slot and network_interface
--ALTER TABLE network_interface
--	ADD CONSTRAINT fk_netint_slot_id
--	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);

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
ALTER TABLE slot
	ADD CONSTRAINT fk_slot_component_id
	FOREIGN KEY (component_id) REFERENCES component(component_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'slot');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'slot');
ALTER SEQUENCE slot_slot_id_seq
	 OWNED BY slot.slot_id;
DROP TABLE IF EXISTS slot_v60;
DROP TABLE IF EXISTS audit.slot_v60;
-- DONE DEALING WITH TABLE slot [2500964]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE component_property [2460318]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'component_property', 'component_property');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_slt_typ_id;
ALTER TABLE jazzhands.component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_slt_slt_id;
ALTER TABLE jazzhands.component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_comp_typ_id;
ALTER TABLE jazzhands.component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_sltfuncid;
ALTER TABLE jazzhands.component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_cmp_id;
ALTER TABLE jazzhands.component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_prop_nmty;
ALTER TABLE jazzhands.component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_comp_func;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'component_property');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.component_property DROP CONSTRAINT IF EXISTS pk_component_property;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_comp_prop_prop_nmty";
DROP INDEX IF EXISTS "jazzhands"."xif_comp_prop_comp_func";
DROP INDEX IF EXISTS "jazzhands"."xif_comp_prop_sltfuncid";
DROP INDEX IF EXISTS "jazzhands"."xif_comp_prop_comp_typ_id";
DROP INDEX IF EXISTS "jazzhands"."xif_comp_prop_slt_slt_id";
DROP INDEX IF EXISTS "jazzhands"."xif_comp_prop_cmp_id";
DROP INDEX IF EXISTS "jazzhands"."xif_comp_prop_slt_typ_id";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_validate_component_property ON jazzhands.component_property;
DROP TRIGGER IF EXISTS trig_userlog_component_property ON jazzhands.component_property;
DROP TRIGGER IF EXISTS trigger_audit_component_property ON jazzhands.component_property;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'component_property');
---- BEGIN audit.component_property TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'component_property');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."component_property_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'component_property');
---- DONE audit.component_property TEARDOWN


ALTER TABLE component_property RENAME TO component_property_v60;
ALTER TABLE audit.component_property RENAME TO component_property_v60;

CREATE TABLE component_property
(
	component_property_id	integer NOT NULL,
	component_function	varchar(50)  NULL,
	component_type_id	integer  NULL,
	component_id	integer  NULL,
	inter_component_connection_id	integer  NULL,
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
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'component_property', false);
ALTER TABLE component_property
	ALTER component_property_id
	SET DEFAULT nextval('component_property_component_property_id_seq'::regclass);
INSERT INTO component_property (
	component_property_id,
	component_function,
	component_type_id,
	component_id,
	inter_component_connection_id,		-- new column (inter_component_connection_id)
	slot_function,
	slot_type_id,
	slot_id,
	component_property_name,
	component_property_type,
	property_value,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	component_property_id,
	component_function,
	component_type_id,
	component_id,
	NULL,		-- new column (inter_component_connection_id)
	slot_function,
	slot_type_id,
	slot_id,
	component_property_name,
	component_property_type,
	property_value,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM component_property_v60;

INSERT INTO audit.component_property (
	component_property_id,
	component_function,
	component_type_id,
	component_id,
	inter_component_connection_id,		-- new column (inter_component_connection_id)
	slot_function,
	slot_type_id,
	slot_id,
	component_property_name,
	component_property_type,
	property_value,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	component_property_id,
	component_function,
	component_type_id,
	component_id,
	NULL,		-- new column (inter_component_connection_id)
	slot_function,
	slot_type_id,
	slot_id,
	component_property_name,
	component_property_type,
	property_value,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.component_property_v60;

ALTER TABLE component_property
	ALTER component_property_id
	SET DEFAULT nextval('component_property_component_property_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE component_property ADD CONSTRAINT pk_component_property PRIMARY KEY (component_property_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_comp_prop_slt_slt_id ON component_property USING btree (slot_id);
CREATE INDEX xif_comp_prop_comp_func ON component_property USING btree (component_function);
CREATE INDEX xif_comp_prop_cmp_id ON component_property USING btree (component_id);
CREATE INDEX xif_comp_prop_comp_typ_id ON component_property USING btree (component_type_id);
CREATE INDEX xif_comp_prop_sltfuncid ON component_property USING btree (slot_function);
CREATE INDEX xif8component_property ON component_property USING btree (inter_component_connection_id);
CREATE INDEX xif_comp_prop_prop_nmty ON component_property USING btree (component_property_name, component_property_type);
CREATE INDEX xif_comp_prop_slt_typ_id ON component_property USING btree (slot_type_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK component_property and val_slot_function
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_sltfuncid
	FOREIGN KEY (slot_function) REFERENCES val_slot_function(slot_function);
-- consider FK component_property and component
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_cmp_id
	FOREIGN KEY (component_id) REFERENCES component(component_id);
-- consider FK component_property and slot_type
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_slt_typ_id
	FOREIGN KEY (slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK component_property and component_type
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_comp_typ_id
	FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id);
-- consider FK component_property and val_component_property
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_prop_nmty
	FOREIGN KEY (component_property_name, component_property_type) REFERENCES val_component_property(component_property_name, component_property_type);
-- consider FK component_property and val_component_function
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_comp_func
	FOREIGN KEY (component_function) REFERENCES val_component_function(component_function);
-- consider FK component_property and inter_component_connection
ALTER TABLE component_property
	ADD CONSTRAINT r_680
	FOREIGN KEY (inter_component_connection_id) REFERENCES inter_component_connection(inter_component_connection_id);
-- consider FK component_property and slot
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_slt_slt_id
	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);

-- TRIGGERS
CREATE CONSTRAINT TRIGGER trigger_validate_component_property AFTER INSERT OR UPDATE ON component_property DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE validate_component_property();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'component_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'component_property');
ALTER SEQUENCE component_property_component_property_id_seq
	 OWNED BY component_property.component_property_id;
DROP TABLE IF EXISTS component_property_v60;
DROP TABLE IF EXISTS audit.component_property_v60;
-- DONE DEALING WITH TABLE component_property [2499798]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE operating_system [2461117]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'operating_system', 'operating_system');

-- FOREIGN KEYS FROM
ALTER TABLE property DROP CONSTRAINT IF EXISTS fk_property_osid;
ALTER TABLE operating_system_snapshot DROP CONSTRAINT IF EXISTS fk_os_snap_osid;
ALTER TABLE device DROP CONSTRAINT IF EXISTS fk_dev_os_id;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.operating_system DROP CONSTRAINT IF EXISTS fk_os_ref_swpkgrepos;
ALTER TABLE jazzhands.operating_system DROP CONSTRAINT IF EXISTS fk_os_os_family;
ALTER TABLE jazzhands.operating_system DROP CONSTRAINT IF EXISTS fk_os_company;
ALTER TABLE jazzhands.operating_system DROP CONSTRAINT IF EXISTS fk_os_fk_val_dev_arch;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'operating_system');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.operating_system DROP CONSTRAINT IF EXISTS pk_operating_system;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_os_company";
DROP INDEX IF EXISTS "jazzhands"."xif_os_os_family";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_operating_system ON jazzhands.operating_system;
DROP TRIGGER IF EXISTS trigger_audit_operating_system ON jazzhands.operating_system;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'operating_system');
---- BEGIN audit.operating_system TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'operating_system');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."operating_system_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'operating_system');
---- DONE audit.operating_system TEARDOWN


ALTER TABLE operating_system RENAME TO operating_system_v60;
ALTER TABLE audit.operating_system RENAME TO operating_system_v60;

CREATE TABLE operating_system
(
	operating_system_id	integer NOT NULL,
	operating_system_name	varchar(255) NOT NULL,
	company_id	integer  NULL,
	major_version	varchar(50) NOT NULL,
	version	varchar(255) NOT NULL,
	operating_system_family	varchar(50)  NULL,
	processor_architecture	varchar(50)  NULL,
	sw_package_repository_id	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'operating_system', false);
ALTER TABLE operating_system
	ALTER operating_system_id
	SET DEFAULT nextval('operating_system_operating_system_id_seq'::regclass);
INSERT INTO operating_system (
	operating_system_id,
	operating_system_name,
	company_id,
	major_version,
	version,
	operating_system_family,
	processor_architecture,
	sw_package_repository_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	operating_system_id,
	operating_system_name,
	company_id,
	major_version,
	version,
	operating_system_family,
	processor_architecture,
	sw_package_repository_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM operating_system_v60;

INSERT INTO audit.operating_system (
	operating_system_id,
	operating_system_name,
	company_id,
	major_version,
	version,
	operating_system_family,
	processor_architecture,
	sw_package_repository_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	operating_system_id,
	operating_system_name,
	company_id,
	major_version,
	version,
	operating_system_family,
	processor_architecture,
	sw_package_repository_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.operating_system_v60;

ALTER TABLE operating_system
	ALTER operating_system_id
	SET DEFAULT nextval('operating_system_operating_system_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE operating_system ADD CONSTRAINT pk_operating_system PRIMARY KEY (operating_system_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_os_os_family ON operating_system USING btree (operating_system_family);
CREATE INDEX xif_os_company ON operating_system USING btree (company_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK operating_system and property
ALTER TABLE property
	ADD CONSTRAINT fk_property_osid
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);
-- consider FK operating_system and operating_system_snapshot
ALTER TABLE operating_system_snapshot
	ADD CONSTRAINT fk_os_snap_osid
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);
-- consider FK operating_system and device
ALTER TABLE device
	ADD CONSTRAINT fk_dev_os_id
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);

-- FOREIGN KEYS TO
-- consider FK operating_system and val_operating_system_family
ALTER TABLE operating_system
	ADD CONSTRAINT fk_os_os_family
	FOREIGN KEY (operating_system_family) REFERENCES val_operating_system_family(operating_system_family);
-- consider FK operating_system and sw_package_repository
ALTER TABLE operating_system
	ADD CONSTRAINT fk_os_ref_swpkgrepos
	FOREIGN KEY (sw_package_repository_id) REFERENCES sw_package_repository(sw_package_repository_id);
-- consider FK operating_system and val_processor_architecture
ALTER TABLE operating_system
	ADD CONSTRAINT fk_os_fk_val_dev_arch
	FOREIGN KEY (processor_architecture) REFERENCES val_processor_architecture(processor_architecture);
-- consider FK operating_system and company
ALTER TABLE operating_system
	ADD CONSTRAINT fk_os_company
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'operating_system');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'operating_system');
ALTER SEQUENCE operating_system_operating_system_id_seq
	 OWNED BY operating_system.operating_system_id;
DROP TABLE IF EXISTS operating_system_v60;
DROP TABLE IF EXISTS audit.operating_system_v60;
-- DONE DEALING WITH TABLE operating_system [2500553]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE operating_system_snapshot [2461128]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'operating_system_snapshot', 'operating_system_snapshot');

-- FOREIGN KEYS FROM
ALTER TABLE property DROP CONSTRAINT IF EXISTS fk_prop_os_snapshot;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.operating_system_snapshot DROP CONSTRAINT IF EXISTS fk_os_snap_osid;
ALTER TABLE jazzhands.operating_system_snapshot DROP CONSTRAINT IF EXISTS fk_os_snap_snap_type;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'operating_system_snapshot');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.operating_system_snapshot DROP CONSTRAINT IF EXISTS ak_os_snap_name_type;
ALTER TABLE jazzhands.operating_system_snapshot DROP CONSTRAINT IF EXISTS pk_val_operating_system_snapsh;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_os_snap_snap_type";
DROP INDEX IF EXISTS "jazzhands"."xif_os_snap_osid";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_operating_system_snapshot ON jazzhands.operating_system_snapshot;
DROP TRIGGER IF EXISTS trigger_audit_operating_system_snapshot ON jazzhands.operating_system_snapshot;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'operating_system_snapshot');
---- BEGIN audit.operating_system_snapshot TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'operating_system_snapshot');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."operating_system_snapshot_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'operating_system_snapshot');
---- DONE audit.operating_system_snapshot TEARDOWN


ALTER TABLE operating_system_snapshot RENAME TO operating_system_snapshot_v60;
ALTER TABLE audit.operating_system_snapshot RENAME TO operating_system_snapshot_v60;

CREATE TABLE operating_system_snapshot
(
	operating_system_snapshot_id	integer NOT NULL,
	operating_system_snapshot_name	varchar(255) NOT NULL,
	operating_system_snapshot_type	varchar(50) NOT NULL,
	operating_system_id	integer NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'operating_system_snapshot', false);
ALTER TABLE operating_system_snapshot
	ALTER operating_system_snapshot_id
	SET DEFAULT nextval('operating_system_snapshot_operating_system_snapshot_id_seq'::regclass);
INSERT INTO operating_system_snapshot (
	operating_system_snapshot_id,
	operating_system_snapshot_name,
	operating_system_snapshot_type,
	operating_system_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	operating_system_snapshot_id,
	operating_system_snapshot_name,
	operating_system_snapshot_type,
	operating_system_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM operating_system_snapshot_v60;

INSERT INTO audit.operating_system_snapshot (
	operating_system_snapshot_id,
	operating_system_snapshot_name,
	operating_system_snapshot_type,
	operating_system_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	operating_system_snapshot_id,
	operating_system_snapshot_name,
	operating_system_snapshot_type,
	operating_system_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.operating_system_snapshot_v60;

ALTER TABLE operating_system_snapshot
	ALTER operating_system_snapshot_id
	SET DEFAULT nextval('operating_system_snapshot_operating_system_snapshot_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE operating_system_snapshot ADD CONSTRAINT pk_val_operating_system_snapsh PRIMARY KEY (operating_system_snapshot_id);
ALTER TABLE operating_system_snapshot ADD CONSTRAINT ak_os_snap_name_type UNIQUE (operating_system_id, operating_system_snapshot_name, operating_system_snapshot_type);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_os_snap_osid ON operating_system_snapshot USING btree (operating_system_id);
CREATE INDEX xif_os_snap_snap_type ON operating_system_snapshot USING btree (operating_system_snapshot_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK operating_system_snapshot and property
ALTER TABLE property
	ADD CONSTRAINT fk_prop_os_snapshot
	FOREIGN KEY (operating_system_snapshot_id) REFERENCES operating_system_snapshot(operating_system_snapshot_id);

-- FOREIGN KEYS TO
-- consider FK operating_system_snapshot and val_os_snapshot_type
ALTER TABLE operating_system_snapshot
	ADD CONSTRAINT fk_os_snap_snap_type
	FOREIGN KEY (operating_system_snapshot_type) REFERENCES val_os_snapshot_type(operating_system_snapshot_type);
-- consider FK operating_system_snapshot and operating_system
ALTER TABLE operating_system_snapshot
	ADD CONSTRAINT fk_os_snap_osid
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'operating_system_snapshot');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'operating_system_snapshot');
ALTER SEQUENCE operating_system_snapshot_operating_system_snapshot_id_seq
	 OWNED BY operating_system_snapshot.operating_system_snapshot_id;
DROP TABLE IF EXISTS operating_system_snapshot_v60;
DROP TABLE IF EXISTS audit.operating_system_snapshot_v60;
-- DONE DEALING WITH TABLE operating_system_snapshot [2500566]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE account_password [2460078]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'account_password', 'account_password');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.account_password DROP CONSTRAINT IF EXISTS fk_system_pass_ref_vpasstype;
ALTER TABLE jazzhands.account_password DROP CONSTRAINT IF EXISTS fk_system_password;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'account_password');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.account_password DROP CONSTRAINT IF EXISTS pk_system_password;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_account_password ON jazzhands.account_password;
DROP TRIGGER IF EXISTS trigger_audit_account_password ON jazzhands.account_password;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'account_password');
---- BEGIN audit.account_password TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'account_password');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."account_password_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'account_password');
---- DONE audit.account_password TEARDOWN


ALTER TABLE account_password RENAME TO account_password_v60;
ALTER TABLE audit.account_password RENAME TO account_password_v60;

CREATE TABLE account_password
(
	account_id	integer NOT NULL,
	account_realm_id	integer NOT NULL,
	password_type	varchar(50) NOT NULL,
	password	varchar(255) NOT NULL,
	change_time	timestamp with time zone  NULL,
	expire_time	timestamp with time zone  NULL,
	unlock_time	timestamp with time zone  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'account_password', false);
INSERT INTO account_password (
	account_id,
	account_realm_id,		-- new column (account_realm_id)
	password_type,
	password,
	change_time,
	expire_time,
	unlock_time,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	ap.account_id,
	a.account_realm_id,		-- new column (account_realm_id)
	ap.password_type,
	ap.password,
	ap.change_time,
	ap.expire_time,
	ap.unlock_time,
	ap.data_ins_user,
	ap.data_ins_date,
	ap.data_upd_user,
	ap.data_upd_date
FROM account_password_v60 ap
	join account a using (account_id);

INSERT INTO audit.account_password (
	account_id,
	account_realm_id,		-- new column (account_realm_id)
	password_type,
	password,
	change_time,
	expire_time,
	unlock_time,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	ap.account_id,
	a.account_id,		-- new column (account_realm_id)
	ap.password_type,
	ap.password,
	ap.change_time,
	ap.expire_time,
	ap.unlock_time,
	ap.data_ins_user,
	ap.data_ins_date,
	ap.data_upd_user,
	ap.data_upd_date,
	ap."aud#action",
	ap."aud#timestamp",
	ap."aud#user",
	ap."aud#seq"
FROM audit.account_password_v60 ap
	join account a using (account_id);


-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE account_password ADD CONSTRAINT pk_accunt_password PRIMARY KEY (account_id, account_realm_id, password_type);

-- Table/Column Comments
COMMENT ON COLUMN account_password.account_realm_id IS 'Set to allow enforcement of password type/account_realm_id.   Largely managed in the background by trigger';
COMMENT ON COLUMN account_password.change_time IS 'The last thie this password was changed';
COMMENT ON COLUMN account_password.expire_time IS 'The time this password expires, if different from the default';
COMMENT ON COLUMN account_password.unlock_time IS 'indicates the time that the password is unlocked and can thus be changed; NULL means the password can be changed.  This is application enforced.';
-- INDEXES
CREATE INDEX xif_acctpwd_acct_id ON account_password USING btree (account_id, account_realm_id);
CREATE INDEX xif_acct_pwd_acct_realm ON account_password USING btree (account_realm_id);
CREATE INDEX xif_acct_pwd_relm_type ON account_password USING btree (password_type, account_realm_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK account_password and account
ALTER TABLE account_password
	ADD CONSTRAINT fk_acctpwd_acct_id
	FOREIGN KEY (account_id, account_realm_id) REFERENCES account(account_id, account_realm_id);
-- consider FK account_password and val_password_type
ALTER TABLE account_password
	ADD CONSTRAINT fk_acct_pass_ref_vpasstype
	FOREIGN KEY (password_type) REFERENCES val_password_type(password_type);
-- consider FK account_password and account_realm_password_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE account_password
--	ADD CONSTRAINT fk_acct_pwd_realm_type
--	FOREIGN KEY (password_type, account_realm_id) REFERENCES account_realm_password_type(password_type, account_realm_id);

-- consider FK account_password and account_realm
ALTER TABLE account_password
	ADD CONSTRAINT fk_acct_pwd_acct_realm
	FOREIGN KEY (account_realm_id) REFERENCES account_realm(account_realm_id);

-- TRIGGERS
CREATE TRIGGER trigger_pull_password_account_realm_from_account BEFORE INSERT OR UPDATE OF account_id ON account_password FOR EACH ROW EXECUTE PROCEDURE pull_password_account_realm_from_account();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'account_password');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'account_password');
DROP TABLE IF EXISTS account_password_v60;
DROP TABLE IF EXISTS audit.account_password_v60;
-- DONE DEALING WITH TABLE account_password [2499546]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE account_realm_password_type
CREATE TABLE account_realm_password_type
(
	password_type	varchar(50) NOT NULL,
	account_realm_id	integer NOT NULL,
	description	varchar(255)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'account_realm_password_type', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE account_realm_password_type ADD CONSTRAINT pk_account_realm_password_type PRIMARY KEY (password_type, account_realm_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_acrlm_pwd_type ON account_realm_password_type USING btree (password_type);
CREATE INDEX xif_acrlm_acct_rlm_id ON account_realm_password_type USING btree (account_realm_id);

INSERT INTO account_realm_password_type
	(account_realm_id, password_type)
SELECT DISTINCT account_realm_id, password_type
FROM account_password
ORDER BY account_realm_id, password_type;

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK account_realm_password_type and account_password
ALTER TABLE account_password
	ADD CONSTRAINT fk_acct_pwd_realm_type
	FOREIGN KEY (password_type, account_realm_id) REFERENCES account_realm_password_type(password_type, account_realm_id);

-- FOREIGN KEYS TO
-- consider FK account_realm_password_type and account_realm
ALTER TABLE account_realm_password_type
	ADD CONSTRAINT fk_acrlm_acct_rlm_id
	FOREIGN KEY (account_realm_id) REFERENCES account_realm(account_realm_id);
-- consider FK account_realm_password_type and val_password_type
ALTER TABLE account_realm_password_type
	ADD CONSTRAINT fk_acrlm_pwd_type
	FOREIGN KEY (password_type) REFERENCES val_password_type(password_type);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'account_realm_password_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'account_realm_password_type');
-- DONE DEALING WITH TABLE account_realm_password_type [2499589]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_property [2462408]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'val_property', 'val_property');

-- FOREIGN KEYS FROM
ALTER TABLE property DROP CONSTRAINT IF EXISTS fk_property_nmtyp;
ALTER TABLE property_collection_property DROP CONSTRAINT IF EXISTS fk_prop_col_propnamtyp;
ALTER TABLE val_property_value DROP CONSTRAINT IF EXISTS fk_valproval_namtyp;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_val_prop_nblk_coll_type;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_pv_actyp_rst;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_propdttyp;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS fk_valprop_proptyp;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_property');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS pk_val_property;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif2val_property";
DROP INDEX IF EXISTS "jazzhands"."xif1val_property";
DROP INDEX IF EXISTS "jazzhands"."xif3val_property";
DROP INDEX IF EXISTS "jazzhands"."xif4val_property";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_sitec;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1279736247;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pucls_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_2016888554;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_ismulti;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1279736503;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_prodstate;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1804972034;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_271462566;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_606225804;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_2139007167;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pacct_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pdevcol_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_cmp_id;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_pdnsdomid;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS check_prp_prmt_354296970;
ALTER TABLE jazzhands.val_property DROP CONSTRAINT IF EXISTS ckc_val_prop_osid;
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


ALTER TABLE val_property RENAME TO val_property_v60;
ALTER TABLE audit.val_property RENAME TO val_property_v60;

CREATE TABLE val_property
(
	property_name	varchar(255) NOT NULL,
	property_type	varchar(50) NOT NULL,
	description	varchar(255)  NULL,
	is_multivalue	character(1) NOT NULL,
	prop_val_acct_coll_type_rstrct	varchar(50)  NULL,
	prop_val_dev_coll_type_rstrct	varchar(50)  NULL,
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
	permit_os_snapshot_id	character(10) NOT NULL,
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
	ALTER permit_os_snapshot_id
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
	prop_val_dev_coll_type_rstrct,		-- new column (prop_val_dev_coll_type_rstrct)
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
	permit_os_snapshot_id,
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
	NULL,		-- new column (prop_val_dev_coll_type_rstrct)
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
	permit_os_snapshot_id,
	permit_person_id,
	permit_property_collection_id,
	permit_service_env_collection,
	permit_site_code,
	permit_property_rank,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM val_property_v60;

INSERT INTO audit.val_property (
	property_name,
	property_type,
	description,
	is_multivalue,
	prop_val_acct_coll_type_rstrct,
	prop_val_dev_coll_type_rstrct,		-- new column (prop_val_dev_coll_type_rstrct)
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
	permit_os_snapshot_id,
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
	NULL,		-- new column (prop_val_dev_coll_type_rstrct)
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
	permit_os_snapshot_id,
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
FROM audit.val_property_v60;

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
	ALTER permit_os_snapshot_id
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
COMMENT ON TABLE val_property IS 'valid values and attributes for (name,type) pairs in the property table.  This defines how triggers enforce aspects of the property table';
COMMENT ON COLUMN val_property.property_name IS 'property name for validation purposes';
COMMENT ON COLUMN val_property.property_type IS 'property type for validation purposes';
COMMENT ON COLUMN val_property.is_multivalue IS 'If N, acts like an alternate key on property.(lhs,property_name,property_type)';
COMMENT ON COLUMN val_property.prop_val_acct_coll_type_rstrct IS 'if property_value is account_collection_Id, this limits the account_collection_types that can be used in that column.';
COMMENT ON COLUMN val_property.prop_val_dev_coll_type_rstrct IS 'if property_value is devicet_collection_Id, this limits the devicet_collection_types that can be used in that column.';
COMMENT ON COLUMN val_property.prop_val_nblk_coll_type_rstrct IS 'if property_value isnetblockt_collection_Id, this limits the netblockt_collection_types that can be used in that column.';
COMMENT ON COLUMN val_property.property_data_type IS 'which, if any, of the property_table_* columns should be used for this value.   May turn more complex enforcement via trigger';
COMMENT ON COLUMN val_property.permit_account_collection_id IS 'defines permissibility/requirement of account_collection_id on LHS of property';
COMMENT ON COLUMN val_property.permit_account_id IS 'defines permissibility/requirement of account_idon LHS of property';
COMMENT ON COLUMN val_property.permit_account_realm_id IS 'defines permissibility/requirement of account_realm_id on LHS of property';
COMMENT ON COLUMN val_property.permit_company_id IS 'defines permissibility/requirement of company_id on LHS of property';
COMMENT ON COLUMN val_property.permit_device_collection_id IS 'defines permissibility/requirement of device_collection_id on LHS of property';
COMMENT ON COLUMN val_property.permit_dns_domain_id IS 'defines permissibility/requirement of dns_domain_id on LHS of property';
COMMENT ON COLUMN val_property.permit_layer2_network_id IS 'defines permissibility/requirement of layer2_network_id on LHS of property';
COMMENT ON COLUMN val_property.permit_layer3_network_id IS 'defines permissibility/requirement of layer3_network_id on LHS of property';
COMMENT ON COLUMN val_property.permit_netblock_collection_id IS 'defines permissibility/requirement of netblock_collection_id on LHS of property';
COMMENT ON COLUMN val_property.permit_operating_system_id IS 'defines permissibility/requirement of operating_system_id on LHS of property';
COMMENT ON COLUMN val_property.permit_os_snapshot_id IS 'defines permissibility/requirement of operating_system_snapshot_id on LHS of property';
COMMENT ON COLUMN val_property.permit_person_id IS 'defines permissibility/requirement of person_id on LHS of property';
COMMENT ON COLUMN val_property.permit_property_collection_id IS 'defines permissibility/requirement of property_collection_id on LHS of property';
COMMENT ON COLUMN val_property.permit_service_env_collection IS 'defines permissibility/requirement of service_env_collection_id on LHS of property';
COMMENT ON COLUMN val_property.permit_site_code IS 'defines permissibility/requirement of site_code on LHS of property';
COMMENT ON COLUMN val_property.permit_property_rank IS 'defines permissibility of property_rank, and if it should be part of the "lhs" of the given property';
-- INDEXES
CREATE INDEX xif4val_property ON val_property USING btree (prop_val_nblk_coll_type_rstrct);
CREATE INDEX xif3val_property ON val_property USING btree (prop_val_acct_coll_type_rstrct);
CREATE INDEX xif2val_property ON val_property USING btree (property_type);
CREATE INDEX xif1val_property ON val_property USING btree (property_data_type);
CREATE INDEX xif5val_property ON val_property USING btree (prop_val_dev_coll_type_rstrct);

-- CHECK CONSTRAINTS
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pdevcol_id
	CHECK (permit_device_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pacct_id
	CHECK (permit_account_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_2139007167
	CHECK (permit_property_rank = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_354296970
	CHECK (permit_netblock_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_osid
	CHECK (permit_operating_system_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pdnsdomid
	CHECK (permit_dns_domain_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_cmp_id
	CHECK (permit_company_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_ismulti
	CHECK (is_multivalue = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_1279736503
	CHECK (permit_layer2_network_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_prodstate
	CHECK (permit_service_env_collection = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_2016888554
	CHECK (permit_account_realm_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_1279736247
	CHECK (permit_layer3_network_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_pucls_id
	CHECK (permit_account_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT ckc_val_prop_sitec
	CHECK (permit_site_code = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_606225804
	CHECK (permit_person_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_271462566
	CHECK (permit_property_collection_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_property ADD CONSTRAINT check_prp_prmt_1804972034
	CHECK (permit_os_snapshot_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK val_property and property_collection_property
ALTER TABLE property_collection_property
	ADD CONSTRAINT fk_prop_col_propnamtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);
-- consider FK val_property and property
ALTER TABLE property
	ADD CONSTRAINT fk_property_nmtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);
-- consider FK val_property and val_property_value
ALTER TABLE val_property_value
	ADD CONSTRAINT fk_valproval_namtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);

-- FOREIGN KEYS TO
-- consider FK val_property and val_property_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_valprop_proptyp
	FOREIGN KEY (property_type) REFERENCES val_property_type(property_type);
-- consider FK val_property and val_property_data_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_valprop_propdttyp
	FOREIGN KEY (property_data_type) REFERENCES val_property_data_type(property_data_type);
-- consider FK val_property and val_netblock_collection_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_val_prop_nblk_coll_type
	FOREIGN KEY (prop_val_nblk_coll_type_rstrct) REFERENCES val_netblock_collection_type(netblock_collection_type);
-- consider FK val_property and val_device_collection_type
ALTER TABLE val_property
	ADD CONSTRAINT r_683
	FOREIGN KEY (prop_val_dev_coll_type_rstrct) REFERENCES val_device_collection_type(device_collection_type);
-- consider FK val_property and val_account_collection_type
ALTER TABLE val_property
	ADD CONSTRAINT fk_valprop_pv_actyp_rst
	FOREIGN KEY (prop_val_acct_coll_type_rstrct) REFERENCES val_account_collection_type(account_collection_type);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_property');
DROP TABLE IF EXISTS val_property_v60;
DROP TABLE IF EXISTS audit.val_property_v60;
-- DONE DEALING WITH TABLE val_property [2501746]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE property [2461372]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'property', 'property');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_devcolid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_pwdtyp;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_swpkgid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_prop_os_snapshot;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_osid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_acctid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_tokcolid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_acctrealmid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_compid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pv_nblkcol_id;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_prop_svc_env_coll_id;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_dnsdomid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_acct_col;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_prop_coll_id;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_val_prsnid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_nblk_coll_id;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_site_code;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_prop_l3netid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_nmtyp;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_acct_colid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_dnsdomid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_prop_l2netid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_pval_compid;
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS fk_property_person_id;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'property');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS pk_property;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xifprop_osid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_acct_colid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_pwdtyp";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_dnsdomid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_acctcol_id";
DROP INDEX IF EXISTS "jazzhands"."xif21property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_compid";
DROP INDEX IF EXISTS "jazzhands"."xif_prop_os_snapshot";
DROP INDEX IF EXISTS "jazzhands"."xifprop_nmtyp";
DROP INDEX IF EXISTS "jazzhands"."xif23property";
DROP INDEX IF EXISTS "jazzhands"."xif22property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_swpkgid";
DROP INDEX IF EXISTS "jazzhands"."xif24property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_tokcolid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_site_code";
DROP INDEX IF EXISTS "jazzhands"."xifprop_devcolid";
DROP INDEX IF EXISTS "jazzhands"."xifprop_pval_compid";
DROP INDEX IF EXISTS "jazzhands"."xif20property";
DROP INDEX IF EXISTS "jazzhands"."xif19property";
DROP INDEX IF EXISTS "jazzhands"."xifprop_account_id";
DROP INDEX IF EXISTS "jazzhands"."xifprop_dnsdomid";
DROP INDEX IF EXISTS "jazzhands"."xif25property";
DROP INDEX IF EXISTS "jazzhands"."xif17property";
DROP INDEX IF EXISTS "jazzhands"."xif18property";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.property DROP CONSTRAINT IF EXISTS ckc_prop_isenbld;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_validate_property ON jazzhands.property;
DROP TRIGGER IF EXISTS trig_userlog_property ON jazzhands.property;
DROP TRIGGER IF EXISTS trigger_audit_property ON jazzhands.property;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'property');
---- BEGIN audit.property TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'property');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."property_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'property');
---- DONE audit.property TEARDOWN


ALTER TABLE property RENAME TO property_v60;
ALTER TABLE audit.property RENAME TO property_v60;

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
	operating_system_snapshot_id	integer  NULL,
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
	property_value_device_coll_id	integer  NULL,
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
	operating_system_snapshot_id,
	person_id,
	property_collection_id,
	service_env_collection_id,
	site_code,
	property_name,
	property_type,
	property_value,
	property_value_timestamp,
	property_value_company_id,
	property_value_account_coll_id,
	property_value_device_coll_id,		-- new column (property_value_device_coll_id)
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
	operating_system_snapshot_id,
	person_id,
	property_collection_id,
	service_env_collection_id,
	site_code,
	property_name,
	property_type,
	property_value,
	property_value_timestamp,
	property_value_company_id,
	property_value_account_coll_id,
	NULL,		-- new column (property_value_device_coll_id)
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
FROM property_v60;

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
	operating_system_snapshot_id,
	person_id,
	property_collection_id,
	service_env_collection_id,
	site_code,
	property_name,
	property_type,
	property_value,
	property_value_timestamp,
	property_value_company_id,
	property_value_account_coll_id,
	property_value_device_coll_id,		-- new column (property_value_device_coll_id)
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
	operating_system_snapshot_id,
	person_id,
	property_collection_id,
	service_env_collection_id,
	site_code,
	property_name,
	property_type,
	property_value,
	property_value_timestamp,
	property_value_company_id,
	property_value_account_coll_id,
	NULL,		-- new column (property_value_device_coll_id)
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
FROM audit.property_v60;

ALTER TABLE property
	ALTER property_id
	SET DEFAULT nextval('property_property_id_seq'::regclass);
ALTER TABLE property
	ALTER is_enabled
	SET DEFAULT 'Y'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE property ADD CONSTRAINT pk_property PRIMARY KEY (property_id);

-- Table/Column Comments
COMMENT ON TABLE property IS 'generic mechanism to create arbitrary associations between lhs database objects and assign them to zero or one other database objects/strings/lists/etc.  They are trigger enforced based on characteristics in val_property and val_property_value where foreign key enforcement does not work.';
COMMENT ON COLUMN property.property_id IS 'primary key for table to uniquely identify rows.';
COMMENT ON COLUMN property.account_collection_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.account_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.account_realm_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.company_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.device_collection_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.dns_domain_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.netblock_collection_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.layer2_network_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.layer3_network_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.operating_system_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.operating_system_snapshot_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.person_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.property_collection_id IS 'LHS settable based on val_property.  NOTE, this is actually collections of property_name,property_type';
COMMENT ON COLUMN property.service_env_collection_id IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.site_code IS 'LHS settable based on val_property';
COMMENT ON COLUMN property.property_name IS 'textual name of a property';
COMMENT ON COLUMN property.property_type IS 'textual type of a department';
COMMENT ON COLUMN property.property_value IS 'RHS - general purpose column for value of property not defined by other types.  This may be enforced by fk (trigger) if val_property.property_data_type is list (fk is to val_property_value).   permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_timestamp IS 'RHS - value is a timestamp , permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_company_id IS 'RHS - fk to company_id,  permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_account_coll_id IS 'RHS, fk to account_collection,    permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_device_coll_id IS 'RHS - fk to device_collection.    permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_dns_domain_id IS 'RHS - fk to dns_domain.    permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_nblk_coll_id IS 'RHS - fk to network_collection.    permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_password_type IS 'RHS - fk to val_password_type.     permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_person_id IS 'RHS - fk to person.     permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_sw_package_id IS 'RHS - fk to sw_package.  possibly will be deprecated.     permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_value_token_col_id IS 'RHS - fk to token_collection_id.     permitted based on val_property.property_data_type.';
COMMENT ON COLUMN property.property_rank IS 'for multivalues, specifies the order.  If set, this basically becomes part of the "ak" for the lhs.';
COMMENT ON COLUMN property.start_date IS 'date/time that the assignment takes effect or NULL.  .  The view v_property filters this out.';
COMMENT ON COLUMN property.finish_date IS 'date/time that the assignment ceases taking effect or NULL.  .  The view v_property filters this out.';
COMMENT ON COLUMN property.is_enabled IS 'indiciates if the property is temporarily disabled or not.  The view v_property filters this out.';
-- INDEXES
CREATE INDEX xif17property ON property USING btree (property_value_person_id);
CREATE INDEX xif18property ON property USING btree (person_id);
CREATE INDEX xif25property ON property USING btree (property_collection_id);
CREATE INDEX xifprop_dnsdomid ON property USING btree (dns_domain_id);
CREATE INDEX xifprop_account_id ON property USING btree (account_id);
CREATE INDEX xif19property ON property USING btree (property_value_nblk_coll_id);
CREATE INDEX xif20property ON property USING btree (netblock_collection_id);
CREATE INDEX xifprop_pval_compid ON property USING btree (property_value_company_id);
CREATE INDEX xifprop_devcolid ON property USING btree (device_collection_id);
CREATE INDEX xifprop_site_code ON property USING btree (site_code);
CREATE INDEX xifprop_pval_tokcolid ON property USING btree (property_value_token_col_id);
CREATE INDEX xif24property ON property USING btree (layer3_network_id);
CREATE INDEX xifprop_pval_swpkgid ON property USING btree (property_value_sw_package_id);
CREATE INDEX xif22property ON property USING btree (account_realm_id);
CREATE INDEX xif23property ON property USING btree (layer2_network_id);
CREATE INDEX xif_prop_pv_devcolid ON property USING btree (property_value_device_coll_id);
CREATE INDEX xifprop_nmtyp ON property USING btree (property_name, property_type);
CREATE INDEX xif_prop_os_snapshot ON property USING btree (operating_system_snapshot_id);
CREATE INDEX xifprop_compid ON property USING btree (company_id);
CREATE INDEX xif21property ON property USING btree (service_env_collection_id);
CREATE INDEX xifprop_acctcol_id ON property USING btree (account_collection_id);
CREATE INDEX xifprop_pval_dnsdomid ON property USING btree (property_value_dns_domain_id);
CREATE INDEX xifprop_pval_pwdtyp ON property USING btree (property_value_password_type);
CREATE INDEX xifprop_pval_acct_colid ON property USING btree (property_value_account_coll_id);
CREATE INDEX xifprop_osid ON property USING btree (operating_system_id);

-- CHECK CONSTRAINTS
ALTER TABLE property ADD CONSTRAINT ckc_prop_isenbld
	CHECK (is_enabled = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK property and layer2_network
ALTER TABLE property
	ADD CONSTRAINT fk_prop_l2netid
	FOREIGN KEY (layer2_network_id) REFERENCES layer2_network(layer2_network_id);
-- consider FK property and dns_domain
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_dnsdomid
	FOREIGN KEY (property_value_dns_domain_id) REFERENCES dns_domain(dns_domain_id);
-- consider FK property and company
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_compid
	FOREIGN KEY (property_value_company_id) REFERENCES company(company_id) DEFERRABLE;
-- consider FK property and person
ALTER TABLE property
	ADD CONSTRAINT fk_property_person_id
	FOREIGN KEY (person_id) REFERENCES person(person_id);
-- consider FK property and device_collection
ALTER TABLE property
	ADD CONSTRAINT fk_prop_pv_devcolid
	FOREIGN KEY (property_value_device_coll_id) REFERENCES device_collection(device_collection_id);
-- consider FK property and property_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_prop_coll_id
	FOREIGN KEY (property_collection_id) REFERENCES property_collection(property_collection_id);
-- consider FK property and person
ALTER TABLE property
	ADD CONSTRAINT fk_property_val_prsnid
	FOREIGN KEY (property_value_person_id) REFERENCES person(person_id);
-- consider FK property and val_property
ALTER TABLE property
	ADD CONSTRAINT fk_property_nmtyp
	FOREIGN KEY (property_name, property_type) REFERENCES val_property(property_name, property_type);
-- consider FK property and layer3_network
ALTER TABLE property
	ADD CONSTRAINT fk_prop_l3netid
	FOREIGN KEY (layer3_network_id) REFERENCES layer3_network(layer3_network_id);
-- consider FK property and site
ALTER TABLE property
	ADD CONSTRAINT fk_property_site_code
	FOREIGN KEY (site_code) REFERENCES site(site_code);
-- consider FK property and netblock_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_nblk_coll_id
	FOREIGN KEY (netblock_collection_id) REFERENCES netblock_collection(netblock_collection_id);
-- consider FK property and account_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_acct_colid
	FOREIGN KEY (property_value_account_coll_id) REFERENCES account_collection(account_collection_id);
-- consider FK property and company
ALTER TABLE property
	ADD CONSTRAINT fk_property_compid
	FOREIGN KEY (company_id) REFERENCES company(company_id) DEFERRABLE;
-- consider FK property and account_realm
ALTER TABLE property
	ADD CONSTRAINT fk_property_acctrealmid
	FOREIGN KEY (account_realm_id) REFERENCES account_realm(account_realm_id);
-- consider FK property and service_environment_collection
ALTER TABLE property
	ADD CONSTRAINT fk_prop_svc_env_coll_id
	FOREIGN KEY (service_env_collection_id) REFERENCES service_environment_collection(service_env_collection_id);
-- consider FK property and netblock_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_pv_nblkcol_id
	FOREIGN KEY (property_value_nblk_coll_id) REFERENCES netblock_collection(netblock_collection_id);
-- consider FK property and dns_domain
ALTER TABLE property
	ADD CONSTRAINT fk_property_dnsdomid
	FOREIGN KEY (dns_domain_id) REFERENCES dns_domain(dns_domain_id);
-- consider FK property and account_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_acct_col
	FOREIGN KEY (account_collection_id) REFERENCES account_collection(account_collection_id);
-- consider FK property and device_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_devcolid
	FOREIGN KEY (device_collection_id) REFERENCES device_collection(device_collection_id);
-- consider FK property and val_password_type
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_pwdtyp
	FOREIGN KEY (property_value_password_type) REFERENCES val_password_type(password_type);
-- consider FK property and operating_system_snapshot
ALTER TABLE property
	ADD CONSTRAINT fk_prop_os_snapshot
	FOREIGN KEY (operating_system_snapshot_id) REFERENCES operating_system_snapshot(operating_system_snapshot_id);
-- consider FK property and sw_package
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_swpkgid
	FOREIGN KEY (property_value_sw_package_id) REFERENCES sw_package(sw_package_id);
-- consider FK property and account
ALTER TABLE property
	ADD CONSTRAINT fk_property_acctid
	FOREIGN KEY (account_id) REFERENCES account(account_id);
-- consider FK property and token_collection
ALTER TABLE property
	ADD CONSTRAINT fk_property_pval_tokcolid
	FOREIGN KEY (property_value_token_col_id) REFERENCES token_collection(token_collection_id);
-- consider FK property and operating_system
ALTER TABLE property
	ADD CONSTRAINT fk_property_osid
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);

-- TRIGGERS
CREATE TRIGGER trigger_validate_property BEFORE INSERT OR UPDATE ON property FOR EACH ROW EXECUTE PROCEDURE validate_property();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'property');
ALTER SEQUENCE property_property_id_seq
	 OWNED BY property.property_id;
DROP TABLE IF EXISTS property_v60;
DROP TABLE IF EXISTS audit.property_v60;
-- DONE DEALING WITH TABLE property [2500792]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_component_property_value [2461956]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'val_component_property_value', 'val_component_property_value');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.val_component_property_value DROP CONSTRAINT IF EXISTS fk_comp_prop_val_nametyp;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_component_property_value');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_component_property_value DROP CONSTRAINT IF EXISTS pk_val_component_property_valu;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_comp_prop_val_nametyp";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_val_component_property_value ON jazzhands.val_component_property_value;
DROP TRIGGER IF EXISTS trigger_audit_val_component_property_value ON jazzhands.val_component_property_value;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_component_property_value');
---- BEGIN audit.val_component_property_value TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_component_property_value');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_component_property_value_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_component_property_value');
---- DONE audit.val_component_property_value TEARDOWN


ALTER TABLE val_component_property_value RENAME TO val_component_property_value_v60;
ALTER TABLE audit.val_component_property_value RENAME TO val_component_property_value_v60;

CREATE TABLE val_component_property_value
(
	component_property_name	varchar(50) NOT NULL,
	component_property_type	varchar(50) NOT NULL,
	valid_property_value	varchar(255) NOT NULL,
	description	varchar(255)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_component_property_value', false);
INSERT INTO val_component_property_value (
	component_property_name,
	component_property_type,
	valid_property_value,
	description,		-- new column (description)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	component_property_name,
	component_property_type,
	valid_property_value,
	NULL,		-- new column (description)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM val_component_property_value_v60;

INSERT INTO audit.val_component_property_value (
	component_property_name,
	component_property_type,
	valid_property_value,
	description,		-- new column (description)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	component_property_name,
	component_property_type,
	valid_property_value,
	NULL,		-- new column (description)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.val_component_property_value_v60;


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
DROP TABLE IF EXISTS val_component_property_value_v60;
DROP TABLE IF EXISTS audit.val_component_property_value_v60;
-- DONE DEALING WITH TABLE val_component_property_value [2501371]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_component_property [2461920]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'val_component_property', 'val_component_property');

-- FOREIGN KEYS FROM
ALTER TABLE val_component_property_value DROP CONSTRAINT IF EXISTS fk_comp_prop_val_nametyp;
ALTER TABLE component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_prop_nmty;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS fk_vcomp_prop_rqd_slttyp_id;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS fk_cmop_prop_rqd_cmpfunc;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_rqd_cmptypid;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS fk_comp_prop_comp_prop_type;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS fk_vcomp_prop_rqd_slt_func;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_component_property');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS pk_val_component_property;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_prop_rqd_slt_func";
DROP INDEX IF EXISTS "jazzhands"."xif_vcomp_prop_rqd_cmpfunc";
DROP INDEX IF EXISTS "jazzhands"."xif_vcomp_prop_rqd_slttyp_id";
DROP INDEX IF EXISTS "jazzhands"."xif_vcomp_prop_rqd_cmptypid";
DROP INDEX IF EXISTS "jazzhands"."xif_vcomp_prop_comp_prop_type";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS check_yes_no_1709686918;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS check_prp_prmt_342055273;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS check_prp_prmt_27441051;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1181188899;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1984425150;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1618700758;
ALTER TABLE jazzhands.val_component_property DROP CONSTRAINT IF EXISTS check_prp_prmt_1784750469;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_component_property ON jazzhands.val_component_property;
DROP TRIGGER IF EXISTS trig_userlog_val_component_property ON jazzhands.val_component_property;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_component_property');
---- BEGIN audit.val_component_property TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_component_property');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_component_property_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_component_property');
---- DONE audit.val_component_property TEARDOWN


ALTER TABLE val_component_property RENAME TO val_component_property_v60;
ALTER TABLE audit.val_component_property RENAME TO val_component_property_v60;

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
	permit_intcomp_conn_id	character(10) NOT NULL,
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
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_component_property', false);
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
	ALTER permit_intcomp_conn_id
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
INSERT INTO val_component_property (
	component_property_name,
	component_property_type,
	description,
	is_multivalue,
	property_data_type,
	permit_component_type_id,
	required_component_type_id,
	permit_component_function,
	required_component_function,
	permit_component_id,
	permit_intcomp_conn_id,		-- new column (permit_intcomp_conn_id)
	permit_slot_type_id,
	required_slot_type_id,
	permit_slot_function,
	required_slot_function,
	permit_slot_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	component_property_name,
	component_property_type,
	description,
	is_multivalue,
	property_data_type,
	permit_component_type_id,
	required_component_type_id,
	permit_component_function,
	required_component_function,
	permit_component_id,
	'PROHIBITED'::bpchar,		-- new column (permit_intcomp_conn_id)
	permit_slot_type_id,
	required_slot_type_id,
	permit_slot_function,
	required_slot_function,
	permit_slot_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM val_component_property_v60;

INSERT INTO audit.val_component_property (
	component_property_name,
	component_property_type,
	description,
	is_multivalue,
	property_data_type,
	permit_component_type_id,
	required_component_type_id,
	permit_component_function,
	required_component_function,
	permit_component_id,
	permit_intcomp_conn_id,		-- new column (permit_intcomp_conn_id)
	permit_slot_type_id,
	required_slot_type_id,
	permit_slot_function,
	required_slot_function,
	permit_slot_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	component_property_name,
	component_property_type,
	description,
	is_multivalue,
	property_data_type,
	permit_component_type_id,
	required_component_type_id,
	permit_component_function,
	required_component_function,
	permit_component_id,
	NULL,		-- new column (permit_intcomp_conn_id)
	permit_slot_type_id,
	required_slot_type_id,
	permit_slot_function,
	required_slot_function,
	permit_slot_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.val_component_property_v60;

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
	ALTER permit_intcomp_conn_id
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
CREATE INDEX xif_vcomp_prop_comp_prop_type ON val_component_property USING btree (component_property_type);
CREATE INDEX xif_vcomp_prop_rqd_slttyp_id ON val_component_property USING btree (required_slot_type_id);
CREATE INDEX xif_vcomp_prop_rqd_cmptypid ON val_component_property USING btree (required_component_type_id);
CREATE INDEX xif_vcomp_prop_rqd_cmpfunc ON val_component_property USING btree (required_component_function);
CREATE INDEX xif_prop_rqd_slt_func ON val_component_property USING btree (required_slot_function);

-- CHECK CONSTRAINTS
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_342055273
	CHECK (permit_slot_type_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_27441051
	CHECK (permit_component_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_1181188899
	CHECK (permit_component_type_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_1618700758
	CHECK (permit_component_function = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_yes_no_1709686918
	CHECK (is_multivalue = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_1984425150
	CHECK (permit_slot_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_677097419
	CHECK (permit_intcomp_conn_id = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));
ALTER TABLE val_component_property ADD CONSTRAINT check_prp_prmt_1784750469
	CHECK (permit_slot_function = ANY (ARRAY['REQUIRED'::bpchar, 'PROHIBITED'::bpchar, 'ALLOWED'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK val_component_property and val_component_property_value
ALTER TABLE val_component_property_value
	ADD CONSTRAINT fk_comp_prop_val_nametyp
	FOREIGN KEY (component_property_name, component_property_type) REFERENCES val_component_property(component_property_name, component_property_type);
-- consider FK val_component_property and component_property
ALTER TABLE component_property
	ADD CONSTRAINT fk_comp_prop_prop_nmty
	FOREIGN KEY (component_property_name, component_property_type) REFERENCES val_component_property(component_property_name, component_property_type);

-- FOREIGN KEYS TO
-- consider FK val_component_property and val_component_function
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_cmop_prop_rqd_cmpfunc
	FOREIGN KEY (required_component_function) REFERENCES val_component_function(component_function);
-- consider FK val_component_property and slot_type
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_vcomp_prop_rqd_slttyp_id
	FOREIGN KEY (required_slot_type_id) REFERENCES slot_type(slot_type_id);
-- consider FK val_component_property and component_type
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_comp_prop_rqd_cmptypid
	FOREIGN KEY (required_component_type_id) REFERENCES component_type(component_type_id);
-- consider FK val_component_property and val_component_property_type
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_comp_prop_comp_prop_type
	FOREIGN KEY (component_property_type) REFERENCES val_component_property_type(component_property_type);
-- consider FK val_component_property and val_slot_function
ALTER TABLE val_component_property
	ADD CONSTRAINT fk_vcomp_prop_rqd_slt_func
	FOREIGN KEY (required_slot_function) REFERENCES val_slot_function(slot_function);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_component_property');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_component_property');
DROP TABLE IF EXISTS val_component_property_v60;
DROP TABLE IF EXISTS audit.val_component_property_v60;
-- DONE DEALING WITH TABLE val_component_property [2501333]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE physicalish_volume [2461359]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'physicalish_volume', 'physicalish_volume');

-- FOREIGN KEYS FROM
ALTER TABLE volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vgp_phy_phyid;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.physicalish_volume DROP CONSTRAINT IF EXISTS fk_physvol_lvid;
ALTER TABLE jazzhands.physicalish_volume DROP CONSTRAINT IF EXISTS fk_physvol_compid;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'physicalish_volume');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.physicalish_volume DROP CONSTRAINT IF EXISTS pk_physicalish_volume;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_physvol_lvid";
DROP INDEX IF EXISTS "jazzhands"."xif_physvol_compid";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_physicalish_volume ON jazzhands.physicalish_volume;
DROP TRIGGER IF EXISTS trigger_verify_physicalish_volume ON jazzhands.physicalish_volume;
DROP TRIGGER IF EXISTS trig_userlog_physicalish_volume ON jazzhands.physicalish_volume;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'physicalish_volume');
---- BEGIN audit.physicalish_volume TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'physicalish_volume');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."physicalish_volume_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'physicalish_volume');
---- DONE audit.physicalish_volume TEARDOWN


ALTER TABLE physicalish_volume RENAME TO physicalish_volume_v60;
ALTER TABLE audit.physicalish_volume RENAME TO physicalish_volume_v60;

CREATE TABLE physicalish_volume
(
	physicalish_volume_id	integer NOT NULL,
	physicalish_volume_name	varchar(50) NOT NULL,
	physicalish_volume_type	varchar(50) NOT NULL,
	device_id	integer NOT NULL,
	logical_volume_id	integer  NULL,
	component_id	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'physicalish_volume', false);
ALTER TABLE physicalish_volume
	ALTER physicalish_volume_id
	SET DEFAULT nextval('physicalish_volume_physicalish_volume_id_seq'::regclass);
INSERT INTO physicalish_volume (
	physicalish_volume_id,
	physicalish_volume_name,		-- new column (physicalish_volume_name)
	physicalish_volume_type,		-- new column (physicalish_volume_type)
	device_id,		-- new column (device_id)
	logical_volume_id,
	component_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	physicalish_volume_id,
	NULL,		-- new column (physicalish_volume_name)
	NULL,		-- new column (physicalish_volume_type)
	NULL,		-- new column (device_id)
	logical_volume_id,
	component_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM physicalish_volume_v60;

INSERT INTO audit.physicalish_volume (
	physicalish_volume_id,
	physicalish_volume_name,		-- new column (physicalish_volume_name)
	physicalish_volume_type,		-- new column (physicalish_volume_type)
	device_id,		-- new column (device_id)
	logical_volume_id,
	component_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	physicalish_volume_id,
	NULL,		-- new column (physicalish_volume_name)
	NULL,		-- new column (physicalish_volume_type)
	NULL,		-- new column (device_id)
	logical_volume_id,
	component_id,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.physicalish_volume_v60;

ALTER TABLE physicalish_volume
	ALTER physicalish_volume_id
	SET DEFAULT nextval('physicalish_volume_physicalish_volume_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE physicalish_volume ADD CONSTRAINT ak_physicalish_volume_devid UNIQUE (physicalish_volume_id, device_id);
ALTER TABLE physicalish_volume ADD CONSTRAINT pk_physicalish_volume PRIMARY KEY (physicalish_volume_id);
ALTER TABLE physicalish_volume ADD CONSTRAINT ak_physvolname_type_devid UNIQUE (device_id, physicalish_volume_name, physicalish_volume_type);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_physvol_device_id ON physicalish_volume USING btree (device_id);
CREATE INDEX xif_physicalish_vol_pvtype ON physicalish_volume USING btree (physicalish_volume_type);
CREATE INDEX xif_physvol_lvid ON physicalish_volume USING btree (logical_volume_id);
CREATE INDEX xif_physvol_compid ON physicalish_volume USING btree (component_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK physicalish_volume and volume_group_physicalish_vol
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vgp_phy_phyid
	FOREIGN KEY (physicalish_volume_id) REFERENCES physicalish_volume(physicalish_volume_id);
-- consider FK physicalish_volume and volume_group_physicalish_vol
--ALTER TABLE volume_group_physicalish_vol
--	ADD CONSTRAINT fk_physvol_vg_phsvol_dvid
--	FOREIGN KEY (physicalish_volume_id, device_id) REFERENCES physicalish_volume(physicalish_volume_id, device_id);

-- FOREIGN KEYS TO
-- consider FK physicalish_volume and component
--ALTER TABLE physicalish_volume
--	ADD CONSTRAINT fk_physvol_compid
--	FOREIGN KEY (component_id) REFERENCES component(component_id);
-- consider FK physicalish_volume and val_physicalish_volume_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE physicalish_volume
--	ADD CONSTRAINT fk_physicalish_vol_pvtype
--	FOREIGN KEY (physicalish_volume_type) REFERENCES val_physicalish_volume_type(physicalish_volume_type);

-- consider FK physicalish_volume and device
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physvol_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK physicalish_volume and logical_volume
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physvol_lvid
	FOREIGN KEY (logical_volume_id) REFERENCES logical_volume(logical_volume_id);

-- TRIGGERS
CREATE TRIGGER trigger_verify_physicalish_volume BEFORE INSERT OR UPDATE ON physicalish_volume FOR EACH ROW EXECUTE PROCEDURE verify_physicalish_volume();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'physicalish_volume');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'physicalish_volume');
ALTER SEQUENCE physicalish_volume_physicalish_volume_id_seq
	 OWNED BY physicalish_volume.physicalish_volume_id;
DROP TABLE IF EXISTS physicalish_volume_v60;
DROP TABLE IF EXISTS audit.physicalish_volume_v60;
-- DONE DEALING WITH TABLE physicalish_volume [2500773]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE logical_volume [2460929]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'logical_volume', 'logical_volume');

-- FOREIGN KEYS FROM
ALTER TABLE physicalish_volume DROP CONSTRAINT IF EXISTS fk_physvol_lvid;
ALTER TABLE logical_volume_property DROP CONSTRAINT IF EXISTS fk_lvol_prop_lvid_fstyp;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.logical_volume DROP CONSTRAINT IF EXISTS fk_logvol_vgid;
ALTER TABLE jazzhands.logical_volume DROP CONSTRAINT IF EXISTS fk_logvol_fstype;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'logical_volume');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.logical_volume DROP CONSTRAINT IF EXISTS ak_logical_volume_filesystem;
ALTER TABLE jazzhands.logical_volume DROP CONSTRAINT IF EXISTS pk_logical_volume;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_logvol_vgid";
DROP INDEX IF EXISTS "jazzhands"."xif_logvol_fstype";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_logical_volume ON jazzhands.logical_volume;
DROP TRIGGER IF EXISTS trigger_audit_logical_volume ON jazzhands.logical_volume;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'logical_volume');
---- BEGIN audit.logical_volume TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'logical_volume');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."logical_volume_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'logical_volume');
---- DONE audit.logical_volume TEARDOWN


ALTER TABLE logical_volume RENAME TO logical_volume_v60;
ALTER TABLE audit.logical_volume RENAME TO logical_volume_v60;

CREATE TABLE logical_volume
(
	logical_volume_id	integer NOT NULL,
	volume_group_id	integer NOT NULL,
	device_id	integer  NULL,
	logical_volume_name	varchar(50) NOT NULL,
	logical_volume_size_in_bytes	bigint NOT NULL,
	logical_volume_offset_in_bytes	bigint  NULL,
	filesystem_type	varchar(50) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'logical_volume', false);
ALTER TABLE logical_volume
	ALTER logical_volume_id
	SET DEFAULT nextval('logical_volume_logical_volume_id_seq'::regclass);
INSERT INTO logical_volume (
	logical_volume_id,
	volume_group_id,
	device_id,		-- new column (device_id)
	logical_volume_name,
	logical_volume_size_in_bytes,		-- new column (logical_volume_size_in_bytes)
	logical_volume_offset_in_bytes,		-- new column (logical_volume_offset_in_bytes)
	filesystem_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	logical_volume_id,
	volume_group_id,
	NULL,		-- new column (device_id)
	logical_volume_name,
	NULL,		-- new column (logical_volume_size_in_bytes)
	NULL,		-- new column (logical_volume_offset_in_bytes)
	filesystem_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM logical_volume_v60;

INSERT INTO audit.logical_volume (
	logical_volume_id,
	volume_group_id,
	device_id,		-- new column (device_id)
	logical_volume_name,
	logical_volume_size_in_bytes,		-- new column (logical_volume_size_in_bytes)
	logical_volume_offset_in_bytes,		-- new column (logical_volume_offset_in_bytes)
	filesystem_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	logical_volume_id,
	volume_group_id,
	NULL,		-- new column (device_id)
	logical_volume_name,
	NULL,		-- new column (logical_volume_size_in_bytes)
	NULL,		-- new column (logical_volume_offset_in_bytes)
	filesystem_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.logical_volume_v60;

ALTER TABLE logical_volume
	ALTER logical_volume_id
	SET DEFAULT nextval('logical_volume_logical_volume_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE logical_volume ADD CONSTRAINT ak_logvol_lv_devid UNIQUE (logical_volume_id);
ALTER TABLE logical_volume ADD CONSTRAINT ak_logvol_devid_lvname UNIQUE (logical_volume_name);
ALTER TABLE logical_volume ADD CONSTRAINT pk_logical_volume PRIMARY KEY (logical_volume_id);
ALTER TABLE logical_volume ADD CONSTRAINT ak_logical_volume_filesystem UNIQUE (logical_volume_id, filesystem_type);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_logvol_fstype ON logical_volume USING btree (filesystem_type);
CREATE INDEX xif_logvol_vgid ON logical_volume USING btree (volume_group_id, device_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK logical_volume and logical_volume_property
ALTER TABLE logical_volume_property
	ADD CONSTRAINT fk_lvol_prop_lvid_fstyp
	FOREIGN KEY (logical_volume_id, filesystem_type) REFERENCES logical_volume(logical_volume_id, filesystem_type);
-- consider FK logical_volume and logical_volume_purpose
-- Skipping this FK since table does not exist yet
--ALTER TABLE logical_volume_purpose
--	ADD CONSTRAINT fk_lvpurp_lvid
--	FOREIGN KEY (logical_volume_id) REFERENCES logical_volume(logical_volume_id);

-- consider FK logical_volume and physicalish_volume
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physvol_lvid
	FOREIGN KEY (logical_volume_id) REFERENCES logical_volume(logical_volume_id);

-- FOREIGN KEYS TO
-- consider FK logical_volume and val_filesystem_type
ALTER TABLE logical_volume
	ADD CONSTRAINT fk_logvol_fstype
	FOREIGN KEY (filesystem_type) REFERENCES val_filesystem_type(filesystem_type);
-- consider FK logical_volume and volume_group
-- ALTER TABLE logical_volume
-- 	ADD CONSTRAINT fk_logvol_vgid
-- 	FOREIGN KEY (volume_group_id, device_id) REFERENCES volume_group(volume_group_id, device_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'logical_volume');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'logical_volume');
ALTER SEQUENCE logical_volume_logical_volume_id_seq
	 OWNED BY logical_volume.logical_volume_id;
DROP TABLE IF EXISTS logical_volume_v60;
DROP TABLE IF EXISTS audit.logical_volume_v60;
-- DONE DEALING WITH TABLE logical_volume [2500350]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE volume_group [2462710]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'volume_group', 'volume_group');

-- FOREIGN KEYS FROM
ALTER TABLE logical_volume DROP CONSTRAINT IF EXISTS fk_logvol_vgid;
ALTER TABLE volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vgp_phy_vgrpid;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.volume_group DROP CONSTRAINT IF EXISTS fk_volgrp_rd_type;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'volume_group');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.volume_group DROP CONSTRAINT IF EXISTS pk_volume_group;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_volgrp_rd_type";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_volume_group ON jazzhands.volume_group;
DROP TRIGGER IF EXISTS trig_userlog_volume_group ON jazzhands.volume_group;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'volume_group');
---- BEGIN audit.volume_group TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'volume_group');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."volume_group_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'volume_group');
---- DONE audit.volume_group TEARDOWN


ALTER TABLE volume_group RENAME TO volume_group_v60;
ALTER TABLE audit.volume_group RENAME TO volume_group_v60;

CREATE TABLE volume_group
(
	volume_group_id	integer NOT NULL,
	device_id	integer  NULL,
	volume_group_name	varchar(50) NOT NULL,
	volume_group_type	varchar(50)  NULL,
	volume_group_size_in_bytes	bigint NOT NULL,
	raid_type	varchar(50)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'volume_group', false);
ALTER TABLE volume_group
	ALTER volume_group_id
	SET DEFAULT nextval('volume_group_volume_group_id_seq'::regclass);
INSERT INTO volume_group (
	volume_group_id,
	device_id,		-- new column (device_id)
	volume_group_name,
	volume_group_type,		-- new column (volume_group_type)
	volume_group_size_in_bytes,		-- new column (volume_group_size_in_bytes)
	raid_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	volume_group_id,
	NULL,		-- new column (device_id)
	volume_group_name,
	NULL,		-- new column (volume_group_type)
	NULL,		-- new column (volume_group_size_in_bytes)
	raid_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM volume_group_v60;

INSERT INTO audit.volume_group (
	volume_group_id,
	device_id,		-- new column (device_id)
	volume_group_name,
	volume_group_type,		-- new column (volume_group_type)
	volume_group_size_in_bytes,		-- new column (volume_group_size_in_bytes)
	raid_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	volume_group_id,
	NULL,		-- new column (device_id)
	volume_group_name,
	NULL,		-- new column (volume_group_type)
	NULL,		-- new column (volume_group_size_in_bytes)
	raid_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.volume_group_v60;

ALTER TABLE volume_group
	ALTER volume_group_id
	SET DEFAULT nextval('volume_group_volume_group_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE volume_group ADD CONSTRAINT pk_volume_group PRIMARY KEY (volume_group_id);
ALTER TABLE volume_group ADD CONSTRAINT ak_volume_group_devid_vgid UNIQUE (volume_group_id, device_id);
ALTER TABLE volume_group ADD CONSTRAINT ak_volgrp_devid_name_type UNIQUE (device_id, volume_group_name, volume_group_type);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_volgrp_volgrp_type ON volume_group USING btree (volume_group_type);
CREATE INDEX xif_volgrp_rd_type ON volume_group USING btree (raid_type);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK volume_group and logical_volume
ALTER TABLE logical_volume
	ADD CONSTRAINT fk_logvol_vgid
	FOREIGN KEY (volume_group_id, device_id) REFERENCES volume_group(volume_group_id, device_id);
-- consider FK volume_group and volume_group_purpose
-- Skipping this FK since table does not exist yet
--ALTER TABLE volume_group_purpose
--	ADD CONSTRAINT fk_val_volgrp_purp_vgid
--	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id);

-- consider FK volume_group and volume_group_physicalish_vol
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vgp_phy_vgrpid
	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id);

-- FOREIGN KEYS TO
-- consider FK volume_group and volume_group_physicalish_vol
--ALTER TABLE volume_group
--	ADD CONSTRAINT fk_volgrp_vg_devid
--	FOREIGN KEY (volume_group_id, device_id) REFERENCES volume_group_physicalish_vol(volume_group_id, device_id);
-- consider FK volume_group and val_raid_type
ALTER TABLE volume_group
	ADD CONSTRAINT fk_volgrp_rd_type
	FOREIGN KEY (raid_type) REFERENCES val_raid_type(raid_type);
-- consider FK volume_group and val_volume_group_type
-- Skipping this FK since table does not exist yet
--ALTER TABLE volume_group
--	ADD CONSTRAINT fk_volgrp_volgrp_type
--	FOREIGN KEY (volume_group_type) REFERENCES val_volume_group_type(volume_group_type);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'volume_group');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'volume_group');
ALTER SEQUENCE volume_group_volume_group_id_seq
	 OWNED BY volume_group.volume_group_id;
DROP TABLE IF EXISTS volume_group_v60;
DROP TABLE IF EXISTS audit.volume_group_v60;
-- DONE DEALING WITH TABLE volume_group [2502057]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE volume_group_physicalish_vol [2462720]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'volume_group_physicalish_vol', 'volume_group_physicalish_vol');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vgp_phy_vgrpid;
ALTER TABLE jazzhands.volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vg_physvol_vgrel;
ALTER TABLE jazzhands.volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vgp_phy_phyid;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'volume_group_physicalish_vol');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS pk_volume_group_physicalish_vo;
ALTER TABLE jazzhands.volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS ak_volgrp_pv_position;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_vgp_phy_vgrpid";
DROP INDEX IF EXISTS "jazzhands"."xif_vg_physvol_vgrel";
DROP INDEX IF EXISTS "jazzhands"."xif_vgp_phy_phyid";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_volume_group_physicalish_vol ON jazzhands.volume_group_physicalish_vol;
DROP TRIGGER IF EXISTS trigger_audit_volume_group_physicalish_vol ON jazzhands.volume_group_physicalish_vol;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'volume_group_physicalish_vol');
---- BEGIN audit.volume_group_physicalish_vol TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'volume_group_physicalish_vol');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."volume_group_physicalish_vol_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'volume_group_physicalish_vol');
---- DONE audit.volume_group_physicalish_vol TEARDOWN


ALTER TABLE volume_group_physicalish_vol RENAME TO volume_group_physicalish_vol_v60;
ALTER TABLE audit.volume_group_physicalish_vol RENAME TO volume_group_physicalish_vol_v60;

CREATE TABLE volume_group_physicalish_vol
(
	physicalish_volume_id	integer NOT NULL,
	volume_group_id	integer NOT NULL,
	device_id	integer  NULL,
	volume_group_position	integer NOT NULL,
	volume_group_relation	varchar(50) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'volume_group_physicalish_vol', false);
INSERT INTO volume_group_physicalish_vol (
	physicalish_volume_id,
	volume_group_id,
	device_id,		-- new column (device_id)
	volume_group_position,
	volume_group_relation,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	physicalish_volume_id,
	volume_group_id,
	NULL,		-- new column (device_id)
	volume_group_position,
	volume_group_relation,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM volume_group_physicalish_vol_v60;

INSERT INTO audit.volume_group_physicalish_vol (
	physicalish_volume_id,
	volume_group_id,
	device_id,		-- new column (device_id)
	volume_group_position,
	volume_group_relation,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	physicalish_volume_id,
	volume_group_id,
	NULL,		-- new column (device_id)
	volume_group_position,
	volume_group_relation,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.volume_group_physicalish_vol_v60;


-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE volume_group_physicalish_vol ADD CONSTRAINT ak_volgrp_pv_position UNIQUE (volume_group_id, volume_group_position);
ALTER TABLE volume_group_physicalish_vol ADD CONSTRAINT ak_volume_group_vg_devid UNIQUE (volume_group_id, device_id);
ALTER TABLE volume_group_physicalish_vol ADD CONSTRAINT pk_volume_group_physicalish_vo PRIMARY KEY (physicalish_volume_id, volume_group_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_physvol_vg_phsvol_dvid ON volume_group_physicalish_vol USING btree (physicalish_volume_id, device_id);
CREATE INDEX xif_vgp_phy_phyid ON volume_group_physicalish_vol USING btree (physicalish_volume_id);
CREATE INDEX xif_vgp_phy_vgrpid ON volume_group_physicalish_vol USING btree (volume_group_id);
CREATE INDEX xif_vg_physvol_vgrel ON volume_group_physicalish_vol USING btree (volume_group_relation);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK volume_group_physicalish_vol and volume_group
ALTER TABLE volume_group
	ADD CONSTRAINT fk_volgrp_vg_devid
	FOREIGN KEY (volume_group_id, device_id) REFERENCES volume_group_physicalish_vol(volume_group_id, device_id);

-- FOREIGN KEYS TO
-- consider FK volume_group_physicalish_vol and val_volume_group_relation
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vg_physvol_vgrel
	FOREIGN KEY (volume_group_relation) REFERENCES val_volume_group_relation(volume_group_relation);
-- consider FK volume_group_physicalish_vol and physicalish_volume
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vgp_phy_phyid
	FOREIGN KEY (physicalish_volume_id) REFERENCES physicalish_volume(physicalish_volume_id);
-- consider FK volume_group_physicalish_vol and volume_group
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vgp_phy_vgrpid
	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id);
-- consider FK volume_group_physicalish_vol and physicalish_volume
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_physvol_vg_phsvol_dvid
	FOREIGN KEY (physicalish_volume_id, device_id) REFERENCES physicalish_volume(physicalish_volume_id, device_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'volume_group_physicalish_vol');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'volume_group_physicalish_vol');
DROP TABLE IF EXISTS volume_group_physicalish_vol_v60;
DROP TABLE IF EXISTS audit.volume_group_physicalish_vol_v60;
-- DONE DEALING WITH TABLE volume_group_physicalish_vol [2502072]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE volume_group_purpose
CREATE TABLE volume_group_purpose
(
	volume_group_id	integer NOT NULL,
	volume_group_purpose	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'volume_group_purpose', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE volume_group_purpose ADD CONSTRAINT pk_volume_group_purpose PRIMARY KEY (volume_group_id, volume_group_purpose);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_val_volgrp_purp_vgpurp ON volume_group_purpose USING btree (volume_group_purpose);
CREATE INDEX xif_val_volgrp_purp_vgid ON volume_group_purpose USING btree (volume_group_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK volume_group_purpose and volume_group
ALTER TABLE volume_group_purpose
	ADD CONSTRAINT fk_val_volgrp_purp_vgid
	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id);
-- consider FK volume_group_purpose and val_volume_group_purpose
-- Skipping this FK since table does not exist yet
--ALTER TABLE volume_group_purpose
--	ADD CONSTRAINT fk_val_volgrp_purp_vgpurp
--	FOREIGN KEY (volume_group_purpose) REFERENCES val_volume_group_purpose(volume_group_purpose);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'volume_group_purpose');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'volume_group_purpose');
-- DONE DEALING WITH TABLE volume_group_purpose [2502088]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE logical_volume_purpose
CREATE TABLE logical_volume_purpose
(
	logical_volume_purpose	varchar(50) NOT NULL,
	logical_volume_id	integer NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'logical_volume_purpose', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE logical_volume_purpose ADD CONSTRAINT pk_logical_volume_purpose PRIMARY KEY (logical_volume_purpose, logical_volume_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_lvpurp_lvid ON logical_volume_purpose USING btree (logical_volume_id);
CREATE INDEX xif_lvpurp_val_lgpuprp ON logical_volume_purpose USING btree (logical_volume_purpose);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK logical_volume_purpose and logical_volume
ALTER TABLE logical_volume_purpose
	ADD CONSTRAINT fk_lvpurp_lvid
	FOREIGN KEY (logical_volume_id) REFERENCES logical_volume(logical_volume_id);
-- consider FK logical_volume_purpose and val_logical_volume_purpose
-- Skipping this FK since table does not exist yet
--ALTER TABLE logical_volume_purpose
--	ADD CONSTRAINT fk_lvpurp_val_lgpuprp
--	FOREIGN KEY (logical_volume_purpose) REFERENCES val_logical_volume_purpose(logical_volume_purpose);


-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'logical_volume_purpose');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'logical_volume_purpose');
-- DONE DEALING WITH TABLE logical_volume_purpose [2500379]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_logical_volume_purpose
CREATE TABLE val_logical_volume_purpose
(
	logical_volume_purpose	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_logical_volume_purpose', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_logical_volume_purpose ADD CONSTRAINT pk_val_logical_volume_purpose PRIMARY KEY (logical_volume_purpose);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_logical_volume_purpose and logical_volume_purpose
ALTER TABLE logical_volume_purpose
	ADD CONSTRAINT fk_lvpurp_val_lgpuprp
	FOREIGN KEY (logical_volume_purpose) REFERENCES val_logical_volume_purpose(logical_volume_purpose);

-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_logical_volume_purpose');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_logical_volume_purpose');
-- DONE DEALING WITH TABLE val_logical_volume_purpose [2501561]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_physicalish_volume_type
CREATE TABLE val_physicalish_volume_type
(
	physicalish_volume_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_physicalish_volume_type', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_physicalish_volume_type ADD CONSTRAINT pk_val_physicalish_volume_type PRIMARY KEY (physicalish_volume_type);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_physicalish_volume_type and physicalish_volume
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physicalish_vol_pvtype
	FOREIGN KEY (physicalish_volume_type) REFERENCES val_physicalish_volume_type(physicalish_volume_type);

-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_physicalish_volume_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_physicalish_volume_type');
-- DONE DEALING WITH TABLE val_physicalish_volume_type [2501721]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_volume_group_purpose
CREATE TABLE val_volume_group_purpose
(
	volume_group_purpose	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_volume_group_purpose', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_volume_group_purpose ADD CONSTRAINT pk_val_volume_group_purpose PRIMARY KEY (volume_group_purpose);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_volume_group_purpose and volume_group_purpose
ALTER TABLE volume_group_purpose
	ADD CONSTRAINT fk_val_volgrp_purp_vgpurp
	FOREIGN KEY (volume_group_purpose) REFERENCES val_volume_group_purpose(volume_group_purpose);

-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_volume_group_purpose');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_volume_group_purpose');
-- DONE DEALING WITH TABLE val_volume_group_purpose [2501956]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_volume_group_type
CREATE TABLE val_volume_group_type
(
	volume_group_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_volume_group_type', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_volume_group_type ADD CONSTRAINT pk_volume_group_type PRIMARY KEY (volume_group_type);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_volume_group_type and volume_group
ALTER TABLE volume_group
	ADD CONSTRAINT fk_volgrp_volgrp_type
	FOREIGN KEY (volume_group_type) REFERENCES val_volume_group_type(volume_group_type);

-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_volume_group_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_volume_group_type');
-- DONE DEALING WITH TABLE val_volume_group_type [2501972]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE network_interface [2461025]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'network_interface', 'network_interface');

-- FOREIGN KEYS FROM
ALTER TABLE ip_group_network_interface DROP CONSTRAINT IF EXISTS fk_ipgrp_netint_netint_id;
ALTER TABLE network_interface_netblock DROP CONSTRAINT IF EXISTS fk_netint_nb_nblk_id;
ALTER TABLE static_route DROP CONSTRAINT IF EXISTS fk_statrt_netintdst_id;
ALTER TABLE network_interface_purpose DROP CONSTRAINT IF EXISTS fk_netint_purp_dev_ni_id;
ALTER TABLE network_service DROP CONSTRAINT IF EXISTS fk_netsvc_netint_id;
ALTER TABLE static_route_template DROP CONSTRAINT IF EXISTS fk_static_rt_net_interface;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS fk_netint_netblk_v4id;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS fk_net_int_lgl_port_id;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS fk_network_int_phys_port_devid;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS fk_netint_device_id;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS fk_netint_netinttyp_id;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS fk_netint_ref_parentnetint;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'network_interface');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS ak_net_int_devid_netintid;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS fk_netint_devid_name;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS pk_network_interface_id;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif_net_int_lgl_port_id";
DROP INDEX IF EXISTS "jazzhands"."idx_netint_shouldmonitor";
DROP INDEX IF EXISTS "jazzhands"."xif_netint_prim_v4id";
DROP INDEX IF EXISTS "jazzhands"."xif_netint_netdev_id";
DROP INDEX IF EXISTS "jazzhands"."xif_net_int_phs_port_devid";
DROP INDEX IF EXISTS "jazzhands"."xif_netint_parentnetint";
DROP INDEX IF EXISTS "jazzhands"."xif_netint_typeid";
DROP INDEX IF EXISTS "jazzhands"."idx_netint_isifaceup";
DROP INDEX IF EXISTS "jazzhands"."idx_netint_providesnat";
DROP INDEX IF EXISTS "jazzhands"."idx_netint_shouldmange";
DROP INDEX IF EXISTS "jazzhands"."idx_netint_provides_dhcp";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS ckc_is_interface_up_network_;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS ckc_netint_parent_r_1604677531;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS ckc_provides_dhcp_network_;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS ckc_provides_nat_network_;
ALTER TABLE jazzhands.network_interface DROP CONSTRAINT IF EXISTS ckc_should_manage_network_;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_network_interface ON jazzhands.network_interface;
DROP TRIGGER IF EXISTS trigger_net_int_nb_single_address ON jazzhands.network_interface;
DROP TRIGGER IF EXISTS trig_userlog_network_interface ON jazzhands.network_interface;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'network_interface');
---- BEGIN audit.network_interface TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'network_interface');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."network_interface_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'network_interface');
---- DONE audit.network_interface TEARDOWN


ALTER TABLE network_interface RENAME TO network_interface_v60;
ALTER TABLE audit.network_interface RENAME TO network_interface_v60;

CREATE TABLE network_interface
(
	network_interface_id	integer NOT NULL,
	device_id	integer NOT NULL,
	network_interface_name	varchar(255)  NULL,
	description	varchar(255)  NULL,
	parent_network_interface_id	integer  NULL,
	parent_relation_type	varchar(255)  NULL,
	netblock_id	integer  NULL,
	physical_port_id	integer  NULL,
	slot_id	integer  NULL,
	logical_port_id	integer  NULL,
	network_interface_type	varchar(50) NOT NULL,
	is_interface_up	character(1) NOT NULL,
	mac_addr	macaddr  NULL,
	should_monitor	varchar(255) NOT NULL,
	provides_nat	character(1) NOT NULL,
	should_manage	character(1) NOT NULL,
	provides_dhcp	character(1) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'network_interface', false);
ALTER TABLE network_interface
	ALTER network_interface_id
	SET DEFAULT nextval('network_interface_network_interface_id_seq'::regclass);
ALTER TABLE network_interface
	ALTER is_interface_up
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE network_interface
	ALTER provides_nat
	SET DEFAULT 'N'::bpchar;
ALTER TABLE network_interface
	ALTER should_manage
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE network_interface
	ALTER provides_dhcp
	SET DEFAULT 'N'::bpchar;
INSERT INTO network_interface (
	network_interface_id,
	device_id,
	network_interface_name,
	description,
	parent_network_interface_id,
	parent_relation_type,
	netblock_id,
	physical_port_id,
	slot_id,		-- new column (slot_id)
	logical_port_id,
	network_interface_type,
	is_interface_up,
	mac_addr,
	should_monitor,
	provides_nat,
	should_manage,
	provides_dhcp,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	network_interface_id,
	device_id,
	network_interface_name,
	description,
	parent_network_interface_id,
	parent_relation_type,
	netblock_id,
	physical_port_id,
	NULL,		-- new column (slot_id)
	logical_port_id,
	network_interface_type,
	is_interface_up,
	mac_addr,
	should_monitor,
	provides_nat,
	should_manage,
	provides_dhcp,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM network_interface_v60;

INSERT INTO audit.network_interface (
	network_interface_id,
	device_id,
	network_interface_name,
	description,
	parent_network_interface_id,
	parent_relation_type,
	netblock_id,
	physical_port_id,
	slot_id,		-- new column (slot_id)
	logical_port_id,
	network_interface_type,
	is_interface_up,
	mac_addr,
	should_monitor,
	provides_nat,
	should_manage,
	provides_dhcp,
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
	device_id,
	network_interface_name,
	description,
	parent_network_interface_id,
	parent_relation_type,
	netblock_id,
	physical_port_id,
	NULL,		-- new column (slot_id)
	logical_port_id,
	network_interface_type,
	is_interface_up,
	mac_addr,
	should_monitor,
	provides_nat,
	should_manage,
	provides_dhcp,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.network_interface_v60;

ALTER TABLE network_interface
	ALTER network_interface_id
	SET DEFAULT nextval('network_interface_network_interface_id_seq'::regclass);
ALTER TABLE network_interface
	ALTER is_interface_up
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE network_interface
	ALTER provides_nat
	SET DEFAULT 'N'::bpchar;
ALTER TABLE network_interface
	ALTER should_manage
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE network_interface
	ALTER provides_dhcp
	SET DEFAULT 'N'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE network_interface ADD CONSTRAINT pk_network_interface_id PRIMARY KEY (network_interface_id);
ALTER TABLE network_interface ADD CONSTRAINT fk_netint_devid_name UNIQUE (device_id, network_interface_name);
ALTER TABLE network_interface ADD CONSTRAINT ak_net_int_devid_netintid UNIQUE (network_interface_id, device_id);

-- Table/Column Comments
COMMENT ON COLUMN network_interface.physical_port_id IS 'historical column to be dropped in the next release after tools use slot_id.  matches slot_id by trigger.';
COMMENT ON COLUMN network_interface.slot_id IS 'to be dropped after transition to logical_ports are complete.';
-- INDEXES
CREATE INDEX idx_netint_isifaceup ON network_interface USING btree (is_interface_up);
CREATE INDEX idx_netint_provides_dhcp ON network_interface USING btree (provides_dhcp);
CREATE INDEX idx_netint_shouldmange ON network_interface USING btree (should_manage);
CREATE INDEX idx_netint_providesnat ON network_interface USING btree (provides_nat);
CREATE INDEX xif_netint_prim_v4id ON network_interface USING btree (netblock_id);
CREATE INDEX idx_netint_shouldmonitor ON network_interface USING btree (should_monitor);
CREATE INDEX xif_net_int_lgl_port_id ON network_interface USING btree (logical_port_id);
CREATE INDEX xif_netint_slot_id ON network_interface USING btree (slot_id);
CREATE INDEX xif_net_int_phys_port_id ON network_interface USING btree (physical_port_id);
CREATE INDEX xif_netint_typeid ON network_interface USING btree (network_interface_type);
CREATE INDEX xif_netint_parentnetint ON network_interface USING btree (parent_network_interface_id);
CREATE INDEX xif_netint_netdev_id ON network_interface USING btree (device_id);

-- CHECK CONSTRAINTS
ALTER TABLE network_interface ADD CONSTRAINT ckc_is_interface_up_network_
	CHECK ((is_interface_up = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_interface_up)::text = upper((is_interface_up)::text)));
ALTER TABLE network_interface ADD CONSTRAINT ckc_netint_parent_r_1604677531
	CHECK ((parent_relation_type)::text = ANY ((ARRAY['NONE'::character varying, 'SUBINTERFACE'::character varying, 'SECONDARY'::character varying])::text[]));
ALTER TABLE network_interface ADD CONSTRAINT ckc_should_manage_network_
	CHECK ((should_manage = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((should_manage)::text = upper((should_manage)::text)));
ALTER TABLE network_interface ADD CONSTRAINT ckc_provides_nat_network_
	CHECK ((provides_nat = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((provides_nat)::text = upper((provides_nat)::text)));
ALTER TABLE network_interface ADD CONSTRAINT ckc_provides_dhcp_network_
	CHECK ((provides_dhcp = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((provides_dhcp)::text = upper((provides_dhcp)::text)));

-- FOREIGN KEYS FROM
-- consider FK network_interface and static_route_template
ALTER TABLE static_route_template
	ADD CONSTRAINT fk_static_rt_net_interface
	FOREIGN KEY (network_interface_dst_id) REFERENCES network_interface(network_interface_id);
-- consider FK network_interface and network_service
ALTER TABLE network_service
	ADD CONSTRAINT fk_netsvc_netint_id
	FOREIGN KEY (network_interface_id) REFERENCES network_interface(network_interface_id);
-- consider FK network_interface and network_interface_purpose
ALTER TABLE network_interface_purpose
	ADD CONSTRAINT fk_netint_purp_dev_ni_id
	FOREIGN KEY (network_interface_id, device_id) REFERENCES network_interface(network_interface_id, device_id);
-- consider FK network_interface and static_route
ALTER TABLE static_route
	ADD CONSTRAINT fk_statrt_netintdst_id
	FOREIGN KEY (network_interface_dst_id) REFERENCES network_interface(network_interface_id);
-- consider FK network_interface and network_interface_netblock
ALTER TABLE network_interface_netblock
	ADD CONSTRAINT fk_netint_nb_nblk_id
	FOREIGN KEY (network_interface_id) REFERENCES network_interface(network_interface_id) DEFERRABLE;
-- consider FK network_interface and ip_group_network_interface
ALTER TABLE ip_group_network_interface
	ADD CONSTRAINT fk_ipgrp_netint_netint_id
	FOREIGN KEY (network_interface_id) REFERENCES network_interface(network_interface_id);

-- FOREIGN KEYS TO
-- consider FK network_interface and netblock
ALTER TABLE network_interface
	ADD CONSTRAINT fk_netint_netblk_v4id
	FOREIGN KEY (netblock_id) REFERENCES netblock(netblock_id);
-- consider FK network_interface and logical_port
ALTER TABLE network_interface
	ADD CONSTRAINT fk_net_int_lgl_port_id
	FOREIGN KEY (logical_port_id) REFERENCES logical_port(logical_port_id);
-- consider FK network_interface and device
ALTER TABLE network_interface
	ADD CONSTRAINT fk_netint_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK network_interface and slot
ALTER TABLE network_interface
	ADD CONSTRAINT fk_netint_slot_id
	FOREIGN KEY (slot_id) REFERENCES slot(slot_id);
-- consider FK network_interface and val_network_interface_type
ALTER TABLE network_interface
	ADD CONSTRAINT fk_netint_netinttyp_id
	FOREIGN KEY (network_interface_type) REFERENCES val_network_interface_type(network_interface_type);
-- consider FK network_interface and slot
ALTER TABLE network_interface
	ADD CONSTRAINT fk_net_int_phys_port_id
	FOREIGN KEY (physical_port_id) REFERENCES slot(slot_id);
-- consider FK network_interface and network_interface
ALTER TABLE network_interface
	ADD CONSTRAINT fk_netint_ref_parentnetint
	FOREIGN KEY (parent_network_interface_id) REFERENCES network_interface(network_interface_id);

-- TRIGGERS
CREATE TRIGGER trigger_net_int_physical_id_to_slot_id_enforce BEFORE INSERT OR UPDATE OF physical_port_id, slot_id ON network_interface FOR EACH ROW EXECUTE PROCEDURE net_int_physical_id_to_slot_id_enforce();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_net_int_nb_single_address BEFORE INSERT OR UPDATE OF netblock_id ON network_interface FOR EACH ROW EXECUTE PROCEDURE net_int_nb_single_address();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'network_interface');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'network_interface');
ALTER SEQUENCE network_interface_network_interface_id_seq
	 OWNED BY network_interface.network_interface_id;
DROP TABLE IF EXISTS network_interface_v60;
DROP TABLE IF EXISTS audit.network_interface_v60;
-- DONE DEALING WITH TABLE network_interface [2500460]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE device [2460414]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'device', 'device');

-- FOREIGN KEYS FROM
ALTER TABLE device_management_controller DROP CONSTRAINT IF EXISTS fk_dvc_mgmt_ctrl_mgr_dev_id;
ALTER TABLE chassis_location DROP CONSTRAINT IF EXISTS fk_chass_loc_chass_devid;
ALTER TABLE device_layer2_network DROP CONSTRAINT IF EXISTS fk_device_l2_net_devid;
ALTER TABLE device_management_controller DROP CONSTRAINT IF EXISTS fk_dev_mgmt_ctlr_dev_id;
ALTER TABLE snmp_commstr DROP CONSTRAINT IF EXISTS fk_snmpstr_device_id;
ALTER TABLE mlag_peering DROP CONSTRAINT IF EXISTS fk_mlag_peering_devid1;
ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_l1conn_ref_device;
ALTER TABLE mlag_peering DROP CONSTRAINT IF EXISTS fk_mlag_peering_devid2;
ALTER TABLE network_interface_purpose DROP CONSTRAINT IF EXISTS fk_netint_purpose_device_id;
ALTER TABLE network_service DROP CONSTRAINT IF EXISTS fk_netsvc_device_id;
ALTER TABLE device_ticket DROP CONSTRAINT IF EXISTS fk_dev_tkt_dev_id;
ALTER TABLE static_route DROP CONSTRAINT IF EXISTS fk_statrt_devsrc_id;
ALTER TABLE network_interface DROP CONSTRAINT IF EXISTS fk_netint_device_id;
ALTER TABLE device_encapsulation_domain DROP CONSTRAINT IF EXISTS fk_dev_encap_domain_devid;
ALTER TABLE device_ssh_key DROP CONSTRAINT IF EXISTS fk_dev_ssh_key_ssh_key_id;
ALTER TABLE device_collection_device DROP CONSTRAINT IF EXISTS fk_devcolldev_dev_id;
ALTER TABLE device_note DROP CONSTRAINT IF EXISTS fk_device_note_device;
ALTER TABLE physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_dev_id;
ALTER TABLE device_power_interface DROP CONSTRAINT IF EXISTS fk_device_device_power_supp;
ALTER TABLE jazzhands.physicalish_volume DROP CONSTRAINT IF EXISTS fk_physvol_device_id;
ALTER TABLE jazzhands.device_type DROP CONSTRAINT IF EXISTS fk_dev_typ_tmplt_dev_typ_id;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_comp_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_chasloc_chass_devid;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_ref_mgmt_proto;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_site_code;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_ref_voesymbtrk;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_dev_val_status;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_rack_location_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_chass_loc_id_mod_enfc;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_fk_voe;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_id_dnsrecord;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_company__id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_asset_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_devtp_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_ref_parent_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_device_dev_v_svcenv;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS fk_dev_os_id;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'device');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS pk_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ak_device_rack_location_id;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ak_device_chassis_location_id;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_dev_ismonitored";
DROP INDEX IF EXISTS "jazzhands"."idx_device_type_location";
DROP INDEX IF EXISTS "jazzhands"."xif_dev_chass_loc_id_mod_enfc";
DROP INDEX IF EXISTS "jazzhands"."xif_device_comp_id";
DROP INDEX IF EXISTS "jazzhands"."xif_device_fk_voe";
DROP INDEX IF EXISTS "jazzhands"."xif_device_id_dnsrecord";
DROP INDEX IF EXISTS "jazzhands"."xif_device_asset_id";
DROP INDEX IF EXISTS "jazzhands"."xif_dev_os_id";
DROP INDEX IF EXISTS "jazzhands"."xif_device_dev_v_svcenv";
DROP INDEX IF EXISTS "jazzhands"."xif_device_dev_val_status";
DROP INDEX IF EXISTS "jazzhands"."xif_device_company__id";
DROP INDEX IF EXISTS "jazzhands"."xif_device_site_code";
DROP INDEX IF EXISTS "jazzhands"."idx_dev_islclymgd";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_should_fetch_conf_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069059;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069052;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069060;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_monitored_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_locally_manage_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069057;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS sys_c0069051;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS ckc_is_virtual_device_device;
ALTER TABLE jazzhands.device DROP CONSTRAINT IF EXISTS dev_osid_notnull;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_device ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_audit_device ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_delete_per_device_device_collection ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_verify_device_voe ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_device_one_location_validate ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_update_per_device_device_collection ON jazzhands.device;
DROP TRIGGER IF EXISTS trigger_validate_device_component_assignment ON jazzhands.device;
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


ALTER TABLE device RENAME TO device_v60;
ALTER TABLE audit.device RENAME TO device_v60;

CREATE TABLE device
(
	device_id	integer NOT NULL,
	component_id	integer  NULL,
	device_type_id	integer NOT NULL,
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
	component_id,
	device_type_id,
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
	component_id,
	device_type_id,
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
FROM device_v60;

INSERT INTO audit.device (
	device_id,
	component_id,
	device_type_id,
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
	component_id,
	device_type_id,
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
FROM audit.device_v60;

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
ALTER TABLE device ADD CONSTRAINT ak_device_rack_location_id UNIQUE (rack_location_id);
ALTER TABLE device ADD CONSTRAINT ak_device_chassis_location_id UNIQUE (chassis_location_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX idx_dev_ismonitored ON device USING btree (is_monitored);
CREATE INDEX idx_device_type_location ON device USING btree (device_type_id);
CREATE INDEX xif_dev_chass_loc_id_mod_enfc ON device USING btree (chassis_location_id, parent_device_id, device_type_id);
CREATE INDEX xif_device_comp_id ON device USING btree (component_id);
CREATE INDEX xif_device_fk_voe ON device USING btree (voe_id);
CREATE INDEX xif_device_id_dnsrecord ON device USING btree (identifying_dns_record_id);
CREATE INDEX xif_device_asset_id ON device USING btree (asset_id);
CREATE INDEX xif_device_dev_v_svcenv ON device USING btree (service_environment_id);
CREATE INDEX xif_dev_os_id ON device USING btree (operating_system_id);
CREATE INDEX xif_device_dev_val_status ON device USING btree (device_status);
CREATE INDEX xif_device_site_code ON device USING btree (site_code);
CREATE INDEX idx_dev_islclymgd ON device USING btree (is_locally_managed);

-- CHECK CONSTRAINTS
ALTER TABLE device ADD CONSTRAINT sys_c0069057
	CHECK (is_monitored IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT sys_c0069051
	CHECK (device_id IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT dev_osid_notnull
	CHECK (operating_system_id IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT ckc_is_virtual_device_device
	CHECK ((is_virtual_device = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_virtual_device)::text = upper((is_virtual_device)::text)));
ALTER TABLE device ADD CONSTRAINT sys_c0069059
	CHECK (is_virtual_device IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT ckc_should_fetch_conf_device
	CHECK ((should_fetch_config = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((should_fetch_config)::text = upper((should_fetch_config)::text)));
ALTER TABLE device ADD CONSTRAINT ckc_is_locally_manage_device
	CHECK ((is_locally_managed = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_locally_managed)::text = upper((is_locally_managed)::text)));
ALTER TABLE device ADD CONSTRAINT ckc_is_monitored_device
	CHECK ((is_monitored = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ((is_monitored)::text = upper((is_monitored)::text)));
ALTER TABLE device ADD CONSTRAINT sys_c0069060
	CHECK (should_fetch_config IS NOT NULL);
ALTER TABLE device ADD CONSTRAINT sys_c0069052
	CHECK (device_type_id IS NOT NULL);

-- FOREIGN KEYS FROM
-- consider FK device and device_type
ALTER TABLE device_type
	ADD CONSTRAINT fk_dev_typ_tmplt_dev_typ_id
	FOREIGN KEY (template_device_id) REFERENCES device(device_id);
-- consider FK device and device_collection_device
ALTER TABLE device_collection_device
	ADD CONSTRAINT fk_devcolldev_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_note
ALTER TABLE device_note
	ADD CONSTRAINT fk_device_note_device
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_encapsulation_domain
ALTER TABLE device_encapsulation_domain
	ADD CONSTRAINT fk_dev_encap_domain_devid
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_ssh_key
ALTER TABLE device_ssh_key
	ADD CONSTRAINT fk_dev_ssh_key_ssh_key_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and network_interface
ALTER TABLE network_interface
	ADD CONSTRAINT fk_netint_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and mlag_peering
ALTER TABLE mlag_peering
	ADD CONSTRAINT fk_mlag_peering_devid2
	FOREIGN KEY (device2_id) REFERENCES device(device_id);
-- consider FK device and network_interface_purpose
ALTER TABLE network_interface_purpose
	ADD CONSTRAINT fk_netint_purpose_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and network_service
ALTER TABLE network_service
	ADD CONSTRAINT fk_netsvc_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_ticket
ALTER TABLE device_ticket
	ADD CONSTRAINT fk_dev_tkt_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and static_route
ALTER TABLE static_route
	ADD CONSTRAINT fk_statrt_devsrc_id
	FOREIGN KEY (device_src_id) REFERENCES device(device_id);
-- consider FK device and physicalish_volume
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physvol_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and mlag_peering
ALTER TABLE mlag_peering
	ADD CONSTRAINT fk_mlag_peering_devid1
	FOREIGN KEY (device1_id) REFERENCES device(device_id);
-- consider FK device and snmp_commstr
ALTER TABLE snmp_commstr
	ADD CONSTRAINT fk_snmpstr_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_management_controller
ALTER TABLE device_management_controller
	ADD CONSTRAINT fk_dvc_mgmt_ctrl_mgr_dev_id
	FOREIGN KEY (manager_device_id) REFERENCES device(device_id);
-- consider FK device and chassis_location
ALTER TABLE chassis_location
	ADD CONSTRAINT fk_chass_loc_chass_devid
	FOREIGN KEY (chassis_device_id) REFERENCES device(device_id) DEFERRABLE;
-- consider FK device and device_management_controller
ALTER TABLE device_management_controller
	ADD CONSTRAINT fk_dev_mgmt_ctlr_dev_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);
-- consider FK device and device_layer2_network
ALTER TABLE device_layer2_network
	ADD CONSTRAINT fk_device_l2_net_devid
	FOREIGN KEY (device_id) REFERENCES device(device_id);

-- FOREIGN KEYS TO
-- consider FK device and dns_record
ALTER TABLE device
	ADD CONSTRAINT fk_device_id_dnsrecord
	FOREIGN KEY (identifying_dns_record_id) REFERENCES dns_record(dns_record_id);
-- consider FK device and voe
ALTER TABLE device
	ADD CONSTRAINT fk_device_fk_voe
	FOREIGN KEY (voe_id) REFERENCES voe(voe_id);
-- consider FK device and rack_location
ALTER TABLE device
	ADD CONSTRAINT fk_dev_rack_location_id
	FOREIGN KEY (rack_location_id) REFERENCES rack_location(rack_location_id);
-- consider FK device and operating_system
ALTER TABLE device
	ADD CONSTRAINT fk_dev_os_id
	FOREIGN KEY (operating_system_id) REFERENCES operating_system(operating_system_id);
-- consider FK device and chassis_location
ALTER TABLE device
	ADD CONSTRAINT fk_dev_chass_loc_id_mod_enfc
	FOREIGN KEY (chassis_location_id, parent_device_id, device_type_id) REFERENCES chassis_location(chassis_location_id, chassis_device_id, module_device_type_id) DEFERRABLE;
-- consider FK device and voe_symbolic_track
ALTER TABLE device
	ADD CONSTRAINT fk_device_ref_voesymbtrk
	FOREIGN KEY (voe_symbolic_track_id) REFERENCES voe_symbolic_track(voe_symbolic_track_id);
-- consider FK device and val_device_status
ALTER TABLE device
	ADD CONSTRAINT fk_device_dev_val_status
	FOREIGN KEY (device_status) REFERENCES val_device_status(device_status);
-- consider FK device and service_environment
ALTER TABLE device
	ADD CONSTRAINT fk_device_dev_v_svcenv
	FOREIGN KEY (service_environment_id) REFERENCES service_environment(service_environment_id);
-- consider FK device and val_device_auto_mgmt_protocol
ALTER TABLE device
	ADD CONSTRAINT fk_dev_ref_mgmt_proto
	FOREIGN KEY (auto_mgmt_protocol) REFERENCES val_device_auto_mgmt_protocol(auto_mgmt_protocol);
-- consider FK device and site
ALTER TABLE device
	ADD CONSTRAINT fk_device_site_code
	FOREIGN KEY (site_code) REFERENCES site(site_code);
-- consider FK device and asset
ALTER TABLE device
	ADD CONSTRAINT fk_device_asset_id
	FOREIGN KEY (asset_id) REFERENCES asset(asset_id);
-- consider FK device and chassis_location
ALTER TABLE device
	ADD CONSTRAINT fk_chasloc_chass_devid
	FOREIGN KEY (chassis_location_id) REFERENCES chassis_location(chassis_location_id) DEFERRABLE;
-- consider FK device and device_type
ALTER TABLE device
	ADD CONSTRAINT fk_dev_devtp_id
	FOREIGN KEY (device_type_id) REFERENCES device_type(device_type_id);
-- consider FK device and device
ALTER TABLE device
	ADD CONSTRAINT fk_device_ref_parent_device
	FOREIGN KEY (parent_device_id) REFERENCES device(device_id);
-- consider FK device and component
ALTER TABLE device
	ADD CONSTRAINT fk_device_comp_id
	FOREIGN KEY (component_id) REFERENCES component(component_id);

-- TRIGGERS
CREATE TRIGGER trigger_device_one_location_validate BEFORE INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE device_one_location_validate();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_verify_device_voe BEFORE INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE verify_device_voe();

-- XXX - may need to include trigger function
CREATE CONSTRAINT TRIGGER trigger_validate_device_component_assignment AFTER INSERT OR UPDATE OF device_type_id, component_id ON device DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE validate_device_component_assignment();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_delete_per_device_device_collection BEFORE DELETE ON device FOR EACH ROW EXECUTE PROCEDURE delete_per_device_device_collection();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_update_per_device_device_collection AFTER INSERT OR UPDATE ON device FOR EACH ROW EXECUTE PROCEDURE update_per_device_device_collection();

-- XXX - may need to include trigger function
CREATE TRIGGER trigger_create_device_component BEFORE INSERT ON device FOR EACH ROW EXECUTE PROCEDURE create_device_component_by_trigger();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'device');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'device');
ALTER SEQUENCE device_device_id_seq
	 OWNED BY device.device_id;
DROP TABLE IF EXISTS device_v60;
DROP TABLE IF EXISTS audit.device_v60;
-- DONE DEALING WITH TABLE device [2499895]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE physical_connection [2461320]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'physical_connection', 'physical_connection');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.physical_connection DROP CONSTRAINT IF EXISTS fk_physical_conn_v_cable_type;
ALTER TABLE jazzhands.physical_connection DROP CONSTRAINT IF EXISTS fk_patch_panel_port1;
ALTER TABLE jazzhands.physical_connection DROP CONSTRAINT IF EXISTS fk_patch_panel_port2;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'physical_connection');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.physical_connection DROP CONSTRAINT IF EXISTS ak_uq_physical_port_id2;
ALTER TABLE jazzhands.physical_connection DROP CONSTRAINT IF EXISTS ak_uq_physical_port_id1;
ALTER TABLE jazzhands.physical_connection DROP CONSTRAINT IF EXISTS pk_physical_connection;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_physconn_cabletype";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_physical_connection ON jazzhands.physical_connection;
DROP TRIGGER IF EXISTS trigger_verify_physical_connection ON jazzhands.physical_connection;
DROP TRIGGER IF EXISTS trig_userlog_physical_connection ON jazzhands.physical_connection;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'physical_connection');
---- BEGIN audit.physical_connection TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'physical_connection');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."physical_connection_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'physical_connection');
---- DONE audit.physical_connection TEARDOWN


ALTER TABLE physical_connection RENAME TO physical_connection_v60;
ALTER TABLE audit.physical_connection RENAME TO physical_connection_v60;

CREATE TABLE physical_connection
(
	physical_connection_id	integer NOT NULL,
	slot1_id	integer  NULL,
	slot2_id	integer  NULL,
	cable_type	varchar(50) NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'physical_connection', false);
ALTER TABLE physical_connection
	ALTER physical_connection_id
	SET DEFAULT nextval('physical_connection_physical_connection_id_seq'::regclass);
INSERT INTO physical_connection (
	physical_connection_id,
	slot1_id,		-- new column (slot1_id)
	slot2_id,		-- new column (slot2_id)
	cable_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	physical_connection_id,
	NULL,		-- new column (slot1_id)
	NULL,		-- new column (slot2_id)
	cable_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM physical_connection_v60;

INSERT INTO audit.physical_connection (
	physical_connection_id,
	slot1_id,		-- new column (slot1_id)
	slot2_id,		-- new column (slot2_id)
	cable_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	physical_connection_id,
	NULL,		-- new column (slot1_id)
	NULL,		-- new column (slot2_id)
	cable_type,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.physical_connection_v60;

ALTER TABLE physical_connection
	ALTER physical_connection_id
	SET DEFAULT nextval('physical_connection_physical_connection_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE physical_connection ADD CONSTRAINT pk_physical_connection PRIMARY KEY (physical_connection_id);

-- Table/Column Comments
-- INDEXES
CREATE INDEX xif_physical_conn_v_cable_type ON physical_connection USING btree (cable_type);
CREATE INDEX xif_physconn_slot1_id ON physical_connection USING btree (slot1_id);
CREATE INDEX xif_physconn_slot2_id ON physical_connection USING btree (slot2_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK physical_connection and slot
ALTER TABLE physical_connection
	ADD CONSTRAINT fk_physconn_slot1_id
	FOREIGN KEY (slot1_id) REFERENCES slot(slot_id);
-- consider FK physical_connection and slot
ALTER TABLE physical_connection
	ADD CONSTRAINT fk_physconn_slot2_id
	FOREIGN KEY (slot2_id) REFERENCES slot(slot_id);
-- consider FK physical_connection and val_cable_type
ALTER TABLE physical_connection
	ADD CONSTRAINT fk_physical_conn_v_cable_type
	FOREIGN KEY (cable_type) REFERENCES val_cable_type(cable_type);

-- TRIGGERS
CREATE TRIGGER trigger_verify_physical_connection AFTER INSERT OR UPDATE ON physical_connection FOR EACH STATEMENT EXECUTE PROCEDURE verify_physical_connection();

-- XXX - may need to include trigger function
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'physical_connection');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'physical_connection');
ALTER SEQUENCE physical_connection_physical_connection_id_seq
	 OWNED BY physical_connection.physical_connection_id;
DROP TABLE IF EXISTS physical_connection_v60;
DROP TABLE IF EXISTS audit.physical_connection_v60;
-- DONE DEALING WITH TABLE physical_connection [2500759]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE physical_port [2461336]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'physical_port', 'physical_port');

-- FOREIGN KEYS FROM
ALTER TABLE physical_connection DROP CONSTRAINT IF EXISTS fk_patch_panel_port2;
ALTER TABLE network_interface DROP CONSTRAINT IF EXISTS fk_network_int_phys_port_devid;
ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_cnct_phys_port2;
ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_cnct_phys_port1;
ALTER TABLE physical_connection DROP CONSTRAINT IF EXISTS fk_patch_panel_port1;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_val_protocol;
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS fk_physical_fk_physic_val_port;
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_dev_id;
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_port_medium;
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS fk_physical_port_lgl_port_id;
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_ref_vportpurp;
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_val_port_speed;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'physical_port');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS pk_physical_port;
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS ak_physical_port_devnamtype;
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS iak_pport_dvid_pportid;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif4physical_port";
DROP INDEX IF EXISTS "jazzhands"."xif6physical_port";
DROP INDEX IF EXISTS "jazzhands"."idx_physport_device_id";
DROP INDEX IF EXISTS "jazzhands"."xif5physical_port";
DROP INDEX IF EXISTS "jazzhands"."xif7physical_port";
DROP INDEX IF EXISTS "jazzhands"."idx_physport_porttype";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.physical_port DROP CONSTRAINT IF EXISTS check_yes_no_1847015416;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_physical_port ON jazzhands.physical_port;
DROP TRIGGER IF EXISTS trig_userlog_physical_port ON jazzhands.physical_port;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'physical_port');
---- BEGIN audit.physical_port TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'physical_port');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."physical_port_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'physical_port');
---- DONE audit.physical_port TEARDOWN


ALTER TABLE physical_port RENAME TO physical_port_v60;
ALTER TABLE audit.physical_port RENAME TO physical_port_v60;



create or replace view physical_port
AS
SELECT	
	sl.slot_id			AS physical_port_id,
	d.device_id,
	sl.slot_name			AS port_name,
	st.slot_function		AS port_type,
	sl.description,
	st.slot_physical_interface_type	AS port_plug_style,
	NULL::text			AS port_medium,
	NULL::text			AS port_protocol,
	NULL::text			AS port_speed,
	sl.physical_label,
	NULL::text			AS port_purpose,
	NULL::integer			AS logical_port_id,
	NULL::integer			AS tcp_port,
	CASE WHEN ct.is_removable = 'Y' THEN 'N' ELSE 'Y' END AS is_hardwired,
	sl.data_ins_user,
	sl.data_ins_date,
	sl.data_upd_user,
	sl.data_upd_date
  FROM	slot sl 
	INNER JOIN slot_type st USING (slot_type_id)
	INNER JOIN device d USING (component_id)
	INNER JOIN component c USING (component_id)
	INNER JOIN component_type ct USING (component_type_id)
 WHERE	st.slot_function in ('network', 'serial', 'patchpanel')
;

delete from __recreate where type = 'view' and object = 'physical_port';
DROP TABLE IF EXISTS physical_port_v60;
DROP TABLE IF EXISTS audit.physical_port_v60;
-- DONE DEALING WITH TABLE physical_port [2507308]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE layer1_connection [2460833]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'layer1_connection', 'layer1_connection');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_stop_bits;
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_data_bits;
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_l1conn_circuit_id;
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_parity;
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_cnct_phys_port1;
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_cnct_phys_port2;
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_l1conn_ref_device;
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_flow_cntrl;
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_baud;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'layer1_connection');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS pk_layer1connetion;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_layer1conn_physport2";
DROP INDEX IF EXISTS "jazzhands"."idx_layer1conn_physport1";
DROP INDEX IF EXISTS "jazzhands"."idx_layer1conn_circuit_id";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.layer1_connection DROP CONSTRAINT IF EXISTS ckc_is_tcpsrv_enabled_layer1_c;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_verify_layer1_connection ON jazzhands.layer1_connection;
DROP TRIGGER IF EXISTS trig_userlog_layer1_connection ON jazzhands.layer1_connection;
DROP TRIGGER IF EXISTS trigger_audit_layer1_connection ON jazzhands.layer1_connection;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'layer1_connection');
---- BEGIN audit.layer1_connection TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'layer1_connection');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."layer1_connection_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'layer1_connection');
---- DONE audit.layer1_connection TEARDOWN


ALTER TABLE layer1_connection RENAME TO layer1_connection_v60;
ALTER TABLE audit.layer1_connection RENAME TO layer1_connection_v60;

CREATE VIEW layer1_connection AS
 WITH conn_props AS (
         SELECT component_property.inter_component_connection_id,
            component_property.component_property_name,
            component_property.component_property_type,
            component_property.property_value
           FROM component_property
          WHERE component_property.component_property_type::text = 'serial-connection'::text
        ), tcpsrv_device_id AS (
         SELECT component_property.inter_component_connection_id,
            device.device_id
           FROM component_property
             JOIN device USING (component_id)
          WHERE component_property.component_property_type::text = 'tcpsrv-connections'::text AND component_property.component_property_name::text = 'tcpsrv_device_id'::text
        ), tcpsrv_enabled AS (
         SELECT component_property.inter_component_connection_id,
            component_property.property_value
           FROM component_property
          WHERE component_property.component_property_type::text = 'tcpsrv-connections'::text AND component_property.component_property_name::text = 'tcpsrv_enabled'::text
        )
 SELECT icc.inter_component_connection_id AS layer1_connection_id,
    icc.slot1_id AS physical_port1_id,
    icc.slot2_id AS physical_port2_id,
    icc.circuit_id,
    baud.property_value::integer AS baud,
    dbits.property_value AS data_bits,
    sbits.property_value AS stop_bits,
    parity.property_value AS parity,
    flow.property_value AS flow_control,
    tcpsrv.device_id AS tcpsrv_device_id,
    COALESCE(tcpsrvon.property_value, 'N'::character varying) AS is_tcpsrv_enabled,
    icc.data_ins_user,
    icc.data_ins_date,
    icc.data_upd_user,
    icc.data_upd_date
   FROM inter_component_connection icc
     JOIN slot s1 ON icc.slot1_id = s1.slot_id
     JOIN slot_type st1 ON st1.slot_type_id = s1.slot_type_id
     JOIN slot s2 ON icc.slot2_id = s2.slot_id
     JOIN slot_type st2 ON st2.slot_type_id = s2.slot_type_id
     LEFT JOIN tcpsrv_device_id tcpsrv USING (inter_component_connection_id)
     LEFT JOIN tcpsrv_enabled tcpsrvon USING (inter_component_connection_id)
     LEFT JOIN conn_props baud ON baud.inter_component_connection_id = icc.inter_component_connection_id AND baud.component_property_name::text = 'baud'::text
     LEFT JOIN conn_props dbits ON dbits.inter_component_connection_id = icc.inter_component_connection_id AND dbits.component_property_name::text = 'data-bits'::text
     LEFT JOIN conn_props sbits ON sbits.inter_component_connection_id = icc.inter_component_connection_id AND sbits.component_property_name::text = 'stop-bits'::text
     LEFT JOIN conn_props parity ON parity.inter_component_connection_id = icc.inter_component_connection_id AND parity.component_property_name::text = 'parity'::text
     LEFT JOIN conn_props flow ON flow.inter_component_connection_id = icc.inter_component_connection_id AND flow.component_property_name::text = 'flow-control'::text
  WHERE (st1.slot_function::text = ANY (ARRAY['network'::character varying, 'serial'::character varying, 'patchpanel'::character varying]::text[])) OR (st1.slot_function::text = ANY (ARRAY['network'::character varying, 'serial'::character varying, 'patchpanel'::character varying]::text[]));

delete from __recreate where type = 'view' and object = 'layer1_connection';
DROP TABLE IF EXISTS layer1_connection_v60;
DROP TABLE IF EXISTS audit.layer1_connection_v60;
-- DONE DEALING WITH TABLE layer1_connection [2507313]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_port_protocol [2462339]

-- FOREIGN KEYS FROM
-- ALTER TABLE physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_val_protocol;
ALTER TABLE device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_dt_phsport_tmp_v_protocol;
ALTER TABLE val_port_protocol_speed DROP CONSTRAINT IF EXISTS fk_v_prt_proto_speed_proto;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_port_protocol');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_port_protocol DROP CONSTRAINT IF EXISTS pk_val_port_protocol;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_port_protocol ON jazzhands.val_port_protocol;
DROP TRIGGER IF EXISTS trig_userlog_val_port_protocol ON jazzhands.val_port_protocol;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_port_protocol');
---- BEGIN audit.val_port_protocol TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_port_protocol');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_port_protocol_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_port_protocol');
---- DONE audit.val_port_protocol TEARDOWN


ALTER TABLE val_port_protocol RENAME TO val_port_protocol_v60;
ALTER TABLE audit.val_port_protocol RENAME TO val_port_protocol_v60;

DROP TABLE IF EXISTS val_port_protocol_v60;
DROP TABLE IF EXISTS audit.val_port_protocol_v60;
-- DONE DEALING WITH OLD TABLE val_port_protocol [2462339]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_baud [2461888]

-- FOREIGN KEYS FROM
-- ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_baud;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_baud');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_baud DROP CONSTRAINT IF EXISTS pk_val_baud;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_baud ON jazzhands.val_baud;
DROP TRIGGER IF EXISTS trig_userlog_val_baud ON jazzhands.val_baud;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_baud');
---- BEGIN audit.val_baud TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_baud');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_baud_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_baud');
---- DONE audit.val_baud TEARDOWN


ALTER TABLE val_baud RENAME TO val_baud_v60;
ALTER TABLE audit.val_baud RENAME TO val_baud_v60;

DROP TABLE IF EXISTS val_baud_v60;
DROP TABLE IF EXISTS audit.val_baud_v60;
-- DONE DEALING WITH OLD TABLE val_baud [2461888]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_data_bits [2461981]

-- FOREIGN KEYS FROM
-- ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_data_bits;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_data_bits');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_data_bits DROP CONSTRAINT IF EXISTS pk_val_data_bits;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_data_bits ON jazzhands.val_data_bits;
DROP TRIGGER IF EXISTS trig_userlog_val_data_bits ON jazzhands.val_data_bits;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_data_bits');
---- BEGIN audit.val_data_bits TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_data_bits');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_data_bits_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_data_bits');
---- DONE audit.val_data_bits TEARDOWN


ALTER TABLE val_data_bits RENAME TO val_data_bits_v60;
ALTER TABLE audit.val_data_bits RENAME TO val_data_bits_v60;

DROP TABLE IF EXISTS val_data_bits_v60;
DROP TABLE IF EXISTS audit.val_data_bits_v60;
-- DONE DEALING WITH OLD TABLE val_data_bits [2461981]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_port_speed [2462367]

-- FOREIGN KEYS FROM
-- ALTER TABLE physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_val_port_speed;
ALTER TABLE val_port_protocol_speed DROP CONSTRAINT IF EXISTS fk_v_prt_proto_speed_speed;
ALTER TABLE device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_dt_phsport_tmp_val_prt_spd;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_port_speed');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_port_speed DROP CONSTRAINT IF EXISTS pk_val_port_speed;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_port_speed ON jazzhands.val_port_speed;
DROP TRIGGER IF EXISTS trig_userlog_val_port_speed ON jazzhands.val_port_speed;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_port_speed');
---- BEGIN audit.val_port_speed TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_port_speed');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_port_speed_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_port_speed');
---- DONE audit.val_port_speed TEARDOWN


ALTER TABLE val_port_speed RENAME TO val_port_speed_v60;
ALTER TABLE audit.val_port_speed RENAME TO val_port_speed_v60;

DROP TABLE IF EXISTS val_port_speed_v60;
DROP TABLE IF EXISTS audit.val_port_speed_v60;
-- DONE DEALING WITH OLD TABLE val_port_speed [2462367]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_stop_bits [2462551]

-- FOREIGN KEYS FROM
-- ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_stop_bits;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_stop_bits');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_stop_bits DROP CONSTRAINT IF EXISTS pk_val_stop_bits;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_stop_bits ON jazzhands.val_stop_bits;
DROP TRIGGER IF EXISTS trig_userlog_val_stop_bits ON jazzhands.val_stop_bits;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_stop_bits');
---- BEGIN audit.val_stop_bits TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_stop_bits');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_stop_bits_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_stop_bits');
---- DONE audit.val_stop_bits TEARDOWN


ALTER TABLE val_stop_bits RENAME TO val_stop_bits_v60;
ALTER TABLE audit.val_stop_bits RENAME TO val_stop_bits_v60;

DROP TABLE IF EXISTS val_stop_bits_v60;
DROP TABLE IF EXISTS audit.val_stop_bits_v60;
-- DONE DEALING WITH OLD TABLE val_stop_bits [2462551]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_port_medium [2462322]

-- FOREIGN KEYS FROM
ALTER TABLE device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_dt_phsport_tmpl_v_port_medm;
-- ALTER TABLE physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_port_medium;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.val_port_medium DROP CONSTRAINT IF EXISTS fk_val_prt_medm_prt_plug_typ;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_port_medium');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_port_medium DROP CONSTRAINT IF EXISTS pk_val_port_medium;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif1val_port_medium";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_val_port_medium ON jazzhands.val_port_medium;
DROP TRIGGER IF EXISTS trigger_audit_val_port_medium ON jazzhands.val_port_medium;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_port_medium');
---- BEGIN audit.val_port_medium TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_port_medium');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_port_medium_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_port_medium');
---- DONE audit.val_port_medium TEARDOWN


ALTER TABLE val_port_medium RENAME TO val_port_medium_v60;
ALTER TABLE audit.val_port_medium RENAME TO val_port_medium_v60;

DROP TABLE IF EXISTS val_port_medium_v60;
DROP TABLE IF EXISTS audit.val_port_medium_v60;
-- DONE DEALING WITH OLD TABLE val_port_medium [2462322]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_port_purpose [2462357]

-- FOREIGN KEYS FROM
-- ALTER TABLE physical_port DROP CONSTRAINT IF EXISTS fk_phys_port_ref_vportpurp;
ALTER TABLE device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_devtphyprttmpl_ref_vprtpurp;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_port_purpose');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_port_purpose DROP CONSTRAINT IF EXISTS pk_val_port_purpose;
-- INDEXES
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.val_port_purpose DROP CONSTRAINT IF EXISTS ckc_is_console_val_port;
ALTER TABLE jazzhands.val_port_purpose DROP CONSTRAINT IF EXISTS ckc_is_lom_val_port;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_val_port_purpose ON jazzhands.val_port_purpose;
DROP TRIGGER IF EXISTS trigger_audit_val_port_purpose ON jazzhands.val_port_purpose;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_port_purpose');
---- BEGIN audit.val_port_purpose TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_port_purpose');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_port_purpose_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_port_purpose');
---- DONE audit.val_port_purpose TEARDOWN


ALTER TABLE val_port_purpose RENAME TO val_port_purpose_v60;
ALTER TABLE audit.val_port_purpose RENAME TO val_port_purpose_v60;

DROP TABLE IF EXISTS val_port_purpose_v60;
DROP TABLE IF EXISTS audit.val_port_purpose_v60;
-- DONE DEALING WITH OLD TABLE val_port_purpose [2462357]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_port_plug_style [2462331]

-- FOREIGN KEYS FROM
-- Skipping this FK since table been dropped
--ALTER TABLE val_port_medium DROP CONSTRAINT IF EXISTS fk_val_prt_medm_prt_plug_typ;


-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_port_plug_style');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_port_plug_style DROP CONSTRAINT IF EXISTS pk_val_port_plug_style;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_port_plug_style ON jazzhands.val_port_plug_style;
DROP TRIGGER IF EXISTS trig_userlog_val_port_plug_style ON jazzhands.val_port_plug_style;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_port_plug_style');
---- BEGIN audit.val_port_plug_style TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_port_plug_style');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_port_plug_style_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_port_plug_style');
---- DONE audit.val_port_plug_style TEARDOWN


ALTER TABLE val_port_plug_style RENAME TO val_port_plug_style_v60;
ALTER TABLE audit.val_port_plug_style RENAME TO val_port_plug_style_v60;

DROP TABLE IF EXISTS val_port_plug_style_v60;
DROP TABLE IF EXISTS audit.val_port_plug_style_v60;
-- DONE DEALING WITH OLD TABLE val_port_plug_style [2462331]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE device_type_phys_port_templt [2460631]

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_dt_phs_port_templt_port_typ;
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_dt_phsport_tmp_val_prt_spd;
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_dt_phsport_tmp_v_protocol;
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_dt_phsport_tmpl_v_port_medm;
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_devtype_ref_devtphysprttmpl;
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_devtphyprttmpl_ref_vprtpurp;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'device_type_phys_port_templt');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS pk_device_type_phys_port_templ;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif3device_type_phys_port_temp";
DROP INDEX IF EXISTS "jazzhands"."xif4device_type_phys_port_temp";
DROP INDEX IF EXISTS "jazzhands"."xif6device_type_phys_port_temp";
DROP INDEX IF EXISTS "jazzhands"."xif5device_type_phys_port_temp";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS check_yes_no_400418313;
ALTER TABLE jazzhands.device_type_phys_port_templt DROP CONSTRAINT IF EXISTS ckc_dvtyp_physp_tmp_opt;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_device_type_phys_port_templt ON jazzhands.device_type_phys_port_templt;
DROP TRIGGER IF EXISTS trig_userlog_device_type_phys_port_templt ON jazzhands.device_type_phys_port_templt;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'device_type_phys_port_templt');
---- BEGIN audit.device_type_phys_port_templt TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'device_type_phys_port_templt');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."device_type_phys_port_templt_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'device_type_phys_port_templt');
---- DONE audit.device_type_phys_port_templt TEARDOWN


ALTER TABLE device_type_phys_port_templt RENAME TO device_type_phys_port_templt_v60;
ALTER TABLE audit.device_type_phys_port_templt RENAME TO device_type_phys_port_templt_v60;

DROP TABLE IF EXISTS device_type_phys_port_templt_v60;
DROP TABLE IF EXISTS audit.device_type_phys_port_templt_v60;
-- DONE DEALING WITH OLD TABLE device_type_phys_port_templt [2460631]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_port_protocol_speed [2462347]

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.val_port_protocol_speed DROP CONSTRAINT IF EXISTS fk_v_prt_proto_speed_proto;
ALTER TABLE jazzhands.val_port_protocol_speed DROP CONSTRAINT IF EXISTS fk_v_prt_proto_speed_speed;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_port_protocol_speed');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_port_protocol_speed DROP CONSTRAINT IF EXISTS pk_val_port_protocol_speed;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif1val_port_protocol_speed";
DROP INDEX IF EXISTS "jazzhands"."xif2val_port_protocol_speed";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_port_protocol_speed ON jazzhands.val_port_protocol_speed;
DROP TRIGGER IF EXISTS trig_userlog_val_port_protocol_speed ON jazzhands.val_port_protocol_speed;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_port_protocol_speed');
---- BEGIN audit.val_port_protocol_speed TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_port_protocol_speed');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_port_protocol_speed_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_port_protocol_speed');
---- DONE audit.val_port_protocol_speed TEARDOWN


ALTER TABLE val_port_protocol_speed RENAME TO val_port_protocol_speed_v60;
ALTER TABLE audit.val_port_protocol_speed RENAME TO val_port_protocol_speed_v60;

DROP TABLE IF EXISTS val_port_protocol_speed_v60;
DROP TABLE IF EXISTS audit.val_port_protocol_speed_v60;
-- DONE DEALING WITH OLD TABLE val_port_protocol_speed [2462347]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_port_type [2462375]

-- FOREIGN KEYS FROM
-- ALTER TABLE physical_port DROP CONSTRAINT IF EXISTS fk_physical_fk_physic_val_port;
-- Skipping this FK since table been dropped
--ALTER TABLE device_type_phys_port_templt DROP CONSTRAINT IF EXISTS fk_dt_phs_port_templt_port_typ;


-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_port_type');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_port_type DROP CONSTRAINT IF EXISTS pk_val_port_type;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_val_port_type ON jazzhands.val_port_type;
DROP TRIGGER IF EXISTS trigger_audit_val_port_type ON jazzhands.val_port_type;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_port_type');
---- BEGIN audit.val_port_type TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_port_type');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_port_type_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_port_type');
---- DONE audit.val_port_type TEARDOWN


ALTER TABLE val_port_type RENAME TO val_port_type_v60;
ALTER TABLE audit.val_port_type RENAME TO val_port_type_v60;

DROP TABLE IF EXISTS val_port_type_v60;
DROP TABLE IF EXISTS audit.val_port_type_v60;
-- DONE DEALING WITH OLD TABLE val_port_type [2462375]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE device_power_interface [2460561]

-- FOREIGN KEYS FROM
ALTER TABLE device_power_connection DROP CONSTRAINT IF EXISTS fk_dev_ps_dev_power_conn_srv;
ALTER TABLE device_power_connection DROP CONSTRAINT IF EXISTS fk_dev_ps_dev_power_conn_rpc;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device_power_interface DROP CONSTRAINT IF EXISTS fk_dev_pwr_int_pwr_plug;
ALTER TABLE jazzhands.device_power_interface DROP CONSTRAINT IF EXISTS fk_device_device_power_supp;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'device_power_interface');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.device_power_interface DROP CONSTRAINT IF EXISTS pk_device_power_interface;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif2device_power_interface";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.device_power_interface DROP CONSTRAINT IF EXISTS check_yes_no_2067088750;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_device_power_interface ON jazzhands.device_power_interface;
DROP TRIGGER IF EXISTS trigger_audit_device_power_interface ON jazzhands.device_power_interface;
DROP TRIGGER IF EXISTS trigger_device_power_port_sanity ON jazzhands.device_power_interface;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'device_power_interface');
---- BEGIN audit.device_power_interface TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'device_power_interface');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."device_power_interface_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'device_power_interface');
---- DONE audit.device_power_interface TEARDOWN


ALTER TABLE device_power_interface RENAME TO device_power_interface_v60;
ALTER TABLE audit.device_power_interface RENAME TO device_power_interface_v60;

DROP TABLE IF EXISTS device_power_interface_v60;
DROP TABLE IF EXISTS audit.device_power_interface_v60;
-- DONE DEALING WITH OLD TABLE device_power_interface [2460561]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_flow_control [2462113]

-- FOREIGN KEYS FROM
-- ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_flow_cntrl;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_flow_control');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_flow_control DROP CONSTRAINT IF EXISTS pk_val_flow_control;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_val_flow_control ON jazzhands.val_flow_control;
DROP TRIGGER IF EXISTS trigger_audit_val_flow_control ON jazzhands.val_flow_control;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_flow_control');
---- BEGIN audit.val_flow_control TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_flow_control');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_flow_control_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_flow_control');
---- DONE audit.val_flow_control TEARDOWN


ALTER TABLE val_flow_control RENAME TO val_flow_control_v60;
ALTER TABLE audit.val_flow_control RENAME TO val_flow_control_v60;

DROP TABLE IF EXISTS val_flow_control_v60;
DROP TABLE IF EXISTS audit.val_flow_control_v60;
-- DONE DEALING WITH OLD TABLE val_flow_control [2462113]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_power_plug_style [2462383]

-- FOREIGN KEYS FROM
ALTER TABLE device_type_power_port_templt DROP CONSTRAINT IF EXISTS fk_dev_pport_v_pwr_plug_style;
-- Skipping this FK since table been dropped
--ALTER TABLE device_power_interface DROP CONSTRAINT IF EXISTS fk_dev_pwr_int_pwr_plug;


-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_power_plug_style');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_power_plug_style DROP CONSTRAINT IF EXISTS pk_val_power_plug_style;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_power_plug_style ON jazzhands.val_power_plug_style;
DROP TRIGGER IF EXISTS trig_userlog_val_power_plug_style ON jazzhands.val_power_plug_style;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_power_plug_style');
---- BEGIN audit.val_power_plug_style TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_power_plug_style');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_power_plug_style_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_power_plug_style');
---- DONE audit.val_power_plug_style TEARDOWN


ALTER TABLE val_power_plug_style RENAME TO val_power_plug_style_v60;
ALTER TABLE audit.val_power_plug_style RENAME TO val_power_plug_style_v60;

DROP TABLE IF EXISTS val_power_plug_style_v60;
DROP TABLE IF EXISTS audit.val_power_plug_style_v60;
-- DONE DEALING WITH OLD TABLE val_power_plug_style [2462383]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE device_type_power_port_templt [2460647]

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device_type_power_port_templt DROP CONSTRAINT IF EXISTS fk_dev_pport_v_pwr_plug_style;
ALTER TABLE jazzhands.device_type_power_port_templt DROP CONSTRAINT IF EXISTS fk_dev_type_dev_pwr_prt_tmpl;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'device_type_power_port_templt');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.device_type_power_port_templt DROP CONSTRAINT IF EXISTS pk_device_type_power_port_temp;
-- INDEXES
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.device_type_power_port_templt DROP CONSTRAINT IF EXISTS ckc_dtyp_pwrtmp_opt;
ALTER TABLE jazzhands.device_type_power_port_templt DROP CONSTRAINT IF EXISTS ckc_provides_power_device_t;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_device_type_power_port_templt ON jazzhands.device_type_power_port_templt;
DROP TRIGGER IF EXISTS trigger_audit_device_type_power_port_templt ON jazzhands.device_type_power_port_templt;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'device_type_power_port_templt');
---- BEGIN audit.device_type_power_port_templt TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'device_type_power_port_templt');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."device_type_power_port_templt_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'device_type_power_port_templt');
---- DONE audit.device_type_power_port_templt TEARDOWN


ALTER TABLE device_type_power_port_templt RENAME TO device_type_power_port_templt_v60;
ALTER TABLE audit.device_type_power_port_templt RENAME TO device_type_power_port_templt_v60;

DROP TABLE IF EXISTS device_type_power_port_templt_v60;
DROP TABLE IF EXISTS audit.device_type_power_port_templt_v60;
-- DONE DEALING WITH OLD TABLE device_type_power_port_templt [2460647]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_parity [2462246]

-- FOREIGN KEYS FROM
-- ALTER TABLE layer1_connection DROP CONSTRAINT IF EXISTS fk_layer1_c_ref_v_parity;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_parity');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_parity DROP CONSTRAINT IF EXISTS pk_val_parity;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_val_parity ON jazzhands.val_parity;
DROP TRIGGER IF EXISTS trig_userlog_val_parity ON jazzhands.val_parity;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_parity');
---- BEGIN audit.val_parity TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_parity');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_parity_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_parity');
---- DONE audit.val_parity TEARDOWN


ALTER TABLE val_parity RENAME TO val_parity_v60;
ALTER TABLE audit.val_parity RENAME TO val_parity_v60;

DROP TABLE IF EXISTS val_parity_v60;
DROP TABLE IF EXISTS audit.val_parity_v60;
-- DONE DEALING WITH OLD TABLE val_parity [2462246]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE device_power_connection [2460550]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'device_power_connection', 'device_power_connection');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.device_power_connection DROP CONSTRAINT IF EXISTS fk_dev_ps_dev_power_conn_srv;
ALTER TABLE jazzhands.device_power_connection DROP CONSTRAINT IF EXISTS fk_dev_ps_dev_power_conn_rpc;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'device_power_connection');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.device_power_connection DROP CONSTRAINT IF EXISTS pk_device_power_connection;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_devpconn_svrdevpint";
DROP INDEX IF EXISTS "jazzhands"."idx_devpconn_rpcdevpint";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_device_power_connection ON jazzhands.device_power_connection;
DROP TRIGGER IF EXISTS trigger_device_power_connection_sanity ON jazzhands.device_power_connection;
DROP TRIGGER IF EXISTS trigger_audit_device_power_connection ON jazzhands.device_power_connection;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'device_power_connection');
---- BEGIN audit.device_power_connection TEARDOWN

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'device_power_connection');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."device_power_connection_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'device_power_connection');
---- DONE audit.device_power_connection TEARDOWN


ALTER TABLE device_power_connection RENAME TO device_power_connection_v60;
ALTER TABLE audit.device_power_connection RENAME TO device_power_connection_v60;

CREATE VIEW device_power_connection AS
 WITH slotdev AS (
         SELECT slot.slot_id,
            slot.slot_name,
            device.device_id
           FROM slot
             JOIN device USING (component_id)
             JOIN slot_type st USING (slot_type_id)
          WHERE st.slot_function::text = 'power'::text
        )
 SELECT icc.inter_component_connection_id AS device_power_connection_id,
    icc.inter_component_connection_id,
    s1.device_id AS rpc_device_id,
    s1.slot_name AS rpc_power_interface_port,
    s2.slot_name AS power_interface_port,
    s2.device_id,
    icc.data_ins_user,
    icc.data_ins_date,
    icc.data_upd_user,
    icc.data_upd_date
   FROM inter_component_connection icc
     JOIN slotdev s1 ON icc.slot1_id = s1.slot_id
     JOIN slotdev s2 ON icc.slot2_id = s2.slot_id;

delete from __recreate where type = 'view' and object = 'device_power_connection';
DROP TABLE IF EXISTS device_power_connection_v60;
DROP TABLE IF EXISTS audit.device_power_connection_v60;
-- DONE DEALING WITH TABLE device_power_connection [2507323]
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH TABLE v_l1_all_physical_ports [2468182]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'v_l1_all_physical_ports', 'v_l1_all_physical_ports');
CREATE VIEW v_l1_all_physical_ports AS
 SELECT subquery.layer1_connection_id,
    subquery.physical_port_id,
    subquery.device_id,
    subquery.port_name,
    subquery.port_type,
    subquery.port_purpose,
    subquery.other_physical_port_id,
    subquery.other_device_id,
    subquery.other_port_name,
    subquery.other_port_purpose,
    subquery.baud,
    subquery.data_bits,
    subquery.stop_bits,
    subquery.parity,
    subquery.flow_control
   FROM ( SELECT l1.layer1_connection_id,
            p1.physical_port_id,
            p1.device_id,
            p1.port_name,
            p1.port_type,
            p1.port_purpose,
            p2.physical_port_id AS other_physical_port_id,
            p2.device_id AS other_device_id,
            p2.port_name AS other_port_name,
            p2.port_purpose AS other_port_purpose,
            l1.baud,
            l1.data_bits,
            l1.stop_bits,
            l1.parity,
            l1.flow_control
           FROM physical_port p1
             JOIN layer1_connection l1 ON l1.physical_port1_id = p1.physical_port_id
             JOIN physical_port p2 ON l1.physical_port2_id = p2.physical_port_id
          WHERE p1.port_type::text = p2.port_type::text
        UNION
         SELECT l1.layer1_connection_id,
            p1.physical_port_id,
            p1.device_id,
            p1.port_name,
            p1.port_type,
            p1.port_purpose,
            p2.physical_port_id AS other_physical_port_id,
            p2.device_id AS other_device_id,
            p2.port_name AS other_port_name,
            p2.port_purpose AS other_port_purpose,
            l1.baud,
            l1.data_bits,
            l1.stop_bits,
            l1.parity,
            l1.flow_control
           FROM physical_port p1
             JOIN layer1_connection l1 ON l1.physical_port2_id = p1.physical_port_id
             JOIN physical_port p2 ON l1.physical_port1_id = p2.physical_port_id
          WHERE p1.port_type::text = p2.port_type::text
        UNION
         SELECT NULL::integer,
            p1.physical_port_id,
            p1.device_id,
            p1.port_name,
            p1.port_type,
            p1.port_purpose,
            NULL::integer,
            NULL::integer,
            NULL::character varying,
            NULL::text,
            NULL::integer,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying
           FROM physical_port p1
             LEFT JOIN layer1_connection l1 ON l1.physical_port1_id = p1.physical_port_id OR l1.physical_port2_id = p1.physical_port_id
          WHERE l1.layer1_connection_id IS NULL) subquery
  ORDER BY network_strings.numeric_interface(subquery.port_name);

delete from __recreate where type = 'view' and object = 'v_l1_all_physical_ports';
-- DONE DEALING WITH TABLE v_l1_all_physical_ports [2507318]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE v_physical_connection [2468250]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'v_physical_connection', 'v_physical_connection');
CREATE VIEW v_physical_connection AS
 WITH RECURSIVE var_recurse(level, inter_component_connection_id, physical_connection_id, inter_dev_conn_slot1_id, inter_dev_conn_slot2_id, slot1_id, slot2_id, array_path, cycle) AS (
         SELECT 0,
            l1.inter_component_connection_id,
            pc.physical_connection_id,
            l1.slot1_id AS inter_dev_conn_slot1_id,
            l1.slot2_id AS inter_dev_conn_slot2_id,
            pc.slot1_id,
            pc.slot2_id,
            ARRAY[l1.slot1_id] AS array_path,
            false AS cycle
           FROM inter_component_connection l1
             JOIN physical_connection pc USING (slot1_id)
        UNION ALL
         SELECT x.level + 1,
            x.inter_component_connection_id,
            pc.physical_connection_id,
            x.slot1_id AS inter_dev_conn_slot1_id,
            x.slot2_id AS inter_dev_conn_slot2_id,
            pc.slot1_id,
            pc.slot2_id,
            pc.slot2_id || x.array_path AS array_path,
            pc.slot2_id = ANY (x.array_path) AS cycle
           FROM var_recurse x
             JOIN physical_connection pc ON x.slot2_id = pc.slot1_id
        )
 SELECT var_recurse.level,
    var_recurse.inter_component_connection_id,
    var_recurse.physical_connection_id,
    var_recurse.inter_dev_conn_slot1_id,
    var_recurse.inter_dev_conn_slot2_id,
    var_recurse.slot1_id,
    var_recurse.slot2_id
   FROM var_recurse;

delete from __recreate where type = 'view' and object = 'v_physical_connection';
-- DONE DEALING WITH TABLE v_physical_connection [2507396]
--------------------------------------------------------------------
-- Dropping obsoleted sequences....
DROP SEQUENCE IF EXISTS physical_port_physical_port_id_seq;
DROP SEQUENCE IF EXISTS device_power_connection_device_power_connection_id_seq;
DROP SEQUENCE IF EXISTS layer1_connection_layer1_connection_id_seq;


-- Dropping obsoleted audit sequences....
DROP SEQUENCE IF EXISTS audit.device_type_power_port_templt_seq;
DROP SEQUENCE IF EXISTS audit.val_port_purpose_seq;
DROP SEQUENCE IF EXISTS audit.val_baud_seq;
DROP SEQUENCE IF EXISTS audit.val_port_protocol_speed_seq;
DROP SEQUENCE IF EXISTS audit.val_port_type_seq;
DROP SEQUENCE IF EXISTS audit.physical_port_seq;
DROP SEQUENCE IF EXISTS audit.device_type_phys_port_templt_seq;
DROP SEQUENCE IF EXISTS audit.device_power_connection_seq;
DROP SEQUENCE IF EXISTS audit.val_power_plug_style_seq;
DROP SEQUENCE IF EXISTS audit.val_port_medium_seq;
DROP SEQUENCE IF EXISTS audit.val_parity_seq;
DROP SEQUENCE IF EXISTS audit.val_port_protocol_seq;
DROP SEQUENCE IF EXISTS audit.val_stop_bits_seq;
DROP SEQUENCE IF EXISTS audit.device_power_interface_seq;
DROP SEQUENCE IF EXISTS audit.val_port_plug_style_seq;
DROP SEQUENCE IF EXISTS audit.val_port_speed_seq;
DROP SEQUENCE IF EXISTS audit.val_data_bits_seq;
DROP SEQUENCE IF EXISTS audit.layer1_connection_seq;
DROP SEQUENCE IF EXISTS audit.val_flow_control_seq;


-- Processing tables with no structural changes
-- Some of these may be redundant
-- fk constraints
-- triggers
CREATE TRIGGER trigger_create_component_template_slots AFTER INSERT OR UPDATE OF component_type_id ON component FOR EACH ROW EXECUTE PROCEDURE create_component_slots_by_trigger();
CREATE TRIGGER trigger_zzz_generate_slot_names AFTER INSERT OR UPDATE OF parent_slot_id ON component FOR EACH ROW EXECUTE PROCEDURE set_slot_names_by_trigger();


-- Clean Up
SELECT schema_support.replay_saved_grants();
SELECT schema_support.replay_object_recreates();
GRANT select on all tables in schema jazzhands to ro_role;
GRANT insert,update,delete on all tables in schema jazzhands to iud_role;
GRANT select on all sequences in schema jazzhands to ro_role;
GRANT usage on all sequences in schema jazzhands to iud_role;
GRANT select on all tables in schema audit to ro_role;
GRANT select on all sequences in schema audit to ro_role;
-- SELECT schema_support.end_maintenance();
