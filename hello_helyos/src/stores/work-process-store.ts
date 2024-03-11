import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { H_WorkProcess, H_WorkProcessType } from 'helyosjs-sdk'
import { dispatchWorkProcess } from '@/services/helyos-service'

export const useWorkProcessStore = defineStore('work-process', ()=>{
    // Initiate helyos work process store
    const selectedMission = ref(); // selected work process type
    const workProcess = ref({}); // helyOS work process object
    const workProcessType = ref([] as H_WorkProcessType[]); // all work process types

    const dispatchMission = (agentId: number, yardId: any, requestMsg: any, settingMsg: any) => {
        workProcess.value = {
            agentIds: [agentId],
            yardId: yardId,
            workProcessTypeName: selectedMission.value,
            data: requestMsg,
            status: 'dispatched', 
        }
        const missionLog = dispatchWorkProcess(workProcess.value);  
        console.log(missionLog);
                
    }

    return{
        selectedMission,
        workProcess,
        workProcessType,
        dispatchMission
    }

})