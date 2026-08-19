<script setup lang="ts">
// Saying yes, on behalf of a device that can't ask for itself.
//
// A television has no keyboard worth using, so it never asks for an email. It
// shows a code; this page — a browser, where somebody is already signed in and
// can read what they are agreeing to — is what approves it.
//
// The code alone can only approve. Collecting the session needs a secret that
// never left the television, so approving the wrong code hands nothing to
// anybody: at worst a stranger's device is linked to no session it can reach.

import { CatalogueError } from '~/lib/catalogue/client'
import type { DeviceLinkStatus } from '~/types/catalogue'

const route = useRoute()
const catalogue = useCatalogue()
const { user, named, refresh } = useSession()

const code = ref(String(route.query.code ?? '').toUpperCase())
const link = ref<DeviceLinkStatus | null>(null)
const problem = ref<string | null>(null)
const busy = ref(false)
const approved = ref(false)
const left = ref(0)

let ticking: ReturnType<typeof setInterval> | null = null

/** What is being asked for — fetched before anyone is invited to agree to it. */
async function look(): Promise<void> {
  problem.value = null
  link.value = null
  if (code.value.length < 4) return

  busy.value = true
  try {
    link.value = await catalogue.deviceLink(code.value)
    approved.value = link.value.approved
    countdown(link.value.expires_in)
  } catch (cause) {
    problem.value =
      cause instanceof CatalogueError && cause.status === 404
        ? 'No device is waiting on that code. Check it, or ask the device for a new one.'
        : (cause as Error).message
  } finally {
    busy.value = false
  }
}

async function approve(): Promise<void> {
  busy.value = true
  problem.value = null
  try {
    link.value = await catalogue.approveDevice(code.value)
    approved.value = true
  } catch (cause) {
    problem.value = (cause as Error).message
  } finally {
    busy.value = false
  }
}

/** Codes die after ten minutes, and a page that doesn't say so looks broken. */
function countdown(seconds: number): void {
  left.value = seconds
  if (ticking) clearInterval(ticking)
  ticking = setInterval(() => {
    left.value = Math.max(0, left.value - 1)
    if (left.value === 0 && ticking) clearInterval(ticking)
  }, 1000)
}

const expired = computed(() => link.value !== null && left.value === 0)
const clock = computed(() => {
  const minutes = Math.floor(left.value / 60)
  return `${minutes}:${String(left.value % 60).padStart(2, '0')}`
})

onMounted(async () => {
  if (!user.value) await refresh()
  await look()
})

onBeforeUnmount(() => {
  if (ticking) clearInterval(ticking)
})
</script>

<template>
  <section class="section">
    <div class="section-head">
      <h2 class="section-title">Link a device</h2>
      <span v-if="link && !expired && !approved" class="section-link">{{ clock }} left</span>
    </div>

    <div class="panels">
      <div class="panel">
        <h6>The device</h6>

        <form v-if="!link" class="form" @submit.prevent="look">
          <p class="aside">
            Type the code shown on the television. It is six characters, and it
            is not case sensitive.
          </p>
          <div class="field">
            <label for="code">Code</label>
            <input
              id="code"
              v-model="code"
              class="input code"
              maxlength="6"
              autocapitalize="characters"
              autocomplete="off"
              spellcheck="false"
              required
            >
          </div>
          <button type="submit" class="btn btn-primary" :disabled="busy">
            {{ busy ? 'Looking…' : 'Find it' }}
          </button>
        </form>

        <template v-else>
          <dl class="facts">
            <dt>Asking</dt>
            <dd>{{ link.device_name ?? 'An unnamed device' }}</dd>
            <dt>Code</dt>
            <dd class="code">{{ link.code }}</dd>
            <dt>Status</dt>
            <dd>{{ approved ? 'approved' : expired ? 'expired' : 'waiting' }}</dd>
          </dl>

          <StateNote
            v-if="approved"
            :message="`Done. ${link.device_name ?? 'The device'} is signing in as ${user?.display_name ?? 'you'} — it may take a moment to notice.`"
          />
          <StateNote
            v-else-if="expired"
            tone="error"
            message="This code has run out. Ask the device for a new one."
          />
        </template>

        <StateNote v-if="problem" tone="error" :message="problem" class="gap-top" />
      </div>

      <div class="panel">
        <h6>You</h6>
        <p class="aside">
          The device will be signed in as whoever you are here — so it gets your
          history, your resume points and your playlists.
        </p>

        <dl v-if="user" class="facts">
          <dt>Name</dt>
          <dd>{{ user.display_name }}</dd>
          <dt>Account</dt>
          <dd>{{ named ? user.email : 'guest' }}</dd>
        </dl>
        <StateNote v-else message="Asking the server…" />

        <p v-if="user && !named" class="aside">
          You are a guest in this browser. Linking still works — the television
          shares this guest — but neither of you can get back in from anywhere
          else until the account is kept.
          <NuxtLink to="/account" class="section-link">Keep it first →</NuxtLink>
        </p>

        <button
          v-if="link && !approved && !expired"
          type="button"
          class="btn btn-primary"
          :disabled="busy"
          @click="approve"
        >
          {{ busy ? 'Working…' : `Sign in ${link.device_name ?? 'this device'}` }}
        </button>

        <button
          v-if="approved"
          type="button"
          class="btn btn-secondary"
          @click="(link = null), (approved = false), (code = '')"
        >
          Link another
        </button>
      </div>
    </div>
  </section>
</template>

<style scoped lang="scss">
.panels {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--space-6);
}

.panel {
  padding: var(--space-6);
  border: 2px solid var(--color-divider);
}

.form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  margin-top: var(--space-4);
}

.facts {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: var(--space-2) var(--space-4);
  margin: var(--space-4) 0;
  font-size: 14px;

  dt {
    color: color-mix(in srgb, var(--color-text) 60%, transparent);
  }

  dd {
    margin: 0;
    font-weight: 600;
  }
}

// The one place letters are read aloud off a screen and typed back in.
.code {
  font-family: var(--font-mono, ui-monospace, monospace);
  letter-spacing: 0.18em;
  text-transform: uppercase;
}

.aside {
  margin: 0 0 var(--space-4);
  font-size: 13px;
  color: color-mix(in srgb, var(--color-text) 65%, transparent);
}

.gap-top {
  margin-top: var(--space-4);
}
</style>
