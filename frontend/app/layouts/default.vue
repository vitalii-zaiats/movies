<template>
  <div class="shell">
    <AppNav />
    <main>
      <slot />
    </main>
    <AppFooter />
    <CastButton />
  </div>
</template>

<style scoped lang="scss">
.shell {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

main {
  flex: 1;
}
</style>
