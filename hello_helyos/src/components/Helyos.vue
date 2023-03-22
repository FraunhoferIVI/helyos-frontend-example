<template src="./../assets/html/helyos-demo.html"></template>  
<style src="./../assets/css/helyos-demo.css"></style>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import Map from "./LeafletMap.vue";
import * as HS from '@/services/helyos-service';
import { useYardStore } from '@/stores/yard-store';
import { useUserStore } from '@/stores/user-store';
import { useMapObjectStore } from '@/stores/map-object-store';
import { useToolStore } from '@/stores/tool-store';
import { useWorkProcessStore } from '@/stores/work-process-store';
import { useLeafletMapStore } from '@/stores/leaflet-map-store';

const mapStore = useLeafletMapStore(); // leaflet map store
const mapRef = ref(); // reactive variable of leaflet map

const userStore = useUserStore(); // helyos user store
const yardStore = useYardStore(); // helyos yards Store
const mapObjectStore = useMapObjectStore();// helyos map object store
const toolStore = useToolStore(); // helyos tools store
const workProcessStore = useWorkProcessStore(); // helyos work process store

const hintMsg = ref("Welcome to HelyOS");

// initialize yard
const initYard = () => {
    console.log("Initiate yard", yardStore.selectedYard);
    // set new map view of current yard
    const currentYard = yardStore.getCurrentYard();
    const originLatLon = {
        lat: currentYard[0].lat,
        lon: currentYard[0].lon
    }
    mapRef.value.updateMap(originLatLon.lat, originLatLon.lon);

    // display MapObjects of current yard from MapObject store
    initMapObjects();

    // display tools of current yard from tool store
    initTools();
}

// initialize tools layer
const initTools = () => {
    console.log(yardStore.selectedYard);

    const tools = toolStore.filterToolByYard(yardStore.selectedYard);
    console.log("tools in current yard", tools);
    tools.forEach((tool) => {
        mapRef.value.toolMarker(tool);
    })
}

// watch tool status
const unwatch = watch(
    () => toolStore.ifSubscription,
    (ifSubscription) => {
        // console.log("watching", ifsubscription);
        if (ifSubscription && yardStore.selectedYard) {

            toolStore.tools.forEach((tool) => {

                if ('marker' in tool) {
                    const toolPose = {
                        lat: tool.y,
                        lng: tool.x
                    }
                    mapRef.value.updateMarkerLatLng(tool, toolPose);
                }

                if (toolStore.selectedTool) {
                    toolStore.updateSelectedTool();
                }
            })
        }
        toolStore.ifSubscription = 0;
    },
    { deep: true }
)

// upload a image file as truck icon
const updateToolIcon = (ev: any) => {
    console.log("upload icon");

    // read png file
    const PNGFile = ev.target.files[0];

    // check if file is a .geojson or .json format
    const checkPNGFile = PNGFile.name.split(".").pop();
    if (checkPNGFile === "png" || checkPNGFile === "PNG") {
        // read json file as text
        const reader = new FileReader();
        reader.readAsDataURL(PNGFile);
        reader.onload = (file) => {
            // console.log(tool);
            const iconURL = file.target?.result as string;
            toolStore.patchToolIcon(iconURL);
            initYard();
        }
    } else {
        alert("Wrong file format! Please upload png format.")
    }
}

// initialize MapObjects layer
const initMapObjects = () => {
    // get mapObjects from MapObject store
    const mapObjects = mapObjectStore.filterMapObjectByYard(yardStore.selectedYard);
    // if (yardStore.selectedYard === "4") { // geojson format MapObjects
    console.log("MapObjects in current yard", mapObjects);

    mapObjects.forEach((mapObject) => {
        mapRef.value.geoJsonDisplay(mapObject.data);
    })

    // clear temporary geojson object
    geoJsonObj.value = undefined;
}

// upload GeoJSON file and display objects on the map
const geoJsonObj = ref(); // geojson object container
const uploadGeoJson = (ev: any) => {
    console.log("upload geojson");

    // read json file
    const jsonFile = ev.target.files[0];

    // check if file is a .geojson or .json format
    const checkJsonFile = jsonFile.name.split(".").pop();
    if (checkJsonFile === "json" || checkJsonFile === "geojson") {

        // read json file as text
        const reader = new FileReader();
        reader.readAsText(jsonFile);
        reader.onload = (file) => {
            // convert text to json object
            geoJsonObj.value = JSON.parse(file.target?.result as any); // FeatureCollection from geojson/json file 
            // display geojson object
            mapRef.value.geoJsonDisplay(geoJsonObj.value);
        }

    } else {
        alert("Wrong file format!")
    }
}

// push uploaded GeoJSON data to helyos database
const pushGeoJson = async () => {
    if (geoJsonObj.value) {
        const newMapObject = {
            yardId: yardStore.selectedYard,
            // isObstacle: true,
            type: "obstacle",
            dataFormat: "GeoJSON",
            name: "obstacle",
            data: geoJsonObj.value
        }
        console.log(newMapObject);
        mapObjectStore.pushMapObject(newMapObject);
    } else {
        alert("Push failed: please upload geojson file firstly.");
    }
}

// delete all MapObjects of current yard
const deleteGeoJson = () => {
    mapObjectStore.deleteMapObjectsByYard(yardStore.selectedYard);
    initYard();
}

// create a new mission dispatch it via workProcess store
const settingMsg = ref("{}");
const requestMsg = ref("{}");
const initMission = () => {
    console.log("mission", workProcessStore.selectedMission); // workProcessType.name

    if (workProcessStore.selectedMission) { // if mission selected
        if (!toolStore.selectedTool) { // if tool not selected
            requestMsg.value = "{\"results\": [{\"tool_id\": , \"result\": { \"destination\": { \"x\": , \"y\": , \"orientations\":[0,0] }}}]}";
        } else if (!mapStore.onClickCoords) { // if map not clicked
            requestMsg.value = "{\"results\": [{\"tool_id\": " + toolStore.selectedTool.id + ", \"result\": { \"destination\": { \"x\": , \"y\": , \"orientations\":[0,0] }}}]}";
        } else { // if tool, mission are selected and map clicked
            requestMsg.value = "{\"results\": [{\"tool_id\": " + toolStore.selectedTool.id + ", \"result\": { \"destination\": { \"x\":" + mapStore.onClickCoords.lng + ", \"y\":" + mapStore.onClickCoords.lat + ", \"orientations\":[0,0] }}}]}";
        }
    } else {

        requestMsg.value = "{}";
    }
}

// watch map onClick latlng coordinates
const unwatchOnClickMap = watch(
    () => mapStore.onClickCoords,
    (coords) => {
        if (!toolStore.selectedTool) {
            alert("Please select a tool firstly!")
        } else if (workProcessStore.selectedMission) {
            requestMsg.value = "{\"results\": [{\"tool_id\": " + toolStore.selectedTool.id + ", \"result\": { \"destination\": { \"x\":" + coords.lng + ", \"y\":" + coords.lat + ", \"orientations\":[0,0] }}}]}";
        }
        // console.log("coords", coords);
    }
)

// dispatch the mission
const createMission = () => {
    console.log("mission", workProcessStore.selectedMission); // workProcessType.name
    console.log("request", requestMsg.value);
    console.log("setting", settingMsg.value);

    if (!toolStore.selectedTool) {
        alert("Please select a tool firstly!")
    } else if (workProcessStore.selectedMission == "") {
        alert("Please select a mission!")
    } else if (requestMsg.value === "{}") {
        alert("Request must not be empty!")
    } else {
        workProcessStore.dispatchMission(Number(toolStore.selectedTool.id), yardStore.selectedYard, requestMsg.value, settingMsg.value);
    }

}


onMounted(() => {
    setTimeout(() => {
        initYard();
    }, 1000)
})

</script>
