

-- Copyright (c) 2015, Todd Kover
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

/*
Invoked:

	--suffix=v62
	--scan-tables
	component_utils.delete_component_hier
	component_utils.set_slot_names
	val_network_range_type
	network_range
	snapshot_manip
	device_utils.purge_physical_path
	netblock_manip.allocate_netblock
	v_lv_hier
	val_token_type
	v_dev_col_user_prop_expanded
	component_utils.insert_pci_component
	validate_component_property
	create_component_slots_by_trigger
*/

\set ON_ERROR_STOP
SELECT schema_support.begin_maintenance();
-- Creating new sequences....


--------------------------------------------------------------------
-- DEALING WITH TABLE x509_certificate [4591155]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'x509_certificate', 'x509_certificate');

-- FOREIGN KEYS FROM
ALTER TABLE x509_key_usage_attribute DROP CONSTRAINT IF EXISTS fk_x509_certificate;

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.x509_certificate DROP CONSTRAINT IF EXISTS fk_x509cert_enc_id_id;
ALTER TABLE jazzhands.x509_certificate DROP CONSTRAINT IF EXISTS fk_x509_cert_cert;
ALTER TABLE jazzhands.x509_certificate DROP CONSTRAINT IF EXISTS fk_x509_cert_revoc_reason;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'x509_certificate');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.x509_certificate DROP CONSTRAINT IF EXISTS ak_x509_cert_ski;
ALTER TABLE jazzhands.x509_certificate DROP CONSTRAINT IF EXISTS pk_x509_certificate;
ALTER TABLE jazzhands.x509_certificate DROP CONSTRAINT IF EXISTS ak_x509_cert_cert_ca_ser;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."xif3x509_certificate";
-- CHECK CONSTRAINTS, etc
ALTER TABLE jazzhands.x509_certificate DROP CONSTRAINT IF EXISTS check_yes_no_1933598984;
ALTER TABLE jazzhands.x509_certificate DROP CONSTRAINT IF EXISTS check_yes_no_31190954;
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_x509_certificate ON jazzhands.x509_certificate;
DROP TRIGGER IF EXISTS trigger_audit_x509_certificate ON jazzhands.x509_certificate;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'x509_certificate');
---- BEGIN audit.x509_certificate TEARDOWN
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('audit', 'x509_certificate', 'x509_certificate');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'x509_certificate');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."x509_certificate_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'x509_certificate');
---- DONE audit.x509_certificate TEARDOWN


ALTER TABLE x509_certificate RENAME TO x509_certificate_v62;
ALTER TABLE audit.x509_certificate RENAME TO x509_certificate_v62;

CREATE TABLE x509_certificate
(
	x509_cert_id	integer NOT NULL,
	friendly_name	varchar(255) NOT NULL,
	is_active	character(1) NOT NULL,
	is_certificate_authority	character(1) NOT NULL,
	signing_cert_id	integer  NULL,
	x509_ca_cert_serial_number	numeric  NULL,
	public_key	text NULL,
	private_key	text  NULL,
	certificate_sign_req	text  NULL,
	subject	varchar(255) NOT NULL,
	subject_key_identifier	varchar(255) NOT NULL,
	valid_from	timestamp(6) without time zone NOT NULL,
	valid_to	timestamp(6) without time zone NOT NULL,
	x509_revocation_date	timestamp with time zone  NULL,
	x509_revocation_reason	varchar(50)  NULL,
	passphrase	varchar(255)  NULL,
	encryption_key_id	integer  NULL,
	ocsp_uri	varchar(255)  NULL,
	crl_uri	varchar(255)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'x509_certificate', false);
ALTER TABLE x509_certificate
	ALTER x509_cert_id
	SET DEFAULT nextval('x509_certificate_x509_cert_id_seq'::regclass);
ALTER TABLE x509_certificate
	ALTER is_active
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE x509_certificate
	ALTER is_certificate_authority
	SET DEFAULT 'N'::bpchar;
INSERT INTO x509_certificate (
	x509_cert_id,
	friendly_name,
	is_active,
	is_certificate_authority,
	signing_cert_id,
	x509_ca_cert_serial_number,
	public_key,
	private_key,
	certificate_sign_req,
	subject,
	subject_key_identifier,
	valid_from,
	valid_to,
	x509_revocation_date,
	x509_revocation_reason,
	passphrase,
	encryption_key_id,
	ocsp_uri,		-- new column (ocsp_uri)
	crl_uri,		-- new column (crl_uri)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	x509_cert_id,
	friendly_name,
	is_active,
	is_certificate_authority,
	signing_cert_id,
	x509_ca_cert_serial_number,
	public_key,
	private_key,
	certificate_sign_req,
	subject,
	subject_key_identifier,
	valid_from,
	valid_to,
	x509_revocation_date,
	x509_revocation_reason,
	passphrase,
	encryption_key_id,
	NULL,		-- new column (ocsp_uri)
	NULL,		-- new column (crl_uri)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM x509_certificate_v62;

INSERT INTO audit.x509_certificate (
	x509_cert_id,
	friendly_name,
	is_active,
	is_certificate_authority,
	signing_cert_id,
	x509_ca_cert_serial_number,
	public_key,
	private_key,
	certificate_sign_req,
	subject,
	subject_key_identifier,
	valid_from,
	valid_to,
	x509_revocation_date,
	x509_revocation_reason,
	passphrase,
	encryption_key_id,
	ocsp_uri,		-- new column (ocsp_uri)
	crl_uri,		-- new column (crl_uri)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	x509_cert_id,
	friendly_name,
	is_active,
	is_certificate_authority,
	signing_cert_id,
	x509_ca_cert_serial_number,
	public_key,
	private_key,
	certificate_sign_req,
	subject,
	subject_key_identifier,
	valid_from,
	valid_to,
	x509_revocation_date,
	x509_revocation_reason,
	passphrase,
	encryption_key_id,
	NULL,		-- new column (ocsp_uri)
	NULL,		-- new column (crl_uri)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.x509_certificate_v62;

ALTER TABLE x509_certificate
	ALTER x509_cert_id
	SET DEFAULT nextval('x509_certificate_x509_cert_id_seq'::regclass);
ALTER TABLE x509_certificate
	ALTER is_active
	SET DEFAULT 'Y'::bpchar;
ALTER TABLE x509_certificate
	ALTER is_certificate_authority
	SET DEFAULT 'N'::bpchar;

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE x509_certificate ADD CONSTRAINT ak_x509_cert_cert_ca_ser UNIQUE (signing_cert_id, x509_ca_cert_serial_number);
ALTER TABLE x509_certificate ADD CONSTRAINT pk_x509_certificate PRIMARY KEY (x509_cert_id);
ALTER TABLE x509_certificate ADD CONSTRAINT ak_x509_cert_ski UNIQUE (subject_key_identifier);

-- Table/Column Comments
COMMENT ON TABLE x509_certificate IS 'X509 specification Certificate.';
COMMENT ON COLUMN x509_certificate.x509_cert_id IS 'Uniquely identifies Certificate';
COMMENT ON COLUMN x509_certificate.friendly_name IS 'human readable name for certificate.  often just the CN.';
COMMENT ON COLUMN x509_certificate.is_active IS 'indicates certificate is in active use.  This is used by tools to decide how to show it; does not indicate revocation';
COMMENT ON COLUMN x509_certificate.signing_cert_id IS 'x509_cert_id for the certificate that has signed this one.';
COMMENT ON COLUMN x509_certificate.x509_ca_cert_serial_number IS 'Serial INTEGER assigned to the certificate within Certificate Authority. It uniquely identifies certificate within the realm of the CA.';
COMMENT ON COLUMN x509_certificate.public_key IS 'Textual representation of Certificate Public Key. Public Key is a component of X509 standard and is used for encryption.';
COMMENT ON COLUMN x509_certificate.private_key IS 'Textual representation of Certificate Private Key. Private Key is a component of X509 standard and is used for encryption.';
COMMENT ON COLUMN x509_certificate.subject IS 'Textual representation of a certificate subject. Certificate subject is a part of X509 certificate specifications.  This is the full subject from the certificate.  Friendly Name provides a human readable one.';
COMMENT ON COLUMN x509_certificate.subject_key_identifier IS 'colon seperate byte hex string with X509v3 SKIextension of this certificate';
COMMENT ON COLUMN x509_certificate.valid_from IS 'Timestamp indicating when the certificate becomes valid and can be used.';
COMMENT ON COLUMN x509_certificate.valid_to IS 'Timestamp indicating when the certificate becomes invalid and can''t be used.';
COMMENT ON COLUMN x509_certificate.x509_revocation_date IS 'if certificate was revoked, when it was revokeed.  reason must also be set.   NULL means not revoked';
COMMENT ON COLUMN x509_certificate.x509_revocation_reason IS 'if certificate was revoked, why iit was revokeed.  date must also be set.   NULL means not revoked';
COMMENT ON COLUMN x509_certificate.passphrase IS 'passphrase to decrypt key.  If encrypted, encryption_key_id indicates how to decrypt.';
COMMENT ON COLUMN x509_certificate.encryption_key_id IS 'if set, encryption key information for decrypting passphrase.';
COMMENT ON COLUMN x509_certificate.ocsp_uri IS 'The URI (without URI: prefix) of the OCSP server for certs signed by this CA.  This is only valid for CAs.  This URI will be included in said certificates.';
COMMENT ON COLUMN x509_certificate.crl_uri IS 'The URI (without URI: prefix) of the CRL for certs signed by this CA.  This is only valid for CAs.  This URI will be included in said certificates.';
-- INDEXES
CREATE INDEX xif3x509_certificate ON x509_certificate USING btree (x509_revocation_reason);

-- CHECK CONSTRAINTS
ALTER TABLE x509_certificate ADD CONSTRAINT check_yes_no_1933598984
	CHECK (is_active = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));
ALTER TABLE x509_certificate ADD CONSTRAINT check_yes_no_31190954
	CHECK (is_certificate_authority = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]));

-- FOREIGN KEYS FROM
-- consider FK x509_certificate and x509_key_usage_attribute
ALTER TABLE x509_key_usage_attribute
	ADD CONSTRAINT fk_x509_certificate
	FOREIGN KEY (x509_cert_id) REFERENCES x509_certificate(x509_cert_id);

-- FOREIGN KEYS TO
-- consider FK x509_certificate and x509_certificate
ALTER TABLE x509_certificate
	ADD CONSTRAINT fk_x509_cert_cert
	FOREIGN KEY (signing_cert_id) REFERENCES x509_certificate(x509_cert_id);
-- consider FK x509_certificate and encryption_key
ALTER TABLE x509_certificate
	ADD CONSTRAINT fk_x509cert_enc_id_id
	FOREIGN KEY (encryption_key_id) REFERENCES encryption_key(encryption_key_id);
-- consider FK x509_certificate and val_x509_revocation_reason
ALTER TABLE x509_certificate
	ADD CONSTRAINT fk_x509_cert_revoc_reason
	FOREIGN KEY (x509_revocation_reason) REFERENCES val_x509_revocation_reason(x509_revocation_reason);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'x509_certificate');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'x509_certificate');
ALTER SEQUENCE x509_certificate_x509_cert_id_seq
	 OWNED BY x509_certificate.x509_cert_id;
DROP TABLE IF EXISTS x509_certificate_v62;
DROP TABLE IF EXISTS audit.x509_certificate_v62;
-- DONE DEALING WITH TABLE x509_certificate [4626552]
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH proc component_utils.delete_component_hier -> delete_component_hier 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 4632091
CREATE OR REPLACE FUNCTION component_utils.delete_component_hier(component_id integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path TO jazzhands
AS $function$
DECLARE
	slot_list		integer[];
	component_list	integer[];
	cid				integer;
BEGIN
	cid := component_id;

	
	SELECT ARRAY(
		SELECT
			slot_id
		FROM
			v_component_hier h JOIN
			slot s ON (h.child_component_id = s.component_id)
		WHERE
			h.component_id = cid)
	INTO slot_list;

	SELECT ARRAY(
		SELECT
			child_component_id
		FROM
			v_component_hier h
		WHERE
			h.component_id = cid)
	INTO component_list;

	DELETE FROM
		inter_component_connection
	WHERE
		slot1_id = ANY (slot_list) OR
		slot2_id = ANY (slot_list);

	UPDATE
		component c
	SET
		parent_slot_id = NULL
	WHERE
		c.component_id = ANY (component_list) AND
		parent_slot_id IS NOT NULL;

	DELETE FROM component_property cp WHERE
		cp.component_id = ANY (component_list) OR
		slot_id = ANY (slot_list);
		
	DELETE FROM
		slot
	WHERE
		slot_id = ANY (slot_list);
		
	DELETE FROM
		component c
	WHERE
		c.component_id = ANY (component_list);

	RETURN true;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc component_utils.delete_component_hier -> delete_component_hier 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc component_utils.set_slot_names -> set_slot_names 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('component_utils', 'set_slot_names', 'set_slot_names');

-- DROP OLD FUNCTION
-- triggers on this function (if applicable)
-- consider old oid 4596669
DROP FUNCTION IF EXISTS component_utils.set_slot_names(slot_id_list integer[]);

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 4632090
CREATE OR REPLACE FUNCTION component_utils.set_slot_names(slot_id_list integer[] DEFAULT NULL::integer[])
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO jazzhands
AS $function$
DECLARE
	slot_rec	RECORD;
	sn			text;
BEGIN
	-- Get a list of all slots that have replacement values

	FOR slot_rec IN
		SELECT 
			s.slot_id,
			st.slot_name_template,
			st.slot_index as slot_index,
			pst.slot_index as parent_slot_index
		FROM
			slot s JOIN
			component_type_slot_tmplt st ON (s.component_type_slot_tmplt_id =
				st.component_type_slot_tmplt_id) JOIN
			component c ON (s.component_id = c.component_id) LEFT JOIN
			slot ps ON (c.parent_slot_id = ps.slot_id) LEFT JOIN
			component_type_slot_tmplt pst ON (ps.component_type_slot_tmplt_id =
				pst.component_type_slot_tmplt_id)
		WHERE
			s.slot_id = ANY(slot_id_list) AND
			st.slot_name_template LIKE '%\%{%'
	LOOP
		sn := slot_rec.slot_name_template;
		IF (slot_rec.slot_index IS NOT NULL) THEN
			sn := regexp_replace(sn,
				'%\{slot_index\}', slot_rec.slot_index::text,
				'g');
		END IF;
		IF (slot_rec.parent_slot_index IS NOT NULL) THEN
			sn := regexp_replace(sn,
				'%\{parent_slot_index\}', slot_rec.parent_slot_index::text,
				'g');
		END IF;
		IF (slot_rec.parent_slot_index IS NOT NULL AND
			slot_rec.slot_index IS NOT NULL) THEN
			sn := regexp_replace(sn,
				'%\{relative_slot_index\}', 
				(slot_rec.parent_slot_index + slot_rec.slot_index)::text,
				'g');
		END IF;
		RAISE DEBUG 'Setting name of slot % to %',
			slot_rec.slot_id,
			sn;
		UPDATE slot SET slot_name = sn WHERE slot_id = slot_rec.slot_id;
	END LOOP;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc component_utils.set_slot_names -> set_slot_names 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH NEW TABLE val_network_range_type
CREATE TABLE val_network_range_type
(
	network_range_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_network_range_type', true);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_network_range_type ADD CONSTRAINT pk_val_network_range_type PRIMARY KEY (network_range_type);

-- Table/Column Comments
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_network_range_type and network_range
-- does not exist yet
--ALTER TABLE network_range
--	ADD CONSTRAINT fk_netrng_netrng_typ
--	FOREIGN KEY (network_range_type) REFERENCES val_network_range_type(network_range_type);

-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_network_range_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_network_range_type');

-- Insert a reasonable default

INSERT INTO val_network_range_type ( network_range_type, description)
values ('unknown', 'exists before types');

-- DONE DEALING WITH TABLE val_network_range_type [4626047]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE network_range [4589564]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'network_range', 'network_range');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
ALTER TABLE jazzhands.network_range DROP CONSTRAINT IF EXISTS fk_net_range_start_netblock;
ALTER TABLE jazzhands.network_range DROP CONSTRAINT IF EXISTS fk_net_range_stop_netblock;
ALTER TABLE jazzhands.network_range DROP CONSTRAINT IF EXISTS fk_net_range_dns_domain_id;

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'network_range');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.network_range DROP CONSTRAINT IF EXISTS pk_network_range;
-- INDEXES
DROP INDEX IF EXISTS "jazzhands"."idx_netrng_dnsdomainid";
DROP INDEX IF EXISTS "jazzhands"."idx_netrng_startnetblk";
DROP INDEX IF EXISTS "jazzhands"."idx_netrng_stopnetblk";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trigger_audit_network_range ON jazzhands.network_range;
DROP TRIGGER IF EXISTS trig_userlog_network_range ON jazzhands.network_range;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'network_range');
---- BEGIN audit.network_range TEARDOWN
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('audit', 'network_range', 'network_range');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'network_range');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."network_range_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'network_range');
---- DONE audit.network_range TEARDOWN


ALTER TABLE network_range RENAME TO network_range_v62;
ALTER TABLE audit.network_range RENAME TO network_range_v62;

CREATE TABLE network_range
(
	network_range_id	integer NOT NULL,
	network_range_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	parent_netblock_id	integer NOT NULL,
	start_netblock_id	integer NOT NULL,
	stop_netblock_id	integer NOT NULL,
	dns_prefix	varchar(255)  NULL,
	dns_domain_id	integer NOT NULL,
	lease_time	integer  NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'network_range', false);
ALTER TABLE network_range
	ALTER network_range_id
	SET DEFAULT nextval('network_range_network_range_id_seq'::regclass);
INSERT INTO network_range (
	network_range_id,
	network_range_type,		-- new column (network_range_type)
	description,
	parent_netblock_id,		-- new column (parent_netblock_id)
	start_netblock_id,
	stop_netblock_id,
	dns_prefix,
	dns_domain_id,
	lease_time,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	o.network_range_id,
	'unknown',	-- new column (network_range_type)
	o.description,
	nb.parent_netblock_id,		-- new column (parent_netblock_id)
	o.start_netblock_id,
	o.stop_netblock_id,
	o.dns_prefix,
	o.dns_domain_id,
	o.lease_time,
	o.data_ins_user,
	o.data_ins_date,
	o.data_upd_user,
	o.data_upd_date
FROM network_range_v62 o
	join netblock nb on nb.netblock_id = o.start_netblock_id;

INSERT INTO audit.network_range (
	network_range_id,
	network_range_type,		-- new column (network_range_type)
	description,
	parent_netblock_id,		-- new column (parent_netblock_id)
	start_netblock_id,
	stop_netblock_id,
	dns_prefix,
	dns_domain_id,
	lease_time,
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	o.network_range_id,
	'unknown',	-- new column (network_range_type)
	o.description,
	nb.parent_netblock_id,		-- new column (parent_netblock_id)
	o.start_netblock_id,
	o.stop_netblock_id,
	o.dns_prefix,
	o.dns_domain_id,
	o.lease_time,
	o.data_ins_user,
	o.data_ins_date,
	o.data_upd_user,
	o.data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.network_range_v62 o
	join netblock nb on nb.netblock_id = o.start_netblock_id;

ALTER TABLE network_range
	ALTER network_range_id
	SET DEFAULT nextval('network_range_network_range_id_seq'::regclass);

-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE network_range ADD CONSTRAINT pk_network_range PRIMARY KEY (network_range_id);

-- Table/Column Comments
COMMENT ON COLUMN network_range.parent_netblock_id IS 'The netblock where the range appears.  This can be of a different type than start/stop netblocks, but start/stop need to be within the parent.';
-- INDEXES
CREATE INDEX xif_netrng_prngnblkid ON network_range USING btree (parent_netblock_id);
CREATE INDEX xif_netrng_dnsdomainid ON network_range USING btree (dns_domain_id);
CREATE INDEX xif_netrng_netrng_typ ON network_range USING btree (network_range_type);
CREATE INDEX xif_netrng_stopnetblk ON network_range USING btree (stop_netblock_id);
CREATE INDEX xif_netrng_startnetblk ON network_range USING btree (start_netblock_id);

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO
-- consider FK network_range and netblock
ALTER TABLE network_range
	ADD CONSTRAINT fk_net_range_start_netblock
	FOREIGN KEY (start_netblock_id) REFERENCES netblock(netblock_id);
-- consider FK network_range and val_network_range_type
ALTER TABLE network_range
	ADD CONSTRAINT fk_netrng_netrng_typ
	FOREIGN KEY (network_range_type) REFERENCES val_network_range_type(network_range_type);
-- consider FK network_range and netblock
ALTER TABLE network_range
	ADD CONSTRAINT fk_net_range_stop_netblock
	FOREIGN KEY (stop_netblock_id) REFERENCES netblock(netblock_id);
-- consider FK network_range and netblock
ALTER TABLE network_range
	ADD CONSTRAINT fk_netrng_prngnblkid
	FOREIGN KEY (parent_netblock_id) REFERENCES netblock(netblock_id);
-- consider FK network_range and dns_domain
ALTER TABLE network_range
	ADD CONSTRAINT fk_net_range_dns_domain_id
	FOREIGN KEY (dns_domain_id) REFERENCES dns_domain(dns_domain_id);

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'network_range');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'network_range');
ALTER SEQUENCE network_range_network_range_id_seq
	 OWNED BY network_range.network_range_id;
DROP TABLE IF EXISTS network_range_v62;
DROP TABLE IF EXISTS audit.network_range_v62;
-- DONE DEALING WITH TABLE network_range [4624951]
--------------------------------------------------------------------

-- triggers

-- Copyright (c) 2015, Kurt Adam
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

\set ON_ERROR_STOP

DO $$
DECLARE
	_tal INTEGER;
BEGIN
	select count(*)
	from pg_catalog.pg_namespace
	into _tal
	where nspname = 'snapshot_manip';
	IF _tal = 0 THEN
		DROP SCHEMA IF EXISTS snapshot_manip CASCADE;
		-- CREATE SCHEMA snapshot_manip AUTHORIZATION jazzhands;
		CREATE SCHEMA snapshot_manip;
		COMMENT ON SCHEMA snapshot_manip IS 'part of jazzhands';
	END IF;
END;
$$;

CREATE OR REPLACE FUNCTION snapshot_manip.add_snapshot(
	os_name       operating_system.operating_system_name%type,
	os_version    operating_system.version%type,
	snapshot_name operating_system_snapshot.operating_system_snapshot_name%type,
	snapshot_type operating_system_snapshot.operating_system_snapshot_type%type
) RETURNS integer AS $$

DECLARE
	major_version text;
	companyid     company.company_id%type;
	osid          operating_system.operating_system_id%type;
	snapid        operating_system_snapshot.operating_system_snapshot_id%type;
	dcid          device_collection.device_collection_id%type;

BEGIN
	SELECT company.company_id INTO companyid FROM company
		INNER JOIN company_type USING (company_id)
		WHERE company_short_name = os_name
		AND company_type = 'os provider';

	IF NOT FOUND THEN
		RAISE 'Operating system vendor not found';
	END IF;

	SELECT operating_system_id INTO osid FROM operating_system
		WHERE operating_system_name = os_name
		AND version = os_version;

	IF NOT FOUND THEN
		major_version := substring(os_version, '^[^.]+');

		INSERT INTO operating_system (
			operating_system_name,
			company_id,
			major_version,
			version,
			operating_system_family
		) VALUES (
			os_name,
			companyid,
			major_version,
			os_version,
			'Linux'
		) RETURNING * INTO osid;

		INSERT INTO property (
			property_type,
			property_name,
			operating_system_id,
			property_value
		) VALUES (
			'OperatingSystem',
			'AllowOSDeploy',
			osid,
			'N'
		);
	END IF;

	INSERT INTO operating_system_snapshot (
		operating_system_snapshot_name,
		operating_system_snapshot_type,
		operating_system_id
	) VALUES (
		snapshot_name,
		snapshot_type,
		osid
	) RETURNING * INTO snapid;

	INSERT INTO device_collection (
		device_collection_name,
		device_collection_type,
		description
	) VALUES (
		CONCAT(os_name, '-', os_version, '-', snapshot_name),
		'os-snapshot',
		NULL
	) RETURNING * INTO dcid;

	INSERT INTO property (
		property_type,
		property_name,
		device_collection_id,
		operating_system_snapshot_id,
		property_value
	) VALUES (
		'OperatingSystem',
		'DeviceCollection',
		dcid,
		snapid,
		NULL
	), (
		'OperatingSystem',
		'AllowSnapDeploy',
		NULL,
		snapid,
		'N'
	);

	RETURN snapid;
END;
$$
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION snapshot_manip.set_default_snapshot(
	os_name       operating_system.operating_system_name%type,
	os_version    operating_system.version%type,
	snapshot_name operating_system_snapshot.operating_system_snapshot_name%type
) RETURNS void AS $$

DECLARE
	osrec           RECORD;
	previous_snapid operating_system_snapshot.operating_system_snapshot_id%type;

BEGIN
	SELECT os.operating_system_id, oss.operating_system_snapshot_id INTO osrec FROM operating_system os
		INNER JOIN operating_system_snapshot oss USING(operating_system_id)
		WHERE operating_system_name = os_name
		AND version = os_version
		AND operating_system_snapshot_name = snapshot_name;

	IF NOT FOUND THEN
		RAISE 'Operating system snapshot not found';
	END IF;

	SELECT oss.operating_system_snapshot_id INTO previous_snapid FROM operating_system_snapshot oss
		INNER JOIN operating_system USING (operating_system_id)
		INNER JOIN property USING (operating_system_snapshot_id)
		WHERE version = os_version
		AND operating_system_name = os_name
		AND property_type = 'OperatingSystem'
		AND property_name = 'DefaultSnapshot';

	IF previous_snapid IS NOT NULL THEN
		IF osrec.operating_system_snapshot_id = previous_snapid THEN
			RETURN;
		END IF;

		DELETE FROM property
			WHERE operating_system_snapshot_id = previous_snapid
			AND property_type = 'OperatingSystem'
			AND property_name = 'DefaultSnapshot';
	END IF;

	INSERT INTO property (
		property_type,
		property_name,
		operating_system_id,
		operating_system_snapshot_id
	) VALUES (
		'OperatingSystem',
		'DefaultSnapshot',
		osrec.operating_system_id,
		osrec.operating_system_snapshot_id
	);
END;
$$
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION snapshot_manip.set_default_os_version(
	os_name       operating_system.operating_system_name%type,
	os_version    operating_system.version%type
) RETURNS void AS $$

DECLARE
	osid          operating_system.operating_system_id%type;
	previous_osid operating_system.operating_system_id%type;

BEGIN
	SELECT os.operating_system_id INTO osid FROM operating_system os
		WHERE operating_system_name = os_name
		AND version = os_version;

	IF NOT FOUND THEN
		RAISE 'Operating system not found';
	END IF;

	SELECT os.operating_system_id INTO previous_osid FROM operating_system os
		INNER JOIN property USING (operating_system_id)
		WHERE operating_system_name = os_name
		AND property_type = 'OperatingSystem'
		AND property_name = 'DefaultVersion';

	IF previous_osid IS NOT NULL THEN
		IF osid = previous_osid THEN
			RETURN;
		END IF;

		DELETE FROM property
			WHERE operating_system_id = previous_osid
			AND property_type = 'OperatingSystem'
			AND property_name = 'DefaultVersion';
	END IF;

	INSERT INTO property (
		property_type,
		property_name,
		operating_system_id,
		property_value
	) VALUES (
		'OperatingSystem',
		'DefaultVersion',
		osid,
		os_name
	);
END;
$$
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION snapshot_manip.delete_snapshot(
	os_name       operating_system.operating_system_name%type,
	os_version    operating_system.version%type,
	snapshot_name operating_system_snapshot.operating_system_snapshot_name%type
) RETURNS void AS $$

DECLARE
	snapid  operating_system_snapshot.operating_system_snapshot_id%type;
	dcid    device_collection.device_collection_id%type;
	dccount integer;

BEGIN
	SELECT operating_system_snapshot_id INTO snapid FROM operating_system
		INNER JOIN operating_system_snapshot USING (operating_system_id)
		WHERE operating_system_name = os_name
		AND operating_system_snapshot_name = snapshot_name
		AND version = os_version;

	IF NOT FOUND THEN
		RAISE 'Operating system snapshot not found';
	END IF;

	SELECT device_collection_id INTO dcid FROM property
		INNER JOIN operating_system_snapshot USING (operating_system_snapshot_id)
		WHERE property_type = 'OperatingSystem'
		AND property_name = 'DeviceCollection'
		AND property.operating_system_snapshot_id = snapid;

	SELECT COUNT(*) INTO dccount FROM device_collection_device where device_collection_id = dcid;

	IF dccount != 0 THEN
		RAISE 'Operating system snapshot still in use by some devices';
	END IF;

	DELETE FROM property WHERE operating_system_snapshot_id = snapid;
	DELETE FROM device_collection WHERE device_collection_name = CONCAT(os_name, '-', os_version, '-', snapshot_name);
	DELETE FROM operating_system_snapshot WHERE operating_system_snapshot_id = snapid;
END;
$$
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION snapshot_manip.set_device_snapshot(
	input_device  device.device_id%type,
	os_name       operating_system.operating_system_name%type,
	os_version    operating_system.version%type,
	snapshot_name operating_system_snapshot.operating_system_snapshot_name%type
) RETURNS void AS $$

DECLARE
	snapid        operating_system_snapshot.operating_system_snapshot_id%type;
	previous_dcid device_collection.device_collection_id%type;
	new_dcid      device_collection.device_collection_id%type;

BEGIN
	IF snapshot_name = 'default' THEN
		SELECT oss.operating_system_snapshot_id INTO snapid FROM operating_system_snapshot oss
			INNER JOIN operating_system os USING (operating_system_id)
			INNER JOIN property p USING (operating_system_snapshot_id)
			WHERE os.version = os_version
			AND os.operating_system_name = os_name
			AND p.property_type = 'OperatingSystem'
			AND p.property_name = 'DefaultSnapshot';
	ELSE
		SELECT oss.operating_system_snapshot_id INTO snapid FROM operating_system_snapshot oss
			INNER JOIN operating_system os USING(operating_system_id)
			WHERE os.operating_system_name = os_name
			AND os.version = os_version
			AND oss.operating_system_snapshot_name = snapshot_name;
	END IF;

	IF NOT FOUND THEN
		RAISE 'Operating system snapshot not found';
	END IF;

	SELECT property.device_collection_id INTO new_dcid FROM property
		WHERE operating_system_snapshot_id = snapid
		AND property_type = 'OperatingSystem'
		AND property_name = 'DeviceCollection';

	SELECT device_collection_id INTO previous_dcid FROM device_collection_device
		INNER JOIN device_collection USING(device_collection_id)
		WHERE device_id = input_device
		AND device_collection_type = 'os-snapshot';

	IF FOUND THEN
		IF new_dcid = previous_dcid THEN
			RETURN;
		END IF;

		DELETE FROM device_collection_device
			WHERE device_id = input_device
			AND device_collection_id = previous_dcid;
	END IF;

	INSERT INTO device_collection_device (
		device_id,
		device_collection_id
	) VALUES (
		input_device,
		new_dcid
	);
END;
$$
SET search_path=jazzhands
LANGUAGE plpgsql SECURITY DEFINER;

--------------------------------------------------------------------
-- DEALING WITH proc device_utils.purge_physical_path -> purge_physical_path 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('device_utils', 'purge_physical_path', 'purge_physical_path');

-- DROP OLD FUNCTION
-- triggers on this function (if applicable)
-- consider old oid 4596637
DROP FUNCTION IF EXISTS device_utils.purge_physical_path(_in_l1c integer);

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 4632058
CREATE OR REPLACE FUNCTION device_utils.purge_physical_path(_in_l1c integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	_r	RECORD;
BEGIN
	FOR _r IN 
	      SELECT  pc.physical_connection_id,
			pc.cable_type,
			p1.physical_port_id as pc_p1_physical_port_id,
			p1.port_name as pc_p1_physical_port_name,
			d1.device_id as pc_p1_device_id,
			d1.device_name as pc_p1_device_name,
			p2.physical_port_id as pc_p2_physical_port_id,
			p2.port_name as pc_p2_physical_port_name,
			d2.device_id as pc_p2_device_id,
			d2.device_name as pc_p2_device_name
		  FROM  v_physical_connection vpc
			INNER JOIN physical_connection pc
				USING (physical_connection_id)
			INNER JOIN physical_port p1
				ON p1.physical_port_id = pc.physical_port1_id
			INNER JOIN device d1
				ON d1.device_id = p1.device_id
			INNER JOIN physical_port p2
				ON p2.physical_port_id = pc.physical_port2_id
			INNER JOIN device d2
				ON d2.device_id = p2.device_id
		WHERE   vpc.inter_component_connection_id = _in_l1c
		ORDER BY level
	LOOP
		DELETE from physical_connecion where physical_connection_id =
			_r.physical_connection_id;
	END LOOP;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc device_utils.purge_physical_path -> purge_physical_path 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH proc netblock_manip.allocate_netblock -> allocate_netblock 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('netblock_manip', 'allocate_netblock', 'allocate_netblock');

-- DROP OLD FUNCTION
-- triggers on this function (if applicable)
-- consider old oid 4596660
DROP FUNCTION IF EXISTS netblock_manip.allocate_netblock(parent_netblock_id integer, netmask_bits integer, address_type text, can_subnet boolean, allocation_method text, rnd_masklen_threshold integer, rnd_max_count integer, ip_address inet, description character varying, netblock_status character varying);
-- consider old oid 4596661
DROP FUNCTION IF EXISTS netblock_manip.allocate_netblock(parent_netblock_list integer[], netmask_bits integer, address_type text, can_subnet boolean, allocation_method text, rnd_masklen_threshold integer, rnd_max_count integer, ip_address inet, description character varying, netblock_status character varying);

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 4632081
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
-- consider NEW oid 4632082
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
	ip_addr			ALIAS FOR ip_address;
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

	IF ip_address IS NOT NULL THEN
		SELECT 
			array_agg(netblock_id)
		INTO
			parent_netblock_list
		FROM
			netblock n
		WHERE
			ip_addr <<= n.ip_address AND
			netblock_id = ANY(parent_netblock_list);

		IF parent_netblock_list IS NULL THEN
			RETURN NULL;
		END IF;
	END IF;

	-- Lock the parent row, which should keep parallel processes from
	-- trying to obtain the same address

	FOR parent_rec IN SELECT * FROM jazzhands.netblock WHERE netblock_id = 
			ANY(allocate_netblock.parent_netblock_list) ORDER BY netblock_id
			FOR UPDATE LOOP

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

		PERFORM dns_utils.add_domains_from_netblock(
			netblock_id := netblock_rec.netblock_id);

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

		PERFORM dns_utils.add_domains_from_netblock(
			netblock_id := netblock_rec.netblock_id);

		RETURN netblock_rec;
	END IF;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc netblock_manip.allocate_netblock -> allocate_netblock 
--------------------------------------------------------------------


--------------------------------------------------------------------
-- DEALING WITH NEW TABLE v_lv_hier
CREATE OR REPLACE VIEW v_lv_hier AS
 WITH RECURSIVE lv_hier(physicalish_volume_id, pv_logical_volume_id, volume_group_id, logical_volume_id, pv_path, vg_path, lv_path) AS (
         SELECT pv.physicalish_volume_id,
            pv.logical_volume_id,
            vg.volume_group_id,
            lv.logical_volume_id,
            ARRAY[pv.physicalish_volume_id] AS "array",
            ARRAY[vg.volume_group_id] AS "array",
            ARRAY[lv.logical_volume_id] AS "array"
           FROM physicalish_volume pv
             LEFT JOIN volume_group_physicalish_vol USING (physicalish_volume_id)
             FULL JOIN volume_group vg USING (volume_group_id)
             LEFT JOIN logical_volume lv USING (volume_group_id)
          WHERE lv.logical_volume_id IS NULL OR NOT (lv.logical_volume_id IN ( SELECT physicalish_volume.logical_volume_id
                   FROM physicalish_volume
                  WHERE physicalish_volume.logical_volume_id IS NOT NULL))
        UNION
         SELECT pv.physicalish_volume_id,
            pv.logical_volume_id,
            vg.volume_group_id,
            lv.logical_volume_id,
            array_prepend(pv.physicalish_volume_id, lh.pv_path) AS array_prepend,
            array_prepend(vg.volume_group_id, lh.vg_path) AS array_prepend,
            array_prepend(lv.logical_volume_id, lh.lv_path) AS array_prepend
           FROM physicalish_volume pv
             LEFT JOIN volume_group_physicalish_vol USING (physicalish_volume_id)
             FULL JOIN volume_group vg USING (volume_group_id)
             LEFT JOIN logical_volume lv USING (volume_group_id)
             JOIN lv_hier lh(physicalish_volume_id_1, pv_logical_volume_id, volume_group_id_1, logical_volume_id, pv_path, vg_path, lv_path) ON lv.logical_volume_id = lh.pv_logical_volume_id
        )
 SELECT DISTINCT lv_hier.physicalish_volume_id,
    lv_hier.volume_group_id,
    lv_hier.logical_volume_id,
    unnest(lv_hier.pv_path) AS child_pv_id,
    unnest(lv_hier.vg_path) AS child_vg_id,
    unnest(lv_hier.lv_path) AS child_lv_id,
    lv_hier.pv_path,
    lv_hier.vg_path,
    lv_hier.lv_path
   FROM lv_hier;

delete from __recreate where type = 'view' and object = 'v_lv_hier';
-- DONE DEALING WITH TABLE v_lv_hier [4763835]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE val_token_type [5075193]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'val_token_type', 'val_token_type');

-- FOREIGN KEYS FROM
ALTER TABLE token DROP CONSTRAINT IF EXISTS fk_token_ref_v_token_type;

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('jazzhands', 'val_token_type');

-- PRIMARY and ALTERNATE KEYS
ALTER TABLE jazzhands.val_token_type DROP CONSTRAINT IF EXISTS pk_val_token_type;
-- INDEXES
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
DROP TRIGGER IF EXISTS trig_userlog_val_token_type ON jazzhands.val_token_type;
DROP TRIGGER IF EXISTS trigger_audit_val_token_type ON jazzhands.val_token_type;
SELECT schema_support.save_dependant_objects_for_replay('jazzhands', 'val_token_type');
---- BEGIN audit.val_token_type TEARDOWN
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('audit', 'val_token_type', 'val_token_type');

-- FOREIGN KEYS FROM

-- FOREIGN KEYS TO

-- EXTRA-SCHEMA constraints
SELECT schema_support.save_constraint_for_replay('audit', 'val_token_type');

-- PRIMARY and ALTERNATE KEYS
-- INDEXES
DROP INDEX IF EXISTS "audit"."val_token_type_aud#timestamp_idx";
-- CHECK CONSTRAINTS, etc
-- TRIGGERS, etc
SELECT schema_support.save_dependant_objects_for_replay('audit', 'val_token_type');
---- DONE audit.val_token_type TEARDOWN


ALTER TABLE val_token_type RENAME TO val_token_type_v63;
ALTER TABLE audit.val_token_type RENAME TO val_token_type_v63;

CREATE TABLE val_token_type
(
	token_type	varchar(50) NOT NULL,
	description	varchar(4000)  NULL,
	token_digit_count	integer NOT NULL,
	data_ins_user	varchar(255)  NULL,
	data_ins_date	timestamp with time zone  NULL,
	data_upd_user	varchar(255)  NULL,
	data_upd_date	timestamp with time zone  NULL
);
SELECT schema_support.build_audit_table('audit', 'jazzhands', 'val_token_type', false);
INSERT INTO val_token_type (
	token_type,
	description,
	token_digit_count,		-- new column (token_digit_count)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
) SELECT
	token_type,
	description,
	NULL,		-- new column (token_digit_count)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date
FROM val_token_type_v63;

INSERT INTO audit.val_token_type (
	token_type,
	description,
	token_digit_count,		-- new column (token_digit_count)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
) SELECT
	token_type,
	description,
	NULL,		-- new column (token_digit_count)
	data_ins_user,
	data_ins_date,
	data_upd_user,
	data_upd_date,
	"aud#action",
	"aud#timestamp",
	"aud#user",
	"aud#seq"
FROM audit.val_token_type_v63;


-- PRIMARY AND ALTERNATE KEYS
ALTER TABLE val_token_type ADD CONSTRAINT pk_val_token_type PRIMARY KEY (token_type);

-- Table/Column Comments
COMMENT ON COLUMN val_token_type.token_digit_count IS 'number of digits that the token displays';
-- INDEXES

-- CHECK CONSTRAINTS

-- FOREIGN KEYS FROM
-- consider FK val_token_type and token
ALTER TABLE token
	ADD CONSTRAINT fk_token_ref_v_token_type
	FOREIGN KEY (token_type) REFERENCES val_token_type(token_type);

-- FOREIGN KEYS TO

-- TRIGGERS
SELECT schema_support.rebuild_stamp_trigger('jazzhands', 'val_token_type');
SELECT schema_support.rebuild_audit_trigger('audit', 'jazzhands', 'val_token_type');
GRANT SELECT ON val_token_type TO ro_role;
GRANT ALL ON val_token_type TO jazzhands;
GRANT INSERT,UPDATE,DELETE ON val_token_type TO iud_role;
DROP TABLE IF EXISTS val_token_type_v63;
DROP TABLE IF EXISTS audit.val_token_type_v63;
-- DONE DEALING WITH TABLE val_token_type [5035411]
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH TABLE v_dev_col_user_prop_expanded [5080698]
-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'v_dev_col_user_prop_expanded', 'v_dev_col_user_prop_expanded');
DROP VIEW IF EXISTS v_dev_col_user_prop_expanded;
CREATE VIEW v_dev_col_user_prop_expanded AS
 SELECT dchd.device_collection_id,
    a.account_id,
    a.login,
    a.account_status,
    ar.account_realm_id,
    ar.account_realm_name,
        CASE
            WHEN vps.is_disabled = 'N'::bpchar THEN 'Y'::text
            ELSE 'N'::text
        END AS is_enabled,
    upo.property_type,
    upo.property_name,
    COALESCE(upo.property_value_password_type, upo.property_value) AS property_value,
        CASE
            WHEN upn.is_multivalue = 'N'::bpchar THEN 0
            ELSE 1
        END AS is_multivalue,
        CASE
            WHEN pdt.property_data_type::text = 'boolean'::text THEN 1
            ELSE 0
        END AS is_boolean
   FROM v_acct_coll_acct_expanded_detail uued
     JOIN account_collection u USING (account_collection_id)
     JOIN v_property upo ON upo.account_collection_id = u.account_collection_id AND (upo.property_type::text = ANY (ARRAY['CCAForceCreation'::character varying, 'CCARight'::character varying, 'ConsoleACL'::character varying, 'RADIUS'::character varying, 'TokenMgmt'::character varying, 'UnixPasswdFileValue'::character varying, 'UserMgmt'::character varying, 'cca'::character varying, 'feed-attributes'::character varying, 'wwwgroup'::character varying]::text[]))
     JOIN val_property upn ON upo.property_name::text = upn.property_name::text AND upo.property_type::text = upn.property_type::text
     JOIN val_property_data_type pdt ON upn.property_data_type::text = pdt.property_data_type::text
     JOIN account a ON uued.account_id = a.account_id
     JOIN account_realm ar ON a.account_realm_id = ar.account_realm_id
     JOIN val_person_status vps ON vps.person_status::text = a.account_status::text
     LEFT JOIN v_device_coll_hier_detail dchd ON dchd.parent_device_collection_id = upo.device_collection_id
  ORDER BY dchd.device_collection_level,
        CASE
            WHEN u.account_collection_type::text = 'per-account'::text THEN 0
            WHEN u.account_collection_type::text = 'property'::text THEN 1
            WHEN u.account_collection_type::text = 'systems'::text THEN 2
            ELSE 3
        END,
        CASE
            WHEN uued.assign_method = 'Account_CollectionAssignedToPerson'::text THEN 0
            WHEN uued.assign_method = 'Account_CollectionAssignedToDept'::text THEN 1
            WHEN uued.assign_method = 'ParentAccount_CollectionOfAccount_CollectionAssignedToPerson'::text THEN 2
            WHEN uued.assign_method = 'ParentAccount_CollectionOfAccount_CollectionAssignedToDept'::text THEN 2
            WHEN uued.assign_method = 'Account_CollectionAssignedToParentDept'::text THEN 3
            WHEN uued.assign_method = 'ParentAccount_CollectionOfAccount_CollectionAssignedToParentDep'::text THEN 3
            ELSE 6
        END, uued.dept_level, uued.acct_coll_level, dchd.device_collection_id, u.account_collection_id;

delete from __recreate where type = 'view' and object = 'v_dev_col_user_prop_expanded';
GRANT INSERT,UPDATE,DELETE ON v_dev_col_user_prop_expanded TO iud_role;
GRANT ALL ON v_dev_col_user_prop_expanded TO jazzhands;
GRANT SELECT ON v_dev_col_user_prop_expanded TO ro_role;
-- DONE DEALING WITH TABLE v_dev_col_user_prop_expanded [5040944]
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH proc component_utils.insert_pci_component -> insert_pci_component 


-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 5114655
CREATE OR REPLACE FUNCTION component_utils.insert_pci_component(pci_vendor_id integer, pci_device_id integer, pci_sub_vendor_id integer DEFAULT NULL::integer, pci_subsystem_id integer DEFAULT NULL::integer, pci_vendor_name text DEFAULT NULL::text, pci_device_name text DEFAULT NULL::text, pci_sub_vendor_name text DEFAULT NULL::text, pci_sub_device_name text DEFAULT NULL::text, component_function_list text[] DEFAULT NULL::text[], slot_type text DEFAULT 'unknown'::text)
 RETURNS component
 LANGUAGE plpgsql
 SET search_path TO jazzhands
AS $function$
DECLARE
	ctid		integer;
	comp_id		integer;
	sub_comp_id	integer;
	stid		integer;
	vendor_name	text;
	sub_vendor_name	text;
	model_name	text;
	c			RECORD;
BEGIN
	IF (pci_sub_vendor_id IS NULL AND pci_subsystem_id IS NOT NULL) OR
			(pci_sub_vendor_id IS NOT NULL AND pci_subsystem_id IS NULL) THEN
		RAISE EXCEPTION
			'pci_sub_vendor_id and pci_subsystem_id must be set together';
	END IF;

	--
	-- See if we have this component type in the database already
	--
	SELECT
		vid.component_type_id INTO ctid
	FROM
		component_property vid JOIN
		component_property did ON (
			vid.component_property_name = 'PCIVendorID' AND
			vid.component_property_type = 'PCI' AND
			did.component_property_name = 'PCIDeviceID' AND
			did.component_property_type = 'PCI' AND
			vid.component_type_id = did.component_type_id ) LEFT JOIN
		component_property svid ON (
			svid.component_property_name = 'PCISubsystemVendorID' AND
			svid.component_property_type = 'PCI' AND
			svid.component_type_id = did.component_type_id ) LEFT JOIN
		component_property sid ON (
			sid.component_property_name = 'PCISubsystemID' AND
			sid.component_property_type = 'PCI' AND
			sid.component_type_id = did.component_type_id )
	WHERE
		vid.property_value = pci_vendor_id::varchar AND
		did.property_value = pci_device_id::varchar AND
		svid.property_value IS NOT DISTINCT FROM pci_sub_vendor_id::varchar AND
		sid.property_value IS NOT DISTINCT FROM pci_subsystem_id::varchar;

	IF FOUND THEN
		INSERT INTO jazzhands.component (
			component_type_id
		) VALUES (
			ctid
		) RETURNING * INTO c;
		RETURN c;
	END IF;

	--
	-- The device type doesn't exist, so attempt to insert it
	--

	
	IF pci_device_name IS NULL OR component_function_list IS NULL THEN
		RAISE EXCEPTION 'component_id not found and pci_device_name or component_function_list was not passed' USING ERRCODE = 'JH501';
	END IF;

	--
	-- Ensure that there's a company linkage for the PCI (subsystem)vendor
	--
	SELECT
		company_id, company_name INTO comp_id, vendor_name
	FROM
		property p JOIN
		company c USING (company_id)
	WHERE
		property_type = 'DeviceProvisioning' AND
		property_name = 'PCIVendorID' AND
		company_id = pci_vendor_id;
	
	IF NOT FOUND THEN
		IF pci_vendor_name IS NULL THEN
			RAISE EXCEPTION 'PCI vendor id mapping not found and pci_vendor_name was not passed' USING ERRCODE = 'JH501';
		END IF;
		SELECT company_id INTO comp_id FROM company
		WHERE company_name = pci_vendor_name;
	
		IF NOT FOUND THEN
			INSERT INTO company (company_name, description)
			VALUES (pci_vendor_name, 'PCI vendor auto-insert')
			RETURNING company_id INTO comp_id;
		END IF;

		INSERT INTO property (
			property_name,
			property_type,
			property_value,
			company_id
		) VALUES (
			'PCIVendorID',
			'DeviceProvisioning',
			pci_vendor_id,
			comp_id
		);
		vendor_name := pci_vendor_name;
	END IF;

	SELECT
		company_id, company_name INTO sub_comp_id, sub_vendor_name
	FROM
		property JOIN
		company c USING (company_id)
	WHERE
		property_type = 'DeviceProvisioning' AND
		property_name = 'PCIVendorID' AND
		company_id = pci_sub_vendor_id;
	
	IF NOT FOUND THEN
		IF pci_sub_vendor_name IS NULL THEN
			RAISE EXCEPTION 'PCI subsystem vendor id mapping not found and pci_sub_vendor_name was not passed' USING ERRCODE = 'JH501';
		END IF;
		SELECT company_id INTO sub_comp_id FROM company
		WHERE company_name = pci_sub_vendor_name;
	
		IF NOT FOUND THEN
			INSERT INTO company (company_name, description)
			VALUES (pci_sub_vendor_name, 'PCI vendor auto-insert')
			RETURNING company_id INTO sub_comp_id;
		END IF;

		INSERT INTO property (
			property_name,
			property_type,
			property_value,
			company_id
		) VALUES (
			'PCIVendorID',
			'DeviceProvisioning',
			pci_sub_vendor_id,
			sub_comp_id
		);
		sub_vendor_name := pci_sub_vendor_name;
	END IF;

	--
	-- Fetch the slot type
	--

	SELECT 
		slot_type_id INTO stid
	FROM
		slot_type st
	WHERE
		st.slot_type = insert_pci_component.slot_type AND
		slot_function = 'PCI';

	IF NOT FOUND THEN
		RAISE EXCEPTION 'slot type not found adding component_type'
			USING ERRCODE = 'JH501';
	END IF;

	--
	-- Figure out the best name/description to insert this component with
	--
	IF pci_sub_device_name IS NOT NULL AND pci_sub_device_name != 'Device' THEN
		model_name = concat_ws(' ', 
			sub_vendor_name, pci_sub_device_name,
			'(' || vendor_name, pci_device_name || ')');
	ELSIF pci_sub_device_name = 'Device' THEN
		model_name = concat_ws(' ', 
			vendor_name, '(' || sub_vendor_name || ')', pci_device_name);
	ELSE
		model_name = concat_ws(' ', vendor_name, pci_device_name);
	END IF;
	INSERT INTO component_type (
		company_id,
		model,
		slot_type_id,
		description
	) VALUES (
		CASE WHEN 
			sub_comp_id IS NULL OR
			pci_sub_device_name IS NULL OR
			pci_sub_device_name = 'Device'
		THEN
			comp_id
		ELSE
			sub_comp_id
		END,
		CASE WHEN
			pci_sub_device_name IS NULL OR
			pci_sub_device_name = 'Device'
		THEN
			pci_device_name
		ELSE
			pci_sub_device_name
		END,
		stid,
		model_name
	) RETURNING component_type_id INTO ctid;
	--
	-- Insert properties for the PCI vendor/device IDs
	--
	INSERT INTO component_property (
		component_property_name,
		component_property_type,
		component_type_id,
		property_value
	) VALUES 
		('PCIVendorID', 'PCI', ctid, pci_vendor_id),
		('PCIDeviceID', 'PCI', ctid, pci_device_id);
	
	IF (pci_subsystem_id IS NOT NULL) THEN
		INSERT INTO component_property (
			component_property_name,
			component_property_type,
			component_type_id,
			property_value
		) VALUES 
			('PCISubsystemVendorID', 'PCI', ctid, pci_sub_vendor_id),
			('PCISubsystemID', 'PCI', ctid, pci_subsystem_id);
	END IF;

	--
	-- Insert the component functions
	--

	INSERT INTO component_type_component_func (
		component_type_id,
		component_function
	) SELECT DISTINCT
		ctid,
		cf
	FROM
		unnest(array_append(component_function_list, 'PCI')) x(cf);

	--
	-- We have a component_type_id now, so insert the component and return
	--
	INSERT INTO jazzhands.component (
		component_type_id
	) VALUES (
		ctid
	) RETURNING * INTO c;
	RETURN c;
END;
$function$
;
-- triggers on this function (if applicable)

-- DONE WITH proc component_utils.insert_pci_component -> insert_pci_component 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- DEALING WITH proc validate_component_property -> validate_component_property 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'validate_component_property', 'validate_component_property');

-- DROP OLD FUNCTION
-- triggers on this function (if applicable)
DROP TRIGGER IF EXISTS trigger_validate_component_property ON jazzhands.component_property;
-- consider old oid 5167954
DROP FUNCTION IF EXISTS validate_component_property();

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 5159525
CREATE OR REPLACE FUNCTION jazzhands.validate_component_property()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
DECLARE
	tally				INTEGER;
	v_comp_prop			RECORD;
	v_comp_prop_type	RECORD;
	v_num				INTEGER;
	v_listvalue			TEXT;
	component_attrs		RECORD;
BEGIN

	-- Pull in the data from the property and property_type so we can
	-- figure out what is and is not valid

	BEGIN
		SELECT * INTO STRICT v_comp_prop FROM val_component_property WHERE
			component_property_name = NEW.component_property_name AND
			component_property_type = NEW.component_property_type;

		SELECT * INTO STRICT v_comp_prop_type FROM val_component_property_type 
			WHERE component_property_type = NEW.component_property_type;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE EXCEPTION 
				'Component property name or type does not exist'
				USING ERRCODE = 'foreign_key_violation';
			RETURN NULL;
	END;

	-- Check to see if the property itself is multivalue.  That is, if only
	-- one value can be set for this property for a specific property LHS

	IF (v_comp_prop.is_multivalue != 'Y') THEN
		PERFORM 1 FROM component_property WHERE
			component_property_id != NEW.component_property_id AND
			component_property_name = NEW.component_property_name AND
			component_property_type = NEW.component_property_type AND
			component_type_id IS NOT DISTINCT FROM NEW.component_type_id AND
			component_function IS NOT DISTINCT FROM NEW.component_function AND
			component_id iS NOT DISTINCT FROM NEW.component_id AND
			slot_type_id IS NOT DISTINCT FROM NEW.slot_type_id AND
			slot_function IS NOT DISTINCT FROM NEW.slot_function AND
			slot_id IS NOT DISTINCT FROM NEW.slot_id;
			
		IF FOUND THEN
			RAISE EXCEPTION 
				'Property with name % and type % already exists for given LHS and property is not multivalue',
				NEW.component_property_name,
				NEW.component_property_type
				USING ERRCODE = 'unique_violation';
			RETURN NULL;
		END IF;
	END IF;

	-- Check to see if the property type is multivalue.  That is, if only
	-- one property and value can be set for any properties with this type
	-- for a specific property LHS

	IF (v_comp_prop_type.is_multivalue != 'Y') THEN
		PERFORM 1 FROM component_property WHERE
			component_property_id != NEW.component_property_id AND
			component_property_type = NEW.component_property_type AND
			component_type_id IS NOT DISTINCT FROM NEW.component_type_id AND
			component_function IS NOT DISTINCT FROM NEW.component_function AND
			component_id iS NOT DISTINCT FROM NEW.component_id AND
			slot_type_id IS NOT DISTINCT FROM NEW.slot_type_id AND
			slot_function IS NOT DISTINCT FROM NEW.slot_function AND
			slot_id IS NOT DISTINCT FROM NEW.slot_id;

		IF FOUND THEN
			RAISE EXCEPTION 
				'Property % of type % already exists for given LHS and property type is not multivalue',
				NEW.component_property_name, NEW.component_property_type
				USING ERRCODE = 'unique_violation';
			RETURN NULL;
		END IF;
	END IF;

	-- now validate the property_value columns.
	tally := 0;

	--
	-- first determine if the property_value is set properly.
	--

	-- at this point, tally will be set to 1 if one of the other property
	-- values is set to something valid.  Now, check the various options for
	-- PROPERTY_VALUE itself.  If a new type is added to the val table, this
	-- trigger needs to be updated or it will be considered invalid.  If a
	-- new PROPERTY_VALUE_* column is added, then it will pass through without
	-- trigger modification.  This should be considered bad.

	IF NEW.property_value IS NOT NULL THEN
		tally := tally + 1;
		IF v_comp_prop.property_data_type = 'boolean' THEN
			IF NEW.Property_Value != 'Y' AND NEW.Property_Value != 'N' THEN
				RAISE 'Boolean property_value must be Y or N' USING
					ERRCODE = 'invalid_parameter_value';
			END IF;
		ELSIF v_comp_prop.property_data_type = 'number' THEN
			BEGIN
				v_num := to_number(NEW.property_value, '9');
			EXCEPTION
				WHEN OTHERS THEN
					RAISE 'property_value must be numeric' USING
						ERRCODE = 'invalid_parameter_value';
			END;
		ELSIF v_comp_prop.property_data_type = 'list' THEN
			BEGIN
				SELECT valid_property_value INTO STRICT v_listvalue FROM 
					val_component_property_value WHERE
						component_property_name = NEW.component_property_name AND
						component_property_type = NEW.component_property_type AND
						valid_property_value = NEW.property_value;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE 'property_value must be a valid value' USING
						ERRCODE = 'invalid_parameter_value';
			END;
		ELSIF v_comp_prop.property_data_type != 'string' THEN
			RAISE 'property_data_type is not a known type' USING
				ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF v_comp_prop.property_data_type != 'none' AND tally = 0 THEN
		RAISE 'One of the property_value fields must be set.' USING
			ERRCODE = 'invalid_parameter_value';
	END IF;

	IF tally > 1 THEN
		RAISE 'Only one of the property_value fields may be set.' USING
			ERRCODE = 'invalid_parameter_value';
	END IF;

	--
	-- At this point, the value itself is valid for this property, now
	-- determine whether the property is allowed on the target
	--
	-- There needs to be a stanza here for every "lhs".  If a new column is
	-- added to the component_property table, a new stanza needs to be added
	-- here, otherwise it will not be validated.  This should be considered bad.

	IF v_comp_prop.permit_component_type_id = 'REQUIRED' THEN
		IF NEW.component_type_id IS NULL THEN
			RAISE 'component_type_id is required.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	ELSIF v_comp_prop.permit_component_type_id = 'PROHIBITED' THEN
		IF NEW.component_type_id IS NOT NULL THEN
			RAISE 'component_type_id is prohibited.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF v_comp_prop.permit_component_function = 'REQUIRED' THEN
		IF NEW.component_function IS NULL THEN
			RAISE 'component_function is required.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	ELSIF v_comp_prop.permit_component_function = 'PROHIBITED' THEN
		IF NEW.component_function IS NOT NULL THEN
			RAISE 'component_function is prohibited.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF v_comp_prop.permit_component_id = 'REQUIRED' THEN
		IF NEW.component_id IS NULL THEN
			RAISE 'component_id is required.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	ELSIF v_comp_prop.permit_component_id = 'PROHIBITED' THEN
		IF NEW.component_id IS NOT NULL THEN
			RAISE 'component_id is prohibited.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF v_comp_prop.permit_intcomp_conn_id = 'REQUIRED' THEN
		IF NEW.inter_component_connection_id IS NULL THEN
			RAISE 'inter_component_connection_id is required.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	ELSIF v_comp_prop.permit_intcomp_conn_id = 'PROHIBITED' THEN
		IF NEW.inter_component_connection_id IS NOT NULL THEN
			RAISE 'inter_component_connection_id is prohibited.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF v_comp_prop.permit_slot_type_id = 'REQUIRED' THEN
		IF NEW.slot_type_id IS NULL THEN
			RAISE 'slot_type_id is required.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	ELSIF v_comp_prop.permit_slot_type_id = 'PROHIBITED' THEN
		IF NEW.slot_type_id IS NOT NULL THEN
			RAISE 'slot_type_id is prohibited.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF v_comp_prop.permit_slot_function = 'REQUIRED' THEN
		IF NEW.slot_function IS NULL THEN
			RAISE 'slot_function is required.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	ELSIF v_comp_prop.permit_slot_function = 'PROHIBITED' THEN
		IF NEW.slot_function IS NOT NULL THEN
			RAISE 'slot_function is prohibited.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF v_comp_prop.permit_slot_id = 'REQUIRED' THEN
		IF NEW.slot_id IS NULL THEN
			RAISE 'slot_id is required.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	ELSIF v_comp_prop.permit_slot_id = 'PROHIBITED' THEN
		IF NEW.slot_id IS NOT NULL THEN
			RAISE 'slot_id is prohibited.'
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	--
	-- LHS population is verified; now validate any particular restrictions
	-- on individual values
	--

	--
	-- For slot_id, validate that the component_type, component_function,
	-- slot_type, and slot_function are all valid
	--
	IF NEW.slot_id IS NOT NULL AND COALESCE(
			v_comp_prop.required_component_type_id::text,
			v_comp_prop.required_component_function,
			v_comp_prop.required_slot_type_id::text,
			v_comp_prop.required_slot_function) IS NOT NULL THEN

		WITH x AS (
			SELECT
				component_type_id,
				array_agg(component_function) as component_function
			FROM
				component_type_component_func
			GROUP BY
				component_type_id
		) SELECT
			component_type_id,
			component_function,
			st.slot_type_id,
			slot_function
		INTO
			component_attrs
		FROM
			slot cs JOIN
			slot_type st USING (slot_type_id) JOIN
			component c USING (component_id) JOIN
			component_type ct USING (component_type_id) LEFT JOIN
			x USING (component_type_id)
		WHERE
			slot_id = NEW.slot_id;

		IF v_comp_prop.required_component_type_id IS NOT NULL AND
				v_comp_prop.required_component_type_id !=
				component_attrs.component_type_id THEN
			RAISE 'component_type for slot_id must be % (is: %)',
					v_comp_prop.required_component_type_id,
					component_attrs.component_type_id
				USING ERRCODE = 'invalid_parameter_value';
		END IF;

		IF v_comp_prop.required_component_function IS NOT NULL AND
				NOT (v_comp_prop.required_component_function =
					ANY(component_attrs.component_function)) THEN
			RAISE 'component_function for slot_id must be % (is: %)',
					v_comp_prop.required_component_function,
					component_attrs.component_function
				USING ERRCODE = 'invalid_parameter_value';
		END IF;

		IF v_comp_prop.required_slot_type_id IS NOT NULL AND
				v_comp_prop.required_slot_type_id !=
				component_attrs.slot_type_id THEN
			RAISE 'slot_type_id for slot_id must be % (is: %)',
					v_comp_prop.required_slot_type_id,
					component_attrs.slot_type_id
				USING ERRCODE = 'invalid_parameter_value';
		END IF;

		IF v_comp_prop.required_slot_function IS NOT NULL AND
				v_comp_prop.required_slot_function !=
				component_attrs.slot_function THEN
			RAISE 'slot_function for slot_id must be % (is: %)',
					v_comp_prop.required_slot_function,
					component_attrs.slot_function
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF NEW.slot_type_id IS NOT NULL AND 
			v_comp_prop.required_slot_function IS NOT NULL THEN

		SELECT
			slot_function
		INTO
			component_attrs
		FROM
			slot_type st
		WHERE
			slot_type_id = NEW.slot_type_id;

		IF v_comp_prop.required_slot_function !=
				component_attrs.slot_function THEN
			RAISE 'slot_function for slot_type_id must be % (is: %)',
					v_comp_prop.required_slot_function,
					component_attrs.slot_function
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF NEW.component_id IS NOT NULL AND COALESCE(
			v_comp_prop.required_component_type_id::text,
			v_comp_prop.required_component_function) IS NOT NULL THEN

		SELECT
			component_type_id,
			array_agg(component_function) as component_function
		INTO
			component_attrs
		FROM
			component c JOIN
			component_type_component_func ctcf USING (component_type_id)
		WHERE
			component_id = NEW.component_id
		GROUP BY
			component_type_id;

		IF v_comp_prop.required_component_type_id IS NOT NULL AND
				v_comp_prop.required_component_type_id !=
				component_attrs.component_type_id THEN
			RAISE 'component_type for component_id must be % (is: %)',
					v_comp_prop.required_component_type_id,
					component_attrs.component_type_id
				USING ERRCODE = 'invalid_parameter_value';
		END IF;

		IF v_comp_prop.required_component_function IS NOT NULL AND
				NOT (v_comp_prop.required_component_function =
					ANY(component_attrs.component_function)) THEN
			RAISE 'component_function for component_id must be % (is: %)',
					v_comp_prop.required_component_function,
					component_attrs.component_function
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;

	IF NEW.component_type_id IS NOT NULL AND 
			v_comp_prop.required_component_function IS NOT NULL THEN

		SELECT
			component_type_id,
			array_agg(component_function) as component_function
		INTO
			component_attrs
		FROM
			component_type_component_func ctcf
		WHERE
			component_type_id = NEW.component_type_id
		GROUP BY
			component_type_id;

		IF v_comp_prop.required_component_function IS NOT NULL AND
				NOT (v_comp_prop.required_component_function =
					ANY(component_attrs.component_function)) THEN
			RAISE 'component_function for component_type_id must be % (is: %)',
					v_comp_prop.required_component_function,
					component_attrs.component_function
				USING ERRCODE = 'invalid_parameter_value';
		END IF;
	END IF;
		
	RETURN NEW;
END;
$function$
;
-- triggers on this function (if applicable)
CREATE CONSTRAINT TRIGGER trigger_validate_component_property AFTER INSERT OR UPDATE ON component_property DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE validate_component_property();

-- DONE WITH proc validate_component_property -> validate_component_property 
--------------------------------------------------------------------
--------------------------------------------------------------------
-- DEALING WITH proc create_component_slots_by_trigger -> create_component_slots_by_trigger 

-- Save grants for later reapplication
SELECT schema_support.save_grants_for_replay('jazzhands', 'create_component_slots_by_trigger', 'create_component_slots_by_trigger');

-- DROP OLD FUNCTION
-- triggers on this function (if applicable)
DROP TRIGGER IF EXISTS trigger_create_component_template_slots ON jazzhands.component;
-- consider old oid 5177412
DROP FUNCTION IF EXISTS create_component_slots_by_trigger();

-- RECREATE FUNCTION

-- DROP OLD FUNCTION (in case type changed)
-- consider NEW oid 5159529
CREATE OR REPLACE FUNCTION jazzhands.create_component_slots_by_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO jazzhands
AS $function$
BEGIN
	-- For inserts, just do a simple slot creation, for updates, things
	-- get more complicated, so try to migrate slots

	IF (TG_OP == 'INSERT' OR OLD.component_type_id != NEW.component_type_id)
	THEN
		PERFORM component_utils.create_component_template_slots(
			component_id := NEW.component_id);
	END IF;
	IF (TG_OP == 'UPDATE' AND OLD.component_type_id != NEW.component_type_id)
	THEN
		PERFORM component_utils.migrate_component_template_slots(
			component_id := NEW.component_id,
			old_component_type_id := OLD.component_type_id,
			new_component_type_id := NEW.component_type_id
			);
		RETURN NEW;
	END IF;
END;
$function$
;
-- triggers on this function (if applicable)
CREATE TRIGGER trigger_create_component_template_slots AFTER INSERT OR UPDATE OF component_type_id ON component FOR EACH ROW EXECUTE PROCEDURE create_component_slots_by_trigger();

-- DONE WITH proc create_component_slots_by_trigger -> create_component_slots_by_trigger 
--------------------------------------------------------------------

-- Dropping obsoleted sequences....


-- Dropping obsoleted audit sequences....


-- Processing tables with no structural changes
-- Some of these may be redundant
-- fk constraints
ALTER TABLE logical_volume DROP CONSTRAINT IF EXISTS fk_logvol_device_id;
ALTER TABLE logical_volume
	ADD CONSTRAINT fk_logvol_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id) DEFERRABLE;

ALTER TABLE logical_volume DROP CONSTRAINT IF EXISTS fk_logvol_fstype;
ALTER TABLE logical_volume
	ADD CONSTRAINT fk_logvol_fstype
	FOREIGN KEY (filesystem_type) REFERENCES val_filesystem_type(filesystem_type) DEFERRABLE;

ALTER TABLE logical_volume DROP CONSTRAINT IF EXISTS fk_logvol_vgid;
ALTER TABLE logical_volume
	ADD CONSTRAINT fk_logvol_vgid
	FOREIGN KEY (volume_group_id, device_id) REFERENCES volume_group(volume_group_id, device_id) DEFERRABLE;

ALTER TABLE logical_volume_property DROP CONSTRAINT IF EXISTS fk_lvol_prop_lvid_fstyp;
ALTER TABLE logical_volume_property
	ADD CONSTRAINT fk_lvol_prop_lvid_fstyp
	FOREIGN KEY (logical_volume_id, filesystem_type) REFERENCES logical_volume(logical_volume_id, filesystem_type) DEFERRABLE;

ALTER TABLE logical_volume_property DROP CONSTRAINT IF EXISTS fk_lvol_prop_lvpn_fsty;
ALTER TABLE logical_volume_property
	ADD CONSTRAINT fk_lvol_prop_lvpn_fsty
	FOREIGN KEY (logical_volume_property_name, filesystem_type) REFERENCES val_logical_volume_property(logical_volume_property_name, filesystem_type) DEFERRABLE;

ALTER TABLE logical_volume_purpose DROP CONSTRAINT IF EXISTS fk_lvpurp_lvid;
ALTER TABLE logical_volume_purpose
	ADD CONSTRAINT fk_lvpurp_lvid
	FOREIGN KEY (logical_volume_id) REFERENCES logical_volume(logical_volume_id) DEFERRABLE;

ALTER TABLE logical_volume_purpose DROP CONSTRAINT IF EXISTS fk_lvpurp_val_lgpuprp;
ALTER TABLE logical_volume_purpose
	ADD CONSTRAINT fk_lvpurp_val_lgpuprp
	FOREIGN KEY (logical_volume_purpose) REFERENCES val_logical_volume_purpose(logical_volume_purpose) DEFERRABLE;

ALTER TABLE physicalish_volume DROP CONSTRAINT IF EXISTS fk_physicalish_vol_pvtype;
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physicalish_vol_pvtype
	FOREIGN KEY (physicalish_volume_type) REFERENCES val_physicalish_volume_type(physicalish_volume_type);

ALTER TABLE physicalish_volume DROP CONSTRAINT IF EXISTS fk_physvol_compid;
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physvol_compid
	FOREIGN KEY (component_id) REFERENCES component(component_id) DEFERRABLE;

ALTER TABLE physicalish_volume DROP CONSTRAINT IF EXISTS fk_physvol_device_id;
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physvol_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id) DEFERRABLE;

ALTER TABLE physicalish_volume DROP CONSTRAINT IF EXISTS fk_physvol_lvid;
ALTER TABLE physicalish_volume
	ADD CONSTRAINT fk_physvol_lvid
	FOREIGN KEY (logical_volume_id) REFERENCES logical_volume(logical_volume_id) DEFERRABLE;

ALTER TABLE volume_group DROP CONSTRAINT IF EXISTS fk_volgrp_devid;
ALTER TABLE volume_group
	ADD CONSTRAINT fk_volgrp_devid
	FOREIGN KEY (device_id) REFERENCES device(device_id) DEFERRABLE;

ALTER TABLE volume_group DROP CONSTRAINT IF EXISTS fk_volgrp_rd_type;
ALTER TABLE volume_group
	ADD CONSTRAINT fk_volgrp_rd_type
	FOREIGN KEY (raid_type) REFERENCES val_raid_type(raid_type) DEFERRABLE;

ALTER TABLE volume_group DROP CONSTRAINT IF EXISTS fk_volgrp_volgrp_type;
ALTER TABLE volume_group
	ADD CONSTRAINT fk_volgrp_volgrp_type
	FOREIGN KEY (volume_group_type) REFERENCES val_volume_group_type(volume_group_type) DEFERRABLE;

ALTER TABLE volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_physvol_vg_phsvol_dvid;
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_physvol_vg_phsvol_dvid
	FOREIGN KEY (physicalish_volume_id, device_id) REFERENCES physicalish_volume(physicalish_volume_id, device_id) DEFERRABLE;

ALTER TABLE volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vg_physvol_vgrel;
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vg_physvol_vgrel
	FOREIGN KEY (volume_group_relation) REFERENCES val_volume_group_relation(volume_group_relation) DEFERRABLE;

ALTER TABLE volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vgp_phy_phyid;
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vgp_phy_phyid
	FOREIGN KEY (physicalish_volume_id) REFERENCES physicalish_volume(physicalish_volume_id) DEFERRABLE;

ALTER TABLE volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vgp_phy_vgrpid;
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vgp_phy_vgrpid
	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id) DEFERRABLE;

ALTER TABLE volume_group_physicalish_vol DROP CONSTRAINT IF EXISTS fk_vgp_phy_vgrpid_devid;
ALTER TABLE volume_group_physicalish_vol
	ADD CONSTRAINT fk_vgp_phy_vgrpid_devid
	FOREIGN KEY (volume_group_id, device_id) REFERENCES volume_group(volume_group_id, device_id) DEFERRABLE;

ALTER TABLE volume_group_purpose DROP CONSTRAINT IF EXISTS fk_val_volgrp_purp_vgid;
ALTER TABLE volume_group_purpose
	ADD CONSTRAINT fk_val_volgrp_purp_vgid
	FOREIGN KEY (volume_group_id) REFERENCES volume_group(volume_group_id) DEFERRABLE;

ALTER TABLE volume_group_purpose DROP CONSTRAINT IF EXISTS fk_val_volgrp_purp_vgpurp;
ALTER TABLE volume_group_purpose
	ADD CONSTRAINT fk_val_volgrp_purp_vgpurp
	FOREIGN KEY (volume_group_purpose) REFERENCES val_volume_group_purpose(volume_group_purpose) DEFERRABLE;

ALTER TABLE PHYSICALISH_VOLUME DROP CONSTRAINT IF EXISTS FK_PHYSICALISH_VOL_PVTYPE;
ALTER TABLE PHYSICALISH_VOLUME 
	ADD CONSTRAINT FK_PHYSICALISH_VOL_PVTYPE 
	FOREIGN KEY (PHYSICALISH_VOLUME_TYPE) REFERENCES VAL_PHYSICALISH_VOLUME_TYPE (PHYSICALISH_VOLUME_TYPE) DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE physicalish_volume DROP CONSTRAINT IF EXISTS ak_physvolname_type_devid;
ALTER TABLE ONLY physicalish_volume
	ADD CONSTRAINT ak_physvolname_type_devid 
	UNIQUE (device_id, physicalish_volume_name, physicalish_volume_type);

GRANT USAGE ON SCHEMA snapshot_manip TO iud_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA snapshot_manip TO iud_role;


-- slot changes
ALTER TABLE slot ALTER slot_side drop default;
ALTER TABLE slot ALTER slot_side drop not null;

drop trigger IF EXISTS trig_userlog_token_sequence on token_sequence;
drop trigger IF EXISTS trigger_audit_token_sequence on token_sequence;

-- Clean Up
SELECT schema_support.replay_object_recreates();
SELECT schema_support.replay_saved_grants();
GRANT select on all tables in schema jazzhands to ro_role;
GRANT insert,update,delete on all tables in schema jazzhands to iud_role;
GRANT select on all sequences in schema jazzhands to ro_role;
GRANT usage on all sequences in schema jazzhands to iud_role;
GRANT select on all tables in schema audit to ro_role;
GRANT select on all sequences in schema audit to ro_role;
-- SELECT schema_support.end_maintenance();
