import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from './views/DashboardView.vue'
import DisplayView from './views/DisplayView.vue'
import RemoteView from './views/RemoteView.vue'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    // The big screen is the default: that's what gets opened on a TV.
    { path: '/', name: 'display', component: DisplayView },
    // What the QR points at. Without a code it asks for one.
    { path: '/r/:code?', name: 'remote', component: RemoteView },
    // Where playlists get built — a desk job, not a couch one.
    { path: '/dashboard', name: 'dashboard', component: DashboardView },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})
