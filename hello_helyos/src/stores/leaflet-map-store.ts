import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useLeafletMapStore = defineStore('map', ()=>{
    const onClickCoords = ref(); // the coordinates of clicked point on map

    return{
        onClickCoords
    }

})