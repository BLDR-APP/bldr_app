// supabase/functions/enviar-lembrete/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import * as djwt from "https://deno.land/x/djwt@v3.0.2/mod.ts"

async function getAccessToken() {
  console.log("Iniciando getAccessToken (RS256 + CryptoKey)...")

  const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')
  const privateKeyPem = Deno.env.get('FCM_PRIVATE_KEY')

  if (!clientEmail || !privateKeyPem) {
    throw new Error('FCM_CLIENT_EMAIL ou FCM_PRIVATE_KEY não estão configurados no Supabase Secrets.')
  }

  // Corrigir \\n → \n (Supabase salva como string literal)
  const privateKey = privateKeyPem.replace(/\\n/g, '\n').trim()

  // Remover cabeçalhos PEM e espaços
  const pemContents = privateKey
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '')

  // Decodificar Base64 → ArrayBuffer
  let binaryDer: ArrayBuffer
  try {
    binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0)).buffer
  } catch (err) {
    throw new Error('Erro ao decodificar chave privada (Base64 inválido). Verifique FCM_PRIVATE_KEY.')
  }

  // Importar chave como CryptoKey (PKCS#8, RS256)
  let key: CryptoKey
  try {
    key = await crypto.subtle.importKey(
      'pkcs8',
      binaryDer,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    )
  } catch (err) {
    throw new Error(`Erro ao importar chave privada: ${err.message}`)
  }

  const now = Math.floor(Date.now() / 1000)

  // Criar JWT com RS256
  const jwt = await djwt.create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now,
    },
    key
  )

  // Trocar JWT por access_token
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const data = await response.json()
  if (!response.ok) {
    throw new Error(`Falha ao obter access_token: ${JSON.stringify(data)}`)
  }

  return data.access_token as string
}

// === Servidor HTTP ===
serve(async (req) => {
  try {
    const projectId = Deno.env.get('FCM_PROJECT_ID')
    if (!projectId) {
      throw new Error('FCM_PROJECT_ID não está configurado no Supabase Secrets.')
    }

    const accessToken = await getAccessToken()

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: profiles, error } = await supabaseAdmin
      .from('user_profiles')
      .select('fcm_token')
      .eq('notifications_enabled', true)
      .not('fcm_token', 'is', null)

    if (error) throw error
    if (!profiles || profiles.length === 0) {
      return new Response(
        JSON.stringify({ message: 'Nenhum usuário com token FCM encontrado.' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    const FCM_URL = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    const sendPromises = profiles.map(async (profile) => {
      const payload = {
        message: {
          token: profile.fcm_token,
          notification: {
            title: 'Hora de Treinar!',
            body: 'Seu treino de hoje já está disponível. Vamos nessa!',
          },
          android: {
            priority: 'high',
            notification: { sound: 'default' },
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
            payload: {
              aps: {
                alert: {
                  title: 'Hora de Treinar!',
                  body: 'Seu treino de hoje já está disponível. Vamos nessa!',
                },
                sound: 'default',
                badge: 1,
              },
            },
          },
        },
      }

      return fetch(FCM_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(payload),
      })
    })

    const results = await Promise.all(sendPromises)
    const successes = results.filter(r => r.ok).length
    const failures = results.length - successes

    return new Response(
      JSON.stringify({
        message: 'Notificações de lembrete enviadas',
        total: profiles.length,
        sucessos: successes,
        falhas: failures,
      }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (err) {
    console.error('Erro na Edge Function (enviar-lembrete):', err)
    return new Response(
      JSON.stringify({ error: err.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})