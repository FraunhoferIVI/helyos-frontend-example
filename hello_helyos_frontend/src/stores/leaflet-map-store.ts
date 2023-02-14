import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useLeafletMapStore = defineStore('map', ()=>{
    // map view object
    const leafletMap = ref();

    return{
        leafletMap,
    }

})