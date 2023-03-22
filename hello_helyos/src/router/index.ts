import { createRouter, createWebHistory } from 'vue-router'
import Login from '../components/Login.vue'
import Helyos from '@/components/Helyos.vue'
import { useUserStore } from '@/stores/user-store';

const routes = [
    {
        path: '/',
        name: 'login',
        component: Login
    },
    {
        path: '/',
        name: 'demo',
        component: Helyos
    }
]

const router = createRouter({
    history: createWebHistory(process.env.BASE_URL),
    routes
})

router.beforeEach((to, from, next)=>{
    const userStore = useUserStore();
    const token = userStore.user.token;
    if(token || to.path === '/'){
        next();    
    }else{
        next("/");
    }   
})

export default router