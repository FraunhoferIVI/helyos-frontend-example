<template>
    <div class="login-form">
        <h1>Welcome to helyOS hello-world application</h1>
        <div>Username:
            <input type="text" v-model="loginForm.username" placeholder="user name" />
        </div>
        <div>Password:
            <input type="password" v-model="loginForm.password" placeholder="password" />
        </div>
        <button @click="login">Login</button>
    </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useUserStore, type User } from '@/stores/user-store';
import { useRouter } from 'vue-router'
import * as HS from '@/services/helyos-service';

// define loginForm
const loginForm = ref({
    username: '',
    password: '',
    token: ''
} as User);

// define userStore
const userStore = useUserStore();
// define router
const router = useRouter();

// login
const login = async () => {

    // login into helyOS and get the helyOS Token
    const helyosToken = await HS.helyosLogin(loginForm.value.username, loginForm.value.password);
    console.log("tk", helyosToken);

    // login in successfully
    if (helyosToken) {
        loginForm.value.token = helyosToken.jwtToken;
        // store user information
        userStore.setUser(loginForm.value);

        // initialize helyOS connection and data fetching
        const connected = await HS.helyosConnect();
        console.log(connected);

        // routing to next page
        router.push({
            name: "demo",
        })
    } else {
        alert("Incorrect username or password!")
    }
}

defineExpose({
    login,
})

</script>

<style scoped>
.login-form {
    background-color: lightgray;
    margin: auto;
    width: 50%;
    border: 3px solid green;
    padding: 10px;
    text-align: center;
    /* padding: 20%; */
}

.login-form input {
    margin: 10px;
}

.login-form button {
    margin: 10px;
}
</style>
