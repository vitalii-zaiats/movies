// Who's watching, as one piece of shared state.
//
// There is no signed-out state to design around: the API mints a guest on first
// contact, so this is always somebody — the only question is whether they have
// claimed an account yet. That's what makes history and resume work for a
// visitor who never signs up, and why registering keeps the same person rather
// than starting a second one.

import type { User } from '~/types/catalogue'

export function useSession() {
  const catalogue = useCatalogue()
  const user = useState<User | null>('session:user', () => null)
  const problem = useState<string | null>('session:problem', () => null)

  /** Who the API says we are. Also what mints the guest, first time round. */
  async function refresh(): Promise<void> {
    try {
      user.value = await catalogue.me()
    } catch (cause) {
      // Not being able to say who you are shouldn't take the page down with it.
      problem.value = (cause as Error).message
    }
  }

  async function guard<T>(work: () => Promise<T>): Promise<T | null> {
    problem.value = null
    try {
      return await work()
    } catch (cause) {
      problem.value = (cause as Error).message
      return null
    }
  }

  async function register(
    email: string,
    password: string,
    displayName?: string,
  ): Promise<boolean> {
    const identity = await guard(() => catalogue.register(email, password, displayName))
    if (identity) user.value = identity.user
    return identity !== null
  }

  async function signIn(email: string, password: string): Promise<boolean> {
    const identity = await guard(() => catalogue.signIn(email, password))
    if (identity) user.value = identity.user
    return identity !== null
  }

  /** Signing out doesn't end you, it makes you a stranger again — a new guest. */
  async function signOut(): Promise<void> {
    await guard(() => catalogue.signOut())
    await refresh()
  }

  const named = computed(() => user.value !== null && !user.value.is_guest)

  return { user, named, problem, refresh, register, signIn, signOut }
}
