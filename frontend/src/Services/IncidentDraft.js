const DB_NAME = 'cartagena-segura-private'
const STORE_NAME = 'incident-data'
const DB_VERSION = 1
const chatHistoryKey = username => `chat:${username}`

function openDraftDatabase() {
  if (!globalThis.indexedDB) {
    return Promise.reject(new Error('Este navegador no permite guardar borradores locales.'))
  }
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION)
    request.onupgradeneeded = () => {
      if (!request.result.objectStoreNames.contains(STORE_NAME)) {
        request.result.createObjectStore(STORE_NAME)
      }
    }
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error ?? new Error('No se pudo abrir el almacenamiento local.'))
  })
}

async function transactionRequest(mode, action) {
  const db = await openDraftDatabase()
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE_NAME, mode)
    const request = action(transaction.objectStore(STORE_NAME))
    request.onerror = () => reject(request.error ?? new Error('No se pudo guardar la información local.'))
    transaction.oncomplete = () => {
      db.close()
      resolve(request.result)
    }
    transaction.onerror = () => {
      db.close()
      reject(transaction.error ?? new Error('No se pudo completar el almacenamiento local.'))
    }
    transaction.onabort = () => {
      db.close()
      reject(transaction.error ?? new Error('Se canceló el almacenamiento local.'))
    }
  })
}

const draftKey = username => `draft:${username}`
const pendingKey = username => `pending:${username}`

export const loadIncidentDraft = username =>
  transactionRequest('readonly', store => store.get(draftKey(username)))

export const saveIncidentDraft = (username, draft) =>
  transactionRequest('readwrite', store => store.put(draft, draftKey(username)))

export const clearIncidentDraft = username =>
  transactionRequest('readwrite', store => store.delete(draftKey(username)))

export async function loadPendingIncidents(username) {
  return (await transactionRequest('readonly', store => store.get(pendingKey(username)))) ?? []
}

export async function enqueueIncident(username, report) {
  const pending = await loadPendingIncidents(username)
  if (pending.some(item => item.idempotencyKey === report.idempotencyKey)) return
  await transactionRequest('readwrite', store =>
    store.put([...pending, report], pendingKey(username)))
}

export async function removePendingIncident(username, idempotencyKey) {
  const pending = await loadPendingIncidents(username)
  await transactionRequest('readwrite', store =>
    store.put(pending.filter(item => item.idempotencyKey !== idempotencyKey), pendingKey(username)))
}

export async function updatePendingIncident(username, updatedReport) {
  const pending = await loadPendingIncidents(username)
  await transactionRequest('readwrite', store =>
    store.put(
      pending.map(item => item.idempotencyKey === updatedReport.idempotencyKey ? updatedReport : item),
      pendingKey(username),
    ))
}

export const loadChatHistory = username =>
  transactionRequest('readonly', store => store.get(chatHistoryKey(username)))

export const saveChatHistory = (username, history) =>
  transactionRequest('readwrite', store => store.put(history, chatHistoryKey(username)))

export const clearChatHistory = username =>
  transactionRequest('readwrite', store => store.delete(chatHistoryKey(username)))
