// One client for the whole app, chosen once from the runtime config.
//
// Everything that reads the catalogue goes through here, so "where does the data
// come from" has exactly one answer and flipping it is an environment variable:
//
//   NUXT_PUBLIC_USE_MOCKS=false npm run dev

import type { CatalogueClient } from '~/lib/catalogue/client'
import { createHttpClient } from '~/lib/catalogue/http'
import { createMockClient } from '~/lib/catalogue/mock'

let client: CatalogueClient | null = null

export function useCatalogue(): CatalogueClient {
  if (!client) {
    const { apiBase, useMocks } = useRuntimeConfig().public
    client = useMocks ? createMockClient() : createHttpClient(apiBase)
  }
  return client
}
