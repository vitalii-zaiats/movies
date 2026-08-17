<script setup lang="ts">
// Who you are, and the two ways to become somebody the server remembers.
//
// There is no signed-out state here. A visitor is already a guest with a history
// of their own; registering *claims* that guest — same row, same history, now
// with a way back into it from another browser. That is why this page says
// "keep this account" and not "create one".

const { user, named, problem, refresh, register, signIn, signOut } = useSession()

const mode = ref<'in' | 'up'>('up')
const form = ref({ email: '', password: '', displayName: '' })
const busy = ref(false)
const done = ref<string | null>(null)

onMounted(() => {
  if (!user.value) void refresh()
})

async function submit(): Promise<void> {
  busy.value = true
  done.value = null
  const ok =
    mode.value === 'up'
      ? await register(form.value.email.trim(), form.value.password, form.value.displayName.trim() || undefined)
      : await signIn(form.value.email.trim(), form.value.password)
  busy.value = false

  if (ok) {
    form.value = { email: '', password: '', displayName: '' }
    done.value = mode.value === 'up' ? 'Account kept. This browser is you.' : 'Signed in.'
  }
}

async function leave(): Promise<void> {
  busy.value = true
  await signOut()
  busy.value = false
  done.value = 'Signed out. You are a guest again — with a fresh history.'
}
</script>

<template>
  <section class="section">
    <div class="section-head">
      <h2 class="section-title">Account</h2>
      <span v-if="user" class="section-link">{{ named ? 'signed in' : 'guest' }}</span>
    </div>

    <StateNote v-if="problem" tone="error" :message="problem" class="gap" />
    <StateNote v-else-if="done" :message="done" class="gap" />

    <div class="panels">
      <div class="panel">
        <h6>You</h6>
        <dl v-if="user" class="facts">
          <dt>Name</dt>
          <dd>{{ user.display_name }}</dd>
          <dt>Email</dt>
          <dd>{{ user.email ?? '—' }}</dd>
          <dt>Role</dt>
          <dd>{{ user.role }}</dd>
          <dt>Since</dt>
          <dd>{{ formatDate(user.created_at) }}</dd>
        </dl>
        <StateNote v-else message="Asking the server…" />

        <p class="aside">
          Watch history and resume points follow this account, guest or not. They
          were never tied to signing in — only to being remembered.
        </p>

        <button
          v-if="named"
          type="button"
          class="btn btn-secondary"
          :disabled="busy"
          @click="leave"
        >
          Sign out
        </button>
      </div>

      <div class="panel">
        <div class="seg" role="group" aria-label="Mode">
          <label class="seg-opt">
            <input v-model="mode" type="radio" name="mode" value="up" >
            Keep this account
          </label>
          <label class="seg-opt">
            <input v-model="mode" type="radio" name="mode" value="in" >
            Sign in
          </label>
        </div>

        <form class="form" @submit.prevent="submit">
          <div class="field">
            <label for="email">Email</label>
            <input id="email" v-model="form.email" class="input" type="email" autocomplete="email" required >
          </div>

          <div v-if="mode === 'up'" class="field">
            <label for="display">Name <span class="hint">— optional</span></label>
            <input id="display" v-model="form.displayName" class="input" autocomplete="nickname" >
          </div>

          <div class="field">
            <label for="password">Password</label>
            <input
              id="password"
              v-model="form.password"
              class="input"
              type="password"
              :autocomplete="mode === 'up' ? 'new-password' : 'current-password'"
              :minlength="mode === 'up' ? 8 : 1"
              required
            >
            <p v-if="mode === 'up'" class="hint">Eight characters or more.</p>
          </div>

          <button type="submit" class="btn btn-primary" :disabled="busy">
            {{ busy ? 'Working…' : mode === 'up' ? 'Keep it' : 'Sign in' }}
          </button>
        </form>
      </div>
    </div>
  </section>
</template>

<style scoped lang="scss">
.gap {
  margin-bottom: var(--space-4);
}

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

.aside {
  margin: 0 0 var(--space-4);
  font-size: 13px;
  color: color-mix(in srgb, var(--color-text) 65%, transparent);
}
</style>
