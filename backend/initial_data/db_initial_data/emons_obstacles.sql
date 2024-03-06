--
-- PostgreSQL database dump
--

-- Dumped from database version 10.12 (Debian 10.12-2.pgdg90+1)
-- Dumped by pg_dump version 10.13 (Ubuntu 10.13-1.pgdg18.04+1)

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
-- Data for Name: work_processes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.work_process_type 
            (name ,          description,       num_max_agents, dispatch_order, extra_params)
     VALUES   
            ('driving',        'drive from a to b',    1,           '[["A"]]' ,  NULL );

            

INSERT INTO public.work_process_service_plan 
            (work_process_type_id, step ,request_order, agent, service_type,  depends_on_steps, is_result_assignment)
     VALUES   
            (1,                    'A' ,     1,             1,    'my_driving',        '[]',          true);

--
-- Data for Name: yards; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.yards DISABLE TRIGGER ALL;


INSERT INTO public.yards 
            (id, uid , name,   description,   source    ,   yard_type     ,   map_data,                                                            lat,      lon,  alt,    created_at,                      modified_at )
     VALUES   
			(1, '1', 'LatLng Yard', 'test yard', 'initial data', 'logistic_yard','{"origin":{"alt":300,"lat":51.0504,"lon":13.7373,"zoomLevel":19}}', 51.0504, 13.7373, 0, '2020-08-03 12:00:00.000000', '2020-08-03 12:00:00.000000');

ALTER TABLE public.yards ENABLE TRIGGER ALL;
SELECT pg_catalog.setval('public.yards_id_seq', 1, true);

--
-- Data for Name: shapes; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.shapes DISABLE TRIGGER ALL;
ALTER TABLE public.shapes ENABLE TRIGGER ALL;
-- SELECT pg_catalog.setval('public.shapes_id_seq', 42, true);

--
-- Data for Name: targets; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.targets DISABLE TRIGGER ALL;

-- INSERT INTO public.targets VALUES (1, NULL, NULL, 'gate', 'gate_A', 'back', -7500, -20500, -245, 1);
-- INSERT INTO public.targets VALUES (2, NULL, NULL, 'gate', 'gate_B', 'back', 20000, -27300, -1847, 1);
-- INSERT INTO public.targets VALUES (3, NULL, NULL, 'gate', 'gate_C', 'front', -10000, -9800, -245, 1);
-- INSERT INTO public.targets VALUES (4, NULL, NULL, 'parking', 'new_parking_2', 'front', 98041, 11259, 500, 1);
-- INSERT INTO public.targets VALUES (5, NULL, NULL, 'parking', 'new_parking_3', 'front', 96541, 18758, 500, 1);
-- INSERT INTO public.targets VALUES (6, NULL, NULL, 'parking', 'new_parking_4', 'front', 64998, -506, -3534, 1);
-- INSERT INTO public.targets VALUES (7, NULL, NULL, 'parking', 'farm_1', 'front',  80000, -10000, 0, 3);
-- INSERT INTO public.targets VALUES (8, NULL, NULL, 'parking', 'farm_2', 'front', 157074, -89887, 0, 3);
-- INSERT INTO public.targets VALUES (9, NULL, NULL, 'parking', 'farm_3', 'front', 231257, -92469, 0, 3);

ALTER TABLE public.targets ENABLE TRIGGER ALL;
-- SELECT pg_catalog.setval('public.targets_id_seq', 15, true);

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.users DISABLE TRIGGER ALL;

-- INSERT INTO public.users VALUES (2, '', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, '2020-06-08 12:09:09.171705', NULL, 'admin', 0);

ALTER TABLE public.users ENABLE TRIGGER ALL;

--
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.user_account DISABLE TRIGGER ALL;

-- INSERT INTO public.user_account VALUES (2, 'admin@trucktrix.com', '$2a$06$LFwkwir9R1hsVySJY1NfEeFtgj5rGUB/Ax/YUFwOKBfjDIxLfZ88G', 0);

ALTER TABLE public.user_account ENABLE TRIGGER ALL;


--
-- Data for Name: tools; Type: TABLE DATA; Schema: public; Owner: postgres
--

-- ALTER TABLE public.agents DISABLE TRIGGER ALL;

-- INSERT INTO public.agents VALUES (5, 'truck', '{"id": 1024, "axles": [{"id": 0, "position": {"x": 1400, "y": 0}, "steering": {"axle_type": "forced", "max_steer_angle": 1000, "steering_reference": "remote"}, "tire_width": 315, "tire_diameter": 1044, "wheel_positions": [1000, -1000]}, {"id": 4, "position": {"x": 7600, "y": 0}, "steering": {"axle_type": "fixed"}, "tire_width": 315, "tire_diameter": 1044, "wheel_positions": [1000, -1000]}], "width": 2500, "height": 3950, "length": 8500, "chassis_position": {"x": 0, "y": 0}, "ground_clearance": 300, "rear_joint_position": {"x": 8500, "y": 0}, "max_front_joint_angle": 0}', 'free', 'DD-HelyOS_2019', 'DD-HelyOS_2019', NULL, true, 2, -1257, -9554, 5495, '{}', '2020-06-08 12:12:57', NULL, '2020-06-08 12:12:57.345569', NULL);

-- ALTER TABLE public.agents ENABLE TRIGGER ALL;

--
-- PostgreSQL database dump complete
--

