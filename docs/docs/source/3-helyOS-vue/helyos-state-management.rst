helyOS State Management
=======================
Once you have built the **Service Layer** interacting with helyOS core, theoretically, you could start designing the user interfaces and visualization logics. However, for 
the multi-components consisted website, it's very common that multi-components that share a same state or actions from different components may need to mutate the same state. 
Technically, state management solution, like ``Pinia`` or ``Vuex``, could fix these kinds of problems and support more flexibility in large-scale production applications.

As :ref:`state management <StateManagementOverview>` was initially introduced in previous chapter, this chapter will help you complete more stores with ``Pinia`` related 
to helyOS. You might want to create your custom stores, you can also refer this chapter as store templates.

Leaflet Map
-----------
`Leaflet map <https://leafletjs.com/>`_ is used to display helyOS yards, shapes, tools and other map objects. When a map view object was initiated, it could be stored into a 
``Pinia`` store. To implement this leaflet map store, you should define a new store:

*./stores/leaflet-map-store.ts*

.. code:: typescript

    import { defineStore } from 'pinia'
    import { ref } from 'vue'

    export const useLeafletMapStore = defineStore('map', ()=>{
        // map view object
        const leafletMap = ref();

        return{
            leafletMap,
        }

    })

Then, define a leaflet map component:

*./components/LeafletMap.vue*

.. code::

    <template>
        <div id="mapContainer"></div>
        <div class="map-control">
            <button @click="goHome" class="mapBtn">Home</button>
            <br>
            <div class="coord-panel">{{ clickedPoint }}</div>
        </div>
    </template>

    <script setup lang="ts">
    import { onMounted, ref } from 'vue';
    import "leaflet/dist/leaflet.css";
    import L, { type LatLngExpression } from "leaflet";
    import CheapRuler from "cheap-ruler";
    import { useLeafletMapStore } from '@/stores/leaflet-map-store';
    import { useToolStore } from '@/stores/tool-store';


    const leafletMapStore = useLeafletMapStore(); // map store
    const leafletMap = ref(leafletMapStore.leafletMap); // map ref
    const originLatLon = ref({ "lat": 51.053197, "lon": 13.703106 }); // yard 1
    const zoomLevel = 17;

    // initiate map
    const initMap = (): any => {
        leafletMap.value = L.map("mapContainer").setView([originLatLon.value.lat, originLatLon.value.lon], zoomLevel);
        // map layer
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(leafletMap.value);
        onClickCoord();
    };

    // return two types coords of on click location
    const clickedPoint = ref();
    const onClickCoord = () => {
        // get MM coords
        leafletMap.value.on('click', (ev: any) => {
            let point = convertLatLngToMM(originLatLon.value.lat, originLatLon.value.lon, [[ev.latlng.lat, ev.latlng.lng]])
            console.log("Latlng: ", ev.latlng, "\nMM: ", point[0]);
            clickedPoint.value = {
                LatLng: ev.latlng,
                MM: point[0]
            }
        })
    }

    // convert LatLng to MM
    const convertLatLngToMM = (originLat: number, originLon: number, shapeLatLngPoints: number[][]) => {
        const ruler = new CheapRuler(originLat, 'meters'); // calculations around latitude 
        const points = shapeLatLngPoints.map(point => {
            const distance = ruler.distance([originLon, originLat], [point[1], point[0]])
            const angle = ruler.bearing([originLon, originLat], [point[1], point[0]]) * Math.PI / 180;
            return [distance * 1000 * Math.sin(angle), distance * 1000 * Math.cos(angle)];
        });
        return points;
    }


    // go-home button
    const goHome = () => {
        leafletMap.value.flyTo([originLatLon.value.lat, originLatLon.value.lon], zoomLevel);
    };

    // add GeoJson file
    const geoJsonDisplay = (geojsonObj: any) => {
        const geoJsonLayer = L.layerGroup(); // A layer group stores geojson objects  
        // console.log(geojsonObj);
        geoJsonLayer.addLayer(L.geoJSON(geojsonObj)).addTo(leafletMap.value);
    };

    // add polygon layer
    const addPolygon = (polygon: LatLngExpression[] | any) => {
        const polygonLayer = L.layerGroup() // A layer group stores polygon layers   
        polygonLayer.addLayer(L.polygon(polygon)).addTo(leafletMap.value);
    };

    // add tool marker layer
    const toolStore = useToolStore(); // Tool store
    const toolMarker = (tool: any) => {
        // console.log("toolArray", toolArray);
        const toolMarkerLayer = L.layerGroup() // A layer group stores tool markers

        if (tool.picture) {
            const markerIcon = L.icon({
                iconUrl: tool.picture,
                iconSize: [32, 32]
            });
            const toolCoord = { lat: tool.y, lng: tool.x }
            tool.marker = L.marker(toolCoord).setIcon(markerIcon);
        }
        else {
            const toolCoord = { lat: tool.y, lng: tool.x }
            tool.marker = L.marker(toolCoord);
        }
        tool.marker.on('click', () => {
            toolStore.selectedTool = tool;
            toolStore.updateSelectedTool();
            console.log(toolStore.selectedTool);
        });
        toolMarkerLayer.addLayer(tool.marker.bindPopup(tool.name));
        toolMarkerLayer.addTo(leafletMap.value);;
    };

    // move marker to LatLng
    const updateMarkerLatLng = (tool: any, toolPose: any) => {
        // console.log(tool, toolPose);    
        const newLatLng = new L.LatLng(toolPose.lat, toolPose.lng);
        tool.marker.setLatLng(newLatLng);
    };

    // update map view
    const updateMap = (originLat: number, originLon: number) => {
        leafletMap.value.remove(); // Destroys current map and clears all related event listeners
        initMap();
        originLatLon.value = { lat: originLat, lon: originLon };
        leafletMap.value.setView([originLatLon.value.lat, originLatLon.value.lon], zoomLevel);
    }

    // Mount
    onMounted(() => {
        initMap();
    });

    // export default
    defineExpose({
        updateMap, // update map view when switching yard
        addPolygon, // add polygon to the map
        geoJsonDisplay, // display geojson objects
        toolMarker, // initiate markers representing tools
        updateMarkerLatLng, // update markers location based on tools location
        leafletMap, // leaflet map
        clickedPoint // coords of clicked point
    });

    </script>

    <style scoped>
    #mapContainer {
        /* width: 1200px; */
        z-index: 0;
        height: 100%;
        display: flex;
    }

    .map-control {
        margin-bottom: 20px;
        position: relative;
        bottom: 50px;
        left: 10px;
        z-index: 10000;
    }

    .mapBtn {
        background-color: white;
        border: 1px solid darkgray;
        border-radius: 3px;
        margin-right: 5px;
    }

    .mapBtn:hover {
        background-color: lightgray;
    }

    .coord-panel {
        margin-top: 5px;
        background-color: white;
        display: inline-block;
        width: auto;
    }
    </style>

This leaflet map component contains all of methods interacting with map view, and store the map view object into leaflet map store.

Yard Store
----------
Yard store contains two states *selectedYard* and *yards*, representing the id of selected yard by user and all of yard objects respectively. It also provides a method to get 
selected yard object.

*./stores/yard-store.ts*

.. code:: typescript

    import { defineStore } from 'pinia'
    import { ref } from 'vue'
    import type { H_Yard } from 'helyosjs-sdk'

    export const useYardStore = defineStore('yard', () => {
        // Initiate helyos yard store
        const selectedYard = ref("1") // yard id of current shown yard
        const yards = ref([] as H_Yard[]); // all of helyOS yard objects

        // get selected yard object
        const getCurrentYard = () => {
            return yards.value.filter((yards) => {
                return yards.id === selectedYard.value;
            })
        }

        return {
            yards,
            selectedYard,
            getCurrentYard,
        }

    })

Tool Store
----------
Yard store contains states about helyOS agents, and provides operations for tool objects between user interface and service layer.

*./stores/tool-store.ts*

.. code:: typescript

    import { defineStore } from 'pinia'
    import { ref } from 'vue'
    import { useYardStore } from './yard-store'
    import type { H_Tools } from 'helyosjs-sdk'
    import { patchTool, helyosService } from '@/services/helyos-service'

    export const useToolStore = defineStore('tool', () => {
        // Initiate helyos tool store
        const tools = ref([] as H_Tools[]); // all of helyOS agent objects
        const ifSubscription = ref(0); // if 1, subscribe the pose updates of all tools, if 0, cancel the subscription
        const selectedTool = ref(); // selected tool
        const selectedToolInfo = ref(); // shown information of selected tool

        // get tools of selected yard from shape store
        const filterToolByYard = (yardId: string) => {
            console.log(tools.value);
            
            return tools.value.filter((tool) => {
                if(tool.yardId){
                    return tool.yardId.toString() === yardId;
                }            
            })
        }

        // patch all tools
        const patchToolIcon = (icon: any) => {
            tools.value.forEach((tool: H_Tools) => {
                // update icon of tool in tool store
                tool.picture = icon;

                // new tool
                const newTool = {
                    id: tool.id,
                    picture: icon,
                }

                // request patch tool operation
                patchTool(newTool);
            })
        }

        // convert coordinate from trucktrix format to latlng
        const convertToolToLatLng = (tool: H_Tools) => {
            const yardStore = useYardStore();
            const currentYard = yardStore.getCurrentYard();
            const toolLatLng = helyosService.convertMMtoLatLng(currentYard[0].lat, currentYard[0].lon, [[tool.x as number, tool.y as number]]);
            // console.log(toolLatLng);
            tool.x = toolLatLng[0][1]; // Lng as x
            tool.y = toolLatLng[0][0]; // lat as y
            tool.dataFormat = "LatLng-vehicle"
            return tool;
        }

        // update tools
        const updateToolMarkers = () => {
            tools.value.forEach((tool) => {
                const toolPose = {
                    lat: tool.y,
                    lon: tool.x
                }
                // tool.moveMarker(tool, toolPose);
            })
        }

        // update tool status information
        const updateSelectedTool = () => {
            // console.log(selectedTool.value);

            selectedToolInfo.value = {
                id: selectedTool.value.id,
                connectionStatus: selectedTool.value.connectionStatus,
                name: selectedTool.value.name,
                status: selectedTool.value.status,
                // sensors: selectedTool.value.sensors,
                lat: selectedTool.value.y,
                lon: selectedTool.value.x,
                orientation: selectedTool.value.orientation,
                yardId: selectedTool.value.yardId
            }
        }


        return {
            tools,
            ifSubscription,
            selectedToolInfo,
            selectedTool,
            filterToolByYard,
            patchToolIcon,
            updateSelectedTool,
            convertToolToLatLng,
            updateToolMarkers,
        }

    })

Shape Store
-----------
Shape store contains a *shape* state to store all of helyOS shape objects, and provides operations to upload shapes into helyOS database or delete shapes from helyOS database.

*./stores/shape-store.ts*

.. code:: typescript

    import { defineStore } from 'pinia'
    import { ref } from 'vue'
    import type { H_Shape } from 'helyosjs-sdk'
    import { pushNewShape, deleteShape } from '@/services/helyos-service'


    export const useShapeStore = defineStore('shape', () => {
        // Initiate helyos shape store
        const shapes = ref([] as H_Shape[]); // all of helyOS shape objects

        // get shapes of selected yard from shape store
        const filterShapeByYard = (yardId: string) => {
            return shapes.value.filter((shape) => {
                return shape.yardId === yardId;
            })
        }

        // push new shape 
        const pushShape = async (shape: any) => {
            // push new shape into helyos database
            const newShape = await pushNewShape(shape);
            console.log(newShape);

            // push new shape into shape store
            if (newShape) {
                shapes.value.push(newShape as H_Shape);
                alert("Push successfully!");
            } else {
                alert("Push failed!")
            }
        }

        // delete all shapes of selected yard
        const deleteShapesByYard = (yardId: string) => {
            // shapes to be deleted
            const deleteGroup = filterShapeByYard(yardId);
            console.log(deleteGroup);

            if (deleteGroup.length) {
                deleteGroup.forEach((shape) => {
                    // delete shape from helyos database
                    deleteShape(shape.id);

                    // delete shape from shape store
                    const index = shapes.value.indexOf(shape);
                    if (index > -1) {
                        shapes.value.splice(index, 1);
                    }
                })
                alert("Delete" + deleteGroup.length + " shape(s) successfully!")
            }
            else {
                alert("Nothing to be deleted!")
            }

        }

        return {
            shapes,
            filterShapeByYard,
            pushShape,
            deleteShapesByYard,
        }

    })

WorkProcess Store
-----------------
WorkProcess store contains states including pre-defined *Missions* in helyOS Dashboard, *WorkProcess* objects, and selected mission(*WorkProcessType*).

*./stores/work-process-store.ts*

.. code:: typescript

    import { defineStore } from 'pinia'
    import { ref } from 'vue'
    import type { H_WorkProcess, H_WorkProcessType } from 'helyosjs-sdk'
    import { dispatchWorkProcess } from '@/services/helyos-service'

    export const useWorkProcessStore = defineStore('work-process', ()=>{
        // Initiate helyos work process store
        const selectedMission = ref(); // selected work process type
        const workProcess = ref({}); // helyOS work process object
        const workProcessType = ref([] as H_WorkProcessType[]); // all work process types

        const dispatchMission = (toolId: number, yardId: any, requestMsg: any, settingMsg: any) => {
            workProcess.value = {
                toolIds: [toolId],
                yardId: yardId,
                workProcessTypeName: selectedMission.value,
                data: requestMsg,
                status: 'dispatched', 
            }
            const missionLog = dispatchWorkProcess(workProcess.value as H_WorkProcess);  
            console.log(missionLog);
                    
        }

        return{
            selectedMission,
            workProcess,
            workProcessType,
            dispatchMission
        }

    })