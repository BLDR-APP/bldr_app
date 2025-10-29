// supabase/functions/enviar-hidratacao/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import * as djwt from "https://deno.land/x/djwt@v3.0.2/mod.ts"; // Atualizado

async function getAccessToken() {
  console.log("Iniciando getAccessToken (v3)..."); // v3
  const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
  const privateKeyString = Deno.env.get('FCM_PRIVATE_KEY');

  if (!clientEmail || !privateKeyString) {
    throw new Error('Segredos do FCM (FCM_CLIENT_EMAIL ou FCM_PRIVATE_KEY) não estão configurados ou estão vazios.');
  }

  // ===== CORREÇÃO DEFINITIVA =====
  // O Supabase Secrets salva o '\n' do JSON como o texto literal '\\n'.
  // Precisamos convertê-lo de volta para uma quebra de linha real.
  const privateKey = privateKeyString.replace(/\\n/g, '\n');

  console.log("Email lido:", clientEmail);
  console.log("Início da Chave Privada (processada):", privateKey.substring(0, 30));
  // ===============================

  const now = Math.floor(Date.now() / 1000);

  const jwt = await djwt.create(
    { alg: 'RS256', typ: 'JWT' }, // Cabeçalho
    { // Payload
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600, // Token válido por 1 hora
      iat: now,
    },
    privateKey, // <-- Passando a chave processada
  );

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Falha ao obter token de acesso: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

// O resto da função (serve) é igual, mas vou incluir
// para você poder copiar e colar o arquivo todo.
serve(async (req) => {
  try {
    const projectId = Deno.env.get('FCM_PROJECT_ID');
    if (!projectId) {
      throw new Error('Segredo FCM_PROJECT_ID não está configurado.');
    }

    const accessToken = await getAccessToken();

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data: profiles, error } = await supabaseAdmin
      .from('user_profiles')
      .select('fcm_token')
      .eq('notifications_enabled', true)
      .not('fcm_token', 'is', null);

    if (error) {
      throw error;
    }

    if (!profiles || profiles.length === 0) {
      return new Response(
        JSON.stringify({ message: 'Nenhum usuário com token encontrado.' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    const FCM_URL = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const sendPromises = profiles.map(profile => {
      const notificationPayload = {
        message: {
          token: profile.fcm_token,
          notification: {
            title: '💧 Lembrete de Hidratação',
            body: 'Hora de beber água! Lembre-se de se manter hidratado.',
          },
          android: { notification: { sound: 'default' } },
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        },
      };

      return fetch(FCM_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(notificationPayload),
      });
    });

    await Promise.all(sendPromises);

    return new Response(
      JSON.stringify({ message: `Notificações enviadas para ${profiles.length} usuários.` }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (err) {
    console.error('Erro na Edge Function (v3):', err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});