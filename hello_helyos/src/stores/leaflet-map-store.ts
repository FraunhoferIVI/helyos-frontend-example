import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useLeafletMapStore = defineStore('map', ()=>{
    // map view object
    const leafletMap = ref();
    const onClickCoords = ref(); // the destination of driving mission

    return{
        leafletMap,
        onClickCoords
    }

})