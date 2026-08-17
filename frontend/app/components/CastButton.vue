<script setup lang="ts">
// The way in, parked in the corner.
//
// It owns whether this screen is offering itself, and nothing else: the socket
// belongs to `CastSession`, which stays mounted for as long as pairing is on —
// so putting the window away leaves the room, and the phone in it, alone.

const { state, pairing, phones, remembered, heldElsewhere, claim, HEARTBEAT } = useCast()

/** Another tab of this browser is the screen. Ours would only be a second one. */
const elsewhere = ref(false)
let watchOwner: ReturnType<typeof setInterval> | undefined

/** The window, which comes and goes; `pairing` is the thing that persists. */
const showing = ref(false)

onMounted(() => {
  elsewhere.value = heldElsewhere()
  watchOwner = setInterval(() => {
    elsewhere.value = heldElsewhere()
  }, HEARTBEAT)

  // A reload shouldn't drop a phone that's holding the remote: if this screen
  // was pairing when it left, it picks the same room back up — but only if no
  // other tab is already the screen, or the two would fight over the code.
  if (remembered().pairing && !elsewhere.value) pairing.value = true
})

onBeforeUnmount(() => clearInterval(watchOwner))

function open(): void {
  // Taking over is deliberate: the other tab sees the claim and steps down.
  if (elsewhere.value) claim()
  elsewhere.value = false
  pairing.value = true
  showing.value = true
}

function stop(): void {
  pairing.value = false
  showing.value = false
}
</script>

<template>
  <div class="dock">
    <button type="button" class="btn btn-secondary trigger" @click="open">
      <span class="dot" :class="{ live: phones > 0, on: pairing && !phones && !state.idle }" />
      {{ elsewhere ? 'Remote is on another tab' : phones > 0 ? 'Remote on' : 'Remote' }}
    </button>
  </div>

  <CastSession
    v-if="pairing"
    :showing="showing"
    @hide="showing = false"
    @stop="stop"
  />
</template>

<style scoped lang="scss">
.dock {
  position: fixed;
  right: var(--space-4);
  bottom: var(--space-4);
  z-index: 30;
}

.trigger {
  display: inline-flex;
  gap: var(--space-2);
  align-items: center;
  background: var(--color-bg);
  box-shadow: var(--shadow-lg);
}

.dot {
  width: 8px;
  height: 8px;
  background: color-mix(in srgb, var(--color-text) 35%, transparent);
  border-radius: 50%;

  // A phone is holding the remote.
  &.live {
    background: var(--color-accent);
  }

  // Offered, but nobody has scanned it yet.
  &.on {
    background: color-mix(in srgb, var(--color-accent) 45%, transparent);
  }
}
</style>
