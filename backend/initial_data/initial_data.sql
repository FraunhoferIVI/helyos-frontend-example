--
-- PostgreSQL database dump
--

-- Dumped from database version 13.14 (Debian 13.14-1.pgdg120+2)
-- Dumped by pg_dump version 15.2

-- Started on 2024-03-06 14:22:43

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 3435 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 837 (class 1247 OID 16836)
-- Name: jwt_token; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.jwt_token AS (
	role text,
	person_id integer,
	exp integer
);


ALTER TYPE public.jwt_token OWNER TO postgres;

--
-- TOC entry 312 (class 1255 OID 16832)
-- Name: admin_change_password(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.admin_change_password(username text, password text) RETURNS integer
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $_$

DECLARE
  account public.user_account;
  v_RowCountInt int;
BEGIN

  IF username = 'admin' then
    RAISE EXCEPTION SQLSTATE '90002' USING MESSAGE = 'Please use the procedure change_password(admin, new_password, current_password)' ;
  END IF;

  update  public.user_account as A set password_hash = crypt(password, gen_salt('bf')) where A.username=$1;
  GET DIAGNOSTICS v_RowCountInt = ROW_COUNT;
  IF v_RowCountInt = 0 then 
    RAISE EXCEPTION SQLSTATE '90002' USING MESSAGE = 'username not found' ;
  END IF;

  return 0;

END
$_$;


ALTER FUNCTION public.admin_change_password(username text, password text) OWNER TO postgres;

--
-- TOC entry 3437 (class 0 OID 0)
-- Dependencies: 312
-- Name: FUNCTION admin_change_password(username text, password text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.admin_change_password(username text, password text) IS 'Admin changes regular user passwords.';


--
-- TOC entry 314 (class 1255 OID 16837)
-- Name: admin_get_user_authtoken(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.admin_get_user_authtoken(username text) RETURNS public.jwt_token
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $_$
DECLARE
  account public.user_account;
BEGIN
  select a.* into account
  from public.user_account as a
  where (a.email = $1 or a.username = $1);

  IF account.user_role = 0 then
        return ('role_admin', account.user_id, extract(epoch from now() + interval '365 days'))::public.jwt_token;
  END IF; 
  IF account.user_role = 1 then
        return ('role_application', account.user_id, extract(epoch from now() + interval '365 days'))::public.jwt_token;
  END IF;
  IF account.user_role = 2 then
        return ('role_visualization', account.user_id, extract(epoch from now() + interval '365 days'))::public.jwt_token;
  END IF;
END
$_$;


ALTER FUNCTION public.admin_get_user_authtoken(username text) OWNER TO postgres;

--
-- TOC entry 3439 (class 0 OID 0)
-- Dependencies: 314
-- Name: FUNCTION admin_get_user_authtoken(username text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.admin_get_user_authtoken(username text) IS 'Creates a JWT token that will securely identify a person and give them certain permissions. This token expires in 7 days.';


--
-- TOC entry 310 (class 1255 OID 16838)
-- Name: authenticate(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.authenticate(username text, password text) RETURNS public.jwt_token
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $_$
DECLARE
  account public.user_account;
BEGIN
  select a.* into account
  from public.user_account as a
  where (a.email = $1 or a.username = $1);

  IF account.password_hash = crypt(password, account.password_hash) then
    IF account.user_role = 0 then
          return ('role_admin', account.user_id, extract(epoch from now() + interval '7 days'))::public.jwt_token;
    ELSE
          return ('role_application', account.user_id, extract(epoch from now() + interval '7 days'))::public.jwt_token;
    END IF;
  ELSE
    return "'null'";
  END IF;
END
$_$;


ALTER FUNCTION public.authenticate(username text, password text) OWNER TO postgres;

--
-- TOC entry 3441 (class 0 OID 0)
-- Dependencies: 310
-- Name: FUNCTION authenticate(username text, password text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.authenticate(username text, password text) IS 'Creates a JWT token that will securely identify a person and give them certain permissions. This token expires in 7 days.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 16604)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    modified_at timestamp without time zone,
    name character varying,
    metadata json,
    role integer
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 311 (class 1255 OID 16833)
-- Name: change_password(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.change_password(username text, new_password text, current_password text) RETURNS public.users
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $_$
DECLARE
  updated_user public.users;
  account public.user_account;
BEGIN
  select a.* into account from public.user_account as a  where a.username = $1;
  IF account.password_hash = crypt(current_password, account.password_hash) then
      update public.user_account SET password_hash = crypt(new_password, gen_salt('bf')) where user_id = account.user_id;
      return updated_user;
  ELSE
     RAISE EXCEPTION SQLSTATE '90003' USING MESSAGE = 'username or password not correct';
  END IF;
END
$_$;


ALTER FUNCTION public.change_password(username text, new_password text, current_password text) OWNER TO postgres;

--
-- TOC entry 3444 (class 0 OID 0)
-- Dependencies: 311
-- Name: FUNCTION change_password(username text, new_password text, current_password text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.change_password(username text, new_password text, current_password text) IS 'Update password.';


--
-- TOC entry 303 (class 1255 OID 16805)
-- Name: create_row_tool_sensors_history(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_row_tool_sensors_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
     updated_agent_id  bigint;

    BEGIN
      updated_agent_id := NEW.id;

        INSERT INTO public.agent_poses (agent_id, yard_id, x, y, z, work_process_id, orientation, orientations, sensors, status, assignment)
          SELECT T.id, T.yard_id, T.x, T.y, T.z, T.work_process_id, T.orientation, T.orientations, T.sensors, T.status, T.assignment
          FROM   public.agents AS T
          WHERE id = updated_agent_id;
        RETURN NULL;
    END; 
$$;


ALTER FUNCTION public.create_row_tool_sensors_history() OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16724)
-- Name: assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assignments (
    id bigint NOT NULL,
    yard_id bigint,
    work_process_id bigint,
    tool_id bigint,
    agent_id bigint,
    service_request_id bigint,
    data jsonb,
    context jsonb,
    result jsonb,
    status character varying,
    start_time_stamp character varying,
    depend_on_assignments bigint[],
    next_assignments bigint[],
    error character varying,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    modified_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.assignments OWNER TO postgres;

--
-- TOC entry 3447 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN assignments.yard_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assignments.yard_id IS '@ yard ID where assignment should be performed';


--
-- TOC entry 3448 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN assignments.work_process_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assignments.work_process_id IS '@ corresponding work process';


--
-- TOC entry 3449 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN assignments.agent_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assignments.agent_id IS '@ agent for which assignment is assigned';


--
-- TOC entry 3450 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN assignments.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assignments.data IS '@ json-object for assignment';


--
-- TOC entry 3451 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN assignments.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.assignments.status IS '@ status of assignment: "to_dispatch", "executing", "succeeded", "failed", "canceled"';


--
-- TOC entry 319 (class 1255 OID 16840)
-- Name: getworkprocessactiondata(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getworkprocessactiondata(w_process_id bigint) RETURNS SETOF public.assignments
    LANGUAGE sql STABLE
    AS $$

        SELECT * FROM public.assignments  WHERE work_process_id=w_process_id;
    
    $$;


ALTER FUNCTION public.getworkprocessactiondata(w_process_id bigint) OWNER TO postgres;

--
-- TOC entry 309 (class 1255 OID 16839)
-- Name: logout(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.logout(username text) RETURNS public.jwt_token
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $_$
DECLARE
  account public.user_account;
BEGIN
  select a.* into account
  from public.user_account as a
  where a.email = $1 or a.username = $1;
  return ('role_application', account.user_id, extract(epoch from now() + interval '1 minute'))::public.jwt_token;
END
$_$;


ALTER FUNCTION public.logout(username text) OWNER TO postgres;

--
-- TOC entry 3454 (class 0 OID 0)
-- Dependencies: 309
-- Name: FUNCTION logout(username text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.logout(username text) IS 'Creates a JWT token that will substitute the previous token.';


--
-- TOC entry 206 (class 1259 OID 16455)
-- Name: map_objects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.map_objects (
    id bigint NOT NULL,
    yard_id bigint,
    data jsonb,
    type character varying,
    data_format character varying DEFAULT 'trucktrix-map'::character varying,
    metadata jsonb,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    modified_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6) without time zone,
    name character varying
);


ALTER TABLE public.map_objects OWNER TO postgres;

--
-- TOC entry 3456 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN map_objects.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.map_objects.data IS '@description Add any information relevant this map_object; e.g. geometry';


--
-- TOC entry 3457 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN map_objects.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.map_objects.type IS '@description map_object type: "crop", "road", "drivable", "guide-line", "obstacle" ';


--
-- TOC entry 3458 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN map_objects.data_format; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.map_objects.data_format IS '@description Define the format of the data field. The default is trucktrix-map';


--
-- TOC entry 3459 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN map_objects.metadata; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.map_objects.metadata IS '@description Provide additional information carried by the field data';


--
-- TOC entry 3460 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN map_objects.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.map_objects.name IS '@description map_object name: "strawbery field - 02", "Load Gate A", etc. ';


--
-- TOC entry 305 (class 1255 OID 16820)
-- Name: mark_deleted_all_map_objects_of_yard(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.mark_deleted_all_map_objects_of_yard(yard_id_input bigint) RETURNS SETOF public.map_objects
    LANGUAGE sql
    AS $$

 UPDATE public.map_objects  SET  deleted_at =  now()  WHERE yard_id = yard_id_input AND deleted_at IS NULL RETURNING *;
 
$$;


ALTER FUNCTION public.mark_deleted_all_map_objects_of_yard(yard_id_input bigint) OWNER TO postgres;

--
-- TOC entry 292 (class 1255 OID 16813)
-- Name: notify_assignments_insertion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_assignments_insertion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
   BEGIN
       PERFORM pg_notify('assignments_insertion',            
            (SELECT row_to_json(r.*)::varchar FROM (
             SELECT  id, yard_id,  work_process_id, tool_id, agent_id, status, start_time_stamp from public.assignments  where id = NEW.id)
            r)
        );
       RETURN NULL;
   END; 
$$;


ALTER FUNCTION public.notify_assignments_insertion() OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 16814)
-- Name: notify_assignments_updates(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_assignments_updates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        PERFORM pg_notify('assignments_status_update', 
            (SELECT row_to_json(r.*)::varchar FROM (
            SELECT id, yard_id,  work_process_id, tool_id, agent_id, status, start_time_stamp from public.assignments  where id = NEW.id)
            r)
        );
        RETURN NULL;
    END; 
$$;


ALTER FUNCTION public.notify_assignments_updates() OWNER TO postgres;

--
-- TOC entry 300 (class 1255 OID 16806)
-- Name: notify_change_tool(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_change_tool() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN

    IF (OLD.status IS DISTINCT FROM NEW.status OR OLD.connection_status IS DISTINCT FROM NEW.connection_status) THEN
      PERFORM pg_notify('change_agent_status', 
            (SELECT row_to_json(r.*)::varchar FROM (
            SELECT  id, status, uuid, name, connection_status, yard_id, modified_at from public.agents where id = NEW.id)
            r)
        );
    END IF;

    IF (OLD.public_key IS DISTINCT FROM NEW.public_key OR OLD.verify_signature IS DISTINCT FROM NEW.verify_signature OR
        OLD.rbmq_username IS DISTINCT FROM NEW.rbmq_username OR OLD.allow_anonymous_checkin IS DISTINCT FROM NEW.allow_anonymous_checkin) THEN
      PERFORM pg_notify('change_agent_security', 
            (SELECT row_to_json(r.*)::varchar FROM (
            SELECT  id, public_key, uuid, verify_signature, rbmq_username, allow_anonymous_checkin, yard_id, modified_at from public.agents where id = NEW.id)
            r)
        );
    END IF;

    RETURN NULL;
    END; 
$$;


ALTER FUNCTION public.notify_change_tool() OWNER TO postgres;

--
-- TOC entry 301 (class 1255 OID 16808)
-- Name: notify_deleted_tool(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_deleted_tool() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      PERFORM pg_notify('agent_deletion', row_to_json(OLD)::text);
        RETURN NULL;
    END; 
$$;


ALTER FUNCTION public.notify_deleted_tool() OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 16817)
-- Name: notify_instant_actions_insertion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_instant_actions_insertion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        PERFORM pg_notify('instant_actions_insertion',            
              (SELECT row_to_json(r.*)::varchar FROM (
              SELECT id, tool_id, tool_uuid, agent_id, agent_uuid, sender, command from public.instant_actions  where id = NEW.id)
              r)
          );
        RETURN NULL;
    END; 
  $$;


ALTER FUNCTION public.notify_instant_actions_insertion() OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 16822)
-- Name: notify_mission_queue_insertion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_mission_queue_insertion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
   BEGIN
       PERFORM pg_notify('mission_queue_insertion',            
            (SELECT row_to_json(r.*)::varchar FROM (
             SELECT  id, status,  sched_start_at from public.mission_queue  where id = NEW.id)
            r)
        );
       RETURN NULL;
   END; 
$$;


ALTER FUNCTION public.notify_mission_queue_insertion() OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 16821)
-- Name: notify_mission_queue_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_mission_queue_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        --PERFORM pg_notify('mission_queue_update',  row_to_json(NEW)::text);
        PERFORM pg_notify('mission_queue_update',            
            (SELECT row_to_json(r.*)::varchar FROM (
             SELECT id, status,  sched_start_at from public.mission_queue  where id = NEW.id)
            r)
        );
        RETURN NULL;
    END; 
$$;


ALTER FUNCTION public.notify_mission_queue_update() OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 16807)
-- Name: notify_new_rabbitmq_account(integer, text, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.notify_new_rabbitmq_account(agent_id integer, username text, password text)
    LANGUAGE plpgsql
    AS $$
    BEGIN
       PERFORM pg_notify('new_rabbitmq_account', (json_build_object('username', username, 'password', password, 'agent_id', agent_id))::text);
    END; 
$$;


ALTER PROCEDURE public.notify_new_rabbitmq_account(agent_id integer, username text, password text) OWNER TO postgres;

--
-- TOC entry 306 (class 1255 OID 16825)
-- Name: notify_service_requests_insertion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_service_requests_insertion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
   BEGIN
       PERFORM pg_notify('service_requests_insertion',            
            (SELECT row_to_json(r.*)::varchar FROM (
             SELECT  id, work_process_id, fetched, processed, canceled, status from public.service_requests  where id = NEW.id)
            r)
        );
       RETURN NULL;
   END; 
$$;


ALTER FUNCTION public.notify_service_requests_insertion() OWNER TO postgres;

--
-- TOC entry 307 (class 1255 OID 16826)
-- Name: notify_service_requests_updates(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_service_requests_updates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        PERFORM pg_notify('service_requests_update', 
            (SELECT row_to_json(r.*)::varchar FROM (
            SELECT  id, work_process_id, fetched, processed, canceled, service_type, request_uid,
                    status, next_request_to_dispatch_uid, is_result_assignment, assignment_dispatched,
                     context->'map'->>'id' as yard_id from public.service_requests  where id = NEW.id)
            r)
        );
        RETURN NULL;
    END; 
$$;


ALTER FUNCTION public.notify_service_requests_updates() OWNER TO postgres;

--
-- TOC entry 317 (class 1255 OID 16843)
-- Name: notify_work_processes_insertion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_work_processes_insertion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
   BEGIN
       PERFORM pg_notify('work_processes_insertion',            
            (SELECT row_to_json(r.*)::varchar FROM (
             SELECT id, yard_id, yard_uid, work_process_type_id, status, work_process_type_name, tool_ids, tools_uuids, agent_ids, agent_uuids, sched_start_at from public.work_processes  where id = NEW.id)
            r)
        );
       RETURN NULL;
   END; 
$$;


ALTER FUNCTION public.notify_work_processes_insertion() OWNER TO postgres;

--
-- TOC entry 315 (class 1255 OID 16841)
-- Name: notify_work_processes_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_work_processes_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        --PERFORM pg_notify('work_processes_update',  row_to_json(NEW)::text);
        PERFORM pg_notify('work_processes_update',            
            (SELECT row_to_json(r.*)::varchar FROM (
             SELECT id, yard_id, work_process_type_id, status, work_process_type_name, tool_ids, agent_ids,  tools_uuids, agent_uuids, sched_start_at from public.work_processes  where id = NEW.id)
            r)
        );
        RETURN NULL;
    END; 
$$;


ALTER FUNCTION public.notify_work_processes_update() OWNER TO postgres;

--
-- TOC entry 318 (class 1255 OID 16844)
-- Name: prevent_mission_running_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_mission_running_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.data IS DISTINCT FROM NEW.data THEN
        RAISE EXCEPTION SQLSTATE '90005' USING MESSAGE = 'Request data cannot be updated in a running mission.';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_mission_running_update() OWNER TO postgres;

--
-- TOC entry 304 (class 1255 OID 16819)
-- Name: recentmap_objects(double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.recentmap_objects(test_time double precision) RETURNS SETOF public.map_objects
    LANGUAGE sql STABLE
    AS $$

 SELECT *  FROM public.map_objects WHERE created_at > to_timestamp(test_time) OR
                modified_at > to_timestamp(test_time) OR 
                deleted_at > to_timestamp(test_time);
 
$$;


ALTER FUNCTION public.recentmap_objects(test_time double precision) OWNER TO postgres;

--
-- TOC entry 302 (class 1255 OID 16809)
-- Name: register_rabbitmq_account(integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.register_rabbitmq_account(agent_id integer, username text, password text) RETURNS integer
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $_$

DECLARE
  v_RowCountInt int;
BEGIN

  update  public.agents as A set rbmq_username=username, rbmq_encrypted_password=crypt(password, gen_salt('bf')) where A.id=$1;
  GET DIAGNOSTICS v_RowCountInt = ROW_COUNT;
  IF v_RowCountInt = 0 then 
    RAISE EXCEPTION SQLSTATE '90004' USING MESSAGE = 'agent id not found' ;
  END IF;

  
  CALL public.notify_new_rabbitmq_account(agent_id, username, password);

  return 0;

END
$_$;


ALTER FUNCTION public.register_rabbitmq_account(agent_id integer, username text, password text) OWNER TO postgres;

--
-- TOC entry 313 (class 1255 OID 16831)
-- Name: register_user(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.register_user(name text, username text, password text, admin_password text) RETURNS public.users
    LANGUAGE plpgsql STRICT SECURITY DEFINER
    AS $$
DECLARE
  new_user public.users;
  admin_account public.user_account;
BEGIN
  select a.* into admin_account from public.user_account as a WHERE a.username = 'admin';

  IF admin_account.password_hash = crypt(admin_password, admin_account.password_hash) then

      insert into public.users (name, email, role) values (name, username, 1)
      returning * into new_user;

      insert into public.user_account (user_id, username, user_role, password_hash) values
        (new_user.id, username, 1, crypt(password, gen_salt('bf')));
      return new_user;

  ELSE
    RAISE EXCEPTION SQLSTATE '90001' USING MESSAGE = 'Incorrect admin password' ;
  END IF;
END
$$;


ALTER FUNCTION public.register_user(name text, username text, password text, admin_password text) OWNER TO postgres;

--
-- TOC entry 3474 (class 0 OID 0)
-- Dependencies: 313
-- Name: FUNCTION register_user(name text, username text, password text, admin_password text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.register_user(name text, username text, password text, admin_password text) IS 'Registers a single user and creates an account.';


--
-- TOC entry 227 (class 1259 OID 16639)
-- Name: agent_poses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agent_poses (
    id bigint NOT NULL,
    tool_id bigint,
    agent_id bigint,
    yard_id bigint,
    work_process_id bigint,
    x double precision,
    y double precision,
    z double precision,
    orientation double precision,
    orientations double precision[],
    sensors jsonb,
    status character varying,
    assignment jsonb,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.agent_poses OWNER TO postgres;

--
-- TOC entry 3476 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN agent_poses.agent_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_poses.agent_id IS '@ agent_id foreign key to agents';


--
-- TOC entry 3477 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN agent_poses.x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_poses.x IS '@ tool x pose in relative yard coordinates (arb unit)';


--
-- TOC entry 3478 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN agent_poses.y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_poses.y IS '@ tool y pose in relative yard coordinates (arb unit)';


--
-- TOC entry 3479 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN agent_poses.orientation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_poses.orientation IS '@ tool orientation (mrad)';


--
-- TOC entry 3480 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN agent_poses.sensors; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agent_poses.sensors IS '@ object with sensor data from tool';


--
-- TOC entry 299 (class 1255 OID 16804)
-- Name: selecttoolposehistory(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.selecttoolposehistory(start_time double precision, end_time double precision) RETURNS SETOF public.agent_poses
    LANGUAGE sql STABLE
    AS $$

 SELECT *  FROM public.agent_poses WHERE created_at < to_timestamp(end_time) AND  created_at > to_timestamp(start_time);
 
$$;


ALTER FUNCTION public.selecttoolposehistory(start_time double precision, end_time double precision) OWNER TO postgres;

--
-- TOC entry 308 (class 1255 OID 16827)
-- Name: send_next_service(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.send_next_service() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
     next_planner_uid varchar;
     new_status  varchar;

    BEGIN
      new_status := TG_ARGV[0]; 
      next_planner_uid := NEW.next_request_to_dispatch_uid;

            UPDATE public.send_next_service SET  status =  new_status   WHERE planner_uid = next_planner_uid;
    END; 
    $$;


ALTER FUNCTION public.send_next_service() OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 16472)
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.modified_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_set_timestamp() OWNER TO postgres;

--
-- TOC entry 295 (class 1255 OID 16529)
-- Name: trigger_set_timestamp_mission_queue(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_set_timestamp_mission_queue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.modified_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_set_timestamp_mission_queue() OWNER TO postgres;

--
-- TOC entry 298 (class 1255 OID 16563)
-- Name: trigger_set_timestamp_work_processes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_set_timestamp_work_processes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.modified_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_set_timestamp_work_processes() OWNER TO postgres;

--
-- TOC entry 316 (class 1255 OID 16842)
-- Name: update_work_process_list_order(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_work_process_list_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
   BEGIN
      NEW.run_order = (SELECT count(*)+1 from public.work_processes where mission_queue_id = NEW.mission_queue_id);
      RETURN NEW;
   END; 
$$;


ALTER FUNCTION public.update_work_process_list_order() OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16637)
-- Name: agent_poses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agent_poses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.agent_poses_id_seq OWNER TO postgres;

--
-- TOC entry 3487 (class 0 OID 0)
-- Dependencies: 226
-- Name: agent_poses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agent_poses_id_seq OWNED BY public.agent_poses.id;


--
-- TOC entry 229 (class 1259 OID 16651)
-- Name: agents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents (
    id bigint NOT NULL,
    work_process_id bigint,
    proxy_tool_id bigint,
    agent_class character varying DEFAULT 'vehicle'::character varying,
    agent_type character varying,
    connection_status character varying DEFAULT 'offline'::character varying,
    code character varying,
    name character varying,
    message_channel character varying,
    public_key character varying,
    public_key_format character varying(255) DEFAULT 'PEM'::character varying,
    verify_signature boolean DEFAULT false,
    picture text,
    is_actuator boolean DEFAULT true,
    is_simulator boolean DEFAULT false,
    yard_id bigint,
    rbmq_username character varying(255) DEFAULT NULL::character varying,
    rbmq_encrypted_password text DEFAULT ''::text,
    has_rbmq_account boolean DEFAULT false,
    protocol text DEFAULT 'AMQP'::text,
    msg_per_sec double precision DEFAULT 0,
    updt_per_sec double precision DEFAULT 0,
    operation_types character varying[],
    last_message_time timestamp(6) without time zone DEFAULT now() NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    modified_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    stream_url character varying,
    allow_anonymous_checkin boolean DEFAULT true,
    uuid character varying,
    geometry jsonb,
    factsheet jsonb,
    x double precision DEFAULT 0,
    y double precision DEFAULT 0,
    z double precision DEFAULT 0,
    unit character varying,
    orientation double precision,
    orientations double precision[],
    status character varying,
    state character varying,
    sensors jsonb,
    wp_clearance jsonb,
    assignment jsonb,
    resources jsonb,
    acknowledge_reservation boolean DEFAULT true,
    sensors_data_format character varying DEFAULT 'helyos-native'::character varying,
    geometry_data_format character varying DEFAULT 'trucktrix-vehicle'::character varying,
    data_format character varying DEFAULT 'trucktrix-vehicle'::character varying
);


ALTER TABLE public.agents OWNER TO postgres;

--
-- TOC entry 3489 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.connection_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.connection_status IS '@ tool connection status: "online", "offline" (more than 30 seconds without any agent update)';


--
-- TOC entry 3490 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.rbmq_encrypted_password; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.rbmq_encrypted_password IS '@ rabbitmq password for the agent: random password hashed using the agent public key';


--
-- TOC entry 3491 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.geometry; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.geometry IS '@ tool geometry object';


--
-- TOC entry 3492 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.factsheet; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.factsheet IS '@ tool geometry object';


--
-- TOC entry 3493 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.x IS '@ tool x pose - horizontal (unit)';


--
-- TOC entry 3494 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.y IS '@ tool y pose - vertical (unit)';


--
-- TOC entry 3495 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.z; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.z IS '@ tool z pose - altitude (unit)';


--
-- TOC entry 3496 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.orientations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.orientations IS '@ tool orientations (mrad)';


--
-- TOC entry 3497 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.status IS '@ tool status: Depracated. It will be converted to state.';


--
-- TOC entry 3498 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.state; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.state IS '@ tool state: "free", "busy", "ready"';


--
-- TOC entry 3499 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.wp_clearance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.wp_clearance IS '@ tool response for the last request to change its status to "READY" for a specific work process';


--
-- TOC entry 3500 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.acknowledge_reservation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.acknowledge_reservation IS '@ if false helyOS will send the assigment immediatelly after the reservation request.';


--
-- TOC entry 3501 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN agents.sensors_data_format; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents.sensors_data_format IS '@ JSON data structure for the field sensors';


--
-- TOC entry 228 (class 1259 OID 16649)
-- Name: agents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.agents_id_seq OWNER TO postgres;

--
-- TOC entry 3503 (class 0 OID 0)
-- Dependencies: 228
-- Name: agents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agents_id_seq OWNED BY public.agents.id;


--
-- TOC entry 231 (class 1259 OID 16693)
-- Name: agents_interconnections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_interconnections (
    id bigint NOT NULL,
    leader_id bigint,
    follower_id bigint,
    connection_geometry jsonb,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.agents_interconnections OWNER TO postgres;

--
-- TOC entry 3505 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN agents_interconnections.leader_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_interconnections.leader_id IS '@  leading, usually owns a computer for interface';


--
-- TOC entry 3506 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN agents_interconnections.follower_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_interconnections.follower_id IS '@  follower, e.g. trailer';


--
-- TOC entry 3507 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN agents_interconnections.connection_geometry; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.agents_interconnections.connection_geometry IS '@  connection_geometry data';


--
-- TOC entry 230 (class 1259 OID 16691)
-- Name: agents_interconnections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agents_interconnections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.agents_interconnections_id_seq OWNER TO postgres;

--
-- TOC entry 3509 (class 0 OID 0)
-- Dependencies: 230
-- Name: agents_interconnections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agents_interconnections_id_seq OWNED BY public.agents_interconnections.id;


--
-- TOC entry 221 (class 1259 OID 16593)
-- Name: agents_work_processes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agents_work_processes (
    tool_id bigint NOT NULL,
    work_process_id bigint NOT NULL
);


ALTER TABLE public.agents_work_processes OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 16431)
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.ar_internal_metadata OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16722)
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assignments_id_seq OWNER TO postgres;

--
-- TOC entry 3511 (class 0 OID 0)
-- Dependencies: 232
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- TOC entry 237 (class 1259 OID 16759)
-- Name: guidelines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.guidelines (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now(),
    deleted_at timestamp(6) without time zone,
    type character varying,
    name character varying,
    geometry jsonb,
    geometry_type character varying,
    data jsonb,
    data_type character varying,
    start_x integer,
    start_y integer,
    start_orientation integer,
    yard_id bigint
);


ALTER TABLE public.guidelines OWNER TO postgres;

--
-- TOC entry 3513 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN guidelines.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.guidelines.type IS '@ type: "permanent", "pre-calculated"';


--
-- TOC entry 3514 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN guidelines.geometry; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.guidelines.geometry IS '@description JSON field with information to build the geometry, e.g {points:[]}. It depends on the geometry_type';


--
-- TOC entry 3515 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN guidelines.geometry_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.guidelines.geometry_type IS '@description It defines the format of geometry. E.g. "polyline"';


--
-- TOC entry 3516 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN guidelines.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.guidelines.data IS '@description Add any information relevant for actions performed in this guideline';


--
-- TOC entry 3517 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN guidelines.start_x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.guidelines.start_x IS '@ x coordinate of vehicle point at beginning of guide line path.';


--
-- TOC entry 3518 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN guidelines.start_y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.guidelines.start_y IS '@ y coordinate of vehicle point at beginning of guide line path.';


--
-- TOC entry 236 (class 1259 OID 16757)
-- Name: guidelines_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.guidelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.guidelines_id_seq OWNER TO postgres;

--
-- TOC entry 3520 (class 0 OID 0)
-- Dependencies: 236
-- Name: guidelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.guidelines_id_seq OWNED BY public.guidelines.id;


--
-- TOC entry 241 (class 1259 OID 16788)
-- Name: instant_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.instant_actions (
    id bigint NOT NULL,
    yard_id bigint,
    tool_id bigint,
    agent_id bigint,
    tool_uuid character varying,
    agent_uuid character varying,
    sender character varying,
    command character varying,
    result character varying,
    status character varying,
    error character varying,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.instant_actions OWNER TO postgres;

--
-- TOC entry 3522 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN instant_actions.yard_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instant_actions.yard_id IS '@ yard ID where assignment should be performed';


--
-- TOC entry 3523 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN instant_actions.agent_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instant_actions.agent_id IS '@ agent for which assignment is assigned';


--
-- TOC entry 3524 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN instant_actions.command; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instant_actions.command IS '@ string for command';


--
-- TOC entry 3525 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN instant_actions.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.instant_actions.status IS '@ status of assignment: "to_dispatch", "executing", "succeeded", "failed", "canceled"';


--
-- TOC entry 240 (class 1259 OID 16786)
-- Name: instant_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.instant_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.instant_actions_id_seq OWNER TO postgres;

--
-- TOC entry 3527 (class 0 OID 0)
-- Dependencies: 240
-- Name: instant_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.instant_actions_id_seq OWNED BY public.instant_actions.id;


--
-- TOC entry 205 (class 1259 OID 16453)
-- Name: map_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.map_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.map_objects_id_seq OWNER TO postgres;

--
-- TOC entry 3529 (class 0 OID 0)
-- Dependencies: 205
-- Name: map_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.map_objects_id_seq OWNED BY public.map_objects.id;


--
-- TOC entry 212 (class 1259 OID 16518)
-- Name: mission_queue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mission_queue (
    id bigint NOT NULL,
    name character varying,
    status character varying,
    description character varying,
    created_at timestamp(6) without time zone DEFAULT now(),
    modified_at timestamp(6) without time zone DEFAULT now(),
    started_at timestamp(6) without time zone,
    ended_at timestamp(6) without time zone,
    sched_start_at timestamp(6) without time zone,
    sched_end_at timestamp(6) without time zone,
    stop_on_failure boolean DEFAULT false
);


ALTER TABLE public.mission_queue OWNER TO postgres;

--
-- TOC entry 3531 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN mission_queue.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mission_queue.status IS '@ status of this work process: "stop", "stopped", "failed", "run", "running", "ended", "ended-with-failures"';


--
-- TOC entry 3532 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN mission_queue.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mission_queue.description IS '@ description';


--
-- TOC entry 3533 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN mission_queue.sched_start_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mission_queue.sched_start_at IS '@ specify when the work process will be processed: path planning, agent reservation, etc.';


--
-- TOC entry 3534 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN mission_queue.stop_on_failure; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.mission_queue.stop_on_failure IS '@ specify if the run list should stop or continue when one work process fails';


--
-- TOC entry 211 (class 1259 OID 16516)
-- Name: mission_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.mission_queue ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.mission_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 201 (class 1259 OID 16423)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16533)
-- Name: service_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_requests (
    id bigint NOT NULL,
    work_process_id character varying,
    request jsonb,
    config jsonb,
    response jsonb,
    service_type character varying,
    service_url character varying,
    service_queue_id character varying,
    result_timeout integer DEFAULT 180,
    context jsonb,
    require_agents_data boolean DEFAULT true,
    require_mission_agents_data boolean DEFAULT true,
    require_map_data boolean DEFAULT true,
    tool_ids integer[],
    agent_ids integer[],
    step character varying,
    request_uid character varying,
    next_request_to_dispatch_uid character varying,
    next_request_to_dispatch_uids text[],
    next_step text[],
    depend_on_requests text[],
    is_result_assignment boolean,
    wait_dependencies_assignments boolean,
    start_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    assignment_dispatched boolean,
    status character varying,
    fetched boolean,
    processed boolean,
    canceled boolean,
    dispatched_at timestamp(6) without time zone,
    result_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6) without time zone,
    modified_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.service_requests OWNER TO postgres;

--
-- TOC entry 3537 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN service_requests.request; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_requests.request IS '@ request object';


--
-- TOC entry 3538 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN service_requests.response; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_requests.response IS '@ result object';


--
-- TOC entry 3539 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN service_requests.service_queue_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_requests.service_queue_id IS '@ request id provided by web service';


--
-- TOC entry 3540 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN service_requests.context; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_requests.context IS '@ context object';


--
-- TOC entry 3541 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN service_requests.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_requests.status IS '@ status of service request: "not_ready_for_service", "ready_for_service", "pending", "ready"';


--
-- TOC entry 3542 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN service_requests.fetched; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_requests.fetched IS '@ shows if request has been send to service';


--
-- TOC entry 3543 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN service_requests.processed; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_requests.processed IS '@ shows if result is received from service';


--
-- TOC entry 3544 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN service_requests.canceled; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_requests.canceled IS '@ field to cancel service request';


--
-- TOC entry 213 (class 1259 OID 16531)
-- Name: service_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.service_requests_id_seq OWNER TO postgres;

--
-- TOC entry 3546 (class 0 OID 0)
-- Dependencies: 213
-- Name: service_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_requests_id_seq OWNED BY public.service_requests.id;


--
-- TOC entry 210 (class 1259 OID 16496)
-- Name: services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.services (
    id bigint NOT NULL,
    name character varying,
    service_type character varying,
    service_url character varying,
    health_endpoint character varying,
    licence_key character varying,
    config jsonb,
    class character varying,
    is_dummy boolean DEFAULT false,
    unhealthy boolean DEFAULT false,
    enabled boolean DEFAULT false,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6) without time zone,
    modified_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    availability_timeout integer DEFAULT 180,
    result_timeout integer DEFAULT 180,
    require_agents_data boolean DEFAULT true,
    require_mission_agents_data boolean DEFAULT true,
    require_map_data boolean DEFAULT true
);


ALTER TABLE public.services OWNER TO postgres;

--
-- TOC entry 3548 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.name IS '@ name of service';


--
-- TOC entry 3549 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.service_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.service_type IS '@ type of service. Examples: "drive", "field_cover", "storage", "map"';


--
-- TOC entry 3550 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.service_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.service_url IS '@ url of the web service';


--
-- TOC entry 3551 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.health_endpoint; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.health_endpoint IS '@ end-point that returns status 2XX when service is healthy';


--
-- TOC entry 3552 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.licence_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.licence_key IS '@ licence key (to be provided for web service as x-api-key header)';


--
-- TOC entry 3553 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.config; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.config IS '@ additional information to be provided for web service. For instance, for trucktrix path planner the following parameters could be provided (default first): "trucktrix_planner_type": "all_directions"/"forward"; "postprocessing": "no_postprocessing"/"smoothing"/"high_resolution_at_end". ';


--
-- TOC entry 3554 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.class; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.class IS '@ class of web service. Supported: "Path Planner", "Storage", "Map Service"';


--
-- TOC entry 3555 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.is_dummy; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.is_dummy IS '@ do not dispatch request; just copy request body to response body';


--
-- TOC entry 3556 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.unhealthy; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.unhealthy IS '@  Is microservice unhealthy?';


--
-- TOC entry 3557 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.availability_timeout; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.availability_timeout IS '@ maximum time helyos will hold a request waiting for the system to be healthy';


--
-- TOC entry 3558 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN services.result_timeout; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.services.result_timeout IS '@ maximum time helyOS will wait for the result in seconds';


--
-- TOC entry 209 (class 1259 OID 16494)
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.services_id_seq OWNER TO postgres;

--
-- TOC entry 3560 (class 0 OID 0)
-- Dependencies: 209
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- TOC entry 208 (class 1259 OID 16476)
-- Name: shapes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shapes (
    id bigint NOT NULL,
    yard_id bigint,
    geometry jsonb,
    is_obstacle boolean,
    is_permanent boolean,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6) without time zone,
    modified_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    data jsonb,
    geometry_type character varying,
    data_type character varying,
    type character varying,
    cost integer,
    data_format character varying DEFAULT 'trucktrix-map'::character varying
);


ALTER TABLE public.shapes OWNER TO postgres;

--
-- TOC entry 3562 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN shapes.geometry; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shapes.geometry IS '@description JSON field with information to build the geometry, e.g {points:[], top:1000, bottom:0}. It depends on the shape.geometry_type';


--
-- TOC entry 3563 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN shapes.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shapes.data IS '@description Add any information relevant for actions performed in this shape; e.g. initial/final position inside shape';


--
-- TOC entry 3564 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN shapes.geometry_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shapes.geometry_type IS '@description It defines the format of shape.geometry. E.g. "polygons"';


--
-- TOC entry 3565 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN shapes.data_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shapes.data_type IS '@description Define type of information carried by the field data';


--
-- TOC entry 3566 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN shapes.type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shapes.type IS '@description Shape type: "crop", "road", "drivable", "guide-line", "obstacle" ';


--
-- TOC entry 3567 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN shapes.data_format; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.shapes.data_format IS '@description Define the format of the object shape. The default is trucktrix-map';


--
-- TOC entry 207 (class 1259 OID 16474)
-- Name: shapes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shapes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shapes_id_seq OWNER TO postgres;

--
-- TOC entry 3569 (class 0 OID 0)
-- Dependencies: 207
-- Name: shapes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shapes_id_seq OWNED BY public.shapes.id;


--
-- TOC entry 239 (class 1259 OID 16776)
-- Name: system_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_logs (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now(),
    yard_id bigint,
    wproc_id bigint,
    tool_uuid character varying,
    agent_uuid character varying,
    service_type character varying,
    event character varying,
    origin character varying,
    log_type character varying,
    collected boolean,
    msg character varying
);


ALTER TABLE public.system_logs OWNER TO postgres;

--
-- TOC entry 3571 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN system_logs.event; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.system_logs.event IS '@ "send to microservice" | "get from microservice" | "send to agent" | "get from agent" | "service unhealthy"';


--
-- TOC entry 3572 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN system_logs.origin; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.system_logs.origin IS '@ "microservice" | "agent" | "app" | "database"';


--
-- TOC entry 3573 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN system_logs.log_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.system_logs.log_type IS '@ "error" | "warning" | "normal"';


--
-- TOC entry 3574 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN system_logs.collected; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.system_logs.collected IS '@ if log was sent to a log collector service';


--
-- TOC entry 3575 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN system_logs.msg; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.system_logs.msg IS '@ log message.';


--
-- TOC entry 238 (class 1259 OID 16774)
-- Name: system_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.system_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.system_logs_id_seq OWNER TO postgres;

--
-- TOC entry 3577 (class 0 OID 0)
-- Dependencies: 238
-- Name: system_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.system_logs_id_seq OWNED BY public.system_logs.id;


--
-- TOC entry 235 (class 1259 OID 16747)
-- Name: targets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.targets (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now(),
    deleted_at timestamp(6) without time zone,
    target_type character varying,
    target_name character varying,
    anchor character varying,
    x integer,
    y integer,
    orientation integer,
    yard_id bigint
);


ALTER TABLE public.targets OWNER TO postgres;

--
-- TOC entry 3579 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN targets.target_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.targets.target_type IS '@ type: "parking", "gate"';


--
-- TOC entry 3580 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN targets.anchor; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.targets.anchor IS '@ anchor variants: "front", "back", "middle"';


--
-- TOC entry 3581 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN targets.x; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.targets.x IS '@ x coordinate of vehicle point at target corresponding to anchor';


--
-- TOC entry 3582 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN targets.y; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.targets.y IS '@ y coordinate of vehicle point at target corresponding to anchor';


--
-- TOC entry 3583 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN targets.orientation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.targets.orientation IS '@ orientation of vehicle at target';


--
-- TOC entry 234 (class 1259 OID 16745)
-- Name: targets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.targets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.targets_id_seq OWNER TO postgres;

--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 234
-- Name: targets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.targets_id_seq OWNED BY public.targets.id;


--
-- TOC entry 225 (class 1259 OID 16618)
-- Name: user_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_account (
    id bigint NOT NULL,
    user_id integer,
    username character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    modified_at timestamp without time zone,
    description character varying,
    metadata json,
    email text,
    password_hash text NOT NULL,
    user_role integer
);


ALTER TABLE public.user_account OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16616)
-- Name: user_account_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_account_id_seq OWNER TO postgres;

--
-- TOC entry 3588 (class 0 OID 0)
-- Dependencies: 224
-- Name: user_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_account_id_seq OWNED BY public.user_account.id;


--
-- TOC entry 222 (class 1259 OID 16602)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 3590 (class 0 OID 0)
-- Dependencies: 222
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 220 (class 1259 OID 16578)
-- Name: work_process_service_plan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.work_process_service_plan (
    id bigint NOT NULL,
    work_process_type_id bigint,
    step character varying,
    request_order integer,
    agent integer,
    service_type character varying,
    service_config jsonb,
    depends_on_steps jsonb,
    is_result_assignment boolean,
    wait_dependencies_assignments boolean DEFAULT true
);


ALTER TABLE public.work_process_service_plan OWNER TO postgres;

--
-- TOC entry 3592 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN work_process_service_plan.step; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_process_service_plan.step IS '@description Label ("A", "B"..."Z") of the calculation step. Each step represents one request.';


--
-- TOC entry 3593 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN work_process_service_plan.request_order; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_process_service_plan.request_order IS '@description Order of the requests sent to external service.';


--
-- TOC entry 3594 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN work_process_service_plan.service_config; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_process_service_plan.service_config IS '@description It overides default config of external service.';


--
-- TOC entry 3595 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN work_process_service_plan.is_result_assignment; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_process_service_plan.is_result_assignment IS '@description If request result should be dispacthed as an assignment.';


--
-- TOC entry 219 (class 1259 OID 16576)
-- Name: work_process_service_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.work_process_service_plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.work_process_service_plan_id_seq OWNER TO postgres;

--
-- TOC entry 3597 (class 0 OID 0)
-- Dependencies: 219
-- Name: work_process_service_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.work_process_service_plan_id_seq OWNED BY public.work_process_service_plan.id;


--
-- TOC entry 218 (class 1259 OID 16567)
-- Name: work_process_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.work_process_type (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    num_max_agents integer,
    dispatch_order jsonb,
    settings jsonb,
    extra_params jsonb
);


ALTER TABLE public.work_process_type OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16565)
-- Name: work_process_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.work_process_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.work_process_type_id_seq OWNER TO postgres;

--
-- TOC entry 3600 (class 0 OID 0)
-- Dependencies: 217
-- Name: work_process_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.work_process_type_id_seq OWNED BY public.work_process_type.id;


--
-- TOC entry 216 (class 1259 OID 16551)
-- Name: work_processes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.work_processes (
    id bigint NOT NULL,
    mission_queue_id bigint,
    run_order integer DEFAULT 0,
    yard_id bigint,
    yard_uid character varying,
    work_process_type_id integer,
    status character varying,
    work_process_type_name character varying NOT NULL,
    description character varying,
    data jsonb,
    tool_ids integer[],
    tools_uuids text[],
    agent_ids integer[],
    agent_uuids text[],
    created_at timestamp(6) without time zone DEFAULT now(),
    modified_at timestamp(6) without time zone DEFAULT now(),
    started_at timestamp(6) without time zone,
    ended_at timestamp(6) without time zone,
    sched_start_at timestamp(6) without time zone,
    sched_end_at timestamp(6) without time zone,
    wait_free_agent boolean DEFAULT true,
    process_type character varying
);


ALTER TABLE public.work_processes OWNER TO postgres;

--
-- TOC entry 3602 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.yard_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.yard_id IS '@ db id of yard where happens the work process';


--
-- TOC entry 3603 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.yard_uid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.yard_uid IS '@ unique identifier of yard where happens the work process; the redundancy with yard_id is necessary to improve usability of graphQL requests';


--
-- TOC entry 3604 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.status IS '@ status of this work process: "created", "planning", "executing", "succeeded"';


--
-- TOC entry 3605 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.description IS '@ object with request data';


--
-- TOC entry 3606 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.data IS '@ object with request data';


--
-- TOC entry 3607 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.tool_ids; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.tool_ids IS '@ array of tools participating within work process';


--
-- TOC entry 3608 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.tools_uuids; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.tools_uuids IS '@ array DEPRECATED of tools uuids participating within work process; the redundancy with tool_ids is necessary to improve usability of graphQL requests';


--
-- TOC entry 3609 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.agent_ids; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.agent_ids IS '@ array of agent ids participating within work process; the redundancy with tool_ids is necessary to improve usability of graphQL requests';


--
-- TOC entry 3610 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.agent_uuids; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.agent_uuids IS '@ array of agent uuids participating within work process; the redundancy with tool_ids is necessary to improve usability of graphQL requests';


--
-- TOC entry 3611 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN work_processes.sched_start_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.work_processes.sched_start_at IS '@ specify when the work process will be processed: path planning, agent reservation, etc.';


--
-- TOC entry 215 (class 1259 OID 16549)
-- Name: work_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.work_processes ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.work_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 204 (class 1259 OID 16441)
-- Name: yards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.yards (
    id bigint NOT NULL,
    uid character varying,
    name character varying,
    source character varying,
    yard_type character varying,
    map_data jsonb,
    lat double precision,
    lon double precision,
    originshift_dx integer,
    originshift_dy integer,
    picture_base64 text,
    picture_pos jsonb,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    deleted_at timestamp(6) without time zone,
    modified_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    description character varying,
    alt double precision,
    data_format character varying DEFAULT 'trucktrix-map'::character varying
);


ALTER TABLE public.yards OWNER TO postgres;

--
-- TOC entry 3614 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN yards.yard_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.yards.yard_type IS '@ type of the yard. Currently supported: "logistic_yard"';


--
-- TOC entry 3615 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN yards.map_data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.yards.map_data IS '@ map data object. Example: { "origin": { "lat": 51.0531973, "lon": 13.7031056, "zoomLevel": 19 }}';


--
-- TOC entry 3616 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN yards.lat; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.yards.lat IS '@ latitude of the yard reference point';


--
-- TOC entry 3617 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN yards.lon; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.yards.lon IS '@ longitude of the yard reference point';


--
-- TOC entry 3618 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN yards.description; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.yards.description IS '@ field for the arbitrary description of the yard';


--
-- TOC entry 203 (class 1259 OID 16439)
-- Name: yards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.yards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.yards_id_seq OWNER TO postgres;

--
-- TOC entry 3620 (class 0 OID 0)
-- Dependencies: 203
-- Name: yards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.yards_id_seq OWNED BY public.yards.id;


--
-- TOC entry 3137 (class 2604 OID 16642)
-- Name: agent_poses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_poses ALTER COLUMN id SET DEFAULT nextval('public.agent_poses_id_seq'::regclass);


--
-- TOC entry 3139 (class 2604 OID 16654)
-- Name: agents id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents ALTER COLUMN id SET DEFAULT nextval('public.agents_id_seq'::regclass);


--
-- TOC entry 3163 (class 2604 OID 16696)
-- Name: agents_interconnections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_interconnections ALTER COLUMN id SET DEFAULT nextval('public.agents_interconnections_id_seq'::regclass);


--
-- TOC entry 3165 (class 2604 OID 16727)
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- TOC entry 3170 (class 2604 OID 16762)
-- Name: guidelines id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guidelines ALTER COLUMN id SET DEFAULT nextval('public.guidelines_id_seq'::regclass);


--
-- TOC entry 3174 (class 2604 OID 16791)
-- Name: instant_actions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instant_actions ALTER COLUMN id SET DEFAULT nextval('public.instant_actions_id_seq'::regclass);


--
-- TOC entry 3093 (class 2604 OID 16458)
-- Name: map_objects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.map_objects ALTER COLUMN id SET DEFAULT nextval('public.map_objects_id_seq'::regclass);


--
-- TOC entry 3115 (class 2604 OID 16536)
-- Name: service_requests id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_requests ALTER COLUMN id SET DEFAULT nextval('public.service_requests_id_seq'::regclass);


--
-- TOC entry 3101 (class 2604 OID 16499)
-- Name: services id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- TOC entry 3097 (class 2604 OID 16479)
-- Name: shapes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shapes ALTER COLUMN id SET DEFAULT nextval('public.shapes_id_seq'::regclass);


--
-- TOC entry 3172 (class 2604 OID 16779)
-- Name: system_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_logs ALTER COLUMN id SET DEFAULT nextval('public.system_logs_id_seq'::regclass);


--
-- TOC entry 3168 (class 2604 OID 16750)
-- Name: targets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.targets ALTER COLUMN id SET DEFAULT nextval('public.targets_id_seq'::regclass);


--
-- TOC entry 3134 (class 2604 OID 16621)
-- Name: user_account id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account ALTER COLUMN id SET DEFAULT nextval('public.user_account_id_seq'::regclass);


--
-- TOC entry 3130 (class 2604 OID 16607)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3128 (class 2604 OID 16581)
-- Name: work_process_service_plan id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_process_service_plan ALTER COLUMN id SET DEFAULT nextval('public.work_process_service_plan_id_seq'::regclass);


--
-- TOC entry 3127 (class 2604 OID 16570)
-- Name: work_process_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_process_type ALTER COLUMN id SET DEFAULT nextval('public.work_process_type_id_seq'::regclass);


--
-- TOC entry 3089 (class 2604 OID 16444)
-- Name: yards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yards ALTER COLUMN id SET DEFAULT nextval('public.yards_id_seq'::regclass);


--
-- TOC entry 3415 (class 0 OID 16639)
-- Dependencies: 227
-- Data for Name: agent_poses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agent_poses (id, tool_id, agent_id, yard_id, work_process_id, x, y, z, orientation, orientations, sensors, status, assignment, created_at) FROM stdin;
\.


--
-- TOC entry 3417 (class 0 OID 16651)
-- Dependencies: 229
-- Data for Name: agents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents (id, work_process_id, proxy_tool_id, agent_class, agent_type, connection_status, code, name, message_channel, public_key, public_key_format, verify_signature, picture, is_actuator, is_simulator, yard_id, rbmq_username, rbmq_encrypted_password, has_rbmq_account, protocol, msg_per_sec, updt_per_sec, operation_types, last_message_time, created_at, modified_at, stream_url, allow_anonymous_checkin, uuid, geometry, factsheet, x, y, z, unit, orientation, orientations, status, state, sensors, wp_clearance, assignment, resources, acknowledge_reservation, sensors_data_format, geometry_data_format, data_format) FROM stdin;
\.


--
-- TOC entry 3419 (class 0 OID 16693)
-- Dependencies: 231
-- Data for Name: agents_interconnections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_interconnections (id, leader_id, follower_id, connection_geometry, created_at) FROM stdin;
\.


--
-- TOC entry 3409 (class 0 OID 16593)
-- Dependencies: 221
-- Data for Name: agents_work_processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.agents_work_processes (tool_id, work_process_id) FROM stdin;
\.


--
-- TOC entry 3390 (class 0 OID 16431)
-- Dependencies: 202
-- Data for Name: ar_internal_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3421 (class 0 OID 16724)
-- Dependencies: 233
-- Data for Name: assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assignments (id, yard_id, work_process_id, tool_id, agent_id, service_request_id, data, context, result, status, start_time_stamp, depend_on_assignments, next_assignments, error, created_at, modified_at) FROM stdin;
\.


--
-- TOC entry 3425 (class 0 OID 16759)
-- Dependencies: 237
-- Data for Name: guidelines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.guidelines (id, created_at, deleted_at, type, name, geometry, geometry_type, data, data_type, start_x, start_y, start_orientation, yard_id) FROM stdin;
\.


--
-- TOC entry 3429 (class 0 OID 16788)
-- Dependencies: 241
-- Data for Name: instant_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.instant_actions (id, yard_id, tool_id, agent_id, tool_uuid, agent_uuid, sender, command, result, status, error, created_at) FROM stdin;
\.


--
-- TOC entry 3394 (class 0 OID 16455)
-- Dependencies: 206
-- Data for Name: map_objects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.map_objects (id, yard_id, data, type, data_format, metadata, created_at, modified_at, deleted_at, name) FROM stdin;
\.


--
-- TOC entry 3400 (class 0 OID 16518)
-- Dependencies: 212
-- Data for Name: mission_queue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mission_queue (id, name, status, description, created_at, modified_at, started_at, ended_at, sched_start_at, sched_end_at, stop_on_failure) FROM stdin;
\.


--
-- TOC entry 3389 (class 0 OID 16423)
-- Dependencies: 201
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version) FROM stdin;
\.


--
-- TOC entry 3402 (class 0 OID 16533)
-- Dependencies: 214
-- Data for Name: service_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_requests (id, work_process_id, request, config, response, service_type, service_url, service_queue_id, result_timeout, context, require_agents_data, require_mission_agents_data, require_map_data, tool_ids, agent_ids, step, request_uid, next_request_to_dispatch_uid, next_request_to_dispatch_uids, next_step, depend_on_requests, is_result_assignment, wait_dependencies_assignments, start_at, assignment_dispatched, status, fetched, processed, canceled, dispatched_at, result_at, created_at, deleted_at, modified_at) FROM stdin;
\.


--
-- TOC entry 3398 (class 0 OID 16496)
-- Dependencies: 210
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.services (id, name, service_type, service_url, health_endpoint, licence_key, config, class, is_dummy, unhealthy, enabled, created_at, deleted_at, modified_at, availability_timeout, result_timeout, require_agents_data, require_mission_agents_data, require_map_data) FROM stdin;
\.


--
-- TOC entry 3396 (class 0 OID 16476)
-- Dependencies: 208
-- Data for Name: shapes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shapes (id, yard_id, geometry, is_obstacle, is_permanent, created_at, deleted_at, modified_at, data, geometry_type, data_type, type, cost, data_format) FROM stdin;
\.


--
-- TOC entry 3427 (class 0 OID 16776)
-- Dependencies: 239
-- Data for Name: system_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_logs (id, created_at, yard_id, wproc_id, tool_uuid, agent_uuid, service_type, event, origin, log_type, collected, msg) FROM stdin;
\.


--
-- TOC entry 3423 (class 0 OID 16747)
-- Dependencies: 235
-- Data for Name: targets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.targets (id, created_at, deleted_at, target_type, target_name, anchor, x, y, orientation, yard_id) FROM stdin;
\.


--
-- TOC entry 3413 (class 0 OID 16618)
-- Dependencies: 225
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_account (id, user_id, username, created_at, modified_at, description, metadata, email, password_hash, user_role) FROM stdin;
1	1	admin	2024-03-06 13:18:46.450484	\N	\N	\N	admin	$2a$06$S2eZNP5bzlzmtXPEYDco1eSOxqw/ZP3xfJYusiKUMJzD7fgPBeXsi	0
\.


--
-- TOC entry 3411 (class 0 OID 16604)
-- Dependencies: 223
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, reset_password_token, reset_password_sent_at, remember_created_at, sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, created_at, modified_at, name, metadata, role) FROM stdin;
1		\N	\N	\N	0	\N	\N	\N	\N	2024-03-06 13:18:46.448568	\N	admin	\N	0
\.


--
-- TOC entry 3408 (class 0 OID 16578)
-- Dependencies: 220
-- Data for Name: work_process_service_plan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_process_service_plan (id, work_process_type_id, step, request_order, agent, service_type, service_config, depends_on_steps, is_result_assignment, wait_dependencies_assignments) FROM stdin;
1	1	A	1	1	my_driving	\N	[]	t	t
\.


--
-- TOC entry 3406 (class 0 OID 16567)
-- Dependencies: 218
-- Data for Name: work_process_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_process_type (id, name, description, num_max_agents, dispatch_order, settings, extra_params) FROM stdin;
1	driving	drive from a to b	1	[["A"]]	\N	\N
\.


--
-- TOC entry 3404 (class 0 OID 16551)
-- Dependencies: 216
-- Data for Name: work_processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.work_processes (id, mission_queue_id, run_order, yard_id, yard_uid, work_process_type_id, status, work_process_type_name, description, data, tool_ids, tools_uuids, agent_ids, agent_uuids, created_at, modified_at, started_at, ended_at, sched_start_at, sched_end_at, wait_free_agent, process_type) FROM stdin;
\.


--
-- TOC entry 3392 (class 0 OID 16441)
-- Dependencies: 204
-- Data for Name: yards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.yards (id, uid, name, source, yard_type, map_data, lat, lon, originshift_dx, originshift_dy, picture_base64, picture_pos, created_at, deleted_at, modified_at, description, alt, data_format) FROM stdin;
1	1	LatLng Yard	initial data	logistic_yard	{"origin": {"alt": 300, "lat": 51.0504, "lon": 13.7373, "zoomLevel": 19}}	51.0504	13.7373	\N	\N	\N	\N	2020-08-03 12:00:00	\N	2020-08-03 12:00:00	test yard	0	trucktrix-map
\.


--
-- TOC entry 3622 (class 0 OID 0)
-- Dependencies: 226
-- Name: agent_poses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.agent_poses_id_seq', 1, false);


--
-- TOC entry 3623 (class 0 OID 0)
-- Dependencies: 228
-- Name: agents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.agents_id_seq', 1, false);


--
-- TOC entry 3624 (class 0 OID 0)
-- Dependencies: 230
-- Name: agents_interconnections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.agents_interconnections_id_seq', 1, false);


--
-- TOC entry 3625 (class 0 OID 0)
-- Dependencies: 232
-- Name: assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assignments_id_seq', 1, false);


--
-- TOC entry 3626 (class 0 OID 0)
-- Dependencies: 236
-- Name: guidelines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.guidelines_id_seq', 1, false);


--
-- TOC entry 3627 (class 0 OID 0)
-- Dependencies: 240
-- Name: instant_actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.instant_actions_id_seq', 1, false);


--
-- TOC entry 3628 (class 0 OID 0)
-- Dependencies: 205
-- Name: map_objects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.map_objects_id_seq', 1, false);


--
-- TOC entry 3629 (class 0 OID 0)
-- Dependencies: 211
-- Name: mission_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mission_queue_id_seq', 1, false);


--
-- TOC entry 3630 (class 0 OID 0)
-- Dependencies: 213
-- Name: service_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_requests_id_seq', 1, false);


--
-- TOC entry 3631 (class 0 OID 0)
-- Dependencies: 209
-- Name: services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.services_id_seq', 1, false);


--
-- TOC entry 3632 (class 0 OID 0)
-- Dependencies: 207
-- Name: shapes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shapes_id_seq', 1, false);


--
-- TOC entry 3633 (class 0 OID 0)
-- Dependencies: 238
-- Name: system_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.system_logs_id_seq', 1, false);


--
-- TOC entry 3634 (class 0 OID 0)
-- Dependencies: 234
-- Name: targets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.targets_id_seq', 1, false);


--
-- TOC entry 3635 (class 0 OID 0)
-- Dependencies: 224
-- Name: user_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_account_id_seq', 10, true);


--
-- TOC entry 3636 (class 0 OID 0)
-- Dependencies: 222
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 10, true);


--
-- TOC entry 3637 (class 0 OID 0)
-- Dependencies: 219
-- Name: work_process_service_plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.work_process_service_plan_id_seq', 1, true);


--
-- TOC entry 3638 (class 0 OID 0)
-- Dependencies: 217
-- Name: work_process_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.work_process_type_id_seq', 1, true);


--
-- TOC entry 3639 (class 0 OID 0)
-- Dependencies: 215
-- Name: work_processes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.work_processes_id_seq', 1, false);


--
-- TOC entry 3640 (class 0 OID 0)
-- Dependencies: 203
-- Name: yards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.yards_id_seq', 1, false);


--
-- TOC entry 3208 (class 2606 OID 16648)
-- Name: agent_poses agent_poses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_poses
    ADD CONSTRAINT agent_poses_pkey PRIMARY KEY (id);


--
-- TOC entry 3216 (class 2606 OID 16704)
-- Name: agents_interconnections agents_interconnections_leader_id_follower_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_interconnections
    ADD CONSTRAINT agents_interconnections_leader_id_follower_id_key UNIQUE (leader_id, follower_id);


--
-- TOC entry 3218 (class 2606 OID 16702)
-- Name: agents_interconnections agents_interconnections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_interconnections
    ADD CONSTRAINT agents_interconnections_pkey PRIMARY KEY (id);


--
-- TOC entry 3212 (class 2606 OID 16682)
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- TOC entry 3214 (class 2606 OID 16684)
-- Name: agents agents_uuid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_uuid_key UNIQUE (uuid);


--
-- TOC entry 3179 (class 2606 OID 16438)
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- TOC entry 3220 (class 2606 OID 16734)
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- TOC entry 3224 (class 2606 OID 16768)
-- Name: guidelines guidelines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guidelines
    ADD CONSTRAINT guidelines_pkey PRIMARY KEY (id);


--
-- TOC entry 3228 (class 2606 OID 16797)
-- Name: instant_actions instant_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.instant_actions
    ADD CONSTRAINT instant_actions_pkey PRIMARY KEY (id);


--
-- TOC entry 3183 (class 2606 OID 16466)
-- Name: map_objects map_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.map_objects
    ADD CONSTRAINT map_objects_pkey PRIMARY KEY (id);


--
-- TOC entry 3190 (class 2606 OID 16528)
-- Name: mission_queue mission_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mission_queue
    ADD CONSTRAINT mission_queue_pkey PRIMARY KEY (id);


--
-- TOC entry 3177 (class 2606 OID 16430)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- TOC entry 3192 (class 2606 OID 16548)
-- Name: service_requests service_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_requests
    ADD CONSTRAINT service_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 3188 (class 2606 OID 16514)
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- TOC entry 3185 (class 2606 OID 16487)
-- Name: shapes shapes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shapes
    ADD CONSTRAINT shapes_pkey PRIMARY KEY (id);


--
-- TOC entry 3226 (class 2606 OID 16785)
-- Name: system_logs system_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 3222 (class 2606 OID 16756)
-- Name: targets targets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.targets
    ADD CONSTRAINT targets_pkey PRIMARY KEY (id);


--
-- TOC entry 3204 (class 2606 OID 16628)
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);


--
-- TOC entry 3206 (class 2606 OID 16630)
-- Name: user_account user_account_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_username_key UNIQUE (username);


--
-- TOC entry 3202 (class 2606 OID 16615)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3198 (class 2606 OID 16587)
-- Name: work_process_service_plan work_process_service_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_process_service_plan
    ADD CONSTRAINT work_process_service_plan_pkey PRIMARY KEY (id);


--
-- TOC entry 3196 (class 2606 OID 16575)
-- Name: work_process_type work_process_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_process_type
    ADD CONSTRAINT work_process_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3194 (class 2606 OID 16562)
-- Name: work_processes work_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_processes
    ADD CONSTRAINT work_processes_pkey PRIMARY KEY (id);


--
-- TOC entry 3181 (class 2606 OID 16452)
-- Name: yards yards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.yards
    ADD CONSTRAINT yards_pkey PRIMARY KEY (id);


--
-- TOC entry 3209 (class 1259 OID 16685)
-- Name: index_tool_poses_on_agent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_tool_poses_on_agent_id ON public.agent_poses USING btree (agent_id);


--
-- TOC entry 3210 (class 1259 OID 16719)
-- Name: index_tool_poses_on_tool_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_tool_poses_on_tool_id ON public.agent_poses USING btree (tool_id);


--
-- TOC entry 3199 (class 1259 OID 16596)
-- Name: index_tools_work_processes_on_work_process_id_and_tool_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_tools_work_processes_on_work_process_id_and_tool_id ON public.agents_work_processes USING btree (work_process_id, tool_id);


--
-- TOC entry 3200 (class 1259 OID 16636)
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- TOC entry 3186 (class 1259 OID 16515)
-- Name: only_one_type_enabled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX only_one_type_enabled ON public.services USING btree (service_type, service_type) WHERE (enabled IS TRUE);


--
-- TOC entry 3253 (class 2620 OID 16810)
-- Name: agents change_sensors_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER change_sensors_trigger AFTER UPDATE ON public.agents FOR EACH ROW WHEN ((((old.status)::text IS DISTINCT FROM (new.status)::text) OR (((new.status)::text = 'busy'::text) AND ((old.x IS DISTINCT FROM new.x) OR (old.y IS DISTINCT FROM new.y) OR (old.z IS DISTINCT FROM new.z) OR (old.assignment IS DISTINCT FROM new.assignment))))) EXECUTE FUNCTION public.create_row_tool_sensors_history();


--
-- TOC entry 3254 (class 2620 OID 16811)
-- Name: agents change_tool_status_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER change_tool_status_trigger AFTER UPDATE ON public.agents FOR EACH ROW WHEN ((((old.status)::text IS DISTINCT FROM (new.status)::text) OR ((old.connection_status)::text IS DISTINCT FROM (new.connection_status)::text) OR (old.protocol IS DISTINCT FROM new.protocol) OR ((old.public_key)::text IS DISTINCT FROM (new.public_key)::text) OR (old.verify_signature IS DISTINCT FROM new.verify_signature) OR ((old.rbmq_username)::text IS DISTINCT FROM (new.rbmq_username)::text) OR (old.allow_anonymous_checkin IS DISTINCT FROM new.allow_anonymous_checkin))) EXECUTE FUNCTION public.notify_change_tool();


--
-- TOC entry 3255 (class 2620 OID 16812)
-- Name: agents delete_tool_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER delete_tool_trigger AFTER DELETE ON public.agents FOR EACH ROW EXECUTE FUNCTION public.notify_deleted_tool();


--
-- TOC entry 3256 (class 2620 OID 16815)
-- Name: assignments notify_assignments_insertion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_assignments_insertion AFTER INSERT ON public.assignments FOR EACH ROW EXECUTE FUNCTION public.notify_assignments_insertion();


--
-- TOC entry 3257 (class 2620 OID 16816)
-- Name: assignments notify_assignments_updates; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_assignments_updates AFTER UPDATE ON public.assignments FOR EACH ROW WHEN (((old.status)::text IS DISTINCT FROM (new.status)::text)) EXECUTE FUNCTION public.notify_assignments_updates();


--
-- TOC entry 3242 (class 2620 OID 16823)
-- Name: mission_queue notify_mission_queue_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_mission_queue_update AFTER UPDATE ON public.mission_queue FOR EACH ROW EXECUTE FUNCTION public.notify_mission_queue_update();


--
-- TOC entry 3245 (class 2620 OID 16829)
-- Name: service_requests notify_service_requests_insertion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_service_requests_insertion AFTER INSERT ON public.service_requests FOR EACH ROW EXECUTE FUNCTION public.notify_service_requests_insertion();


--
-- TOC entry 3246 (class 2620 OID 16830)
-- Name: service_requests notify_service_requests_updates; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_service_requests_updates AFTER UPDATE ON public.service_requests FOR EACH ROW EXECUTE FUNCTION public.notify_service_requests_updates();


--
-- TOC entry 3248 (class 2620 OID 16845)
-- Name: work_processes notify_work_processes_before_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_work_processes_before_update BEFORE UPDATE ON public.work_processes FOR EACH ROW WHEN ((((old.status)::text = 'executing'::text) OR ((old.status)::text = 'calculating'::text))) EXECUTE FUNCTION public.prevent_mission_running_update();


--
-- TOC entry 3249 (class 2620 OID 16846)
-- Name: work_processes notify_work_processes_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER notify_work_processes_update AFTER UPDATE ON public.work_processes FOR EACH ROW EXECUTE FUNCTION public.notify_work_processes_update();


--
-- TOC entry 3240 (class 2620 OID 16473)
-- Name: map_objects set_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.map_objects FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 3241 (class 2620 OID 16493)
-- Name: shapes set_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.shapes FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- TOC entry 3243 (class 2620 OID 16530)
-- Name: mission_queue set_timestamp_mission_queue; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_mission_queue BEFORE UPDATE ON public.mission_queue FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp_mission_queue();


--
-- TOC entry 3250 (class 2620 OID 16564)
-- Name: work_processes set_timestamp_work_processes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_timestamp_work_processes BEFORE UPDATE ON public.work_processes FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp_work_processes();


--
-- TOC entry 3244 (class 2620 OID 16824)
-- Name: mission_queue trigger_mission_queue_insertion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_mission_queue_insertion AFTER INSERT ON public.mission_queue FOR EACH ROW EXECUTE FUNCTION public.notify_mission_queue_insertion();


--
-- TOC entry 3258 (class 2620 OID 16818)
-- Name: instant_actions trigger_new_instant_action_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_new_instant_action_trigger AFTER INSERT ON public.instant_actions FOR EACH ROW EXECUTE FUNCTION public.notify_instant_actions_insertion();


--
-- TOC entry 3247 (class 2620 OID 16828)
-- Name: service_requests trigger_service_requests_ready; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_service_requests_ready AFTER UPDATE ON public.service_requests FOR EACH ROW WHEN (((old.response IS DISTINCT FROM new.response) AND (new.next_request_to_dispatch_uid IS NOT NULL) AND ((new.status)::text = 'SUCCESS'::text))) EXECUTE FUNCTION public.send_next_service('READY_TO_BE_SENT');


--
-- TOC entry 3251 (class 2620 OID 16847)
-- Name: work_processes trigger_work_processes_before_insertion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_work_processes_before_insertion BEFORE INSERT ON public.work_processes FOR EACH ROW EXECUTE FUNCTION public.update_work_process_list_order();


--
-- TOC entry 3252 (class 2620 OID 16848)
-- Name: work_processes trigger_work_processes_insertion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_work_processes_insertion AFTER INSERT ON public.work_processes FOR EACH ROW EXECUTE FUNCTION public.notify_work_processes_insertion();


--
-- TOC entry 3237 (class 2606 OID 16740)
-- Name: assignments assignments_service_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_service_request_id_fkey FOREIGN KEY (service_request_id) REFERENCES public.service_requests(id) ON DELETE SET NULL;


--
-- TOC entry 3238 (class 2606 OID 16735)
-- Name: assignments assignments_work_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_work_process_id_fkey FOREIGN KEY (work_process_id) REFERENCES public.work_processes(id) ON DELETE CASCADE;


--
-- TOC entry 3235 (class 2606 OID 16710)
-- Name: agents_interconnections fk_follower_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_interconnections
    ADD CONSTRAINT fk_follower_id FOREIGN KEY (follower_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- TOC entry 3236 (class 2606 OID 16705)
-- Name: agents_interconnections fk_leader_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agents_interconnections
    ADD CONSTRAINT fk_leader_id FOREIGN KEY (leader_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- TOC entry 3234 (class 2606 OID 16686)
-- Name: agent_poses fk_rails_d915c2fa05; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agent_poses
    ADD CONSTRAINT fk_rails_d915c2fa05 FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- TOC entry 3231 (class 2606 OID 16597)
-- Name: work_processes fk_wp_mission_queue; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_processes
    ADD CONSTRAINT fk_wp_mission_queue FOREIGN KEY (mission_queue_id) REFERENCES public.mission_queue(id) ON DELETE SET NULL;


--
-- TOC entry 3239 (class 2606 OID 16769)
-- Name: guidelines guidelines_yard_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guidelines
    ADD CONSTRAINT guidelines_yard_id_fkey FOREIGN KEY (yard_id) REFERENCES public.yards(id);


--
-- TOC entry 3229 (class 2606 OID 16467)
-- Name: map_objects map_objects_yard_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.map_objects
    ADD CONSTRAINT map_objects_yard_id_fkey FOREIGN KEY (yard_id) REFERENCES public.yards(id) ON DELETE CASCADE;


--
-- TOC entry 3230 (class 2606 OID 16488)
-- Name: shapes shapes_yard_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shapes
    ADD CONSTRAINT shapes_yard_id_fkey FOREIGN KEY (yard_id) REFERENCES public.yards(id);


--
-- TOC entry 3233 (class 2606 OID 16631)
-- Name: user_account user_account_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3232 (class 2606 OID 16588)
-- Name: work_process_service_plan work_process_service_plan_work_process_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.work_process_service_plan
    ADD CONSTRAINT work_process_service_plan_work_process_type_id_fkey FOREIGN KEY (work_process_type_id) REFERENCES public.work_process_type(id) ON DELETE CASCADE;


--
-- TOC entry 3436 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO role_anonymous;
GRANT USAGE ON SCHEMA public TO role_application;
GRANT USAGE ON SCHEMA public TO role_admin;


--
-- TOC entry 3438 (class 0 OID 0)
-- Dependencies: 312
-- Name: FUNCTION admin_change_password(username text, password text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.admin_change_password(username text, password text) TO role_admin;
GRANT ALL ON FUNCTION public.admin_change_password(username text, password text) TO role_postgraphile;
GRANT ALL ON FUNCTION public.admin_change_password(username text, password text) TO role_application;


--
-- TOC entry 3440 (class 0 OID 0)
-- Dependencies: 314
-- Name: FUNCTION admin_get_user_authtoken(username text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.admin_get_user_authtoken(username text) TO role_admin;
GRANT ALL ON FUNCTION public.admin_get_user_authtoken(username text) TO role_postgraphile;
GRANT ALL ON FUNCTION public.admin_get_user_authtoken(username text) TO role_application;


--
-- TOC entry 3442 (class 0 OID 0)
-- Dependencies: 310
-- Name: FUNCTION authenticate(username text, password text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.authenticate(username text, password text) TO role_application;
GRANT ALL ON FUNCTION public.authenticate(username text, password text) TO role_admin;
GRANT ALL ON FUNCTION public.authenticate(username text, password text) TO role_anonymous;
GRANT ALL ON FUNCTION public.authenticate(username text, password text) TO role_postgraphile;


--
-- TOC entry 3443 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.users TO role_anonymous;
GRANT SELECT,DELETE,UPDATE ON TABLE public.users TO role_application;
GRANT SELECT,DELETE,UPDATE ON TABLE public.users TO role_admin;


--
-- TOC entry 3445 (class 0 OID 0)
-- Dependencies: 311
-- Name: FUNCTION change_password(username text, new_password text, current_password text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.change_password(username text, new_password text, current_password text) TO role_application;
GRANT ALL ON FUNCTION public.change_password(username text, new_password text, current_password text) TO role_admin;
GRANT ALL ON FUNCTION public.change_password(username text, new_password text, current_password text) TO role_anonymous;
GRANT ALL ON FUNCTION public.change_password(username text, new_password text, current_password text) TO role_postgraphile;


--
-- TOC entry 3446 (class 0 OID 0)
-- Dependencies: 303
-- Name: FUNCTION create_row_tool_sensors_history(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_row_tool_sensors_history() TO role_admin;
GRANT ALL ON FUNCTION public.create_row_tool_sensors_history() TO role_application;
GRANT ALL ON FUNCTION public.create_row_tool_sensors_history() TO role_postgraphile;


--
-- TOC entry 3452 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE assignments; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.assignments TO role_visualization;
GRANT SELECT ON TABLE public.assignments TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.assignments TO role_admin;


--
-- TOC entry 3453 (class 0 OID 0)
-- Dependencies: 319
-- Name: FUNCTION getworkprocessactiondata(w_process_id bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.getworkprocessactiondata(w_process_id bigint) TO role_admin;
GRANT ALL ON FUNCTION public.getworkprocessactiondata(w_process_id bigint) TO role_application;
GRANT ALL ON FUNCTION public.getworkprocessactiondata(w_process_id bigint) TO role_postgraphile;


--
-- TOC entry 3455 (class 0 OID 0)
-- Dependencies: 309
-- Name: FUNCTION logout(username text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.logout(username text) TO role_application;
GRANT ALL ON FUNCTION public.logout(username text) TO role_admin;
GRANT ALL ON FUNCTION public.logout(username text) TO role_postgraphile;


--
-- TOC entry 3461 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE map_objects; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.map_objects TO role_visualization;
GRANT SELECT ON TABLE public.map_objects TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.map_objects TO role_admin;


--
-- TOC entry 3462 (class 0 OID 0)
-- Dependencies: 305
-- Name: FUNCTION mark_deleted_all_map_objects_of_yard(yard_id_input bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.mark_deleted_all_map_objects_of_yard(yard_id_input bigint) TO role_application;
GRANT ALL ON FUNCTION public.mark_deleted_all_map_objects_of_yard(yard_id_input bigint) TO role_admin;
GRANT ALL ON FUNCTION public.mark_deleted_all_map_objects_of_yard(yard_id_input bigint) TO role_postgraphile;


--
-- TOC entry 3463 (class 0 OID 0)
-- Dependencies: 292
-- Name: FUNCTION notify_assignments_insertion(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_assignments_insertion() TO role_application;
GRANT ALL ON FUNCTION public.notify_assignments_insertion() TO role_admin;
GRANT ALL ON FUNCTION public.notify_assignments_insertion() TO role_postgraphile;


--
-- TOC entry 3464 (class 0 OID 0)
-- Dependencies: 293
-- Name: FUNCTION notify_assignments_updates(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_assignments_updates() TO role_application;
GRANT ALL ON FUNCTION public.notify_assignments_updates() TO role_admin;
GRANT ALL ON FUNCTION public.notify_assignments_updates() TO role_postgraphile;


--
-- TOC entry 3465 (class 0 OID 0)
-- Dependencies: 300
-- Name: FUNCTION notify_change_tool(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_change_tool() TO role_application;
GRANT ALL ON FUNCTION public.notify_change_tool() TO role_admin;
GRANT ALL ON FUNCTION public.notify_change_tool() TO role_postgraphile;


--
-- TOC entry 3466 (class 0 OID 0)
-- Dependencies: 301
-- Name: FUNCTION notify_deleted_tool(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_deleted_tool() TO role_application;
GRANT ALL ON FUNCTION public.notify_deleted_tool() TO role_admin;
GRANT ALL ON FUNCTION public.notify_deleted_tool() TO role_postgraphile;


--
-- TOC entry 3467 (class 0 OID 0)
-- Dependencies: 296
-- Name: FUNCTION notify_instant_actions_insertion(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_instant_actions_insertion() TO role_application;
GRANT ALL ON FUNCTION public.notify_instant_actions_insertion() TO role_admin;
GRANT ALL ON FUNCTION public.notify_instant_actions_insertion() TO role_postgraphile;


--
-- TOC entry 3468 (class 0 OID 0)
-- Dependencies: 297
-- Name: FUNCTION notify_mission_queue_insertion(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_mission_queue_insertion() TO role_application;
GRANT ALL ON FUNCTION public.notify_mission_queue_insertion() TO role_admin;
GRANT ALL ON FUNCTION public.notify_mission_queue_insertion() TO role_postgraphile;


--
-- TOC entry 3469 (class 0 OID 0)
-- Dependencies: 294
-- Name: FUNCTION notify_mission_queue_update(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_mission_queue_update() TO role_application;
GRANT ALL ON FUNCTION public.notify_mission_queue_update() TO role_admin;
GRANT ALL ON FUNCTION public.notify_mission_queue_update() TO role_postgraphile;


--
-- TOC entry 3470 (class 0 OID 0)
-- Dependencies: 306
-- Name: FUNCTION notify_service_requests_insertion(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_service_requests_insertion() TO role_application;
GRANT ALL ON FUNCTION public.notify_service_requests_insertion() TO role_admin;
GRANT ALL ON FUNCTION public.notify_service_requests_insertion() TO role_postgraphile;


--
-- TOC entry 3471 (class 0 OID 0)
-- Dependencies: 307
-- Name: FUNCTION notify_service_requests_updates(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_service_requests_updates() TO role_application;
GRANT ALL ON FUNCTION public.notify_service_requests_updates() TO role_admin;
GRANT ALL ON FUNCTION public.notify_service_requests_updates() TO role_postgraphile;


--
-- TOC entry 3472 (class 0 OID 0)
-- Dependencies: 304
-- Name: FUNCTION recentmap_objects(test_time double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.recentmap_objects(test_time double precision) TO role_application;
GRANT ALL ON FUNCTION public.recentmap_objects(test_time double precision) TO role_admin;
GRANT ALL ON FUNCTION public.recentmap_objects(test_time double precision) TO role_postgraphile;


--
-- TOC entry 3473 (class 0 OID 0)
-- Dependencies: 302
-- Name: FUNCTION register_rabbitmq_account(agent_id integer, username text, password text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.register_rabbitmq_account(agent_id integer, username text, password text) TO role_application;
GRANT ALL ON FUNCTION public.register_rabbitmq_account(agent_id integer, username text, password text) TO role_admin;
GRANT ALL ON FUNCTION public.register_rabbitmq_account(agent_id integer, username text, password text) TO role_postgraphile;


--
-- TOC entry 3475 (class 0 OID 0)
-- Dependencies: 313
-- Name: FUNCTION register_user(name text, username text, password text, admin_password text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.register_user(name text, username text, password text, admin_password text) TO role_admin;
GRANT ALL ON FUNCTION public.register_user(name text, username text, password text, admin_password text) TO role_postgraphile;
GRANT ALL ON FUNCTION public.register_user(name text, username text, password text, admin_password text) TO role_application;


--
-- TOC entry 3481 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE agent_poses; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.agent_poses TO role_visualization;
GRANT SELECT ON TABLE public.agent_poses TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agent_poses TO role_admin;


--
-- TOC entry 3482 (class 0 OID 0)
-- Dependencies: 299
-- Name: FUNCTION selecttoolposehistory(start_time double precision, end_time double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.selecttoolposehistory(start_time double precision, end_time double precision) TO role_application;
GRANT ALL ON FUNCTION public.selecttoolposehistory(start_time double precision, end_time double precision) TO role_admin;
GRANT ALL ON FUNCTION public.selecttoolposehistory(start_time double precision, end_time double precision) TO role_postgraphile;


--
-- TOC entry 3483 (class 0 OID 0)
-- Dependencies: 308
-- Name: FUNCTION send_next_service(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.send_next_service() TO role_application;
GRANT ALL ON FUNCTION public.send_next_service() TO role_admin;
GRANT ALL ON FUNCTION public.send_next_service() TO role_postgraphile;


--
-- TOC entry 3484 (class 0 OID 0)
-- Dependencies: 291
-- Name: FUNCTION trigger_set_timestamp(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.trigger_set_timestamp() TO role_application;
GRANT ALL ON FUNCTION public.trigger_set_timestamp() TO role_admin;
GRANT ALL ON FUNCTION public.trigger_set_timestamp() TO role_postgraphile;


--
-- TOC entry 3485 (class 0 OID 0)
-- Dependencies: 295
-- Name: FUNCTION trigger_set_timestamp_mission_queue(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.trigger_set_timestamp_mission_queue() TO role_application;
GRANT ALL ON FUNCTION public.trigger_set_timestamp_mission_queue() TO role_admin;
GRANT ALL ON FUNCTION public.trigger_set_timestamp_mission_queue() TO role_postgraphile;


--
-- TOC entry 3486 (class 0 OID 0)
-- Dependencies: 298
-- Name: FUNCTION trigger_set_timestamp_work_processes(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.trigger_set_timestamp_work_processes() TO role_application;
GRANT ALL ON FUNCTION public.trigger_set_timestamp_work_processes() TO role_admin;
GRANT ALL ON FUNCTION public.trigger_set_timestamp_work_processes() TO role_postgraphile;


--
-- TOC entry 3488 (class 0 OID 0)
-- Dependencies: 226
-- Name: SEQUENCE agent_poses_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.agent_poses_id_seq TO role_admin;


--
-- TOC entry 3502 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE agents; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.agents TO role_visualization;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents TO role_admin;


--
-- TOC entry 3504 (class 0 OID 0)
-- Dependencies: 228
-- Name: SEQUENCE agents_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.agents_id_seq TO role_admin;


--
-- TOC entry 3508 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE agents_interconnections; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.agents_interconnections TO role_application;


--
-- TOC entry 3510 (class 0 OID 0)
-- Dependencies: 230
-- Name: SEQUENCE agents_interconnections_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.agents_interconnections_id_seq TO role_admin;


--
-- TOC entry 3512 (class 0 OID 0)
-- Dependencies: 232
-- Name: SEQUENCE assignments_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.assignments_id_seq TO role_admin;


--
-- TOC entry 3519 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE guidelines; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.guidelines TO role_application;


--
-- TOC entry 3521 (class 0 OID 0)
-- Dependencies: 236
-- Name: SEQUENCE guidelines_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.guidelines_id_seq TO role_admin;


--
-- TOC entry 3526 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE instant_actions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.instant_actions TO role_visualization;
GRANT SELECT,INSERT,UPDATE ON TABLE public.instant_actions TO role_application;
GRANT SELECT,INSERT,DELETE ON TABLE public.instant_actions TO role_admin;


--
-- TOC entry 3528 (class 0 OID 0)
-- Dependencies: 240
-- Name: SEQUENCE instant_actions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.instant_actions_id_seq TO role_admin;


--
-- TOC entry 3530 (class 0 OID 0)
-- Dependencies: 205
-- Name: SEQUENCE map_objects_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.map_objects_id_seq TO role_admin;


--
-- TOC entry 3535 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE mission_queue; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.mission_queue TO role_visualization;
GRANT SELECT,INSERT,UPDATE ON TABLE public.mission_queue TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.mission_queue TO role_admin;


--
-- TOC entry 3536 (class 0 OID 0)
-- Dependencies: 211
-- Name: SEQUENCE mission_queue_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.mission_queue_id_seq TO role_admin;


--
-- TOC entry 3545 (class 0 OID 0)
-- Dependencies: 214
-- Name: TABLE service_requests; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE ON TABLE public.service_requests TO role_admin;


--
-- TOC entry 3547 (class 0 OID 0)
-- Dependencies: 213
-- Name: SEQUENCE service_requests_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.service_requests_id_seq TO role_admin;


--
-- TOC entry 3559 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE services; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.services TO role_admin;


--
-- TOC entry 3561 (class 0 OID 0)
-- Dependencies: 209
-- Name: SEQUENCE services_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.services_id_seq TO role_admin;


--
-- TOC entry 3568 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE shapes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.shapes TO role_visualization;
GRANT SELECT ON TABLE public.shapes TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.shapes TO role_admin;


--
-- TOC entry 3570 (class 0 OID 0)
-- Dependencies: 207
-- Name: SEQUENCE shapes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.shapes_id_seq TO role_admin;


--
-- TOC entry 3576 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE system_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.system_logs TO role_visualization;
GRANT SELECT ON TABLE public.system_logs TO role_application;
GRANT SELECT,INSERT,DELETE ON TABLE public.system_logs TO role_admin;


--
-- TOC entry 3578 (class 0 OID 0)
-- Dependencies: 238
-- Name: SEQUENCE system_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.system_logs_id_seq TO role_admin;


--
-- TOC entry 3584 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE targets; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.targets TO role_application;


--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 234
-- Name: SEQUENCE targets_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.targets_id_seq TO role_admin;


--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE user_account; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_account TO role_admin;


--
-- TOC entry 3589 (class 0 OID 0)
-- Dependencies: 224
-- Name: SEQUENCE user_account_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.user_account_id_seq TO role_admin;


--
-- TOC entry 3591 (class 0 OID 0)
-- Dependencies: 222
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.users_id_seq TO role_admin;


--
-- TOC entry 3596 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE work_process_service_plan; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.work_process_service_plan TO role_visualization;
GRANT SELECT ON TABLE public.work_process_service_plan TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.work_process_service_plan TO role_admin;


--
-- TOC entry 3598 (class 0 OID 0)
-- Dependencies: 219
-- Name: SEQUENCE work_process_service_plan_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.work_process_service_plan_id_seq TO role_admin;


--
-- TOC entry 3599 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE work_process_type; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.work_process_type TO role_visualization;
GRANT SELECT ON TABLE public.work_process_type TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.work_process_type TO role_admin;


--
-- TOC entry 3601 (class 0 OID 0)
-- Dependencies: 217
-- Name: SEQUENCE work_process_type_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.work_process_type_id_seq TO role_admin;


--
-- TOC entry 3612 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE work_processes; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.work_processes TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.work_processes TO role_admin;


--
-- TOC entry 3613 (class 0 OID 0)
-- Dependencies: 215
-- Name: SEQUENCE work_processes_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.work_processes_id_seq TO role_admin;


--
-- TOC entry 3619 (class 0 OID 0)
-- Dependencies: 204
-- Name: TABLE yards; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.yards TO role_visualization;
GRANT SELECT ON TABLE public.yards TO role_application;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.yards TO role_admin;


--
-- TOC entry 3621 (class 0 OID 0)
-- Dependencies: 203
-- Name: SEQUENCE yards_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.yards_id_seq TO role_admin;


--
-- TOC entry 1923 (class 826 OID 16803)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES  TO role_application;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES  TO role_admin;


-- Completed on 2024-03-06 14:22:43

--
-- PostgreSQL database dump complete
--

