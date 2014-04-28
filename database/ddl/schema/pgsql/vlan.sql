DROP TABLE IF EXISTS encapsulation_netblock CASCADE;
DROP TABLE IF EXISTS layer2_encapsulation CASCADE;
DROP TABLE IF EXISTS encapsulation CASCADE;
DROP TABLE IF EXISTS val_encapsulation_type CASCADE;

CREATE TABLE val_encapsulation_type (
	encapsulation_type		VARCHAR(50) NOT NULL,
	description				text NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE val_encapsulation_type ADD CONSTRAINT pk_encapsulation_type PRIMARY KEY (encapsulation_type);

CREATE TABLE val_encapsulation_mode (
	encapsulation_mode		VARCHAR(50) NOT NULL,
	encapsulation_type		VARCHAR(50) NOT NULL,
	description				text NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE val_encapsulation_mode ADD CONSTRAINT pk_encapsulation_mode PRIMARY KEY (encapsulation_type, encapsulation_mode);

CREATE TABLE encapsulation_domain (
	encapsulation_type		VARCHAR(50) NOT NULL,
	encapsulation_domain	VARCHAR(255) NOT NULL,
	description				text NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE encapsulation_domain ADD CONSTRAINT pk_encapsulation_domain PRIMARY KEY (encapsulation_type, encapsulation_domain);

CREATE TABLE layer2_network (
	layer2_network_id		SERIAL,
	encapsulation_name		VARCHAR(32) NOT NULL,
	encapsulation_type		VARCHAR(50) NOT NULL,
	encapsulation_domain	VARCHAR(255) NOT NULL,
	encapsulation_tag		integer NOT NULL,
	description				text NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE layer2_network ADD CONSTRAINT pk_layer2_network PRIMARY KEY (layer2_network_id);
ALTER TABLE layer2_network ADD CONSTRAINT ak_l2n_ecaps_tag UNIQUE (encapsulation_type, encapsulation_domain, encapsulation_tag);
ALTER TABLE layer2_network ADD CONSTRAINT ak_l2n_ecaps_name UNIQUE (encapsulation_type, encapsulation_domain, encapsulation_name);


CREATE TABLE device_encapsulation_domain (
	device_id				integer NOT NULL,
	encapsulation_type		VARCHAR(50) NOT NULL,
	encapsulation_domain	VARCHAR(255) NOT NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE device_encapsulation_domain ADD CONSTRAINT pk_device_encaps_domain PRIMARY KEY (device_id, encapsulation_type);

CREATE TABLE device_layer2_network (
	device_id				integer NOT NULL,
	layer2_network_id		integer NOT NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE device_layer2_network ADD CONSTRAINT pk_device_layer2_network PRIMARY KEY (device_id, layer2_network_id);

CREATE TABLE val_logical_port_type (
	logical_port_type		VARCHAR(50) NOT NULL,
	description				text NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE val_logical_port_type ADD CONSTRAINT pk_val_logical_port_type PRIMARY KEY (logical_port_type);

CREATE TABLE logical_port (
	logical_port_id			SERIAL,
	parent_logical_port_id	integer NULL,
	logical_port_type		VARCHAR(50) NOT NULL,
	logical_port_name		VARCHAR(255) NOT NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE logical_port ADD CONSTRAINT pk_logical_port PRIMARY KEY (logical_port_id);

CREATE TABLE layer2_connection (
	layer2_connection_id	SERIAL,
	logical_port1_id		integer NOT NULL,
	logical_port2_id		integer NOT NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE layer2_connection ADD CONSTRAINT pk_layer2_connection PRIMARY KEY (layer2_connection_id);


CREATE TABLE layer2_connection_layer2_network (
	layer2_connection_id	integer NOT NULL,
	layer2_network_id		integer NOT NULL,
	encapsulation_mode		integer NOT NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE layer2_connection_layer2_network ADD CONSTRAINT pk_layer2_connection_layer2_network PRIMARY KEY (layer2_connection_id, layer2_network_id);

CREATE TABLE layer3_network (
	layer3_network_id		SERIAL,
	netblock_id				integer NOT NULL,
	layer2_network_id		integer NULL,
	default_gateway_netblock_id		integer NULL,
	rendezvous_point_netblock_id	integer NULL,
	description				text NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE layer3_network ADD CONSTRAINT pk_layer3_network PRIMARY KEY (layer3_network_id);
ALTER TABLE layer3_network ADD CONSTRAINT ak_layer3_network_netblock_id UNIQUE(netblock_id);


CREATE TABLE mlag_peers (
	mlag_peers_id			SERIAL,
	device1_id				integer NOT NULL,
	device2_id				integer NOT NULL,
	DATA_INS_USER			VARCHAR(255) NULL,
	DATA_INS_DATE			TIMESTAMP WITH TIME ZONE NULL,
	DATA_UPD_USER			VARCHAR(255) NULL,
	DATA_UPD_DATE			TIMESTAMP WITH TIME ZONE NULL 
);

ALTER TABLE layer3_network ADD CONSTRAINT pk_mlag_peers PRIMARY KEY (mlag_peers_id);
ALTER TABLE layer3_network ADD CONSTRAINT ak_mlag_peers_dev1_id UNIQUE(device1_id);
ALTER TABLE layer3_network ADD CONSTRAINT ak_mlag_peers_dev2_id UNIQUE(device2_id);

---
--- Table changes
---

ALTER TABLE physical_port ADD COLUMN logical_port_id integer NULL;

---
--- Foreign keys
---

ALTER TABLE encapsulation_domain ADD CONSTRAINT fk_encaps_domain_encaps_type 
	FOREIGN KEY (encapsulation_type) REFERENCES 
		val_encapsulation_type (encapsulation_type);

ALTER TABLE layer2_network ADD CONSTRAINT fk_l2_network_encaps_tag
	FOREIGN KEY (encapsulation_type, encapsulation_domain) REFERENCES
		encapsulation_domain(encapsulation_type, encapsulation_domain);

ALTER TABLE device_encapsulation_domain ADD CONSTRAINT fk_device_encaps_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

ALTER TABLE device_encapsulation_domain ADD CONSTRAINT fk_device_encaps_domain_encaps_domain
	FOREIGN KEY (encapsulation_type, encapsulation_domain) REFERENCES
		encapsulation_domain(encapsulation_type, encapsulation_domain);

ALTER TABLE device_layer2_network ADD CONSTRAINT fk_device_l2_network_device_id
	FOREIGN KEY (device_id) REFERENCES device(device_id);

ALTER TABLE device_layer2_network ADD CONSTRAINT fk_device_l2_network_l2_network
	FOREIGN KEY (layer2_network_id) REFERENCES layer2_network(layer2_network_id);

ALTER TABLE val_encapsulation_mode ADD CONSTRAINT fk_val_encaps_mode_encaps_type
	FOREIGN KEY (encapsulation_type) REFERENCES val_encapsulation_type(encapsulation_type);

ALTER TABLE logical_port ADD CONSTRAINT fk_logical_port_parent_log_port
	FOREIGN KEY (parent_logical_port_id) REFERENCES logical_port(logical_port_id);

ALTER TABLE layer2_connection ADD CONSTRAINT fk_l2_connection_p1_id
	FOREIGN KEY (logical_port1_id) REFERENCES logical_port(logical_port_id);

ALTER TABLE layer2_connection ADD CONSTRAINT fk_l2_connection_p2_id
	FOREIGN KEY (logical_port2_id) REFERENCES logical_port(logical_port_id);

ALTER TABLE layer2_connection_layer2_network ADD CONSTRAINT fk_l2_conn_l2_netwk_l2_netwk_id
	FOREIGN KEY (layer2_network_id) REFERENCES layer2_network(layer2_network_id);

ALTER TABLE layer3_network ADD CONSTRAINT fk_l3_network_netblock_id
	FOREIGN KEY (netblock_id) REFERENCES netblock(netblock_id);

ALTER TABLE layer3_network ADD CONSTRAINT fk_l3_network_l2_network_id
	FOREIGN KEY (layer2_network_id) REFERENCES layer2_network(layer2_network_id);

ALTER TABLE layer3_network ADD CONSTRAINT fk_l3_network_dg_netblock_id
	FOREIGN KEY (default_gateway_netblock_id) REFERENCES netblock(netblock_id);

ALTER TABLE layer3_network ADD CONSTRAINT fk_l3_network_rp_netblock_id
	FOREIGN KEY (rendezvous_point_netblock_id) REFERENCES netblock(netblock_id);

ALTER TABLE mlag_peers ADD CONSTRAINT fk_mlag_peers_dev1_id
	FOREIGN KEY (device1_id) REFERENCES device (device_id);

ALTER TABLE mlag_peers ADD CONSTRAINT fk_mlag_peers_dev2_id
	FOREIGN KEY (device2_id) REFERENCES device (device_id);

ALTER TABLE physical_port ADD CONSTRAINT fk_phys_port_logl_port_id
	FOREIGN KEY (logical_port_id) REFERENCES logical_port (logical_port_id);

