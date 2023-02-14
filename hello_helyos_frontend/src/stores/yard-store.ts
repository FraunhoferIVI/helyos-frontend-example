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