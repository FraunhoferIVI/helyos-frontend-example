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
import { slideTo } from "leaflet.marker.slideto";
import { useLeafletMapStore } from '@/stores/leaflet-map-store';
import { useToolStore } from '@/stores/tool-store';


const leafletMapStore = useLeafletMapStore(); // map store
const leafletMap = ref(leafletMapStore.leafletMap); // map ref
const originLatLon = ref({ "lat": 51.0504, "lon": 13.7373 }); // yard 1
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

        // coordinates panel
        clickedPoint.value = {
            LatLng: ev.latlng,
            MM: point[0]
        }

        // the destination of driving mission
        leafletMapStore.onClickCoords = ev.latlng

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
    tool.marker.slideTo(newLatLng, { duration: 1000 });
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
    // geoJsonDisplay(testJson);
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