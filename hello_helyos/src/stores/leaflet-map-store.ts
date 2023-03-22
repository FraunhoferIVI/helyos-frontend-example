import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useLeafletMapStore = defineStore('map', ()=>{
    const onClickCoords = ref(); // the destination of driving mission

    return{
        onClickCoords
    }

})