import { defineStore } from 'pinia'
import { ref } from 'vue'

// define user type
export type User = { username: string; password: string; token: string};

// define a Store
export const useUserStore = defineStore("user", ()=>{

    // define a user type state
    const user = ref({} as User)

    // define an action that set user's data into userStore
    const setUser = (userInfo: User)=>{
        user.value = userInfo;
    }

    // expose states and actions
    return{
        user,
        setUser
    }
})