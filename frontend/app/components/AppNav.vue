<script setup lang="ts">
const links = [
  { to: '/', label: 'Home' },
  { to: '/shows', label: 'Shows' },
  { to: '/playlists', label: 'Playlists' },
  { to: '/search', label: 'Search' },
]

// Said out loud rather than hidden: nobody should mistake fixtures for a seeded
// catalogue while the backend is still being wired up.
const { mocked } = useCatalogue()

// Asked once, here, because the nav is on every page. A guest is somebody too,
// so this always has a name to show — it just isn't an account until it is.
const { user, named, refresh } = useSession()
onMounted(() => {
  if (!user.value) void refresh()
})
</script>

<template>
  <nav class="nav app-nav">
    <NuxtLink to="/" class="nav-brand">LUMEN</NuxtLink>
    <div class="links">
      <NuxtLink v-for="link in links" :key="link.to" :to="link.to">{{ link.label }}</NuxtLink>
    </div>
    <span v-if="mocked" class="tag tag-accent mock">mock data</span>
    <NuxtLink to="/account" class="who">
      <span class="name">{{ user?.display_name ?? '…' }}</span>
      <span v-if="user && !named" class="tag guest">guest</span>
    </NuxtLink>
  </nav>
</template>

<style scoped lang="scss">
.app-nav {
  position: sticky;
  top: 0;
  z-index: 40;
  background: var(--color-bg);
}

.nav-brand {
  margin-right: var(--space-8);
  color: inherit;
  text-decoration: none;
}

.links {
  display: flex;
  gap: var(--space-6);
  font-size: 14px;
  font-weight: 600;

  a {
    color: inherit;
    text-decoration: none;

    &:hover,
    &.router-link-active {
      color: var(--color-accent);
    }
  }

  // Every route is under "/", so the home link would always look active.
  a[href='/']:not(.router-link-exact-active) {
    color: inherit;
  }
}

// The links take the slack, so everything after them sits against the edge —
// with or without the mock badge between.
.links {
  margin-right: auto;
}

.mock {
  margin-left: var(--space-4);
}

.who {
  display: flex;
  gap: var(--space-2);
  align-items: center;
  margin-left: var(--space-4);
  font-size: 14px;
  font-weight: 600;
  color: inherit;
  text-decoration: none;

  &:hover .name,
  &.router-link-active .name {
    color: var(--color-accent);
  }
}

.guest {
  font-size: 11px;
  color: color-mix(in srgb, var(--color-text) 60%, transparent);
  border-color: currentcolor;
}

@media (max-width: 720px) {
  .links {
    gap: var(--space-4);
    font-size: 13px;
  }

  .nav-brand {
    margin-right: var(--space-3);
  }

  .mock {
    display: none;
  }
}
</style>
