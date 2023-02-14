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