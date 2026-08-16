import { createApp } from 'vue'
import { registerSW } from 'virtual:pwa-register'
import App from './App.vue'
import { router } from './router'
import './styles/main.scss'

// autoUpdate: a screen left running for days should not sit on stale code.
registerSW({ immediate: true })

createApp(App).use(router).mount('#app')
